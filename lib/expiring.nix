{ lib }:

# Overrides that announce their own obsolescence. Each helper wraps a value in
# an eval-time warning that fires once the condition the override was written
# for no longer holds.
#
#   xdg-desktop-portal-wlr = expiring.atVersion prev.xdg-desktop-portal-wlr "0.8.4"
#     "the screencast stall is fixed upstream" (prev.xdg-desktop-portal-wlr.overrideAttrs ...);

let
  warn = message: value: lib.warn "expiring override: ${message}" value;
in
{
  # Generic escape hatch: warn when `condition` is true.
  when =
    condition: message: value:
    if condition then warn message value else value;

  # Pin/patch waiting on a fix that lands in `version` or later.
  atVersion =
    pkg: version: message: value:
    if lib.versionAtLeast pkg.version version then
      warn "${pkg.pname or "package"} is now ${pkg.version} (>= ${version}): ${message}" value
    else
      value;

  # Workaround verified against exactly one version; a bump means re-test.
  onBump =
    pkg: version: message: value:
    if pkg.version != version then
      warn "${pkg.pname or "package"} moved ${version} -> ${pkg.version}: ${message}" value
    else
      value;

  # Package carried here because nixpkgs lacks it; expires when it lands.
  whenPackaged =
    pkgs: attr: message: value:
    if pkgs ? ${attr} then warn "nixpkgs now has ${attr}: ${message}" value else value;
}
