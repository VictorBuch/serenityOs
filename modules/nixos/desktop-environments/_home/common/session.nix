{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  session = osConfig.desktop.session;

  fileManagers = {
    dolphin = {
      desktopFile = "org.kde.dolphin.desktop";
      dbusExec = "${pkgs.kdePackages.dolphin}/bin/dolphin --daemon";
    };
    nautilus = {
      desktopFile = "org.gnome.Nautilus.desktop";
      dbusExec = "${pkgs.nautilus}/bin/nautilus --gapplication-service";
    };
  };
  fileManager = fileManagers.${session.fileManager};

  dialogApps = [
    "xdg-desktop-portal.*"
    "org\\.freedesktop\\.impl\\.portal\\..*"
    "zenity"
    "polkit-.*"
    "pavucontrol"
    "\\.?blueman-.*"
    "nm-connection-editor"
    "file-roller"
    "nwg-look"
    "qt[56]ct"
  ];
in
{
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  }
  // lib.optionalAttrs session.keyring {
    GSM_SKIP_SSH_AGENT_WORKAROUND = "1";
  };

  xdg.configFile."autostart/gnome-keyring-ssh.desktop" = lib.mkIf session.keyring {
    text = ''
      [Desktop Entry]
      Type=Application
      Hidden=true
    '';
  };

  # NOTE: this makes ~/.config/mimeapps.list a read-only store symlink, so
  # "set as default" from an application's own settings will fail -- defaults
  # have to be declared here instead.
  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = [ fileManager.desktopFile ];
  };
  xdg.configFile."mimeapps.list".force = true;

  xdg.dataFile."dbus-1/services/org.freedesktop.FileManager1.service".text = ''
    [D-BUS Service]
    Name=org.freedesktop.FileManager1
    Exec=${fileManager.dbusExec}
  '';

  # KDE apps resolve their icon theme through KIconTheme, which reads
  # ~/.config/kdeglobals -- not qt6ct.conf. Without this Dolphin falls back to
  # Breeze regardless of what qt6ct says. kdeglobals cannot be HM-owned: the
  # shell's kcolorscheme template merges the palette into it at runtime and
  # needs it writable, so seed the key idempotently instead.
  home.activation.kdeIconTheme = lib.mkIf (session.fileManager == "dolphin") (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            ${pkgs.python3}/bin/python3 - "$HOME/.config/kdeglobals" ${config.stylix.icons.dark} <<'PYICON'
      import os, sys, re
      path, theme = sys.argv[1], sys.argv[2]
      os.makedirs(os.path.dirname(path), exist_ok=True)
      text = open(path).read() if os.path.exists(path) else ""
      if re.search(r"^\[Icons\]", text, re.M):
          new = re.sub(r"(^\[Icons\][^\[]*?^Theme=).*$", r"\g<1>" + theme, text, flags=re.M)
          if new == text and "Theme=" not in text.split("[Icons]")[1].split("[")[0]:
              new = text.replace("[Icons]", "[Icons]\nTheme=" + theme, 1)
      else:
          new = text.rstrip("\n") + "\n\n[Icons]\nTheme=" + theme + "\n"
      if new != text:
          open(path, "w").write(new)
          print("kdeglobals: icon theme set to " + theme)
      PYICON
    ''
  );

  home.desktop.windowRules = [
    {
      appId = config.home.desktop.apps.${session.fileManager}.regex;
      float = true;
      width = 0.7;
      height = 0.7;
    }
    {
      appId = "^(${lib.concatStringsSep "|" dialogApps})$";
      float = true;
      width = 0.6;
      height = 0.6;
    }
    {
      title = "^iLok|PACE|License";
      float = true;
      width = 0.6;
      height = 0.6;
    }
    {
      title = "^IK Product Manager|IK Multimedia";
      float = true;
      width = 0.6;
      height = 0.6;
    }
    {
      title = "^Picture-in-Picture$";
      float = true;
      width = 345;
      height = 200;
    }
  ];
}
