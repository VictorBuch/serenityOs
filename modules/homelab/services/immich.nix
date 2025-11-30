{
  pkgs,
  lib,
  options,
  config,
  ...
}:
let
  immichDir = config.homelab.immichDir;
  domain = config.homelab.domain;
  user = config.user;
  uid = toString config.user.uid; # serenity user UID
  gid = "immich"; # immich group
in
{
  options.immich.enable = lib.mkEnableOption "Enables Immich photo backup service";

  config = lib.mkIf config.immich.enable {
    users = {
      # Create dedicated immich group
      groups.immich = {
        name = "immich";
        gid = 980; # Match your existing TrueNAS setup
      };

      # Create immich system user
      users.immich = {
        isSystemUser = true;
        uid = 980; # Match your existing TrueNAS setup
        group = "immich";
        extraGroups = [ "users" ];
        home = immichDir;
        shell = pkgs.unstable.bash;
      };

      # Add serenity user to immich group for management access
      users.${user.userName}.extraGroups = [ "immich" ];
    };

    boot.kernel.sysctl = {
      "vm.overcommit_memory" = lib.mkForce 1;
    };

    systemd = {
      services = {
        # Ensure all Immich services wait for storage mounts
        immich-server = {
          after = [ "mnt-pool.mount" ];
          requires = [ "mnt-pool.mount" ];
        };
        immich-machine-learning = {
          after = [ "mnt-pool.mount" ];
          requires = [ "mnt-pool.mount" ];
        };
        redis-immich = {
          after = [ "mnt-pool.mount" ];
          requires = [ "mnt-pool.mount" ];
        };

        # Create immich directories and set proper ownership
        immich-directories = {
          description = "Create Immich directories and set ownership";
          before = [
            "immich-server.service"
            "immich-machine-learning.service"
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

              # Check ownership (owner should be immich:immich)
              local owner=$(stat -c "%U:%G" "$dir" 2>/dev/null)
              if [ "$owner" != "immich:immich" ]; then
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
                chown immich:immich "$dir"
                chmod "$perm" "$dir"
              else
                echo "Directory OK: $dir"
              fi
            }

            # Check and fix directories only if needed
            fix_dir "${immichDir}" "770"
            fix_dir "${immichDir}/photos" "770"
            fix_dir "${immichDir}/config" "770"
            fix_dir "${immichDir}/config/machine-learning" "770"

            # Only run recursive chown if we detect ownership issues in subdirectories
            if [ -d "${immichDir}" ]; then
              # Check if any files/subdirs have wrong ownership (but don't fix yet)
              wrong_files=$(find "${immichDir}" ! -user immich -o ! -group immich 2>/dev/null | wc -l)
              if [ "$wrong_files" -gt 0 ]; then
                echo "Found $wrong_files files with wrong ownership, fixing recursively..."
                chown -R immich:immich "${immichDir}"
              else
                echo "All files have correct ownership, skipping recursive chown"
              fi
            fi
          '';
        };
      };
    };

    services.immich = {
      enable = true;
      package = pkgs.unstable.immich;
      user = "immich";
      group = "immich";
      host = "0.0.0.0"; # Allow external access
      openFirewall = true;
      machine-learning.enable = true;

      mediaLocation = immichDir;

      settings = {
        server.externalDomain = "https://immich.${domain}"; # Domain for publicly shared links, including http(s)://
        newVersionCheck.enabled = true; # Check for new versions. This feature relies on periodic communication with github.com.
      };

      database = {
        createDB = true;
        # Disable pgvecto.rs to allow PostgreSQL 17+
        # Immich now uses pgvector which supports newer PostgreSQL versions
        enableVectors = false;
      };

      redis = {
        enable = true;
        port = 6381;
        host = "127.0.0.1";
      };
    };

    # Use unstable redis globally to avoid RDB format version mismatch
    services.redis.package = pkgs.unstable.redis;
  };
}
