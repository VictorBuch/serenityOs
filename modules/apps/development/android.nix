args@{
  config,
  pkgs,
  lib,
  inputs ? null,
  isLinux,
  mkApp,
  ...
}:

let
  # Compose Android SDK with all needed components
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    # Command-line and platform tools
    cmdLineToolsVersion = "11.0";
    platformToolsVersion = "35.0.1";

    # Build tools for Flutter/Gradle
    buildToolsVersions = [
      "35.0.0"
      "36.0.0"
    ];

    # Platform versions (API levels)
    platformVersions = [
      "35"
      "36"
    ];

    # ABIs for emulator system images
    abiVersions = [
      "x86_64"
      "arm64-v8a"
    ];

    # Include emulator and system images
    includeEmulator = true;
    emulatorVersion = "35.1.4";
    includeSystemImages = true;
    systemImageTypes = [ "google_apis_playstore" ];

    # Include NDK (required by some Flutter plugins)
    includeNDK = true;
    ndkVersions = [ "28.0.13004108" ];  # Closest available to 28.2.x
    includeSources = false;
    includeExtras = [ "extras;google;gcm" ];
  };

  androidSdk = androidComposition.androidsdk;
in
mkApp {
  _file = toString ./.;
  name = "android";
  packages = pkgs: [
    pkgs.unstable.flutter
    pkgs.unstable.android-studio
    androidSdk
    pkgs.jdk17
  ];
  description = "Android development tools with SDK and emulator support";
  extraConfig = {
    # Enable ADB
    programs.adb.enable = true;

    # Add user to required groups
    users.users.${config.user.userName}.extraGroups = [
      "adbusers"
      "kvm"
    ];

    # Set Android/Flutter environment variables system-wide
    environment.variables = {
      ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
      ANDROID_NDK_HOME = "${androidSdk}/libexec/android-sdk/ndk/28.0.13004108";
      JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
      # Gradle cache workaround (prevents writing to Nix store)
      GRADLE_USER_HOME = "$HOME/.gradle";
      # Override aapt2 with Nix-provided version (fixes "corrupted build tools" error)
      GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/35.0.0/aapt2";
    };
  };
} args
