/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
(import ./lib.nix) {
  name = "null test";
  nodes = {
    # `self` here is set by using specialArgs in `lib.nix`
    node1 = { self, pkgs, ... }: {
      imports = [ self.nixosModules.default ];      
      wirenix.enable = false;
    };
  };
  # This is the test code that will check if our service is running correctly:
  testScript = ''
    start_all()
    output = node1.succeed("echo Hello world")
    # Check if our webserver returns the expected result
    assert "Hello world" in output, f"'{output}' does not contain 'Hello world'"
  '';
}