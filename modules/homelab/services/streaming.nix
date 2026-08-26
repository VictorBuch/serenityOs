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
    homelab.streaming.enable = lib.mkEnableOption "Enables streaming services";
  };

  config = lib.mkIf config.homelab.streaming.enable {
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
    systemd.services.plex = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
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
        package = pkgs.jellyfin;
        openFirewall = true;
        user = "${user.userName}";
        group = "multimedia";
      };
      seerr = {
        # port 5055
        enable = true;
        package = pkgs.seerr;
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
      # Written against the v8 config schema. Upstream's config-templates repo
      # dropped includes.json and every `*-quality-profile-*` fragment id on
      # 2026-08-07, so the old `include: { template = ...; }` style no longer
      # resolves. Guide content is pulled in by trash_id instead, which also
      # keeps this self-contained -- nothing here depends on a template id that
      # upstream may rename again.
      recyclarr = {
        enable = true;
        configuration = {
          sonarr = {
            sonarr_main = {
              # Point _secret straight at the sops path. The NixOS module
              # derives its own LoadCredential entries from these values via
              # genJqSecretsReplacement, so naming /run/credentials/... here
              # makes it load a credential from a path that only exists once
              # the credential has been loaded -- the unit then dies at step
              # CREDENTIALS and recyclarr never runs at all.
              api_key = {
                _secret = config.sops.secrets."sonarr_api_key".path;
              };
              base_url = "http://localhost:8989";

              # trash's `series` sizes leave preferred at 995 MB/min, i.e.
              # "always take the biggest". Sizes are MB per minute, so a 50
              # minute episode lands near preferred * 50. WEB is where nearly
              # everything comes from and its bitrate is fixed by the source
              # anyway; the cap that matters is Bluray-1080p, which is how the
              # library ended up with 7-8 GiB Mr. Robot and Banshee episodes.
              quality_definition = {
                type = "series";
                qualities = [
                  {
                    name = "WEBDL-1080p";
                    preferred = 55;
                    max = 130;
                  }
                  {
                    name = "WEBRip-1080p";
                    preferred = 55;
                    max = 130;
                  }
                  {
                    name = "Bluray-1080p";
                    preferred = 60;
                    max = 90;
                  }
                ];
              };

              # The guide's WEB-1080p profile enables *only* WEBDL/WEBRip
              # 1080p and marks every other tier allowed:false, so a show that
              # never got a WEB release can never be grabbed at all. Override
              # `qualities` to enable fallback tiers underneath the WEB target;
              # the profile's own cutoff stays WEB 1080p, so the lower tiers
              # act as a floor rather than a habit.
              quality_profiles = [
                {
                  trash_id = "72dae194fc92bf828f32cde7744e51a1"; # WEB-1080p
                  reset_unmatched_scores.enabled = true;
                  quality_sort = "top";
                  qualities = [
                    {
                      name = "WEB 1080p";
                      qualities = [
                        "WEBDL-1080p"
                        "WEBRip-1080p"
                      ];
                    }
                    { name = "Bluray-1080p"; }
                    {
                      name = "WEB 720p";
                      qualities = [
                        "WEBDL-720p"
                        "WEBRip-720p"
                      ];
                    }
                    { name = "HDTV-1080p"; }
                  ];
                }
              ];

              # The groups the upstream web-1080p template enables, plus the DV
              # blocker. See the Radarr instance below for why the x265 swap.
              custom_format_groups.add = [
                {
                  trash_id = "158188097a58d7687dee647e04af0da3"; # [Optional] Golden Rule HD
                  exclude = [ "47435ece6b99a0b477caf360e79ba0bb" ]; # x265 (HD)
                  select = [ "9b64dff695c2115facf1b6ea59c9bd07" ]; # x265 (no HDR/DV)
                }
                { trash_id = "74aff4168620ed49dcc67e92b2c2a5b4"; } # [Optional] Language Profiles
                { trash_id = "85fae4a2294965b75710ef2989c850eb"; } # [Streaming Services] HD/UHD boost
                { trash_id = "59c3af66780d08332fdc64e68297098f"; } # [Unwanted] Unwanted Formats
                { trash_id = "d776a1ea912a117d66d83b880ff2055d"; } # [HDR Formats] DV (w/o HDR fallback)
              ];
            };
          };
          radarr = {
            radarr_main = {
              api_key = {
                _secret = config.sops.secrets."radarr_api_key".path;
              };
              base_url = "http://localhost:7878";

              # trash's `movie` sizes leave preferred at 1999 MB/min --
              # effectively unbounded, so Radarr always takes the largest
              # release it can find, which is why the library averaged 12.2 GiB
              # a film. Sizes are MB per minute: 82 puts a two hour film around
              # 9.6 GB, with max as a hard reject well above that so a slightly
              # chunky release still gets through.
              quality_definition = {
                type = "movie";
                qualities = [
                  {
                    name = "Bluray-1080p";
                    preferred = 82;
                    max = 120;
                  }
                  {
                    name = "WEBDL-1080p";
                    preferred = 60;
                    max = 100;
                  }
                  {
                    name = "WEBRip-1080p";
                    preferred = 60;
                    max = 100;
                  }
                ];
              };

              quality_profiles = [
                {
                  trash_id = "d1d67249d3890e49bc12e275d989a7e9"; # HD Bluray + WEB
                  reset_unmatched_scores.enabled = true;
                }
              ];

              # Golden Rule HD blocks all 1080p x265 by default, because 1080p
              # x265 is usually a double-compressed re-encode of an x264 source.
              # That default assumes mixed clients; playback here is a Shield
              # Pro, which direct-plays HEVC/HDR/DV and TrueHD with no transcode,
              # so the blanket block only costs us. Swap it for the narrower
              # `x265 (no HDR/DV)`, which still rejects the SDR re-encodes but
              # lets 1080p-downscaled-from-UHD HDR x265 through -- the best
              # quality-per-byte available at this resolution, and the only way
              # HDR reaches the TV from a 1080p library at all. The two formats
              # are declared conflicting in the guide's conflicts.json, so this
              # has to be an exclude+select swap, not just a select.
              custom_format_groups.add = [
                {
                  trash_id = "f8bf8eab4617f12dfdbd16303d8da245"; # [Optional] Golden Rule HD
                  exclude = [ "dc98083864ea246d05a42df0d05f81cc" ]; # x265 (HD)
                  select = [ "839bea857ed2c0a8e084f3cbdbd65ecb" ]; # x265 (no HDR/DV)
                }
                { trash_id = "a3ac6af01d78e4f21fcb75f601ac96df"; } # [Unwanted] Unwanted Formats
                # The TV is HDR but not confirmed Dolby Vision. A DV release
                # with no HDR10 fallback renders grey and washed out on a
                # non-DV display, so block that specific case.
                { trash_id = "7fc2751eef7e6bdc70b74136e5e35c76"; } # [HDR Formats] DV (w/o HDR fallback)
              ];
            };
          };
        };
      };
    };
  };
}
