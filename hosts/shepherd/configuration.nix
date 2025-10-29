{
  config,
  pkgs,
  inputs,
  isLinux,
  ...
}:
let
  username = "shepherd";
in
{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  networking.hostName = "shepherd"; # Define your hostname.

  # Define a user account.
  user.userName = username;

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Enable networking
  networking.networkmanager.enable = true;

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

  # Enable Home Manager
  home-manager = {
    # also pass inputs to home-manager modules
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit username inputs isLinux;
    };
    users = {
      "${username}" = import ../../home/default.nix;
    };
  };

  # Enable zsh shell
  programs.zsh.enable = true;

  ############### Apps ########################

  apps = {
    audio = {
      enable = false;
    };

    browsers = {
      enable = true;
      floorp.enable = false; # Disable specific browser
    };

    communication = {
      enable = false;
    };

    development = {
      enable = false;
      editors.neovim.enable = true;
      terminals.ghostty.enable = true;
      tools.enable = true;
    };

    emacs = {
      enable = false;
    };

    emulation = {
      enable = false;
    };

    gaming = {
      enable = false;
    };

    media = {
      enable = false;
    };

    productivity = {
      enable = false;
    };

    utilities = {
      enable = false;
    };

  };
  #############################################

  ############### Desktop/ WM ########################
  desktop-environments = {
    gnome.enable = false;
    hyprland.enable = false;
    kde.enable = false;
    niri.enable = true;
  };
  ###################################################

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nixos = {
    isNormalUser = true;
    description = "default";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      neovim
      nushell
      git
      lazygit
      zoxide
    ];
    shell = pkgs.nushell;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.05";

}
