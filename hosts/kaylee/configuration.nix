{
  config,
  pkgs,
  inputs,
  ...
}:
let
  username = "kaylee";
in
{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # Define a user account.
  user.userName = username;

  #services.getty.autologinUser = username;

  # enable modules
  ############### System configs ########################
  nvidia.enable = true;
  # amd-gpu.enable = true;
  maintenance.enable = true;
  #######################################################

  ############### Apps ########################
  apps = {
    browsers.zen.enable = true;
    audio.enable = true;
    communication.enable = true;
    gaming.enable = false;
    development.enable = true;
    utilities.enable = true;
  };
  #############################################

  ############### Desktop/ WM ########################
  desktop-environments = {
    gnome.enable = false;
    hyprland.enable = true;
    kde.enable = false;
  };
  ###################################################

  # Pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };
  services.pulseaudio.enable = false;

  networking.hostName = "${username}"; # Define your hostname.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

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

  # Force Electron apps to use Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Configure console keymap
  console.keyMap = "dk-latin1";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [ ];

  # Enable Home Manager
  home-manager = {
    # also pass inputs to home-manager modules
    extraSpecialArgs = {
      inherit username;
      inherit inputs;
      inherit isLinux;
    };
    users = {
      "${username}" = import ../../home/default.nix;
    };
    backupFileExtension = "backup";
  };

  system.stateVersion = "24.05"; # Did you read the comment?

}
