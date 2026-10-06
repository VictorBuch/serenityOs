{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.theme.authority;

  writerType = lib.types.enum [
    "noctalia"
    "stylix"
    "app"
  ];

  appModule = lib.types.submodule (
    { name, ... }:
    {
      options = {
        colors = lib.mkOption {
          type = writerType;
          description = ''
            The single component permitted to write ${name}'s colors.
            "app" means ${name}'s own module in this repo writes them.
          '';
        };
        noctaliaTemplates = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "noctalia builtin template ids that render ${name}'s palette.";
        };
        noctaliaUserTemplates = lib.mkOption {
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
          default = { };
          description = "noctalia user templates (theme.templates.user.<id>) that render ${name}'s palette.";
        };
        stylixTargets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "stylix targets that must be off while ${name}'s colors belong to someone else.";
        };
        reDeclared = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Settings the disabled stylix target also carried, which ${name}'s own
            module therefore has to declare itself. A stylix target is one switch
            over colors, fonts and opacity together; turning it off drops all three.
          '';
        };
        note = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Why the authority for ${name} is where it is.";
        };
      };
    }
  );

  apps = cfg.apps;
  appsWith = f: lib.filterAttrs (_: app: f app) apps;
  collect = field: lib.unique (lib.concatMap (app: app.${field}) (lib.attrValues apps));
in
{
  options.theme.authority = {
    icons = lib.mkOption {
      type = writerType;
      default = "stylix";
      description = "Theme Authority for icon themes.";
    };
    cursor = lib.mkOption {
      type = writerType;
      default = "stylix";
      description = "Theme Authority for the pointer cursor.";
    };
    fonts = lib.mkOption {
      type = writerType;
      default = "stylix";
      description = "Theme Authority for fonts.";
    };

    apps = lib.mkOption {
      type = lib.types.attrsOf appModule;
      default = { };
      description = "Per-app color authority. One writer per app; a second writer is a defect.";
    };

    noctalia.builtinIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      default = lib.sort (a: b: a < b) (
        lib.unique (
          lib.concatMap (app: app.noctaliaTemplates) (lib.attrValues (appsWith (a: a.colors == "noctalia")))
        )
      );
      description = "Derived: programs.noctalia.settings.theme.templates.builtin_ids.";
    };

    noctalia.userTemplates = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      readOnly = true;
      default = lib.mergeAttrsList (
        map (app: app.noctaliaUserTemplates) (lib.attrValues (appsWith (a: a.colors == "noctalia")))
      );
      description = "Derived: programs.noctalia.settings.theme.templates.user.";
    };

    stylix.disabledTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      default = lib.sort (a: b: a < b) (
        lib.unique (
          lib.concatMap (app: app.stylixTargets) (lib.attrValues (appsWith (a: a.colors != "stylix")))
        )
      );
      description = "Derived: stylix targets to switch off, one per app whose colors belong elsewhere.";
    };

    stylix.allTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      default = lib.sort (a: b: a < b) (collect "stylixTargets");
      description = "Derived: every stylix target this table has an opinion about.";
    };
  };

  config = {
    theme.authority.apps = {
      mango = {
        colors = "noctalia";
        noctaliaTemplates = [ "mango" ];
        note = "Window decorations, reloaded live via `mmsg reload_config`. stylix has no mango target.";
      };
      niri = {
        colors = "noctalia";
        noctaliaTemplates = [ "niri" ];
        note = "Focus ring, border and tab colors in ~/.config/niri/noctalia.kdl, included last from config.kdl.";
      };
      hyprland = {
        colors = "noctalia";
        noctaliaTemplates = [ "hyprland" ];
        stylixTargets = [ "hyprland" ];
        note = "Border and group colors; the conf sources ~/.config/hypr/noctalia.conf so the template's apply step is a no-op.";
      };
      ghostty = {
        colors = "noctalia";
        noctaliaTemplates = [ "ghostty" ];
        stylixTargets = [ "ghostty" ];
        reDeclared = [
          "background-opacity"
          "font-family"
          "font-size"
        ];
        note = "noctalia's template writes palette/background/foreground/cursor/selection only.";
      };
      kitty = {
        colors = "noctalia";
        noctaliaTemplates = [ "kitty" ];
        stylixTargets = [ "kitty" ];
      };
      btop = {
        colors = "noctalia";
        noctaliaTemplates = [ "btop" ];
        stylixTargets = [ "btop" ];
      };
      gtk = {
        colors = "noctalia";
        noctaliaTemplates = [
          "gtk3"
          "gtk4"
        ];
        stylixTargets = [ "gtk" ];
        note = "noctalia also switches adw-gtk3/adw-gtk3-dark over gsettings.";
      };
      qt = {
        colors = "noctalia";
        noctaliaTemplates = [ "qt" ];
        stylixTargets = [ "qt" ];
        note = "Rendered into ~/.config/qt6ct/colors/noctalia.conf, which qt6ct.conf points at.";
      };
      kde = {
        colors = "noctalia";
        noctaliaTemplates = [ "kcolorscheme" ];
        note = "Merged into ~/.config/kdeglobals, which Dolphin reads. stylix has no kcolorscheme target.";
      };

      noctalia = {
        colors = "app";
        stylixTargets = [
          "noctalia"
          "noctalia-shell"
        ];
        note = "The Shell derives its own Material You palette from the wallpaper; stylix must not feed it one.";
      };
      zen = {
        colors = "noctalia";
        noctaliaUserTemplates = lib.listToAttrs (
          map
            (sheet: {
              name = "zen_${sheet}";
              value = {
                input_path = "${inputs.noctalia-templates}/zen-browser/zen-${sheet}.css";
                output_path = "$XDG_CACHE_HOME/noctalia/zen-browser/zen-${sheet}.css";
              };
            })
            [
              "userChrome"
              "userContent"
            ]
        );
        stylixTargets = [ "zen-browser" ];
        reDeclared = [
          "font.name.*"
          "zen.view.window.scheme"
        ];
        note = "Zen imports the rendered sheets from its userChrome/userContent; a new palette shows after a Zen restart.";
      };
      sone = {
        colors = "noctalia";
        noctaliaUserTemplates.sone = {
          input_path = "${inputs.noctalia-templates}/sone/theme.json";
          output_path = "$XDG_CONFIG_HOME/sone/theme.json";
        };
        note = "Sone watches theme.json live once Settings > Themes is set to Custom.";
      };

      starship = {
        colors = "app";
        stylixTargets = [ "starship" ];
        note = "Unowned by design: noctalia's starship template edits the config in place, which fails on home-manager's read-only symlink, so it is excluded from builtinIds too.";
      };
    };

    assertions =
      lib.mapAttrsToList (name: app: {
        assertion =
          app.colors != "noctalia" -> app.noctaliaTemplates == [ ] && app.noctaliaUserTemplates == { };
        message = "theme.authority.apps.${name}: colors are written by ${app.colors}, so it must not also list noctalia templates.";
      }) apps
      ++ lib.mapAttrsToList (name: app: {
        assertion =
          app.colors != "noctalia" || app.noctaliaTemplates != [ ] || app.noctaliaUserTemplates != { };
        message = "theme.authority.apps.${name}: colors are assigned to noctalia but no template renders them, so nothing writes them at all.";
      }) apps;
  };
}
