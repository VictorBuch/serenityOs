args@{
  config,
  pkgs,
  lib,
  inputs ? null,
  isLinux,
  mkApp,
  ...
}:

mkApp {
  _file = toString ./.;
  name = "sunshine";
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
