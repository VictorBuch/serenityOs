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
  name = "localsend";
  darwinPackages = { pkgs, ... }: [ pkgs.localsend ];
  linuxExtraConfig = {
    programs.localsend = {
      enable = true;
      openFirewall = true;
    };
  };
  description = "LocalSend - share files locally";
} args
