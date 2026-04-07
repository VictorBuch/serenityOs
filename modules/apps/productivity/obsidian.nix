{ mkModule, ... }:

mkModule {
  name = "obsidian";
  category = "productivity";
  packages = { pkgs, ... }: [ pkgs.obsidian ];
  description = "Obsidian note-taking app";
}
