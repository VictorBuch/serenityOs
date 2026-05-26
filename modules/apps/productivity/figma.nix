args@{
  mkModule,
  ...
}:

mkModule {
  name = "figma";
  category = "productivity";
  linuxPackages = { pkgs, ... }: [ pkgs.figma-linux ];
  casks = [ "figma" ];
  description = "Figma";
} args
