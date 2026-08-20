# fee[dB]ack desktop -- Electron shell around the got-feedback Python backend, plus a JUCE
# audio engine (VST hosting, NAM neural-amp modelling).
#
# Wrapped from the upstream AppImage rather than built from source or unpacked from the .deb.
# The bundle is deeply self-contained: its own $ORIGIN-rpath'd Python 3.12 runtime, its own
# ffmpeg/fluidsynth plus ~40 .so files under resources/bin, and native .node addons linking a
# vendored libonnxruntime. autoPatchelfHook would have to rewrite every one of those; an FHS
# env just satisfies them.
#
# Upstream has no stable release yet -- v0.3.0-alpha.1 is the newest tagged build, and the
# `nightly` tag moves daily. Bumping means re-running:
#   nix-prefetch-url --type sha256 <url>   (then `nix hash convert --to sri`)
{
  lib,
  fetchurl,
  appimageTools,
}:
let
  # buildFHSEnv names the launcher after pname, so this is what lands on PATH. Match
  # upstream's executableName ("feedback", as in the .deb) rather than the repo name.
  pname = "feedback";
  version = "0.3.0-alpha.1";

  src = fetchurl {
    url = "https://github.com/got-feedback/feedBack-desktop/releases/download/v${version}/feedback-0.3.0-x86_64.AppImage";
    hash = "sha256-vq8IqVE6uXr7SUMndAbxWEuGxq1PWnAsFkZxKmANX4M=";
  };

  # Same derivation wrapType2 builds internally, so naming it here costs nothing.
  extracted = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # appimageTools.defaultFhsEnvArgs already covers everything Electron 35 and JUCE need
  # (alsa-lib, fontconfig, freetype, libx11, libGL, wayland, libxkbcommon, libpulseaudio,
  # nss, cups, dbus, libgbm, udev...). The one gap is libjack.so.0, which the audio engine
  # dlopens -- pipewire.jack is what actually provides JACK on this machine.
  extraPkgs = pkgs: [ pkgs.pipewire.jack ];

  # Reuse the AppImage's own desktop entry and icon. Its Exec is `AppRun --no-sandbox %U`;
  # --no-sandbox stays because Electron's chrome-sandbox needs a setuid binary, which the
  # store cannot provide.
  extraInstallCommands = ''
    install -Dm444 ${extracted}/feedback.desktop $out/share/applications/feedback.desktop
    install -Dm444 ${extracted}/feedback.png \
      $out/share/icons/hicolor/512x512/apps/feedback.png
    substituteInPlace $out/share/applications/feedback.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=feedback'
  '';

  meta = {
    description = "Guitar practice app with integrated audio engine, VST hosting, and amp modeling";
    homepage = "https://github.com/got-feedback/feedBack-desktop";
    license = lib.licenses.agpl3Only;
    mainProgram = "feedback";
    platforms = [ "x86_64-linux" ];
  };
}
