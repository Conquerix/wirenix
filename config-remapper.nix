{lib}: wirenix-config:
with lib.attrsets;
with lib.lists;
with lib.trivial;
with builtins;
let 
  # Math
  # extract-key :: string -> list -> attrSet
  # Example: 
  # listOfSetsToSetByKey "primary" [ {primary = "foo"; secondary = 1; tertiary = "one"} {primary = "bar"; secondary = 2; tertiary = "two"} ]
  # {foo = {secondary = 1; tertiary = "one"}; bar = {secondary = 2; tertiary = "two"};}
  listOfSetsToSetByKey = key: list: 
    listToAttrs (
      forEach list (elem: {
        name = elem."${key}";
        value = removeAttrs elem [ key ];
      })
    );
  # returns true if `elem` is in `list`
  inList = elem: list: any (e: e == elem) list;  
  # adds colons to a string every 4 characters for IPv6 shenanigans
  add-colons = string: 
    if ((stringLength string) > 4) 
    then 
      ((substring 0 4 string) + ":" + (add-colons (substring 4 32 string)))
    else string;
  
  # Peer Information
  # Helper functions for querying data about peers from the config
  peerInfo = {
    # last 20 (hardcoded atm) characters (80 bits) of the peer's IPv6 address
    ipSuffix = peerName: substring 0 20 (hashString "sha256" peerName);
    # list of subnets (as subnet attrset in wirenix config) the peer belongs to
    subnets = peer: filter (subnet: inList subnet.name peer.subnets) wirenix-config.subnets;
    # list of groups the peer connects to
    groupConnections = peer: catAttrs "group" peer.connections;
    # list of peers the peer connects to
    directConnections = peer: catAttrs "peer" peer.connections;
    # list of subnets for which the peer will try to connect to all peer in the subnet
    subnetConnections = peer: catAttrs "subnet" peer.connections;
    # gets the peer (as peer attrset in wirenix config) from a name
    peerFromName = peerName: head (filter (peer: peer.name == peerName) wirenix-config.peers);
    # gets all peers (as peer attrset in wirenix config) the are in a group
    peersInGroup = groupName: filter (peer: inList groupName peer.groups) wirenix-config.peers;
    # returns true if peer is in group
    peerIsInGroup = peer: groupName: inList peer (peerInfo.peersInGroup groupName);
    # gets all peers (as peer attrset in wirenix config) that the given peer connects to, may contain the peer itself and duplicates
    connectionsUnfiltered = peer:
      (map (peerInfo.peerFromName) (peerInfo.directConnections peer)) ++
      (concatMap (group: peerInfo.peersInGroup group) (peerInfo.groupConnections peer)) ++
      (concatMap (subnet: subnetInfo.peersInSubnet subnet) (peerInfo.subnetConnections peer));
    # gets all peers (as peer attrset in wirenix config) that the given peer connects to, will not contain the peer itself or duplicates
    connections = peer: remove peer (unique (peerInfo.connectionsUnfiltered peer));
    # returns the peer's IP when given the peer's name and subnet name
    ip = subnetName: PeerName: (add-colons ((subnetInfo.prefix subnetName) + (peerInfo.ipSuffix PeerName))) + "/80";
    # returns the endpoint for peerTo that peerFrom will connect with
    endpointMatches = peerFrom: peerTo: map (matched: removeAttrs matched [ "match" ]) (
      filter (endpoint: 
        if endpoint == {} then true else
        all (id) (
          mapAttrsToList (type: value: 
            if (type == "group") then
              (peerInfo.peerIsInGroup peerFrom value)
            else if (type == "peer") then
              (peerFrom.name == endpoint.match.peer)
            else if (type == "subnet") then
              (peerInfo.peerIsInSubnet peerFrom (subnetInfo.subnetFromName value))
            else throw "Unexpected type "+type+" in endpoints config."
          ) endpoint
        )
      ) peerTo.endpoints
    );
    endpoint = foldl' (mergeAttrs) {} endpointMatches;
  };
  # Subnet Information
  # Helper functions for querying data about subnets from the config
  subnetInfo = {
    # gets all peers (as peer attrset in wirenix config) that belong to the subnet
    peersInSubnet = subnet: filter (peer: inList subnet.name peer.subnets) wirenix-config.peers;
    # returns true if peer is in subnet
    peerIsInSubnet = subnet: peer: inList peer (subnetInfo.peersInSubnet subnet);
    # gets the subnet (as subnet attrset in wirenix config) from a name
    subnetFromName = subnetName: head (filter (subnet: subnet.name == subnetName) wirenix-config.subnets);
    # gets the first 10 characters of the IPV6 address for the subnet name
    prefix = subnetName: "fd" + (substring 0 10 (hashString "sha256" subnetName));
  };
  
  # Mappers take a peer or subnet from the config and convert it
  # into a recursive attrset that is better suited for nix configs
  mappers = rec {
    
    # Maps a wirenix config subnet to a recursive attrset, structure is as follows:
    #   peers: a set of peers (as similar recursive attrsets), keyed by name
    #   ip: the subnet ip in CIDR notation
    subnetMap = subnet: {
      name = subnet.name;
      peers = listOfSetsToSetByKey "name" (map (peerMap) (subnetInfo.peersInSubnet subnet));
      ip = (add-colons (subnetInfo.prefix subnet.name)) + "::/80";
    };
  
    # Maps a wirenix config peer to a recursive attrset, structure is as follows:
    #   subnets: a set of subnets (as similar recursive attrsets), keyed by name, with the following structure:
    #     subnet: the subnet as described in the subnetMap function's description
    #     ip: the peer's ip on the subnet (can only be one IP at the moment)
    #     peers: peers (as recursive attrset) on the subnet that the current peer has connections to, keyed by name, with the following structure:
    #       peer: the peer as described by this description
    #       ip: the connected peers ip on the subnet (same as subnets[subnetName].peers[peerName].subnets[subnetName].ip)
    #       endpoint: the endpoint to connect to, described as follows:
    #         ip: the ip to connect to
    #         port: the port to connect to 
    #         persistentKeepalive: (optional) see networking.wireguard.interfaces.<name>.*.persistentKeepalive
    #         dynamicEndpointRefreshSeconds: (optional) see networking.wireguard.interfaces.<name>.*.dynamicEndpointRefreshSeconds
    #         dynamicEndpointRefreshRestartSeconds: (optional) see networking.wireguard.interfaces.<name>.*.dynamicEndpointRefreshRestartSeconds
    #   connections: a set of all peers (as recursive attrset) which the current peer connects to, keyed by name
    #   publicKey: the peer's public key
    #   privateKeyFile: the location of the peer's private key
    peerMap = peer: {
      name = peer.name;
      subnets = listOfSetsToSetByKey "name" (
        map (subnet: {
          name = subnet.name;
          subnet = removeAttrs (subnetMap subnet) [ "name" ];
          ip = peerInfo.ip subnet.name peer.name;
          peers = listOfSetsToSetByKey "name" (
            (map (peerTo: {
              name = peerTo.name;
              peer = removeAttrs (peerMap peerTo) [ "name" ];
              ip = peerInfo.ip subnet.name peerTo.name;
              endpoint = peerInfo.endpoint peer peerTo;
            }) (filter (otherPeer: inList subnet.name otherPeer.subnets) (peerInfo.connections peer)))
          );
          }) (peerInfo.subnets peer)
      );
      connections = listOfSetsToSetByKey "name" (map (peerMap) (peerInfo.connections peer)); 
      publicKey = peer.publicKey;
      privateKeyFile = peer.privateKeyFile;
    };
  };
in 
{
  peerFromName = removeAttrs (mappers.peerMap peerInfo.peerFromName) [ "name" ];
  subnetFromName = removeAttrs (mappers.subnetMap subnetInfo.subnetFromName) [ "name" ];
  peers = listOfSetsToSetByKey "name" (map (mappers.peerMap) (wirenix-config.peers));
  subnets = listOfSetsToSetByKey "name" (map (mappers.subnetMap) (wirenix-config.subnets));
}