{ mkModule, ... }:

mkModule {
  name = "tidal";
  category = "audio";
  packages = { pkgs, ... }: [ pkgs.tidal-hifi ];
  description = "Tidal music streaming";
}
