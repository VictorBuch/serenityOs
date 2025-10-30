{
  pkgs,
  lib,
  isLinux,
  ...
}:

{
  imports = [
    ./home.nix
    ./cli
    ./terminals
  ]
  ++ lib.optionals isLinux [
    ./nixos
  ];

  options = {
    wallpaper = lib.mkOption {
      type = lib.types.path;
      default = ./wallpapers/dark-hole.png;
      description = "Path to the wallpaper used across modules.";
    };
  };

  config = {
    home.cli.enable = lib.mkDefault true;
    home.terminals.enable = lib.mkDefault true;
  };
}
