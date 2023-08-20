/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
{lib, ...}@inputs: keyProviders: intermediateConfig: localPeerName:
with lib.trivial;
with lib.attrsets;
with lib.lists;
with lib;
with builtins;
with import ../lib.nix;
let
  thisPeer = intermediateConfig.peers."${localPeerName}";
  # these aren't really important, I just wanted to reverse the argument order
  forEachAttr' = flip mapAttrs'; 
  forEachAttrToList = flip mapAttrsToList; 
in
with getKeyProviderFuncs keyProviders inputs intermediateConfig localPeerName;
{
  networking.extraHosts = concatStringsSep "\n" (concatLists ( concatLists (forEachAttrToList thisPeer.subnetConnections (subnetName: subnetConnection: 
    forEachAttrToList subnetConnection.peerConnections (remotePeerName: peerConnection: forEach peerConnection.ipAddresses (ip: "${strings.removeSuffix "/64" ip} ${remotePeerName}.${subnetName}"))
  )))); 
  networking.wireguard = {
    interfaces = forEachAttr' thisPeer.subnetConnections (subnetName: subnetConnection: nameValuePair "${head (strings.splitString "." subnetName)}"
      {
        ips = subnetConnection.ipAddresses;
        listenPort = subnetConnection.listenPort;
        privateKeyFile = getPrivKeyFile;  
        peers = forEachAttrToList subnetConnection.peerConnections (remotePeerName: peerConnection: 
          {
            name = remotePeerName;
            publicKey = getPeerPubKey remotePeerName;
            presharedKeyFile = getSubnetPSKFile subnetName;
            allowedIPs = map (ip: cidr2ip ip + "/128") peerConnection.ipAddresses;
            endpoint = "${peerConnection.endpoint.ip}:${builtins.toString peerConnection.endpoint.port}";
          }
          // (mergeIf peerConnection.endpoint "persistentKeepalive")
          // (mergeIf peerConnection.endpoint "dynamicEndpointRefreshSeconds")
          // (mergeIf peerConnection.endpoint "dynamicEndpointRefreshRestartSeconds")
        );
      }
    );
  };
} // getProviderConfig