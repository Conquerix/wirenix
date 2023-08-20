/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
let 
  sharedConfig = {
    wirenix = {
      enable = true;
      keyProviders = ["acl"];
      aclConfig = import ./acls/simple.nix;
    };
  };
in
(import ./lib.nix)
{
  name = "Null test, should always pass";
  nodes = {
    # `self` here is set by using specialArgs in `lib.nix`
    node1 = { self, pkgs, ... }: sharedConfig // {
      imports = [ self.nixosModules.default ];      
      wirenix = {
        enable = true;
        keyProviders = ["acl"];
        peerName = "peer1";
        aclConfig = import ./acls/simple.nix;
      };
      networking.interfaces.eth1.ipv4.addresses = [
        {
          address = "192.168.1.2";
          prefixLength = 24;
        }
      ];
      environment.systemPackages = [ pkgs.curl ];
    };
    
    node2 = { self, pkgs, ... }: sharedConfig // {
      imports = [ self.nixosModules.default ];      
      wirenix = {
        enable = true;
        keyProviders = ["acl"];
        peerName = "peer2";
        aclConfig = import ./acls/simple.nix;
      };
      networking.interfaces.eth1.ipv4.addresses = [
        {
          address = "192.168.1.3";
          prefixLength = 24;
        }
      ];
      environment.systemPackages = [ pkgs.curl ];
    };
  };
  # This is the test code that will check if our service is running correctly:
  testScript = ''
    start_all()
    node1.wait_for_unit("wireguard-simple")
    node2.wait_for_unit("wireguard-simple")
    output = node1.succeed("ping -c 1 peer2.simple")
    # Check if our webserver returns the expected result
    assert "Hello world" in output, f"'{output}' does not contain 'Hello world'"
  '';
}