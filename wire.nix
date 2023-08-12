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
        default = defaultConfigurers.static;
        defaultText = literalExpression "wirenix.lib.defaultConfigurers.static";
        type = with types;  functionTo (functionTo (functionTo (functionTo attrset)));
        description = mdDoc ''
          Configurer to use. Builtin values can be 
          `wirenix.lib.defaultConfigurers.static`
          `wirenix.lib.defaultConfigurers.networkd` or
          `wirenix.lib.defaultConfigurers.network-manager`
          Or you can put your own configurer here.
        '';
      };
      keyProviders = mkOption {
        default = [defaultKeyProviders.acl];
        type = with types; listOf (functionTo attrset);
        defaultText = literalExpression "[ wirenix.lib.defaultKeyProviders.acl ]";
        description = mdDoc ''
          List of key providers. Key providers will be queried in order.
          Builtin providers are `wirenix.lib.defaultKeyProviders.acl`
          and `wirenix.lib.defaultKeyProviders.agenix-rekey`. The latter
          requires the agenix-rekey flake.
        '';
      };
      additionalParsers = mkOption {
        type = with types; attrsOf (functionTo attrset);
        description = mdDoc ''
          Additional parsers to load, with their names being used to compare to the acl's
          "version" field.
        '';
      };
      aclConfig = mkOption {
        default = {};
        type = types.attrset;
        description = ''
          Shared configuration file that describes all clients
        '';
      };
      secretsDir = mkOption {
        type = types.path;
        description = mdDoc ''
          If using a secrets manager, where you have wireguard secrets stored for the client.
        '';
      };
      subnetSecretsDir = mkOption {
        type = types.path;
        description = mdDoc ''
          If using a secrets manager, where you have wireguard secrets stored for subnets.
          Needs to be the same on all clients.
        '';
      };
    };
  };
  
  # --------------------------------------------------------------- #
  
  config =
  let
    parsers = defaultParsers // config.modules.wirenix.additionalParsers;
    acl = config.modules.wirenix.aclConfig;
    parser = parsers."${acl.version}" inputs;
    configurer =  config.modules.wirenix.configurer inputs;
    keyProviders =  config.modules.wirenix.keyProviders;
  in
  lib.mkIf (config.modules.wirenix.enable) 
    configurer (parser acl) keyProviders config.modules.wirenix.peerName;
}