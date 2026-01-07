args@{
  config,
  pkgs,
  lib,
  inputs ? null,
  isLinux,
  mkApp,
  ...
}:

mkApp {
  _file = toString ./work.nix;
  name = "work";
  optionPath = "apps.work";
  packages = pkgs: [
    pkgs.google-cloud-sdk
    pkgs.prisma-engines
    pkgs.prisma
    pkgs.openssl
  ];
  linuxExtraConfig = {
    environment.sessionVariables = {
      PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
      PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/schema-engine";
      PRISMA_QUERY_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/query-engine";
      PRISMA_QUERY_ENGINE_LIBRARY = "${pkgs.prisma-engines}/lib/libquery_engine.node";
      PRISMA_FMT_BINARY = "${pkgs.prisma-engines}/bin/prisma-fmt";
    };
  };
  darwinExtraConfig = {
    launchd.user.envVariables = {
      PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
      PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/schema-engine";
      PRISMA_QUERY_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/query-engine";
      PRISMA_QUERY_ENGINE_LIBRARY = "${pkgs.prisma-engines}/lib/libquery_engine.node";
      PRISMA_FMT_BINARY = "${pkgs.prisma-engines}/bin/prisma-fmt";
    };
  };
  description = "Command-line development and management tools";
} args
