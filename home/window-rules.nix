{ lib, ... }:
let
  size = lib.types.nullOr (lib.types.either lib.types.int lib.types.float);
in
{
  options.home.desktop.windowRules = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          appId = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Regex matched against the window's app_id or class.";
          };
          title = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Regex matched against the window title.";
          };
          float = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "Open floating (true) or tiled (false); null leaves the Compositor's default.";
          };
          width = lib.mkOption {
            type = size;
            default = null;
            description = "Width: a fraction of the output when at most 1, otherwise pixels.";
          };
          height = lib.mkOption {
            type = size;
            default = null;
            description = "Height: a fraction of the output when at most 1, otherwise pixels.";
          };
        };
      }
    );
    default = [ ];
    description = "How an app's windows open, stated by the module that owns the app and rendered by every Compositor.";
  };
}
