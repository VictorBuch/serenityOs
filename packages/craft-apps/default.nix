{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  alsa-lib,
  wayland,
  libxkbcommon,
  libGL,
  vulkan-loader,
  dbus,
  fontconfig,
  libva,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxrender,
}:
let
  mkCraftApp =
    pname:
    { version, hash }:
    stdenv.mkDerivation {
      inherit pname version;

      src = fetchurl {
        url = "https://github.com/storytold/${pname}/releases/download/v${version}/${pname}-${version}-linux-x86_64.tar.gz";
        inherit hash;
      };

      nativeBuildInputs = [ autoPatchelfHook ];
      buildInputs = [
        stdenv.cc.cc.lib
        alsa-lib
      ];
      runtimeDependencies = [
        wayland
        libxkbcommon
        libGL
        vulkan-loader
        dbus
        fontconfig
        (lib.getLib libva)
        libx11
        libxcb
        libxcursor
        libxi
        libxrender
      ];

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r bin share $out/
        runHook postInstall
      '';

      meta = {
        homepage = "https://github.com/storytold/${pname}";
        license = lib.licenses.asl20;
        platforms = [ "x86_64-linux" ];
        mainProgram = pname;
      };
    };
in
lib.mapAttrs mkCraftApp (lib.importJSON ./sources.json)
