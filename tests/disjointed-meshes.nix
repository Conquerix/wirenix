/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
(import ./lib.nix) ({wnlib}:
{
  name = "disjointed-meshes connection";
  nodes = {
    # `self` here is set by using specialArgs in `lib.nix`
    node1 = { self, pkgs, ... }: {
      virtualisation.vlans = [ 1 ];
      imports = [ self.nixosModules.default ];
      wirenix = {
        enable = true;
        keyProviders = ["acl"];
        peerName = "node1";
        aclConfig = import ./acls/disjointed-meshes.nix;
      };
      # Don't do this! This is for testing only!
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
        peerName = "node2";
        aclConfig = import ./acls/disjointed-meshes.nix;
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
        aclConfig = import ./acls/disjointed-meshes.nix;
      };
      environment.etc."wg-key" = {
        text = "MFsj7nmb2efBFNwON8RxZf+MHbopTY9P3+/xhiqJFlM=";
      };
      networking.firewall.enable = false;
    };
  };
  # This is the test code that will check if our service is running correctly:
  testScript = ''
    start_all()
    node1.wait_for_unit("wireguard-disjoint1-peer-node2")
    node2.wait_for_unit("wireguard-disjoint1-peer-node1")
    node2.wait_for_unit("wireguard-disjoint2-peer-node3")
    node3.wait_for_unit("wireguard-disjoint2-peer-node2")

    node1.succeed("wg show >&2")
    node2.succeed("wg show >&2")
    node3.succeed("wg show >&2")

    node1.succeed("ping -c 1 node2.disjoint1")
    node1.fail("ping -c 1 node3.disjoint2")

    node2.succeed("ping -c 1 node1.disjoint1")
    node2.succeed("ping -c 1 node3.disjoint2")

    node3.fail("ping -c 1 node1.disjoint1")
    node3.succeed("ping -c 1 node2.disjoint2")
  '';
})