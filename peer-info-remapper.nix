{lib}: wirenix-config:
let 
  # Math
  inList = elem: list: builtins.any (e: e == elem) list;  
  # IP
  add-colons = string: 
    if ((builtins.stringLength string) > 4) 
    then 
      ((builtins.substring 0 4 string) + ":" + (add-colons (builtins.substring 4 32 string)))
    else string;
  
  # Peer Information
  peerInfo = {
    peerSuffix = peerName: builtins.substring 0 20 (builtins.hashString "sha256" peerName);
    peerSubnets = peer: builtins.filter (subnet: inList subnet.name peer.subnets) wirenix-config.subnets;
    peerGroups = peer: builtins.catAttrs "group" peer.peers;
    directPeers = peer: builtins.catAttrs "peer" peer.peers;
    peerFromName = peerName: builtins.head (builtins.filter (peer: peer.name == peerName) wirenix-config.peers);
    peersInGroup = groupName: builtins.filter (peer: inList groupName peer.groups) wirenix-config.peers;
    peerPeersUnfiltered = peer: (builtins.map (peerInfo.peerFromName) (peerInfo.directPeers peer)) ++ (builtins.concatMap (group: peerInfo.peersInGroup group) (peerInfo.peerGroups peer));
    peerIP = subnetName: PeerName: (add-colons ((subnetInfo.subnetPrefix subnetName) + (peerInfo.peerSuffix PeerName))) + "/80";  
    };
  # Subnet Information
  subnetInfo = {
    subnetPrefix = subnetName: "fd" + (builtins.substring 0 10 (builtins.hashString "sha256" subnetName));    
    subnetPeers = subnet: builtins.filter (peer: inList subnet.name peer.subnets) wirenix-config.peers;
  };
in 
{
  peer = peer:
    rec {
      subnets = peerInfo.peerSubnets peer;
      peers = lib.lists.remove peer (lib.lists.unique (peerInfo.peerPeersUnfiltered peer)); 
      ip = subnet: peerInfo.peerIP subnet.name peer.name;  
      peersOnSubnet = subnet: builtins.filter (otherPeer: inList subnet.name otherPeer.subnets) peers;  
      publicKey = peer.publicKey;
      privateKeyFile = peer.privateKeyFile;
    };
  subnet = subnet:
    {
      peers = subnetInfo.subnetPeers subnet;
      ip = (add-colons (subnetInfo.subnetPrefix subnet.name)) + "::/80";
    };
}
# subnets:
#   networkOne:
#     prefix: "auto" or "none" or canonicalized ipv6
#     ipv4: canonicalized ipv4 or "none"
#     ipv6: canonicalized ipv6 or "auto" or "none"
# peers:
#   peerOne:
#     pubKey: "ABC..." Or "auto"
#     subnets:
#       networkOne:
#         - ipv4: ip
#         - ipv6: "auto" or "none" or ip
#     groups:
#       - "groupOne"
#     peers:
#       - peer: "peerTwo"
#       - group: "groupOne"