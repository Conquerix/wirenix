{lib}: wirenix-config:
let 
  # Math
  # extract-key :: string -> list -> attrSet
  # Example: 
  # listOfSetsToSetByKey "primary" [ {primary = "foo"; secondary = 1; tertiary = "one"} {primary = "bar"; secondary = 2; tertiary = "two"} ]
  # {foo = {secondary = 1; tertiary = "one"}; bar = {secondary = 2; tertiary = "two"};}
  listOfSetsToSetByKey = key: list: 
    builtins.listToAttrs (
      lib.lists.forEach list (elem: {
        name = elem."${key}";
        value = lib.attrsets.filterAttrs (n: v: n != key) elem;
      })
    );
  # returns true if `elem` is in `list`
  inList = elem: list: builtins.any (e: e == elem) list;  
  # adds colons to a string every 4 characters for IPv6 shenanigans
  add-colons = string: 
    if ((builtins.stringLength string) > 4) 
    then 
      ((builtins.substring 0 4 string) + ":" + (add-colons (builtins.substring 4 32 string)))
    else string;
  
  # Peer Information
  # Helper functions for querying data about peers from the config
  peerInfo = {
    # last 20 (hardcoded atm) characters (80 bits) of the peer's IPv6 address
    IPSuffix = peerName: builtins.substring 0 20 (builtins.hashString "sha256" peerName);
    # list of subnets (as subnet attrset in wirenix config) the peer belongs to
    subnets = peer: builtins.filter (subnet: inList subnet.name peer.subnets) wirenix-config.subnets;
    # list of groups the peer connects to
    groupConnections = peer: builtins.catAttrs "group" peer.connections;
    # list of peers the peer connects to
    directConnections = peer: builtins.catAttrs "peer" peer.connections;
    # gets the peer (as peer attrset in wirenix config) from a name
    peerFromName = peerName: builtins.head (builtins.filter (peer: peer.name == peerName) wirenix-config.peers);
    # gets all peers (as peer attrset in wirenix config) the are in a group
    peersInGroup = groupName: builtins.filter (peer: inList groupName peer.groups) wirenix-config.peers;
    # gets all peers (as peer attrset in wirenix config) that the given peer connects to, may contain the peer itself and duplicates
    connectionsUnfiltered = peer: (builtins.map (peerInfo.peerFromName) (peerInfo.directConnections peer)) ++ (builtins.concatMap (group: peerInfo.peersInGroup group) (peerInfo.groupConnections peer));
    # gets all peers (as peer attrset in wirenix config) that the given peer connects to, will not contain the peer itself or duplicates
    connections = peer: lib.lists.remove peer (lib.lists.unique (peerInfo.connectionsUnfiltered peer));
    # returns the peer's IP when given the peer's name and subnet name
    IP = subnetName: PeerName: (add-colons ((subnetInfo.prefix subnetName) + (peerInfo.IPSuffix PeerName))) + "/80";  
    };
  # Subnet Information
  # Helper functions for querying data about subnets from the config
  subnetInfo = {
    # gets the subnet (as subnet attrset in wirenix config) from a name
    subnetFromName = subnetName: builtins.head (builtins.filter (subnet: subnet.name == subnetName) wirenix-config.subnets);
    # gets the first 10 characters of the IPV6 address for the subnet 
    prefix = subnetName: "fd" + (builtins.substring 0 10 (builtins.hashString "sha256" subnetName));
    # gets all peers (as peer attrset in wirenix config) that belong to the subnet
    peers = subnet: builtins.filter (peer: inList subnet.name peer.subnets) wirenix-config.peers;
  };
  
  # Mappers take a peer or subnet from the config and convert it
  # into a recursive attrset that is better suited for nix configs
  mappers = rec {
    
    # Maps a wirenix config subnet to a recursive attrset, structure is as follows:
    #   peers: a set of peers (as similar recursive attrsets), keyed by name
    #   ip: the subnet ip in CIDR notation
    subnetMap = subnet: {
      name = subnet.name;
      peers = listOfSetsToSetByKey "name" (builtins.map (peerMap) (subnetInfo.peers subnet));
      ip = (add-colons (subnetInfo.prefix subnet.name)) + "::/80";
    };
  
    # Maps a wirenix config peer to a recursive attrset, structure is as follows:
    #   subnets: a set of subnets (as similar recursive attrsets), keyed by name, with the following structure:
    #     subnet: the subnet as described in the subnetMap function's description
    #     ip: the peer's ip on the subnet (can only be one IP at the moment)
    #     peers: peers (as recursive attrset) on the subnet that the current peer has connections with
    #   connections: a set of all peers (as recursive attrset) which the current peer connects to, keyed by name
    #   publicKey: the peer's public key
    #   privateKeyFile: the location of the peer's private key
    peerMap = peer: {
      name = peer.name;
      subnets = listOfSetsToSetByKey "name" (
        builtins.map (subnet: {
          name = subnet.name;
          subnet = lib.attrsets.filterAttrs (n: v: n != "name") (subnetMap subnet);
          ip = peerInfo.IP subnet.name peer.name;
          peers = listOfSetsToSetByKey "name" (builtins.map (peerMap) (builtins.filter (otherPeer: inList subnet.name otherPeer.subnets) (peerInfo.connections peer)));
          }) (peerInfo.subnets peer)
      );
      connections = listOfSetsToSetByKey "name" (builtins.map (peerMap) (peerInfo.connections peer)); 
      publicKey = peer.publicKey;
      privateKeyFile = peer.privateKeyFile;
    };
  };
in 
{
  peerFromName = lib.attrsets.filterAttrs (n: v: n != "name") (mappers.peerMap peerInfo.peerFromName);
  subnetFromName = lib.attrsets.filterAttrs (n: v: n != "name") (mappers.subnetMap subnetInfo.subnetFromName);
  peers = listOfSetsToSetByKey "name" (builtins.map (mappers.peerMap) (wirenix-config.peers));
  subnets = listOfSetsToSetByKey "name" (builtins.map (mappers.subnetMap) (wirenix-config.subnets));
}