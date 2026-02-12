args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "mangohud";
  packages = { pkgs, ... }: [ pkgs.mangohud ];
  description = "MangoHud performance overlay";
} args
