{ config, lib, pkgs, ... }: 
with lib;
let
  has-rekey = config ? rekey;
  peerOpts = {
    options = {
      subnets = mkOption {
        default = [];
        type = with types; listOf str;
        description = ''
          subnets the peer belongs to
        '';
      };
      groups = mkOption {
        default = true;
        type = with types; listOf str;
        description = ''
          groups the peer belongs to
        '';
      };
      peers = {
        default = true;
        type = with types; listOf set;
        description = mdDoc ''
          Peers the peer is connected to, can be one of `{ peer = "peerName"; }`
          or `{ group = "groupname"; }`. Remember to configure this for *both* peers.
          The best way to do this is with a simple full mesh network, where all peers
          belong to one group ("groupA"), and their peers are `{ group = "groupA"}`.
          '';
      };
      privateKeyFile = mkOption {
        example = "/private/wireguard_key";
        type = with types; nullOr str;
        default = null;
        description = mdDoc ''
          Private key file as generated by {command}`wg genkey`.
        '';
      };
      name = mkOption {
        default = config.networking.hostName;
        defaultText = literalExpression "hostName";
        example = "bernd";
        type = types.str;
        description = mdDoc "Unique name for the peer (must be unique for all subdomains this peer is a member of)";
      };
      publicKey = mkOption {
        example = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
        type = types.singleLineStr;
        description = mdDoc "The base64 public key of the peer.";
      };
      presharedKeyFile = mkOption {
        default = null;
        example = "/private/wireguard_psk";
        type = with types; nullOr str;
        description = mdDoc ''
          File pointing to preshared key as generated by {command}`wg genpsk`.
          Optional, and may be omitted. This option adds an additional layer of
          symmetric-key cryptography to be mixed into the already existing
          public-key cryptography, for post-quantum resistance.
        '';
      };
    };
  };
  subnetOpts = {
    options = {
      name = mkOption {
        default = "wireguard";
        example = "mySubnet.myDomain.me";
        type = types.str;
        description = mdDoc "Unique name for the subnet";
      };
    };
  };
  configOpts = {
    options = {
      subnets = mkOption {
        default = {};
        type = with types; listOf (submodule subnetOpts);
        description = ''
          Shared configuration file that describes all clients 
        '';
      };
      peers = mkOption {
        default = {};
        type = with types; listOf (submodule peerOpts);
        description = ''
          Shared configuration file that describes all clients 
        '';
      };
    };
  };
in
{
  options = {
    modules.wirenix = {
      enable = mkOption {
        default = true;
        type = with lib.types; bool;
        description = ''
          Wirenix
        '';
      };
      config = mkOption {
        default = {};
        type = with types; setOf (submodule configOpts);
        description = ''
          Shared configuration file that describes all clients
        '';
      };
    };
  };
  
  # --------------------------------------------------------------- #
  
  config = lib.mkIf (config.modules.wirenix.enable) (lib.mkMerge [
    (lib.mkIf (has-rekey) {
      environment.etc.rekey.text = "yes";
    })
    (lib.mkIf (!has-rekey ) {
      environment.etc.rekey.text = "no";
    })
  ]);
}