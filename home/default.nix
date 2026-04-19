{
  lib,
  ...
}:

{
  imports = [
    ./home.nix
  ];

  options = {
    wallpaper = lib.mkOption {
      type = lib.types.path;
      default = ./wallpapers/dark-hole.png;
      description = "Path to the wallpaper used across modules.";
    };
  };
}
