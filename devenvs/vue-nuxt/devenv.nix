{ pkgs, lib, ... }:

{
  # Enable JavaScript/Node.js language support with LTS version
  languages.javascript = {
    enable = true;
    package = pkgs.nodePackages_latest.nodejs;
  };

  # Additional packages for Vue/Nuxt development
  packages = with pkgs; [
    # Package managers (prefer pnpm for Vue/Nuxt)
    nodePackages.pnpm
    nodePackages.npm

    # Development tools
    nodePackages.typescript
    vue-language-server
    nodePackages.typescript-language-server
    nodePackages.prettier

    # Utilities
    jq
  ];

  # Git hooks for automatic formatting
  git-hooks.hooks = {
    prettier = {
      enable = true;
      excludes = [
        "package-lock.json"
        "pnpm-lock.yaml"
        ".nuxt/*"
        "dist/*"
      ];
    };
  };

  # Custom scripts for common Vue/Nuxt tasks
  scripts = {
    dev.exec = ''
      if [ -f "package.json" ]; then
        pnpm dev
      else
        echo "No package.json found. Create a project first:"
        echo "  npm create vue@latest    - Create Vue 3 project"
        echo "  npx nuxi init <name>     - Create Nuxt 3 project"
      fi
    '';

    build.exec = ''
      if [ -f "package.json" ]; then
        pnpm build
      else
        echo "No package.json found"
      fi
    '';

    preview.exec = ''
      if [ -f "package.json" ]; then
        pnpm preview
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
    echo "🚀 Vue 3 + Nuxt 3 Development Environment"
    echo ""
    echo "Node.js: $(node --version)"
    echo "npm: $(npm --version)"
    echo "pnpm: $(pnpm --version)"
    echo ""
    echo "Available scripts:"
    echo "  dev       - Start development server"
    echo "  build     - Build for production"
    echo "  preview   - Preview production build"
    echo "  format    - Format code with Prettier"
    echo ""
    echo "Quick start:"
    echo "  npm create vue@latest    - Create new Vue 3 project"
    echo "  npx nuxi init <name>     - Create new Nuxt 3 project"
    echo "  pnpm install             - Install dependencies"
  '';
}
