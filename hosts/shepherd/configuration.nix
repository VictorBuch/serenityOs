{
  config,
  pkgs,
  inputs,
  pkgs-stable,
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
  boot.loader.efi.efiSysMountPoint = "/boot";

  networking.hostName = "shepherd"; # Define your hostname.

  # Define a user account.
  user.userName = username;

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
      inherit
        username
        inputs
        pkgs-stable
        ;
    };
    users = {
      "${username}" = import ../../home/default.nix;
    };

    sharedModules = [
      inputs.noctalia.homeModules.default
      inputs.zen-browser.homeModules.default
    ];
  };

  # Enable zsh shell
  programs.zsh.enable = true;

  # Enables GC, boot-cleanup, and optimization (Linux-specific options auto-enabled)
  maintenance.enable = true;
  ############### Apps ########################

  apps = {
    # CLI and neovim (unified)
    cli.enable = true;
    neovim.nixvim.enable = true;
    theming.stylix.enable = true;
    audio = {
      enable = false;
    };

    browsers = {
      enable = true;
      floorp.enable = false;
      zen.enable = true;
    };

    communication = {
      enable = false;
    };

    development = {
      enable = false;
      neovim.enable = true;
      ghostty.enable = true;
      common.enable = true;
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
      ripgrep
      fd
    ];
    shell = pkgs.nushell;
  };

  # Enable graphics/OpenGL (required for Wayland compositors like niri)
  hardware.graphics.enable = true;

  # Enable X server and video drivers (required even for Wayland)
  services.xserver = {
    enable = true;
    videoDrivers = [ "modesetting" ]; # Generic driver for VMs
  };

  system.stateVersion = "25.05";

}
