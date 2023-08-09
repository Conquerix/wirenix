{lib, ...}: v1_acl: 
with lib.attrsets;
with lib.lists;
with lib.trivial;
with (import ../lib.nix);
with builtins;
let
  /** parsePeer :: acl_peer -> ic_peer */
  parsePeer = acl_peer: {
      subnetConnections = listOfSetsToSetByKey "name" (pipeMap [subnetFromName (getSubnetConnectionAndName acl_peer)] acl_peer.subnets);
      publicKey = acl_peer.publicKey;
      privateKeyFile = acl_peer.privateKeyFile;
    } //
    (if acl_peer ? extraArgs then {extraArgs = acl_peer.extraArgs;} else {}) //
    {
      publicKey = acl_peer.publicKey;
      privateKeyFile = acl_peer.privateKeyFile;
    } //
    (if acl_peer ? groups then {groups = map groupFromName acl_peer.groups;} else {groups = [];});
  
  /** parseGroup :: acl_group -> ic_group */
  parseGroup = acl_group: {
    peers = mapListOfSetsToSetByKey parsePeer (selectPeers [{type="group"; rule="is"; value="${acl_group.name}";}]);
  } // (if acl_group ? extraArgs then {extraArgs = acl_group.extraArgs;} else {});
  
  /** parseSubnet :: acl_subnet -> ic_subnet */
  parseSubnet = acl_subnet: {
    peers = mapListOfSetsToSetByKey parsePeer (selectPeers [{type="subnet"; rule="is"; value="${acl_subnet.name}";}]);
  } // (if acl_subnet ? extraArgs then {extraArgs = acl_subnet.extraArgs;} else {});
  
  /** getSubnetConnection :: acl_peer -> acl_subnet -> (subnetConnection // {name}) */
  getSubnetConnectionAndName = acl_peer: acl_subnet: {
    name = acl_subnet.name; # name gets removed shortly after, name is not in the actual subnetConnection object
    subnet = parseSubnet acl_subnet;
    ipAddresses = getIpAddresses acl_peer acl_subnet;
    listenPort = acl_peer.subnets."${acl_subnet.name}".listenPort;
    peerConnections = getPeerConnections acl_peer acl_subnet;
  } // (if acl_peer.subnets."${acl_subnet.name}" ? extraArgs then {extraArgs = acl_peer.subnets."${acl_subnet.name}".extraArgs;} else {});
  
  /** getIpAddresses :: acl_peer -> acl_subnet -> [str] */
  getIpAddresses = acl_peer: acl_subnet: 
    if (acl_peer.subnets."${acl_subnet.name}" ? ipAddresses) then (
      if (elem "auto" acl_peer.subnets."${acl_subnet.name}".ipAddresses) then (
        (remove "auto" acl_peer.subnets."${acl_subnet.name}".ipAddresses) ++ (singleton (generateIPv6Address acl_peer.name acl_subnet.name))
      ) else acl_peer.subnets."${acl_subnet.name}".ipAddresses
    ) else (singleton (generateIPv6Address acl_peer.name acl_subnet.name));
  
  /** getPeerConnections :: acl_peer -> acl_subnet -> str -> peerConnection */
  getPeerConnections = acl_peerFrom: acl_subnet:
    let
      filterSubnets   = connection: elem acl_subnet.name connection.subnets;
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
    {
      name = acl_peerTo.name;
      peer = parsePeer acl_peerTo;
      ipAddresses = getIpAddresses acl_peerTo acl_subnet;
      endpoint = getEndpoint acl_peerFrom acl_peerTo;
      extraArgs = getExtraArgs acl_peerTo;
    }) allOtherPeers);
  
  /** getEndpoint :: acl_peer -> acl_peer -> ic_endpoint */
  getEndpoint = acl_peerFrom: acl_peerTo: 
    let
      getAllEndpointMatches = filter (endpoint: elem acl_peerFrom.name (catAttrs "name" (selectPeers (if endpoint ? match then endpoint.match else [])))) acl_peerTo.endpoints;
    in
    removeAttrs (foldl' mergeAttrs {} getAllEndpointMatches) [ "match" ];
  
  /** selectPeers :: [acl_filters] -> str -> [acl_peer]
   * (str -> ic_peer) means it returns an attrset of peers keyed by name, typescript syntax:
   * selectPeers(acl: acl, acl_filters: acl_filter[]): {[peerName: string]: ic_peer};
   */
  selectPeers = acl_filters:
    if length acl_filters == 0
    then 
      v1_acl.peers
    else
      foldl' intersectAttrs (selectPeersSingleFilter (head acl_filters)) (map selectPeersSingleFilter acl_filters);
    
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
  peers = mapListOfSetsToSetByKey parsePeer v1_acl.peers;
  subnets = mapListOfSetsToSetByKey parseSubnet v1_acl.subnets;
  groups = mapListOfSetsToSetByKey parseGroup v1_acl.groups;
}