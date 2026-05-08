{
  config,
  pkgs,
  lib,
  ...
}:

# MAM Dynamic Seedbox IP Updates
#
# Runs an alpine container in the pia-tun container's network namespace,
# fetches the current PIA exit IP from MAM's IP-check endpoint, and
# updates the MAM seedbox session if the IP changed.
#
# Setup:
# 1. Create MAM session at MyAnonaMouse > Preferences > Security
#    - Enter your VPN IP, set "IP vs ASN locked session" to "ASN"
#    - Enable "Allow session to set dynamic seedbox IP"
#    - Copy the mam_id string
# 2. sops secrets/secrets.yaml -> add `mam/session_cookie: "<mam_id>"`
# 3. Enable in host config:
#      homelab.mam-dynamic-seedbox.enable = true;
#      homelab.mam-dynamic-seedbox.interval = "10min"; # optional
# 4. Rebuild
#
# Logs: journalctl -u mam-ip-update.service -f
#
# Depends on: homelab.qbittorrent-vpn (provides docker-pia-tun.service).

{
  options.homelab.mam-dynamic-seedbox = {
    enable = lib.mkEnableOption "MyAnonaMouse dynamic seedbox IP updates via pia-tun";

    interval = lib.mkOption {
      type = lib.types.str;
      default = "30min";
      description = "How often to check for IP changes (systemd time format)";
    };
  };

  config = lib.mkIf config.homelab.mam-dynamic-seedbox.enable {

    sops.templates."mam-cookie" = {
      content = ''
        mam_id=${config.sops.placeholder."mam/session_cookie"}
      '';
      owner = "root";
      group = "root";
      mode = "0400";
    };

    environment.etc."mam-ip-monitor.sh" = {
      text = ''
        #!/bin/bash
        set -euo pipefail

        STATE_DIR="/data"
        CACHE_FILE="''${STATE_DIR}/last_ip"
        RATE_LIMIT_FILE="''${STATE_DIR}/last_update"
        COOKIE_FILE="''${STATE_DIR}/mam_cookie"
        MAM_API_URL="https://t.myanonamouse.net/json/dynamicSeedbox.php"
        MAM_IP_URL="https://t.myanonamouse.net/json/jsonIp.php"

        if [[ ! -f "''${COOKIE_FILE}" ]]; then
          echo "ERROR: MAM cookie file not found at ''${COOKIE_FILE}"
          exit 1
        fi

        MAM_COOKIE=$(cat "''${COOKIE_FILE}" | grep '^mam_id=' | cut -d'=' -f2- || echo "")
        if [[ -z "''${MAM_COOKIE}" ]]; then
          echo "ERROR: MAM cookie is empty or malformed"
          exit 1
        fi

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

        CACHED_IP=""
        if [[ -f "''${CACHE_FILE}" ]]; then
          CACHED_IP=$(cat "''${CACHE_FILE}" 2>/dev/null || echo "")
        fi

        echo "Cached IP: ''${CACHED_IP}"

        if [[ "''${CURRENT_IP}" == "''${CACHED_IP}" ]]; then
          echo "IP unchanged, no update needed"
          exit 0
        fi

        # MAM rate limit: 1 update per hour
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

        echo "Updating MAM with new IP: ''${CURRENT_IP}"
        API_RESPONSE=$(curl -s -b "mam_id=''${MAM_COOKIE}" "''${MAM_API_URL}" || echo "")

        if [[ -z "''${API_RESPONSE}" ]]; then
          echo "ERROR: Failed to call MAM API"
          exit 1
        fi

        echo "MAM API Response: ''${API_RESPONSE}"

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

    systemd.services.mam-ip-update = {
      description = "Run MAM IP update via pia-tun VPN namespace";
      after = [ "docker-pia-tun.service" ];
      wants = [ "docker-pia-tun.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "run-mam-update" ''
          mkdir -p /var/lib/mam-dynamic-seedbox

          cp "${config.sops.templates."mam-cookie".path}" /var/lib/mam-dynamic-seedbox/mam_cookie

          ${pkgs.docker}/bin/docker run --rm \
            --network=container:pia-tun \
            --volume /var/lib/mam-dynamic-seedbox:/data \
            --volume /etc/mam-ip-monitor.sh:/mam-ip-monitor.sh:ro \
            alpine:latest \
            sh -c 'apk add --no-cache curl jq bash && bash /mam-ip-monitor.sh'
        '';
        Restart = "no";
      };
    };

    systemd.timers.mam-ip-update = {
      description = "MAM Dynamic Seedbox IP Update Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = config.homelab.mam-dynamic-seedbox.interval;
        Persistent = true;
      };
    };
  };
}
