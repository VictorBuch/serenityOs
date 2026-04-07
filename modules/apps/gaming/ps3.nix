{ mkModule, ... }:

mkModule {
  name = "ps3";
  category = "gaming";
  packages = { pkgs, ... }: [ pkgs.rpcs3 ];
  description = "RPCS3 PS3 emulator";
}
