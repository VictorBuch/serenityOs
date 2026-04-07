args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "insta360-x4air";
  category = "media";
  description = "Insta360 X4 Air virtual webcam via WiFi RTMP stream";

  # v4l-utils for testing (v4l2-ctl), ffmpeg for the bridge
  linuxPackages = { pkgs, ... }: [
    pkgs.v4l-utils
    pkgs.ffmpeg
  ];

  linuxExtraConfig = {
    # v4l2loopback kernel module — creates /dev/video10 as a virtual webcam
    boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    boot.kernelModules = [ "v4l2loopback" ];
    boot.extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=10 card_label="X4Air Virtual Camera" exclusive_caps=1
    '';

    # mediamtx — lightweight RTMP server that the camera streams to
    services.mediamtx = {
      enable = true;
      settings = {
        # Only enable RTMP ingest and RTSP restream, disable unused protocols
        rtmp = true;
        rtmpAddress = ":1935";
        rtsp = true;
        rtspAddress = ":8554";
        hls = false;
        webrtc = false;

        paths = {
          # The camera streams to rtmp://<host>:1935/live/stream
          "live/stream" = { };
        };
      };
    };

    # Firewall — allow RTMP ingest from the local network
    networking.firewall.allowedTCPPorts = [ 1935 ];

    # systemd service — bridges the RTMP stream to the v4l2loopback device
    systemd.services.x4air-webcam = {
      description = "Insta360 X4 Air RTMP to v4l2loopback bridge";
      after = [ "mediamtx.service" ];
      requires = [ "mediamtx.service" ];

      # Not started at boot — start manually when streaming
      wantedBy = lib.mkForce [ ];

      serviceConfig = {
        ExecStart = ''
          ${pkgs.ffmpeg}/bin/ffmpeg \
            -i rtmp://localhost:1935/live/stream \
            -f v4l2 -vcodec rawvideo -pix_fmt yuv420p \
            /dev/video10
        '';
        Restart = "on-failure";
        RestartSec = 3;
        # Needs access to /dev/video10
        SupplementaryGroups = [ "video" ];
        DynamicUser = true;
      };
    };
  };
} args
