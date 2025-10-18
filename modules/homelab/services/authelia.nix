{
  config,
  pkgs,
  lib,
  ...
}:

let
  hl = config.homelab;
  domain = hl.domain;
in

{
  options = {
    authelia.enable = lib.mkEnableOption "Enables Authelia SSO authentication";
  };

  config = lib.mkIf config.authelia.enable {

    # SOPS template for users database with admin password
    sops.templates."authelia-users.yml" = {
      content = ''
        users:
          admin:
            displayname: "Admin User"
            password: "${config.sops.placeholder."authelia/admin_password_hash"}"
            email: admin@${domain}
            groups:
              - admins
              - dev
      '';
      owner = "authelia-main";
      group = "authelia-main";
      mode = "0600";
    };

    services.authelia.instances.main = {
      enable = true;

      secrets = {
        jwtSecretFile = config.sops.secrets."authelia/jwt_secret".path;
        sessionSecretFile = config.sops.secrets."authelia/session_secret".path;
        storageEncryptionKeyFile = config.sops.secrets."authelia/storage_encryption_key".path;
      };

      settings = {
        theme = "dark";

        server = {
          address = "tcp://127.0.0.1:9091";
          buffers = {
            read = 16384;
          };
        };

        log = {
          level = "info";
          format = "text";
        };

        totp.issuer = domain;

        authentication_backend = {
          file = {
            path = "${config.sops.templates."authelia-users.yml".path}";
            password = {
              algorithm = "argon2id";
              iterations = 1;
              salt_length = 16;
              parallelism = 8;
              memory = 64;
            };
          };
        };

        access_control = {
          default_policy = "deny";
          rules = [
            # Allow access to Authelia portal
            {
              domain = "auth.${domain}";
              policy = "bypass";
            }
            # Bypass authentication for excluded services
            {
              domain = "plex.${domain}";
              policy = "bypass";
            }
            {
              domain = "jellyfin.${domain}";
              policy = "bypass";
            }
            {
              domain = "request.${domain}";
              policy = "bypass";
            }
            # Require authentication for all other services
            {
              domain = "*.${domain}";
              policy = "one_factor";
            }
          ];
        };

        session = {
          name = "authelia_session";
          expiration = "1h";
          inactivity = "5m";
          cookies = [
            {
              domain = domain;
              authelia_url = "https://auth.${domain}";
              default_redirection_url = "https://dashboard.${domain}";
            }
          ];
        };

        regulation = {
          max_retries = 3;
          find_time = "2m";
          ban_time = "5m";
        };

        storage = {
          local = {
            path = "/var/lib/authelia-main/db.sqlite3";
          };
        };

        notifier = {
          filesystem = {
            filename = "/var/lib/authelia-main/notification.txt";
          };
        };
      };
    };

  };
}
