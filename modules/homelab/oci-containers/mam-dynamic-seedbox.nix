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

        # MAM session is ASN-locked (per setup instructions), so we only need
        # to call dynamicSeedbox when the ASN we're egressing from changes.
        # PIA cycles exit IPs per-connection within the same ASN, so IP-based
        # change detection would trigger on every run for no reason.
        # HEARTBEAT_INTERVAL forces a refresh even when ASN is stable, so the
        # session keeps showing activity to MAM.

        STATE_DIR="/data"
        ASN_CACHE_FILE="''${STATE_DIR}/last_asn"
        RATE_LIMIT_FILE="''${STATE_DIR}/last_update"
        COOKIE_FILE="''${STATE_DIR}/mam_cookie"
        MAM_API_URL="https://t.myanonamouse.net/json/dynamicSeedbox.php"
        ASN_LOOKUP_URL="https://ipinfo.io/json"
        HEARTBEAT_INTERVAL=604800  # 7 days

        if [[ ! -f "''${COOKIE_FILE}" ]]; then
          echo "ERROR: MAM cookie file not found at ''${COOKIE_FILE}"
          exit 1
        fi

        MAM_COOKIE=$(cat "''${COOKIE_FILE}" | grep '^mam_id=' | cut -d'=' -f2- || echo "")
        if [[ -z "''${MAM_COOKIE}" ]]; then
          echo "ERROR: MAM cookie is empty or malformed"
          exit 1
        fi

        echo "Looking up current ASN..."
        LOOKUP_RESPONSE=$(curl -s --fail "''${ASN_LOOKUP_URL}" || echo "")
        if [[ -z "''${LOOKUP_RESPONSE}" ]]; then
          echo "ERROR: Failed to look up current ASN"
          exit 1
        fi

        CURRENT_ASN=$(echo "''${LOOKUP_RESPONSE}" | jq -r '.org' 2>/dev/null | grep -oE '^AS[0-9]+' || echo "")
        if [[ -z "''${CURRENT_ASN}" ]]; then
          echo "ERROR: Failed to parse ASN from response: ''${LOOKUP_RESPONSE}"
          exit 1
        fi

        CURRENT_IP=$(echo "''${LOOKUP_RESPONSE}" | jq -r '.ip' 2>/dev/null || echo "unknown")
        echo "Current egress: ''${CURRENT_IP} (''${CURRENT_ASN})"

        CACHED_ASN=""
        if [[ -f "''${ASN_CACHE_FILE}" ]]; then
          CACHED_ASN=$(cat "''${ASN_CACHE_FILE}" 2>/dev/null || echo "")
        fi

        NOW=$(date +%s)
        LAST_UPDATE=0
        if [[ -f "''${RATE_LIMIT_FILE}" ]]; then
          LAST_UPDATE=$(cat "''${RATE_LIMIT_FILE}" 2>/dev/null || echo "0")
        fi
        TIME_SINCE_UPDATE=$((NOW - LAST_UPDATE))

        if [[ "''${CURRENT_ASN}" == "''${CACHED_ASN}" && ''${TIME_SINCE_UPDATE} -lt ''${HEARTBEAT_INTERVAL} ]]; then
          echo "ASN unchanged (''${CURRENT_ASN}), heartbeat not due (''${TIME_SINCE_UPDATE}s/''${HEARTBEAT_INTERVAL}s), skipping"
          exit 0
        fi

        if [[ ''${TIME_SINCE_UPDATE} -lt 3600 ]]; then
          WAIT_TIME=$((3600 - TIME_SINCE_UPDATE))
          echo "Rate limit: Must wait ''${WAIT_TIME} seconds before next update"
          exit 0
        fi

        if [[ "''${CURRENT_ASN}" != "''${CACHED_ASN}" ]]; then
          echo "ASN changed: ''${CACHED_ASN:-<none>} -> ''${CURRENT_ASN}, updating MAM..."
        else
          echo "Heartbeat refresh (''${TIME_SINCE_UPDATE}s since last update), updating MAM..."
        fi

        API_RESPONSE=$(curl -s -b "mam_id=''${MAM_COOKIE}" "''${MAM_API_URL}" || echo "")

        if [[ -z "''${API_RESPONSE}" ]]; then
          echo "ERROR: Failed to call MAM API"
          exit 1
        fi

        echo "MAM API Response: ''${API_RESPONSE}"

        SUCCESS=$(echo "''${API_RESPONSE}" | jq -r '.Success' 2>/dev/null || echo "false")
        MESSAGE=$(echo "''${API_RESPONSE}" | jq -r '.msg' 2>/dev/null || echo "unknown")
        RESPONSE_ASN=$(echo "''${API_RESPONSE}" | jq -r '.ASN' 2>/dev/null || echo "")

        if [[ "''${SUCCESS}" == "true" ]]; then
          case "''${MESSAGE}" in
            "Completed"|"No Change")
              echo "SUCCESS: ''${MESSAGE} (MAM ASN=AS''${RESPONSE_ASN})"
              ;;
            *)
              echo "SUCCESS: ''${MESSAGE}"
              ;;
          esac
          if [[ -n "''${RESPONSE_ASN}" && "''${RESPONSE_ASN}" != "null" ]]; then
            echo "AS''${RESPONSE_ASN}" > "''${ASN_CACHE_FILE}"
          else
            echo "''${CURRENT_ASN}" > "''${ASN_CACHE_FILE}"
          fi
          date +%s > "''${RATE_LIMIT_FILE}"
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
