# Generic Node.js Development Shell

Flexible Node.js development environment that works with any JavaScript/TypeScript project including Next.js, React, Vite, and more.

## Included Tools

- **Node.js 22** (Latest)
- **pnpm** - Fast package manager
- **npm** - Default Node package manager
- **yarn** - Alternative package manager
- **bun** - Ultra-fast JavaScript runtime & package manager
- **TypeScript** - Type checking and compilation
- **ESLint** - Code linting
- **Prettier** - Code formatting
- **Git** - Version control

## Usage in a Project

1. Copy the `.envrc` file to your project root:
   ```bash
   cp ~/nixos/templates/nodejs/.envrc /path/to/your/project/
   ```

2. Allow direnv:
   ```bash
   cd /path/to/your/project
   direnv allow
   ```

## Create New Projects

**Next.js:**
```bash
npx create-next-app@latest my-next-app
cd my-next-app
cp ~/nixos/templates/nodejs/.envrc .
direnv allow
```

**React (Vite):**
```bash
npm create vite@latest my-react-app -- --template react-ts
cd my-react-app
cp ~/nixos/templates/nodejs/.envrc .
direnv allow
```

**Generic TypeScript Project:**
```bash
mkdir my-project && cd my-project
npm init -y
npm install -D typescript @types/node
cp ~/nixos/templates/nodejs/.envrc .
direnv allow
```

## Switching Node Versions

If you need a different Node.js version (e.g., Node 20 LTS), edit `~/nixos/templates/nodejs/default.nix`:

```nix
# Change nodejs_22 to:
nodejs_20  # LTS
# or
nodejs_18  # Older LTS
```

Then rebuild:
```bash
cd ~/nixos
sudo nixos-rebuild switch --flake .
```
