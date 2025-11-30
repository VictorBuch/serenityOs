{
  config,
  pkgs,
  lib,
  options,
  ...
}:

let
  domain = config.homelab.domain;
  user = config.user;
  giteaDir = "/var/lib/gitea";
  giteaUser = "gitea";
  giteaGroup = "gitea";
in

{
  options.gitea.enable = lib.mkEnableOption "Enables Gitea git service with Actions runners";

  config = lib.mkIf config.gitea.enable {

    # PostgreSQL database for Gitea
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
      ensureDatabases = [ "gitea" ];
      ensureUsers = [
        {
          name = giteaUser;
          ensureDBOwnership = true;
        }
      ];
    };

    # Ensure PostgreSQL starts before Gitea
    systemd.services.gitea.after = [ "postgresql.service" ];
    systemd.services.gitea.requires = [ "postgresql.service" ];

    # Gitea service configuration
    services.gitea = {
      enable = true;
      package = pkgs.unstable.gitea;
      appName = "Git Server";

      database = {
        type = "postgres";
        host = "/run/postgresql";
        name = "gitea";
        user = giteaUser;
        # Uses Unix socket authentication - no password needed
      };

      # Git LFS support for large files
      lfs.enable = true;

      settings = {
        server = {
          DOMAIN = "git.${domain}";
          ROOT_URL = "https://git.${domain}/";
          HTTP_ADDR = "127.0.0.1";
          HTTP_PORT = 3004;

          # SSH configuration
          DISABLE_SSH = false;
          SSH_DOMAIN = "git.${domain}";
          SSH_PORT = 2222;
          START_SSH_SERVER = true;
          SSH_LISTEN_HOST = "0.0.0.0";
          SSH_LISTEN_PORT = 2222;
        };

        service = {
          DISABLE_REGISTRATION = true; # Allow user registration (change to true after initial setup if desired)
          REQUIRE_SIGNIN_VIEW = false; # Public repositories are viewable without login
        };

        # Enable Gitea Actions for CI/CD
        actions = {
          ENABLED = true;
          DEFAULT_ACTIONS_URL = "github";
        };

        # Security settings
        security = {
          INSTALL_LOCK = true;
        };

        # Session configuration
        session = {
          COOKIE_SECURE = true;
          COOKIE_NAME = "gitea_session";
        };

        # Git LFS configuration
        lfs = {
          PATH = "${giteaDir}/data/lfs";
        };

        # Repository settings
        repository = {
          ROOT = "${giteaDir}/repositories";
          DEFAULT_BRANCH = "main";
        };

        # Log settings
        log = {
          MODE = "console, file";
          LEVEL = "Info";
        };
      };
    };

    # Gitea Actions Runners for CI/CD
    services.gitea-actions-runner = {
      package = pkgs.unstable.forgejo-runner; # Compatible with Gitea Actions

      instances = {
        # Docker runner for containerized builds
        docker = {
          enable = true;
          name = "docker-runner";
          url = "https://git.${domain}";
          # Token needs to be generated in Gitea UI after first setup
          # Go to Site Administration -> Actions -> Runners -> Create new runner
          tokenFile = config.sops.templates."gitea-runner-env".path;
          labels = [
            "docker:docker://node:20-bookworm"
            "ubuntu-latest:docker://node:20-bookworm"
          ];
          settings = {
            container = {
              network = "bridge";
            };
          };
        };

        # Nix runner for Nix builds
        nix = {
          enable = true;
          name = "nix-runner";
          url = "https://git.${domain}";
          tokenFile = config.sops.templates."gitea-runner-env".path;
          labels = [
            "nix:host"
          ];
          hostPackages = with pkgs; [
            bash
            coreutils
            curl
            git
            nix
          ];
        };
      };
    };

    # SOPS secrets configuration
    sops.secrets."gitea/runner_token" = {
      mode = "0444"; # Make readable by both runner users
      owner = "root";
      group = "root";
      restartUnits = [
        "gitea-runner-docker.service"
        "gitea-runner-nix.service"
      ];
    };

    # Create environment file with TOKEN variable for runners
    sops.templates."gitea-runner-env" = {
      content = ''
        TOKEN=${config.sops.placeholder."gitea/runner_token"}
      '';
      owner = "root";
      group = "root";
      mode = "0444";
    };

    # Open firewall port for Gitea SSH
    networking.firewall.allowedTCPPorts = [ 2222 ];

    # Add main user to gitea group for management access
    users.users.${user.userName}.extraGroups = [ giteaGroup ];

    # Ensure proper permissions on Gitea directories
    systemd.tmpfiles.rules = [
      "d ${giteaDir} 0750 ${giteaUser} ${giteaGroup}"
      "d ${giteaDir}/repositories 0750 ${giteaUser} ${giteaGroup}"
      "d ${giteaDir}/data 0750 ${giteaUser} ${giteaGroup}"
      "d ${giteaDir}/data/lfs 0750 ${giteaUser} ${giteaGroup}"
    ];
  };
}
