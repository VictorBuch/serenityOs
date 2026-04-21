{ lib }:

# Simplified module helper - replaces mkApp, mkHomeModule
# Creates an enable option and conditionally applies config when enabled.
#
# Usage:
#   args@{ config, pkgs, lib, mkModule, ... }:
#   mkModule {
#     name = "discord";
#     category = "communication";
#     packages = { pkgs, ... }: [ pkgs.discord ];
#   } args

{
  name,
  category ? null,
  namespace ? "apps",
  description ? "Enable ${name}",
  packages ? null,
  linuxPackages ? null,
  darwinPackages ? null,
  extraConfig ? {},
  linuxExtraConfig ? {},
  darwinExtraConfig ? {},
  homeConfig ? null,
  linuxHomeConfig ? null,
  darwinHomeConfig ? null,
  # Homebrew shortcuts (Darwin only). Require `darwin.homebrew.enable = true`.
  brews ? [ ],
  casks ? [ ],
}:

# Inner module function -- receives the full NixOS module args via `args` passthrough
{ config, pkgs, pkgs-stable ? pkgs, lib, ... }:
let
  isLinux = pkgs.stdenv.isLinux;

  # Build option path: apps.browsers.firefox or homelab.caddy
  optPath =
    if category != null then
      [ namespace category name ]
    else
      [ namespace name ];

  cfg = lib.attrByPath optPath { enable = false; } config;

  # Resolve packages -- functions receive both pkgs and pkgs-stable
  resolve =
    p:
    if p == null then
      [ ]
    else if lib.isFunction p then
      p { inherit pkgs pkgs-stable; }
    else
      p;

  # Platform-aware package selection
  sysPkgs =
    if linuxPackages != null || darwinPackages != null then
      resolve (if isLinux then linuxPackages else darwinPackages)
    else
      resolve packages;

  # Homebrew shortcuts -> darwin homebrew config
  hasHomebrew = brews != [ ] || casks != [ ];
  homebrewConfig = lib.optionalAttrs (!isLinux && hasHomebrew) {
    homebrew = {
      inherit brews casks;
    };
  };

  # Platform-aware extra config
  platformExtra = lib.recursiveUpdate (lib.recursiveUpdate extraConfig (
    if isLinux then linuxExtraConfig else darwinExtraConfig
  )) homebrewConfig;

  # Platform-aware home config
  platformHome =
    if isLinux then (if linuxHomeConfig != null then linuxHomeConfig else homeConfig)
    else (if darwinHomeConfig != null then darwinHomeConfig else homeConfig);

  # Platform compatibility check
  isLinuxOnly = linuxPackages != null && darwinPackages == null && packages == null && !hasHomebrew;
  isDarwinOnly = (darwinPackages != null || hasHomebrew) && linuxPackages == null && packages == null;
  compatible = !(isLinuxOnly && !isLinux) && !(isDarwinOnly && isLinux);
in
{
  options = lib.setAttrByPath (optPath ++ [ "enable" ]) (lib.mkEnableOption description);

  config = lib.mkIf (cfg.enable && compatible) (lib.mkMerge [
    (lib.optionalAttrs (sysPkgs != [ ]) {
      environment.systemPackages = sysPkgs;
    })
    (lib.optionalAttrs (platformExtra != { }) platformExtra)
    (lib.optionalAttrs (platformHome != null) {
      home-manager.sharedModules = [ platformHome ];
    })
  ]);
}
