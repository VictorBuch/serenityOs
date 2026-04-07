{ mkModule, ... }:

mkModule {
  name = "gamemode";
  category = "gaming";
  packages = { pkgs, ... }: [ pkgs.gamemode ];
  description = "GameMode performance optimization";
}
