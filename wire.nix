{ config, lib, ... }@inputs: 
with lib;
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
      peerName = mkOption {
        default = config.networking.hostName;
        defaultText = literalExpression "hostName";
        example = "bernd";
        type = types.str;
        description = mdDoc ''
          Name of the peer using this module, to match the name in
          `wirenix.config.peers.*.name`
        '';
      };
      configurer = mkOption {
        default = "auto";
        type = types.str;
        description = mdDoc ''
          Configurer to use. Builtin values can be "auto", "networkmanager", or "networkd".
          See the `additionalConfigurers` for adding more options.
        '';
      };
      additionalConfigurers = mkOption {
        default = "auto";
        type = with types; attrsOf (functionTo attrset);
        description = mdDoc ''
          Additional configurers to load, with their names being used to select from the
          configurer option.
        '';
      };
      additionalParsers = mkOption {
        default = "auto";
        type = with types; attrsOf (functionTo attrset);
        description = mdDoc ''
          Additional parsers to load, with their names being used to compare to the acl's
          "version" feild.
        '';
      };
      aclConfig = mkOption {
        default = {};
        type = types.attrset;
        description = ''
          Shared configuration file that describes all clients
        '';
      };
    };
  };
  
  # --------------------------------------------------------------- #
  
  config =
  let
    configurers = rec {
      auto = static;
      static = import ./configurers/static.nix;
      networkd = import ./configurers/networkd.nix;
      networkmanager = import ./configurers/networkmanager.nix;
    } // config.modules.wirenix.additionalConfigurers;
    parsers = {
      v1 = import ./parsers/v1.nix;
    } // config.modules.wirenix.additionalParsers;
    acl = config.modules.wirenix.aclConfig;
    parser = parsers."${acl.version}" inputs;
    configurer = configurers."${config.modules.wirenix.configurer}" inputs;
  in
  lib.mkIf (config.modules.wirenix.enable) 
    configurer (parser acl);
}