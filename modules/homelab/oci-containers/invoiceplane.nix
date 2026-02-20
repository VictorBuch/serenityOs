{
  pkgs,
  lib,
  options,
  config,
  ...
}:

let
  user = config.user;
  uid = toString config.user.uid;
  domain = config.homelab.domain;
in

{
  options.invoiceplane.enable = lib.mkEnableOption "Enables the InvoicePlane invoicing application with a dedicated MariaDB database";

  config = lib.mkIf config.invoiceplane.enable {
    networking.firewall.allowedTCPPorts = [ 8380 ];

    systemd.tmpfiles.rules = [
      "d /var/lib/invoiceplane 755 root root"
      "d /var/lib/invoiceplane/uploads 755 root root"
      "d /var/lib/invoiceplane/db 755 root root"
    ];

    # SOPS secrets for database credentials
    sops.secrets."invoiceplane/mysql_password" = {
      owner = "root";
      group = "root";
    };
    sops.secrets."invoiceplane/mysql_root_password" = {
      owner = "root";
      group = "root";
    };

    # Environment file for the InvoicePlane container
    sops.templates."invoiceplane-env" = {
      content = ''
        MYSQL_PASSWORD=${config.sops.placeholder."invoiceplane/mysql_password"}
      '';
    };

    # Environment file for the MariaDB container
    sops.templates."invoiceplane-db-env" = {
      content = ''
        MYSQL_PASSWORD=${config.sops.placeholder."invoiceplane/mysql_password"}
        MYSQL_ROOT_PASSWORD=${config.sops.placeholder."invoiceplane/mysql_root_password"}
      '';
    };

    # Create a Docker network so InvoicePlane can reach MariaDB by container name
    systemd.services.docker-invoiceplane-network = {
      description = "Create Docker network for InvoicePlane";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      before = [
        "docker-invoiceplane.service"
        "docker-invoiceplane-db.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.docker}/bin/docker network inspect invoiceplane-net >/dev/null 2>&1 || \
          ${pkgs.docker}/bin/docker network create invoiceplane-net
      '';
      preStop = ''
        ${pkgs.docker}/bin/docker network rm invoiceplane-net || true
      '';
      wantedBy = [ "multi-user.target" ];
    };

    # Ensure both containers start after the network is created
    systemd.services.docker-invoiceplane = {
      after = [ "docker-invoiceplane-network.service" ];
      requires = [ "docker-invoiceplane-network.service" ];
    };
    systemd.services.docker-invoiceplane-db = {
      after = [ "docker-invoiceplane-network.service" ];
      requires = [ "docker-invoiceplane-network.service" ];
    };

    virtualisation.oci-containers.containers.invoiceplane-db = {
      image = "mariadb:10.11";
      volumes = [
        "/var/lib/invoiceplane/db:/var/lib/mysql"
      ];
      environment = {
        MYSQL_DATABASE = "invoiceplane";
        MYSQL_USER = "invoiceplane";
        TZ = "Europe/Prague";
      };
      environmentFiles = [
        config.sops.templates."invoiceplane-db-env".path
      ];
      extraOptions = [ "--network=invoiceplane-net" ];
      autoStart = true;
    };

    virtualisation.oci-containers.containers.invoiceplane = {
      image = "mhzawadi/invoiceplane:latest";
      ports = [ "8380:80" ];
      volumes = [
        "/var/lib/invoiceplane/uploads:/var/www/html/uploads"
      ];
      environment = {
        MYSQL_HOST = "invoiceplane-db";
        MYSQL_USER = "invoiceplane";
        MYSQL_DB = "invoiceplane";
        MYSQL_PORT = "3306";
        IP_URL = "https://invoiceplane.${domain}";
        REMOVE_INDEXPHP = "true";
        TZ = "Europe/Prague";
      };
      environmentFiles = [
        config.sops.templates."invoiceplane-env".path
      ];
      dependsOn = [ "invoiceplane-db" ];
      extraOptions = [ "--network=invoiceplane-net" ];
      autoStart = true;
    };
  };
}
