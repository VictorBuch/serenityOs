# modules/homelab/deluge-vpn.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  options = {
    homelab.deluge-vpn.enable = lib.mkEnableOption "Enables deluge with VPN through Gluetun container";

    homelab.mam-dynamic-seedbox = {
      enable = lib.mkEnableOption "Enable MyAnonaMouse dynamic seedbox IP updates";

      interval = lib.mkOption {
        type = lib.types.str;
        default = "30min";
        description = "How often to check for IP changes (systemd time format)";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.homelab.deluge-vpn.enable {

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
          "OPENVPN_ENDPOINT_PORT" = "8080"; # PIA deprecated port 1197; current UDP ports: 8080, 853, 123, 53
          "PORT_FORWARD_ONLY" = "true"; # only connect to servers that support port forwarding
          "FIREWALL_OUTBOUND_SUBNETS" = "192.168.0.0/24,10.0.0.0/24"; # Allow local network access
          "TZ" = "Europe/Copenhagen";
          # Port forwarding handled by pia-port-forward.service (bypasses gluetun bug
          # where it re-encodes the PIA payload, changing bytes and breaking the signature)
          "UPDATER_PERIOD" = "24h"; # Keep PIA server list fresh to prevent TLS failures on reconnect
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

      # Refresh PIA server list from host network before gluetun starts.
      # Gluetun's own updater can't run when VPN is down (its firewall blocks all clearnet),
      # causing a deadlock where stale IPs/ports prevent VPN from ever connecting.
      # PIA's servers are NOT in gluetun's GitHub servers.json — they use a dynamic API.
      systemd.services.gluetun-update-servers = {
        description = "Pre-fetch fresh PIA server list for gluetun";
        before = [ "docker-gluetun.service" ];
        wantedBy = [ "docker-gluetun.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "gluetun-update-servers" ''
            set -euo pipefail
            SERVERS_FILE="/var/lib/gluetun/servers.json"
            PIA_URL="https://serverlist.piaservers.net/vpninfo/servers/v6"

            echo "Fetching fresh PIA server list from PIA API..."
            RAW=$(${pkgs.curl}/bin/curl -fsSL --max-time 30 "$PIA_URL")

            # PIA response = JSON + newline + signature — strip the signature
            PIA_JSON=$(echo "$RAW" | ${pkgs.python3}/bin/python3 -c "
            import sys, json, time
            raw = sys.stdin.read()
            # Find the end of the JSON object (PIA appends a signature after a newline)
            end = raw.rfind('}') + 1
            pia = json.loads(raw[:end])

            udp_ports = pia['groups']['ovpnudp'][0]['ports']
            tcp_ports = pia['groups']['ovpntcp'][0]['ports']

            servers = []
            for region in pia['regions']:
                svrs = region.get('servers', {})
                udp_ips  = [s['ip'] for s in svrs.get('ovpnudp', [])]
                tcp_ips  = [s['ip'] for s in svrs.get('ovpntcp', [])]
                wg_ips   = [s['ip'] for s in svrs.get('wg', [])]
                if not (udp_ips or tcp_ips):
                    continue
                servers.append({
                    'region':      region['name'],
                    'hostname':    region['dns'],
                    'portforward': region.get('port_forward', False),
                    'udp':         bool(udp_ips),
                    'tcp':         bool(tcp_ips),
                    'ips':         udp_ips,
                    'tcpips':      tcp_ips,
                    'wgips':       wg_ips,
                })

            out = {
                'version': 1,
                'privateinternetaccess': {
                    'timestamp': int(time.time()),
                    'servers':   servers,
                },
            }
            print(json.dumps(out))
            ")

            echo "$PIA_JSON" > "$SERVERS_FILE.tmp"
            mv "$SERVERS_FILE.tmp" "$SERVERS_FILE"
            COUNT=$(echo "$PIA_JSON" | ${pkgs.python3}/bin/python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d['privateinternetaccess']['servers']))")
            echo "PIA server list updated: $COUNT regions written to $SERVERS_FILE"
          '';
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };

      # Ensure containers wait for storage mounts
      systemd.services.docker-gluetun = {
        after = [ "mnt-pool.mount" "gluetun-update-servers.service" ];
        requires = [ "mnt-pool.mount" ];
      };

      systemd.services.docker-deluge = {
        after = [ "mnt-pool.mount" ];
        requires = [ "mnt-pool.mount" ];
      };

      # PIA port forwarding, bypassing gluetun's built-in implementation.
      # Gluetun bug: it decodes PIA's base64 payload then re-encodes it for /bindPort.
      # Any change in timestamp precision (trailing zeros) changes the bytes,
      # invalidating PIA's signature. We save the raw payload and pass it unchanged.
      systemd.services.pia-port-forward = {
        description = "PIA port forwarding via gluetun network namespace";
        after = [ "docker-gluetun.service" ];
        wants = [ "docker-gluetun.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "pia-port-forward" ''
            set -euo pipefail
            PIA_USER=$(cat "$CREDENTIALS_DIRECTORY/pia_username")
            PIA_PASS=$(cat "$CREDENTIALS_DIRECTORY/pia_password")

            GLUETUN_PID=$(${pkgs.docker}/bin/docker inspect --format='{{.State.Pid}}' gluetun 2>/dev/null || true)
            if [ -z "$GLUETUN_PID" ] || [ "$GLUETUN_PID" = "0" ]; then
              echo "ERROR: gluetun container not running"
              exit 1
            fi

            # PIA's token API rejects requests originating from inside the VPN (403 Forbidden).
            # Fetch the token here on the host network, then pass it into the VPN namespace.
            echo "Getting PIA auth token from host network..."
            PIA_TOKEN=$(${pkgs.curl}/bin/curl -sf \
              --max-time 15 \
              --data-urlencode "username=$PIA_USER" \
              --data-urlencode "password=$PIA_PASS" \
              "https://www.privateinternetaccess.com/api/client/v2/token" \
              | ${pkgs.python3}/bin/python3 -c "import json,sys; print(json.load(sys.stdin)['token'])")

            if [ -z "$PIA_TOKEN" ]; then
              echo "ERROR: Failed to get PIA auth token"
              exit 1
            fi
            echo "Got PIA token"

            export PIA_TOKEN
            exec ${pkgs.util-linux}/bin/nsenter --net=/proc/"$GLUETUN_PID"/ns/net -- \
              ${pkgs.python3}/bin/python3 ${pkgs.writeText "pia-pf.py" ''
                import urllib.request, urllib.parse, json, base64, ssl, subprocess, os, time
                from pathlib import Path

                STATE_FILE = Path('/var/lib/gluetun/pia_pf_state.json')
                OUT_FILE   = Path('/var/lib/gluetun/forwarded_port')
                # Token was fetched on the host to avoid 403 from PIA's API inside the VPN
                token = os.environ['PIA_TOKEN']

                # Self-signed PIA gateway certs are expected — skip verification
                gw_ctx = ssl.create_default_context()
                gw_ctx.check_hostname = False
                gw_ctx.verify_mode    = ssl.CERT_NONE

                def get_json(url, ctx=None, data=None):
                    req = urllib.request.Request(url, data=data)
                    if data:
                        req.add_header('Content-Type', 'application/x-www-form-urlencoded')
                    return json.loads(urllib.request.urlopen(req, timeout=15, context=ctx).read())

                def bind(api_ip, raw_payload, signature):
                    url = (f'https://{api_ip}:19999/bindPort'
                           f'?payload={urllib.parse.quote(raw_payload)}'
                           f'&signature={urllib.parse.quote(signature)}')
                    resp = get_json(url, gw_ctx)
                    if resp.get('status') != 'OK':
                        raise RuntimeError(f'bindPort failed: {resp}')

                IPTABLES = '${pkgs.iptables}/bin/iptables'
                FW_TAG   = 'pia-pf'

                def open_firewall(port):
                    # Drop any stale pia-pf rules (e.g. from a prior port)
                    listing = subprocess.run([IPTABLES, '-S', 'INPUT'],
                                             capture_output=True, text=True).stdout
                    for line in listing.splitlines():
                        if FW_TAG in line and line.startswith('-A '):
                            del_args = ['-D'] + line.split()[1:]
                            subprocess.run([IPTABLES] + del_args, check=False)
                    for proto in ('tcp', 'udp'):
                        subprocess.run([IPTABLES, '-I', 'INPUT', '-i', 'tun0',
                                        '-p', proto, '--dport', str(port),
                                        '-m', 'comment', '--comment', FW_TAG,
                                        '-j', 'ACCEPT'], check=True)
                    print(f'Firewall opened for port {port} on tun0')

                def get_vpn_octets():
                    result = subprocess.run(['${pkgs.iproute2}/bin/ip', 'addr', 'show', 'tun0'], capture_output=True, text=True)
                    vpn_ip = next((l.strip().split()[1].split('/')[0]
                                   for l in result.stdout.splitlines() if 'inet ' in l), None)
                    if not vpn_ip:
                        raise RuntimeError('tun0 not up — VPN not connected')
                    return vpn_ip.split('.')

                def api_candidates(o):
                    return [f'{o[0]}.{o[1]}.128.1', f'{o[0]}.{o[1]}.0.1']

                # Load saved state if still valid
                state = None
                if STATE_FILE.exists():
                    try:
                        state = json.loads(STATE_FILE.read_text())
                        expires = state.get('expires_at', "")
                        if expires < time.strftime('%Y-%m-%d'):
                            print('Saved port forwarding state expired, renewing...')
                            state = None
                    except Exception:
                        state = None

                if state:
                    # Re-bind using ORIGINAL raw payload — no re-encoding, preserving exact bytes
                    print(f'Re-binding existing port {state["port"]} using saved raw payload...')
                    o = get_vpn_octets()
                    bound = False
                    for candidate in api_candidates(o):
                        try:
                            bind(candidate, state['raw_payload'], state['signature'])
                            print(f'Re-bind OK via {candidate}')
                            bound = True
                            break
                        except Exception as e:
                            print(f'  {candidate}: {e}')
                    if not bound:
                        print('Re-bind failed, getting fresh port...')
                        state = None

                if not state:
                    print('Getting fresh port signature from PIA gateway...')
                    o = get_vpn_octets()
                    api_ip = None
                    sig_resp = None
                    for candidate in api_candidates(o):
                        try:
                            r = get_json(f'https://{candidate}:19999/getSignature'
                                        f'?token={urllib.parse.quote(token)}', gw_ctx)
                            if r.get('status') == 'OK':
                                api_ip, sig_resp = candidate, r
                                break
                        except Exception as e:
                            print(f'  {candidate}: {e}')
                    if not api_ip:
                        raise RuntimeError('Cannot find PIA API endpoint or get signature')

                    raw_payload = sig_resp['payload']
                    signature   = sig_resp['signature']
                    payload_dec = json.loads(base64.b64decode(raw_payload + '=='))
                    port        = payload_dec['port']
                    expires_at  = payload_dec.get('expires_at', "")
                    print(f'PIA assigned port {port} (expires {expires_at})')

                    bind(api_ip, raw_payload, signature)
                    print(f'bindPort OK via {api_ip}')

                    state = {'port': port, 'raw_payload': raw_payload,
                             'signature': signature, 'expires_at': expires_at}
                    STATE_FILE.write_text(json.dumps(state))

                port = state['port']
                OUT_FILE.write_text(str(port))
                open_firewall(port)
                print(f'SUCCESS: forwarded_port={port}')
              ''}
          '';
          LoadCredential = [
            "pia_username:${config.sops.secrets."vpn/pia/username".path}"
            "pia_password:${config.sops.secrets."vpn/pia/password".path}"
          ];
          Restart = "on-failure";
          RestartSec = "30s";
        };
      };

      systemd.timers.pia-port-forward = {
        description = "Refresh PIA port forwarding keepalive";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "3min";
          OnUnitActiveSec = "15min";
          Persistent = true;
        };
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

      # Service to fix deluge configuration and sync with PIA forwarded port
      systemd.services.deluge-config-fix = {
        description = "Fix Deluge daemon configuration and sync with VPN forwarded port";
        after = [ "docker-deluge.service" "docker-gluetun.service" ];
        wants = [ "docker-deluge.service" "docker-gluetun.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "fix-deluge-config" ''
            # Wait for deluge to create its config
            sleep 15

            # Wait for Gluetun to establish port forwarding
            echo "Waiting for VPN port forwarding to be established..."
            MAX_WAIT=60
            WAITED=0
            while [ ! -f /var/lib/gluetun/forwarded_port ] && [ $WAITED -lt $MAX_WAIT ]; do
              sleep 5
              WAITED=$((WAITED + 5))
              echo "Waiting for forwarded port file... ($WAITED/$MAX_WAIT seconds)"
            done

            if [ ! -f /var/lib/gluetun/forwarded_port ]; then
              echo "WARNING: Forwarded port file not found after $MAX_WAIT seconds"
              echo "Continuing with configuration without port sync..."
            else
              FORWARDED_PORT=$(cat /var/lib/gluetun/forwarded_port)
              echo "VPN forwarded port detected: $FORWARDED_PORT"
            fi

            if [ -f /var/lib/deluge/config/core.conf ]; then
              # Stop deluge to modify config safely
              systemctl stop docker-deluge.service

              # Fix the configuration
              sed -i 's/"allow_remote": false/"allow_remote": true/g' /var/lib/deluge/config/core.conf
              sed -i 's/"listen_interface": ""/"listen_interface": "0.0.0.0"/g' /var/lib/deluge/config/core.conf

              # Update listen ports to match forwarded port if available
              if [ -n "$FORWARDED_PORT" ] && [ "$FORWARDED_PORT" -gt 0 ] 2>/dev/null; then
                echo "Updating Deluge listen ports to: [$FORWARDED_PORT, $FORWARDED_PORT]"

                # Use Python to properly update the JSON config (handles Deluge's special format)
                ${pkgs.python3}/bin/python3 -c "
import json
# Deluge config has two JSON objects: header and config
with open('/var/lib/deluge/config/core.conf', 'r') as f:
    content = f.read()
    # Find the second JSON object (actual config)
    first_end = content.index('}') + 1
    header = content[:first_end]
    config_str = content[first_end:]
    config = json.loads(config_str)

config['listen_ports'] = [$FORWARDED_PORT, $FORWARDED_PORT]
config['random_port'] = False

with open('/var/lib/deluge/config/core.conf', 'w') as f:
    f.write(header)
    json.dump(config, f, indent=4)
"
                echo "Successfully updated listen_ports using Python"
              fi

              # Restart deluge
              systemctl start docker-deluge.service

              echo "Deluge daemon configuration fixed and synced with VPN port"
            else
              echo "Deluge config not found"
              exit 1
            fi
          '';
          Restart = "on-failure";
          RestartSec = "30s";
        };
      };

      # Service to watch for VPN port changes and update Deluge
      systemd.services.deluge-port-sync = {
        description = "Monitor VPN port forwarding and sync with Deluge";
        after = [ "docker-deluge.service" "docker-gluetun.service" ];
        wants = [ "docker-deluge.service" "docker-gluetun.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "sync-deluge-port" ''
            # Check if forwarded port file exists
            if [ ! -f /var/lib/gluetun/forwarded_port ]; then
              echo "Forwarded port file not found, skipping sync"
              exit 0
            fi

            # Check if Deluge config exists
            if [ ! -f /var/lib/deluge/config/core.conf ]; then
              echo "Deluge config not found, skipping sync"
              exit 0
            fi

            # Read current forwarded port
            FORWARDED_PORT=$(cat /var/lib/gluetun/forwarded_port)

            if [ -z "$FORWARDED_PORT" ] || [ "$FORWARDED_PORT" -le 0 ] 2>/dev/null; then
              echo "Invalid forwarded port: $FORWARDED_PORT"
              exit 0
            fi

            # Check current Deluge port configuration using Python
            CURRENT_PORT=$(${pkgs.python3}/bin/python3 -c "
import json
try:
    with open('/var/lib/deluge/config/core.conf', 'r') as f:
        content = f.read()
        # Find the second JSON object (actual config)
        first_end = content.index('}') + 1
        config_str = content[first_end:]
        config = json.loads(config_str)
    print(config.get('listen_ports', [0])[0])
except:
    print(0)
" 2>/dev/null)

            if [ "$CURRENT_PORT" = "$FORWARDED_PORT" ]; then
              echo "Deluge already configured with correct port: $FORWARDED_PORT"
              exit 0
            fi

            echo "Port mismatch detected! VPN: $FORWARDED_PORT, Deluge: $CURRENT_PORT"
            echo "Updating Deluge configuration..."

            # Stop deluge to modify config safely
            systemctl stop docker-deluge.service

            # Update the port configuration using Python (handles Deluge's special format)
            ${pkgs.python3}/bin/python3 -c "
import json
# Deluge config has two JSON objects: header and config
with open('/var/lib/deluge/config/core.conf', 'r') as f:
    content = f.read()
    # Find the second JSON object (actual config)
    first_end = content.index('}') + 1
    header = content[:first_end]
    config_str = content[first_end:]
    config = json.loads(config_str)

config['listen_ports'] = [$FORWARDED_PORT, $FORWARDED_PORT]
config['random_port'] = False

with open('/var/lib/deluge/config/core.conf', 'w') as f:
    f.write(header)
    json.dump(config, f, indent=4)
"

            # Restart deluge with new configuration
            systemctl start docker-deluge.service

            echo "Deluge port updated to: $FORWARDED_PORT"
          '';
        };
      };

      # Timer to periodically check port synchronization
      systemd.timers.deluge-port-sync = {
        description = "Timer for Deluge port synchronization with VPN";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = "5min";
          Persistent = true;
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

    (lib.mkIf config.homelab.mam-dynamic-seedbox.enable {

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
          OnUnitActiveSec = config.homelab.mam-dynamic-seedbox.interval;
          Persistent = true;
        };
      };

    })
  ];
}
