# modules/homelab/oci-containers/reactive-resume.nix
# Reactive Resume - Free and open-source resume builder
# https://docs.rxresu.me/
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.reactive-resume;
  hl = config.homelab;
  domain = hl.domain;

  # Browserless token for printer service
  browserlessToken = "rxresume-printer-token";
in

{
  options.reactive-resume = {
    enable = lib.mkEnableOption "Enables Reactive Resume - open-source resume builder";

    port = lib.mkOption {
      type = lib.types.int;
      default = 3200;
      description = "Host port for Reactive Resume web UI";
    };

    appUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://cv.${domain}";
      description = "Public URL where Reactive Resume will be accessible";
    };
  };

  config = lib.mkIf cfg.enable {

    # Create data directories
    systemd.tmpfiles.rules = [
      "d /var/lib/rxresume 755 root root"
      "d /var/lib/rxresume/postgres 755 root root"
      "d /var/lib/rxresume/seaweedfs 755 root root"
      "d /var/lib/rxresume/data 755 root root"
    ];

    # Create Docker network for inter-container communication
    systemd.services.rxresume-network = {
      description = "Create Docker network for Reactive Resume";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "create-rxresume-network" ''
          ${pkgs.docker}/bin/docker network inspect rxresume-network >/dev/null 2>&1 || \
          ${pkgs.docker}/bin/docker network create rxresume-network
        '';
        ExecStop = "${pkgs.docker}/bin/docker network rm rxresume-network || true";
      };
    };

    # SOPS secrets
    sops.secrets = {
      "reactive-resume/auth_secret" = {
        owner = "root";
        group = "root";
      };
      "reactive-resume/db_password" = {
        owner = "root";
        group = "root";
      };
    };

    # Environment file template with secrets
    sops.templates."rxresume-env" = {
      content = ''
        AUTH_SECRET=${config.sops.placeholder."reactive-resume/auth_secret"}
        DATABASE_URL=postgresql://postgres:${
          config.sops.placeholder."reactive-resume/db_password"
        }@rxresume-postgres:5432/postgres
      '';
      owner = "root";
      group = "root";
      mode = "0400";
    };

    sops.templates."rxresume-postgres-env" = {
      content = ''
        POSTGRES_PASSWORD=${config.sops.placeholder."reactive-resume/db_password"}
      '';
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # --- PostgreSQL Container ---
    virtualisation.oci-containers.containers.rxresume-postgres = {
      image = "postgres:16";
      autoStart = true;

      volumes = [
        "/var/lib/rxresume/postgres:/var/lib/postgresql/data"
      ];

      environment = {
        "POSTGRES_DB" = "postgres";
        "POSTGRES_USER" = "postgres";
      };

      environmentFiles = [
        config.sops.templates."rxresume-postgres-env".path
      ];

      extraOptions = [
        "--network=rxresume-network"
        "--health-cmd=pg_isready -U postgres -d postgres"
        "--health-interval=30s"
        "--health-timeout=10s"
        "--health-retries=3"
        "--health-start-period=10s"
      ];
    };

    # --- Browserless (Chromium) Container ---
    virtualisation.oci-containers.containers.rxresume-browserless = {
      image = "ghcr.io/browserless/chromium:latest";
      autoStart = true;

      environment = {
        "QUEUED" = "10";
        "HEALTH" = "true";
        "CONCURRENT" = "5";
        "TOKEN" = browserlessToken;
      };

      extraOptions = [
        "--network=rxresume-network"
        "--health-cmd=curl -f http://localhost:3000/pressure?token=${browserlessToken} || exit 1"
        "--health-interval=10s"
        "--health-timeout=5s"
        "--health-retries=10"
      ];
    };

    # --- SeaweedFS Container ---
    virtualisation.oci-containers.containers.rxresume-seaweedfs = {
      image = "chrislusf/seaweedfs:latest";
      autoStart = true;

      cmd = [
        "server"
        "-s3"
        "-filer"
        "-dir=/data"
        "-ip=0.0.0.0"
      ];

      volumes = [
        "/var/lib/rxresume/seaweedfs:/data"
      ];

      environment = {
        "AWS_ACCESS_KEY_ID" = "seaweedfs";
        "AWS_SECRET_ACCESS_KEY" = "seaweedfs";
      };

      extraOptions = [
        "--network=rxresume-network"
        "--health-cmd=wget -q -O /dev/null http://localhost:8888 || exit 1"
        "--health-interval=30s"
        "--health-timeout=10s"
        "--health-retries=3"
        "--health-start-period=10s"
      ];
    };

    # --- Bucket Init Container (one-shot) ---
    # Creates the S3 bucket on first run
    systemd.services.rxresume-bucket-init = {
      description = "Create Reactive Resume S3 bucket";
      after = [ "docker-rxresume-seaweedfs.service" ];
      wants = [ "docker-rxresume-seaweedfs.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "create-rxresume-bucket" ''
          # Wait for SeaweedFS to be healthy
          echo "Waiting for SeaweedFS to be ready..."
          MAX_WAIT=60
          WAITED=0
          while ! ${pkgs.docker}/bin/docker exec rxresume-seaweedfs wget -q -O /dev/null http://localhost:8888 2>/dev/null; do
            sleep 5
            WAITED=$((WAITED + 5))
            if [ $WAITED -ge $MAX_WAIT ]; then
              echo "SeaweedFS did not become ready in time"
              exit 1
            fi
            echo "Waiting for SeaweedFS... ($WAITED/$MAX_WAIT seconds)"
          done

          echo "Creating S3 bucket..."
          ${pkgs.docker}/bin/docker run --rm \
            --network=rxresume-network \
            quay.io/minio/mc:latest \
            sh -c "mc alias set seaweedfs http://rxresume-seaweedfs:8333 seaweedfs seaweedfs && mc mb seaweedfs/reactive-resume --ignore-existing"

          echo "Bucket created successfully"
        '';
        Restart = "on-failure";
        RestartSec = "30s";
      };
    };

    # --- Main Reactive Resume Container ---
    virtualisation.oci-containers.containers.reactive-resume = {
      image = "amruthpillai/reactive-resume:latest";
      autoStart = true;
      dependsOn = [
        "rxresume-postgres"
        "rxresume-browserless"
        "rxresume-seaweedfs"
      ];

      ports = [
        "${toString cfg.port}:3000"
      ];

      volumes = [
        "/var/lib/rxresume/data:/app/data"
      ];

      environmentFiles = [
        config.sops.templates."rxresume-env".path
      ];

      environment = {
        # Server
        "TZ" = "Europe/Copenhagen";
        "NODE_ENV" = "production";
        "APP_URL" = cfg.appUrl;
        "PRINTER_APP_URL" = "http://reactive-resume:3000";
        # Printer
        "PRINTER_ENDPOINT" = "ws://rxresume-browserless:3000?token=${browserlessToken}";
        # Storage (SeaweedFS S3)
        "S3_ACCESS_KEY_ID" = "seaweedfs";
        "S3_SECRET_ACCESS_KEY" = "seaweedfs";
        "S3_ENDPOINT" = "http://rxresume-seaweedfs:8333";
        "S3_BUCKET" = "reactive-resume";
        "S3_FORCE_PATH_STYLE" = "true";
      };

      extraOptions = [
        "--network=rxresume-network"
        "--health-cmd=curl -f http://localhost:3000/api/health || exit 1"
        "--health-interval=30s"
        "--health-timeout=10s"
        "--health-retries=3"
        "--health-start-period=10s"
      ];
    };

    # Ensure containers wait for network to be created
    systemd.services.docker-rxresume-postgres = {
      after = [ "rxresume-network.service" ];
      requires = [ "rxresume-network.service" ];
    };

    systemd.services.docker-rxresume-browserless = {
      after = [ "rxresume-network.service" ];
      requires = [ "rxresume-network.service" ];
    };

    systemd.services.docker-rxresume-seaweedfs = {
      after = [ "rxresume-network.service" ];
      requires = [ "rxresume-network.service" ];
    };

    systemd.services.docker-reactive-resume = {
      after = [
        "rxresume-network.service"
        "rxresume-bucket-init.service"
      ];
      requires = [ "rxresume-network.service" ];
      wants = [ "rxresume-bucket-init.service" ];
    };
  };
}
