{ mkModule, ... }:

mkModule {
  name = "ffmpeg";
  category = "media";
  packages = { pkgs, ... }: [ pkgs.ffmpeg ];
  description = "FFmpeg for video editing";
}
