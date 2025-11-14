{
  pkgs,
  lib,
  config,
  ...
}:

{
  # Enable Android development support
  android = {
    enable = true;
    platforms.version = [
      "34"
      "35"
    ];
    ndk.enable = true;
    emulator.enable = false;
  };

  # Enable JavaScript/Node.js for Appwrite CLI
  languages.javascript = {
    enable = true;
    package = pkgs.nodePackages_latest.nodejs;
  };

  # Flutter, Android, and Node.js packages
  packages = with pkgs; [
    # Flutter and Dart
    flutter
    jdk17
    gradle
    android-tools
    chromium

    # Node.js package manager for Appwrite CLI
    nodePackages.pnpm
  ];

  # Environment variables for Flutter and Android
  env = {
    ANDROID_HOME = config.env.ANDROID_SDK_ROOT;
    JAVA_HOME = "${pkgs.jdk17}";
    CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
  };

  # Git hooks for automatic formatting
  git-hooks.hooks = {
    dart-format = {
      enable = true;
      name = "dart format";
      entry = "${pkgs.flutter}/bin/dart format";
      files = "\\.dart$";
      language = "system";
    };
  };

  # Custom scripts for Flutter + Appwrite development
  scripts = {
    doctor.exec = ''
      flutter doctor -v
    '';

    devices.exec = ''
      echo "Available devices:"
      flutter devices
      echo ""
      echo "Connected Android devices:"
      adb devices
    '';

    clean.exec = ''
      if [ -f "pubspec.yaml" ]; then
        flutter clean
        flutter pub get
      else
        echo "No pubspec.yaml found"
      fi
    '';

    run-android.exec = ''
      flutter run
    '';

    run-web.exec = ''
      flutter run -d chrome
    '';

    analyze.exec = ''
      flutter analyze
    '';

    appwrite-login.exec = ''
      if command -v appwrite &> /dev/null; then
        appwrite login
      else
        echo "Appwrite CLI not installed. Install with: npm install -g appwrite-cli"
      fi
    '';

    appwrite-deploy.exec = ''
      if command -v appwrite &> /dev/null; then
        appwrite deploy -a --force
      else
        echo "Appwrite CLI not installed. Install with: npm install -g appwrite-cli"
      fi
    '';
  };

  # Welcome message and setup when entering the shell
  enterShell = ''
    # Set up npm global prefix for Appwrite CLI
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
    mkdir -p "$NPM_CONFIG_PREFIX"

    # Gradle cache workaround (prevents writing to Nix store)
    export _JAVA_OPTIONS="-Dorg.gradle.projectcachedir=$(mktemp -d)"

    # Accept Android SDK licenses silently
    yes | sdkmanager --licenses 2>/dev/null || true

    # Configure Flutter
    flutter config --android-sdk "$ANDROID_SDK_ROOT" 2>/dev/null || true
    flutter config --no-analytics 2>/dev/null || true

    # Auto-install Appwrite CLI if not present
    if ! command -v appwrite &> /dev/null; then
      echo "📦 Installing Appwrite CLI..."
      npm install -g appwrite-cli
    fi

    echo "📱 Flutter + Appwrite Development Environment"
    echo ""
    echo "Flutter: $(flutter --version | head -n 1)"
    echo "Java: $(java -version 2>&1 | head -n 1)"
    echo "Node.js: $(node --version)"
    echo "pnpm: $(pnpm --version)"
    if command -v appwrite &> /dev/null; then
      echo "Appwrite CLI: $(appwrite --version 2>&1 | head -n 1)"
    fi
    echo ""
    echo "Available scripts:"
    echo "  doctor          - Check Flutter installation"
    echo "  devices         - List available devices"
    echo "  clean           - Clean and get dependencies"
    echo "  run-android     - Run on Android device"
    echo "  run-web         - Run in Chrome browser"
    echo "  analyze         - Analyze Dart code"
    echo "  appwrite-login  - Login to Appwrite"
    echo "  appwrite-deploy - Deploy Appwrite from json"
  '';
}
