/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
{lib, ...}: intermediateConfig: localPeerName:
let wnlib = import ../lib.nix {inherit lib;}; in
with wnlib;
with lib;
{
  getPeerPubKey = remotePeerName: attrByPath [remotePeerName "publicKey"] null intermediateConfig.peers;
  getPrivKeyFile = attrByPath [localPeerName "privateKeyFile"] null intermediateConfig.peers;
  getSubnetPSKFile = subnetName: attrByPath [subnetName "presharedKeyFile"] null intermediateConfig.subnets;
}