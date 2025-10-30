args@{ config, pkgs, lib, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "adguard";
  description = "AdGuard Home DNS filtering service with Unbound";
  packages = pkgs: [];  # No packages to install
  extraConfig = {
    # Configure Unbound as the recursive DNS resolver
    services.unbound = {
      enable = true;
      settings = {
        server = {
          interface = [ "127.0.0.1" ];
          port = 5335;
          access-control = [
            "127.0.0.0/8 allow"
          ];
          hide-identity = true;
          hide-version = true;
          prefetch = true;
          prefetch-key = true;
          cache-min-ttl = 3600;
          cache-max-ttl = 86400;
          serve-expired = true;
          serve-expired-ttl = 3600;
          num-threads = 2;
          msg-cache-slabs = 4;
          rrset-cache-slabs = 4;
          infra-cache-slabs = 4;
          key-cache-slabs = 4;
          rrset-cache-size = "64m";
          msg-cache-size = "32m";
          so-rcvbuf = "4m";
          so-sndbuf = "4m";
          unwanted-reply-threshold = 10000;
        };
      };
    };

    # Configure AdGuard Home to use Unbound
    services.adguardhome = {
      enable = true;
      host = "0.0.0.0";
      port = 3000;
      settings = {
        dns = {
          bind_hosts = [ "0.0.0.0" ];
          port = 53;
          # Point to local Unbound instance instead of external resolvers
          upstream_dns = [
            "127.0.0.1:5335"
          ];
          # Keep external DNS for bootstrap and fallback
          bootstrap_dns = [
            "9.9.9.9"
            "149.112.112.112"
          ];
          fallback_dns = [
            "1.1.1.1"
            "8.8.8.8"
          ];
          # Enable parallel requests for better performance
          all_servers = false;
          fastest_addr = true;
        };
        filtering = {
          protection_enabled = true;
          filtering_enabled = true;
          parental_enabled = false;
          safebrowsing_enabled = true;
        };
        filters = [
          {
            enabled = true;
            url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
            name = "AdGuard DNS filter";
            id = 1;
          }
          {
            enabled = true;
            url = "https://someonewhocares.org/hosts/zero/hosts";
            name = "Dan Pollock's List";
            id = 2;
          }
        ];
      };
    };

    # Disable systemd-resolved to prevent DNS conflicts
    services.resolved.enable = false;

    # Increase socket buffer limits for better DNS performance
    boot.kernel.sysctl = {
      "net.core.rmem_max" = 16777216; # 16MB
      "net.core.wmem_max" = 16777216; # 16MB
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [
      3000
      53
    ];
    networking.firewall.allowedUDPPorts = [ 53 ];

    # Ensure Unbound starts before AdGuard Home
    systemd.services.adguardhome = {
      after = [ "unbound.service" ];
      wants = [ "unbound.service" ];
    };
  };
} args
