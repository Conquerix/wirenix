{
  description = "Do we have agnenix-rekey?";

  outputs = { self, ... }:
  {
    wirenix.lib = import ./lib.nix;
    nixosModules.default = import ./wire.nix;
  };
}
