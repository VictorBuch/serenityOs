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
    {
      version,
      assetId,
      hash,
    }:
    stdenv.mkDerivation {
      inherit pname version;

      src = fetchurl {
        name = "${pname}-${version}-linux-x86_64.tar.gz";
        url = "https://api.github.com/repos/storytold/${pname}/releases/assets/${toString assetId}";
        curlOptsList = [
          "-H"
          "Accept: application/octet-stream"
        ];
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
