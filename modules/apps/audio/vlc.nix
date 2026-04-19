args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "vlc";
  category = "audio";
  packages = { pkgs, ... }: [ pkgs.vlc ];
  description = "VLC media player";
} args
