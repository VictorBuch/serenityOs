{
  flake.modules.nixos.craft-apps =
    { pkgs, lib, ... }:
    {
      environment.systemPackages = lib.filter lib.isDerivation (builtins.attrValues pkgs.craft-apps);
    };
}
