# modules/homelab/oci-containers/tinyauth.nix
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.tinyauth;
  hl = config.homelab;
  domain = hl.domain;
in

{
  options.tinyauth = {
    enable = lib.mkEnableOption "Enables TinyAuth authentication service";

    appUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://auth.${domain}";
      description = "The URL where TinyAuth will be accessible";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 3000;
      description = "Port for TinyAuth service";
    };

    cookieSecure = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable secure cookies (HTTPS only)";
    };

    sessionExpiry = lib.mkOption {
      type = lib.types.int;
      default = 86400; # 24 hours
      description = "Session expiry time in seconds";
    };

    logLevel = lib.mkOption {
      type = lib.types.str;
      default = "info";
      description = "Log level verbosity";
    };

    loginMaxRetries = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "Maximum login attempts before lockout";
    };
  };

  config = lib.mkIf cfg.enable {

    # Firewall rules - allow access to TinyAuth service
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    # Create data directory for TinyAuth
    systemd.tmpfiles.rules = [
      "d /var/lib/tinyauth 755 root root"
    ];

    # TinyAuth container
    virtualisation.oci-containers.containers.tinyauth = {
      image = "ghcr.io/steveiliop56/tinyauth:v4.1.0";
      autoStart = true;

      ports = [
        "${toString cfg.port}:3000"
      ];

      volumes = [
        "/var/lib/tinyauth:/data"
      ];

      environmentFiles = [
        config.sops.templates."tinyauth-env".path
      ];

      environment = {
        "PORT" = "3000";
        "ADDRESS" = "0.0.0.0";
        "APP_URL" = cfg.appUrl;
        "SECURE_COOKIE" = lib.boolToString cfg.cookieSecure;
        "SESSION_EXPIRY" = toString cfg.sessionExpiry;
        "LOG_LEVEL" = toString cfg.logLevel;
        "LOGIN_MAX_RETRIES" = toString cfg.loginMaxRetries;
        "PROVIDERS_POCKETID_AUTH_URL" = "https://id.${domain}/authorize";
        "PROVIDERS_POCKETID_TOKEN_URL" = "https://id.${domain}/api/oidc/token";
        "PROVIDERS_POCKETID_USER_INFO_URL" = "https://id.${domain}/api/oidc/userinfo";
        "PROVIDERS_POCKETID_SCOPES" = "openid email profile groups";
        "PROVIDERS_POCKETID_NAME" = "Pocket ID";
        "PROVIDERS_POCKETID_REDIRECT_URL" = "https://auth.${domain}/api/oauth/callback/pocketid";
	"OAUTH_AUTO_REDIRECT" = "pocketid";
        "TZ" = "Europe/Copenhagen";
      };
    };

    # Create environment file template for TinyAuth with credentials
    sops.templates."tinyauth-env" = {
      content = ''
        USERS=${config.sops.placeholder."tinyauth/users"}
        PROVIDERS_POCKETID_CLIENT_ID=${config.sops.placeholder."pocket-id/oidc_client_id"}
        PROVIDERS_POCKETID_CLIENT_SECRET=${config.sops.placeholder."pocket-id/oidc_client_secret"}
      '';
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # SOPS secrets configuration for Pocket ID OIDC credentials
    sops.secrets = {
      "pocket-id/oidc_client_id" = {
        owner = "root";
        group = "root";
      };
      "pocket-id/oidc_client_secret" = {
        owner = "root";
        group = "root";
      };
    };
  };
}
