{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
let
  version = "0.1.0";
in
buildGoModule rec {
  pname = "pam";
  inherit version;

  src = fetchFromGitHub {
    owner = "VictorBuch";
    repo = "pam";
    tag = "v${version}";
    hash = "sha256-eCkflREdcJ9JiksJsXMQXF/pi9p5ZoA33nuFbEw5+qk=";
  };

  vendorHash = "sha256-tzxnD+noUdc9OJ1O2Opc3phW8j0NZsevTVY6rAV9G0I=";

  meta = {
    description = "Package Application Manager - Interactive CLI for managing Nix packages";
    homepage = "https://github.com/VictorBuch/pam";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ VictorBuch ];
    mainProgram = "pam";
    platforms = lib.platforms.unix;
  };
}
