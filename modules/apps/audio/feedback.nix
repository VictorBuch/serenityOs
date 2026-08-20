args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "feedback";
  category = "audio";
  linuxPackages = { pkgs, ... }: [ pkgs.feedback-desktop ];
  description = "fee[dB]ack - guitar practice app with integrated audio engine and VST hosting";
} args
