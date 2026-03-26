{ pkgs, lib, ... }:
let
  dirContents = builtins.readDir ./.;
  # Auto-discover all subdirectories that have a default.nix
  subdirs = lib.filterAttrs (name: type: type == "directory") dirContents;
  subdirImports = lib.mapAttrsToList (name: _: ./${name}) (
    lib.filterAttrs (
      name: _: builtins.pathExists (./. + "/${name}/default.nix")
    ) subdirs
  );
in
{
  imports = subdirImports;
}
