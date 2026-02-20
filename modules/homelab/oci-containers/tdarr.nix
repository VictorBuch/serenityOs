# modules/homelab/oci-containers/tdarr.nix
{
  config,
  pkgs,
  lib,
  ...
}:

let
  mediaDir = config.homelab.mediaDir;
  user = config.user;
  uid = toString config.user.uid;
in

{

  options = {
    tdarr.enable = lib.mkEnableOption "Enables Tdarr media transcoding with NVENC support";
  };

  config = lib.mkIf config.tdarr.enable {

    # Firewall rules
    networking.firewall.allowedTCPPorts = [
      8265 # Web UI
      8266 # Server communication
    ];

    # Persistent data directories + transcode cache on local NVMe
    systemd.tmpfiles.rules = [
      "d /var/lib/tdarr 0770 ${uid} multimedia"
      "d /var/lib/tdarr/server 0770 ${uid} multimedia"
      "d /var/lib/tdarr/configs 0770 ${uid} multimedia"
      "d /var/lib/tdarr/logs 0770 ${uid} multimedia"
      "d /var/lib/tdarr/transcode_cache 0770 ${uid} multimedia"
    ];

    # Single combined server + internal node container
    virtualisation.oci-containers.containers.tdarr = {
      image = "ghcr.io/haveagitgat/tdarr:latest";
      autoStart = true;

      ports = [
        "8265:8265" # Web UI
        "8266:8266" # Server port
      ];

      environment = {
        "TZ" = "Europe/Copenhagen";
        "PUID" = uid;
        "PGID" = "994"; # multimedia group
        "UMASK_SET" = "002";
        "serverIP" = "0.0.0.0";
        "serverPort" = "8266";
        "webUIPort" = "8265";
        "internalNode" = "true";
        "inContainer" = "true";
        "ffmpegVersion" = "7";
        "nodeName" = "SerenityNode";
        "NVIDIA_DRIVER_CAPABILITIES" = "all";
        "NVIDIA_VISIBLE_DEVICES" = "all";
      };

      volumes = [
        "/var/lib/tdarr/server:/app/server"
        "/var/lib/tdarr/configs:/app/configs"
        "/var/lib/tdarr/logs:/app/logs"
        "/var/lib/tdarr/transcode_cache:/temp"
        "${mediaDir}:/media"
      ];

      extraOptions = [
        "--gpus=all"
        "--device=/dev/dri:/dev/dri"
      ];
    };

    # Wait for storage mount before starting
    systemd.services.docker-tdarr = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
    };
  };
}
