# psarc2feedpak -- converts Rocksmith 2014 .psarc songs into .feedpak packages for
# fee[dB]ack (packages/feedback-desktop). A standalone tool, not a feedback plugin: convert
# here, then import the .feedpak in the app.
#
# Built from source; the release zips are Windows-only PyInstaller bundles. Pinned to a main
# commit rather than a tag -- v0.3.2 still reports 0.3.1 and predates the settings dialog
# and --template/--quality flags the README documents.
#
# Audio and cover art need vgmstream-cli (.wem decode) and ffmpeg (ogg encode, dds->png).
# The code finds both with shutil.which, so they go on the wrapper's PATH; without them it
# still converts charts but silently drops audio.
{
  lib,
  python3,
  fetchFromGitHub,
  vgmstream,
  ffmpeg,
  makeDesktopItem,
  copyDesktopItems,
}:
python3.pkgs.buildPythonApplication {
  pname = "psarc2feedpak";
  version = "0.3.3-unstable-2026-07-13";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "carelesshangman";
    repo = "psarc2feedpak";
    rev = "356d7f234be3d7dc0f7064b9f8c2df0b12b4b250";
    hash = "sha256-j/3kYiVX9ATxwpq+wgPnyDa7J5SjqWi4feRNmy7e5ls=";
  };

  build-system = [ python3.pkgs.setuptools ];

  dependencies = with python3.pkgs; [
    construct
    cryptography
    # The GUI is tkinter; nixpkgs' python3 ships without it.
    tkinter
  ];

  nativeBuildInputs = [ copyDesktopItems ];

  makeWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        vgmstream
        ffmpeg
      ]
    }"
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "psarc2feedpak";
      desktopName = "psarc2feedpak";
      comment = "Convert Rocksmith .psarc songs to fee[dB]ack .feedpak packages";
      exec = "psarc2feedpak-gui";
      icon = "feedback";
      categories = [
        "Audio"
        "Utility"
      ];
    })
  ];

  # No test suite upstream.
  doCheck = false;
  pythonImportsCheck = [ "psarc2feedpak" ];

  meta = {
    description = "Convert Rocksmith 2014 .psarc songs to fee[dB]ack .feedpak packages";
    homepage = "https://github.com/carelesshangman/psarc2feedpak";
    license = lib.licenses.mit;
    mainProgram = "psarc2feedpak";
    platforms = lib.platforms.linux;
  };
}
