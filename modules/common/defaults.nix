# Default enable values for common modules
let
  module =
    { lib, ... }:
    {
      fonts.enable = lib.mkDefault true;
      nh.enable = lib.mkDefault true;
      yubikey.enable = lib.mkDefault true;
    };
in
{
  flake.modules.nixos.base = module;
  flake.modules.darwin.base = module;
}
