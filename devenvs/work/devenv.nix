{ pkgs, lib, ... }:

{
  # Enable JavaScript/Node.js language support
  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_22;
  };

  # Packages from the work module + dev tooling
  packages = with pkgs; [
    # Work-specific
    google-cloud-sdk
    prisma-engines_6
    prisma
    openssl

    # Docker
    docker-compose

    # Package manager
    pnpm
  ];

  # Prisma and OpenSSL environment variables
  env.PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  env.PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs.prisma-engines_6}/bin/schema-engine";
  env.PRISMA_QUERY_ENGINE_BINARY = "${pkgs.prisma-engines_6}/bin/query-engine";
  env.PRISMA_QUERY_ENGINE_LIBRARY = "${pkgs.prisma-engines_6}/lib/libquery_engine.node";
  env.PRISMA_FMT_BINARY = "${pkgs.prisma-engines_6}/bin/prisma-fmt";

  # Custom scripts for common tasks
  scripts = {
    dev.exec = ''
      if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
        echo "Starting Docker services..."
        docker compose up -d
      fi
      if [ -f "package.json" ]; then
        pnpm dev
      else
        echo "No package.json found"
      fi
    '';

    build.exec = ''
      if [ -f "package.json" ]; then
        pnpm build
      else
        echo "No package.json found"
      fi
    '';

    test.exec = ''
      if [ -f "package.json" ]; then
        pnpm test
      else
        echo "No package.json found"
      fi
    '';

    down.exec = ''
      if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
        docker compose down
      else
        echo "No compose file found"
      fi
    '';

    logs.exec = ''
      if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
        docker compose logs -f
      else
        echo "No compose file found"
      fi
    '';

    db-push.exec = ''
      pnpm prisma db push
    '';

    db-generate.exec = ''
      pnpm prisma generate
    '';

    db-studio.exec = ''
      pnpm prisma studio
    '';
  };

  # Welcome message when entering the shell
  enterShell = ''
    echo "Work Development Environment"
    echo ""
    echo "Node.js: $(node --version)"
    echo "pnpm: $(pnpm --version)"
    echo "gcloud: $(gcloud --version 2>/dev/null | head -1)"
    echo "prisma: $(prisma --version 2>/dev/null | head -1)"
    echo ""
    echo "Available scripts:"
    echo "  dev          - Start Docker services + development server"
    echo "  build        - Build for production"
    echo "  test         - Run tests"
    echo "  down         - Stop Docker services"
    echo "  logs         - Follow Docker service logs"
    echo "  db-push      - Push Prisma schema to database"
    echo "  db-generate  - Generate Prisma client"
    echo "  db-studio    - Open Prisma Studio"
  '';
}
