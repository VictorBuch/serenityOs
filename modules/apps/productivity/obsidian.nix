args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "obsidian";
  packages = pkgs: [ pkgs.obsidian ];
  description = "Obsidian note-taking app";
} args
