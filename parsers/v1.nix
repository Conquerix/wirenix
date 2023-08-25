/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
{lib, ...}: v1_acl: 
with lib.attrsets;
with lib.lists;
with lib.trivial;
with (import ../lib.nix);
with builtins;
let
  /** parsePeer :: acl_peer -> ic_peer */
  parsePeer = acl_peer: {
      subnetConnections = listOfSetsToSetByKey "name" (pipeMap [subnetFromName (getSubnetConnectionAndName acl_peer)] (attrNames acl_peer.subnets));
    }
    // mergeIf acl_peer "extraArgs"
    // mergeIf acl_peer "publicKey"
    // mergeIf acl_peer "privateKeyFile"
    // mergeIf acl_peer "privateKey"
    // (if acl_peer ? groups then {groups = map groupFromName acl_peer.groups;} else {groups = {};});     
  
  /** parseGroup :: acl_group -> ic_group */
  parseGroup = acl_group: {
    peers = mapListOfSetsToSetByKey "name" parsePeer (selectPeers [{type="group"; rule="is"; value="${acl_group.name}";}]);
  }
  // mergeIf acl_group "extraArgs";
  
  /** parseSubnet :: acl_subnet -> ic_subnet */
  parseSubnet = acl_subnet: {
    peers = mapListOfSetsToSetByKey "name" parsePeer (selectPeers [{type="subnet"; rule="is"; value="${acl_subnet.name}";}]);
  }
  // mergeIf acl_subnet "extraArgs"
  // mergeIf acl_subnet "presharedKeyFile";
  
  /** getSubnetConnection :: acl_peer -> acl_subnet -> (subnetConnection // {name}) */
  getSubnetConnectionAndName = acl_peer: acl_subnet: {
    name = acl_subnet.name; # name gets removed shortly after, name is not in the actual subnetConnection object
    subnet = parseSubnet acl_subnet;
    ipAddresses = getIpAddresses acl_subnet acl_peer;
    listenPort = acl_peer.subnets."${acl_subnet.name}".listenPort;
    peerConnections = getPeerConnections acl_peer acl_subnet;
  } 
  // mergeIf (getAttr acl_subnet.name acl_peer.subnets) "extraArgs";
    
  /** getIpAddresses :: acl_peer -> acl_subnet -> [str] */
  getIpAddresses = acl_subnet: acl_peer: 
    if (acl_peer.subnets."${acl_subnet.name}" ? ipAddresses) then (
      if (elem "auto" acl_peer.subnets."${acl_subnet.name}".ipAddresses) then (
        (remove "auto" acl_peer.subnets."${acl_subnet.name}".ipAddresses) ++ (singleton (generateIPv6Address acl_subnet.name acl_peer.name))
      ) else acl_peer.subnets."${acl_subnet.name}".ipAddresses
    ) else (singleton (generateIPv6Address acl_subnet.name acl_peer.name));
  
  /** getPeerConnections :: acl_peer -> acl_subnet -> str -> peerConnection */
  getPeerConnections = acl_peerFrom: acl_subnet:
    let
      filterSubnets   = connection: !(connection ? subnets) || elem acl_subnet.name connection.subnets;
      filterPeer      = key: acl_peer: connection: elem acl_peer.name (catAttrs "name" (selectPeers connection."${key}"));
      getConnectionsX = key: filter (connection: all (x: x connection) [filterSubnets (filterPeer key acl_peerFrom)]) v1_acl.connections;
      getConnectionsA = getConnectionsX "a";
      getConnectionsB = getConnectionsX "b";
      allPeers = unique ((concatMap (connection: selectPeers connection.b) getConnectionsA) ++ (concatMap (connection: selectPeers connection.a) getConnectionsB));
      allOtherPeers = remove acl_peerFrom allPeers;
      getExtraArgs = acl_peerTo:
        let
          connections = (filter (filterPeer "a" acl_peerTo) getConnectionsB) ++ (filter (filterPeer "b" acl_peerTo) getConnectionsA);
          extraArgsList = catAttrs "extraArgs" connections;
        in
        foldl' mergeAttrs {} extraArgsList;
    in 
    listOfSetsToSetByKey "name" (map (acl_peerTo:
    let
      extraArgs = getExtraArgs acl_peerTo;
    in
    {
      name = acl_peerTo.name;
      peer = parsePeer acl_peerTo;
      ipAddresses = getIpAddresses acl_subnet acl_peerTo;
      endpoint = getEndpoint acl_subnet acl_peerFrom acl_peerTo;
    } // (if extraArgs == {} then {} else {inherit extraArgs;})
    ) allOtherPeers);
  
  /** getEndpoint :: acl_peer -> acl_peer -> ic_endpoint */
  getEndpoint = acl_subnet: acl_peerFrom: acl_peerTo:
    let
      peersForEndpoint = endpoint: catAttrs "name" (selectPeers (attrByPath ["match"] [] endpoint));
      allPeerEndpoints = if acl_peerTo ? endpoints then
          (filter (endpoint: elem acl_peerFrom.name (peersForEndpoint endpoint)) acl_peerTo.endpoints)
        else [];
      allGroupEndpoints = concatMap (acl_group: attrByPath ["endpoints"] [] (groupFromName acl_group)) (intersectLists 
        (attrByPath ["groups"] [] acl_peerTo)
        (attrByPath ["groups"] [] acl_peerFrom)
      );
      allSubnetEndpoints = acl_subnet.endpoints;
      allEndpointMatches = allSubnetEndpoints ++ allGroupEndpoints ++ allPeerEndpoints;
    in
    removeAttrs (foldl' mergeAttrs {} allEndpointMatches) [ "match" ];
  
  /** selectPeers :: [acl_filters] -> str -> [acl_peer]
   * (str -> ic_peer) means it returns an attrset of peers keyed by name, typescript syntax:
   * selectPeers(acl: acl, acl_filters: acl_filter[]): {[peerName: string]: ic_peer};
   */
  selectPeers = acl_filters:
    if length acl_filters == 0
    then 
      v1_acl.peers
    else
      foldl' intersectLists (selectPeersSingleFilter (head acl_filters)) (map selectPeersSingleFilter acl_filters);
    
  /** selectPeersSingleFilter :: acl_filter -> [acl_peer] */
  selectPeersSingleFilter = acl_filter:
    with acl_filter;
    let 
      applyRule = comparison: if rule == "is" then comparison else if rule == "not" then !comparison else throw ("Unknown filter rule " + rule);
    in
    if type == "peer" then
      (filter (acl_peer: applyRule (acl_peer.name == value)) v1_acl.peers) 
    else if type == "group" then 
      (filter (acl_peer: applyRule (elem value acl_peer.groups))  v1_acl.peers)
    else if type == "subnet" then
      (filter (acl_peer: applyRule (elem value (attrNames acl_peer.subnets)))  v1_acl.peers)
    else throw ("Unknown filter type " + type);
    
  groupFromName = groupName: findSingle
    (group: group.name == groupName) 
    (throw "No group " + groupName)
    (throw "Multiply defined group " + groupName)
    v1_acl.groups;

  subnetFromName = subnetName: findSingle
    (subnet: subnet.name == subnetName)
    (throw "No subnet " + subnetName)
    (throw "Multiply defined subnet " + subnetName)
    v1_acl.subnets;
    
  
in
{
  peers = mapListOfSetsToSetByKey "name" parsePeer v1_acl.peers;
  subnets = mapListOfSetsToSetByKey "name" parseSubnet v1_acl.subnets;
  groups = mapListOfSetsToSetByKey "name" parseGroup v1_acl.groups;
} 
// mergeIf v1_acl "extraArgs"