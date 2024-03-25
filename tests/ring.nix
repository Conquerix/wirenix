/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
(import ./lib.nix) ({wnlib}:
{
  name = "ring connection";
  nodes = {
    # `self` here is set by using specialArgs in `lib.nix`
    node1 = { self, pkgs, ... }: {
      virtualisation.vlans = [ 1 ];
      imports = [ self.nixosModules.default ];      
      wirenix = {
        enable = true;
        aclConfig = import ./acls/ring.nix;
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
        aclConfig = import ./acls/ring.nix;
      };
      environment.etc."wg-key" = {
        text = "yG4mJiduoAvzhUJMslRbZwOp1gowSfC+wgY8B/Mul1M=";
      };
      networking.firewall.enable = false;
    };
    
    node3 = { self, pkgs, ... }: {
      virtualisation.vlans = [ 1 ];
      imports = [ self.nixosModules.default ];      
      wirenix = {
        enable = true;
        keyProviders = ["acl"];
        peerName = "node3";
        aclConfig = import ./acls/ring.nix;
      };
      environment.etc."wg-key" = {
        text = "yPcTvQOK9eVXQjLNapOsv2iAkbOeSzCCxlrWPMe1o0g=";
      };
      networking.firewall.enable = false;
    };
    
    node4 = { self, pkgs, ... }: {
      virtualisation.vlans = [ 1 ];
      imports = [ self.nixosModules.default ];      
      wirenix = {
        enable = true;
        keyProviders = ["acl"];
        peerName = "node4";
        aclConfig = import ./acls/ring.nix;
      };
      environment.etc."wg-key" = {
        text = "CLREBQ+oGXsGxhlQc3ufSoBd7MNFoM6KmMnNyuQ9S0E=";
      };
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
    connections = {
      "node1": ["node2", "node4"],
      "node2": ["node3", "node1"],
      "node3": ["node4", "node2"],
      "node4": ["node1", "node3"]
    }
    for local_name, local_node in nodes.items():
      for remote_name in connections[local_name]:
        local_node.wait_for_unit(f"wireguard-ring-peer-{remote_name}")
    node1.wait_for_unit("wireguard-ring.target")
    node2.wait_for_unit("wireguard-ring.target")
    node3.wait_for_unit("wireguard-ring.target")
    node4.wait_for_unit("wireguard-ring.target")
    for local_name, local_node in nodes.items():
      local_node.succeed("wg showconf ring >&2")
      for remote_name in set(nodes.keys()) - set([local_name]):
        local_node.succeed(f"ping -c 1 {remote_name} >&2")
        if remote_name in connections[local_name]:
          local_node.succeed(f"ping -c 1 {remote_name}.ring >&2")
        else:
          local_node.fail(f"ping -c 1 -W 1 {remote_name}.ring")
  '';
})