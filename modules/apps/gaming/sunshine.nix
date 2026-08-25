args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "sunshine";
  platforms = [ "linux" ];
  category = "gaming";
  packages = { pkgs, ... }: [ ]; # Sunshine is enabled via services.sunshine
  description = "Sunshine game streaming (Linux only)";
  extraConfig = {
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };
  };
} args
