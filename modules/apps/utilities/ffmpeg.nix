args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "ffmpeg";
  packages = pkgs: [ pkgs.ffmpeg ];
  description = "FFmpeg multimedia framework";
} args
