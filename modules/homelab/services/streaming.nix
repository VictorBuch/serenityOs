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
  nixosIp = config.homelab.nixosIp;
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
        gid = 993;
      };
      users."${user.userName}".extraGroups = [ "multimedia" ];
    };

    systemd.tmpfiles.rules = [
      "d ${mediaDir}/media 0770 ${uid} multimedia"
      "d ${mediaDir}/media/downloads 0770 ${uid} multimedia"
      "d ${mediaDir}/media/tv 0770 ${uid} multimedia"
      "d ${mediaDir}/media/movies 0770 ${uid} multimedia"
      "d ${mediaDir}/media/books 0770 ${uid} multimedia"
      "d ${mediaDir}/media/books/audio 0770 ${uid} multimedia"
      "d ${mediaDir}/media/books/analog 0770 ${uid} multimedia"
      "d ${mediaDir}/media/music 0770 ${uid} multimedia"
      "d /home/${user.userName}/gluetun 0770 ${uid} multimedia"
      "d /home/${user.userName}/deluge 0770 ${uid} multimedia"
    ];

    environment.systemPackages = with pkgs; [
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
      recyclarr
    ];

    # Ensure all streaming services wait for NFS mounts
    systemd.services.jellyfin = {
      after = [ "nfs-mounts-ready.target" ];
      requires = [ "nfs-mounts-ready.target" ];
    };
    systemd.services.plex = {
      after = [ "nfs-mounts-ready.target" ];
      requires = [ "nfs-mounts-ready.target" ];
    };

    # Streaming services
    services = {
      plex = {
        enable = true;
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      jellyfin = {
        # port 8096
        enable = true;
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      jellyseerr = {
        # port 5055
        enable = true;
        openFirewall = true;
      };
      sonarr = {
        # port 8989
        enable = true;
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      radarr = {
        # port 7878
        enable = true;
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      readarr = {
        # port 8787
        enable = true;
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      lidarr = {
        #port 8686
        enable = true;
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      prowlarr = {
        # port 9696
        enable = true;
        openFirewall = true;
      };
      bazarr = {
        # port 6767
        enable = true;
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      audiobookshelf = {
        enable = true;
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
