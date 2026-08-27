{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.homelab.copyparty;
  hl = config.homelab;
  domain = hl.domain;
  filesDir = hl.filesDir;

  # Static half of the config: everything that is not a secret, so it can live
  # in the nix store. Copyparty's format is INI-ish; two-space indent under a
  # section header is significant.
  mainConf = pkgs.writeText "copyparty.conf" ''
    [global]
      # Loopback only — Caddy fronts this on files.${domain} (see edge-services.nix)
      i: ${cfg.address}
      p: ${toString cfg.port}
      name: ${cfg.serverName}

      # Index files + media tags so search and thumbnails work
      e2dsa
      e2ts
      grid

      # Keep the index/thumb databases off the mergerfs pool: they are churny
      # sqlite writes that snapraid has no business versioning.
      hist: /var/lib/copyparty/hist
      shr-db: /var/lib/copyparty/shares.db
      ses-db: /var/lib/copyparty/sessions.db

      # Share links: /share/<key>, created by any logged-in user, expiring.
      # shr-site pins the public origin so links are copyable as-is.
      shr: /share
      shr-who: auth
      shr-site: https://files.${domain}/

      # Trust the closest proxy (Caddy on loopback) for the client IP. Caddy's
      # serviceBody sets X-Forwarded-For to {client_ip}, replacing rather than
      # appending, so the resolved client is the only value present — and
      # without this copyparty refuses to use the header at all and warns on
      # every single request.
      rproxy: -1

      # Stop accepting uploads if the pool drops below this many GB free
      df: ${toString cfg.minFreeGB}

      no-robots

    [/]
      ${filesDir}
      accs:
        rwmda: ${cfg.account}
  '';
in
{
  ###########################################################################
  # copyparty — the file UI half of the NAS. Browse/upload/download over http,
  # WebDAV, and share links with expiry for the rare external hand-off.
  #
  # It deliberately does NOT sync: copyparty ships no two-way client (its u2c
  # CLI is a one-way local->server mirror). Two-way sync of the same directory
  # is Syncthing's job — see services/filesync.nix.
  #
  # Both write into homelab.filesDir as members of the `files` group, which is
  # created alongside the directory in storage.nix.
  ###########################################################################
  options.homelab.copyparty = {
    enable = lib.mkEnableOption "copyparty file server on files.<domain>";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.copyparty;
      description = "copyparty package to run.";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind. Loopback by default; Caddy reverse-proxies it.";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 3923;
      description = "Port copyparty listens on. Kept in sync with the `files` entry in edge-services.nix.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "copyparty";
      description = "System user the service runs as.";
    };

    account = lib.mkOption {
      type = lib.types.str;
      default = config.user.userName;
      description = ''
        copyparty login name granted read/write/move/delete/admin on the volume.
        Its password comes from the sops secret `copyparty/password`.
      '';
    };

    serverName = lib.mkOption {
      type = lib.types.str;
      default = "mal";
      description = "Server name shown top-left in the web UI.";
    };

    minFreeGB = lib.mkOption {
      type = lib.types.int;
      default = 16;
      description = "Refuse uploads when the pool has less than this many GB free.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Password is rendered into a second config file at runtime so it never
    # reaches the nix store. Listed before mainConf on the command line so the
    # account exists by the time the volume's accs block references it.
    sops.secrets."copyparty/password" = { };

    sops.templates."copyparty-accounts.conf" = {
      content = ''
        [accounts]
          ${cfg.account}: ${config.sops.placeholder."copyparty/password"}
      '';
      owner = cfg.user;
      group = "files";
      mode = "0400";
      restartUnits = [ "copyparty.service" ];
    };

    users.users.${cfg.user} = {
      isSystemUser = true;
      description = "copyparty file server";
      group = cfg.user;
      extraGroups = [ "files" ];
      home = "/var/lib/copyparty";
    };
    users.groups.${cfg.user} = { };

    systemd.services.copyparty = {
      description = "copyparty file server";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "mnt-pool.mount"
      ];
      requires = [ "mnt-pool.mount" ];

      environment = {
        PYTHONUNBUFFERED = "x";
        XDG_CONFIG_HOME = "/var/lib/copyparty";
      };

      serviceConfig = {
        # copyparty speaks sd_notify, so dependants wait for a listening socket
        Type = "notify";
        User = cfg.user;
        Group = cfg.user;
        # Group-writable output so Syncthing (running as ${config.user.userName})
        # can update files copyparty created, and vice versa.
        UMask = "0002";
        ExecStart = "${cfg.package}/bin/copyparty -c ${config.sops.templates."copyparty-accounts.conf".path} -c ${mainConf}";
        ExecReload = "${pkgs.coreutils}/bin/kill -s USR1 $MAINPID";
        Restart = "on-failure";
        RestartSec = 5;
        StateDirectory = "copyparty";
        WorkingDirectory = "/var/lib/copyparty";

        # Hardening — copyparty only ever touches its state dir and the pool.
        NoNewPrivileges = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
      };
    };
  };
}
