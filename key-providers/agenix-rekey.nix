{config, nixosConfigurations, lib, ...}: intermediateConfig: peerName:
with (import ../lib.nix);
with lib.attrsets;
with builtins;
let secretsDir = peerName: (nixosConfigForPeer nixosConfigurations peerName).config.modules.wirenix.secrestsDir; in
{
  config = {
    age.generators.wireguard-priv = {pkgs, file, ...}: ''
      priv=$(${pkgs.wireguard-tools}/bin/wg genkey)
      ${pkgs.wireguard-tools}/bin/wg pubkey <<< "$priv" > ${lib.escapeShellArg (lib.removeSuffix ".age" file + ".pub")}
      echo "$priv"
    '';
    age.generators.wireguard-psk = {pkgs, file, ...}: ''
      psk=$(${pkgs.wireguard-tools}/bin/wg genpsk)
      echo "$psk"
    '';
    age.secrets = {
    age.secrets = {
      "wirenix-peer-${peerName}" = {
        rekeyFile = config.modules.wirenix.secretsDir + /wirenix- + peerName + ".age";
        generator.script = "wireguard-priv";
      };
    } // mapAttrs' (name: value: nameValuePair ("wirenix-subnet-${name}") {
      rekeyFile = config.modules.wirenix.subnetSecretsDir + /wirenix-subnet- + name + ".age";
      generator.script = "wireguard-psk";
    }) intermediateConfig.peers."${peerName}".subnetConnections;
    
  };
  getPeerPubKey    = otherPeerName: lib.removeSuffix ".age" ((secretsDir otherPeerName).config.secrets."wirenix-peer-${peerName}".path) + ".pub";
  getPrivKeyFile   = config.age.secrets."wirenix-peer-${peerName}".path;
  getPubKey        = lib.removeSuffix ".age" (config.age.secrets."wirenix-peer-${peerName}".path) + ".pub";
  getSubnetPSKFile = subnetName: config.age.secrets."wirenix-subnet-${subnetName}".path;
}