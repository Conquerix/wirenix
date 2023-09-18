/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
{
  description = "A wireguard network creation tool";
  outputs = { self, nixpkgs, ... }:
  let
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
  in
  {
    wnlib = import ./lib.nix;
    nixosModules.default = import ./wire.nix;
    checks = forAllSystems (system: 
      let
        checkArgs = {
          # reference to nixpkgs for the current system
          pkgs = nixpkgs.legacyPackages.${system};
          # this gives us a reference to our flake but also all flake inputs
          inherit self;
        };
      in {
      # import our test
      null = import ./tests/null.nix checkArgs;
      simple = import ./tests/simple.nix checkArgs;
      mesh = import ./tests/mesh.nix checkArgs;
      ring = import ./tests/ring.nix checkArgs;
      manual-ipv4 = import ./tests/manual-ipv4.nix checkArgs;
      manual-ipv6 = import ./tests/manual-ipv6.nix checkArgs;
      manual-ipv6-auto = import ./tests/manual-ipv6-auto.nix checkArgs;
    });
  };
}
