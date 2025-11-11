{
  config,
  pkgs,
  inputs,
  isLinux,
  mkHomeModule,
  mkHomeCategory,
  ...
}:
let
  username = "victorbuch";
in
{
  # Enable Home Manager
  home-manager = {
    useGlobalPkgs = true; # Use system nixpkgs (saves evaluation, adds consistency)
    useUserPackages = true; # Install packages to user profile
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit
        username
        inputs
        isLinux
        mkHomeModule
        mkHomeCategory
        ;
    };
    users = {
      "${username}" = import ../../home/default.nix;
    };

    sharedModules = [
      {
        home = {
          cli = {
            enable = true;
            zsh.enable = false;
            neovim = {
              nixvim.enable = false;
              nvf.enable = true;
            };
          };
          terminals = {
            enable = true;
            kitty.enable = false;
          };
        };
      }
    ];
  };

  # User configuration
  users.users."${username}" = {
    name = username;
    home = "/Users/${username}";
    # shell is managed by Home Manager
  };

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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
    neovim
    nushell
    git
    lazygit
    claude-code
    mcp-nixos
    lolcat
    figlet

    # TO BE MOVED LATER
    tailscale
    flutter
  ];

  maintenance.enable = true;
  apps = {

    browsers = {
      # Zen is still too experimental on macOS with nix
      enable = false;
    };

    communication = {
      enable = true;
    };

    development = {
      enable = true;
      terminals = {
        ghostty.enable = false;
      };
    };

    media = {
      ffmpeg.enable = true;
    };

    productivity = {
      obsidian.enable = true;
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
        "/Applications/Nix Apps/Obsidian.app"
        "/Applications/TIDAL.app"
        "/Applications/Zen.app"
        "/Applications/Linear.app"
        "/Applications/Figma.app"
        "/Applications/Slack.app"
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
