{
  config,
  pkgs,
  lib,
  options,
  ...
}:

let
  domain = config.homelab.domain;
  user = config.user;
  nextcloudDir = config.homelab.nextcloudDir;
  uid = toString config.user.uid;
in

{
  options = {
    nextcloud.enable = lib.mkEnableOption "Enables NextCloud with MySQL and Redis";
  };

  config = lib.mkIf config.nextcloud.enable {

    services.nginx.enable = false;

    networking.firewall.allowedTCPPorts = [ 5672 ];

    # MySQL service for NextCloud
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      ensureDatabases = [ "nextcloud" ];
      ensureUsers = [
        {
          name = "nextcloud";
          ensurePermissions = {
            "nextcloud.*" = "ALL PRIVILEGES";
          };
        }
      ];

      # Configure MySQL for proper UTF8MB4 support
      settings = {
        mysqld = {
          character-set-server = "utf8mb4";
          collation-server = "utf8mb4_general_ci";
          innodb_file_format = "barracuda";
          innodb_file_per_table = "1";
          innodb_large_prefix = "1";
          port = 3306;
          bind = "127.0.0.1";
        };
      };
    };

    # Redis service for NextCloud (separate from Immich container)
    services.redis.servers.nextcloud = {
      enable = true;
      port = 6380;
      bind = lib.mkForce "127.0.0.1";
      settings.dir = "/var/lib/redis-nextcloud";
    };

    # Set redis package (serenity uses unstable nixpkgs by default)
    services.redis.package = lib.mkDefault pkgs.redis;

    users = {
      groups.nextcloud = {
        name = "nextcloud";
        members = [ "${user.userName}" ];
        gid = 912;
      };
      users.nextcloud = {
        isSystemUser = true;
        uid = 912;
        group = "nextcloud";
        home = nextcloudDir;
      };
      users."${user.userName}".extraGroups = [ "nextcloud" ];
    };

    # Ensure all Nextcloud services wait for mergerFS pool mount and database services
    systemd.services.nextcloud-setup = {
      after = [ "mnt-pool.mount" "mysql.service" "redis-nextcloud.service" ];
      requires = [ "mnt-pool.mount" "mysql.service" "redis-nextcloud.service" ];
    };
    systemd.services.nextcloud-update-db = {
      after = [ "mnt-pool.mount" "mysql.service" "redis-nextcloud.service" ];
      requires = [ "mnt-pool.mount" "mysql.service" "redis-nextcloud.service" ];
    };
    systemd.services.phpfpm-nextcloud = {
      after = [ "mnt-pool.mount" "mysql.service" "redis-nextcloud.service" ];
      requires = [ "mnt-pool.mount" "mysql.service" "redis-nextcloud.service" ];
    };

    # Create nextcloud directories and set proper ownership
    systemd.services.nextcloud-directories = {
      description = "Create Nextcloud directories and set ownership";
      before = [
        "nextcloud-setup.service"
        "phpfpm-nextcloud.service"
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

          # Check ownership (owner should be nextcloud:nextcloud)
          local owner=$(stat -c "%U:%G" "$dir" 2>/dev/null)
          if [ "$owner" != "nextcloud:nextcloud" ]; then
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
            chown nextcloud:nextcloud "$dir"
            chmod "$perm" "$dir"
          else
            echo "Directory OK: $dir"
          fi
        }

        # Check and fix directories only if needed
        fix_dir "${nextcloudDir}" "770"
        fix_dir "${nextcloudDir}/config" "770"
        fix_dir "${nextcloudDir}/data" "770"
        fix_dir "${nextcloudDir}/store-apps" "770"
        fix_dir "${nextcloudDir}/apps" "770"

        # Only run recursive chown if we detect ownership issues in subdirectories
        if [ -d "${nextcloudDir}" ]; then
          # Check if any files/subdirs have wrong ownership (but don't fix yet)
          wrong_files=$(find "${nextcloudDir}" ! -user nextcloud -o ! -group nextcloud 2>/dev/null | wc -l)
          if [ "''${wrong_files}" -gt 0 ]; then
            echo "Found ''${wrong_files} files with wrong ownership, fixing recursively..."
            chown -R nextcloud:nextcloud "${nextcloudDir}"
          else
            echo "All files have correct ownership, skipping recursive chown"
          fi
        fi
      '';
    };

    # NextCloud service configuration
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud32;
      hostName = "nextcloud.${domain}";
      https = true;
      maxUploadSize = "16G";
      home = nextcloudDir;
      appstoreEnable = false;

      # Configure PHP-FPM for NextCloud
      poolSettings = {
        "pm" = "dynamic";
        "pm.max_children" = 32;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 2;
        "pm.max_spare_servers" = 4;
        "pm.max_requests" = 500;
      };

      # Database configuration - force MySQL over web installation
      config = {
        dbtype = "mysql";
        dbname = "nextcloud";
        dbhost = "localhost";
        dbuser = "nextcloud";
        dbpassFile = config.sops.secrets."nextcloud/db_password".path;
        adminuser = "admin";
        adminpassFile = config.sops.secrets."nextcloud/admin_password".path;
      };

      # Redis caching configuration
      caching = {
        redis = true;
        memcached = false;
      };

      settings = {
        # Force MySQL database configuration over web installation
        dbtype = "mysql";
        dbname = "nextcloud";
        dbhost = "localhost";
        dbuser = "nextcloud";

        # Fix MySQL UTF8MB4 collation issues
        "mysql.utf8mb4" = true;
        "mysql.collation" = "utf8mb4_general_ci";

        # Redis configuration
        redis = {
          host = lib.mkForce config.services.redis.servers.nextcloud.bind;
          port = lib.mkForce config.services.redis.servers.nextcloud.port;
          dbindex = 0;
          timeout = 1.5;
        };
        maintenance_window_start = 2;
        default_phone_region = "DK";
        filelocking.enabled = true;
        overwriteProtocol = "https";

        # Trust Caddy as reverse proxy
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };

      # Basic apps
      extraApps = with config.services.nextcloud.package.packages.apps; {
        inherit
          calendar
          contacts
          ;
      };

    };

    # Configure PHP-FPM to work with Caddy
    # Note: Nextcloud module enables nginx by default, but we use Caddy instead
    services.phpfpm.pools.nextcloud = {
      settings = {
        "listen.owner" = config.services.caddy.user;
        "listen.group" = config.services.caddy.group;
      };
    };

    # Add Caddy user to nextcloud group for file access
    users.users.${config.services.caddy.user}.extraGroups = [ "nextcloud" ];

  };
}
