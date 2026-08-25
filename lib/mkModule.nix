{ lib }:

# Module helper: creates an enable option and applies config when enabled.
#
# Usage:
#   args@{ config, pkgs, lib, mkModule, ... }:
#   mkModule {
#     name = "discord";
#     category = "communication";
#     packages = { pkgs, ... }: [ pkgs.discord ];
#   } args
#
# `packages` and `extraConfig` may be a value or a function of
# { pkgs, pkgs-stable, lib, platform }, where platform is "linux" or "darwin".
# Which platforms a module is for is stated, not inferred: set `platforms`.

{
  name,
  category ? null,
  description ? "Enable ${name}",
  platforms ? [
    "linux"
    "darwin"
  ],
  packages ? null,
  extraConfig ? { },
  homeConfig ? null,
  # Homebrew shortcuts (Darwin only). Require `darwin.homebrew.enable = true`.
  brews ? [ ],
  casks ? [ ],
}:

# Inner module function -- receives the full NixOS module args via `args` passthrough
{
  config,
  pkgs,
  pkgs-stable ? pkgs,
  lib,
  ...
}:
let
  platform = if pkgs.stdenv.hostPlatform.isLinux then "linux" else "darwin";

  # Build option path: apps.browsers.firefox or homelab.caddy
  optPath = if category != null then [ "apps" category name ] else [ "apps" name ];

  cfg = lib.attrByPath optPath { enable = false; } config;

  resolve =
    v:
    if v == null then
      null
    else if lib.isFunction v then
      v {
        inherit
          pkgs
          pkgs-stable
          lib
          platform
          ;
      }
    else
      v;

  sysPkgs = if packages == null then [ ] else resolve packages;

  hasHomebrew = brews != [ ] || casks != [ ];
  homebrewConfig = lib.optionalAttrs (platform == "darwin" && hasHomebrew) {
    homebrew = { inherit brews casks; };
  };

  resolvedExtra = lib.recursiveUpdate (resolve extraConfig) homebrewConfig;

  compatible = lib.elem platform platforms;
in
{
  options = lib.setAttrByPath (optPath ++ [ "enable" ]) (lib.mkEnableOption description);

  # On a platform this module is not for, define nothing at all. `mkIf false`
  # would not be enough: the module system still type-checks the option paths
  # inside it, and a Linux-only module names options that do not exist on
  # Darwin.
  config =
    if !compatible then
      { }
    else
      lib.mkIf cfg.enable (lib.mkMerge [
        (lib.optionalAttrs (sysPkgs != [ ]) {
          environment.systemPackages = sysPkgs;
        })
        (lib.optionalAttrs (resolvedExtra != { }) resolvedExtra)
        (lib.optionalAttrs (homeConfig != null) {
          home-manager.sharedModules = [ homeConfig ];
        })
      ]);
}
