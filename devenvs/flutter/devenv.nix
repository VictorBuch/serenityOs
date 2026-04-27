{
  pkgs,
  lib,
  config,
  ...
}:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  android = {
    enable = true;
    flutter.enable = true;
    platforms.version = [
      "34"
      "35"
      "36"
    ];
    ndk.enable = true;
    # System images + emulator unpack to ~8GB each. On darwin we use the system
    # Android Studio SDK (~/Library/Android/sdk) for emulators instead.
    emulator.enable = !isDarwin;
    systemImages.enable = !isDarwin;
    systemImageTypes = [ "google_apis_playstore" ];
    abis =
      if isDarwin then
        [ "arm64-v8a" ]
      else
        [
          "arm64-v8a"
          "x86_64"
        ];
  };

  packages =
    with pkgs;
    [
      jdk17
      gradle
      android-tools
      jq
    ]
    ++ lib.optionals (!isDarwin) [
      # chromium on darwin pulls mesa-darwin which throws "driverLink not supported on darwin"
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
    # On darwin, point Flutter at a system Chrome/Edge if present; otherwise leave unset.
    if command -v chromium >/dev/null 2>&1; then
      export CHROME_EXECUTABLE=$(command -v chromium)
    elif [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
      export CHROME_EXECUTABLE="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    fi
    export ANDROID_HOME=$(which android | sed -E 's|(.*libexec/android-sdk).*|\1|')
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
    export _JAVA_OPTIONS="-Dorg.gradle.projectcachedir=$(mktemp -d)"

    # Tell the Android emulator to use system Qt/X11 libs instead of its bundled
    # copies. Avoids the Wayland Qt clash without poisoning LD_LIBRARY_PATH for
    # Gradle/JVM tooling. Falls back to the `emu` script if this isn't enough.
    export ANDROID_EMULATOR_USE_SYSTEM_LIBS=1

    # nixpkgs Flutter 3.41 omits bin/cache/engine.realm; gradle plugin requires it.
    # Mirror SDK via symlinks into a writable per-project state dir and add an empty
    # engine.realm. DEVENV_STATE is set by devenv (per-project, gitignored).
    SDK_SRC=$(dirname $(dirname $(readlink -f $(command -v flutter))))
    SDK_OUT="$DEVENV_STATE/flutter-sdk"
    if [ "$(readlink "$SDK_OUT/.source" 2>/dev/null)" != "$SDK_SRC" ]; then
      rm -rf "$SDK_OUT"
      mkdir -p "$SDK_OUT/bin/cache"
      for entry in "$SDK_SRC"/*; do
        name=$(basename "$entry")
        [ "$name" = "bin" ] && continue
        ln -s "$entry" "$SDK_OUT/$name"
      done
      for entry in "$SDK_SRC/bin"/*; do
        name=$(basename "$entry")
        [ "$name" = "cache" ] && continue
        ln -s "$entry" "$SDK_OUT/bin/$name"
      done
      for entry in "$SDK_SRC/bin/cache"/*; do
        ln -s "$entry" "$SDK_OUT/bin/cache/$(basename "$entry")"
      done
      : > "$SDK_OUT/bin/cache/engine.realm"
      ln -s "$SDK_SRC" "$SDK_OUT/.source"
    fi
    export FLUTTER_ROOT="$SDK_OUT"
    export PATH="$SDK_OUT/bin:$PATH"

    flutter config --android-sdk "$ANDROID_SDK_ROOT" 2>/dev/null || true
    flutter config --no-analytics 2>/dev/null || true
    rm -f android/local.properties
  '';
}
