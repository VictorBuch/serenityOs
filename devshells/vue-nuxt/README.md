# Vue 3 + Nuxt 3 Development Shell

Development environment for Vue 3 and Nuxt 3 projects.

## Included Tools

- **Node.js 20** (LTS)
- **pnpm** - Fast, disk space efficient package manager
- **npm** - Node package manager
- **Vue CLI** - Vue.js project scaffolding
- **TypeScript** - Type checking
- **Volar** - Vue Language Server

## Usage in a Project

1. Copy the `.envrc` file to your project root:
   ```bash
   cp ~/serenityOs/templates/vue-nuxt/.envrc /path/to/your/project/
   ```

2. Allow direnv:
   ```bash
   cd /path/to/your/project
   direnv allow
   ```

3. The shell will activate automatically when you enter the directory!

## Create New Projects

**Vue 3:**
```bash
npm create vue@latest my-vue-app
cd my-vue-app
cp ~/serenityOs/templates/vue-nuxt/.envrc .
direnv allow
pnpm install
pnpm dev
```

**Nuxt 3:**
```bash
npx nuxi init my-nuxt-app
cd my-nuxt-app
cp ~/serenityOs/templates/vue-nuxt/.envrc .
direnv allow
pnpm install
pnpm dev
```

## Customization

Edit `~/serenityOs/templates/vue-nuxt/default.nix` to add/remove packages, then rebuild:
```bash
cd ~/serenityOs
sudo nixos-rebuild switch --flake .
```
