{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  username = "ghost";
  hl = config.homelab;
  nixosIp = hl.nixosIp;
  uid = toString config.user.uid;
  # Main network interface - update this if interface name changes
  mainInterface = "ens18";
in
{
  imports = [
    ./hardware-configuration.nix
    # inputs.home-manager.nixosModules.default
  ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # Adjust according to your disk

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = "1048576"; # 128 times the default 8192
  };

  # Enable networking
  networking.networkmanager.enable = true;

  # Static IP configuration for main interface
  networking.interfaces.${mainInterface}.ipv4.addresses = [
    {
      address = nixosIp; # 192.168.0.243
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "192.168.0.1";
  networking.nameservers = [
    "127.0.0.1"
    "1.1.1.1"
  ];

  networking.hostName = "serenity"; # Define your hostname.

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Enable all maintenance features
  # (GC with 10-day retention, auto-upgrade with lockfile commits, store optimization, boot cleanup)
  maintenance.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_DK.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "da_DK.UTF-8";
    LC_IDENTIFICATION = "da_DK.UTF-8";
    LC_MEASUREMENT = "da_DK.UTF-8";
    LC_MONETARY = "da_DK.UTF-8";
    LC_NAME = "da_DK.UTF-8";
    LC_NUMERIC = "da_DK.UTF-8";
    LC_PAPER = "da_DK.UTF-8";
    LC_TELEPHONE = "da_DK.UTF-8";
    LC_TIME = "da_DK.UTF-8";
  };

  # Configure console keymap
  console.keyMap = "dk-latin1";

  # Enable zsh shell
  programs.zsh.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable binaries to work
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # add any missing dynamic libraries for unpackaged programs here
    libz
  ];

  # Define a user account.
  user.userName = username;

  # Enable automatic login for the user.
  services.getty.autologinUser = username;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # SSH protection
  services.fail2ban = {
    enable = true;
    bantime = "1h";
  };

  # Sops configuration
  sops = {
    defaultSopsFile = "${inputs.self}/secrets/secrets.yaml";
    defaultSopsFormat = "yaml";

    age.keyFile = "/home/${username}/.config/sops/age/keys.txt";

    templates."cloudflared-credentials" = {
      content = ''
        {"AccountTag":"${config.sops.placeholder."cloudflare/tunnel/account_tag"}","TunnelSecret":"${
          config.sops.placeholder."cloudflare/tunnel/tunnel_secret"
        }","TunnelID":"${config.sops.placeholder."cloudflare/tunnel/tunnel_id"}"}
      '';
      owner = "root";
      group = "root";
      mode = "0400";
    };
    secrets = {
      "vpn/pia/username" = {
        mode = "0444";
        owner = "root";
        group = "root";
      };
      "vpn/pia/password" = {
        mode = "0444";
        owner = "root";
        group = "root";
      };
      "cloudflare/tunnel/account_tag" = {
        mode = "0444";
        owner = "root";
        group = "root";
      };
      "cloudflare/tunnel/tunnel_secret" = {
        mode = "0444";
        owner = "root";
        group = "root";
      };
      "cloudflare/tunnel/tunnel_id" = {
        mode = "0444";
        owner = "root";
        group = "root";
      };
      # "authelia/jwt_secret" = {
      #   mode = "0400";
      #   owner = "authelia-main";
      #   group = "authelia-main";
      # };
      # "authelia/session_secret" = {
      #   mode = "0400";
      #   owner = "authelia-main";
      #   group = "authelia-main";
      # };
      # "authelia/storage_encryption_key" = {
      #   mode = "0400";
      #   owner = "authelia-main";
      #   group = "authelia-main";
      # };
      # "authelia/admin_password_hash" = {
      #   mode = "0400";
      #   owner = "authelia-main";
      #   group = "authelia-main";
      # };
      "sonarr_api_key" = {
        mode = "0444";
        owner = "root";
        group = "root";
      };
      "radarr_api_key" = {
        mode = "0444";
        owner = "root";
        group = "root";
      };
      "nextcloud/admin_password" = {
        mode = "0400";
        owner = "nextcloud";
        group = "nextcloud";
      };
      "nextcloud/db_password" = {
        mode = "0400";
        owner = "nextcloud";
        group = "nextcloud";
      };
      "mam/session_cookie" = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
      "immich/db_password" = {
        mode = "0444";
        owner = "root";
        group = "root";
      };
      "mealie/db_password" = {
        mode = "0400";
        owner = "mealie";
        group = "mealie";
      };
      "tinyauth/secret" = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
      "tinyauth/users" = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
      "tailscale/auth_key" = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
    };
  };

  # better memory management
  zramSwap.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    2283
  ];
  networking.firewall.allowedUDPPorts = [
    2283
  ];

  # Server Settings
  # Enable OpenGL
  hardware.graphics = {
    enable = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # enable docker
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # Virtualization containers
  virtualisation.oci-containers.backend = "docker";

  users.users."${username}".extraGroups = [ "docker" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    docker-compose
    neovim
    fzf
    lazygit
    git
    nh
    zoxide
    sops

    claude-code
    mcp-nixos
    nodePackages_latest.nodejs
  ];

  programs.neovim.defaultEditor = true;

  # Networking and Auth
  tailscale = {
    enable = true;
    advertiseExitNode = true;
    useRoutingFeatures = "both"; # Act as both client and server
    enableSsh = true; # Allow SSH via Tailscale
    extraUpFlags = [
      "--advertise-routes=192.168.0.0/24" # Share your local network
    ];
  };
  cloudflare-tunnel.enable = true;
  caddy.enable = true;
  nginx-reverse-proxy.enable = false;
  tinyauth = {
    enable = true;
    port = 3002;
  };
  authelia.enable = false;
  adguard.enable = true;
  pocket-id.enable = true;

  # Smart home
  hyperhdr.enable = true;
  music-assistant.enable = true;

  # Monitor and Dashboards
  dashboard = {
    homarr.enable = false;
    glance.enable = true;
  };
  uptime-kuma.enable = true;
  wallos.enable = true;

  # Media
  streaming.enable = true;
  immich.enable = true;
  deluge-vpn.enable = true;
  filebrowser.enable = true;
  nextcloud.enable = true;

  # Utils
  mam-dynamic-seedbox.enable = true;
  it-tools.enable = true;

  # Other
  crafty.enable = true;
  mealie.enable = true;
  lab.enable = false;

  # Development
  gitea.enable = true;

  system.stateVersion = "24.05"; # Did you read the comment?

}
