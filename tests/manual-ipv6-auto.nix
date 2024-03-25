/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
(import ./lib.nix) ({wnlib}:
{
  name = "explicit auto ipv6 connection";
  nodes = {
    # `self` here is set by using specialArgs in `lib.nix`
    node1 = { self, pkgs, ... }: {
      virtualisation.vlans = [ 1 ];
      imports = [ self.nixosModules.default ];      
      wirenix = {
        enable = true;
        keyProviders = ["acl"];
        peerName = "node1";
        aclConfig = import ./acls/manual-ipv6-auto.nix;
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
        peerName = "node2";
        aclConfig = import ./acls/manual-ipv6-auto.nix;
      };
      environment.etc."wg-key" = {
        text = "yG4mJiduoAvzhUJMslRbZwOp1gowSfC+wgY8B/Mul1M=";
      };
      networking.firewall.enable = false;
    };
  };
  # This is the test code that will check if our service is running correctly:
  testScript = ''
    start_all()
    node1.wait_for_unit("wireguard-manual-peer-node2")
    node2.wait_for_unit("wireguard-manual-peer-node1")
    node1.succeed("ping -c 1 node2 >&2")
    node1.succeed("wg show >&2")
    node2.succeed("ping -c 1 node1 >&2")
    node2.succeed("wg show >&2")
    node1.succeed("ping -c 1 node2.manual")
    node2.succeed("ping -c 1 node1.manual")
  '';
})
