{
  config,
  pkgs,
  inputs,
  pkgs-stable,
  ...
}:
let
  username = "victorbuch";
in
{
  user.userName = username;

  home-manager.useUserPackages = true;

  # User configuration
  users.users."${username}" = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.nushell;
  };

  # Set up nix channels
  nix.channel.enable = false; # We're using flakes

  # Enable darwin-rebuild command
  system.tools.darwin-rebuild.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Allow broken packages (needed for some Linux packages that pull in broken deps on macOS)
  nixpkgs.config.allowBroken = true;

  # System packages (keep minimal, prefer home-manager for user apps)
  environment.systemPackages = with pkgs; [
    git
    lazygit
    claude-code
    #mcp-nixos
    lolcat
    figlet
    bat

    # TO BE MOVED LATER
    tailscale
    flutter
    opencode
    postman
    sops
  ];

  maintenance.enable = true;
  apps = {
    cli = {
      fzf.enable = true;
      git.enable = true;
      herdr.enable = true;
      jujutsu.enable = true;
      notes.enable = true;
      nushell.enable = true;
      opencode.enable = true;
      sesh.enable = true;
      starship.enable = true;
    };

    communication = {
      discord.enable = true;
      signal.enable = true;
      slack.enable = true;
      zoom.enable = true;
    };

    # zed comes from the homebrew cask instead, to avoid compiling it.
    development = {
      agent-browser.enable = true;
      android-studio.enable = true;
      common.enable = true;
      devenv-init.enable = true;
      docker.enable = true;
      neovim.enable = true;
      tmux.enable = true;
      vscode.enable = true;
    };

    media.ffmpeg.enable = true;

    neovim.lazyvim.enable = true;

    productivity = {
      logseq.enable = true;
      obsidian.enable = true;
    };

    utilities = {
      cli-tools.enable = true;
      localsend.enable = true;
    };
  };

  # Register nushell as a permissible login shell (configured via Home Manager)
  environment.shells = [ pkgs.nushell ];
  environment.variables = {
    EDITOR = "nvim";
  };

  system.primaryUser = "${username}";

  # macOS System Defaults
  system.defaults = {
    # Dock settings
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.2;
      orientation = "bottom";
      tilesize = 38;
      largesize = 48;
      magnification = false;
      show-recents = false;
      mru-spaces = false; # Don't rearrange spaces based on most recent use
      launchanim = true;
      mineffect = "genie";
      minimize-to-application = true;

      persistent-apps = [
        "/Applications/Ghostty.app"
        "/Applications/TIDAL.app"
        "/Applications/Zen.app"
        "/Applications/Linear.app"
        "/Applications/Figma.app"
        "/Applications/Nix Apps/Slack.app"
      ];
    };

    # Finder settings
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = false;
      CreateDesktop = true;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv"; # List view
      QuitMenuItem = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    # Global system settings
    NSGlobalDomain = {
      # Appearance
      AppleInterfaceStyle = "Dark";
      AppleInterfaceStyleSwitchesAutomatically = false;

      # Keyboard
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      ApplePressAndHoldEnabled = false;

      # Trackpad
      "com.apple.trackpad.scaling" = 1.0;
      "com.apple.swipescrolldirection" = true; # Natural scrolling

      # UI/UX
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Automatic";
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;

      # Window management
      AppleWindowTabbingMode = "manual";
    };

    # Menu bar settings
    controlcenter = {
      BatteryShowPercentage = true;
      Bluetooth = true;
      Sound = true;
    };

    # Window management
    WindowManager = {
      EnableStandardClickToShowDesktop = false;
      GloballyEnabled = false; # Stage Manager
      StandardHideDesktopIcons = false;
    };

    # Activity Monitor
    ActivityMonitor = {
      IconType = 5; # CPU usage
      ShowCategory = 100; # All processes
    };
  };

  # Keyboard settings
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/Users/${username}/.config/sops/age/age-yubikey-identity-907e6f67.txt";
    age.sshKeyPaths = [ ]; # Don't try SSH keys, use YubiKey identity only
  };

  # Set hostname
  networking.hostName = "inara";
  networking.computerName = "Inara";
  networking.localHostName = "inara";

  # Time zone and locale
  time.timeZone = "Europe/Prague";

  # Shells
  programs.zsh.enable = true;

  # State version
  system.stateVersion = 5;
}
