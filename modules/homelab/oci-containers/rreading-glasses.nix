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

    sops.templates."rreading-glasses-env" = {
      content = ''
        POSTGRES_PASSWORD=${config.sops.placeholder."rreading-glasses/postgres-password"}
      '';
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # PostgreSQL database for rreading-glasses
    virtualisation.oci-containers.containers.rreading-glasses-db = {
      image = "postgres:17";
      autoStart = true;

      volumes = [
        "/home/${user.userName}/rreading-glasses/db:/var/lib/postgresql/data"
      ];

      environmentFiles = [
        config.sops.templates."rreading-glasses-env".path
      ];
    };

    # rreading-glasses metadata proxy (Goodreads source)
    virtualisation.oci-containers.containers.rreading-glasses = {
      image = "blampe/rreading-glasses:latest";
      autoStart = true;
      dependsOn = [ "rreading-glasses-db" ];

      ports = [ "8788:8788" ];

      environmentFiles = [
        config.sops.templates."rreading-glasses-env".path
      ];
    };

    systemd.services.docker-rreading-glasses-db = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
    };

    systemd.services.docker-rreading-glasses = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
    };
  };
}
