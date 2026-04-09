{
  lib,
  python3,
  fetchPypi,
  mecab,
  makeWrapper,
}:
let
  pythonPackages = python3.pkgs;

  # --- Dependencies not in nixpkgs ---

  natto-py = pythonPackages.buildPythonPackage rec {
    pname = "natto-py";
    version = "1.0.1";
    pyproject = true;
    src = fetchPypi {
      pname = "natto-py";
      inherit version;
      hash = "sha256-dgEDuzlyMu4DPJkk0TV+MrFCu+Ey/GpDuM+C3WtlToY=";
    };
    build-system = [ pythonPackages.setuptools ];
    dependencies = [ pythonPackages.cffi ];
    doCheck = false;
    meta = {
      description = "A Tasty Python Binding with MeCab";
      homepage = "https://github.com/buruzaemon/natto-py";
      license = lib.licenses.bsd2;
    };
  };

  openepub = pythonPackages.buildPythonPackage rec {
    pname = "openepub";
    version = "0.0.8";
    pyproject = true;
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-zsB6zDGIuthbs76+ZtQPgA9P+NvLXysSaaTsoMh3c+Q=";
    };
    build-system = [ pythonPackages.hatchling ];
    dependencies = with pythonPackages; [ beautifulsoup4 xmltodict ];
    # xmltodict in nixpkgs is 1.0.2 but openepub pins <1 — works fine
    pythonRelaxDeps = [ "xmltodict" ];
    doCheck = false;
    meta = {
      description = "Open and parse EPUB files";
      homepage = "https://pypi.org/project/openepub/";
      license = lib.licenses.mit;
    };
  };

  subtitle-parser = pythonPackages.buildPythonPackage rec {
    pname = "subtitle_parser";
    version = "1.3.0";
    pyproject = true;
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-W/v+HwOXDTFwwW9aF35d0ldDoOK3pMmai0IK30RbjO4=";
    };
    build-system = [ pythonPackages.poetry-core ];
    dependencies = [ pythonPackages.chardet ];
    doCheck = false;
    meta = {
      description = "Parse SRT and WebVTT subtitle files";
      homepage = "https://pypi.org/project/subtitle-parser/";
      license = lib.licenses.mit;
    };
  };

in
pythonPackages.buildPythonApplication rec {
  pname = "lute3";
  version = "3.10.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-gqwoyINuP54ve6R2OonLUT2oZYmpjvUopyWbJ+stJrE=";
  };

  build-system = [ pythonPackages.flit-core ];

  dependencies = with pythonPackages; [
    flask-sqlalchemy
    flask-wtf
    natto-py
    jaconv
    platformdirs
    requests
    beautifulsoup4
    pyyaml
    toml
    waitress
    openepub
    pyparsing
    pypdf
    subtitle-parser
    ahocorapy
  ];

  # nixpkgs has newer versions than lute3's upper bounds — works fine
  pythonRelaxDeps = [ "platformdirs" "waitress" ];

  nativeBuildInputs = [ makeWrapper ];

  postFixup = ''
    wrapProgram $out/bin/lute \
      --prefix PATH : ${lib.makeBinPath [ mecab ]}
  '';

  doCheck = false;

  meta = {
    description = "LUTE - Learning Using Texts: a web application for language learning";
    homepage = "https://github.com/luteorg/lute-v3";
    license = lib.licenses.mit;
    mainProgram = "lute";
    platforms = lib.platforms.linux;
  };
}
