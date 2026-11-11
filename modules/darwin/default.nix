{
  flake.modules.darwin.base =
    { lib, ... }:
    {
      darwin.homebrew.enable = lib.mkDefault true;
    };
}
