{lib, ...}: intermediateConfig:
with import ../lib.nix;
with lib.attrsets;
with builtins;
{
  config = {};
  getPeerPubKey = peerName: attrByPath [peerName "publicKey"] null intermediateConfig.peers;
  getPeerPrivKeyFile = peerName: attrByPath [peerName "privateKeyFile"] null intermediateConfig.peers;
  getSubnetPSK = subnetName: attrByPath [subnetName "presharedKeyFile"] null intermediateConfig.subnets;
}