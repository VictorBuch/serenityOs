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
  name = "corectrl";
  linuxPackages = { pkgs, ... }: [ ]; # CoreCtrl is enabled via programs.corectrl
  description = "CoreCtrl AMD GPU control (Linux only)";
  linuxExtraConfig = {
    programs.corectrl.enable = true;

    hardware.amdgpu.overdrive = {
      enable = true;
      ppfeaturemask = "0xffffffff";
    };
  };
} args
