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

  # Systemd service for cache mover
  systemd.services.mergerfs-cache-mover = {
    description = "Move old files from SSD cache to backing storage";
    path = with pkgs; [bash coreutils rsync findutils gawk];  # Added gawk for awk command
    script = ''
      #!/usr/bin/env bash
      set -euo pipefail

      CACHE="/cache"
      BACKING="/mnt/cold"
      THRESHOLD=80  # Percentage
      TARGET=60     # Target after cleanup
      AGE_DAYS=7

      usage_pct() { df --output=pcent "''${CACHE}" | tail -1 | tr -dc '0-9'; }

      USAGE=$(usage_pct)
      if [ "''${USAGE}" -le "''${THRESHOLD}" ]; then
        echo "Cache at ''${USAGE}%, no cleanup needed."
        exit 0
      fi

      SIZE=$(df --output=size -B1 "''${CACHE}" | tail -1 | tr -dc '0-9')
      USED=$(df --output=used -B1 "''${CACHE}" | tail -1 | tr -dc '0-9')
      NEED=$(( USED - SIZE * TARGET / 100 ))
      echo "Cache at ''${USAGE}%, need to free $(numfmt --to=iec "''${NEED}")"

      WORK=$(mktemp -d)
      trap 'rm -rf "''${WORK}"' EXIT

      # inode <TAB> atime <TAB> size <TAB> path-relative-to-CACHE
      find "''${CACHE}" -type f -printf '%i\t%A@\t%s\t%P\n' > "''${WORK}/all"

      # The unit of movement is the inode, not the path. rsync only preserves
      # hardlinks between files inside a *single* transfer, so a Sonarr import
      # (torrent in downloads/ hardlinked to the file in tv/) has to move as
      # one batch. Moving paths one at a time -- as this did before -- silently
      # forks every seeded file into two independent copies on the cold pool.
      # An inode is eligible only when its most recently read link is cold, so
      # something still being watched keeps all of its links on the SSD.
      awk -F'\t' -v cutoff="$(date -d "''${AGE_DAYS} days ago" +%s)" '
        { if (!($1 in newest) || $2 > newest[$1]) newest[$1] = $2; size[$1] = $3 }
        END { for (i in newest) if (newest[i] < cutoff)
                printf "%d\t%d\t%d\n", newest[i], i, size[i] }
      ' "''${WORK}/all" | sort -n > "''${WORK}/groups"

      # Coldest inodes first, until the batch covers what we need to free.
      awk -F'\t' -v need="''${NEED}" \
        '{ total += $3; print $2; if (total >= need) exit }' \
        "''${WORK}/groups" > "''${WORK}/inodes"

      if [ ! -s "''${WORK}/inodes" ]; then
        echo "Nothing older than ''${AGE_DAYS} days to move; cache still at ''${USAGE}%."
        exit 0
      fi

      # Expand the chosen inodes back out to every path that links to them.
      awk -F'\t' 'NR==FNR { want[$1] = 1; next } ($1 in want) { print $4 }' \
        "''${WORK}/inodes" "''${WORK}/all" > "''${WORK}/files-from"

      echo "Moving $(wc -l < "''${WORK}/files-from") paths ($(wc -l < "''${WORK}/inodes") inodes)"

      # -H is the whole point: one invocation, hardlinks intact on arrival.
      rsync -aH --remove-source-files --files-from="''${WORK}/files-from" \
        "''${CACHE}/" "''${BACKING}/"

      # Clean up empty directories
      find "''${CACHE}" -type d -empty -delete 2>/dev/null || true

      echo "Cache cleanup complete. Usage now: $(usage_pct)%"
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
