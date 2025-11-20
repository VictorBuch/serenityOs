{ config, lib, pkgs, ... }:
{
  # Install required packages
  environment.systemPackages = with pkgs; [
    mergerfs
    snapraid
    mergerfs-tools  # Useful utilities for pool management
  ];

  # Mount individual data drives with labels for stability
  fileSystems."/mnt/disk1" = {
    device = "/dev/disk/by-label/data01";
    fsType = "xfs";
    options = ["defaults" "noatime"];  # noatime reduces write overhead
  };

  fileSystems."/mnt/disk2" = {
    device = "/dev/disk/by-label/data02";
    fsType = "xfs";
    options = ["defaults" "noatime"];
  };

  # Parity disk 1
  fileSystems."/mnt/parity1" = {
    device = "/dev/disk/by-label/parity01";
    fsType = "xfs";
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
    path = with pkgs; [bash coreutils rsync findutils];
    script = ''
      #!/usr/bin/env bash

      CACHE="/cache"
      BACKING="/mnt/cold"
      THRESHOLD=80  # Percentage
      TARGET=60     # Target after cleanup

      # Get cache usage percentage
      USAGE=$(df "$CACHE" | awk 'NR==2 {print int($5)}')

      if [ "$USAGE" -gt "$THRESHOLD" ]; then
        echo "Cache at $USAGE%, moving files to backing storage..."

        # Find files older than 7 days, move oldest first
        find "$CACHE" -type f -atime +7 -printf '%A@ %p\0' 2>/dev/null | \
          sort -z -n | \
          while IFS= read -r -d "" line; do
            FILE=$(echo "$line" | cut -d' ' -f2-)
            RELPATH="''${FILE#$CACHE/}"

            # Create directory structure in backing storage
            mkdir -p "$BACKING/$(dirname "$RELPATH")"

            # Move file
            rsync -a --remove-source-files "$FILE" "$BACKING/$RELPATH"

            # Check if we've reached target usage
            CURRENT=$(df "$CACHE" | awk 'NR==2 {print int($5)}')
            [ "$CURRENT" -le "$TARGET" ] && break
          done

        # Clean up empty directories
        find "$CACHE" -type d -empty -delete 2>/dev/null || true

        echo "Cache cleanup complete. Usage now: $(df "$CACHE" | awk 'NR==2 {print $5}')"
      else
        echo "Cache at $USAGE%, no cleanup needed."
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
      OnCalendar = "02:00";  # 2 AM, before SnapRAID sync at 3 AM
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

    # Daily sync at 3 AM (after cache mover at 2 AM)
    sync.interval = "03:00";

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
      "downloads/incomplete/"  # Exclude incomplete downloads
      ".cache/"
    ];

    # Touch files before sync to update timestamps
    touchBeforeSync = true;

    # Additional configuration
    extraConfig = ''
      nohidden          # Exclude hidden files
      autosave 500      # Autosave state every 500 MB processed
    '';
  };

  # Ensure SnapRAID sync runs AFTER cache mover
  systemd.services.snapraid-sync = {
    after = ["mergerfs-cache-mover.service"];
  };
}
