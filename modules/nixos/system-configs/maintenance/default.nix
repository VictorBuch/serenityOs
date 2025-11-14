{
  pkgs,
  lib,
  config,
  ...
}:
let
  # Auto-discover all .nix files in this directory (except default.nix)
  dirContents = builtins.readDir ./.;
  nixFiles = lib.filterAttrs (name: type:
    type == "regular" &&
    lib.hasSuffix ".nix" name &&
    name != "default.nix"
  ) dirContents;

  # Import all discovered modules
  moduleImports = map (name: ./. + "/${name}") (builtins.attrNames nixFiles);

  # Extract module names (without .nix extension)
  moduleNames = map (name: lib.removeSuffix ".nix" name) (builtins.attrNames nixFiles);
in
{
  imports = moduleImports;

  options = {
    maintenance.linux.enable = lib.mkEnableOption "Enables Linux-specific maintenance";
  };

  # Auto-enable all discovered maintenance modules when enabled
  config = lib.mkIf config.maintenance.linux.enable (
    lib.listToAttrs (map (moduleName:
      lib.nameValuePair moduleName {
        enable = lib.mkDefault true;
      }
    ) moduleNames)
  );
}
