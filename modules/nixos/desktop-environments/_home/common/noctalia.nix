{
  config,
  pkgs,
  lib,
  inputs,
  osConfig ? { },
  ...
}:
let
  optPath = [
    "home"
    "desktop"
    "shell"
    "noctalia"
  ];
  cfg = lib.attrByPath optPath { enable = false; } config;

  davinci = lib.attrByPath [ "home" "desktop" "common" "davinci-convert" ] {
    enable = false;
  } config;

  # Derived from the Theme Authority table in modules/common/theme-authority.nix.
  # The fallback keeps this module evaluable under bare home-manager.
  builtinTemplateIds = lib.attrByPath [ "theme" "authority" "noctalia" "builtinIds" ] [ ] osConfig;
  userTemplates = lib.attrByPath [ "theme" "authority" "noctalia" "userTemplates" ] { } osConfig;

  bin = "${config.programs.noctalia.package}/bin/noctalia";
  msg =
    args:
    [
      bin
      "msg"
    ]
    ++ args;
in
{
  imports = [ ./shell.nix ];

  options = lib.setAttrByPath (optPath ++ [ "enable" ]) (
    lib.mkEnableOption "Noctalia shell - A modern Wayland shell for niri"
  );

  config = lib.mkIf cfg.enable ({
    programs.noctalia = {
      enable = true;
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };

    home.liveSeams.noctalia.path = ".config/noctalia/config.toml";
    xdg.configFile."noctalia/nix.toml".source = (pkgs.formats.toml { }).generate "noctalia-nix.toml" ({
      theme.templates = {
        enable_builtin_templates = true;
        builtin_ids = builtinTemplateIds;
        enable_community_templates = false;
        user = userTemplates;
      };
      wallpaper.directory = config.wallpapers.path;
    }
    // lib.optionalAttrs davinci.enable {
      plugins.source = map (name: {
        inherit name;
        kind = "git";
        location = "https://github.com/noctalia-dev/${name}-plugins";
        enabled = true;
      }) [ "official" "community" ] ++ [
        {
          name = "serenityos";
          kind = "path";
          location = "${davinci.pluginPackage}";
          enabled = true;
        }
      ];
      plugins.enabled = [ davinci.pluginId ];
      widget.davinci-convert.type = davinci.widgetType;
    });

    home.desktop.shell = {
      start = [ bin ];

      actions = {
        launcher = msg [
          "panel-toggle"
          "launcher"
        ];
        launcher-calc = msg [
          "panel-toggle"
          "launcher"
          "/calc"
        ];
        launcher-windows = msg [
          "panel-toggle"
          "launcher"
          "/win"
        ];
        launcher-emoji = msg [
          "panel-toggle"
          "launcher"
          "/emo"
        ];
        session-menu = msg [
          "panel-toggle"
          "session"
        ];
        settings = msg [ "settings-toggle" ];
        lock = msg [
          "session"
          "lock"
        ];
        lock-and-suspend = msg [
          "session"
          "lock-and-suspend"
        ];
        screenshot-region = msg [ "screenshot-region" ];
        screenshot-fullscreen = msg [ "screenshot-fullscreen" ];
        volume-up = msg [ "volume-up" ];
        volume-down = msg [ "volume-down" ];
        volume-mute = msg [ "volume-mute" ];
        brightness-up = msg [ "brightness-up" ];
        brightness-down = msg [ "brightness-down" ];
      };

      check = pkgs.runCommand "noctalia-shell-actions" { } ''
        HOME=$TMPDIR
        fail=0
        ${lib.concatStrings (
          lib.mapAttrsToList (verb: action: ''
            set -- ${lib.escapeShellArgs (lib.drop 2 action)}
            if ! help=$(${bin} msg "$1" --help 2>&1); then
              echo "Shell Action ${verb}: noctalia has no msg command '$1'"; fail=1
            elif [ -n "''${2-}" ] && choices=$(echo "$help" | grep -o 'one of: .*'); then
              case " $(echo "''${choices#one of: }" | tr -d ,) " in
                *" $2 "*) ;;
                *) echo "Shell Action ${verb}: '$2' is not $choices"; fail=1 ;;
              esac
            fi
          '') config.home.desktop.shell.actions
        )}
        [ $fail = 0 ] && touch $out
      '';
    };

    # Adopt new HM default (was `config.gtk.theme` prior to 26.05)
    gtk.gtk4.theme = lib.mkForce null;

    # Quickshell icon hint — match stylix
    home.sessionVariables = {
      QS_ICON_THEME = config.stylix.icons.dark;
    };

    # Install Qt SVG support packages
    # Without these, Qt silently skips SVG icons (most modern icons are SVG)
    home.packages = with pkgs; [
      qt5.qtsvg
      kdePackages.qtsvg

      # Backends for noctalia's live GTK/Qt templates (stylix targets for
      # these are disabled). noctalia sets adw-gtk3 / adw-gtk3-dark via
      # gsettings for day/night, and writes the qt6ct/qt5ct color scheme.
      adw-gtk3
      kdePackages.qt6ct
      libsForQt5.qt5ct
    ];

    # qt6ct base config: a static pointer to the color scheme noctalia's `qt`
    # template writes at runtime (~/.config/qt6ct/colors/noctalia.conf). HM
    # owns this file; noctalia only writes the separate colors file, so there
    # is no read-only conflict. This is what makes Qt apps pick up the palette.
    xdg.configFile."qt6ct/qt6ct.conf".text = ''
      [Appearance]
      color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/noctalia.conf
      custom_palette=true
      style=Fusion
      icon_theme=${config.stylix.icons.dark}
      standard_dialogs=default
    '';
  });
}
