
{config, lib, ...}: 
let
  has-rekey = config ? rekey;
  infoRemapper = import ./peer-info-remapper.nix {inherit lib;} config.modules.wirenix.config;
in
{
  
}