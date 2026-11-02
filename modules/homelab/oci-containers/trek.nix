# modules/homelab/oci-containers/trek.nix
# TREK - Self-hosted travel planner
# https://github.com/liketrek/TREK
{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab.trek;
  records = config.homelab.records;
in

{
  options.homelab.trek = {
    enable = lib.mkEnableOption "Enables TREK travel planner";
  };

  config = lib.mkIf cfg.enable {
    homelab.records.trek = {
      subdomain = "travel";
      port = 3070;
      exposure = "public";
      tile = {
        title = "TREK";
        icon = "sh:trek";
        group = "productivity";
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/trek 0755 root root"
      "d /var/lib/trek/data 0755 root root"
      "d /var/lib/trek/uploads 0755 root root"
    ];

    sops.secrets = {
      "trek/encryption_key" = {
        owner = "root";
        group = "root";
      };
      "trek/oidc_client_id" = {
        owner = "root";
        group = "root";
      };
      "trek/oidc_client_secret" = {
        owner = "root";
        group = "root";
      };
    };

    sops.templates."trek-env" = {
      content = ''
        ENCRYPTION_KEY=${config.sops.placeholder."trek/encryption_key"}
        OIDC_CLIENT_ID=${config.sops.placeholder."trek/oidc_client_id"}
        OIDC_CLIENT_SECRET=${config.sops.placeholder."trek/oidc_client_secret"}
      '';
      owner = "root";
      group = "root";
      mode = "0400";
    };

    virtualisation.oci-containers.containers.trek = {
      image = "mauriceboe/trek:latest";
      autoStart = true;

      ports = [ "${toString records.trek.port}:3000" ];

      volumes = [
        "/var/lib/trek/data:/app/data"
        "/var/lib/trek/uploads:/app/uploads"
      ];

      environmentFiles = [ config.sops.templates."trek-env".path ];

      environment = {
        NODE_ENV = "production";
        PORT = "3000";
        TZ = "Europe/Copenhagen";
        APP_URL = records.trek.url;
        ALLOWED_ORIGINS = records.trek.url;
        FORCE_HTTPS = "true";
        TRUST_PROXY = "1";
        # OIDC via pocket-id. Client ID/secret come from sops via environmentFiles.
        OIDC_ISSUER = records.pocket-id.url;
        OIDC_DISPLAY_NAME = "Pocket ID";
        OIDC_USERNAME_CLAIM = "preferred_username";
        OIDC_ONLY = "true";
      };

      extraOptions = [
        "--read-only"
        "--tmpfs=/tmp:noexec,nosuid,size=128m"
        "--security-opt=no-new-privileges:true"
        "--cap-drop=ALL"
        "--cap-add=CHOWN"
        "--cap-add=SETUID"
        "--cap-add=SETGID"
        "--cap-add=KILL"
        "--health-cmd=wget -qO- http://localhost:3000/api/health || exit 1"
        "--health-interval=30s"
        "--health-timeout=10s"
        "--health-retries=3"
        "--health-start-period=15s"
      ];
    };
  };
}
