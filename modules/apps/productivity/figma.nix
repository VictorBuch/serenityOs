args@{
  mkModule,
  ...
}:

mkModule {
  name = "figma";
  category = "productivity";
  packages =
    { pkgs, lib, platform, ... }:
    lib.optionals (platform == "linux") [ pkgs.figma-linux ];
  casks = [ "figma" ];
  description = "Figma";
} args
