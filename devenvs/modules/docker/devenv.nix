{ lib, pkgs, ... }:

{
  packages = with pkgs; [
    docker-client
    docker-compose
    lazydocker
  ];

  serenity.cmds = ''
    compose           Run docker compose, falling back to the standalone binary
    up                Start compose services in the background
    down              Stop compose services
    logs              Follow compose logs
    ps                List containers
  '';

  scripts = {
    compose.exec = lib.mkDefault ''
      if docker compose version >/dev/null 2>&1; then
        exec docker compose "$@"
      fi
      exec docker-compose "$@"
    '';

    up.exec = lib.mkDefault ''
      exec compose up -d "$@"
    '';

    down.exec = lib.mkDefault ''
      exec compose down "$@"
    '';

    logs.exec = lib.mkDefault ''
      exec compose logs -f "$@"
    '';

    ps.exec = lib.mkDefault ''
      if compose ps >/dev/null 2>&1; then
        exec compose ps "$@"
      fi
      exec docker ps "$@"
    '';
  };
}
