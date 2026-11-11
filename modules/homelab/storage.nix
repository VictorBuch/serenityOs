{
  flake.modules.nixos.homelab =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      smartTopic = "http://localhost:${toString config.homelab.records.ntfy.port}/mal-smart";
    in
    {
      # Install required packages
      environment.systemPackages = with pkgs; [
        mergerfs
        snapraid
        mergerfs-tools # Useful utilities for pool management
        smartmontools # Provides smartctl, used by `snapraid smart`
      ];

      # Mount individual data drives with labels for stability
      fileSystems."/mnt/disk1" = {
        device = "/dev/disk/by-label/data01";
        fsType = "ext4";
        options = [
          "defaults"
          "noatime"
        ]; # noatime reduces write overhead
      };

      fileSystems."/mnt/disk2" = {
        device = "/dev/disk/by-label/data02";
        fsType = "ext4";
        options = [
          "defaults"
          "noatime"
        ];
      };

      # Parity disk 1
      fileSystems."/mnt/parity1" = {
        device = "/dev/disk/by-label/parity01";
        fsType = "ext4";
        options = [
          "defaults"
          "noatime"
        ];
      };

      # Cold pool - HDDs only, uses path-preserving policy
      fileSystems."/mnt/cold" = {
        depends = [
          "/mnt/disk1"
          "/mnt/disk2"
        ];
        device = "/mnt/disk*";
        fsType = "mergerfs";
        options = [
          "defaults"
          "allow_other"
          "use_ino"
          "cache.files=partial"
          "dropcacheonclose=true"
          "category.create=epmfs" # Keep related files together
          "minfreespace=50G"
          "fsname=mergerfs-cold"
        ];
      };

      # Cache pool - SSD cache first, then cold pool
      fileSystems."/mnt/pool" = {
        depends = [ "/mnt/cold" ];
        device = "/cache:/mnt/cold";
        fsType = "mergerfs";
        options = [
          "defaults"
          "allow_other"
          "use_ino"
          "category.create=ff" # First found = cache gets new files
          "minfreespace=100G" # Reserve 100GB on SSD for OS
          "moveonenospc=true" # Safety net for full cache
          "cache.files=partial"
          "dropcacheonclose=true"
          "fsname=mergerfs-pool"
        ];
      };

      # Shared user-files root. copyparty serves it over http and Syncthing keeps
      # it two-way synced with the desktops; both write as members of `files`, and
      # the setgid bit makes new files inherit that group so neither service ends
      # up with files the other cannot touch.
      users.groups.files = { };

      # Create /cache directory on boot
      systemd.tmpfiles.rules = [
        "d /cache 0755 root root -"
        "d ${config.homelab.filesDir} 2770 root files -"
      ];

      # Short self-test daily 03:00, long on the 1st at 04:00; sleeping disks are skipped.
      services.smartd = {
        enable = true;
        notifications.wall.enable = false;
        defaults.autodetected = "-a -o on -S on -n standby,q -s (S/../.././03|L/../01/./04) -W 4,45,55 -m <nomailer> -M exec ${pkgs.writeShellScript "smartd-ntfy" ''
          ${pkgs.curl}/bin/curl -fsS -o /dev/null -H "Title: SMART alert: $SMARTD_DEVICE" \
            -H "Priority: urgent" -H "Tags: rotating_light" -d "$SMARTD_MESSAGE" ${smartTopic}
        ''}";
      };

      systemd.services.smart-summary = {
        description = "Send a SMART summary of every disk to ntfy";
        path = with pkgs; [
          smartmontools
          jq
          curl
        ];
        environment.NTFY_URL = smartTopic;
        script = builtins.readFile ./smart-ntfy.sh;
        serviceConfig.Type = "oneshot";
      };

      systemd.timers.smart-summary = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "Mon 09:00";
          Persistent = true;
        };
      };

      # Systemd service for cache mover
      systemd.services.mergerfs-cache-mover = {
        description = "Move old files from SSD cache to backing storage";
        path = with pkgs; [
          bash
          coreutils
          rsync
          findutils
          gawk
        ];
        script = ''
          #!/usr/bin/env bash
          set -euo pipefail

          CACHE="/cache"
          BACKING="/mnt/cold"
          AGE_DAYS=2

          # SnapRAID only covers the HDDs, so anything on the SSD is unprotected.
          # Move by age, not by fullness: every file untouched for AGE_DAYS goes
          # to the cold pool, and the 13:00 sync picks it up the same day.
          usage_pct() { df --output=pcent "''${CACHE}" | tail -1 | tr -dc '0-9'; }

          WORK=$(mktemp -d)
          trap 'rm -rf "''${WORK}"' EXIT

          # mtime, not atime: a file that keeps being watched must still get
          # parity. mtime lives on the inode, so every hardlink of a file (a
          # torrent in downloads/ and its Sonarr import in tv/) is selected
          # together -- and rsync only keeps hardlinks between files inside a
          # *single* transfer, so they all go in the one invocation below.
          # Anything still being written has a fresh mtime and stays put.
          find "''${CACHE}" -type f -mmin +$(( AGE_DAYS * 1440 )) -printf '%P\0' \
            > "''${WORK}/files-from"

          COUNT=$(tr -cd '\0' < "''${WORK}/files-from" | wc -c)
          if [ "''${COUNT}" -eq 0 ]; then
            echo "Nothing older than ''${AGE_DAYS} days on cache ($(usage_pct)% used)."
            exit 0
          fi
          echo "Moving ''${COUNT} paths older than ''${AGE_DAYS} days ($(usage_pct)% used)"

          # Exit 24 = a file vanished mid-transfer (deleted by an app); harmless,
          # whatever was left behind moves on the next run.
          rc=0
          rsync -aH --remove-source-files --from0 --files-from="''${WORK}/files-from" \
            "''${CACHE}/" "''${BACKING}/" || rc=$?
          if [ "''${rc}" -ne 0 ] && [ "''${rc}" -ne 24 ]; then
            echo "rsync failed with exit ''${rc}"
            exit "''${rc}"
          fi

          # Clean up empty directories, keeping the top-level share dirs.
          find "''${CACHE}" -mindepth 2 -type d -empty -delete 2>/dev/null || true

          echo "Cache cleanup complete. Usage now: $(usage_pct)%"
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };

      # Run cache mover daily before SnapRAID sync
      systemd.timers.mergerfs-cache-mover = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "12:00"; # Noon, before SnapRAID sync at 1 PM
          Persistent = true;
        };
      };

      # SnapRAID configuration
      services.snapraid = {
        enable = true;

        # Parity file on dedicated disk
        parityFiles = [
          "/mnt/parity1/snapraid.parity"
        ];

        # Content files - MUST have multiple copies on different physical disks
        contentFiles = [
          "/var/snapraid.content" # Boot drive (4TB SSD)
          "/mnt/parity1/.snapraid.content" # Parity disk 1
          "/mnt/disk1/.snapraid.content" # Data disk 1
          "/mnt/disk2/.snapraid.content" # Data disk 2
        ];

        # Data disks - order matters for parity calculation
        dataDisks = {
          d1 = "/mnt/disk1/";
          d2 = "/mnt/disk2/";
        };

        # Daily sync at 1 PM (after cache mover at noon)
        sync.interval = "13:00";

        # Weekly scrub checks 12% of array
        scrub = {
          interval = "weekly";
          plan = 12; # Higher percentage for better protection
          olderThan = 10; # Days before re-scrubbing same data
        };

        # Exclude patterns for files that shouldn't be in parity
        exclude = [
          "*.unrecoverable"
          "*.!sync"
          "/tmp/"
          "/lost+found/"
          ".DS_Store"
          ".Thumbs.db"
          "/downloads/incomplete/" # Exclude incomplete downloads
          "/.cache/"
        ];

        # Touch files before sync to update timestamps
        touchBeforeSync = true;

        # Additional configuration
        extraConfig = ''
          nohidden
          autosave 500
        '';
      };

      # Ensure SnapRAID sync runs AFTER cache mover
      systemd.services.snapraid-sync = {
        after = [ "mergerfs-cache-mover.service" ];
      };

      # Watchdog service to detect and recover from stale mergerfs mounts
      # mergerfs v2.41.1 has a known crash bug (CREATE_UPDATE_LAMBDA assertion)
      # that leaves /mnt/pool as a stale FUSE mount ("Transport endpoint is not connected")
      systemd.services.mergerfs-pool-watchdog = {
        description = "Monitor mergerfs pool health and recover from stale mounts";
        path = with pkgs; [
          bash
          coreutils
          util-linux
          systemd
        ];
        script = ''
          #!/usr/bin/env bash
          set -euo pipefail

          check_mount() {
            local mount_point="$1"
            # Try to stat the mount point - this will fail with ENOTCONN if stale
            if stat "$mount_point" >/dev/null 2>&1; then
              return 0
            else
              return 1
            fi
          }

          if check_mount /mnt/pool; then
            echo "mergerfs pool at /mnt/pool is healthy"
            exit 0
          fi

          echo "ERROR: /mnt/pool is stale (Transport endpoint is not connected)"
          echo "Attempting recovery..."

          # Lazy unmount the stale FUSE mount
          umount -l /mnt/pool 2>/dev/null || true
          sleep 1

          # Also check /mnt/cold since /mnt/pool depends on it
          if ! check_mount /mnt/cold; then
            echo "ERROR: /mnt/cold is also stale, recovering..."
            umount -l /mnt/cold 2>/dev/null || true
            sleep 1
            # Remount cold pool first
            systemctl restart mnt-cold.mount
            sleep 2
          fi

          # Remount the pool
          systemctl restart mnt-pool.mount
          sleep 2

          # Verify recovery
          if check_mount /mnt/pool; then
            echo "Recovery successful! /mnt/pool is accessible again"

            # Restart dependent services that may have failed
            echo "Restarting dependent services..."
            systemctl try-restart paperless-directories.service 2>/dev/null || true
            systemctl try-restart paperless-scheduler.service 2>/dev/null || true
          else
            echo "CRITICAL: Recovery failed! /mnt/pool is still inaccessible"
            exit 1
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };

      # Run the watchdog every 5 minutes
      systemd.timers.mergerfs-pool-watchdog = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = "5min";
          RandomizedDelaySec = "30s";
        };
      };
    };
}
