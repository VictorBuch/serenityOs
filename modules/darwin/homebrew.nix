{
  lib,
  config,
  pkgs,
  ...
}:

{
  options.darwin.homebrew = {
    enable = lib.mkEnableOption "Enable Homebrew package manager";
  };

  config = lib.mkIf config.darwin.homebrew.enable {
    homebrew = {
      enable = true;

      # Auto-update homebrew on activation
      onActivation = {
        autoUpdate = true;
        upgrade = true;
        cleanup = "zap"; # Uninstall packages not listed in config
      };

      # Global homebrew settings
      global = {
        autoUpdate = true;
      };

      # Taps (additional repositories)
      taps = [
      ];

      # Formulae (CLI tools)
      brews = [
        "cmatrix"
        "docker"
        "docker-compose"
      ];

      # Casks (GUI applications)
      casks = [
        "1password"
        "amethyst"
        "anki"
        "betterdisplay"
        "bitwarden"
        "ghostty"
        "orbstack"
        "qmk-toolbox"
        "raycast"
        "zed"
        "gcloud-cli"
      ];

      # Mac App Store apps (requires mas CLI tool)
      masApps = {
        # Format: "App Name" = appId;
        # "Xcode" = 497799835;
      };
    };
  };
}
