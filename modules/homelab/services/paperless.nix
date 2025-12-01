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

    # Set redis package (serenity uses unstable nixpkgs by default)
    services.redis.package = lib.mkDefault pkgs.redis;

    systemd.services.redis-paperless = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
    };

    # Create paperless directories and set proper ownership
    systemd.services.paperless-directories = {
      description = "Create Paperless directories and set ownership";
      before = [
        "paperless-scheduler.service"
        "paperless-consumer.service"
        "paperless-web.service"
        "paperless-task-queue.service"
      ];
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Function to check if directory has correct ownership and permissions
        check_dir() {
          local dir="$1"
          local expected_perm="$2"

          # Check if directory exists
          if [ ! -d "$dir" ]; then
            return 1  # Needs creation
          fi

          # Check ownership (owner should be paperless:paperless)
          local owner=$(stat -c "%U:%G" "$dir" 2>/dev/null)
          if [ "$owner" != "paperless:paperless" ]; then
            return 1  # Wrong ownership
          fi

          # Check permissions
          local perms=$(stat -c "%a" "$dir" 2>/dev/null)
          if [ "$perms" != "$expected_perm" ]; then
            return 1  # Wrong permissions
          fi

          return 0  # All good
        }

        # Function to fix directory if needed
        fix_dir() {
          local dir="$1"
          local perm="$2"

          if ! check_dir "$dir" "$perm"; then
            echo "Fixing directory: $dir"
            mkdir -p "$dir"
            chown paperless:paperless "$dir"
            chmod "$perm" "$dir"
          else
            echo "Directory OK: $dir"
          fi
        }

        # Check and fix directories only if needed
        fix_dir "${paperlessDir}" "770"
        fix_dir "${paperlessDir}/data" "770"
        fix_dir "${paperlessDir}/media" "770"
        fix_dir "${paperlessDir}/consumption" "770"

        # Create redis data directory
        if [ ! -d "/var/lib/redis-paperless" ]; then
          echo "Creating redis-paperless directory"
          mkdir -p /var/lib/redis-paperless
          chown redis-paperless:redis-paperless /var/lib/redis-paperless
          chmod 750 /var/lib/redis-paperless
        fi
      '';
    };

    systemd.services.paperless-scheduler = {
      after = [
        "mnt-pool.mount"
        "redis-paperless.service"
      ];
      requires = [
        "mnt-pool.mount"
        "redis-paperless.service"
      ];
      serviceConfig.PrivateNetwork = lib.mkForce false; # Allow Redis TCP connection on port 6382
    };

    # These services must wait for scheduler to complete migrations first
    systemd.services.paperless-consumer = {
      after = [
        "mnt-pool.mount"
        "redis-paperless.service"
        "paperless-scheduler.service"
      ];
      requires = [
        "mnt-pool.mount"
        "redis-paperless.service"
      ];
      wants = [ "paperless-scheduler.service" ];
    };
    systemd.services.paperless-web = {
      after = [
        "mnt-pool.mount"
        "redis-paperless.service"
        "paperless-scheduler.service"
      ];
      requires = [
        "mnt-pool.mount"
        "redis-paperless.service"
      ];
      wants = [ "paperless-scheduler.service" ];
    };
    systemd.services.paperless-task-queue = {
      after = [
        "mnt-pool.mount"
        "redis-paperless.service"
        "paperless-scheduler.service"
      ];
      requires = [
        "mnt-pool.mount"
        "redis-paperless.service"
      ];
      wants = [ "paperless-scheduler.service" ];
    };

    networking.firewall.allowedTCPPorts = [ 28981 ];

    # SOPS secrets for paperless
    sops.templates."paperless-env" = {
      content = ''
        PAPERLESS_DBPASS=${config.sops.placeholder."paperless/db_password"}
        PAPERLESS_SECRET_KEY=${config.sops.placeholder."paperless/secret_key"}
      '';
      mode = "0600";
    };

    # Separate file for admin password (passwordFile expects only the password)
    sops.templates."paperless-admin-password" = {
      content = config.sops.placeholder."paperless/admin_password";
      mode = "0600";
    };

    services.paperless = {
      enable = true;
      port = 28981;
      address = "0.0.0.0";

      # Override package to disable all test phases
      package = pkgs.paperless-ngx.overrideAttrs (oldAttrs: {
        doCheck = false;
        doInstallCheck = false;
        checkPhase = "";
        installCheckPhase = "";
        pytestCheckPhase = "";
      });

      dataDir = "${paperlessDir}/data";
      mediaDir = "${paperlessDir}/media";
      consumptionDir = "${paperlessDir}/consumption";
      consumptionDirIsPublic = true;

      passwordFile = config.sops.templates."paperless-admin-password".path;

      settings = {
        # Database settings - PostgreSQL
        PAPERLESS_DBHOST = "/run/postgresql";
        PAPERLESS_DBNAME = "paperless";
        PAPERLESS_DBUSER = "paperless";

        # Redis settings
        PAPERLESS_REDIS = "redis://127.0.0.1:6382";

        # OCR settings
        PAPERLESS_OCR_LANGUAGE = "eng+dan+ces"; # English, Danish, Czech
        PAPERLESS_OCR_SKIP_ARCHIVE_FILE = "with_text"; # Skip OCR for files that already have text

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
        PAPERLESS_AUTO_LOGIN_USERNAME = ""; # Disable auto-login
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
