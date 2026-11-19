{
  lib,
  fetchurl,
  appimageTools,
  emptyFile,
}:
let
  pname = "es-de";
  version = "3.5.0";

  src = fetchurl {
    url = "https://gitlab.com/es-de/emulationstation-de/-/package_files/357718352/download";
    name = "ES-DE_x64-${version}.AppImage";
    hash = "sha256-q8KZmhI4X4V3W9P5hvqJHHa2nfN5H3wS5MeDzzw2MPU=";
  };

  extracted = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraBwrapArgs = [ ''--ro-bind-try ${emptyFile} "$(readlink -f "$HOME/.config/git/config")"'' ];

  extraInstallCommands = ''
    install -Dm444 ${extracted}/org.es_de.frontend.desktop -t $out/share/applications
    install -Dm444 ${extracted}/org.es_de.frontend.svg -t $out/share/icons/hicolor/scalable/apps
  '';

  meta = {
    description = "ES-DE frontend for browsing and launching games from emulators";
    homepage = "https://es-de.org";
    license = lib.licenses.mit;
    mainProgram = "es-de";
    platforms = [ "x86_64-linux" ];
  };
}
