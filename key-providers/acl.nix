/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
{lib, ...}: intermediateConfig: peerName:
with import ../lib.nix;
with lib.attrsets;
with builtins;
{
  getPeerPubKey = otherPeerName: attrByPath [otherPeerName "publicKey"] null intermediateConfig.peers;
  getPrivKeyFile = attrByPath [peerName "privateKeyFile"] null intermediateConfig.peers;
  getSubnetPSKFile = subnetName: attrByPath [subnetName "presharedKeyFile"] null intermediateConfig.subnets;
}