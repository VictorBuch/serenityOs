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
  stateDir = "/var/lib/invoice-ninja";

  # Nginx config files for the Invoice Ninja sidecar
  nginxInvoiceNinjaConf = pkgs.writeText "invoiceninja.conf" ''
    # https://nginx.org/en/docs/http/ngx_http_core_module.html
    client_max_body_size 100M;
    client_body_buffer_size 10M;
    server_tokens off;

    # https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html
    fastcgi_buffers 32 16K;

    # https://nginx.org/en/docs/http/ngx_http_gzip_module.html
    gzip on;
    gzip_comp_level 2;
    gzip_min_length 1M;
    gzip_proxied any;
    gzip_types *;
  '';

  nginxLaravelConf = pkgs.writeText "laravel.conf" ''
    # https://laravel.com/docs/master/deployment#nginx
    server {
        listen 80 default_server;
        server_name _;
        root /var/www/html/public;

        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Content-Type-Options "nosniff";

        index index.php;

        charset utf-8;

        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }

        location = /favicon.ico { access_log off; log_not_found off; }
        location = /robots.txt  { access_log off; log_not_found off; }

        error_page 404 /index.php;

        location ~ \.php$ {
            fastcgi_pass invoiceninja:9000;
            fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
            include fastcgi_params;
        }

        location ~ /\.(?!well-known).* {
            deny all;
        }
    }
  '';
in

{
  options.invoice-ninja.enable = lib.mkEnableOption "Enables the Invoice Ninja invoicing application";

  config = lib.mkIf config.invoice-ninja.enable {
    networking.firewall.allowedTCPPorts = [ 8380 ];

    systemd.tmpfiles.rules = [
      "d ${stateDir} 755 root root"
      "d ${stateDir}/db 755 root root"
      "d ${stateDir}/public 755 root root"
      "d ${stateDir}/storage 755 root root"
      "d ${stateDir}/redis 755 root root"
      "d ${stateDir}/nginx 755 root root"
    ];

    # Copy nginx config files into the state directory
    systemd.services.invoice-ninja-nginx-config = {
      description = "Generate Invoice Ninja nginx config";
      wantedBy = [ "multi-user.target" ];
      before = [ "docker-invoiceninja-nginx.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        cp -f ${nginxInvoiceNinjaConf} ${stateDir}/nginx/invoiceninja.conf
        cp -f ${nginxLaravelConf} ${stateDir}/nginx/laravel.conf
      '';
    };

    # SOPS secrets
    sops.secrets."invoice-ninja/db_password" = {
      owner = "root";
      group = "root";
    };
    sops.secrets."invoice-ninja/db_root_password" = {
      owner = "root";
      group = "root";
    };
    sops.secrets."invoice-ninja/app_key" = {
      owner = "root";
      group = "root";
    };
    sops.secrets."invoice-ninja/in_user_email" = {
      owner = "root";
      group = "root";
    };
    sops.secrets."invoice-ninja/in_password" = {
      owner = "root";
      group = "root";
    };

    # Environment file for the Invoice Ninja app container
    sops.templates."invoiceninja-env" = {
      content = ''
        APP_KEY=${config.sops.placeholder."invoice-ninja/app_key"}
        DB_PASSWORD=${config.sops.placeholder."invoice-ninja/db_password"}
        IN_USER_EMAIL=${config.sops.placeholder."invoice-ninja/in_user_email"}
        IN_PASSWORD=${config.sops.placeholder."invoice-ninja/in_password"}
      '';
    };

    # Environment file for the MySQL container
    sops.templates."invoiceninja-db-env" = {
      content = ''
        MYSQL_PASSWORD=${config.sops.placeholder."invoice-ninja/db_password"}
        MYSQL_ROOT_PASSWORD=${config.sops.placeholder."invoice-ninja/db_root_password"}
      '';
    };

    # Create a Docker network for all Invoice Ninja containers
    systemd.services.docker-invoiceninja-network = {
      description = "Create Docker network for Invoice Ninja";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      before = [
        "docker-invoiceninja.service"
        "docker-invoiceninja-db.service"
        "docker-invoiceninja-redis.service"
        "docker-invoiceninja-nginx.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.docker}/bin/docker network inspect invoiceninja-net >/dev/null 2>&1 || \
          ${pkgs.docker}/bin/docker network create invoiceninja-net
      '';
      preStop = ''
        ${pkgs.docker}/bin/docker network rm invoiceninja-net || true
      '';
      wantedBy = [ "multi-user.target" ];
    };

    # Ensure all containers start after the network is created
    systemd.services.docker-invoiceninja = {
      after = [ "docker-invoiceninja-network.service" ];
      requires = [ "docker-invoiceninja-network.service" ];
    };
    systemd.services.docker-invoiceninja-db = {
      after = [ "docker-invoiceninja-network.service" ];
      requires = [ "docker-invoiceninja-network.service" ];
    };
    systemd.services.docker-invoiceninja-redis = {
      after = [ "docker-invoiceninja-network.service" ];
      requires = [ "docker-invoiceninja-network.service" ];
    };
    systemd.services.docker-invoiceninja-nginx = {
      after = [
        "docker-invoiceninja-network.service"
        "invoice-ninja-nginx-config.service"
      ];
      requires = [
        "docker-invoiceninja-network.service"
        "invoice-ninja-nginx-config.service"
      ];
    };

    # --- MySQL Database ---
    virtualisation.oci-containers.containers.invoiceninja-db = {
      image = "mysql:8";
      volumes = [
        "${stateDir}/db:/var/lib/mysql"
      ];
      environment = {
        MYSQL_DATABASE = "ninja";
        MYSQL_USER = "ninja";
        TZ = "Europe/Prague";
      };
      environmentFiles = [
        config.sops.templates."invoiceninja-db-env".path
      ];
      extraOptions = [ "--network=invoiceninja-net" ];
      autoStart = true;
    };

    # --- Redis Cache ---
    virtualisation.oci-containers.containers.invoiceninja-redis = {
      image = "redis:alpine";
      volumes = [
        "${stateDir}/redis:/data"
      ];
      extraOptions = [ "--network=invoiceninja-net" ];
      autoStart = true;
    };

    # --- Invoice Ninja App (PHP-FPM) ---
    virtualisation.oci-containers.containers.invoiceninja = {
      image = "invoiceninja/invoiceninja-debian:latest";
      volumes = [
        "${stateDir}/public:/var/www/html/public"
        "${stateDir}/storage:/var/www/html/storage"
      ];
      environment = {
        APP_URL = "https://invoice.${domain}";
        APP_ENV = "production";
        APP_DEBUG = "false";
        REQUIRE_HTTPS = "false";
        TRUSTED_PROXIES = "*";
        IS_DOCKER = "true";
        PDF_GENERATOR = "snappdf";
        FILESYSTEM_DISK = "debian_docker";
        SCOUT_DRIVER = "null";

        # Database
        DB_HOST = "invoiceninja-db";
        DB_PORT = "3306";
        DB_DATABASE = "ninja";
        DB_USERNAME = "ninja";
        DB_CONNECTION = "mysql";

        # Redis
        CACHE_DRIVER = "redis";
        QUEUE_CONNECTION = "redis";
        SESSION_DRIVER = "redis";
        REDIS_HOST = "invoiceninja-redis";
        REDIS_PASSWORD = "null";
        REDIS_PORT = "6379";

        # Mail (log to file by default, configure later)
        MAIL_MAILER = "log";

        TZ = "Europe/Prague";
      };
      environmentFiles = [
        config.sops.templates."invoiceninja-env".path
      ];
      dependsOn = [
        "invoiceninja-db"
        "invoiceninja-redis"
      ];
      extraOptions = [ "--network=invoiceninja-net" ];
      autoStart = true;
    };

    # --- Nginx Sidecar ---
    virtualisation.oci-containers.containers.invoiceninja-nginx = {
      image = "nginx:alpine";
      ports = [ "8380:80" ];
      volumes = [
        "${stateDir}/nginx:/etc/nginx/conf.d:ro"
        "${stateDir}/public:/var/www/html/public:ro"
        "${stateDir}/storage:/var/www/html/storage:ro"
      ];
      dependsOn = [ "invoiceninja" ];
      extraOptions = [ "--network=invoiceninja-net" ];
      autoStart = true;
    };
  };
}
