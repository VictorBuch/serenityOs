{ pkgs, lib, config, ... }:

{
  android = {
    enable = true;
    flutter.enable = true;
    platforms.version = ["34" "35" "36"];
    ndk.enable = true;
    emulator.enable = true;
    systemImageTypes = ["google_apis_playstore"];
    abis = ["arm64-v8a" "x86_64"];
    systemImages.enable = true;
  };

  packages = with pkgs; [
    jdk17
    gradle
    android-tools
    chromium
  ];

  scripts = {
    emu.exec = ''
      EMU_LIB="$ANDROID_SDK_ROOT/emulator/lib64"
      LD_LIBRARY_PATH="$EMU_LIB:$EMU_LIB/qt/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
        emulator -avd "''${1:-pixel_6}" "''${@:2}"
    '';
  };

  enterShell = ''
    export CHROME_EXECUTABLE=$(which chromium)
    export ANDROID_HOME=$(which android | sed -E 's|(.*libexec/android-sdk).*|\1|')
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
    export _JAVA_OPTIONS="-Dorg.gradle.projectcachedir=$(mktemp -d)"

    flutter config --android-sdk "$ANDROID_SDK_ROOT" 2>/dev/null || true
    flutter config --no-analytics 2>/dev/null || true
    rm -f android/local.properties
  '';
}
