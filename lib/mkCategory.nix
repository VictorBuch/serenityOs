{ lib }:

# Category helper for auto-discovering and enabling app modules
#
# Usage:
#   args@{ mkCategory, ... }:
#   mkCategory {
#     _file = toString ./.;
#     name = "browsers";
#   } args
#
# Features:
# - Auto-discovers all .nix files in directory (except default.nix)
# - Auto-imports discovered files and subdirectories
# - Auto-enables all modules when apps.category.enable = true
# - Platform-aware (works with mkApp's platform detection)
# - Optional manual control via enableByDefault parameter

{
  name,
  _file,
  # Optional: manually override which modules are enabled by default
  # Example: { firefox = true; zen = false; }
  enableByDefault ? {},
}:

{ config, pkgs, lib, isLinux ? pkgs.stdenv.isLinux, ... }:

let
  # Derive category path from file location
  # e.g., /nix/store/.../modules/apps/browsers -> "apps.browsers"
  filePath = toString _file;
  parts = lib.splitString "modules/apps/" filePath;
  relativePath = if (builtins.length parts) > 1 then builtins.elemAt parts 1 else "";
  categoryPath = "apps." + (builtins.replaceStrings ["/"] ["."] relativePath);

  # Read directory contents
  dirContents = builtins.readDir _file;

  # Get all .nix files except default.nix in current directory
  nixFiles = lib.filterAttrs (name: type:
    type == "regular" &&
    lib.hasSuffix ".nix" name &&
    name != "default.nix"
  ) dirContents;

  # Get all subdirectories
  subdirs = lib.filterAttrs (name: type: type == "directory") dirContents;

  # For each subdirectory, get all .nix files (except default.nix)
  getSubdirFiles = subdir:
    let
      subdirPath = _file + "/${subdir}";
      subdirContents = builtins.readDir subdirPath;
      subdirNixFiles = lib.filterAttrs (name: type:
        type == "regular" &&
        lib.hasSuffix ".nix" name &&
        name != "default.nix"
      ) subdirContents;
    in
      map (name: subdirPath + "/${name}") (builtins.attrNames subdirNixFiles);

  # Build imports list - all .nix files in current dir plus all .nix files in subdirs
  fileImports = map (name: _file + "/${name}") (builtins.attrNames nixFiles);
  subdirFileImports = lib.flatten (map getSubdirFiles (builtins.attrNames subdirs));
  allImports = fileImports ++ subdirFileImports;

  # Extract module names from filenames (without .nix extension)
  # e.g., "firefox.nix" -> "firefox"
  fileModuleNames = map (name: lib.removeSuffix ".nix" name) (builtins.attrNames nixFiles);

  # Build the enable configuration for all discovered modules
  # We'll enable all modules by default, unless overridden in enableByDefault
  buildEnableConfig = moduleNames:
    lib.listToAttrs (map (moduleName:
      {
        name = "${categoryPath}.${moduleName}";
        value = {
          enable = lib.mkDefault (
            if enableByDefault ? ${moduleName} then
              enableByDefault.${moduleName}
            else
              true
          );
        };
      }
    ) moduleNames);

  # Split category path for accessing options
  categoryParts = lib.splitString "." categoryPath;
in

{
  imports = allImports;

  options = {
    ${categoryPath}.enable = lib.mkEnableOption "Enables all ${name} apps";
  };

  config = lib.mkIf (lib.attrByPath (categoryParts ++ ["enable"]) false config) (
    lib.setAttrByPath
      (lib.splitString "." categoryPath)
      (lib.listToAttrs (map (moduleName:
        lib.nameValuePair moduleName {
          enable = lib.mkDefault (
            if enableByDefault ? ${moduleName} then
              enableByDefault.${moduleName}
            else
              true
          );
        }
      ) fileModuleNames))
  );
}
