{ lib }:

# Category helper for auto-discovering and enabling Home Manager modules
#
# Usage:
#   args@{ mkHomeCategory, ... }:
#   mkHomeCategory {
#     _file = toString ./.;
#     name = "cli";
#   } args
#
# Or with custom defaults:
#   mkHomeCategory {
#     _file = toString ./.;
#     name = "cli";
#     enableByDefault = { zsh = false; nushell = true; };
#   } args
#
# Features:
# - Auto-discovers all .nix files in directory (except default.nix)
# - Auto-imports discovered files and subdirectory default.nix files
# - Auto-enables all modules when home.category.enable = true
# - Optional manual control via enableByDefault parameter
# - Supports nested categories (subdirectories with their own default.nix)

{
  name,
  _file,
  # Optional: manually override which modules are enabled by default
  # Example: { git = true; zsh = false; }
  enableByDefault ? {},
}:

{ config, pkgs, lib, isLinux ? pkgs.stdenv.isLinux, ... }:

let
  # Derive category path from file location
  # e.g., /nix/store/.../home/cli -> "home.cli"
  # e.g., /nix/store/.../home/nixos/desktop-environments -> "home.desktop-environments"
  filePath = toString _file;

  # Split by "home/" and get the relative path
  parts = lib.splitString "home/" filePath;
  relativePath = if (builtins.length parts) > 1 then builtins.elemAt parts 1 else "";

  # Remove "nixos/" prefix since home modules should be "home.cli" not "home.nixos.cli"
  # e.g., "nixos/desktop-environments" -> "desktop-environments"
  cleanedPath = builtins.replaceStrings [ "nixos/" ] [ "" ] relativePath;

  # Build category path: "home.cli" or "home.desktop-environments"
  categoryPath = "home." + (builtins.replaceStrings ["/"] ["."] cleanedPath);

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

  # For each subdirectory, import only its default.nix if it exists
  getSubdirDefaultFile = subdir:
    let
      subdirPath = _file + "/${subdir}";
      subdirContents = builtins.readDir subdirPath;
      hasDefault = subdirContents ? "default.nix";
    in
      if hasDefault then [ (subdirPath + "/default.nix") ] else [];

  # Build imports list - all .nix files in current dir plus subdirectory default.nix files
  fileImports = map (name: _file + "/${name}") (builtins.attrNames nixFiles);
  subdirFileImports = lib.flatten (map getSubdirDefaultFile (builtins.attrNames subdirs));
  allImports = fileImports ++ subdirFileImports;

  # Extract module names from filenames (without .nix extension)
  # e.g., "git.nix" -> "git"
  fileModuleNames = map (name: lib.removeSuffix ".nix" name) (builtins.attrNames nixFiles);

  # Extract subdirectory names as module names
  # e.g., "neovim" subdirectory -> "neovim" module (which imports neovim/default.nix -> neovim/nixvim/neovim.nix)
  subdirModuleNames = builtins.attrNames subdirs;

  # Combine file and subdirectory module names
  allModuleNames = fileModuleNames ++ subdirModuleNames;

  # Split category path for accessing options
  categoryParts = lib.splitString "." categoryPath;
in

{
  imports = allImports;

  options = lib.setAttrByPath (categoryParts ++ ["enable"]) (lib.mkEnableOption "Enables all ${name} home modules");

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
      ) allModuleNames))
  );
}
