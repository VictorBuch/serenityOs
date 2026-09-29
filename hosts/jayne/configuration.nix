# Jayne - Primary desktop workstation (AMD GPU)
# Full workstation with audio production, video editing, gaming, etc.
{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}:
let
  username = "jayne";
in
{
  imports = [
    ./hardware-configuration.nix
    ../profiles/desktop.nix
    ../profiles/desktop-home.nix
  ];

  networking.hostName = "jayne";

  user.userName = username;

  # Jayne-specific boot configuration
  boot = {
    loader = {
      # Wait for a manual selection instead of auto-booting after a countdown.
      # Set to a number (e.g. 5) if you'd rather it auto-boot the default entry
      # after N seconds.
      timeout = null;

      efi.canTouchEfiVariables = true;

      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiSupport = true;

        # Graphical selection menu (Catppuccin theme, matches the Tokyo Night
        # dark palette used elsewhere).
        theme = pkgs.catppuccin-grub;
        gfxmodeEfi = "auto";

        # Dual-boot: chainload the Windows Boot Manager living on the Windows
        extraEntries = ''
          menuentry "Windows 11" --class windows --class os {
            insmod part_gpt
            insmod fat
            insmod chain
            search --no-floppy --fs-uuid --set=root 79DF-17C2
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }
        '';
      };
    };
    # Enable NTFS support for mounting Windows drives
    supportedFilesystems = [ "ntfs" ];
    # Kernel performance optimizations
    kernel.sysctl = {
      # mkForce because musnix (audio-performance.enable) also defines this key -- with
      # the same value, but boot.kernel.sysctl entries must be uniquely defined, so equal
      # values still collide.
      "vm.swappiness" = lib.mkForce 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 10;
      "vm.dirty_background_ratio" = 5;
    };
  };

  # AMD GPU
  amd-gpu.enable = true;

  # Realtime audio tuning for REAPER (musnix on the stock kernel).
  # Note: this also switches the CPU governor to "performance" system-wide.
  audio-performance.enable = true;

  # VPN: Tailscale (mesh) + NetworkManager OpenVPN plugin (for PIA .ovpn imports)
  services.tailscale = {
    enable = false;
    useRoutingFeatures = "client";
    extraUpFlags = [ "--operator=${username}" ];
  };

  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
  ];

  environment.systemPackages = with pkgs; [
    networkmanager-openvpn
    openvpn
  ];

  # Desktop environments
  desktop = {
    compositor.mango.enable = true;
    session = {
      makeDefault = false;
      outputs = [
        {
          name = "DP-2";
          width = 2560;
          height = 1440;
          refresh = 143.912;
        }
        {
          name = "Virtual-1";
          width = 2560;
          height = 1600;
          refresh = 60;
          scale = 1.1;
        }
      ];
      autostart = [ [ "skwd-daemon" ] ];
      autostartApps = [
        "zen"
        "ghostty"
        "figma"
      ];
    };
    environment.gnome.enable = false;
    environment.kde.enable = true;
  };

  # Apps - full workstation
  apps = {

    audio = {
      enable = true;

      feedback.enable = true;

      reaper.wineTrack = "modern";
    };

    browsers = {
      enable = true;
    };

    communication = {
      enable = true;
    };

    development = {
      enable = true;
    };

    emacs.enable = false;

    emulation = {
      enable = true;
      podman.enable = false;
    };

    gaming = {
      enable = true;
    };

    hardware.logitech.enable = true;

    media = {
      enable = true;
    };

    productivity = {
      enable = true;
      logseq.enable = false;
    };

    utilities.enable = true;

    neovim = {
      lazyvim.enable = true;
      nixvim.enable = false;
    };

    # Wallpaper picker. noctalia still draws the wallpaper and derives the
    # palette from it; skwd just chooses which one.
    theming.skwd-wall.enable = true;
  };

  # YubiKey: PAM U2F sudo + screen lock on removal
  yubikey-security.enable = true;

  # U2F key mappings -- deployed to /etc/u2f-mappings
  # Generated with: pamu2fcfg -o pam://serenityOs -i pam://serenityOs
  environment.etc."u2f-mappings".text = ''
    jayne:nOoddQutVofHylA4WNRaidjr+w1mzhNglmLqCOFxh/y0G4KU4691+8AWOmofdOcrdY2a62vljX5aj3Gdn9HmAg==,4neONWeZ0hThNvKlidWWEle3+cUHglUOSlcn5VTcXeO0lPQLXtsyOpq31L4ZLGeRiJVAoQji+/p/RJKumPWzFg==,es256,+presence
  '';

  sops = {
    defaultSopsFile = "${inputs.self}/secrets/secrets.yaml";
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/jayne/.config/sops/age/keys.txt";
    secrets.github-token = { };
    templates."nix-access-tokens" = {
      content = "access-tokens = github.com=${config.sops.placeholder.github-token}";
      owner = username;
      mode = "0400";
    };
  };

  nix.extraOptions = "!include ${config.sops.templates."nix-access-tokens".path}";

  nix.settings.trusted-users = [
    "root"
    "jayne"
  ];

  system.stateVersion = "25.05";
}
