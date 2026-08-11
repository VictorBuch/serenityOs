{ lib, pkgs, ... }:

{
  services.postgres = {
    enable = true;
    package = lib.mkDefault pkgs.postgresql_17;
    initialDatabases = lib.mkDefault [ { name = "devdb"; } ];
    listen_addresses = lib.mkDefault "127.0.0.1";
    port = lib.mkDefault 5432;
  };

  env.PGHOST = lib.mkDefault "127.0.0.1";
  env.PGPORT = lib.mkDefault "5432";
  env.PGDATABASE = lib.mkDefault "devdb";

  serenity.cmds = ''
    db                Open psql against the devenv postgres
    db-reset          Drop and recreate the public schema
  '';

  scripts = {
    db.exec = lib.mkDefault ''
      exec psql "$@"
    '';

    db-reset.exec = lib.mkDefault ''
      psql -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
      echo "Reset schema public in $PGDATABASE"
    '';
  };
}
