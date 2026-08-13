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
