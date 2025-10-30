{
  config,
  pkgs,
  lib,
  modulesPath,
  inputs,
  isLinux,
  mkHomeModule,
  mkHomeCategory,
  ...
}:
{
  imports = [
    # Import the minimal installation CD module
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")

    # Import shepherd configuration for all custom settings
    ./configuration.nix
  ];

  # ISO-specific configuration
  isoImage = {
    # Faster compression for quicker builds (optional: use "xz" for smaller size)
    squashfsCompression = "zstd -Xcompression-level 6";

    # ISO name
    isoName = lib.mkForce "nixos-shepherd-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";

    # Make the installer automatically log in as nixos user
    makeEfiBootable = true;
    makeUsbBootable = true;
  };

  # Add helpful packages for installation and testing
  environment.systemPackages = with pkgs; [
    # Partitioning and disk management (already included in minimal, but explicit)
    gparted
    parted

    # Text editors
    neovim
    vim

    # Version control
    git
    lazygit

    # Network tools
    wget
    curl

    # System utilities
    htop
    tree

    # Installation helpers
    nushell
    zoxide
  ];

  # Enable SSH for remote installation (optional)
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Networking configuration for ISO
  networking.wireless.enable = lib.mkForce false; # Disable wpa_supplicant on ISO
  networking.networkmanager.enable = lib.mkForce true; # Ensure NetworkManager is available

  # Set a default password for the nixos user on the ISO (change after installation!)
  users.users.nixos.password = "nixos";
  users.users.root.password = "nixos";

  # Enable automatic login to the nixos user
  services.getty.autologinUser = lib.mkForce "nixos";

  # Override hardware-configuration to not import the specific hardware config
  # (it will be generated during installation)
  disabledModules = [ ./hardware-configuration.nix ];
}
