{ lib, ... }:
let
  argv = lib.types.listOf lib.types.str;

  verbs = [
    "launcher"
    "launcher-calc"
    "launcher-windows"
    "launcher-emoji"
    "session-menu"
    "settings"
    "lock"
    "lock-and-suspend"
    "screenshot-region"
    "screenshot-fullscreen"
    "volume-up"
    "volume-down"
    "volume-mute"
    "brightness-up"
    "brightness-down"
  ];
in
{
  options.home.desktop.shell = {
    start = lib.mkOption {
      type = argv;
      description = "Command that starts the active Shell.";
    };

    actions = lib.genAttrs verbs (
      verb:
      lib.mkOption {
        type = argv;
        description = "Shell Action `${verb}`, as an argv list.";
      }
    );

    check = lib.mkOption {
      type = lib.types.package;
      description = "Derivation that fails when a Shell Action names a command the Shell does not accept.";
    };
  };
}
