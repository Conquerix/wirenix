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
  keyProvidersInit = map (x: x inputs intermediateConfig peerName) keyProviders;
  getPeerPubKey = otherPeerName: findFirst (x: x != null) (throw "Wirenix: Could not find public key for " + otherPeerName)
    (map (provider: provider.getPeerPubKey otherPeerName) keyProvidersInit);
  getPrivKeyFile = getPrivKeyFile (x: x != null) (throw "Wirenix: Could not find private key file for " + peerName)
    (map (provider: provider.getPrivKeyFile) keyProvidersInit);
  getPubKey = findFirst (x: x != null) (throw "Wirenix: Could not find public key for " + peerName)
    (map (provider: provider.getPubKey) keyProvidersInit);
  getSubnetPSKFile = subnetName: findFirst (x: x != null) (null)
    (map (provider: provider.getSubnetPSKFile subnetName) keyProvidersInit);
in
{
  networking.wireguard = {
    interfaces = forEachAttr' thisPeer.subnetConnections (subnetName: subnetConnection:  { name = "wn-${subnetName}";
      value = {
        ips = subnetConnection.ipAddresses;
        listenPort = subnetConnection.listenPort;
        privateKeyFile = getPrivKeyFile;        
        peers = forEachAttrToList subnetConnection.peerConnections (otherPeerName: peerConnection: 
          {
            name = otherPeerName;
            publicKey = getPeerPubKey otherPeerName;
            presharedKeyFile = getSubnetPSKFile subnetName;
            allowedIPs = peerConnection.ipAddresses;
            endpoint = "${peerConnection.endpoint.ip}:${builtins.toString peerConnection.endpoint.port}";
          }
          // (mergeIf peerConnection.endpoint "persistentKeepalive")
          // (mergeIf peerConnection.endpoint "dynamicEndpointRefreshSeconds")
          // (mergeIf peerConnection.endpoint "dynamicEndpointRefreshRestartSeconds")
        );
      };}
    );
  };
}