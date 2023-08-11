{
  description = "A wireguard network creation tool";
  outputs = { self, ... }:
  {
    wirenix.lib = import ./lib.nix;
    nixosModules.default = import ./wire.nix;
  };
}
