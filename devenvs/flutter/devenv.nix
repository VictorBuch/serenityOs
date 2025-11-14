{ pkgs, lib, config, ... }:

{
  # Enable Android development support
  android = {
    enable = true;
    platforms.version = [ "34" "35" ];
    ndk.enable = true;
    emulator.enable = false;
  };

  # Flutter and additional packages
  packages = with pkgs; [
    flutter
    jdk17
    gradle
    android-tools
    chromium
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

  # Custom scripts for Flutter development
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
  };

  # Welcome message and setup when entering the shell
  enterShell = ''
    # Gradle cache workaround (prevents writing to Nix store)
    export _JAVA_OPTIONS="-Dorg.gradle.projectcachedir=$(mktemp -d)"

    # Accept Android SDK licenses silently
    yes | sdkmanager --licenses 2>/dev/null || true

    # Configure Flutter
    flutter config --android-sdk "$ANDROID_SDK_ROOT" 2>/dev/null || true
    flutter config --no-analytics 2>/dev/null || true

    echo "📱 Flutter + Android Development Environment"
    echo ""
    echo "Flutter: $(flutter --version | head -n 1)"
    echo "Java: $(java -version 2>&1 | head -n 1)"
    echo "Android SDK: $ANDROID_SDK_ROOT"
    echo ""
    echo "Available scripts:"
    echo "  doctor       - Check Flutter installation"
    echo "  devices      - List available devices"
    echo "  clean        - Clean and get dependencies"
    echo "  run-android  - Run on Android device"
    echo "  run-web      - Run in Chrome browser"
    echo "  analyze      - Analyze Dart code"
    echo ""
    echo "Quick commands:"
    echo "  flutter create my_app      - Create new Flutter app"
    echo "  flutter pub get            - Install dependencies"
    echo "  flutter run                - Run on connected device"
    echo "  adb devices                - List connected devices"
  '';
}
