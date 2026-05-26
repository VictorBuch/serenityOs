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

  # For each category, find module names from .nix files (excluding _-prefixed).
  # Recurses into subdirectories so modules can be organized in nested folders
  # (e.g. development/editors/vscode.nix still registers as apps.development.vscode).
  discoverModules =
    catName:
    let
      walk =
        path:
        lib.concatLists (
          lib.mapAttrsToList (
            n: t:
            if t == "directory" && !lib.hasPrefix "_" n then
              walk (path + "/${n}")
            else if t == "regular" && lib.hasSuffix ".nix" n && !lib.hasPrefix "_" n then
              [ (lib.removeSuffix ".nix" n) ]
            else
              [ ]
          ) (builtins.readDir path)
        );
    in
    walk (appsDir + "/${catName}");

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
