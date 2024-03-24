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
  systemd.network = { 
    netdevs = forEachAttr' thisPeer.subnetConnections (subnetName: subnetConnection: nameValuePair "50-${devName subnetName}" { 
      netdevConfig = {
        Kind = "wireguard";
        Name = "${devName subnetName}";
      };
      wireguardConfig = {
        ListenPort = subnetConnection.listenPort;
        PrivateKeyFile = getPrivKeyFile;
      };
      wireguardPeers = forEachAttrToList subnetConnection.peerConnections (remotePeerName: peerConnection: {
        wireguardPeerConfig = {
          Endpoint = "${peerConnection.endpoint.ip}:${builtins.toString peerConnection.endpoint.port}";
          PublicKey = getPeerPubKey remotePeerName;
          AllowedIPs = map (ip: asCidr ip) peerConnection.ipAddresses;
          PresharedKeyFile = getSubnetPSKFile subnetName;
        } // (if peerConnection.endpoint ? persistentKeepalive then {PersistentKeepalive = peerConnection.endpoint.persistentKeepalive;} else {});
      }
      // (warnIf (peerConnection.endpoint ? dynamicEndpointRefreshSeconds) "dynamicEndpointRefreshSeconds not supported for networkd" {}) 
      // (warnIf (peerConnection.endpoint ? dynamicEndpointRefreshRestartSeconds) "dynamicEndpointRefreshRestartSeconds not supported for networkd" {})
      );
    });
    networks = forEachAttr' thisPeer.subnetConnections (subnetName: subnetConnection: nameValuePair "50-${devName subnetName}" { 
      matchConfig.Name = "${devName subnetName}";
      address = map (address: (asCidr' "64" "24" address)) subnetConnection.ipAddresses;
    });
  };
} // getProviderConfig