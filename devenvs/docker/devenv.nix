{ pkgs, lib, ... }:

{
  # Enable JavaScript/Node.js for fullstack development
  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_20;
  };

  # Docker and development packages
  packages = with pkgs; [
    # Docker tools
    docker
    docker-compose

    # Package managers
    nodePackages.pnpm
    nodePackages.npm
    nodePackages.yarn

    # Utilities
    jq          # JSON processor
    curl        # HTTP client
    netcat      # Network utility
    postgresql  # PostgreSQL client (psql)
  ];

  # Local development services (start with `devenv up`)
  services.postgres = {
    enable = true;
    package = pkgs.postgresql_15;
    initialDatabases = [{ name = "devdb"; }];
    listen_addresses = "127.0.0.1";
    port = 5432;
  };

  services.redis = {
    enable = true;
    port = 6379;
  };

  # Git hooks for automatic formatting
  git-hooks.hooks = {
    prettier = {
      enable = true;
      excludes = [ "package-lock.json" "pnpm-lock.yaml" "yarn.lock" ];
    };
  };

  # Custom scripts for Docker development
  scripts = {
    up.exec = ''
      if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
        docker-compose up -d
      else
        echo "No docker-compose.yml found"
        echo "Starting devenv services instead..."
        devenv up -d
      fi
    '';

    down.exec = ''
      if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
        docker-compose down
      else
        echo "No docker-compose.yml found"
      fi
    '';

    logs.exec = ''
      if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
        docker-compose logs -f
      else
        echo "No docker-compose.yml found"
      fi
    '';

    ps.exec = ''
      if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
        docker-compose ps
      else
        docker ps
      fi
    '';

    db-reset.exec = ''
      echo "Resetting local PostgreSQL database..."
      psql -h localhost -p 5432 -U postgres -d devdb -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
      echo "Database reset complete!"
    '';

    db-connect.exec = ''
      psql -h localhost -p 5432 -U postgres -d devdb
    '';
  };

  # Welcome message when entering the shell
  enterShell = ''
    echo "🐳 Docker + Node.js Development Environment"
    echo ""
    echo "Docker: $(docker --version)"
    echo "Docker Compose: $(docker-compose --version)"
    echo "Node.js: $(node --version)"
    echo "npm: $(npm --version)"
    echo ""
    echo "Available scripts:"
    echo "  up         - Start docker-compose services"
    echo "  down       - Stop docker-compose services"
    echo "  logs       - Follow docker-compose logs"
    echo "  ps         - List running containers"
    echo "  db-reset   - Reset local PostgreSQL database"
    echo "  db-connect - Connect to local PostgreSQL"
    echo ""
    echo "Local services (start with 'devenv up'):"
    echo "  PostgreSQL - localhost:5432 (database: devdb)"
    echo "  Redis      - localhost:6379"
    echo ""
    echo "Common commands:"
    echo "  devenv up          - Start PostgreSQL + Redis"
    echo "  devenv up -d       - Start in background"
    echo "  docker ps          - List all Docker containers"
    echo ""
    echo "⚠️  Note: System Docker daemon must be running"
  '';
}
