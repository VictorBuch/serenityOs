{ nixpkgs, system }:

let
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
in
pkgs.mkShell {
  name = "docker-nodejs-dev";

  buildInputs = with pkgs; [
    # Docker tools
    docker
    docker-compose

    # Node.js for fullstack development
    nodejs_20

    # Package managers
    nodePackages.pnpm
    nodePackages.npm
    yarn

    # Useful utilities
    jq # JSON processor
    curl # HTTP client
    netcat # Network utility
    postgresql # PostgreSQL client (psql)

    # Git for version control
    git
  ];

  shellHook = ''
    echo "🐳 Docker + Node.js Development Environment"
    echo ""
    echo "Docker: $(docker --version)"
    echo "Docker Compose: $(docker-compose --version)"
    echo "Node.js: $(node --version)"
    echo "npm: $(npm --version)"
    echo ""
    echo "Common commands:"
    echo "  docker-compose up -d       - Start services in background"
    echo "  docker-compose down        - Stop and remove containers"
    echo "  docker-compose logs -f     - Follow logs"
    echo "  docker-compose ps          - List running containers"
    echo "  docker ps                  - List all Docker containers"
    echo ""
    echo "⚠️  Note: Docker daemon must be running (system-wide service)"
    echo "Check with: systemctl status docker"
  '';
}
