args@{ config, pkgs, lib, mkApp, ... }:

let
  # Define custom options that mkApp doesn't handle
  tailscaleOptions = {
    advertiseExitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Advertise this node as an exit node, allowing other devices on the tailnet
        to route all their traffic through this machine.
      '';
    };

    useRoutingFeatures = lib.mkOption {
      type = lib.types.enum [
        "none"
        "client"
        "server"
        "both"
      ];
      default = "server";
      description = ''
        Enables settings required for Tailscale's routing features.
        - "none": No routing features
        - "client": Enable as a client (loose reverse path filtering)
        - "server": Enable as a server (IP forwarding for exit nodes/subnet routers)
        - "both": Enable both client and server features
      '';
    };

    acceptRoutes = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Accept routes advertised by other nodes on the tailnet.
        Useful for accessing subnet routers.
      '';
    };

    enableSsh = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable Tailscale SSH, allowing SSH access to this machine via Tailscale
        without exposing SSH to the public internet.
      '';
    };

    extraUpFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "--advertise-routes=192.168.1.0/24"
        "--accept-dns=false"
      ];
      description = ''
        Extra flags to pass to 'tailscale up'.
        Only applied if authKeyFile is specified.
      '';
    };

    extraSetFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--auto-update" ];
      description = ''
        Extra flags to pass to 'tailscale set'.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Open UDP port 41641 in the firewall for Tailscale.
        Usually not necessary as Tailscale can work through NAT.
      '';
    };
  };
in

mkApp {
  _file = toString ./.;
  name = "tailscale";
  description = "Tailscale VPN service";
  packages = pkgs: [];  # No packages to install

  extraConfig = { config, lib, ... }:
    let
      # Get the tailscale config from the auto-generated option path
      cfg = lib.attrByPath (lib.splitString "." "apps.homelab.services.tailscale") {} config;
    in
    {
      # Add custom options to the tailscale namespace
      options = lib.setAttrByPath
        (lib.splitString "." "apps.homelab.services.tailscale")
        tailscaleOptions;

      config = lib.mkIf cfg.enable {
        # Enable the Tailscale service
        services.tailscale = {
          enable = true;
          useRoutingFeatures = cfg.useRoutingFeatures or "server";
          authKeyFile = config.sops.secrets."tailscale/auth_key".path;

          # Build extraUpFlags based on configuration
          extraUpFlags =
            [ ]
            ++ lib.optional (cfg.advertiseExitNode or false) "--advertise-exit-node"
            ++ lib.optional (cfg.acceptRoutes or false) "--accept-routes"
            ++ lib.optional (cfg.enableSsh or true) "--ssh"
            ++ (cfg.extraUpFlags or []);

          extraSetFlags = cfg.extraSetFlags or [];
        };

        # Open firewall port if requested
        networking.firewall = lib.mkIf (cfg.openFirewall or true) {
          allowedUDPPorts = [ 41641 ]; # Tailscale default port
          # Tailscale manages its own firewall rules via iptables/nftables
          # Trust the tailscale0 interface
          trustedInterfaces = [ "tailscale0" ];
        };

        # Ensure Tailscale starts after network is online
        systemd.services.tailscaled = {
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
        };

        # Additional kernel parameters for better routing performance when acting as exit node
        boot.kernel.sysctl = lib.mkIf
          ((cfg.useRoutingFeatures or "server") == "server" || (cfg.useRoutingFeatures or "server") == "both")
          {
            # Additional optimizations for routing
            "net.ipv4.conf.all.forwarding" = 1;
            "net.ipv6.conf.all.forwarding" = 1;
          };
      };
    };
} args
