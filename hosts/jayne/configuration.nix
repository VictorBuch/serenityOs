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

  networking.hostName = "jayne";

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

  # Force Electron apps to use Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  zramSwap.enable = true;

  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.printing.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  networking.networkmanager.enable = true;

  programs.zsh.enable = true;

  # Binary compatibility for unpackaged programs
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [ libz ];

  maintenance.enable = true;

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
    initrd.verbose = false;
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
    inputs.edit360.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Desktop environments
  desktop = {
    compositor.mango.enable = false;
    compositor.hyprland.enable = false;
    compositor.niri.enable = true;
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

  apps = {
    audio = {
      audacity.enable = true;
      decent-sampler.enable = true;
      easyeffects.enable = true;
      feedback.enable = true;
      mass.enable = true;
      reaper.enable = true;
      reaper.wineTrack = "modern";
      sone.enable = true;
      spotify.enable = true;
      vlc.enable = true;
      yabridge.enable = true;
    };

    browsers.zen.enable = true;

    cli = {
      fzf.enable = true;
      git.enable = true;
      herdr.enable = true;
      jujutsu.enable = true;
      notes.enable = true;
      nushell.enable = true;
      opencode.enable = true;
      sesh.enable = true;
      starship.enable = true;
      zsh.enable = true;
    };

    communication = {
      discord.enable = true;
      slack.enable = true;
    };

    development = {
      agent-browser.enable = true;
      android-studio.enable = true;
      common.enable = true;
      devenv-init.enable = true;
      docker.enable = true;
      ghostty.enable = true;
      kitty.enable = true;
      neovim.enable = true;
      tmux.enable = true;
      vscode.enable = true;
      zed.enable = true;
    };

    emulation = {
      bottles.enable = true;
      qemu.enable = true;
    };

    gaming = {
      gamemode.enable = true;
      heroic.enable = true;
      minecraft.enable = true;
      ps2.enable = true;
      ps3.enable = true;
      ps4.enable = true;
      steam.enable = true;
      sunshine.enable = true;
      wine.enable = true;
    };

    hardware.logitech.enable = true;

    media = {
      blender.enable = true;
      davinci-resolve.enable = true;
      ffmpeg.enable = true;
      handbrake.enable = true;
    };

    neovim.lazyvim.enable = true;

    productivity = {
      calibre.enable = true;
      figma.enable = true;
      language-learning.enable = true;
      obsidian.enable = true;
    };

    theming.stylix.enable = true;

    utilities = {
      cli-tools.enable = true;
      handy.enable = true;
      localsend.enable = true;
      syncthing.enable = true;
      system-tools.enable = true;
      web-apps.enable = true;
    };
  };

  # YubiKey: PAM U2F sudo + screen lock on removal
  yubikey-security.enable = true;

  # U2F key mappings -- deployed to /etc/u2f-mappings
  # Generated with: pamu2fcfg -o pam://serenityOs -i pam://serenityOs
  environment.etc."u2f-mappings".text = ''
    jayne:nOoddQutVofHylA4WNRaidjr+w1mzhNglmLqCOFxh/y0G4KU4691+8AWOmofdOcrdY2a62vljX5aj3Gdn9HmAg==,4neONWeZ0hThNvKlidWWEle3+cUHglUOSlcn5VTcXeO0lPQLXtsyOpq31L4ZLGeRiJVAoQji+/p/RJKumPWzFg==,es256,+presence
  '';

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
