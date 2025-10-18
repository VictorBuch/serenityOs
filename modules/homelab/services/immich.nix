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
  uid = toString config.user.uid; # ghost user UID
  gid = "immich"; # immich group
in
{
  options.immich.enable = lib.mkEnableOption "Enables Immich photo backup service";

  config = lib.mkIf config.immich.enable {

    # Create dedicated immich group
    users.groups.immich = {
      name = "immich";
      gid = 980; # Match your existing TrueNAS setup
    };

    # Create immich system user
    users.users.immich = {
      isSystemUser = true;
      uid = 980; # Match your existing TrueNAS setup
      group = "immich";
      extraGroups = [ "users" ];
      home = immichDir;
      shell = pkgs.bash;
    };

    # Add ghost user to immich group for management access
    users.users.${user.userName}.extraGroups = [ "immich" ];

    boot.kernel.sysctl = {
      "vm.overcommit_memory" = lib.mkForce 1;
    };

    # Ensure all Immich services wait for NFS mounts
    systemd.services.immich-server = {
      after = [ "nfs-mounts-ready.target" ];
      requires = [ "nfs-mounts-ready.target" ];
    };
    systemd.services.immich-machine-learning = {
      after = [ "nfs-mounts-ready.target" ];
      requires = [ "nfs-mounts-ready.target" ];
    };
    systemd.services.redis-immich = {
      after = [ "nfs-mounts-ready.target" ];
      requires = [ "nfs-mounts-ready.target" ];
    };

    # Create immich directories and set proper ownership for NFSv4
    systemd.services.immich-directories = {
      description = "Create Immich directories and set ownership";
      before = [
        "immich-server.service"
        "immich-machine-learning.service"
      ];
      after = [ "nfs-mounts-ready.target" ];
      requires = [ "nfs-mounts-ready.target" ];
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

    services.immich = {
      enable = true;
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

      database.createDB = true;

      redis = {
        enable = true;
        port = 6381;
        host = "127.0.0.1";
      };
    };
  };
}
