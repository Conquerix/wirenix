/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
{lib, ...}@inputs: keyProviders: intermediateConfig: peerName:
with lib.trivial;
with lib.attrsets;
with lib.lists;
with lib;
with builtins;
with import ../lib.nix;
let
  thisPeer = intermediateConfig.peers."${peerName}";
  # these aren't really important, I just wanted to reverse the argument order
  forEachAttr' = flip mapAttrs'; 
  forEachAttrToList = flip mapAttrsToList; 
in
with getKeyProviderFuncs keyProviders inputs intermediateConfig peerName;
{
  networking.extraHosts = concatStringsSep "\n" (concatLists ( concatLists (forEachAttrToList thisPeer.subnetConnections (subnetName: subnetConnection: 
    forEachAttrToList subnetConnection.peerConnections (otherPeerName: peerConnection: forEach peerConnection.ipAddresses (ip: "${strings.removeSuffix "/64" ip} ${otherPeerName}.${subnetName}"))
  )))); 
  systemd.network = { 
    netdevs = forEachAttr' thisPeer.subnetConnections (subnetName: subnetConnection: nameValuePair "50-wn-${subnetName}" { 
      netdevConfig = {
        Kind = "wireguard";
        Name = "wn-${subnetName}";
      };
      wireguardConfig = {
        PrivateKeyFile = getPrivKeyFile;
        ListenPort = subnetConnection.listenPort;
      };
      wireguardPeers = forEachAttrToList subnetConnection.peerConnections (otherPeerName: peerConnection: {
        wireguardPeerConfig = {
          Endpoint = "${peerConnection.endpoint.ip}:${builtins.toString peerConnection.endpoint.port}";
          PublicKey = getPeerPubKey otherPeerName;
          AllowedIPs = peerConnection.ipAddresses;
          PresharedKeyFile = getSubnetPSKFile subnetName;
        };
      }
      // (if peerConnection.endpoint ? persistentKeepalive then {PersistentKeepalive =  peerConnection.endpoint.persistentKeepalive;} else {})
      // (warnIf (peerConnection.endpoint ? dynamicEndpointRefreshSeconds) "dynamicEndpointRefreshSeconds not supported for networkd" {}) 
      // (warnIf (peerConnection.endpoint ? dynamicEndpointRefreshRestartSeconds) "dynamicEndpointRefreshRestartSeconds not supported for networkd" {})
      );
    });
    networks = forEachAttr' thisPeer.subnetConnections (subnetName: subnetConnection: nameValuePair "${subnetName}" { 
      matchConfig.Name = "wn-${subnetName}";
      address = subnetConnection.ipAddresses;
    });
  };
} // getProviderConfig