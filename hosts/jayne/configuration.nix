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
  ];

  networking = {
    hostName = "jayne";
    networkmanager.enable = true;
    resolvconf.extraOptions = [
      "timeout:1"
      "attempts:2"
    ];
    networkmanager.plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };

  user.userName = username;

  time.timeZone = "Europe/Copenhagen";
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

  console.keyMap = "dk-latin1";

  environment = {

    # Force Electron apps to use Wayland
    sessionVariables.NIXOS_OZONE_WL = "1";

    systemPackages = with pkgs; [
      networkmanager-openvpn
      openvpn
      inputs.edit360.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # U2F key mappings -- deployed to /etc/u2f-mappings
    # Generated with: pamu2fcfg -o pam://serenityOs -i pam://serenityOs
    etc."u2f-mappings".text = ''
      jayne:nOoddQutVofHylA4WNRaidjr+w1mzhNglmLqCOFxh/y0G4KU4691+8AWOmofdOcrdY2a62vljX5aj3Gdn9HmAg==,4neONWeZ0hThNvKlidWWEle3+cUHglUOSlcn5VTcXeO0lPQLXtsyOpq31L4ZLGeRiJVAoQji+/p/RJKumPWzFg==,es256,+presence
    '';
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  zramSwap.enable = true;

  security.rtkit.enable = true;

  services = {
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    printing.enable = true;
    power-profiles-daemon.enable = true;
    upower.enable = true;

    # VPN: Tailscale (mesh) + NetworkManager OpenVPN plugin (for PIA .ovpn imports)
    tailscale = {
      enable = false;
      useRoutingFeatures = "client";
      extraUpFlags = [ "--operator=${username}" ];
    };
  };
  systemd.services.nscd.environment.NSNCD_WORKER_COUNT = "64";

  programs = {

    zsh.enable = true;

    # Binary compatibility for unpackaged programs
    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [ libz ];
  };

  # Flake HM modules that define options our modules use. noctalia is not
  # here: home-manager ships its own programs.noctalia module, and importing
  # the flake's as well makes the option collide.
  home-manager.sharedModules = [ inputs.zen-browser.homeModules.default ];

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
    plymouth = {
      enable = true;
      theme = "rings";
      themePackages = [ (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "rings" ]; }) ];
    };
    consoleLogLevel = 3;
    kernelParams = [
      "quiet"
      "splash"
      "udev.log_level=3"
      "systemd.show_status=auto"
    ];
    # Enable NTFS support for mounting Windows drives
    supportedFilesystems = [ "ntfs" ];
    # Kernel performance optimizations
    kernel.sysctl = {
      # mkForce because musnix (audio-performance) also defines this key -- with
      # the same value, but boot.kernel.sysctl entries must be uniquely defined, so equal
      # values still collide.
      "vm.swappiness" = lib.mkForce 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 10;
      "vm.dirty_background_ratio" = 5;
    };
  };

  # Desktop environments
  desktop = {
    compositor = {
      mango.enable = false;
      hyprland.enable = false;
      niri.enable = true;
    };
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
      autostartApps = [
        "zen"
        "ghostty"
      ];
    };
    environment.gnome.enable = false;
    environment.kde.enable = false;
  };

  apps.audio.reaper.wineTrack = "modern";

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
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
