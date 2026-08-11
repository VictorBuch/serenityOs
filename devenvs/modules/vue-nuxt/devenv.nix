{ lib, pkgs, ... }:

{
  packages = with pkgs; [ vue-language-server ];

  env.DEVENV_JS_PM = lib.mkDefault "pnpm";

  serenity.cmds = ''
    preview           Run the project's "preview" script
  '';

  scripts.preview.exec = lib.mkDefault ''
    exec "$(pm)" run preview "$@"
  '';
}
