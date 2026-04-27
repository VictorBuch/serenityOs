{
  pkgs,
  lib,
  config,
  ...
}:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  # NixOS workaround: nixpkgs android-sdk-emulator-36.4.2 has a broken bundled
  # libc++/libabseil ABI chain (missing _ZTT* VTT symbols). Force-load a known-good
  # libc++ from llvmPackages so the emulator can start.
  emulatorLibcxx = lib.optionalString (!isDarwin) "${pkgs.llvmPackages.libcxx}/lib/libc++.so.1";
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
      # Working libc++ for the emulator LD_PRELOAD shim (see enterShell). Keeping it
      # in the package list anchors the store path in the shell closure, so
      # nix-collect-garbage won't reap it out from under the wrapper script.
      llvmPackages.libcxx
    ];

  scripts = {
    emu.exec = ''
      exec emulator -avd "''${1:-pixel_6}" "''${@:2}"
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
    # Gradle/JVM tooling.
    export ANDROID_EMULATOR_USE_SYSTEM_LIBS=1

    # NixOS-only emulator fix: nixpkgs android-sdk-emulator-36.4.2 ships a broken
    # libc++/libabseil ABI (missing _ZTT* VTT symbols). Build a writable shim of
    # the SDK with a single overridden file: emulator/emulator. The wrapper
    # LD_PRELOADs a working libc++ from llvmPackages, then execs the real binary.
    # We point ANDROID_HOME at the shim so flutter (which uses absolute path
    # $ANDROID_HOME/emulator/emulator, NOT PATH) picks up the wrapper, fixing both
    # `flutter emulators` listing and `:FlutterEmulators` launch from nvim.
    if [ -n "${emulatorLibcxx}" ]; then
      SDK_REAL="$ANDROID_HOME"
      SDK_SHIM="$DEVENV_STATE/android-sdk-shim"
      if [ "$(readlink "$SDK_SHIM/.source" 2>/dev/null)" != "$SDK_REAL" ]; then
        rm -rf "$SDK_SHIM"
        mkdir -p "$SDK_SHIM/emulator"
        for entry in "$SDK_REAL"/*; do
          name=$(basename "$entry")
          [ "$name" = "emulator" ] && continue
          ln -s "$entry" "$SDK_SHIM/$name"
        done
        for entry in "$SDK_REAL/emulator"/*; do
          name=$(basename "$entry")
          [ "$name" = "emulator" ] && continue
          ln -s "$entry" "$SDK_SHIM/emulator/$name"
        done
        cat > "$SDK_SHIM/emulator/emulator" <<EOF
#!/usr/bin/env bash
exec env LD_PRELOAD="${emulatorLibcxx}" "$SDK_REAL/emulator/emulator" "\$@"
EOF
        chmod +x "$SDK_SHIM/emulator/emulator"
        ln -s "$SDK_REAL" "$SDK_SHIM/.source"
      fi
      export ANDROID_HOME="$SDK_SHIM"
      export ANDROID_SDK_ROOT="$SDK_SHIM"
      export PATH="$SDK_SHIM/emulator:$PATH"
    fi

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

    # Self-heal android/gradlew shebang. Something (autoPatchShebangs from a
    # historical stdenv hook, or a manual patchShebangs run) replaced the original
    # portable #!/usr/bin/env sh with an absolute /nix/store/.../bash path. When
    # nix-collect-garbage reaps that bash store path, gradlew breaks with
    # "ProcessException: No such file or directory". Restore the portable shebang
    # if we detect a nix-store shebang.
    for gw in android/gradlew */android/gradlew; do
      if [ -f "$gw" ] && head -1 "$gw" | grep -q "^#!/nix/store/"; then
        sed -i '1c\#!/usr/bin/env sh' "$gw"
        chmod +x "$gw"
        echo "Restored portable shebang in $gw"
      fi
    done
  '';
}
