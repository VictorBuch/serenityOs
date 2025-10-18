{ nixpkgs, system }:

let
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
in
pkgs.mkShell {
  name = "nodejs-dev";

  buildInputs = with pkgs; [
    # Node.js (latest)
    nodejs_22

    # Package managers (choose your preferred one)
    nodePackages.pnpm
    nodePackages.npm
    yarn
    bun

    # Essential development tools
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.eslint
    nodePackages.prettier

    # Git for version control
    git
  ];

  shellHook = ''
    echo "🟢 Node.js Development Environment"
    echo ""
    echo "Node.js: $(node --version)"
    echo "npm: $(npm --version)"
    echo "pnpm: $(pnpm --version)"
    echo "yarn: $(yarn --version)"
    echo "bun: $(bun --version)"
    echo ""
    echo "This shell works with:"
    echo "  • Next.js (npx create-next-app@latest)"
    echo "  • React (npx create-react-app)"
    echo "  • Vite (npm create vite@latest)"
    echo "  • Any Node.js/TypeScript project"
    echo ""
    echo "Quick commands:"
    echo "  npm install / pnpm install / yarn install / bun install"
    echo "  npm run dev / pnpm dev / yarn dev / bun dev"
  '';
}
