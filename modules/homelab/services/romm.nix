{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab.romm;
  hl = config.homelab;
  romm = hl.records.romm;
  vhost = "${romm.subdomain}.${romm.domain}";
  # Behind nginx, loopback only
  apiPort = 8094;
  redisPort = 6383;
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
    homelab.records.romm = {
      port = 8093;
      exposure = "public";
      tile = {
        title = "RomM";
        icon = "sh:romm";
        group = "productivity";
      };
    };
    homelab.ports.romm = [
      apiPort
      redisPort
    ];

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
      port = apiPort;
      redis.port = redisPort;
      nginx.virtualHost = vhost;
      environmentFile = lib.mkIf cfg.igdb.enable config.sops.templates."romm.env".path;
      extraEnvironment = {
        ROMM_BASE_URL = romm.url;
        ROMM_SESSION_SECURE_COOKIE = "true";
        ENABLE_SCHEDULED_RESCAN = "true";
      };
    };

    services.nginx.virtualHosts.${vhost}.listen = [
      {
        addr = "127.0.0.1";
        inherit (romm) port;
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
