{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.networking.wake-on-lan;
in
{
  options.networking.wake-on-lan = {
    enable = lib.mkEnableOption "Wake-on-LAN support for ethernet interfaces";

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "enp11s0" ];
      description = "List of network interfaces to enable WoL on";
      example = [
        "enp11s0"
        "eth0"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable Wake-on-LAN for specified interfaces using built-in NixOS support
    networking.interfaces = lib.genAttrs cfg.interfaces (interface: {
      wakeOnLan.enable = true;
    });

    # Install ethtool for manual WoL management if needed
    environment.systemPackages = with pkgs; [ ethtool ];
  };
}
