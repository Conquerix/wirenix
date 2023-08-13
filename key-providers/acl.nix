{lib, ...}: intermediateConfig: peerName:
with import ../lib.nix;
with lib.attrsets;
with builtins;
{
  getPeerPubKey = otherPeerName: attrByPath [otherPeerName "publicKey"] null intermediateConfig.peers;
  getPrivKeyFile = attrByPath [peerName "privateKeyFile"] null intermediateConfig.peers;
  getSubnetPSKFile = subnetName: attrByPath [subnetName "presharedKeyFile"] null intermediateConfig.subnets;
}