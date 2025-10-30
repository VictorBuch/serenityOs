{ lib }:

# Home Manager module helper with automatic enable options and minimal boilerplate
#
# Usage Examples:
#
# 1. Simple module with auto-derived optionPath:
#   mkHomeModule {
#     _file = toString ./.;
#     name = "git";
#     homeConfig = { config, pkgs, lib, ... }: {
#       home.packages = [ pkgs.delta ];
#       programs.git = {
#         enable = true;
#         userName = "...";
#       };
#     };
#   }
#
# 2. Module with manual optionPath:
#   mkHomeModule {
#     name = "tmux";
#     optionPath = "home.cli.tmux";
#     homeConfig = { config, pkgs, lib, ... }: {
#       programs.tmux = {
#         enable = true;
#         prefix = "C-Space";
#       };
#     };
#   }
#
# 3. Module with description:
#   mkHomeModule {
#     _file = toString ./.;
#     name = "neovim";
#     description = "Neovim text editor with custom configuration";
#     homeConfig = { ... }: { ... };
#   }

{
  name,
  # Auto-derive optionPath from file location (or specify manually)
  _file ? null,
  optionPath ? null,
  # Description for the enable option
  description ? "Enables ${name}",
  # Home Manager configuration
  homeConfig,
}:

{
  config,
  pkgs,
  lib,
  isLinux ? pkgs.stdenv.isLinux,
  ...
}@args:

let
  # Auto-derive optionPath from file location if not explicitly provided
  derivedOptionPath =
    if optionPath != null then
      optionPath
    else if _file != null then
      let
        # Convert file path to string and extract the part after "home/"
        filePath = toString _file;
        # Split by "home/" and take the part after it
        parts = lib.splitString "home/" filePath;
        # Get the relative path (e.g., "cli" or "terminals" or "nixos/desktop-environments")
        relativePath = if (builtins.length parts) > 1 then builtins.elemAt parts 1 else "";
        # Convert path separators to dots (e.g., "nixos/desktop-environments" -> "nixos.desktop-environments")
        # Remove "nixos/" prefix since home modules should be "home.cli" not "home.nixos.cli"
        cleanedPath = builtins.replaceStrings [ "nixos/" ] [ "" ] relativePath;
        categoryPath = builtins.replaceStrings [ "/" ] [ "." ] cleanedPath;
        # Build the full option path: "home.category.name"
        fullPath = "home.${categoryPath}.${name}";
      in
      fullPath
    else
      throw "mkHomeModule: Either '_file' or 'optionPath' must be provided for ${name}";

  # Build the option path dynamically from derived or provided optionPath
  optionParts = lib.splitString "." derivedOptionPath;

  # Apply the homeConfig with all args
  evaluatedConfig = homeConfig args;
in

{
  options = lib.setAttrByPath (optionParts ++ [ "enable" ]) (lib.mkEnableOption description);

  config =
    let
      # Use attrByPath with default to avoid errors when option doesn't exist yet
      optionEnabled = lib.attrByPath optionParts { enable = false; } config;
    in
    lib.mkIf optionEnabled.enable evaluatedConfig;
}
