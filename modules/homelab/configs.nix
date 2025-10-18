{
  pkgs,
  lib,
  config,
  options,
  ...
}:
let
  hl = config.homelab;
in
{
  options.homelab = {
    trueNasIp = lib.mkOption {
      type = lib.types.str;
      default = "192.168.0.249";
    };
    mediaDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/data";
    };
    immichDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/immich";
    };
    nextcloudDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/nextcloud";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "victorbuch.com";
    };
    domain-local = lib.mkOption {
      type = lib.types.str;
      default = "local.victorbuch.com";
    };
    nixosIp = lib.mkOption {
      type = lib.types.str;
      default = "192.168.0.243";
    };
  };

  config = {
    environment.systemPackages = with pkgs; [ nfs-utils ];
    boot.initrd = {
      supportedFilesystems = [ "nfs" ];
      kernelModules = [ "nfs" ];
    };

    # NFS filesystems with robust retry and timeout options
    fileSystems."${hl.mediaDir}" = {
      device = "${hl.trueNasIp}:/mnt/Storage/Media";
      fsType = "nfs";
      options = [
        "defaults"
        "_netdev"
        "rw"
        # Add retry and timeout options for robustness
        "retry=10" # Retry mount 10 times
        "retrans=3" # Retry each request 3 times
        "timeo=600" # 60 second timeout per request
        "hard" # Hard mount - will retry indefinitely
        "intr" # Allow interruption of NFS calls
      ];
    };
    fileSystems."${hl.immichDir}" = {
      device = "${hl.trueNasIp}:/mnt/Storage/Immich";
      fsType = "nfs";
      options = [
        "defaults"
        "_netdev"
        "rw"
        "retry=10"
        "retrans=3"
        "timeo=600"
        "hard"
        "intr"
      ];
    };
    fileSystems."${hl.nextcloudDir}" = {
      device = "${hl.trueNasIp}:/mnt/Storage/Nextcloud";
      fsType = "nfs";
      options = [
        "defaults"
        "_netdev"
        "rw"
        "retry=10"
        "retrans=3"
        "timeo=600"
        "hard"
        "intr"
      ];
    };

    # Create a target that ensures all NFS mounts are ready before critical services
    systemd.targets.nfs-mounts-ready = {
      description = "All NFS mounts are ready";
      after = [
        "mnt-data.mount"
        "mnt-immich.mount"
        "mnt-nextcloud.mount"
        "network-online.target"
      ];
      requires = [
        "mnt-data.mount"
        "mnt-immich.mount"
        "mnt-nextcloud.mount"
      ];
      wantedBy = [ "multi-user.target" ];
    };

    # Add TrueNAS connectivity check service
    systemd.services.truenas-wait = {
      description = "Wait for TrueNAS to be available";
      after = [ "network-online.target" ];
      before = [
        "mnt-data.mount"
        "mnt-immich.mount"
        "mnt-nextcloud.mount"
      ];
      wantedBy = [ "nfs-mounts-ready.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "5min";
      };
      script = ''
        echo "Waiting for TrueNAS (${hl.trueNasIp}) to be available..."

        # Wait up to 5 minutes for TrueNAS to respond
        timeout=300
        interval=5
        elapsed=0

        while [ $elapsed -lt $timeout ]; do
          if ${pkgs.iputils}/bin/ping -c 1 -W 5 ${hl.trueNasIp} >/dev/null 2>&1; then
            echo "TrueNAS is responding to ping"

            # Additional check: try to contact NFS service
            if ${pkgs.nfs-utils}/bin/showmount -e ${hl.trueNasIp} >/dev/null 2>&1; then
              echo "TrueNAS NFS service is available"
              exit 0
            else
              echo "TrueNAS ping OK, but NFS not ready yet..."
            fi
          else
            echo "TrueNAS not responding, waiting... ($elapsed/$timeout seconds)"
          fi

          sleep $interval
          elapsed=$((elapsed + interval))
        done

        echo "ERROR: TrueNAS did not become available within $timeout seconds"
        exit 1
      '';
    };

  };
}
