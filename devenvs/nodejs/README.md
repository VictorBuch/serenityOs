# Node.js Development Template

Modern Node.js development environment with support for Next.js, React, Vite, and any JavaScript/TypeScript project.

## What's Included

- **Node.js 22** - Latest Node.js with npm
- **Package managers** - npm, pnpm, yarn, bun (all available)
- **TypeScript** - TypeScript compiler and language server
- **Linting & Formatting** - ESLint and Prettier
- **Git hooks** - Prettier runs automatically on commit
- **Custom scripts** - Smart scripts that detect your package manager

## Quick Start

```bash
# Copy this template to your project
cp -r ~/serenityOs/devshells/nodejs/* /path/to/your/project/

# Navigate to project and allow direnv
cd /path/to/your/project
direnv allow

# Install dependencies and start developing
npm install
npm run dev
```

## Available Scripts

The template includes smart scripts that auto-detect your package manager:

- **`dev`** - Start development server (detects pnpm/yarn/bun/npm)
- **`build`** - Build for production
- **`test`** - Run tests
- **`format`** - Format code with Prettier

## Works With

This template is perfect for:

- **Next.js** - `npx create-next-app@latest`
- **React** - `npx create-react-app`
- **Vite** - `npm create vite@latest`
- **Remix** - `npx create-remix@latest`
- **Any Node.js/TypeScript project**

## Git Hooks

Prettier automatically formats your code before each commit:

- Formats: `.js`, `.ts`, `.jsx`, `.tsx`, `.json`, `.md`
- Excludes: `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`

## Customization

Edit `devenv.nix` to add project-specific configuration:

```nix
{ pkgs, ... }:

{
  # ... existing config ...

  # Add more packages
  packages = with pkgs; [
    postgresql  # Add PostgreSQL client
  ];

  # Add environment variables
  env.API_URL = "http://localhost:3000";

  # Add custom scripts
  scripts.migrate.exec = ''
    npm run migrate
  '';

  # Add services (PostgreSQL example)
  services.postgres = {
    enable = true;
    initialDatabases = [{ name = "myapp"; }];
  };
}
```

## Troubleshooting

**Scripts not found?**
- Make sure you're in the project directory with `direnv allow` active
- Try: `direnv reload`

**Want to change Node.js version?**
- Edit `devenv.nix` and change `package = pkgs.nodejs_22;` to `pkgs.nodejs_20` or `pkgs.nodejs_18`

**Need different package manager only?**
- Edit `devenv.nix` and remove unwanted package managers from `packages` list
