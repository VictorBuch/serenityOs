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
    loader.efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "wash";
    useDHCP = true;
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

    # lego (via traefik) reads CF_DNS_API_TOKEN for DNS-01 wildcard certs
    templates."traefik-cf.env" = {
      content = ''
        CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare/api_token"}
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
  };

  system.stateVersion = "25.11";
}
