# wash — Netcup VPS running Pangolin (tunneled reverse proxy + auth for the homelab).
# Public entrypoint for *.victorbuch.com and *.smoothless.org; tunnels to mal via newt.
{
  config,
  pkgs,
  lib,
  inputs,
  pkgs-stable,
  ...
}:
let
  username = "wash";
  domain = "victorbuch.com";
  wannaShareDomain = "smoothless.org";

  # Pangolin only offers the "Country" match type in resource rules once it can
  # resolve IPs to countries; with no maxmind_db_path in config.yml the Match
  # Type dropdown is Path/IP/IP Range only. MaxMind's own downloads want an
  # account and a license key, so this pins node-geolite2-redist's mirror of
  # GeoLite2-Country instead. Country assignments drift slowly — bump rev and
  # hash when it goes stale (the redist repo republishes weekly).
  geolite2Country =
    pkgs.runCommand "GeoLite2-Country.mmdb"
      {
        src = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/GitSquared/node-geolite2-redist/f12a2cefc912d73f5c073d1cdd97ab1e36d7b26f/redist/GeoLite2-Country.tar.gz";
          hash = "sha256-CP2YNfXvJnPg/l/S4A1WyoeG8hPXvxHMPN0UwGIL1Kk=";
        };
      }
      ''
        tar -xzf $src --strip-components=1
        install -m 0444 GeoLite2-Country.mmdb $out
      '';
in
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    # Netcup's UEFI NVRAM does not persist reliably across power cycles —
    # skip EFI variables and rely on the fallback \EFI\BOOT\BOOTX64.EFI path
    loader.efi.canTouchEfiVariables = false;
  };

  networking = {
    hostName = "wash";
    useDHCP = true;
    # Static resolvers: DHCP populates resolv.conf too late for traefik's
    # startup (badger plugin download + ACME hit an empty resolv.conf and
    # fall back to [::1]:53). Baked-in entries close the race for good.
    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];
    # 80/443 TCP + 51820 UDP are opened by services.pangolin.openFirewall.
    # Gerbil's actual UDP data-plane server listens on 21820 (module's
    # openFirewall misses it) — without this, newt's WG handshake is dropped
    # and every tunneled request 504s.
    firewall.allowedUDPPorts = [ 21820 ];
  };

  # GC, store optimization, boot cleanup
  maintenance.enable = true;

  # Weekly auto-upgrade, matching mal. Both ends of the pangolin tunnel have to
  # move together: wash upgrading only on manual deploys is what let it jump
  # 3.5 weeks of nixpkgs in one go on 2026-08-27 and break the tunnel.
  autoupgrade.enable = true;

  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_DK.UTF-8";

  zramSwap.enable = true;

  # No desktop, no yubikey tooling on the VPS
  yubikey.enable = false;

  user.userName = username;

  # Key-only SSH box with no console password — wheel must sudo without one
  security.sudo.wheelNeedsPassword = false;

  # FIDO2 SSH authorized keys -- one per YubiKey (same as mal)
  users.users."${username}".openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINIkyb8ktnpdCcN3S2k6gkSGqtoMeAATgUaF3mET/FP7AAAABHNzaDo= jayne@yubikey-5c-nano"
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJvUM1QnLCbxff2rLeHmJ/uwOPwSYpxoxoh644OaMK6CAAAABHNzaDo= inara@yubikey-5c-nano"
  ];

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
        PubkeyAuthentication = true;
        AuthenticationMethods = "publickey";
      };
    };

    fail2ban = {
      enable = true;
      bantime = "8h";
    };
  };

  # Sops configuration — wash only gets secrets/vps.yaml, not the homelab vault
  sops = {
    defaultSopsFile = "${inputs.self}/secrets/vps.yaml";
    defaultSopsFormat = "yaml";

    # Staged by nixos-anywhere --extra-files before first boot
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      "cloudflare/api_token" = { };
      "pangolin/server_secret" = { };
    };

    templates."pangolin.env" = {
      content = ''
        SERVER_SECRET=${config.sops.placeholder."pangolin/server_secret"}
      '';
      mode = "0400";
    };

    # lego (via traefik) reads CF_DNS_API_TOKEN for DNS-01 wildcard certs.
    # Propagation timeout raised: default 60s loses to recursive resolvers'
    # ~5 min negative caching of _acme-challenge names.
    templates."traefik-cf.env" = {
      content = ''
        CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare/api_token"}
        CLOUDFLARE_PROPAGATION_TIMEOUT=300
        CLOUDFLARE_POLLING_INTERVAL=10
      '';
      owner = "traefik";
      mode = "0400";
    };
  };

  # The module wires gerbil `requires` pangolin and traefik `requires`/`partOf`
  # gerbil. systemd propagates stop down that chain but never propagates start
  # back up, so anything that takes pangolin down — a failed start, a restart
  # that loses a race — drops 80/443 and leaves them down until someone notices
  # and runs `systemctl start pangolin gerbil traefik` by hand. That cost a
  # 40 minute outage on 2026-08-27.
  #
  # Upholds= is the missing edge: while the upholding unit is running, systemd
  # keeps starting the upheld one until it is active. Stop still propagates down
  # (intended), but recovery now propagates back up on its own. The module
  # already upholds traefik from gerbil; only this half was missing, which is
  # why a pangolin that failed twice and succeeded on the third restart left
  # gerbil and traefik dead behind it.
  systemd.services.pangolin.upholds = [ "gerbil.service" ];

  # Second half of the same story, and the one that actually caused the long
  # outages. Pangolin dies of V8 heap exhaustion (status=6/ABRT, "Ineffective
  # mark-compacts near heap limit", ~3G RSS on a 3.8G box) and systemd restarts
  # it. Because gerbil `requires` pangolin and traefik `requires`+`partOf`
  # gerbil, every one of those bounces tears down the public listener too --
  # even though traefik's HTTP provider polls pangolin's localhost:3001 with its
  # own backoff and rides a restart out perfectly well on its own.
  #
  # nixpkgs' traefik module then sets StartLimitBurst=5 with a *24 hour*
  # StartLimitIntervalSec (86400, not systemd's 10s default). Five pangolin
  # crashes in a day is enough to lock traefik out for the remainder of that
  # sliding window, and gerbil's Upholds= retries every 10s against a limiter
  # that will not clear -- 78,433 `start-limit-hit` entries in three days, and
  # 80/443 refusing connections for 12h35m on 2026-08-29. The tunnel came back
  # at 10:37:55, 10:38:02, 10:38:09 on three consecutive days: not a timer, just
  # the 24h window sliding.
  #
  # So: ordering, not stop-propagation. traefik stays up across a pangolin
  # bounce, which also keeps /api/v1/auth/newt/get-token reachable so newt can
  # reconnect the moment the backend returns.
  #
  # requiredBy on gerbil has to go too -- it plants a symlink in
  # traefik.service.requires/, which mkForce on traefik.requires cannot reach.
  systemd.services.gerbil.requiredBy = lib.mkForce [ ];

  systemd.services.traefik = {
    requires = lib.mkForce [ ];
    partOf = lib.mkForce [ ];

    # network-online: traefik downloads the badger plugin and reaches LE at
    # startup; without this it races DHCP/DNS on boot and comes up degraded
    # (plugins disabled, ACME stuck on [::1]:53).
    wants = [
      "gerbil.service"
      "network-online.target"
    ];
    after = [ "network-online.target" ];

    # A rate limit that outlives the incident it is rate-limiting is not a
    # safety net. One minute bounds a genuine crash-spin (Upholds= retries at
    # 10s, so ~6 attempts/min against a burst of 10) and clears itself long
    # before anyone notices. Upstream's 24h window is presumably there to keep a
    # restart loop off Let's Encrypt, but these are DNS-01 wildcards read from
    # acme.json -- a restart re-reads them, it does not re-issue.
    startLimitIntervalSec = lib.mkForce 60;
    startLimitBurst = lib.mkForce 10;
  };

  services.pangolin = {
    enable = true;
    # Enterprise build (free for personal use; key from app.pangolin.net,
    # entered at /admin/license) — needed for HTTP private resources
    package = pkgs.fosrl-pangolin.override { edition = "enterprise"; };
    openFirewall = true;
    baseDomain = domain;
    dashboardDomain = "pangolin.${domain}";
    letsEncryptEmail = "victorbuch@protonmail.com";
    dnsProvider = "cloudflare";
    environmentFile = config.sops.templates."pangolin.env".path;
    settings = {
      domains = {
        domain1.prefer_wildcard_cert = true;
        domain2 = {
          base_domain = wannaShareDomain;
          prefer_wildcard_cert = true;
        };
      };
      # Integration API (port 3003) — used for API-key operations like
      # license activation; also silences traefik's int-api-service noise
      flags.enable_integration_api = true;
      # Turns on the Country match type in resource rules (geo-blocking) and
      # the location-aware analytics that share the same database. Store path
      # is readable under the unit's ProtectSystem=full.
      server.maxmind_db_path = "${geolite2Country}";
    };
  };

  services.traefik.environmentFiles = [ config.sops.templates."traefik-cf.env".path ];

  # DNS-01 propagation self-check must not use the box's recursive resolvers
  # (netcup/quad9 negative-cache _acme-challenge lookups); Cloudflare's own
  # resolver sees the zone update within seconds.
  services.traefik.staticConfigOptions.certificatesResolvers.letsencrypt.acme.dnsChallenge.resolvers =
    [
      "1.1.1.1:53"
      "1.0.0.1:53"
    ];

  # Resource targets are mal's Caddy over the encrypted WG tunnel, dialed
  # SNI-less — its wildcard cert can never match the dial address, so
  # upstream verification must be off (transport is already encrypted twice).
  services.traefik.staticConfigOptions.serversTransport.insecureSkipVerify = true;

  # Traefik logs nothing per-request by default; crowdsec's traefik parser needs
  # the access log. No filePath means stdout, which lands in the journal that
  # crowdsec already reads — no extra log file to keep readable.
  services.traefik.staticConfigOptions.accessLog.format = "json";

  # CrowdSec on the public edge: sshd bruteforce + HTTP scanning/CVE probing,
  # enforced in the kernel by the firewall bouncer (iptables+ipset — nftables
  # is off on this host). fail2ban above still covers sshd independently.
  services.crowdsec = {
    enable = true;
    autoUpdateService = true;

    settings = {
      # Standalone engine, so it runs its own LAPI (module defaults it off) and
      # registers itself against the community API for the blocklists.
      general.api.server.enable = true;
      lapi.credentialsFile = "/var/lib/crowdsec/local_api_credentials.yaml";
      capi.credentialsFile = "/var/lib/crowdsec/online_api_credentials.yaml";
    };

    hub.collections = [
      "crowdsecurity/linux" # includes sshd parsers + scenarios
      "crowdsecurity/traefik"
      "crowdsecurity/http-cve"
      "crowdsecurity/base-http-scenarios"
    ];

    localConfig.acquisitions = [
      {
        source = "journalctl";
        journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
        labels.type = "syslog";
      }
      {
        source = "journalctl";
        journalctl_filter = [ "_SYSTEMD_UNIT=traefik.service" ];
        labels.type = "traefik";
      }
    ];
  };

  # Upstream runs crowdsec under DynamicUser, and the bouncer's register unit
  # claims "crowdsec" in its StateDirectory — so systemd migrates /var/lib/crowdsec
  # into /var/lib/private/crowdsec and leaves a symlink behind, which the module's
  # own tmpfiles rules and every host-side cscli then choke on:
  #   Error: while setting up trace directory: mkdir /var/lib/crowdsec: file exists
  # A static user takes that mechanism out of play for all three units (systemd
  # refuses DynamicUser against a user that exists statically).
  users.groups.crowdsec = { };
  users.users.crowdsec = {
    isSystemUser = true;
    group = "crowdsec";
  };

  # The upstream unit is hardened past what a journalctl acquisition survives:
  # `path = mkForce []` leaves journalctl off PATH, and the journal files are
  # 0640 root:systemd-journal, which PrivateUsers keeps out of reach even with
  # the group. Both have to be undone for the acquisition to read anything.
  systemd.services.crowdsec = {
    environment.PATH = lib.mkForce "${config.systemd.package}/bin";
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      SupplementaryGroups = [ "systemd-journal" ];
      PrivateUsers = lib.mkForce false;
      # Otherwise one unreachable hub CDN at boot leaves the agent down for good.
      Restart = "on-failure";
    };
  };

  systemd.services.crowdsec-update-hub.serviceConfig.DynamicUser = lib.mkForce false;

  systemd.services.crowdsec-firewall-bouncer-register.serviceConfig.DynamicUser = lib.mkForce false;

  # The bouncer `requires` the register unit but is only ordered after crowdsec,
  # so on a cold boot it can hit LoadCredential before the API key file exists
  # and dies with 243/CREDENTIALS. Order it behind the unit that writes the key.
  systemd.services.crowdsec-firewall-bouncer.after = [ "crowdsec-firewall-bouncer-register.service" ];

  # The register unit shells out to the raw cscli, which reads
  # /etc/crowdsec/config.yaml — a path the module never populates, since its own
  # cscli wrapper passes `-c <store path>` instead. Publish the same generated
  # config there so every raw invocation (this unit, an interactive one) works.
  environment.etc."crowdsec/config.yaml".source =
    (pkgs.formats.yaml { }).generate "crowdsec.yaml"
      config.services.crowdsec.settings.general;

  # First-run bootstrap deadlock: the setup script runs `cscli machine add`
  # before `cscli capi register`, but naming capi.credentialsFile puts the path
  # in config.yaml straight away, so the machine add dies on the file that
  # register has not written yet. An empty placeholder satisfies the load, and
  # `capi register` fills it on the same run (its guard greps for a password).
  systemd.tmpfiles.settings."20-crowdsec-capi"."/var/lib/crowdsec/online_api_credentials.yaml".f = {
    user = "crowdsec";
    group = "crowdsec";
    mode = "0600";
  };

  # registerBouncer defaults to true whenever crowdsec is enabled, so the API
  # key is minted and handed over by a oneshot unit — nothing to put in sops.
  services.crowdsec-firewall-bouncer.enable = true;

  # Private HTTP resources are terminated by newt on mal's side of the tunnel,
  # so Pangolin has to ship it a keypair. It gets one by tailing Traefik's
  # acme.json (server/private/lib/acmeCertSync.ts polls `acme_json_path`,
  # relative to its WorkingDirectory) and pushing what it finds to every
  # ssl-enabled site resource.
  #
  # Upstream's tmpfiles rule creates Traefik's storage dir 0700 traefik:fossorial,
  # so the pangolin user cannot even traverse it — the sync warns once per tick,
  # no certificate row is populated, and newt dies on every private-resource TLS
  # handshake with "failed to parse TLS keypair: no PEM data".
  #
  # Loosening acme.json in place is off the table: chmod on an ACL'd file rewrites
  # the mask from the group bits, so mode and ACL fight each other, and anything
  # that perturbs the file Traefik owns risks the public edge. Mirror it instead —
  # Traefik keeps its untouched 0600 original, a root-run unit copies it somewhere
  # the fossorial group can read, and privateConfig.yml points the sync at the copy.
  #
  # Remove once nixpkgs makes Traefik's acme.json readable to the pangolin user.
  environment.etc."pangolin/privateConfig.yml".text = ''
    acme:
      acme_json_path: "config/letsencrypt-sync/acme.json"
  '';

  systemd.tmpfiles.settings."20-pangolin-acme-sync" = {
    "/var/lib/pangolin/config/letsencrypt-sync".d = {
      user = "root";
      group = "fossorial";
      mode = "0750";
    };
  };

  # PathChanged fires on close-after-write, so renewals propagate within seconds.
  systemd.paths.pangolin-acme-mirror = {
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathChanged = "/var/lib/pangolin/config/letsencrypt/acme.json";
      Unit = "pangolin-acme-mirror.service";
    };
  };

  systemd.services.pangolin-acme-mirror = {
    # Also runs at boot: the path unit only reacts to writes after it starts.
    wantedBy = [ "multi-user.target" ];
    after = [ "traefik.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "pangolin-acme-mirror" ''
        set -eu
        src=/var/lib/pangolin/config/letsencrypt/acme.json
        dst=/var/lib/pangolin/config/letsencrypt-sync/acme.json
        # Traefik creates acme.json empty before its first issuance; copying that
        # would hand the sync an empty resolver set.
        [ -s "$src" ] || exit 0
        ${pkgs.coreutils}/bin/install -m 0640 -o root -g fossorial "$src" "$dst"
      '';
    };
  };

  # The module's preStart only copies config.yml; privateConfig.yml is ours.
  #
  # The rest of this takes the .next lifecycle away from the package wrapper.
  # That wrapper refreshes the Next.js build out of the store on every start:
  #
  #   test -f .next/.nix_skip_setup || { rm -rf .next && cp -rd $out/share/pangolin/.next .; }
  #
  # `cp -rd` preserves the store's read-only mode, which breaks two things.
  #
  # First, the copy is undeletable, so the next `rm -rf` fails with EACCES and
  # .next stays pinned to whichever package first populated the dataDir.
  # Switching the package (oss -> enterprise, or any version bump) then leaves
  # dist/server.mjs running from the new store path while the dashboard is still
  # served by the old build: no /admin/license route, "Community Edition"
  # forever. (`public` and `node_modules` are symlinked, not copied, so they are
  # unaffected — .next is the only one that needs this.)
  #
  # Second, 0555 dirs mean Next.js's image optimizer cannot mkdir .next/cache,
  # so every image throws `unhandledRejection EACCES` and is re-optimized in
  # memory, never evicted to disk.
  #
  # A postStart chmod cannot fix the second one: the unit is Type=simple, so
  # postStart fires the moment systemd forks, while the wrapper's `cp -rd` is
  # still running — the chmod walks a tree that is then replaced underneath it
  # by read-only files. It also races on files that vanish mid-walk
  # ("cannot access .../page.js.nft.json") and exits 1, which would kill
  # preStart and take gerbil and traefik with it.
  #
  # So do the whole thing here instead, where nothing else is touching the tree,
  # and leave the marker behind so the wrapper skips its own copy. Copying
  # unconditionally from the *current* package path is what keeps the pinning
  # bug fixed — the marker must never mean "already set up", only "not your job".
  #
  # Remove once nixpkgs stops copying the store's mode bits into the dataDir.
  systemd.services.pangolin.preStart = lib.mkAfter ''
    cp -f /etc/pangolin/privateConfig.yml ${config.services.pangolin.dataDir}/config/privateConfig.yml

    if [ -d ${config.services.pangolin.dataDir}/.next ]; then
      chmod -R u+w ${config.services.pangolin.dataDir}/.next || true
    fi
    rm -rf ${config.services.pangolin.dataDir}/.next
    cp -rd ${config.services.pangolin.package}/share/pangolin/.next ${config.services.pangolin.dataDir}/.next
    chmod -R u+w ${config.services.pangolin.dataDir}/.next
    touch ${config.services.pangolin.dataDir}/.next/.nix_skip_setup
  '';

  # The Sunday auto-upgrade builds its own closure, and on 2026-08-30 05:09 a
  # 1.6G node process in that build triggered a *global* OOM on this 3.8G box:
  #
  #   task_memcg=/system.slice/nixos-upgrade.service, task=node, anon-rss:1630052kB
  #   nixos-upgrade.service: Failed with result 'oom-kill'
  #
  # The build genuinely runs inside this unit's cgroup (not nix-daemon's), so a
  # cap here contains it. MemoryHigh throttles and reclaims first so a build that
  # merely runs hot swaps instead of dying; MemoryMax is the hard stop that keeps
  # the kernel's global OOM killer from ever having to choose between the build
  # and the public edge. A capped build that fails just leaves the old
  # generation booted and retries next Sunday — cheap, compared to taking
  # pangolin down to finish an upgrade.
  systemd.services.nixos-upgrade.serviceConfig = {
    MemoryHigh = "1500M";
    MemoryMax = "2G";
  };

  environment.systemPackages = with pkgs; [
    neovim
    git
    jq
    sops
    # Inspecting what the crowdsec bouncer actually enforces: the ban sets live
    # in ipset, matched from CROWDSEC_CHAIN, not in the iptables rules themselves.
    ipset
  ];

  home-manager = {
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit
        username
        inputs
        pkgs-stable
        ;
    };
    users."${username}" = import ../../home/default.nix;
  };

  apps.cli = {
    enable = true;
    git.enable = true;
    # Personal notes vault; nothing on this host reads or writes it.
    notes.enable = false;
    fzf.enable = true;
    nushell.enable = true;
    zsh.enable = false;
    starship.enable = true;
    sesh.enable = false;
    jujutsu.enable = false;
    opencode.enable = false;
    peon-ping.enable = false;
    herdr.enable = false;
  };

  system.stateVersion = "25.11";
}
