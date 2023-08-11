{lib, ...}: intermediateConfig: peerName:
with lib.trivial;
with lib.attrsets;
with lib.lists;
with lib;
let
  thisPeer = intermediateConfig.peers."${peerName}";
  # these aren't really important, I just wanted to reverse the argument order
  forEachAttr' = flip mapAttrs'; 
  forEachAttrToList = flip mapAttrsToList; 
  mergeIf = attr: key: if builtins.hasAttr key attr then {"${key}" = attr."${key}";} else {};
in
{
  networking.wireguard = {
    interfaces = forEachAttr' thisPeer.subnetConnections (name: subnetConnection:  { name = "wg-${name}";
      value = {
        ips = subnetConnection.ipAddresses;
        listenPort = subnetConnection.listenPort;
        privateKeyFile = thisPeer.privateKeyFile;        
        peers = forEachAttrToList subnetConnection.peerConnections (peerName: peerConnection: 
          {
            name = peerName;
            publicKey = peerConnection.peer.publicKey;
            allowedIPs = peerConnection.ipAddresses;
            endpoint = "${peerConnection.endpoint.ip}:${builtins.toString peerConnection.endpoint.port}";
          } //
          (mergeIf peerConnection.endpoint "persistentKeepalive") //
          (mergeIf peerConnection.endpoint "dynamicEndpointRefreshSeconds") //
          (mergeIf peerConnection.endpoint "dynamicEndpointRefreshRestartSeconds")
        );
      };}
    );
  };
}