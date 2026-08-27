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

  # GC, auto-upgrade, store optimization, boot cleanup
  maintenance.enable = true;

  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_DK.UTF-8";

  zramSwap.enable = true;

  # No desktop, no yubikey tooling on the VPS
  yubikey.enable = false;

  user.userName = username;

  # Key-only SSH box with no console password — wheel must sudo without one
  security.sudo.wheelNeedsPassword = false;

  # Traefik downloads the badger plugin and reaches LE at startup; without
  # this it races DHCP/DNS on boot and comes up degraded (plugins disabled,
  # ACME stuck on [::1]:53)
  systemd.services.traefik = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };

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

  # Operational note — the module wires gerbil `requires` pangolin and traefik
  # `requires`/`partOf` gerbil. systemd propagates stop down that chain but
  # never propagates start back up, so `systemctl stop pangolin` takes the
  # whole edge offline (traefik drops 80/443, every tunnelled host refuses
  # connections) and `systemctl start pangolin` does NOT bring it back.
  # Use `restart`, or start the chain: `systemctl start pangolin gerbil traefik`.
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
  # The chmod keeps the frontend and the backend on the same edition. The
  # package's ExecStart wrapper refreshes the Next.js build out of the store
  # with `test -f .next/.nix_skip_setup || { rm -rf .next && cp -rd $out/.next . }`,
  # and `cp -rd` preserves the store's read-only mode — so the copy it just
  # made is undeletable, every later `rm -rf` fails with EACCES, and .next is
  # pinned to whichever package first populated the dataDir. Switching the
  # package (oss -> enterprise, or any version bump) then leaves dist/server.mjs
  # running from the new store path while the dashboard is still served by the
  # old build: no /admin/license route, "Community Edition" forever.
  #
  # Remove once nixpkgs stops copying the store's mode bits into the dataDir.
  systemd.services.pangolin.preStart = lib.mkAfter ''
    cp -f /etc/pangolin/privateConfig.yml ${config.services.pangolin.dataDir}/config/privateConfig.yml
    if [ -d ${config.services.pangolin.dataDir}/.next ]; then
      chmod -R u+w ${config.services.pangolin.dataDir}/.next
    fi
  '';

  # Same read-only mode, second victim: the copy the wrapper makes on *this*
  # start is read-only too, and Next.js's image optimizer writes .next/cache at
  # runtime — without this it throws unhandledRejection EACCES on every image.
  # preStart cannot cover it: the copy happens after it, inside ExecStart.
  systemd.services.pangolin.postStart = ''
    chmod -R u+w ${config.services.pangolin.dataDir}/.next
  '';

  environment.systemPackages = with pkgs; [
    neovim
    git
    jq
    sops
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
