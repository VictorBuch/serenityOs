args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "language-learning";
  packages = pkgs: [
    (pkgs.whisper-cpp.override { vulkanSupport = true; })
    pkgs.yt-dlp
    pkgs.anki
  ];
  description = "Language learning apps (Whisper, Anki, yt-dlp)";
} args
