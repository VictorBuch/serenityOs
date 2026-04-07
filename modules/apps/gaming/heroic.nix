{ mkModule, ... }:

mkModule {
  name = "heroic";
  category = "gaming";
  packages = { pkgs, ... }: [ pkgs.heroic ];
  description = "Heroic Games Launcher";
}
