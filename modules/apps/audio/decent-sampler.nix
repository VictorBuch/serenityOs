args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

mkModule {
  name = "decent-sampler";
  category = "audio";
  platforms = [ "linux" ];
  description = "Decent Sampler native sample player (standalone + VST/VST3)";
  packages = { pkgs, ... }: [ pkgs.decent-sampler ];
  homeConfig =
    { pkgs, ... }:
    {
      home.file.".vst3/DecentSampler.vst3".source =
        "${pkgs.decent-sampler}/lib/vst3/DecentSampler.vst3";
    };
} args
