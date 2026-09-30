args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "feedback";
  platforms = [ "linux" ];
  category = "audio";
  # psarc2feedpak rides along: it converts Rocksmith songs into feedback's .feedpak format.
  packages =
    { pkgs, ... }:
    [
      pkgs.feedback-desktop
      pkgs.psarc2feedpak
    ];
  description = "fee[dB]ack - guitar practice app with integrated audio engine and VST hosting";
} args
