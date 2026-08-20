args@{
  mkModule,
  ...
}:

mkModule {
  name = "linear";
  category = "productivity";
  linuxPackages = { pkgs, ... }: [ pkgs.linear ];
  casks = [ "linear" ];
  description = "Figma";
} args
