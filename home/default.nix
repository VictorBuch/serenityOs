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
      # Night wallpaper of the dynamic day/night pair, so static consumers
      # (wlogout, lock background, stylix fallback image) match the desk at
      # night. The live desktop palette itself comes from noctalia's wallpaper
      # engine, not this option.
      default = ./wallpapers/night/cloudsnight.jpg;
      description = "Path to the wallpaper used across modules.";
    };
  };
}
