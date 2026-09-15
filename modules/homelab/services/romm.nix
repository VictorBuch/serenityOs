{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab.romm;
  hl = config.homelab;
  domain = hl.domain;
  vhost = "romm.${domain}";
  mountPoint = "${config.services.romm.dataDir}/library";
  units = [
    "romm"
    "romm-worker"
    "romm-scheduler"
  ]
  ++ lib.optional config.services.romm.watcher.enable "romm-watcher";
in
{
  options.homelab.romm = {
    enable = lib.mkEnableOption "RomM ROM manager on romm.<domain>";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8093;
      description = "Loopback port of the nginx vhost serving RomM. Kept in sync with the `romm` entry in edge-services.nix.";
    };

    apiPort = lib.mkOption {
      type = lib.types.port;
      default = 8092;
      description = "Loopback port of the RomM API behind nginx (8080 belongs to glance).";
    };

    redisPort = lib.mkOption {
      type = lib.types.port;
      default = 6383;
      description = "Port of RomM's dedicated Redis instance.";
    };

    libraryDir = lib.mkOption {
      type = lib.types.str;
      default = "${hl.filesDir}/games";
      description = ''
        ROM library on the pool, bind-mounted over RomM's fixed library path.
        Lives under homelab.filesDir so copyparty, the `files` SMB share and
        Syncthing can all drop ROMs into it.
      '';
    };

    platforms = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "ps2"
        "psx"
        "psp"
        "gba"
        "gbc"
        "nds"
        "snes"
        "n64"
        "ngc"
        "wii"
      ];
      description = "RomM platform slugs to pre-create as roms/<slug> drop folders.";
    };

    igdb.enable = lib.mkEnableOption "IGDB metadata from the sops secrets romm/igdb_client_id and romm/igdb_client_secret";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.mkIf cfg.igdb.enable {
      "romm/igdb_client_id" = { };
      "romm/igdb_client_secret" = { };
    };

    sops.templates."romm.env" = lib.mkIf cfg.igdb.enable {
      content = ''
        IGDB_CLIENT_ID=${config.sops.placeholder."romm/igdb_client_id"}
        IGDB_CLIENT_SECRET=${config.sops.placeholder."romm/igdb_client_secret"}
      '';
      mode = "0400";
      restartUnits = map (unit: "${unit}.service") units;
    };

    services.romm = {
      enable = true;
      port = cfg.apiPort;
      redis.port = cfg.redisPort;
      nginx.virtualHost = vhost;
      environmentFile = lib.mkIf cfg.igdb.enable config.sops.templates."romm.env".path;
      extraEnvironment = {
        ROMM_BASE_URL = "https://${vhost}";
        ROMM_SESSION_SECURE_COOKIE = "true";
        ENABLE_SCHEDULED_RESCAN = "true";
      };
    };

    services.nginx.virtualHosts.${vhost}.listen = [
      {
        addr = "127.0.0.1";
        port = cfg.port;
      }
    ];

    users.users.romm.extraGroups = [ "files" ];
    users.users.${config.services.nginx.user}.extraGroups = [ "files" ];

    systemd.tmpfiles.rules = [
      "d ${cfg.libraryDir} 2770 romm files -"
      "d ${cfg.libraryDir}/roms 2770 romm files -"
      "d ${cfg.libraryDir}/bios 2770 romm files -"
    ]
    ++ map (platform: "d ${cfg.libraryDir}/roms/${platform} 2770 romm files -") cfg.platforms;

    systemd.tmpfiles.settings."10-romm".${mountPoint}.d = {
      mode = lib.mkForce "2770";
      group = lib.mkForce "files";
    };

    fileSystems.${mountPoint} = {
      device = cfg.libraryDir;
      fsType = "none";
      options = [
        "bind"
        "nofail"
        "x-systemd.requires=mnt-pool.mount"
        "x-systemd.after=systemd-tmpfiles-setup.service"
      ];
    };

    systemd.services = lib.genAttrs units (_: {
      unitConfig.RequiresMountsFor = [ mountPoint ];
      serviceConfig.UMask = "0002";
    });
  };
}
