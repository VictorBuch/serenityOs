# modules/homelab/oci-containers/fileflows.nix
{
  config,
  pkgs,
  lib,
  ...
}:

let
  mediaDir = config.homelab.mediaDir;
  domain = config.homelab.domain;
  user = config.user;
  uid = toString config.user.uid;
in

{

  options = {
    fileflows.enable = lib.mkEnableOption "Enables FileFlows media processing with NVENC support";
  };

  config = lib.mkIf config.fileflows.enable {

    # Firewall rules
    networking.firewall.allowedTCPPorts = [
      19200 # Web UI
    ];

    # Persistent data directories
    systemd.tmpfiles.rules = [
      "d /var/lib/fileflows 0770 ${uid} multimedia"
      "d /var/lib/fileflows/data 0770 ${uid} multimedia"
      "d /var/lib/fileflows/logs 0770 ${uid} multimedia"
      "d /var/lib/fileflows/temp 0770 ${uid} multimedia"
    ];

    # FileFlows container
    virtualisation.oci-containers.containers.fileflows = {
      image = "revenz/fileflows";
      autoStart = true;

      ports = [
        "19200:5000" # Web UI
      ];

      environment = {
        "TZ" = "Europe/Prague";
        "PUID" = uid;
        "PGID" = "994"; # multimedia group
        "NVIDIA_DRIVER_CAPABILITIES" = "compute,video,utility";
        "NVIDIA_VISIBLE_DEVICES" = "all";
        "OidcAuthority" = "https://id.${domain}";
        "OidcCallbackAddress" = "https://fileflows.${domain}";
      };

      environmentFiles = [
        config.sops.templates."fileflows-env".path
      ];

      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro"
        "/var/lib/fileflows/data:/app/Data"
        "/var/lib/fileflows/logs:/app/Logs"
        "/var/lib/fileflows/temp:/temp"
        "${mediaDir}:/media"
      ];

      extraOptions = [
        "--device=nvidia.com/gpu=all"
      ];
    };

    # Sops template for secret OIDC credentials
    sops.templates."fileflows-env" = {
      content = ''
        OidcClientId=${config.sops.placeholder."fileflows/oidc_client_id"}
        OidcClientSecret=${config.sops.placeholder."fileflows/oidc_client_secret"}
      '';
      owner = "root";
      group = "root";
      mode = "0400";
    };

    sops.secrets = {
      "fileflows/oidc_client_id" = {
        owner = "root";
        group = "root";
      };
      "fileflows/oidc_client_secret" = {
        owner = "root";
        group = "root";
      };
    };

    # Wait for storage mount before starting
    systemd.services.docker-fileflows = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
    };
  };
}
