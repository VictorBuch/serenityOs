{ lib, pkgs, ... }:

let
  engines = pkgs.prisma-engines_6;
in
{
  packages = with pkgs; [
    google-cloud-sdk
    prisma_6
    openssl
  ];

  env = {
    DEVENV_JS_PM = lib.mkDefault "pnpm";
    PKG_CONFIG_PATH = lib.mkDefault "${pkgs.openssl.dev}/lib/pkgconfig";
    PRISMA_SCHEMA_ENGINE_BINARY = lib.mkDefault "${engines}/bin/schema-engine";
    PRISMA_QUERY_ENGINE_BINARY = lib.mkDefault "${engines}/bin/query-engine";
    PRISMA_QUERY_ENGINE_LIBRARY = lib.mkDefault "${engines}/lib/libquery_engine.node";
    PRISMA_FMT_BINARY = lib.mkDefault "${engines}/bin/prisma-fmt";
  };

  serenity.cmds = ''
    db-push           pnpm prisma db push
    db-generate       pnpm prisma generate
    db-studio         pnpm prisma studio
  '';

  scripts = {
    dev.exec = lib.mkForce ''
      if compose config >/dev/null 2>&1; then
        compose up -d
      fi
      exec "$(pm)" run dev "$@"
    '';

    db-push.exec = lib.mkDefault ''
      exec "$(pm)" prisma db push "$@"
    '';

    db-generate.exec = lib.mkDefault ''
      exec "$(pm)" prisma generate "$@"
    '';

    db-studio.exec = lib.mkDefault ''
      exec "$(pm)" prisma studio "$@"
    '';
  };
}
