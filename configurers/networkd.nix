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
  shortName = fqdn:  head (strings.splitString "." fqdn);
in
with getKeyProviderFuncs keyProviders inputs intermediateConfig localPeerName;
{
  networking.extraHosts = concatStringsSep "\n" (concatLists ( concatLists (forEachAttrToList thisPeer.subnetConnections (subnetName: subnetConnection: 
    forEachAttrToList subnetConnection.peerConnections (remotePeerName: peerConnection: forEach peerConnection.ipAddresses (ip: "${strings.removeSuffix "/64" ip} ${remotePeerName}.${subnetName}"))
  )))); 
  systemd.network = { 
    netdevs = forEachAttr' thisPeer.subnetConnections (subnetName: subnetConnection: nameValuePair "50-${shortName subnetName}" { 
      netdevConfig = {
        Kind = "wireguard";
        Name = "${shortName subnetName}";
      };
      wireguardConfig = {
        ListenPort = subnetConnection.listenPort;
        # *PLEASE* do not use getPrivKeyfor anything but testing
        PrivateKeyFile = getPrivKeyFile;
      };
      wireguardPeers = forEachAttrToList subnetConnection.peerConnections (remotePeerName: peerConnection: {
        wireguardPeerConfig = {
          Endpoint = "${peerConnection.endpoint.ip}:${builtins.toString peerConnection.endpoint.port}";
          PublicKey = getPeerPubKey remotePeerName;
          AllowedIPs = map (ip: cidr2ip ip + "/128") peerConnection.ipAddresses;
          PresharedKeyFile = getSubnetPSKFile subnetName;
        };
      }
      // (if peerConnection.endpoint ? persistentKeepalive then {PersistentKeepalive =  peerConnection.endpoint.persistentKeepalive;} else {})
      // (warnIf (peerConnection.endpoint ? dynamicEndpointRefreshSeconds) "dynamicEndpointRefreshSeconds not supported for networkd" {}) 
      // (warnIf (peerConnection.endpoint ? dynamicEndpointRefreshRestartSeconds) "dynamicEndpointRefreshRestartSeconds not supported for networkd" {})
      );
    });
    networks = forEachAttr' thisPeer.subnetConnections (subnetName: subnetConnection: nameValuePair "50-${shortName subnetName}" { 
      matchConfig.Name = "${shortName subnetName}";
      address = subnetConnection.ipAddresses;
    });
  };
} // getProviderConfig