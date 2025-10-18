{ nixpkgs, system }:

let
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
in
pkgs.mkShell {
  name = "vue-nuxt-dev";

  buildInputs = with pkgs; [
    # Node.js LTS
    nodejs_20

    # Package managers
    nodePackages.pnpm
    nodePackages.npm

    # Development tools
    nodePackages.typescript
    vue-language-server
    nodePackages.typescript-language-server
  ];

  shellHook = ''
    echo "🚀 Vue 3 + Nuxt 3 Development Environment"
    echo ""
    echo "Node.js: $(node --version)"
    echo "npm: $(npm --version)"
    echo "pnpm: $(pnpm --version)"
    echo ""
    echo "Quick start:"
    echo "  npm create vue@latest    - Create new Vue 3 project"
    echo "  npx nuxi init <name>     - Create new Nuxt 3 project"
    echo "  pnpm install             - Install dependencies"
    echo "  pnpm dev                 - Start dev server"
  '';
}
