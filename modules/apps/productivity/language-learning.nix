{
  config,
  pkgs,
  lib,
  ...
}:

{
  options = {
    apps.productivity.language-learning.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable language learning apps (Whisper, Anki, yt-dlp)";
    };
  };

  config = lib.mkIf config.apps.productivity.language-learning.enable {
    environment.systemPackages = with pkgs; [
      (whisper-cpp.override { vulkanSupport = true; })
      yt-dlp
      anki
    ];
  };
}
