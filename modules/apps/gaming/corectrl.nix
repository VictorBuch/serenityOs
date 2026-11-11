{
  flake.modules.nixos.corectrl =
    { ... }:
    {
      programs.corectrl.enable = true;
    };
}
