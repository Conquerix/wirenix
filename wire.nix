{ config, lib, ... }@inputs: 
with lib;
with import ./lib.nix;
with builtins;
let 
  cfg = config.wirenix;
  parsers = defaultParsers // cfg.additionalParsers;
  configurers = defaultConfigurers // cfg.additionalConfigurers;
  availableKeyProviders = defaultKeyProviders // cfg.additionalKeyProviders;
  acl = cfg.aclConfig;
  parser = parsers."${acl.version}" inputs;
  configurer = (getAttr cfg.configurer configurers) inputs; #config.wirenix.configurer inputs;
  keyProviders = map (providerName: getAttr providerName availableKeyProviders) cfg.keyProviders; # config.wirenix.keyProviders;
  mkMergeTopLevel = names: attrs: attrsets.getAttrs names (
    mapAttrs (k: v: mkMerge v) (attrsets.foldAttrs (n: a: [n] ++ a) [] attrs)
  );
  /** 
   *  We can merge if we want to
   *  We can leave your friends behind
   * 'Cause your friends don't merge and if they don't merge
   *  Well they're, no friends of mine.
   */
  safetyMerge = possibleTopLevelKeys: attrs: 
    (mkMergeTopLevel possibleTopLevelKeys ((lists.singleton (attrsets.genAttrs possibleTopLevelKeys (name: {})))++attrs));
in
{
  options = {
    wirenix = {
      enable = mkEnableOption "wirenix";
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
        default = "static";
        type = types.str;
        description = mdDoc ''
          Configurer to use. Builtin values can be 
          "static" "networkd" or "network-manager"
          Or you can put your own configurer here.
        '';
      };
      keyProviders = mkOption {
        default = ["acl"];
        type = with types; listOf str;
        defaultText = literalExpression "[ "acl" ]";
        description = mdDoc ''
          List of key providers. Key providers will be queried in order.
          Builtin providers are `wirenix.lib.defaultKeyProviders.acl`
          and `wirenix.lib.defaultKeyProviders.agenix-rekey`. The latter
          requires the agenix-rekey flake.
        '';
      };
      additionalKeyProviders = mkOption {
        default = {};
        type = with types; attrsOf (functionTo attrs);
        description = mdDoc ''
          Additional key providers to load, with their names being used to select them in the
          `keyProviders` option
        '';
      };
      additionalParsers = mkOption {
        default = {};
        type = with types; attrsOf (functionTo attrs);
        description = mdDoc ''
          Additional parsers to load, with their names being used to compare to the acl's
          "version" field.
        '';
      };
      additionalConfigurers = mkOption {
        default = {};
        type = with types; attrsOf (functionTo attrs);
        description = mdDoc ''
          Additional configurers to load, with their names being used to select them in the
          `configurer` option.
        '';
      };
      aclConfig = mkOption {
        type = types.attrs;
        description = ''
          Shared configuration file that describes all clients
        '';
      };
      secretsDir = mkOption {
        default = null;
        type = with types; nullOr path;
        description = mdDoc ''
          If using a secrets manager, where you have wirenix secrets stored. Must be
          the same on all peers that need to connect to eachother
        '';
      };
    };
  };
  
  # --------------------------------------------------------------- #
  # Due to merge weirdness, I have to define what configuration keys
  # we're touching upfront, and make sure they exist
  config = (safetyMerge ["networking" "sops" "age" "systemd" "services" "environment"]
    [
      (configurer keyProviders (parser acl) cfg.peerName)
    ]
  );
}