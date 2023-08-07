
{config, lib, ...}: 
with lib.trivial;
with lib.attrsets;
with lib.lists;
with lib;
let
  # check whether or not agenix-rekey exists
  has-rekey = config ? rekey;
  # The remapper transforms the config in a way that makes filling out configs more easy
  remapper = import ./config-remapper.nix {inherit lib;} config.modules.wirenix.config;
  thisPeer = remapper.peerFromName config.wirenix.peerName;
  # these aren't really important, I just wanted to reverse the argument order
  forEachAttr = flip mapAttrs'; 
  forEachAttrToList = flip mapAttrsToList; 
in
{
  networking.wireguard = {
    interfaces = forEachAttr thisPeer.subnets (name: subnetConnection:  { name = "wg-${name}";
      value = {
        ips = [ subnetConnection.ip ];
        listenPort = subnetConnection.subnet.defaultPort;
        privateKeyFile = thisPeer.privateKeyFile;        
        peers = forEachAttrToList subnetConnection.peers (peerName: peerConnection: mkMerge [
          {
            name = peerName;
            publicKey = peerConnection.peer.publicKey;
            allowedIPs = [ peerConnection.ip ];
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