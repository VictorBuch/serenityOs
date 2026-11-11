{
  flake.modules.nixos.logitech =
    { ... }:
    {
      programs.solaar.enable = true;
    };
}
