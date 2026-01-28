{
  config,
  lib,
  pkgs,
  options,
  ...
}:

let
  mediaDir = config.homelab.mediaDir;
  user = config.user;
  uid = toString config.user.uid;
in

{

  options = {
    streaming.enable = lib.mkEnableOption "Enables streaming services";
  };

  config = lib.mkIf config.streaming.enable {
    users = {
      groups.multimedia = {
        name = "multimedia";
        members = [ "${user.userName}" ];
        gid = 994;
      };
      users."${user.userName}".extraGroups = [ "multimedia" ];
    };

    systemd.tmpfiles.rules = [
      "d ${mediaDir} 0770 ${uid} multimedia"
      "d ${mediaDir}/downloads 0770 ${uid} multimedia"
      "d ${mediaDir}/tv 0770 ${uid} multimedia"
      "d ${mediaDir}/movies 0770 ${uid} multimedia"
      "d ${mediaDir}/books 0770 ${uid} multimedia"
      "d ${mediaDir}/books/audio 0770 ${uid} multimedia"
      "d ${mediaDir}/books/analog 0770 ${uid} multimedia"
      "d ${mediaDir}/music 0770 ${uid} multimedia"
      "d /home/${user.userName}/gluetun 0770 ${uid} multimedia"
      "d /home/${user.userName}/deluge 0770 ${uid} multimedia"
    ];

    environment.systemPackages = with pkgs; [
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
      recyclarr
    ];

    # Ensure all streaming services wait for storage mounts
    systemd.services.jellyfin = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
    };
    systemd.services.sonarr = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
    };
    systemd.services.radarr = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
    };
    systemd.services.readarr = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
    };
    systemd.services.lidarr = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
    };
    systemd.services.bazarr = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
    };
    systemd.services.audiobookshelf = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
    };
    # systemd.services.plex = {
    #   after = [ "mnt-pool.mount" ];
    #   requires = [ "mnt-pool.mount" ];
    # };

    # Streaming services
    services = {
      plex = {
        enable = false;
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      jellyfin = {
        # port 8096
        enable = true;
        package = pkgs.jellyfin;
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      jellyseerr = {
        # port 5055
        enable = true;
        package = pkgs.jellyseerr;
        openFirewall = true;
      };
      sonarr = {
        # port 8989
        enable = true;
        package = pkgs.sonarr;
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      radarr = {
        # port 7878
        enable = true;
        package = pkgs.radarr;
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      readarr = {
        # port 8787
        enable = true;
        package = pkgs.readarr;
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      lidarr = {
        #port 8686
        enable = true;
        package = pkgs.lidarr;
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      prowlarr = {
        # port 9696
        enable = true;
        package = pkgs.prowlarr;
        openFirewall = true;
      };
      bazarr = {
        # port 6767
        enable = true;
        package = pkgs.bazarr;
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      audiobookshelf = {
        enable = true;
        package = pkgs.audiobookshelf;
        port = 8004;
        host = "127.0.0.1";
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      recyclarr = {
        enable = true;
        configuration = {
          sonarr = {
            sonarr_main = {
              api_key = {
                _secret = "/run/credentials/recyclarr.service/sonarr-api_key";
              };
              base_url = "http://localhost:8989";

              # Conservative quality profiles - prioritize smaller files but maintain quality
              quality_profiles = [
                {
                  name = "HD-1080p";
                  reset_unmatched_scores = {
                    enabled = true;
                    except = [
                      "x265"
                      "HDR"
                    ];
                  };
                }
              ];

              # Use trash guide templates
              include = [
                {
                  template = "sonarr-quality-definition-series";
                }
                {
                  template = "sonarr-v4-quality-profile-web-1080p";
                }
                {
                  template = "sonarr-v4-custom-formats-web-1080p";
                }
              ];
            };
          };
          radarr = {
            radarr_main = {
              api_key = {
                _secret = "/run/credentials/recyclarr.service/radarr-api_key";
              };
              base_url = "http://localhost:7878";

              # Conservative quality profiles
              quality_profiles = [
                {
                  name = "HD-1080p";
                  reset_unmatched_scores = {
                    enabled = true;
                    except = [
                      "x265"
                      "HDR"
                    ];
                  };
                }
              ];

              # Use trash guide templates
              include = [
                {
                  template = "radarr-quality-definition-movie";
                }
                {
                  template = "radarr-quality-profile-hd-bluray-web";
                }
                {
                  template = "radarr-custom-formats-hd-bluray-web";
                }
              ];
            };
          };
        };
      };
    };

    # Configure recyclarr service credentials
    systemd.services.recyclarr.serviceConfig.LoadCredential = [
      "sonarr-api_key:${config.sops.secrets."sonarr_api_key".path}"
      "radarr-api_key:${config.sops.secrets."radarr_api_key".path}"
    ];
  };
}
