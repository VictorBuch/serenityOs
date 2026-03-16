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
      image = "ghcr.io/steveiliop56/tinyauth:v5.0.4";
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
        # Server config
        "TINYAUTH_SERVER_PORT" = "3000";
        "TINYAUTH_SERVER_ADDRESS" = "0.0.0.0";
        "TINYAUTH_APPURL" = cfg.appUrl;

        # Auth config
        "TINYAUTH_AUTH_SECURECOOKIE" = lib.boolToString cfg.cookieSecure;
        "TINYAUTH_AUTH_SESSIONEXPIRY" = toString cfg.sessionExpiry;
        "TINYAUTH_AUTH_LOGINMAXRETRIES" = toString cfg.loginMaxRetries;

        # Logging
        "TINYAUTH_LOG_LEVEL" = toString cfg.logLevel;

        # Pocket ID OAuth provider
        "TINYAUTH_OAUTH_PROVIDERS_POCKETID_AUTHURL" = "https://id.${domain}/authorize";
        "TINYAUTH_OAUTH_PROVIDERS_POCKETID_TOKENURL" = "https://id.${domain}/api/oidc/token";
        "TINYAUTH_OAUTH_PROVIDERS_POCKETID_USERINFOURL" = "https://id.${domain}/api/oidc/userinfo";
        "TINYAUTH_OAUTH_PROVIDERS_POCKETID_SCOPES" = "openid email profile groups";
        "TINYAUTH_OAUTH_PROVIDERS_POCKETID_NAME" = "Pocket ID";
        "TINYAUTH_OAUTH_PROVIDERS_POCKETID_REDIRECTURL" =
          "https://auth.${domain}/api/oauth/callback/pocketid";
        "TINYAUTH_OAUTH_AUTOREDIRECT" = "pocketid";

        # Analytics disabled for privacy
        "TINYAUTH_ANALYTICS_ENABLED" = "false";

        "TZ" = "Europe/Copenhagen";
      };
    };

    # Create environment file template for TinyAuth with credentials
    sops.templates."tinyauth-env" = {
      content = ''
        TINYAUTH_AUTH_USERS=${config.sops.placeholder."tinyauth/users"}
        TINYAUTH_OAUTH_PROVIDERS_POCKETID_CLIENTID=${config.sops.placeholder."pocket-id/oidc_client_id"}
        TINYAUTH_OAUTH_PROVIDERS_POCKETID_CLIENTSECRET=${
          config.sops.placeholder."pocket-id/oidc_client_secret"
        }
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
