# wash — Netcup VPS running Pangolin (tunneled reverse proxy + auth for the homelab).
# Public entrypoint for *.victorbuch.com and *.smoothless.org; tunnels to mal via newt.
{
  config,
  pkgs,
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
    # 80/443 TCP + 51820 UDP are opened by services.pangolin.openFirewall
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
