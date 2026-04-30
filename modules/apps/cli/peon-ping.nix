args@{
  config,
  pkgs,
  lib,
  mkModule,
  inputs,
  ...
}:

mkModule {
  name = "peon-ping";
  category = "cli";
  description = "Agent sound notifications (peon-ping)";
  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      peonPkg = inputs.peon-ping.packages.${pkgs.stdenv.hostPlatform.system}.default;
      jsonFormat = pkgs.formats.json { };

      ogPacksVersion = "1.4.0";
      ogPacksSrc = pkgs.fetchzip {
        url = "https://github.com/PeonPing/og-packs/archive/refs/tags/v${ogPacksVersion}.tar.gz";
        sha256 = "sha256-jkybxNrXfc8GFPAi0Lb1rF8fsx8Z8K0k5gQxh8Y62Ds=";
        stripRoot = false;
      };

      settings = {
        default_pack = "jarvis";
        pack_rotation_mode = "session_override";
        pack_rotation = [
          "peon"
          "glados"
          "sc_kerrigan"
          "jarvis"
        ];
        volume = 0.7;
        enabled = true;
        desktop_notifications = true;
        categories = {
          "session.start" = true;
          "task.complete" = true;
          "task.error" = true;
          "input.required" = true;
          "resource.limit" = true;
          "user.spam" = false;
        };
      };

      installPacks = [
        "peon"
        "glados"
        "sc_kerrigan"
        {
          name = "jarvis";
          src = pkgs.fetchFromGitHub {
            owner = "FlynnCruse";
            repo = "openpeon-jarvis";
            rev = "307957814af48001f2b32c417acc89d222982ac9";
            hash = "sha256-SDelu1fhg2/JFKIQM4lSLevl7wMUBfuAFNOM/5gf8Mo=";
          };
        }
      ];

      ogPacks = lib.filter lib.isString installPacks;
      customPacks = lib.filter lib.isAttrs installPacks;

      packsDrv = pkgs.runCommand "peon-packs" { } ''
        set -euo pipefail
        mkdir -p $out

        ${lib.concatMapStringsSep "\n" (packName: ''
          if [ -d "${ogPacksSrc}/og-packs-${ogPacksVersion}/${packName}" ]; then
            cp -r "${ogPacksSrc}/og-packs-${ogPacksVersion}/${packName}" $out/
          else
            echo "Error: Pack '${packName}' not found in og-packs" >&2
            exit 1
          fi
        '') ogPacks}

        ${lib.concatMapStringsSep "\n" (pack: ''
          if [ -d "${pack.src}" ]; then
            cp -r "${pack.src}" "$out/${pack.name}"
          else
            echo "Error: Custom pack '${pack.name}' source not found" >&2
            exit 1
          fi
        '') customPacks}
      '';
    in
    {
      home.packages = [
        pkgs.python3
        peonPkg
      ];

      home.sessionVariables.PEON_DIR = "${config.home.homeDirectory}/.openpeon";

      home.file.".openpeon" = {
        source = pkgs.runCommand "peon-home-files" { } ''
          cp -r ${peonPkg}/share/peon-ping $out
          chmod -R u+w $out
          rm -f $out/peon.sh
        '';
        recursive = true;
      };

      home.file.".openpeon/peon.sh".source = "${peonPkg}/bin/peon";
      home.file.".openpeon/config.json".source = jsonFormat.generate "peon-ping-config" settings;
      home.file.".openpeon/packs".source = packsDrv;

      programs.zsh.initContent = ''
        source ${peonPkg}/share/zsh/site-functions/_peon 2>/dev/null || true
        alias peon="${peonPkg}/bin/peon"
      '';
    };
} args
