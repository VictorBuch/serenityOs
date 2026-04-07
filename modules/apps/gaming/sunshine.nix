args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "sunshine";
  category = "gaming";
  linuxPackages = { pkgs, ... }: [ ]; # Sunshine is enabled via services.sunshine
  description = "Sunshine game streaming (Linux only)";
  linuxExtraConfig = {
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };
  };
} args
