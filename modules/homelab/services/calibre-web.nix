{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homelab.calibre-web;
  cw = config.services.calibre-web;
  user = config.user;
  dataDir = "/var/lib/${cw.dataDir}";

  importScript = pkgs.writeShellApplication {
    name = "calibre-import";
    runtimeInputs = [
      cw.calibrePackage
      pkgs.coreutils
      pkgs.curl
    ];
    text = ''
      library="${cfg.libraryDir}"
      HOME="$(mktemp -d)"
      export HOME
      trap 'rm -rf "$HOME"' EXIT

      reconnect() {
        curl -fsS "http://127.0.0.1:${toString cfg.port}/reconnect" >/dev/null || true
      }

      if [ "$#" -gt 0 ]; then
        calibredb add --library-path "$library" --recurse --automerge ignore "$@"
        reconnect
        exit 0
      fi

      stamp="${dataDir}/last-import"
      list="$HOME/new-files"
      touch "$stamp.next"

      newer=()
      if [ -e "$stamp" ]; then
        newer=(-cnewer "$stamp")
      fi

      find "${cfg.ebooksDir}" -type f "''${newer[@]}" \( \
        -iname '*.epub' -o -iname '*.kepub' -o -iname '*.azw' -o -iname '*.azw3' \
        -o -iname '*.mobi' -o -iname '*.pdf' -o -iname '*.fb2' -o -iname '*.cbz' \
      \) -print0 >"$list"

      if [ -s "$list" ]; then
        xargs -0 -n 50 calibredb add --library-path "$library" --automerge ignore <"$list" \
          || echo "calibredb reported errors for some files"
        reconnect
      fi

      mv "$stamp.next" "$stamp"
    '';
  };
in
{
  options.homelab.calibre-web = {
    enable = lib.mkEnableOption "Calibre-Web ebook library with OPDS for KOReader";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8083;
      description = "Port Calibre-Web listens on. Kept in sync with the `ebooks` entry in edge-services.nix.";
    };

    libraryDir = lib.mkOption {
      type = lib.types.str;
      default = "${dataDir}/library";
      description = "Calibre library (metadata.db and book files). Kept off the mergerfs pool so the cache mover never moves the open database.";
    };

    ebooksDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.homelab.mediaDir}/books/ebooks";
      description = "Ebook folder managed by Chaptarr; new files in it are added to the Calibre library on a timer.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.calibre-web = {
      enable = true;
      user = user.userName;
      group = "multimedia";
      listen = {
        ip = "0.0.0.0";
        port = cfg.port;
      };
      openFirewall = true;
      options = {
        calibreLibrary = cfg.libraryDir;
        enableBookUploading = true;
        enableBookConversion = true;
      };
    };

    systemd.services.calibre-web.serviceConfig.ExecStart = lib.mkForce (
      "${cw.package}/bin/calibre-web -p ${dataDir}/app.db -g ${dataDir}/gdrive.db"
      + " -i ${cw.listen.ip} -r"
    );

    systemd.tmpfiles.rules = [
      "d ${cfg.libraryDir} 0770 ${user.userName} multimedia"
    ];

    systemd.services.calibre-web-library-init = {
      description = "Create an empty Calibre library for Calibre-Web";
      before = [ "calibre-web.service" ];
      requiredBy = [ "calibre-web.service" ];
      after = [ "systemd-tmpfiles-setup.service" ];
      unitConfig.ConditionPathExists = "!${cfg.libraryDir}/metadata.db";
      serviceConfig = {
        Type = "oneshot";
        User = user.userName;
        Group = "multimedia";
        PrivateTmp = true;
        Environment = [
          "HOME=/tmp"
          "CALIBRE_CONFIG_DIRECTORY=/tmp/calibre"
        ];
      };
      script = ''
        ${cw.calibrePackage}/bin/calibre-debug -c \
          "from calibre.db.backend import DB; DB('${cfg.libraryDir}')"
      '';
    };

    environment.systemPackages = [ importScript ];

    systemd.services.calibre-web-import = {
      description = "Add new ebooks from ${cfg.ebooksDir} to the Calibre library";
      after = [
        "calibre-web.service"
        "mnt-pool.mount"
      ];
      requires = [ "mnt-pool.mount" ];
      serviceConfig = {
        Type = "oneshot";
        User = user.userName;
        Group = "multimedia";
        ExecStart = lib.getExe importScript;
      };
    };

    systemd.timers.calibre-web-import = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/15";
        Persistent = true;
      };
    };
  };
}
