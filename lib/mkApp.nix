{ lib }:

# Universal app module helper with cross-platform and stable/unstable support
#
# Usage Examples:
#
# 1. Cross-platform (same package):
#   mkApp {
#     name = "firefox";
#     optionPath = "apps.browsers.firefox";
#     packages = pkgs: [ pkgs.firefox ];
#   }
#
# 2. Platform-specific packages:
#   mkApp {
#     name = "ghostty";
#     optionPath = "apps.terminals.ghostty";
#     linuxPackages = pkgs: [ pkgs.ghostty ];
#     darwinPackages = pkgs: [ ];  # Installed via homebrew
#     darwinExtraConfig = { homebrew.casks = [ "ghostty" ]; };
#   }
#
# 3. Linux-only (auto-asserts):
#   mkApp {
#     name = "steam";
#     optionPath = "apps.gaming.steam";
#     linuxPackages = pkgs: [ pkgs.steam ];
#   }
#
# 4. Stable/unstable mix:
#   mkApp {
#     name = "myapp";
#     optionPath = "apps.myapp";
#     packages = { pkgs, stable-pkgs }: [
#       pkgs.firefox           # unstable
#       stable-pkgs.libreoffice  # stable
#     ];
#   }

{
  name,
  optionPath,
  # Cross-platform (use same packages for both)
  packages ? null,
  # Platform-specific packages
  linuxPackages ? packages,
  darwinPackages ? packages,
  # Description
  description ? "Enables ${name}",
  # Extra config (applies to both platforms)
  extraConfig ? { },
  # Platform-specific extra config
  linuxExtraConfig ? { },
  darwinExtraConfig ? { },
}:

{
  config,
  pkgs,
  lib,
  inputs ? null,
  isLinux ? pkgs.stdenv.isLinux,
  ...
}:

let
  # Import stable nixpkgs if inputs is available
  stable-pkgs = if inputs != null then
    import inputs.stable-nixpkgs {
      inherit (pkgs) system;
      config.allowUnfree = true;
    }
  else
    pkgs;

  # Select platform-specific packages
  platformPackages = if isLinux then linuxPackages else darwinPackages;

  # Resolve packages (support functions or direct lists)
  resolvePackages = pkgList:
    if pkgList == null then
      [ ]
    else if lib.isFunction pkgList then
      let
        funcArgs = lib.functionArgs pkgList;
      in
      if funcArgs != { } then
        # Named arguments: { pkgs, stable-pkgs }
        pkgList { inherit pkgs stable-pkgs; }
      else
        # Single argument: pkgs
        pkgList pkgs
    else
      # Direct list
      pkgList;

  resolvedPackages = resolvePackages platformPackages;

  # Detect if this is platform-specific
  isLinuxOnly = linuxPackages != null && darwinPackages == null;
  isDarwinOnly = darwinPackages != null && linuxPackages == null;

  # Merge platform-specific and common extra config
  platformExtraConfig = if isLinux then linuxExtraConfig else darwinExtraConfig;
  finalExtraConfig = lib.recursiveUpdate extraConfig platformExtraConfig;

  # Build the option path dynamically
  optionParts = lib.splitString "." optionPath;
in

{
  options = lib.setAttrByPath (optionParts ++ ["enable"]) (lib.mkEnableOption description);

  config =
    let
      # Use attrByPath with default to avoid errors when option doesn't exist yet
      optionEnabled = lib.attrByPath optionParts { enable = false; } config;
    in
    lib.mkMerge [
      # Add assertion for Linux-only apps on Darwin
      (lib.mkIf (optionEnabled.enable && isLinuxOnly && !isLinux) {
        assertions = [
          {
            assertion = false;
            message = "${name} (${optionPath}) is only available on Linux systems.";
          }
        ];
      })

      # Add assertion for Darwin-only apps on Linux
      (lib.mkIf (optionEnabled.enable && isDarwinOnly && isLinux) {
        assertions = [
          {
            assertion = false;
            message = "${name} (${optionPath}) is only available on macOS systems.";
          }
        ];
      })

      # Apply configuration when enabled
      (lib.mkIf optionEnabled.enable (
        lib.recursiveUpdate
          {
            environment.systemPackages = resolvedPackages;
          }
          finalExtraConfig
      ))
    ];
}
