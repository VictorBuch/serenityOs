args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

mkModule {
  name = "obsidian";
  category = "productivity";
  description = "Obsidian note-taking app";
  packages = { pkgs, ... }: [ pkgs.obsidian ];
} args
