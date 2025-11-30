{
  pkgs,
  lib,
  options,
  config,
  ...
}:
let
  paperlessDir = config.homelab.paperlessDir;
  domain = config.homelab.domain;
  user = config.user;
in
{
  options.paperless.enable = lib.mkEnableOption "Enables Paperless-ngx document management service";

  config = lib.mkIf config.paperless.enable {
    
    users.users.${user.userName}.extraGroups = [ "paperless" ];

    services.redis.servers.paperless = {
      enable = true;
      port = 6382;
      bind = "127.0.0.1";
      settings = {
        dir = "/var/lib/redis-paperless";
        maxmemory = "256mb";
        maxmemory-policy = "allkeys-lru";
      };
    };

    systemd.services.redis-paperless = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
    };

    systemd.services.paperless-scheduler = {
      after = [ "mnt-pool.mount" "redis-paperless.service" ];
      requires = [ "mnt-pool.mount" "redis-paperless.service" ];
      serviceConfig.PrivateNetwork = lib.mkForce false;  # Allow Redis TCP connection on port 6382
    };

    systemd.services.paperless-consumer = {
      after = [ "mnt-pool.mount" "redis-paperless.service" ];
      requires = [ "mnt-pool.mount" "redis-paperless.service" ];
    };
    systemd.services.paperless-web = {
      after = [ "mnt-pool.mount" "redis-paperless.service" ];
      requires = [ "mnt-pool.mount" "redis-paperless.service" ];
    };
    systemd.services.paperless-task-queue = {
      after = [ "mnt-pool.mount" "redis-paperless.service" ];
      requires = [ "mnt-pool.mount" "redis-paperless.service" ];
    };

    networking.firewall.allowedTCPPorts = [ 28981 ];

    # SOPS secrets for paperless
    sops.templates."paperless-env" = {
      content = ''
        PAPERLESS_DBPASS=${config.sops.placeholder."paperless/db_password"}
        PAPERLESS_ADMIN_PASSWORD=${config.sops.placeholder."paperless/admin_password"}
        PAPERLESS_SECRET_KEY=${config.sops.placeholder."paperless/secret_key"}
      '';
      mode = "0600";
    };

    services.paperless = {
      enable = true;
      port = 28981;
      address = "0.0.0.0";
      
      # Override package to disable pytests
      package = pkgs.paperless-ngx.overrideAttrs (oldAttrs: {
        doCheck = false;
        checkPhase = "true";  # Skip all tests
      });

      dataDir = "${paperlessDir}/data";
      mediaDir = "${paperlessDir}/media";
      consumptionDir = "${paperlessDir}/consumption";
      consumptionDirIsPublic = true;

      passwordFile = config.sops.templates."paperless-env".path;

      settings = {
        # Database settings - PostgreSQL
        PAPERLESS_DBHOST = "/run/postgresql";
        PAPERLESS_DBNAME = "paperless";
        PAPERLESS_DBUSER = "paperless";

        # Redis settings
        PAPERLESS_REDIS = "redis://127.0.0.1:6382";

        # OCR settings
        PAPERLESS_OCR_LANGUAGE = "eng+dan+ces";  # English, Danish, Czech
        PAPERLESS_OCR_SKIP_ARCHIVE_FILE = "with_text";  # Skip OCR for files that already have text

        # URL settings
        PAPERLESS_URL = "https://paperless.${domain}";
        PAPERLESS_ALLOWED_HOSTS = "paperless.${domain},${config.homelab.nixosIp}";
        PAPERLESS_CORS_ALLOWED_HOSTS = "https://paperless.${domain}";

        # Features
        PAPERLESS_TIME_ZONE = config.time.timeZone;
        PAPERLESS_DATE_ORDER = "DMY";
        PAPERLESS_CONSUMER_RECURSIVE = true;
        PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true;

        # Performance
        PAPERLESS_TASK_WORKERS = 2;
        PAPERLESS_THREADS_PER_WORKER = 2;

        # Security
        PAPERLESS_AUTO_LOGIN_USERNAME = "";  # Disable auto-login
        PAPERLESS_DISABLE_REGULAR_LOGIN = false;

        # Admin user
        PAPERLESS_ADMIN_USER = "admin";
        PAPERLESS_ADMIN_MAIL = "admin@${domain}";
      };

      # Create database locally
      database = {
        createLocally = true;
      };
    };
  };
}
