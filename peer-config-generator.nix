
{config, lib, ...}: 
let
  has-rekey = config ? rekey;
  infoRemapper = import ./config-remapper.nix {inherit lib;} config.modules.wirenix.config;
in
{
  
}