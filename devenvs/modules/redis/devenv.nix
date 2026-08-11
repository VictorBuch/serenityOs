{ lib, ... }:

{
  services.redis = {
    enable = true;
    port = lib.mkDefault 6379;
  };

  env.REDIS_URL = lib.mkDefault "redis://127.0.0.1:6379";

  serenity.cmds = ''
    cache             Open redis-cli against the devenv redis
  '';

  scripts.cache.exec = lib.mkDefault ''
    exec redis-cli -p "''${REDIS_PORT:-6379}" "$@"
  '';
}
