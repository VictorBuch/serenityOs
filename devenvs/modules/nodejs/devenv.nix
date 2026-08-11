{ lib, pkgs, ... }:

{
  languages.javascript = {
    enable = true;
    package = lib.mkDefault pkgs.nodejs_24;
    npm.enable = lib.mkDefault true;
    pnpm.enable = lib.mkDefault true;
    yarn.enable = lib.mkDefault true;
    bun.enable = lib.mkDefault true;
  };

  packages = with pkgs; [
    typescript
    typescript-language-server
    prettier
  ];

  git-hooks.hooks.prettier = {
    enable = lib.mkDefault true;
    excludes = [
      "package-lock\\.json"
      "pnpm-lock\\.yaml"
      "yarn\\.lock"
      "bun\\.lock"
      "\\.min\\.(js|css)$"
    ];
  };

  serenity.cmds = ''
    pm                Print the package manager detected for this project
    dev               Run the project's "dev" script
    build             Run the project's "build" script
    check             Run the project's "test" script
    fmt               Format the tree with prettier
  '';

  scripts = {
    pm.exec = lib.mkDefault ''
      if [ -f package.json ]; then
        declared=$(jq -r '.packageManager // empty' package.json 2>/dev/null | cut -d@ -f1)
        if [ -n "$declared" ]; then
          echo "$declared"
          exit 0
        fi
      fi
      if [ -f pnpm-lock.yaml ]; then
        echo pnpm
      elif [ -f bun.lock ] || [ -f bun.lockb ]; then
        echo bun
      elif [ -f yarn.lock ]; then
        echo yarn
      elif [ -f package-lock.json ]; then
        echo npm
      else
        echo "''${DEVENV_JS_PM:-npm}"
      fi
    '';

    dev.exec = lib.mkDefault ''
      exec "$(pm)" run dev "$@"
    '';

    build.exec = lib.mkDefault ''
      exec "$(pm)" run build "$@"
    '';

    check.exec = lib.mkDefault ''
      exec "$(pm)" run test "$@"
    '';

    fmt.exec = lib.mkDefault ''
      if [ "$#" -eq 0 ]; then
        exec prettier --write .
      fi
      exec prettier --write "$@"
    '';
  };

  enterTest = ''
    if [ -f package.json ] && jq -e '.scripts.test // empty' package.json >/dev/null 2>&1; then
      "$(pm)" run test
    fi
  '';
}
