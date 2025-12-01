{
  config,
  pkgs,
  inputs,
  isLinux,
  mkHomeModule,
  mkHomeCategory,
  ...
}:
let
  username = "jayne";
in
{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
  ];
  boot = {

    # Bootloader.
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiSupport = true;
        useOSProber = true;
      };
    };

    # Enable NTFS support for mounting Windows drives
    supportedFilesystems = [ "ntfs" ];

    # Kernel performance optimizations
    kernel.sysctl = {
      # SSD I/O scheduler optimizations
      "vm.swappiness" = 10; # Reduce swap usage (we have 64GB RAM)
      "vm.vfs_cache_pressure" = 50; # Keep directory/inode cache
      "vm.dirty_ratio" = 10; # Start writing dirty pages earlier
      "vm.dirty_background_ratio" = 5; # Background write threshold
    };
  };

  # Define a user account.
  user.userName = username;

  # Enable Home Manager
  home-manager = {
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit
        username
        inputs
        isLinux
        mkHomeModule
        mkHomeCategory
        ;
    };
    users = {
      "${username}" = import ../../home/default.nix;
    };

    # Per-host Home Manager configuration
    sharedModules = [
      inputs.noctalia.homeModules.default
      {
        home = {
          audio = {
            yabridge.enable = true;
          };
          catppuccin.enable = true;
          desktop-environments = {
            niri.enable = true;
            noctalia.enable = true;
          };
          cli = {
            enable = true;
            neovim = {
              nixvim.enable = true;
              nvf.enable = false;
            };
          };
          terminals = {
            enable = true;
          };
        };
      }
    ];
  };

  # better memory management
  zramSwap.enable = true;

  # enable modules
  ############### System configs ########################
  amd-gpu.enable = true;
  maintenance = {
    enable = true;
    linux.enable = true;
  };
  #######################################################

  ############### Apps ########################

  catppuccin.enable = true;
  apps = {
    audio = {
      enable = true;
    };

    browsers = {
      enable = true;
      floorp.enable = false; # Disable specific browser
    };

    communication = {
      enable = true;
    };

    development = {
      enable = true;
    };

    emacs = {
      enable = false;
    };

    emulation = {
      enable = false;
    };

    gaming = {
      enable = true;
    };

    media = {
      enable = true;
      davinci-resolve.enable = false;
    };

    productivity = {
      enable = true;
    };

    utilities = {
      enable = true;
    };

  };
  #############################################

  ############### Desktop/ WM ########################
  desktop-environments = {
    gnome.enable = false;
    hyprland.enable = false;
    kde.enable = false; # Disabled to prevent conflict with Hyprland
    niri.enable = true;
  };
  networking = {

    ###################################################

    hostName = "jayne"; # Define your hostname.
    # Enable networking
    networkmanager.enable = true;

    wireless.enable = false;
  };

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth

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

  # Force Electron apps to use Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Configure console keymap
  console.keyMap = "dk-latin1";

  services = {
    printing.enable = true;
    power-profiles-daemon.enable = true;
    upower.enable = true;
  };

  programs = {

    # Enable touchpad support (enabled default in most desktopManager).
    # services.xserver.libinput.enable = true;

    zsh.enable = true;

    # Enable binaries to work
    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      # add any missing dynamic libraries for unpackaged programs here
      libz
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [ ];

  system.stateVersion = "25.05"; # Did you read the comment?

}
