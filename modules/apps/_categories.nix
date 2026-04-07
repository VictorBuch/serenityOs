# Category enable module - replaces all default.nix category files
# When apps.<category>.enable = true, all modules in that category are enabled
# The _ prefix means import-tree ignores this file (imported explicitly in flake.nix)
{ config, lib, ... }:
let
  # Auto-discover categories from directory structure
  appsDir = ./.;
  dirContents = builtins.readDir appsDir;
  categories = lib.filterAttrs (
    n: t: t == "directory" && !lib.hasPrefix "_" n
  ) dirContents;

  # For each category, find module names from .nix files (excluding _-prefixed)
  discoverModules =
    catName:
    let
      contents = builtins.readDir (appsDir + "/${catName}");
      nixFiles = lib.filterAttrs (
        n: t: t == "regular" && lib.hasSuffix ".nix" n && !lib.hasPrefix "_" n
      ) contents;
    in
    map (n: lib.removeSuffix ".nix" n) (builtins.attrNames nixFiles);

  # Per-category overrides for which modules default to disabled
  overrides = {
    gaming = {
      ps3 = false;
    };
    neovim = {
      nixvim = false;
      nvf = false;
    };
    theming = {
      stylix = false;
      catppuccin = false;
    };
  };
in
{
  options.apps = lib.mapAttrs (catName: _: {
    enable = lib.mkEnableOption "Enable all ${catName} apps";
  }) categories;

  config = lib.mkMerge (
    lib.mapAttrsToList (
      catName: _:
      lib.mkIf (config.apps.${catName}.enable or false) {
        apps.${catName} = lib.genAttrs (discoverModules catName) (
          modName: {
            enable = lib.mkDefault (
              if (overrides ? ${catName}) && (overrides.${catName} ? ${modName}) then
                overrides.${catName}.${modName}
              else
                true
            );
          }
        );
      }
    ) categories
  );
}
