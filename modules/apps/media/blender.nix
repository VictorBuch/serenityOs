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
  name = "blender";
  packages = pkgs: [ pkgs.blender ];
  description = "Blender 3D modeling";
} args
