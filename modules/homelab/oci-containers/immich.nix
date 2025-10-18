# Deprecated
{
  config,
  pkgs,
  lib,
  options,
  ...
}:
let
  immichDir = config.homelab.immichDir;
  user = config.user;
  uid = toString config.user.uid; # ghost user UID
  gid = "911"; # users group
in

{

  options = {
    immich-container.enable = lib.mkEnableOption "Enables the immich";
  };

  config = lib.mkIf config.immich-container.enable {
    boot.kernel.sysctl = {
      "vm.overcommit_memory" = lib.mkDefault 1;
    };

    systemd.tmpfiles.rules = [
      "d ${immichDir}/immich 0770 ${uid} ${gid}"
      "d ${immichDir}/immich/photos 0770 ${uid} ${gid}"
      "d ${immichDir}/immich/config 0770 ${uid} ${gid}"
      "d ${immichDir}/immich/config/machine-learning 0770 ${uid} ${gid}"
    ];

    networking.firewall.allowedTCPPorts = [
      2283
      6379
      5432
    ];

    # Immich
    virtualisation.oci-containers.containers = {
      immich = {
        autoStart = true;
        image = "ghcr.io/imagegenius/immich:1.136.0";
        volumes = [
          "${immichDir}/immich/config:/config"
          "${immichDir}/immich/photos:/photos"
          "${immichDir}/immich/config/machine-learning:/config/machine-learning"
        ];
        ports = [ "2283:8080" ];
        environment = {
          TZ = "Europe/Berlin";
          DB_HOSTNAME = "postgres14";
          DB_USERNAME = "postgres";
          DB_PASSWORD = "postgres";
          DB_DATABASE_NAME = "immich";
          REDIS_HOSTNAME = "redis";
          PUID = uid; # ghost user UID
          PGID = gid; # users group
        };
        extraOptions = [ "--network=immich-bridge" ];
      };

      redis = {
        autoStart = true;
        image = "redis";
        ports = [ "6379:6379" ];
        extraOptions = [ "--network=immich-bridge" ];
      };

      postgres14 = {
        autoStart = true;
        # Updated to the new postgres image you mentioned
        image = "ghcr.io/immich-app/postgres:14-vectorchord0.3.0-pgvectors0.2.0";
        ports = [ "5432:5432" ];
        volumes = [
          "pgdata:/var/lib/postgresql/data"
        ];
        environment = {
          POSTGRES_USER = "postgres";
          POSTGRES_PASSWORD = "postgres";
          POSTGRES_DB = "immich";
        };
        extraOptions = [ "--network=immich-bridge" ];
      };
    };

    systemd.services.init-immich-network = {
      description = "Create the network bridge for immich.";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        check=$(${pkgs.docker}/bin/docker network ls | grep "immich-bridge" || true)
        if [ -z "$check" ];
          then ${pkgs.docker}/bin/docker network create immich-bridge
          else echo "immich-bridge already exists in docker"
        fi
      '';
    };
  };
}
