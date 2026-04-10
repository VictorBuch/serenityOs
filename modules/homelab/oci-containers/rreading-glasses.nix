{
  config,
  pkgs,
  lib,
  ...
}:

let
  user = config.user;
in

{
  options.rreading-glasses.enable = lib.mkEnableOption "Enables rreading-glasses book metadata proxy for Readarr";

  config = lib.mkIf config.rreading-glasses.enable {
    networking.firewall.allowedTCPPorts = [ 8788 ];

    systemd.tmpfiles.rules = [
      "d /home/${user.userName}/rreading-glasses 775 ${user.userName} ${user.group}"
      "d /home/${user.userName}/rreading-glasses/db 775 ${user.userName} ${user.group}"
    ];

    sops.templates."rreading-glasses-db-env" = {
      content = ''
        POSTGRES_USER=rreading-glasses
        POSTGRES_DB=rreading-glasses
        POSTGRES_PASSWORD=${config.sops.placeholder."rreading-glasses/postgres-password"}
      '';
      owner = "root";
      group = "root";
      mode = "0400";
    };

    sops.templates."rreading-glasses-env" = {
      content = ''
        POSTGRES_HOST=rreading-glasses-db
        POSTGRES_USER=rreading-glasses
        POSTGRES_DATABASE=rreading-glasses
        POSTGRES_PASSWORD=${config.sops.placeholder."rreading-glasses/postgres-password"}
      '';
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # Docker network for rreading-glasses containers
    systemd.services.rreading-glasses-network = {
      description = "Create Docker network for rreading-glasses";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.docker}/bin/docker network inspect rreading-glasses-net >/dev/null 2>&1 || \
          ${pkgs.docker}/bin/docker network create rreading-glasses-net
      '';
      preStop = ''
        ${pkgs.docker}/bin/docker network rm rreading-glasses-net || true
      '';
      wantedBy = [ "multi-user.target" ];
    };

    # PostgreSQL database for rreading-glasses
    virtualisation.oci-containers.containers.rreading-glasses-db = {
      image = "postgres:17";
      autoStart = true;

      volumes = [
        "/home/${user.userName}/rreading-glasses/db:/var/lib/postgresql/data"
      ];

      environmentFiles = [
        config.sops.templates."rreading-glasses-db-env".path
      ];

      extraOptions = [ "--network=rreading-glasses-net" ];
    };

    # rreading-glasses metadata proxy (Goodreads source)
    virtualisation.oci-containers.containers.rreading-glasses = {
      image = "blampe/rreading-glasses:latest";
      autoStart = true;
      dependsOn = [ "rreading-glasses-db" ];
      cmd = [ "/main" "serve" ];

      ports = [ "8788:8788" ];

      environmentFiles = [
        config.sops.templates."rreading-glasses-env".path
      ];

      extraOptions = [ "--network=rreading-glasses-net" ];
    };

    systemd.services.docker-rreading-glasses-db = {
      after = [ "mnt-pool.mount" "rreading-glasses-network.service" ];
      requires = [ "mnt-pool.mount" "rreading-glasses-network.service" ];
    };

    systemd.services.docker-rreading-glasses = {
      after = [ "mnt-pool.mount" "rreading-glasses-network.service" ];
      requires = [ "mnt-pool.mount" "rreading-glasses-network.service" ];
    };
  };
}
