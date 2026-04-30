{ config, lib, pkgs, ... }:
{
  # Install required packages
  environment.systemPackages = with pkgs; [
    mergerfs
    snapraid
    mergerfs-tools  # Useful utilities for pool management
    smartmontools   # Provides smartctl, used by `snapraid smart`
  ];

  # Mount individual data drives with labels for stability
  fileSystems."/mnt/disk1" = {
    device = "/dev/disk/by-label/data01";
    fsType = "ext4";
    options = ["defaults" "noatime"];  # noatime reduces write overhead
  };

  fileSystems."/mnt/disk2" = {
    device = "/dev/disk/by-label/data02";
    fsType = "ext4";
    options = ["defaults" "noatime"];
  };

  # Parity disk 1
  fileSystems."/mnt/parity1" = {
    device = "/dev/disk/by-label/parity01";
    fsType = "ext4";
    options = ["defaults" "noatime"];
  };

  # Cold pool - HDDs only, uses path-preserving policy
  fileSystems."/mnt/cold" = {
    depends = ["/mnt/disk1" "/mnt/disk2"];
    device = "/mnt/disk*";
    fsType = "mergerfs";
    options = [
      "defaults"
      "allow_other"
      "use_ino"
      "cache.files=partial"
      "dropcacheonclose=true"
      "category.create=epmfs"  # Keep related files together
      "minfreespace=50G"
      "fsname=mergerfs-cold"
    ];
  };

  # Cache pool - SSD cache first, then cold pool
  fileSystems."/mnt/pool" = {
    depends = ["/mnt/cold"];
    device = "/cache:/mnt/cold";
    fsType = "mergerfs";
    options = [
      "defaults"
      "allow_other"
      "use_ino"
      "category.create=ff"      # First found = cache gets new files
      "minfreespace=100G"       # Reserve 100GB on SSD for OS
      "moveonenospc=true"       # Safety net for full cache
      "cache.files=partial"
      "dropcacheonclose=true"
      "fsname=mergerfs-pool"
    ];
  };

  # Create /cache directory on boot
  systemd.tmpfiles.rules = [
    "d /cache 0755 root root -"
  ];

  # Systemd service for cache mover
  systemd.services.mergerfs-cache-mover = {
    description = "Move old files from SSD cache to backing storage";
    path = with pkgs; [bash coreutils rsync findutils gawk];  # Added gawk for awk command
    script = ''
      #!/usr/bin/env bash

      CACHE="/cache"
      BACKING="/mnt/cold"
      THRESHOLD=80  # Percentage
      TARGET=60     # Target after cleanup

      # Get cache usage percentage
      USAGE=$(df "''${CACHE}" | awk 'NR==2 {print int($5)}')

      if [ "''${USAGE}" -gt "''${THRESHOLD}" ]; then
        echo "Cache at ''${USAGE}%, moving files to backing storage..."

        # Find files older than 7 days, move oldest first
        find "''${CACHE}" -type f -atime +7 -printf '%A@ %p\0' 2>/dev/null | \
          sort -z -n | \
          while IFS= read -r -d "" line; do
            FILE=$(echo "''${line}" | cut -d' ' -f2-)
            RELPATH="''${FILE#''${CACHE}/}"

            # Create directory structure in backing storage
            mkdir -p "''${BACKING}/$(dirname "''${RELPATH}")"

            # Move file
            rsync -a --remove-source-files "''${FILE}" "''${BACKING}/''${RELPATH}"

            # Check if we've reached target usage
            CURRENT=$(df "''${CACHE}" | awk 'NR==2 {print int($5)}')
            [ "''${CURRENT}" -le "''${TARGET}" ] && break
          done

        # Clean up empty directories
        find "''${CACHE}" -type d -empty -delete 2>/dev/null || true

        echo "Cache cleanup complete. Usage now: $(df "''${CACHE}" | awk 'NR==2 {print $5}')"
      else
        echo "Cache at ''${USAGE}%, no cleanup needed."
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  # Run cache mover daily before SnapRAID sync
  systemd.timers.mergerfs-cache-mover = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "12:00";  # Noon, before SnapRAID sync at 1 PM
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
      "/var/snapraid.content"              # Boot drive (4TB SSD)
      "/mnt/parity1/.snapraid.content"     # Parity disk 1
      "/mnt/disk1/.snapraid.content"       # Data disk 1
      "/mnt/disk2/.snapraid.content"       # Data disk 2
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
      plan = 12;        # Higher percentage for better protection
      olderThan = 10;   # Days before re-scrubbing same data
    };

    # Exclude patterns for files that shouldn't be in parity
    exclude = [
      "*.unrecoverable"
      "*.!sync"
      "/tmp/"
      "/lost+found/"
      ".DS_Store"
      ".Thumbs.db"
      "/downloads/incomplete/"  # Exclude incomplete downloads
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
    after = ["mergerfs-cache-mover.service"];
  };

  # Watchdog service to detect and recover from stale mergerfs mounts
  # mergerfs v2.41.1 has a known crash bug (CREATE_UPDATE_LAMBDA assertion)
  # that leaves /mnt/pool as a stale FUSE mount ("Transport endpoint is not connected")
  systemd.services.mergerfs-pool-watchdog = {
    description = "Monitor mergerfs pool health and recover from stale mounts";
    path = with pkgs; [bash coreutils util-linux systemd];
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
        systemctl try-restart nextcloud-directories.service 2>/dev/null || true
        systemctl try-restart nextcloud-setup.service 2>/dev/null || true
        systemctl try-restart phpfpm-nextcloud.service 2>/dev/null || true
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
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
      RandomizedDelaySec = "30s";
    };
  };
}
