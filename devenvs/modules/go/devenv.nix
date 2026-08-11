{ lib, pkgs, ... }:

{
  languages.go = {
    enable = true;
    package = lib.mkDefault pkgs.go;
  };

  packages = with pkgs; [
    gotools
    gopls
    delve
    golangci-lint
    gomodifytags
    impl
    gotestsum
    sqlc
  ];

  git-hooks.hooks = {
    gofmt.enable = lib.mkDefault true;
    govet.enable = lib.mkDefault true;
  };

  serenity.cmds = ''
    dev               Run the main package
    build             Build the main package to bin/
    check             go test ./...
    cover             Write an HTML coverage report to coverage.html
    lint              golangci-lint run ./...
    mod-init          Initialise go.mod interactively
  '';

  scripts = {
    dev.exec = lib.mkDefault ''
      if [ -f main.go ]; then
        exec go run . "$@"
      elif [ -f cmd/main.go ]; then
        exec go run ./cmd "$@"
      fi
      echo "No main.go or cmd/main.go found; run 'go run <pkg>' directly." >&2
      exit 1
    '';

    build.exec = lib.mkDefault ''
      mkdir -p bin
      if [ -f main.go ]; then
        exec go build -o bin/app .
      elif [ -f cmd/main.go ]; then
        exec go build -o bin/app ./cmd
      fi
      exec go build ./...
    '';

    check.exec = lib.mkDefault ''
      exec go test ./... "$@"
    '';

    cover.exec = lib.mkDefault ''
      go test ./... -coverprofile=coverage.out
      go tool cover -html=coverage.out -o coverage.html
      echo "Wrote coverage.html"
    '';

    lint.exec = lib.mkDefault ''
      exec golangci-lint run ./... "$@"
    '';

    mod-init.exec = lib.mkDefault ''
      if [ -f go.mod ]; then
        echo "go.mod already exists" >&2
        exit 1
      fi
      printf 'Module name (e.g. github.com/user/project): '
      read -r module_name
      exec go mod init "$module_name"
    '';
  };

  enterTest = ''
    go test ./...
  '';
}
