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
    ]; # Android 14
    includeNDK = true;
    includeEmulator = false;
  };
  androidSdk = androidComposition.androidsdk;
in
pkgs.mkShell {
  name = "flutter-android-dev";

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

    # Git for version control
    git
  ];

  # Environment variables
  ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
  JAVA_HOME = "${pkgs.jdk17}";
  CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
  NIXPKGS_ACCEPT_ANDROID_SDK_LICENSE = "1";

  shellHook = ''
    # Gradle cache workaround (prevents writing to Nix store)
    export _JAVA_OPTIONS="-Dorg.gradle.projectcachedir=$(mktemp -d)"

    # Accept Android SDK licenses
    yes | sdkmanager --licenses 2>/dev/null || true

    # Configure Flutter
    flutter config --android-sdk "$ANDROID_SDK_ROOT"
    flutter config --no-analytics

    echo "📱 Flutter + Android Development Environment"
    echo ""
    echo "Flutter: $(flutter --version | head -n 1)"
    echo "Java: $(java -version 2>&1 | head -n 1)"
    echo "Android SDK: $ANDROID_SDK_ROOT"
    echo ""
    echo "Quick commands:"
    echo "  flutter create my_app      - Create new Flutter app"
    echo "  flutter pub get            - Install dependencies"
    echo "  flutter run                - Run on connected device"
    echo "  flutter run -d chrome      - Run in Chrome (web)"
    echo "  flutter doctor             - Check environment"
    echo "  adb devices                - List connected devices"
  '';
}
