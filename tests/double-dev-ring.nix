/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
(import ./lib.nix) ({wnlib}:
{
  name = "double dev ring connection";
  nodes = {
    # `self` here is set by using specialArgs in `lib.nix`
    node1 = { self, pkgs, ... }: {
      virtualisation.vlans = [ 1 ];
      imports = [ self.nixosModules.default ];      
      systemd.network.enable = true;
      wirenix = {
        configurer = "networkd";
        devNameMethod = "hash";
        enable = true;
        aclConfig = import ./acls/double-dev-ring.nix;
        peerNames = ["peer1" "peer3"];
      };
      environment.etc."wg-key1" = {
        text = "MIELhEc0I7BseAanhk/+LlY/+Yf7GK232vKWITExnEI=";
      };
      environment.etc."wg-key3" = {
        text = "yPcTvQOK9eVXQjLNapOsv2iAkbOeSzCCxlrWPMe1o0g=";
      };
      environment.systemPackages = [pkgs.wireguard-tools];
      networking.firewall.enable = false;
    };
    
    node2 = { self, pkgs, ... }: {
      virtualisation.vlans = [ 1 ];
      imports = [ self.nixosModules.default ];
      systemd.network.enable = true;
      wirenix = {
        configurer = "networkd";
        devNameMethod = "hash";
        enable = true;
        keyProviders = ["acl"];
        aclConfig = import ./acls/double-dev-ring.nix;
        peerNames = ["peer2" "peer4"];
      };
      environment.etc."wg-key2" = {
        text = "yG4mJiduoAvzhUJMslRbZwOp1gowSfC+wgY8B/Mul1M=";
      };
      environment.etc."wg-key4" = {
        text = "CLREBQ+oGXsGxhlQc3ufSoBd7MNFoM6KmMnNyuQ9S0E=";
      };
      environment.systemPackages = [pkgs.wireguard-tools];
      networking.firewall.enable = false;
    };
  };
  # This is the test code that will check if our service is running correctly:
  testScript = ''
    start_all()
    nodes = {
      "peer1": node1,
      "peer2": node2,
      "peer3": node1,
      "peer4": node2
    }
    ifaces = {
      "peer1": "${wnlib.getDevName "hash" "peer1" "ring"}",
      "peer2": "${wnlib.getDevName "hash" "peer2" "ring"}",
      "peer3": "${wnlib.getDevName "hash" "peer3" "ring"}",
      "peer4": "${wnlib.getDevName "hash" "peer4" "ring"}"
    }
    connections = {
      "peer1": ["peer2", "peer4"],
      "peer2": ["peer3", "peer1"],
      "peer3": ["peer4", "peer2"],
      "peer4": ["peer1", "peer3"]
    }
    node1.wait_for_unit("systemd-networkd-wait-online")
    node2.wait_for_unit("systemd-networkd-wait-online")
    node1.succeed("ping -c 3 node2 >&2")
    node2.succeed("ping -c 3 node1 >&2")
    for local_name, local_node in nodes.items():
      for remote_name in set(nodes.keys()) - set([local_name]):
        if remote_name in connections[local_name]:
          local_node.succeed(f"ping -c 3 -I {ifaces[local_name]} {remote_name}.ring >&2")
        else:
          local_node.fail(f"ping -c 3 -W 1 -I {ifaces[local_name]} {remote_name}.ring")
  '';
})