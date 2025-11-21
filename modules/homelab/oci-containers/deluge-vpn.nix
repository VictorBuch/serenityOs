# modules/homelab/deluge-vpn.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  options = {
    deluge-vpn.enable = lib.mkEnableOption "Enables deluge with VPN through Gluetun container";

    mam-dynamic-seedbox = {
      enable = lib.mkEnableOption "Enable MyAnonaMouse dynamic seedbox IP updates";

      interval = lib.mkOption {
        type = lib.types.str;
        default = "30min";
        description = "How often to check for IP changes (systemd time format)";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.deluge-vpn.enable {

      # Firewall rules - only allow web UI access
      networking.firewall = {
        allowedTCPPorts = [ 8112 ]; # Deluge web UI
      };

      # Gluetun VPN container
      virtualisation.oci-containers.containers.gluetun = {
        image = "qmcgaw/gluetun:latest";
        autoStart = true;

        ports = [
          "8112:8112" # Deluge web UI
          "58846:58846" # Deluge daemon
        ];

        volumes = [
          "/var/lib/gluetun:/gluetun"
        ];

        environmentFiles = [
          config.sops.templates."gluetun-env".path
        ];

        environment = {
          # Gluetun configuration
          "VPN_SERVICE_PROVIDER" = "private internet access";
          "VPN_TYPE" = "openvpn";
          "OPENVPN_VERSION" = "2.6";
          "SERVER_REGIONS" = "DE Berlin";
          "FIREWALL_OUTBOUND_SUBNETS" = "192.168.0.0/24,10.0.0.0/24"; # Allow local network access
          "TZ" = "Europe/Copenhagen";
          "VPN_PORT_FORWARDING" = "on";
          "PORT_FORWARDING_STATUS_FILE" = "/gluetun/forwarded_port";
          "LOG_LEVEL" = "info";
        };

        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--device=/dev/net/tun:/dev/net/tun"
        ];
      };

      # Deluge container using Gluetun's network
      virtualisation.oci-containers.containers.deluge = {
        image = "lscr.io/linuxserver/deluge:latest";
        autoStart = true;
        dependsOn = [ "gluetun" ];

        volumes = [
          "/var/lib/deluge/config:/config"
          "${config.homelab.mediaDir}/downloads:/downloads"
        ];

        environment = {
          "PUID" = "1000"; # serenity user UID
          "PGID" = "994"; # multimedia group GID
          "TZ" = "Europe/Copenhagen";
          "DELUGE_LOGLEVEL" = "error";
        };

        extraOptions = [
          "--network=container:gluetun"
        ];
      };

      # Ensure containers wait for storage mounts
      systemd.services.docker-gluetun = {
        after = [ "mnt-pool.mount" ];
        requires = [ "mnt-pool.mount" ];
      };

      systemd.services.docker-deluge = {
        after = [ "mnt-pool.mount" ];
        requires = [ "mnt-pool.mount" ];
      };

      # Create environment file template for Gluetun with PIA credentials
      sops.templates."gluetun-env" = {
        content = ''
          OPENVPN_USER=${config.sops.placeholder."vpn/pia/username"}
          OPENVPN_PASSWORD=${config.sops.placeholder."vpn/pia/password"}
        '';
        owner = "root";
        group = "root";
        mode = "0400";
      };

      # Service to fix deluge configuration after container starts
      systemd.services.deluge-config-fix = {
        description = "Fix Deluge daemon configuration for remote access";
        after = [ "docker-deluge.service" ];
        wants = [ "docker-deluge.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "fix-deluge-config" ''
            # Wait for deluge to create its config
            sleep 15

            if [ -f /var/lib/deluge/config/core.conf ]; then
              # Stop deluge to modify config safely
              systemctl stop docker-deluge.service
              
              # Fix the configuration
              sed -i 's/"allow_remote": false/"allow_remote": true/g' /var/lib/deluge/config/core.conf
              sed -i 's/"listen_interface": ""/"listen_interface": "0.0.0.0"/g' /var/lib/deluge/config/core.conf
              
              # Restart deluge
              systemctl start docker-deluge.service
              
              echo "Deluge daemon configuration fixed for remote access"
            else
              echo "Deluge config not found"
              exit 1
            fi
          '';
          Restart = "on-failure";
          RestartSec = "30s";
        };
      };

      # MAM Dynamic Seedbox IP Updates
      #
      # Setup Instructions:
      # 1. Create MAM session:
      #    - Go to MyAnonaMouse > Your Username > Preferences > Security
      #    - In "Create session" box, enter your VPN IP (check with Gluetun logs or MAM IP check)
      #    - Set "IP vs ASN locked session" to "ASN" (recommended for VPN setups)
      #    - Click "Submit changes!" and copy the long mam_id string
      #    - Go back and enable "Allow session to set dynamic seedbox IP" for that session
      #
      # 2. Add to SOPS secrets file:
      #    Add: mam/session_cookie: "your_long_mam_id_string_here"
      #
      # 3. Enable in configuration:
      #    mam-dynamic-seedbox.enable = true;
      #    mam-dynamic-seedbox.interval = "10min"; # optional, default is 30min
      #
      # 4. Rebuild NixOS configuration
      #
      # The service will automatically:
      # - Check IP every 30 minutes (configurable)
      # - Only call MAM API when IP changes
      # - Respect 1-hour rate limit
      # - Log all actions to systemd journal
      #
      # View logs with: journalctl -u mam-ip-update.service -f
      #

    })

    (lib.mkIf config.mam-dynamic-seedbox.enable {

      # SOPS template for MAM session cookie
      sops.templates."mam-cookie" = {
        content = ''
          mam_id=${config.sops.placeholder."mam/session_cookie"}
        '';
        owner = "root";
        group = "root";
        mode = "0400";
      };

      # MAM IP monitoring script (to be mounted in container)
      environment.etc."mam-ip-monitor.sh" = {
        text = ''
          #!/bin/bash
          set -euo pipefail

          # Configuration
          STATE_DIR="/data"
          CACHE_FILE="''${STATE_DIR}/last_ip"
          RATE_LIMIT_FILE="''${STATE_DIR}/last_update"
          COOKIE_FILE="''${STATE_DIR}/mam_cookie"
          MAM_API_URL="https://t.myanonamouse.net/json/dynamicSeedbox.php"
          MAM_IP_URL="https://t.myanonamouse.net/json/jsonIp.php"

          # Check if cookie file exists
          if [[ ! -f "''${COOKIE_FILE}" ]]; then
            echo "ERROR: MAM cookie file not found at ''${COOKIE_FILE}"
            echo "Please ensure MAM session cookie is configured"
            exit 1
          fi

          # Read cookie
          MAM_COOKIE=$(cat "''${COOKIE_FILE}" | grep '^mam_id=' | cut -d'=' -f2- || echo "")
          if [[ -z "''${MAM_COOKIE}" ]]; then
            echo "ERROR: MAM cookie is empty or malformed"
            exit 1
          fi

          # Get current IP from MAM (this ensures we're using the VPN IP)
          echo "Checking current IP..."
          CURRENT_IP_RESPONSE=$(curl -s --fail "''${MAM_IP_URL}" || echo "")
          if [[ -z "''${CURRENT_IP_RESPONSE}" ]]; then
            echo "ERROR: Failed to get current IP from MAM"
            exit 1
          fi

          CURRENT_IP=$(echo "''${CURRENT_IP_RESPONSE}" | jq -r '.ip' 2>/dev/null || echo "")
          if [[ -z "''${CURRENT_IP}" || "''${CURRENT_IP}" == "null" ]]; then
            echo "ERROR: Failed to parse IP from response: ''${CURRENT_IP_RESPONSE}"
            exit 1
          fi

          echo "Current IP: ''${CURRENT_IP}"

          # Check cached IP
          CACHED_IP=""
          if [[ -f "''${CACHE_FILE}" ]]; then
            CACHED_IP=$(cat "''${CACHE_FILE}" 2>/dev/null || echo "")
          fi

          echo "Cached IP: ''${CACHED_IP}"

          # Check if IP has changed
          if [[ "''${CURRENT_IP}" == "''${CACHED_IP}" ]]; then
            echo "IP unchanged, no update needed"
            exit 0
          fi

          # Check rate limit (1 hour = 3600 seconds)
          if [[ -f "''${RATE_LIMIT_FILE}" ]]; then
            LAST_UPDATE=$(cat "''${RATE_LIMIT_FILE}" 2>/dev/null || echo "0")
            CURRENT_TIME=$(date +%s)
            TIME_DIFF=$((CURRENT_TIME - LAST_UPDATE))

            if [[ ''${TIME_DIFF} -lt 3600 ]]; then
              WAIT_TIME=$((3600 - TIME_DIFF))
              echo "Rate limit: Must wait ''${WAIT_TIME} seconds before next update"
              exit 0
            fi
          fi

          # Update MAM with new IP
          echo "Updating MAM with new IP: ''${CURRENT_IP}"
          API_RESPONSE=$(curl -s -b "mam_id=''${MAM_COOKIE}" "''${MAM_API_URL}" || echo "")

          if [[ -z "''${API_RESPONSE}" ]]; then
            echo "ERROR: Failed to call MAM API"
            exit 1
          fi

          echo "MAM API Response: ''${API_RESPONSE}"

          # Parse response
          SUCCESS=$(echo "''${API_RESPONSE}" | jq -r '.Success' 2>/dev/null || echo "false")
          MESSAGE=$(echo "''${API_RESPONSE}" | jq -r '.msg' 2>/dev/null || echo "unknown")

          if [[ "''${SUCCESS}" == "true" ]]; then
            case "''${MESSAGE}" in
              "Completed")
                echo "SUCCESS: IP updated to ''${CURRENT_IP}"
                echo "''${CURRENT_IP}" > "''${CACHE_FILE}"
                date +%s > "''${RATE_LIMIT_FILE}"
                ;;
              "No Change")
                echo "SUCCESS: IP already set to ''${CURRENT_IP}"
                echo "''${CURRENT_IP}" > "''${CACHE_FILE}"
                ;;
              *)
                echo "SUCCESS: ''${MESSAGE}"
                echo "''${CURRENT_IP}" > "''${CACHE_FILE}"
                ;;
            esac
          else
            echo "ERROR: MAM API call failed - ''${MESSAGE}"
            case "''${MESSAGE}" in
              "Last Change too recent")
                echo "Rate limited by MAM, will retry later"
                ;;
              "No Session Cookie"|"Invalid session"*)
                echo "Cookie/session issue - check MAM session configuration"
                exit 1
                ;;
              "Incorrect session type"*)
                echo "Session type issue - ensure 'Allow session to set dynamic seedbox IP' is enabled"
                exit 1
                ;;
              *)
                echo "Unknown error from MAM API"
                exit 1
                ;;
            esac
          fi
        '';
        mode = "0755";
      };

      # Timer-triggered service to run MAM IP update in VPN container
      systemd.services.mam-ip-update = {
        description = "Run MAM IP update via VPN";
        after = [ "docker-gluetun.service" ];
        wants = [ "docker-gluetun.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "run-mam-update" ''
            # Ensure state directory exists
            mkdir -p /var/lib/mam-dynamic-seedbox

            # Copy cookie file from SOPS template to shared volume
            cp "${config.sops.templates."mam-cookie".path}" /var/lib/mam-dynamic-seedbox/mam_cookie

            # Run the script in a temporary container using Gluetun's network
            ${pkgs.docker}/bin/docker run --rm \
              --network=container:gluetun \
              --volume /var/lib/mam-dynamic-seedbox:/data \
              --volume /etc/mam-ip-monitor.sh:/mam-ip-monitor.sh:ro \
              alpine:latest \
              sh -c 'apk add --no-cache curl jq bash && bash /mam-ip-monitor.sh'
          '';
          Restart = "no";
        };
      };

      # Timer for periodic IP monitoring
      systemd.timers.mam-ip-update = {
        description = "MAM Dynamic Seedbox IP Update Timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = config.mam-dynamic-seedbox.interval;
          Persistent = true;
        };
      };

    })
  ];
}
