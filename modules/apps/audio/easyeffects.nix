{ mkModule, ... }:

mkModule {
  name = "easyeffects";
  category = "audio";
  packages = { pkgs, ... }: [ pkgs.easyeffects ];
  description = "EasyEffects audio effects";
}
