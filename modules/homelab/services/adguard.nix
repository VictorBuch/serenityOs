{
  pkgs,
  lib,
  options,
  config,
  ...
}:

{
  options.homelab.adguard.enable = lib.mkEnableOption "Enables AdGuard Home DNS filtering service with Unbound";

  config = lib.mkIf config.homelab.adguard.enable {

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
          # LAN fast-path: hit Caddy on mal directly instead of hairpinning
          # through the Pangolin VPS. Exact rewrites beat the wildcard, so the
          # Pangolin dashboard (no vhost on mal) still resolves to wash.
          #
          # `enabled` is mandatory: AdGuard's rewrite record carries the field,
          # and an absent key unmarshals to false, so the rewrite gets stored
          # disabled and silently ignored. mutableSettings = true merges this
          # list into the state file on every start, so leaving it out also
          # re-disables anything toggled on in the AdGuard UI.
          #
          # Keep BOTH entries enabled together: caddy.nix's wildcard vhost ends
          # in `handle { abort }` and there is no `pangolin` entry in
          # edge-services.nix, so the wildcard on its own would point the
          # Pangolin dashboard at mal and get the connection dropped.
          rewrites = [
            {
              domain = "*.victorbuch.com";
              answer = "192.168.0.243";
              enabled = true;
            }
            {
              domain = "pangolin.victorbuch.com";
              answer = "89.58.12.15"; # wash (Netcup VPS)
              enabled = true;
            }
          ];
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
}
