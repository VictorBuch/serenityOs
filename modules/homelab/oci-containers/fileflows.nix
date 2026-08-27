# modules/homelab/oci-containers/fileflows.nix
{
  config,
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
    homelab.fileflows.enable = lib.mkEnableOption "Enables FileFlows media processing with NVENC support";
  };

  config = lib.mkIf config.homelab.fileflows.enable {

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
      pull = "always";
      autoStart = true;

      # Loopback-only: Caddy fronts the UI at fileflows.<domain>. Publishing
      # on 0.0.0.0 would also bypass the NixOS firewall entirely, since docker
      # installs its own nat/DOCKER-USER rules.
      ports = [
        "127.0.0.1:19200:5000" # Web UI
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

      # No docker.sock here. FileFlows only needs it for docker-mod/self-update,
      # which this deployment does not use, and its whole purpose is running
      # user-authored flow scripts — handing those the host daemon socket turns
      # any FileFlows compromise into root on the host. `:ro` would not help:
      # the Docker API is request/response over the socket, so POST
      # /containers/create still works through a read-only bind mount.
      volumes = [
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

    # Wait for storage mount and CDI spec before starting
    systemd.services.docker-fileflows = {
      after = [ "mnt-pool.mount" "nvidia-container-toolkit-cdi-generator.service" ];
      requires = [ "mnt-pool.mount" "nvidia-container-toolkit-cdi-generator.service" ];
    };
  };
}
