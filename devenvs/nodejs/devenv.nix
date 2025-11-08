{ pkgs, lib, ... }:

{
  # Enable JavaScript/Node.js language support
  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_22;
  };

  # Additional packages for Node.js development
  packages = with pkgs; [
    # Package managers
    bun
    nodePackages.pnpm
    nodePackages.yarn

    # Development tools
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.eslint
    nodePackages.prettier

    # Utilities
    jq
  ];

  # Git hooks for automatic formatting
  git-hooks.hooks = {
    prettier = {
      enable = true;
      excludes = [ "package-lock.json" "pnpm-lock.yaml" "yarn.lock" ];
    };
  };

  # Custom scripts for common tasks
  scripts = {
    dev.exec = ''
      if [ -f "package.json" ]; then
        if [ -f "pnpm-lock.yaml" ]; then
          pnpm dev
        elif [ -f "yarn.lock" ]; then
          yarn dev
        elif [ -f "bun.lockb" ]; then
          bun dev
        else
          npm run dev
        fi
      else
        echo "No package.json found"
      fi
    '';

    build.exec = ''
      if [ -f "package.json" ]; then
        if [ -f "pnpm-lock.yaml" ]; then
          pnpm build
        elif [ -f "yarn.lock" ]; then
          yarn build
        elif [ -f "bun.lockb" ]; then
          bun run build
        else
          npm run build
        fi
      else
        echo "No package.json found"
      fi
    '';

    test.exec = ''
      if [ -f "package.json" ]; then
        if [ -f "pnpm-lock.yaml" ]; then
          pnpm test
        elif [ -f "yarn.lock" ]; then
          yarn test
        elif [ -f "bun.lockb" ]; then
          bun test
        else
          npm test
        fi
      else
        echo "No package.json found"
      fi
    '';

    format.exec = ''
      prettier --write .
    '';
  };

  # Welcome message when entering the shell
  enterShell = ''
    echo "🟢 Node.js Development Environment"
    echo ""
    echo "Node.js: $(node --version)"
    echo "npm: $(npm --version)"
    echo "pnpm: $(pnpm --version)"
    echo "yarn: $(yarn --version)"
    echo "bun: $(bun --version)"
    echo ""
    echo "Available scripts:"
    echo "  dev       - Start development server"
    echo "  build     - Build for production"
    echo "  test      - Run tests"
    echo "  format    - Format code with Prettier"
    echo ""
    echo "This environment works with:"
    echo "  • Next.js (npx create-next-app@latest)"
    echo "  • React (npx create-react-app)"
    echo "  • Vite (npm create vite@latest)"
    echo "  • Any Node.js/TypeScript project"
  '';
}
