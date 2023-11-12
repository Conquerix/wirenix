/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
{ config, lib, ... }@inputs: 
let wnlib = import ./lib.nix {inherit lib;}; in
with wnlib;
with lib;
let 
  cfg = config.wirenix;
  parsers = defaultParsers // cfg.additionalParsers;
  configurers = defaultConfigurers // cfg.additionalConfigurers;
  availableKeyProviders = defaultKeyProviders // cfg.additionalKeyProviders;
  acl = cfg.aclConfig;
  parser = parsers."${acl.version}" inputs;
  configurer = (getAttr cfg.configurer configurers) (inputs//{devNameMethod = cfg.devNameMethod;}); #config.wirenix.configurer inputs;
  keyProviders = map (providerName: getAttr providerName availableKeyProviders) cfg.keyProviders; # config.wirenix.keyProviders;
  mkMergeTopLevel = names: attrs: getAttrs names (
    mapAttrs (k: v: mkMerge v) (foldAttrs (n: a: [n] ++ a) [] attrs)
  );
  /** 
   *  We can merge if we want to
   *  We can leave your friends behind
   * 'Cause your friends don't merge and if they don't merge
   *  Well they're, no friends of mine.
   */
  safetyMerge = possibleTopLevelKeys: attrs: 
    (mkMergeTopLevel possibleTopLevelKeys ((singleton (genAttrs possibleTopLevelKeys (name: {})))++attrs));
in
{
  options = {
    age = {};
    sops = {};
    wirenix = {
      enable = mkEnableOption "wirenix";
      peerName = mkOption {
        default = config.system.name;
        defaultText = literalExpression "config.system.name";
        example = "bernd";
        type = with types; str;
        description = mdDoc ''
          Name of the peer using this module, to match the name in
          `wirenix.config.peers.*.name`
        '';
      };
      peerNames = mkOption {
        default = null;
        example = [ "container1" "container2" ];
        type = with types; nullOr (listOf str);
        description = mdDoc ''
          When one host needs multiple devs for the same subnet, specify
          multiple names manually. Overrides peerName.
        '';
      };
      configurer = mkOption {
        default = "static";
        type = types.str;
        description = mdDoc ''
          Configurer to use. Builtin values can be 
          "static" or "networkd". Or, you can put
          your own configurer that you registered in
          `additionalConfigurers` here.
        '';
      };
      keyProviders = mkOption {
        default = ["acl"];
        type = with types; listOf str;
        description = mdDoc ''
          List of key providers. Key providers will be queried in order.
          Builtin providers are `wirenix.lib.defaultKeyProviders.acl`
          and `wirenix.lib.defaultKeyProviders.agenix-rekey`. The latter
          requires the agenix-rekey flake.
        '';
      };
      additionalKeyProviders = mkOption {
        default = {};
        type = with types; unspecified;
        description = mdDoc ''
          Additional key providers to load, with their names being used to select them in the
          `keyProviders` option
        '';
      };
      additionalParsers = mkOption {
        default = {};
        type = with types; unspecified;
        description = mdDoc ''
          Additional parsers to load, with their names being used to compare to the acl's
          "version" field.
        '';
      };
      additionalConfigurers = mkOption {
        default = {};
        type = with types; unspecified;
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
      devNameMethod = mkOption {
        default = "short";
        type = with types; strMatching "hash|long|short";
        description = mdDoc ''
          The method used to derive device names. Device names are limited to 15 characters,
          but often times subnet names will exceed that. "hash" is the most reliable, and
          will always create a name unique to the subnet and peer combination. "long" will
          return the entire subnet, and "short" will return the beginning of the subnet up
          until the first "." character.
        '';
      };
    };
  };
  
  # --------------------------------------------------------------- #
  # Due to merge weirdness, I have to define what configuration keys
  # we're touching upfront, and make sure they exist
  config = 
  mkIf cfg.enable (safetyMerge ["networking" "sops" "age" "systemd" "services" "environment"] (
    if builtins.typeOf cfg.peerNames == "null" then (
      [(configurer keyProviders (parser acl) cfg.peerName)]
    )
    else (
      warnIf (cfg.devNameMethod != "hash") "Wirenix: Using multiple peerNames for devNameMethod = \"${cfg.devNameMethod}\" can (will) cause device name collisions. Please use devNameMethod = \"hash\" instead" (
      warnIf (cfg.configurer == "static") "Wirenix: static configurer not supported with multiple peerNames. Please use networkd or networkd-dev-only instead." (
        (map (name: (configurer keyProviders (parser acl) name)) cfg.peerNames)
      ))
    )
  ));
}