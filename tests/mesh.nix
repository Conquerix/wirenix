/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
(import ./lib.nix) ({wnlib}:
{
  name = "mesh connection";
  nodes = {
    # `self` here is set by using specialArgs in `lib.nix`
    node1 = { self, pkgs, ... }: {
      virtualisation.vlans = [ 1 ];
      imports = [ self.nixosModules.default ];      
      wirenix = {
        enable = true;
        aclConfig = import ./acls/mesh.nix;
      };
      environment.etc."wg-key" = {
        text = "MIELhEc0I7BseAanhk/+LlY/+Yf7GK232vKWITExnEI=";
      };
      networking.firewall.enable = false;
    };
    
    node2 = { self, pkgs, ... }: {
      virtualisation.vlans = [ 1 ];
      imports = [ self.nixosModules.default ];      
      wirenix = {
        enable = true;
        keyProviders = ["acl"];
        aclConfig = import ./acls/mesh.nix;
      };
      environment.etc."wg-key" = {
        text = "yG4mJiduoAvzhUJMslRbZwOp1gowSfC+wgY8B/Mul1M=";
      };
      networking.firewall.enable = false;
    };
    
    node3 = { self, pkgs, ... }: {
      virtualisation.vlans = [ 1 ];
      imports = [ self.nixosModules.default ];      
      systemd.network.enable = true;
      networking.useDHCP = false;
      wirenix = {
        enable = true;
        configurer = "networkd";
        keyProviders = ["acl"];
        peerName = "node3";
        aclConfig = import ./acls/mesh.nix;
      };
      environment.etc."wg-key" = {
        text = "yPcTvQOK9eVXQjLNapOsv2iAkbOeSzCCxlrWPMe1o0g=";
        mode = "0640";
        user = "root";
        group = "systemd-network";
      };
      environment.systemPackages = [pkgs.wireguard-tools];
      networking.firewall.enable = false;
    };
    
    node4 = { self, pkgs, ... }: {
      virtualisation.vlans = [ 1 ];
      imports = [ self.nixosModules.default ];      
      systemd.network.enable = true;
      networking.useDHCP = false;
      wirenix = {
        enable = true;
        configurer = "networkd";
        keyProviders = ["acl"];
        peerName = "node4";
        aclConfig = import ./acls/mesh.nix;
      };
      environment.etc."wg-key" = {
        text = "CLREBQ+oGXsGxhlQc3ufSoBd7MNFoM6KmMnNyuQ9S0E=";
        mode = "0640";
        user = "root";
        group = "systemd-network";
      };
      environment.systemPackages = [pkgs.wireguard-tools];
      networking.firewall.enable = false;
    };
  };
  # This is the test code that will check if our service is running correctly:
  testScript = ''
    start_all()
    nodes = {
      "node1": node1,
      "node2": node2,
      "node3": node3,
      "node4": node4
    }
    for local_name, local_node in nodes.items():
      if local_name == "node1" or local_name == "node2":
        for remote_node in set(nodes.keys()) - set([local_name]):
          local_node.wait_for_unit(f"wireguard-mesh-peer-{remote_node}")
    node1.wait_for_unit("wireguard-mesh.target")
    node2.wait_for_unit("wireguard-mesh.target")
    node3.wait_for_unit("systemd-networkd-wait-online")
    node4.wait_for_unit("systemd-networkd-wait-online")
    for local_name, local_node in nodes.items():
      for remote_name in set(nodes.keys()) - set([local_name]):
        local_node.succeed(f"ping -c 1 {remote_name} >&2")
        local_node.succeed(f"ping -c 1 {remote_name}.mesh >&2")
  '';
})