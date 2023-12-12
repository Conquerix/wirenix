/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
{config, lib, ...}: intermediateConfig: localPeerName:
let wnlib = import ../lib.nix {inherit lib;}; in
with wnlib;
with lib;
{
  config.age = {
    secrets = {
      "wirenix-peer-${localPeerName}" = {
        owner = "root";
        mode = "640";
        group = if (builtins.match ".*networkd.*" config.wirenix.configurer != null) then "systemd-network" else "root";
        rekeyFile = config.wirenix.secretsDir + /wirenix-peer- + localPeerName + ".age";
        generator.script = {pkgs, file, ...}: ''
          priv=$(${pkgs.wireguard-tools}/bin/wg genkey)
          ${pkgs.wireguard-tools}/bin/wg pubkey <<< "$priv" > ${lib.escapeShellArg (lib.removeSuffix ".age" file + ".pub")}
          echo "$priv"
        '';
      };
    } // 
    mapAttrs' (name: value: nameValuePair ("wirenix-subnet-${name}") {
        owner = "root";
        mode = "640";
        group = if (builtins.match ".*networkd.*" config.wirenix.configurer != null) then "systemd-network" else "root";
        rekeyFile = config.wirenix.secretsDir + /wirenix-subnet- + name + ".age";
        generator.script = {pkgs, ...}: ''
          psk=$(${pkgs.wireguard-tools}/bin/wg genpsk)
          echo "$psk"
        '';
      }) intermediateConfig.peers."${localPeerName}".subnetConnections;  
    };
  getPeerPubKey    = remotePeerName: builtins.readFile (config.wirenix.secretsDir + /wirenix-peer-${remotePeerName}.pub);
  getPrivKeyFile   = config.age.secrets."wirenix-peer-${localPeerName}".path;
  getSubnetPSKFile = subnetName: config.age.secrets."wirenix-subnet-${subnetName}".path;
}