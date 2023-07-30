{
  description = "Do we have agnenix-rekey?";

  outputs = { self, ... }:
  {
      nixosModules.myModule = import ./wire.nix;
  };
}
