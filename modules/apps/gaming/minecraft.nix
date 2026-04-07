{ mkModule, ... }:

mkModule {
  name = "minecraft";
  category = "gaming";
  packages = { pkgs, ... }: [
    pkgs.zulu17
    pkgs.prismlauncher
  ];
  description = "Minecraft with PrismLauncher";
}
