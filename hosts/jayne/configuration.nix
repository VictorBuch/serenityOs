# Jayne - Primary desktop workstation (AMD GPU)
# Full workstation with audio production, video editing, gaming, etc.
{
  inputs,
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
    inputs.home-manager.nixosModules.default
  ];

  networking.hostName = "jayne";

  user.userName = username;

  # Home Manager setup
  home-manager = {
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit
        username
        inputs
        pkgs-stable
        ;
    };
    users.${username} = import ../../home/default.nix;

    sharedModules = [ ];
  };

  # Jayne-specific boot configuration
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiSupport = true;
      };
    };
    # Enable NTFS support for mounting Windows drives
    supportedFilesystems = [ "ntfs" ];
    # Kernel performance optimizations
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 10;
      "vm.dirty_background_ratio" = 5;
    };
  };

  # AMD GPU
  amd-gpu.enable = true;

  # VPN: Tailscale (mesh) + NetworkManager OpenVPN plugin (for PIA .ovpn imports)
  services.tailscale = {
    enable = true;
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
  desktop-environments = {
    gnome.enable = true;
    kde.enable = false;
    hyprland.enable = false;
    niri.enable = false;
    mango.enable = true;
  };

  # Apps - full workstation
  apps = {
    audio = {
      enable = true;
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
      enable = false;
      gpu-passthrough.enable = true;
    };
    gaming = {
      enable = true;
    };
    media = {
      enable = true;
    };
    productivity.enable = true;
    utilities.enable = true;

    neovim = {
      nixcats.enable = true;
      nixvim.enable = false;
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
    defaultSopsFile = "${inputs.self}/secrets/secrets.yaml";
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/jayne/.config/sops/age/keys.txt";
  };

  nix.settings.trusted-users = [
    "root"
    "jayne"
  ];

  system.stateVersion = "25.05";
}
