{
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./home.nix
    ./wallpaper-pool.nix
    ./live-seams.nix
    ./window-rules.nix
  ];

  options = {
    wallpaper = lib.mkOption {
      type = lib.types.path;
      # Build-time fallback for consumers that need a fixed path (stylix's
      # base16 source image, wlogout's background). The live desktop wallpaper
      # and palette come from noctalia's pool in ./wallpapers, which rotates at
      # runtime and never passes through this option.
      default = "${inputs.wallpapers-nord}/bg8.jpg";
      description = "Path to the wallpaper used across modules.";
    };
  };
}
