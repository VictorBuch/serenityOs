# BookOrbit - self-hosted ebook library and reader
# https://github.com/bookorbit/bookorbit
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.homelab.bookorbit;
  hl = config.homelab;
  dataDir = "/var/lib/bookorbit";
  network = "bookorbit-net";
in
{
  options.homelab.bookorbit.enable = lib.mkEnableOption "BookOrbit ebook library";

  config = lib.mkIf cfg.enable {
    homelab.records.bookorbit = {
      subdomain = "books";
      port = 3060;
      exposure = "public";
      tile = {
        title = "BookOrbit";
        icon = "sh:bookorbit";
        group = "media";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${dataDir} 0755 root root"
      "d ${dataDir}/app 0755 root root"
      "d ${dataDir}/postgres 0755 root root"
    ];

    systemd.services.bookorbit-network = {
      description = "Create Docker network for BookOrbit";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "create-bookorbit-network" ''
          ${pkgs.docker}/bin/docker network inspect ${network} >/dev/null 2>&1 || \
          ${pkgs.docker}/bin/docker network create ${network}
        '';
      };
    };

    sops.secrets = {
      "bookorbit/db_password" = { };
      "bookorbit/jwt_secret" = { };
      "bookorbit/podcast_encryption_key" = { };
      "bookorbit/setup_bootstrap_token" = { };
      "bookorbit/book_request_encryption_key" = { };
    };

    sops.templates."bookorbit-env" = {
      content = ''
        POSTGRES_PASSWORD=${config.sops.placeholder."bookorbit/db_password"}
        JWT_SECRET=${config.sops.placeholder."bookorbit/jwt_secret"}
        PODCAST_ENCRYPTION_KEY=${config.sops.placeholder."bookorbit/podcast_encryption_key"}
        SETUP_BOOTSTRAP_TOKEN=${config.sops.placeholder."bookorbit/setup_bootstrap_token"}
        BOOK_REQUEST_ENCRYPTION_KEY=${config.sops.placeholder."bookorbit/book_request_encryption_key"}
      '';
      mode = "0400";
    };

    virtualisation.oci-containers.containers.bookorbit-db = {
      image = "pgvector/pgvector:pg18";
      autoStart = true;
      environment = {
        POSTGRES_USER = "bookorbit";
        POSTGRES_DB = "bookorbit";
        PGDATA = "/var/lib/postgresql/data/pgdata";
      };
      environmentFiles = [ config.sops.templates."bookorbit-env".path ];
      volumes = [ "${dataDir}/postgres:/var/lib/postgresql/data" ];
      extraOptions = [
        "--network=${network}"
        "--health-cmd=pg_isready -U bookorbit -d bookorbit"
        "--health-interval=10s"
        "--health-timeout=5s"
        "--health-retries=10"
        "--health-start-period=20s"
      ];
    };

    virtualisation.oci-containers.containers.bookorbit = {
      image = "ghcr.io/bookorbit/bookorbit:latest";
      autoStart = true;
      dependsOn = [ "bookorbit-db" ];
      ports = [ "${toString hl.records.bookorbit.port}:3000" ];
      environment = {
        NODE_ENV = "production";
        PORT = "3000";
        POSTGRES_HOST = "bookorbit-db";
        POSTGRES_PORT = "5432";
        POSTGRES_USER = "bookorbit";
        POSTGRES_DB = "bookorbit";
        APP_URL = hl.records.bookorbit.url;
        TZ = config.time.timeZone;
        PUID = toString config.user.uid;
        PGID = toString config.users.groups.multimedia.gid;
        LIBRARY_BROWSE_ROOT = "/books";
      };
      environmentFiles = [ config.sops.templates."bookorbit-env".path ];
      volumes = [
        "${hl.mediaDir}/books:/books"
        "${dataDir}/app:/data"
      ];
      extraOptions = [
        "--network=${network}"
        "--init"
        "--read-only"
        "--tmpfs=/tmp"
        "--cap-drop=ALL"
        "--cap-add=CHOWN"
        "--cap-add=DAC_OVERRIDE"
        "--cap-add=FOWNER"
        "--cap-add=SETGID"
        "--cap-add=SETUID"
        "--security-opt=no-new-privileges:true"
      ];
    };

    systemd.services.docker-bookorbit-db = {
      after = [ "bookorbit-network.service" ];
      requires = [ "bookorbit-network.service" ];
    };

    systemd.services.docker-bookorbit = {
      after = [
        "bookorbit-network.service"
        "mnt-pool.mount"
      ];
      requires = [
        "bookorbit-network.service"
        "mnt-pool.mount"
      ];
    };
  };
}
