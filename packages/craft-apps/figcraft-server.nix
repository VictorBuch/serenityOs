{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
let
  source = (lib.importJSON ./sources.json).figcraft-server;
in
stdenv.mkDerivation {
  pname = "figcraft-server";
  inherit (source) version;

  src = fetchurl {
    name = "figcraft-server-${source.version}-linux-x86_64.tar.gz";
    url = "https://api.github.com/repos/storytold/figcraft/releases/assets/${toString source.assetId}";
    curlOptsList = [
      "-H"
      "Accept: application/octet-stream"
    ];
    inherit (source) hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 figcraft-server -t $out/bin
    install -Dm644 server.md -t $out/share/doc/figcraft-server
    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/storytold/figcraft/blob/main/docs/server.md";
    license = with lib.licenses; [
      asl20
      mit
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "figcraft-server";
  };
}
