# Vue 3 + Nuxt 3 Development Template

Optimized development environment for Vue 3 and Nuxt 3 projects with LTS Node.js and pnpm.

## What's Included

- **Node.js 20 LTS** - Long-term support version
- **pnpm & npm** - Fast, efficient package managers
- **Vue Language Server** - Volar/Vue LSP support
- **TypeScript** - TypeScript compiler and language server
- **Prettier** - Code formatting
- **Git hooks** - Prettier runs automatically on commit
- **Custom scripts** - Development workflow helpers

## Quick Start

```bash
# Create a new Vue 3 project
npm create vue@latest my-vue-app
cd my-vue-app

# Copy this template
cp -r ~/serenityOs/devshells/vue-nuxt/* .

# Allow direnv
direnv allow

# Start developing
pnpm install
pnpm dev
```

Or for Nuxt 3:

```bash
# Create a new Nuxt 3 project
npx nuxi init my-nuxt-app
cd my-nuxt-app

# Copy this template
cp -r ~/serenityOs/devshells/vue-nuxt/* .

# Allow direnv
direnv allow

# Start developing
pnpm install
pnpm dev
```

## Available Scripts

- **`dev`** - Start development server with pnpm
- **`build`** - Build for production
- **`preview`** - Preview production build
- **`format`** - Format code with Prettier

## Git Hooks

Prettier automatically formats your code before each commit:

- Formats: `.vue`, `.js`, `.ts`, `.json`, `.md`
- Excludes: `package-lock.json`, `pnpm-lock.yaml`, `.nuxt/*`, `dist/*`

## Customization

### Add Backend Services

Edit `devenv.nix` to add services for your fullstack app:

```nix
{ pkgs, ... }:

{
  # ... existing config ...

  # Add PostgreSQL for backend
  services.postgres = {
    enable = true;
    initialDatabases = [{ name = "myapp"; }];
  };

  # Add Redis for caching
  services.redis.enable = true;

  # Start services with: devenv up -d
}
```

### Add More Tools

```nix
{ pkgs, ... }:

{
  # ... existing config ...

  packages = with pkgs; [
    # Add more tools
    postgresql  # PostgreSQL client
    jq          # JSON processor
  ];
}
```

## Troubleshooting

**Vue Language Server not working in VSCode?**
- Install the official Vue Language Features (Volar) extension
- Make sure TypeScript Vue Plugin is enabled

**Want to use npm instead of pnpm?**
- Edit scripts in `devenv.nix` to use `npm` instead of `pnpm`

**Need different Node version?**
- Edit `devenv.nix` and change `package = pkgs.nodejs_20;` to desired version
