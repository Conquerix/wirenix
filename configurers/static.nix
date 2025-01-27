/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
{lib, devNameMethod ? "short", ...}@inputs: keyProviders: intermediateConfig: localPeerName:
let wnlib = import ../lib.nix {inherit lib;}; in
with wnlib;
with lib;
let
  thisPeer = intermediateConfig.peers."${localPeerName}";
  # these aren't really important, I just wanted to reverse the argument order
  forEachAttr' = flip mapAttrs'; 
  forEachAttrToList = flip mapAttrsToList; 
  devName = getDevName devNameMethod localPeerName;
in
with getKeyProviderFuncs keyProviders inputs intermediateConfig localPeerName;
{
  networking.hosts = foldl' (mergeAttrs) {} (concatLists ( concatLists (forEachAttrToList thisPeer.subnetConnections (subnetName: subnetConnection: 
    forEachAttrToList subnetConnection.peerConnections (remotePeerName: peerConnection: forEach peerConnection.ipAddresses (ip: {"${asIp ip}" = ["${remotePeerName}.${subnetName}"];}))
  )))); 
  networking.wireguard = {
    interfaces = forEachAttr' thisPeer.subnetConnections (subnetName: subnetConnection: nameValuePair (devName subnetName)
      {
        ips = map (address: (asCidr' "64" "24" address)) subnetConnection.ipAddresses;
        listenPort = subnetConnection.listenPort;
        privateKeyFile = getPrivKeyFile;  
        peers = forEachAttrToList subnetConnection.peerConnections (remotePeerName: peerConnection: 
          mkIf ((peerConnection.endpoint != null && peerConnection.endpoint ? ip && peerConnection.endpoint ? port) || thisPeer.isPublic){
            name = remotePeerName;
            publicKey = getPeerPubKey remotePeerName;
            presharedKeyFile = getSubnetPSKFile subnetName;
            allowedIPs = map ( ip: asCidr ip) peerConnection.ipAddresses;
            endpoint = mkIf (peerConnection.endpoint != null && (peerConnection.endpoint ? ip) == true && (peerConnection.endpoint ? port) == true) "${peerConnection.endpoint.ip}:${builtins.toString peerConnection.endpoint.port}";
          }
          // (mergeIf peerConnection.endpoint "persistentKeepalive")
          // (mergeIf peerConnection.endpoint "dynamicEndpointRefreshSeconds")
          // (mergeIf peerConnection.endpoint "dynamicEndpointRefreshRestartSeconds")
        );
      }
    );
  };
} // getProviderConfig
