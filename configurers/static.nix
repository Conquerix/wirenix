{config, lib, ...}: intermediateConfig: 
with lib.trivial;
with lib.attrsets;
with lib.lists;
with lib;
let
  # check whether or not agenix-rekey exists
  has-rekey = config ? rekey;
  thisPeer = intermediateConfig.peers."${config.wirenix.peerName}";
  # these aren't really important, I just wanted to reverse the argument order
  forEachAttr' = flip mapAttrs'; 
  forEachAttrToList = flip mapAttrsToList; 
in
{
  networking.wireguard = {
    interfaces = forEachAttr' thisPeer.subnetConnections (name: subnetConnection:  { name = "wg-${name}";
      value = {
        ips = subnetConnection.ipAddresses;
        listenPort = subnetConnection.listenPort;
        privateKeyFile = thisPeer.privateKeyFile;        
        peers = forEachAttrToList subnetConnection.peerConnections (peerName: peerConnection: mkMerge [
          {
            name = peerName;
            publicKey = peerConnection.peer.publicKey;
            allowedIPs = peerConnection.ipAddresses;
            endpoint = "${peerConnection.endpoint.ip}:${peerConnection.endpoint.port}";
          }
          mkIf (peerConnection.endpoint ? persistentKeepalive) {
            persistentKeepalive = peerConnection.endpoint.persistentKeepalive;
          }
          mkIf (peerConnection.endpoint ? dynamicEndpointRefreshSeconds) {
            dynamicEndpointRefreshSeconds = peerConnection.endpoint.dynamicEndpointRefreshSeconds;
          }
          mkIf (peerConnection.endpoint ? dynamicEndpointRefreshRestartSeconds) {
            dynamicEndpointRefreshRestartSeconds = peerConnection.endpoint.dynamicEndpointRefreshRestartSeconds;
          }
        ]);
      };}
    );
  };
}