{ nixpkgs, system }:

let
  pkgs = import nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };
  };

  # Compose Android SDK with specific versions
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [
      "34"
      "35"
      "latest"
    ];
    includeNDK = true;
    includeEmulator = false;
  };
  androidSdk = androidComposition.androidsdk;
in
pkgs.mkShell {
  name = "flutter-appwrite-dev";

  buildInputs = with pkgs; [
    # Flutter and Dart
    flutter

    # Android development
    androidSdk
    jdk17
    gradle
    android-tools # Includes adb, fastboot, etc.

    # Flutter web development
    chromium

    # Node.js for Appwrite CLI
    nodejs_20
    nodePackages.npm
    nodePackages.pnpm

    # Git for version control
    git
  ];

  # Environment variables
  ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
  JAVA_HOME = "${pkgs.jdk17}";
  CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
  NIXPKGS_ACCEPT_ANDROID_SDK_LICENSE = "1";

  shellHook = ''
    # Set up npm global prefix
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
    mkdir -p "$NPM_CONFIG_PREFIX"

    # Gradle cache workaround (prevents writing to Nix store)
    export _JAVA_OPTIONS="-Dorg.gradle.projectcachedir=$(mktemp -d)"

    # Accept Android SDK licenses
    yes | sdkmanager --licenses 2>/dev/null || true

    # Configure Flutter
    flutter config --android-sdk "$ANDROID_SDK_ROOT"
    flutter config --no-analytics

    # Auto-install Appwrite CLI if not present
    if ! command -v appwrite &> /dev/null; then
      echo "Installing Appwrite CLI..."
      npm install -g appwrite-cli
    fi

    echo "📱 Flutter + Appwrite Development Environment"
    echo ""
    echo "Flutter: $(flutter --version | head -n 1)"
    echo "Java: $(java -version 2>&1 | head -n 1)"
    echo "Node.js: $(node --version)"
    echo "npm: $(npm --version)"
    echo "pnpm: $(pnpm --version)"
    if command -v appwrite &> /dev/null; then
      echo "Appwrite CLI: $(appwrite --version 2>&1 | head -n 1)"
    fi
    echo ""
    echo "Quick commands:"
    echo "  flutter create my_app      - Create new Flutter app"
    echo "  flutter pub get            - Install Flutter dependencies"
    echo "  flutter run                - Run on connected device"
    echo "  flutter run -d chrome      - Run in Chrome (web)"
    echo ""
    echo "Appwrite CLI commands:"
    echo "  appwrite login                 - Login to Appwrite"
    echo "  appwrite init collection       - Initialize Appwrite collections"
    echo "  appwrite deploy function       - Deploy cloud function"
  '';
}
