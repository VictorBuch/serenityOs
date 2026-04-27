{
  config,
  pkgs,
  inputs,
  lib,
  pkgs-stable,
  ...
}:
let
  username = "serenity";
  hl = config.homelab;
  nixosIp = hl.nixosIp;
  uid = toString config.user.uid;
  # Main network interface - update this if interface name changes
  mainInterface = "enp6s0";
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    # Bootloader (UEFI with systemd-boot)
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576"; # 128 times the default 8192
    };
  };

  networking = {
    # Enable networking
    networkmanager.enable = true;

    # Static IP configuration for main interface
    interfaces.${mainInterface}.ipv4.addresses = [
      {
        address = nixosIp; # 192.168.0.243
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.0.1";
    nameservers = [
      "127.0.0.1"
      "1.1.1.1"
    ];

    hostName = "mal";

    # Open ports in the firewall.
    firewall = {
      allowedTCPPorts = [
        2283
      ];
      allowedUDPPorts = [
        2283
      ];
      trustedInterfaces = [ "docker0" ];
    };
  }; # Define your hostname.

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
  programs = {
    # Enable zsh shell
    zsh.enable = true;

    # Enable binaries to work
    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      # add any missing dynamic libraries for unpackaged programs here
      libz
    ];

    neovim.defaultEditor = true;
  };

  # Define a user account.
  user.userName = username;

  services = {
    # Enable automatic login for the user.
    getty.autologinUser = username;

    # Enable the OpenSSH daemon.
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

    # SSH protection
    fail2ban = {
      enable = true;
      bantime = "8h";
    };

    # Load nvidia driver for Xorg and Wayland
    xserver.videoDrivers = [ "nvidia" ];
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
      "rreading-glasses/postgres-password" = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
      "immich/db_password" = {
        mode = "0444";
        owner = "root";
        group = "root";
      };
      "immich_api_key" = {
        mode = "0444";
        owner = "root";
        group = "root";
      };
      "mealie/db_password" = {
        mode = "0400";
        owner = "mealie";
        group = "mealie";
      };
      "tinyauth/users" = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
      "gitea/runner_token" = {
        mode = "0444";
        owner = "root";
        group = "root";
      };
      "tailscale/auth_key" = {
        mode = "0400";
        owner = "root";
        group = "root";
      };
      "paperless/db_password" = {
        mode = "0400";
      };
      "paperless/admin_password" = {
        mode = "0400";
      };
      "paperless/secret_key" = {
        mode = "0400";
      };
    };
  };

  # better memory management
  zramSwap.enable = true;

  # Server Settings - NVIDIA GPU Support for Jellyfin Transcoding
  # Enable OpenGL and 32-bit support
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Add 32-bit support for better compatibility
  };

  hardware.nvidia = {
    # Modesetting is required
    modesetting.enable = true;

    # Use proprietary drivers (better performance for transcoding)
    open = false;

    # GTX 960 (Maxwell) requires legacy_580 - dropped from stable (595+)
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

    # Power management - keep GPU always on for server use
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # CRITICAL: Enable persistence daemon for headless transcoding
    # This keeps the GPU initialized even without a display
    nvidiaPersistenced = true;

    # Enable nvidia-settings tool (optional but useful for debugging)
    nvidiaSettings = true;
  };

  # Fix nvidia-persistenced race condition during nixos-rebuild switch
  # Device files may briefly disappear when kernel modules reload
  systemd.services.nvidia-persistenced.serviceConfig.RestartSec = 5;

  # CDI generator must wait for nvidia-persistenced to have the driver loaded
  systemd.services.nvidia-container-toolkit-cdi-generator = {
    after = [ "nvidia-persistenced.service" ];
    requires = [ "nvidia-persistenced.service" ];
  };

  # Enable NVIDIA Container Toolkit for GPU passthrough to Docker containers (NVENC)
  hardware.nvidia-container-toolkit.enable = true;

  virtualisation = {
    docker.enable = true;
    docker.daemon.settings = {
      features = {
        cdi = true;
      };
    };
    docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
    oci-containers.backend = "docker";
  };

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    host = "0.0.0.0";
    loadModels = [ "gemma3:4b" ];
  };

  # FIDO2 SSH authorized keys -- one per YubiKey
  users.users."${username}" = {
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINIkyb8ktnpdCcN3S2k6gkSGqtoMeAATgUaF3mET/FP7AAAABHNzaDo= jayne@yubikey-5c-nano"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJvUM1QnLCbxff2rLeHmJ/uwOPwSYpxoxoh644OaMK6CAAAABHNzaDo= inara@yubikey-5c-nano"
    ];
  };

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
    jq

    claude-code
    opencode
    # mcp-nixos
    nodejs

    # NVIDIA VAAPI driver for hardware acceleration
    nvidia-vaapi-driver
  ];

  # Enable Home Manager for CLI tools
  home-manager = {
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit
        username
        inputs
        pkgs-stable
        ;
    };
    users = {
      "${username}" = import ../../home/default.nix;
    };
    sharedModules = [ ];
  };

  # Server: enable tmux
  apps.development.tmux.enable = true;

  # Server CLI tools (selective enables)
  apps.cli = {
    enable = true;
    git.enable = true;
    fzf.enable = true;
    nushell.enable = true;
    zsh.enable = false;
    starship.enable = true;
    sesh.enable = true;
    jujutsu.enable = false;
    opencode.enable = false;
    peon-ping.enable = false;
  };

  # Networking and Auth
  homelab.tailscale = {
    enable = true;
    advertiseExitNode = true;
    useRoutingFeatures = "both"; # Act as both client and server
    enableSsh = true; # Allow SSH via Tailscale
    extraUpFlags = [
      "--advertise-routes=192.168.0.0/24" # Share your local network
    ];
  };
  homelab.cloudflare-tunnel.enable = true;
  homelab.caddy.enable = true;
  homelab.nginx-reverse-proxy.enable = false;
  homelab.tinyauth = {
    enable = true;
    port = 3002;
  };
  homelab.authelia.enable = false;
  homelab.adguard.enable = true;
  homelab.pocket-id = {
    enable = true;
  };

  # Smart home
  homelab.hyperhdr.enable = true;
  homelab.music-assistant.enable = true;
  homelab.home-assistant.enable = true;

  # Monitor and Dashboards
  homelab.dashboard = {
    homarr.enable = false;
    glance.enable = true;
  };
  homelab.uptime-kuma.enable = true;
  homelab.wallos.enable = true;

  # Media
  homelab.fileflows.enable = true;
  homelab.streaming.enable = true;
  homelab.rreading-glasses.enable = true;
  homelab.immich.enable = true;
  homelab.deluge-vpn.enable = true;
  homelab.filebrowser.enable = true;
  homelab.nextcloud.enable = true;

  # Utils
  homelab.mam-dynamic-seedbox.enable = true;
  homelab.it-tools.enable = true;
  homelab.ntfy-sh.enable = true;

  # Other
  homelab.crafty.enable = true;
  homelab.mealie.enable = true;
  homelab.lab.enable = false;
  homelab.lute.enable = true;

  # Development
  homelab.gitea.enable = true;

  # Document Management
  homelab.paperless.enable = true;
  homelab.reactive-resume.enable = true;
  homelab.invoice-ninja.enable = true;

  # Sharing
  homelab.wannashare.enable = true;

  system.stateVersion = "25.05"; # Did you read the comment?

}
