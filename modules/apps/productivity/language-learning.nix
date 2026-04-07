args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "language-learning";
  category = "productivity";
  packages =
    { pkgs, ... }:
    [
      (pkgs.whisper-cpp.override { vulkanSupport = true; })
      pkgs.yt-dlp
      pkgs.anki
    ];
  description = "Language learning apps (Whisper, Anki, yt-dlp)";
} args
