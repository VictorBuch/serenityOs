{
  flake.modules.nixos.homelab =
    {
      config,
      lib,
      pkgs,
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
      };

      config = {
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

        sops.secrets = {
          "romm/retroachievements_api_key" = { };
          "romm/igdb_client_id" = { };
          "romm/igdb_client_secret" = { };
        };

        sops.templates."romm.env" = {
          content = ''
            RETROACHIEVEMENTS_API_KEY=${config.sops.placeholder."romm/retroachievements_api_key"}
            IGDB_CLIENT_ID=${config.sops.placeholder."romm/igdb_client_id"}
            IGDB_CLIENT_SECRET=${config.sops.placeholder."romm/igdb_client_secret"}
          '';
          mode = "0400";
          restartUnits = map (unit: "${unit}.service") units;
        };

        services.romm = {
          enable = true;
          # ponytail: nixpkgs romm 5.4.1 ships patcher.js without its npm dep; drop once upstream vendors it
          package = pkgs.romm.overrideAttrs (old: {
            postInstall = (old.postInstall or "") + ''
              cp -r ${
                pkgs.fetchFromGitHub {
                  owner = "marcrobledo";
                  repo = "RomPatcher.js";
                  rev = "91e522e247f709e894761157ccba3189004d0859";
                  hash = "sha256-bIEvna+8Xfb+np8V3vFRPxtWrlNjEKd0CDp2ayoKnGM=";
                }
              }/rom-patcher-js $out/share/romm/backend/utils/rom_patcher/rom-patcher-js
            '';
          });
          port = apiPort;
          redis.port = redisPort;
          nginx.virtualHost = vhost;
          environmentFile = config.sops.templates."romm.env".path;
          extraEnvironment = {
            ROMM_BASE_URL = romm.url;
            ROMM_SESSION_SECURE_COOKIE = "true";
            ENABLE_SCHEDULED_RESCAN = "true";
            HASHEOUS_API_ENABLED = "true";
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

        systemd.services =
          lib.recursiveUpdate
            (lib.genAttrs units (_: {
              unitConfig.RequiresMountsFor = [ mountPoint ];
              serviceConfig.UMask = "0002";
            }))
            {
              # ponytail: nixpkgs romm-worker omits the `scans` queue (5.4.1); drop once upstream fixes the launch script
              romm-worker.serviceConfig.ExecStart = lib.mkForce "${config.services.romm.package}/bin/romm-worker scans";
            };
      };
    };
}
