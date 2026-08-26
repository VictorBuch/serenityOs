{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.homelab.samba;
  hl = config.homelab;

  passwordFile = config.sops.secrets.${cfg.passwordSecret}.path;

  shareOpts =
    { name, ... }:
    {
      options = {
        path = lib.mkOption {
          type = lib.types.str;
          description = "Directory on the pool to export.";
        };

        comment = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Description shown next to the share in a file manager.";
        };

        group = lib.mkOption {
          type = lib.types.str;
          description = ''
            Unix group new files and directories are forced into. This has to
            match whatever else writes into the directory, or the other side
            ends up with files it cannot touch.
          '';
        };

        readOnly = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Export the share without write access.";
        };

        createMask = lib.mkOption {
          type = lib.types.str;
          default = "0660";
          description = "Upper bound on the permissions of files created over SMB.";
        };

        directoryMask = lib.mkOption {
          type = lib.types.str;
          default = "2770";
          description = ''
            Upper bound on the permissions of directories created over SMB. The
            setgid bit is allowed through so children keep inheriting `group`,
            the way the tmpfiles rules for these trees already set them up.
          '';
        };

        forceCreateMode = lib.mkOption {
          type = lib.types.str;
          default = "0060";
          description = ''
            Permissions always granted on new files. The masks above only cap
            permissions; this is what actually guarantees group read/write, so
            copyparty, Syncthing and the *arr stack can still touch anything
            dropped in over SMB.
          '';
        };

        forceDirectoryMode = lib.mkOption {
          type = lib.types.str;
          default = "2070";
          description = "Permissions always granted on new directories (group rwx + setgid).";
        };
      };
    };

  mkShare = share: {
    inherit (share) path comment;
    "browseable" = "yes";
    "read only" = if share.readOnly then "yes" else "no";
    "guest ok" = "no";
    "valid users" = [ cfg.user ];
    "force group" = share.group;
    "create mask" = share.createMask;
    "directory mask" = share.directoryMask;
    "force create mode" = share.forceCreateMode;
    "force directory mode" = share.forceDirectoryMode;
  }
  // lib.optionalAttrs (cfg.recycleBin && !share.readOnly) {
    # Deleting from an SMB mount in Dolphin bypasses the local trash and is
    # permanent, and snapraid is parity rather than backup -- its next daily
    # sync propagates the delete. So keep a per-user recycle bin on the share.
    "vfs objects" = [ "recycle" ];
    "recycle:repository" = ".recycle/%U";
    "recycle:keeptree" = "yes";
    "recycle:versions" = "yes";
    "recycle:touch" = "yes";
    "recycle:exclude" = [
      "*.tmp"
      "*.part"
      "~$*"
    ];
  };
in
{
  ###########################################################################
  # samba -- the "mount it like a NAS" half of the file story.
  #
  # copyparty (services/copyparty.nix) is the browser UI and Syncthing
  # (services/filesync.nix) is the two-way sync client; neither gives you a
  # drive you can open in Dolphin, drag files into, and have applications read
  # from in place. That is what SMB is here for.
  #
  # This is a LAN/Tailscale-only service on purpose. SMB never goes through
  # Caddy or the Pangolin tunnel -- `hosts allow` below is the backstop that
  # keeps it that way even if the firewall is ever opened wider.
  ###########################################################################
  options.homelab.samba = {
    enable = lib.mkEnableOption "Samba file shares for the storage pool (LAN/Tailscale only)";

    user = lib.mkOption {
      type = lib.types.str;
      default = config.user.userName;
      description = ''
        Unix account the shares authenticate against. Samba keeps its own
        password database, so this account additionally needs an SMB password --
        it is set from the sops secret named by `passwordSecret`.
      '';
    };

    passwordSecret = lib.mkOption {
      type = lib.types.str;
      default = "samba/password";
      description = ''
        sops secret holding the SMB password for `user`. Deliberately separate
        from the Unix login password: Samba cannot read /etc/shadow.
      '';
    };

    workgroup = lib.mkOption {
      type = lib.types.str;
      default = "WORKGROUP";
      description = "SMB workgroup name. Leave as WORKGROUP unless the network uses another.";
    };

    serverString = lib.mkOption {
      type = lib.types.str;
      default = "mal";
      description = "Name shown for this server when browsing the network.";
    };

    hostsAllow = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "192.168.0.0/24" # LAN
        "100.64.0.0/10" # Tailscale CGNAT range
        "127.0.0.1"
      ];
      description = ''
        Networks allowed to reach the shares. Everything else is refused by
        smbd itself, independent of the firewall.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Open the SMB ports. Safe here because mal has no direct WAN ingress
        (external traffic arrives through the Pangolin tunnel, not the LAN
        interface) and `hostsAllow` restricts callers regardless.
      '';
    };

    discovery = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Announce the server over NetBIOS (nmbd) and WS-Discovery (wsdd) so it
        appears under Network in Dolphin and Windows Explorer instead of having
        to be typed in as smb://<ip>/.
      '';
    };

    minProtocol = lib.mkOption {
      type = lib.types.str;
      default = "SMB2_10";
      description = ''
        Oldest SMB dialect accepted. SMB1 is never enabled. Raise to SMB3_00 if
        nothing on the network is older than Windows 8 / Kodi.
      '';
    };

    recycleBin = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Move deleted files to a `.recycle/<user>` folder inside each writable
        share instead of unlinking them. Nothing prunes it automatically --
        empty it by hand when the pool gets tight.
      '';
    };

    shares = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule shareOpts);
      default = {
        files = {
          path = hl.filesDir;
          comment = "Shared files (same tree as copyparty and Syncthing)";
          group = "files";
          createMask = "0664";
          directoryMask = "2775";
        };
        media = {
          path = hl.mediaDir;
          comment = "Movies, TV, music and books";
          group = "multimedia";
        };
      };
      description = "Directories to export over SMB, keyed by share name.";
    };
  };

  config = lib.mkIf cfg.enable {
    # smbd writes as `user`, so it needs the same group memberships the other
    # writers of these trees have. filesync.nix already adds `files` when it is
    # enabled; deriving the list from the shares keeps SMB working on its own.
    users.users.${cfg.user}.extraGroups = lib.unique (
      lib.mapAttrsToList (_: share: share.group) cfg.shares
    );

    sops.secrets.${cfg.passwordSecret} = {
      mode = "0400";
      owner = "root";
      group = "root";
      restartUnits = [ "samba-set-password.service" ];
    };

    services.samba = {
      enable = true;
      inherit (cfg) openFirewall;
      nmbd.enable = cfg.discovery;
      # Standalone server with a local password database -- there is no domain
      # to join, so winbindd has nothing to do.
      winbindd.enable = false;

      settings = {
        global = {
          "workgroup" = cfg.workgroup;
          "server string" = cfg.serverString;
          "netbios name" = config.networking.hostName;
          "server role" = "standalone server";
          "security" = "user";
          "map to guest" = "never";
          "guest account" = "nobody";

          # allow wins over deny, so this is default-deny with an allowlist.
          "hosts allow" = cfg.hostsAllow;
          "hosts deny" = [ "0.0.0.0/0" ];

          "server min protocol" = cfg.minProtocol;
          "client min protocol" = cfg.minProtocol;
          # Encrypt where the client can, without locking out ones that cannot.
          "smb encrypt" = "desired";

          # Nothing here is a print server, and an unconfigured one otherwise
          # advertises a bogus printer share.
          "load printers" = "no";
          "printing" = "bsd";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";

          # Symlinks may be followed inside a share but never out of it.
          "follow symlinks" = "yes";
          "wide links" = "no";
          "unix extensions" = "no";

          "logging" = "systemd";
        }
        // lib.optionalAttrs cfg.discovery {
          # Only meaningful with nmbd running.
          "local master" = "yes";
          "preferred master" = "yes";
          "domain master" = "no";
        };
      }
      // lib.mapAttrs (_: mkShare) cfg.shares;
    };

    # WS-Discovery is what current Dolphin and Windows Explorer actually use to
    # populate "Network"; NetBIOS alone no longer gets the host listed there.
    services.samba-wsdd = lib.mkIf cfg.discovery {
      enable = true;
      inherit (cfg) workgroup openFirewall;
      hostname = config.networking.hostName;
    };

    # Samba's password database is separate from the Unix one and lives in a
    # tdb, so it has to be seeded imperatively. smbpasswd is idempotent: this
    # re-applies the secret on every boot, and sops restarts it on rotation.
    systemd.services.samba-set-password = {
      description = "Seed the Samba password for ${cfg.user}";
      wantedBy = [ "samba.target" ];
      before = [ "samba-smbd.service" ];
      after = [ "systemd-tmpfiles-setup.service" ];
      unitConfig.ConditionPathExists = passwordFile;

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        password=$(cat ${passwordFile})
        printf '%s\n%s\n' "$password" "$password" \
          | ${config.services.samba.package}/bin/smbpasswd -s -a ${cfg.user}
        ${config.services.samba.package}/bin/smbpasswd -e ${cfg.user}
      '';
    };

    # smbd will not start before the pool is there, and a share pointing at an
    # empty mountpoint would happily accept writes onto the root filesystem.
    systemd.services.samba-smbd = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
    };

    # The recycle bin needs a root to live under; smbd creates the per-user
    # subdirectory below it on the first delete.
    systemd.tmpfiles.rules = lib.optionals cfg.recycleBin (
      lib.mapAttrsToList (_: share: "d ${share.path}/.recycle 2770 root ${share.group} -") (
        lib.filterAttrs (_: share: !share.readOnly) cfg.shares
      )
    );
  };
}
