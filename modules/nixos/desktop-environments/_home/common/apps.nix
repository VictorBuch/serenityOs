# What an app is called and how to start it, stated once.
#
# Every Compositor needs the same two facts about an app -- the window
# identifier it presents (app_id under Wayland, class under XWayland) and the
# command that launches it -- and each one used to spell them out again in its
# own keybinds, window rules and focus helper. They drifted.
#
# Which key a slot sits on stays with the Compositor: the modifier budget and
# the tag model genuinely differ between them.
{
  config,
  lib,
  ...
}:
let
  appModule = lib.types.submodule (
    { config, ... }:
    {
      options = {
        command = lib.mkOption {
          type = lib.types.str;
          description = "Command that launches the app.";
        };

        windowIds = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = ''
            Every app_id or class this app is known to present, canonical one
            first. XWayland and Wayland spellings both belong here.
          '';
        };

        appId = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = lib.head config.windowIds;
          description = "Derived: the canonical window identifier, for exact-match IPC.";
        };

        alternatives = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = lib.concatMapStringsSep "|" lib.escapeRegex config.windowIds;
          description = "Derived: unanchored regex alternation, for embedding in a larger pattern.";
        };

        regex = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = lib.concatMapStringsSep "|" (id: "^${lib.escapeRegex id}$") config.windowIds;
          description = "Derived: anchored regex matching any of this app's window identifiers.";
        };
      };
    }
  );
in
{
  options.home.desktop.apps = lib.mkOption {
    type = lib.types.attrsOf appModule;
    default = { };
    description = "Window identifier and launch command per app, shared by every Compositor.";
  };

  config.home.desktop.apps = {
    zen = {
      command = "zen-beta";
      windowIds = [
        "zen-beta"
        "zen"
        "firefox"
      ];
    };
    ghostty = {
      command = "ghostty";
      windowIds = [
        "com.mitchellh.ghostty"
        "ghostty"
      ];
    };
    figma = {
      command = "figma-linux";
      windowIds = [
        "figma-linux"
        "Figma"
      ];
    };
    obsidian = {
      command = "obsidian";
      windowIds = [
        "obsidian"
        "Obsidian"
      ];
    };
    discord = {
      command = "discord";
      windowIds = [
        "discord"
        "Discord"
      ];
    };
    slack = {
      command = "slack";
      # Capital S first: it is what the Electron app reports as its app_id, and
      # niri's focus helper matches exactly rather than by regex.
      windowIds = [
        "Slack"
        "slack"
      ];
    };
    sone = {
      command = "sone";
      windowIds = [ "sone" ];
    };
    tidal = {
      command = "tidal-hifi";
      windowIds = [
        "tidal-hifi"
        "Tidal-hifi"
      ];
    };
    dolphin = {
      command = "dolphin";
      windowIds = [
        "org.kde.dolphin"
        "dolphin"
        "Dolphin"
      ];
    };
  };
}
