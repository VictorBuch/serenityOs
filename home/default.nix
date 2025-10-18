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
    ./terminals/kitty.nix
    ./terminals/ghostty.nix
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
    # Cross-platform applications
    home.terminals = {
      kitty.enable = lib.mkDefault true;
      ghostty.enable = lib.mkDefault true;
    };
  };
}
