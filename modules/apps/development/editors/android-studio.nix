args@{ config, pkgs, lib, mkModule, ... }:

# Android Studio plus the glue needed for Android / Kotlin Multiplatform work
# outside the IDE's FHS sandbox (./gradlew from a terminal, Compose Desktop runs).
#
# No adb package or udev rules: systemd >= 258 grants uaccess to Android devices
# (programs.adb was removed for that reason), and adb comes from the SDK's
# platform-tools so it never fights Android Studio's adb server over versions.
mkModule {
  name = "android-studio";
  category = "development";
  description = "Android Studio and Android/KMP development environment";
  packages =
    { pkgs, lib, platform, ... }:
    lib.optionals (platform == "linux") [ pkgs.androidStudioPackages.stable ];
  casks = [ "android-studio" ];

  # Gradle downloads its own JDKs (foojay toolchains) and Compose Desktop loads
  # AWT and Skiko natively. Those are generic-Linux binaries, so outside Android
  # Studio's FHS env they find their X11/GL/font libraries through nix-ld.
  extraConfig =
    { pkgs, lib, platform, ... }:
    lib.optionalAttrs (platform == "linux") {
      programs.nix-ld.libraries = with pkgs; [
        libx11
        libxext
        libxrender
        libxtst
        libxi
        libxrandr
        libxcursor
        libxkbcommon
        libGL
        fontconfig
        freetype
      ];
    };

  homeConfig =
    { config, pkgs, ... }:
    let
      sdk =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "${config.home.homeDirectory}/Library/Android/sdk"
        else
          "${config.home.homeDirectory}/Android/Sdk";
    in
    {
      # The SDK itself is installed and updated by Android Studio's SDK Manager.
      home.sessionVariables.ANDROID_HOME = sdk;

      programs.nushell.extraEnv = ''
        $env.ANDROID_HOME = "${sdk}"
        $env.PATH = ($env.PATH | split row (char esep) | prepend "${sdk}/platform-tools" | uniq)
      '';
    };
} args
