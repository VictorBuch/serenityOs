{
  config,
  pkgs,
  lib,
  options,
  ...
}:

let
  hl = config.homelab;
  domain = hl.domain;
  nixosIp = hl.nixosIp;
in

{
  options = {
    nginx-reverse-proxy.enable = lib.mkEnableOption "Enables the nginx local reverse proxy";
  };

  config = lib.mkIf config.nginx-reverse-proxy.enable {

    # SOPS templates for SSL certificates
    sops.templates."ssl-cert.pem" = {
      content = config.sops.placeholder."cloudflare/ssl/origin_certificate";
      owner = "nginx";
      group = "nginx";
      mode = "0444";
    };

    sops.templates."ssl-key.pem" = {
      content = config.sops.placeholder."cloudflare/ssl/origin_private_key";
      owner = "nginx";
      group = "nginx";
      mode = "0400";
    };

    networking.firewall.allowedTCPPorts = [
      80 # HTTP
      443 # HTTPS
    ];

    services.nginx = {
      enable = true;
      recommendedProxySettings = true; # This already sets the basic proxy headers
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedTlsSettings = true;

      # Dynamic backend configuration using nginx variables
      appendHttpConfig = ''
                # Map hostnames to complete backend URLs
                map $http_host $backend_url {
                  "auth.${domain}" "http://127.0.0.1:9091";
                  "dashboard.${domain}" "https://127.0.0.1:7575";
                  "glance.${domain}" "http://${nixosIp}:8080";
                  "uptime.${domain}" "http://127.0.0.1:3001";
                  "immich.${domain}" "http://127.0.0.1:2283";
                  "crafty.${domain}" "https://127.0.0.1:8443";
                  "mealie.${domain}" "http://127.0.0.1:9000";
                  "ad.${domain}" "http://127.0.0.1:3000";
                  "jellyfin.${domain}" "http://127.0.0.1:8096";
                  "plex.${domain}" "http://127.0.0.1:32400";
                  "request.${domain}" "http://127.0.0.1:5055";
                  "audiobooks.${domain}" "http://${nixosIp}:8004";
                  "sonarr.${domain}" "http://127.0.0.1:8989";
                  "radarr.${domain}" "http://127.0.0.1:7878";
                  "lidarr.${domain}" "http://127.0.0.1:8686";
                  "readarr.${domain}" "http://127.0.0.1:8787";
                  "prowlarr.${domain}" "http://127.0.0.1:9696";
                  "bazarr.${domain}" "http://127.0.0.1:6767";
                  "deluge.${domain}" "http://127.0.0.1:8112";
        	        "filebrowser.${domain}" "http://127.0.0.1:3030";
                  "wallos.${domain}" "http://127.0.0.1:8282";
                  "music.${domain}" "http://127.0.0.1:8095";
                  default "http://127.0.0.1:80";
                }
      '';

      virtualHosts =
        let
          # Simple proxy function using nginx variables
          proxy = {
            forceSSL = true;
            enableACME = false;
            sslCertificate = config.sops.templates."ssl-cert.pem".path;
            sslCertificateKey = config.sops.templates."ssl-key.pem".path;
            locations."/" = {
              proxyPass = "$backend_url";
              extraConfig = ''
                proxy_buffering off;
                client_max_body_size 0;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";

                # SSL config for HTTPS backends
                proxy_ssl_verify off;
                proxy_ssl_server_name on;
              '';
            };
          };

          # Protected proxy function using nginx variables
          protectedProxy = {
            forceSSL = true;
            enableACME = false;
            sslCertificate = config.sops.templates."ssl-cert.pem".path;
            sslCertificateKey = config.sops.templates."ssl-key.pem".path;
            locations = {
              "/" = {
                proxyPass = "$backend_url";
                extraConfig = ''
                  auth_request /auth;
                  error_page 401 = @error401;

                  proxy_buffering off;
                  client_max_body_size 0;
                  proxy_http_version 1.1;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection "upgrade";

                  # SSL config for HTTPS backends
                  proxy_ssl_verify off;
                  proxy_ssl_server_name on;

                  # Auth headers
                  auth_request_set $user $upstream_http_remote_user;
                  auth_request_set $groups $upstream_http_remote_groups;
                  auth_request_set $name $upstream_http_remote_name;
                  auth_request_set $email $upstream_http_remote_email;

                  proxy_set_header Remote-User $user;
                  proxy_set_header Remote-Groups $groups;
                  proxy_set_header Remote-Name $name;
                  proxy_set_header Remote-Email $email;
                '';
              };
              "/auth" = {
                proxyPass = "http://127.0.0.1:9091/api/verify";
                extraConfig = ''
                  internal;
                  proxy_pass_request_body off;
                  proxy_set_header Content-Length "";
                  proxy_set_header X-Original-URL https://$http_host$request_uri;
                  proxy_set_header X-Original-Method $request_method;
                  proxy_set_header X-Forwarded-Method $request_method;
                  proxy_set_header X-Forwarded-Proto https;
                  proxy_set_header X-Forwarded-Host $http_host;
                  proxy_set_header X-Forwarded-Uri $request_uri;
                  proxy_set_header X-Forwarded-For $remote_addr;
                '';
              };
              "@error401" = {
                return = "302 https://auth.${domain}/?rd=https://$http_host$request_uri";
              };
            };
          };
        in
        {
          "_" = {
            default = true;
            forceSSL = true;
            enableACME = false;
            sslCertificate = config.sops.templates."ssl-cert.pem".path;
            sslCertificateKey = config.sops.templates."ssl-key.pem".path;
            locations."/" = {
              return = "302 https://www.youtube.com/watch?v=dQw4w9WgXcQ";
            };
          };

          # Services using nginx variables for backend configuration
          # Unprotected services
          "auth.${domain}" = proxy;
          "immich.${domain}" = proxy;
          "mealie.${domain}" = proxy;
          "jellyfin.${domain}" = proxy;
          "plex.${domain}" = proxy;
          "request.${domain}" = proxy;
          "audiobooks.${domain}" = proxy;

          # Protected services
          "dashboard.${domain}" = protectedProxy;
          "music.${domain}" = protectedProxy;
          "filebrowser.${domain}" = protectedProxy;
          "glance.${domain}" = protectedProxy;
          "uptime.${domain}" = protectedProxy;
          "crafty.${domain}" = protectedProxy;
          "ad.${domain}" = protectedProxy;
          "sonarr.${domain}" = protectedProxy;
          "radarr.${domain}" = protectedProxy;
          "lidarr.${domain}" = protectedProxy;
          "readarr.${domain}" = protectedProxy;
          "prowlarr.${domain}" = protectedProxy;
          "bazarr.${domain}" = protectedProxy;
          "deluge.${domain}" = protectedProxy;
          "wallos.${domain}" = protectedProxy;
        };
    };
  };
}
