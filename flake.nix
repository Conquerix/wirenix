{
  description = "Do we have agnenix-rekey?";

  outputs = { self, ... }:
  {
    lib = import ./lib.nix;
    nixosModules.myModule = import ./wire.nix;
  };
}
