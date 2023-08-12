{ config, lib, ... }@inputs: 
with lib;
with import ./lib.nix;
{
options = {
    wirenix = {
      enable = mkOption {
        default = true;
        type = with lib.types; bool;
        description = ''
          Wirenix
        '';
      };
      secretsDir = mkOption {
        type = types.path;
        description = mdDoc ''
          where you want the wireguard secrets stored.
        '';
      };
    };
  };
 config =
  let
    configurers = defaultConfigurers // config.modules.wirenix.additionalConfigurers;
    parsers = defaultParsers // config.modules.wirenix.additionalParsers;
    acl = config.modules.wirenix.aclConfig;
    parser = parsers."${acl.version}" inputs;
    configurer = configurers."${config.modules.wirenix.configurer}" inputs;
    nixosConfigForPeer = peerName: builtins.head (builtins.attrValues (
      lib.attrsets.filterAttrs (
        name: value: (lib.attrsets.attrByPath ["config" "modules" "wirenix" "peerName"] null value) == peerName
      ) nixosConfigurations));
  in
  lib.mkIf (config.modules.wirenix.enable) 
    configurer (parser acl) config.modules.wirenix.peerName;
}