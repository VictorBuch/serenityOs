args@{ config, pkgs, lib, mkApp, ... }:

let
  hl = config.homelab;
  domain = hl.domain;

  # Define custom options that mkApp doesn't handle
  tinyauthOptions = {
    appUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://auth.${domain}";
      description = "The URL where TinyAuth will be accessible";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 3002;
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
      type = lib.types.int;
      default = 1;
      description = "Log level verbosity";
    };

    loginMaxRetries = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "Maximum login attempts before lockout";
    };
  };
in

mkApp {
  _file = toString ./.;
  name = "tinyauth";
  description = "TinyAuth authentication service";
  packages = pkgs: [];  # No packages for services

  extraConfig = { config, lib, ... }:
    let
      # Get the tinyauth config from the auto-generated option path
      cfg = lib.attrByPath (lib.splitString "." "apps.homelab.oci-containers.tinyauth") {} config;
    in
    {
      # Add custom options to the tinyauth namespace
      options = lib.setAttrByPath
        (lib.splitString "." "apps.homelab.oci-containers.tinyauth")
        tinyauthOptions;

      config = lib.mkIf cfg.enable {
        # Firewall rules - allow access to TinyAuth service
        networking.firewall.allowedTCPPorts = [ cfg.port ];

        # Create data directory for TinyAuth
        systemd.tmpfiles.rules = [
          "d /var/lib/tinyauth 755 root root"
        ];

        # TinyAuth container
        virtualisation.oci-containers.containers.tinyauth = {
          image = "ghcr.io/steveiliop56/tinyauth:v3";
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
            "COOKIE_SECURE" = lib.boolToString cfg.cookieSecure;
            "SESSION_EXPIRY" = toString cfg.sessionExpiry;
            "LOG_LEVEL" = toString cfg.logLevel;
            "LOGIN_MAX_RETRIES" = toString cfg.loginMaxRetries;
            "GENERIC_AUTH_URL" = "https://id.${domain}/authorize";
            "GENERIC_TOKEN_URL" = "https://id.${domain}/api/oidc/token";
            "GENERIC_USER_URL" = "https://id.${domain}/api/oidc/userinfo";
            "GENERIC_SCOPES" = "openid email profile groups";
            "GENERIC_NAME" = "Pocket ID";
            "OAUTH_AUTO_REDIRECT" = "generic";
            "TZ" = "Europe/Copenhagen";
          };
        };

        # Create environment file template for TinyAuth with credentials
        sops.templates."tinyauth-env" = {
          content = ''
            SECRET=${config.sops.placeholder."tinyauth/secret"}
            USERS=${config.sops.placeholder."tinyauth/users"}
            GENERIC_CLIENT_ID=${config.sops.placeholder."pocket-id/oidc_client_id"}
            GENERIC_CLIENT_SECRET=${config.sops.placeholder."pocket-id/oidc_client_secret"}
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
    };
} args
