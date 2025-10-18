# Development Shell Templates

Project-specific development environments using Nix flakes and direnv for automatic activation.

## Why DevShells?

**Benefits over global installation:**

- ✅ **Version Isolation** - Different projects use different tool versions
- ✅ **Lightweight System** - Only essential tools installed globally
- ✅ **Reproducibility** - Anyone can get the exact same environment
- ✅ **No Conflicts** - No PATH pollution or version conflicts
- ✅ **Auto-Activation** - Shells activate automatically with `direnv`
- ✅ **Easy Cleanup** - `nix-collect-garbage` removes unused dependencies

## Available Templates

| Template     | Use Case                  | Key Tools                                       |
| ------------ | ------------------------- | ----------------------------------------------- |
| **vue-nuxt** | Vue 3 & Nuxt 3 projects   | Node.js 20, pnpm, npm, Vue CLI, Volar           |
| **nodejs**   | Next.js, React, any JS/TS | Node.js 22, pnpm, npm, yarn, bun, TypeScript    |
| **flutter**  | Flutter mobile/web apps   | Flutter, Android SDK, Dart, Chrome              |
| **docker**   | Docker Compose projects   | Docker, Docker Compose, Node.js, PostgreSQL CLI |

## Quick Start

### 1. Enable in Existing Project

```bash
# Copy the .envrc file from the template you need
cd /path/to/your/project
cp ~/nixos/templates/nodejs/.envrc .

# Allow direnv to activate the shell
direnv allow

# The shell is now active! Tools are available
node --version
```

### 2. Create New Project with Template

**Vue/Nuxt Project:**

```bash
npm create vue@latest my-vue-app
cd my-vue-app
cp ~/nixos/templates/vue-nuxt/.envrc .
direnv allow
pnpm install
pnpm dev
```

**Next.js Project:**

```bash
npx create-next-app@latest my-next-app
cd my-next-app
cp ~/nixos/templates/nodejs/.envrc .
direnv allow
npm install
npm run dev
```

**Flutter Project:**

```bash
flutter create my_flutter_app
cd my_flutter_app
cp ~/nixos/templates/flutter/.envrc .
direnv allow
flutter pub get
flutter run
```

**Docker Compose Project:**

```bash
mkdir my-fullstack-app && cd my-fullstack-app
cp ~/nixos/templates/docker/.envrc .
# Create your docker-compose.yml
direnv allow
docker-compose up -d
```

## How It Works

1. **direnv** watches for `.envrc` files in directories
2. When you `cd` into a project, it reads `.envrc`
3. `.envrc` tells direnv to use a specific devShell from `~/nixos`
4. The devShell loads all required tools automatically
5. When you `cd` out, the tools are unloaded

## Usage Examples

### Switching Between Projects

```bash
# Working on a Flutter app
cd ~/projects/my-flutter-app
# Flutter tools automatically available
flutter doctor

# Switch to a Next.js project
cd ~/projects/my-next-app
# Node.js tools automatically available, Flutter unloaded
npm run dev

# Switch to a Vue project with different Node version
cd ~/projects/my-vue-app
# Different Node.js version loaded automatically
pnpm dev
```

### Using Without direnv (Manual Activation)

If you prefer manual control:

```bash
# Enter the shell manually
nix develop ~/nixos#nodejs

# Or use the shell for a single command
nix develop ~/nixos#flutter --command flutter doctor
```

## Customizing Templates

### Modify Existing Template

1. Edit the template file:

```bash
nvim ~/nixos/templates/nodejs/default.nix
```

2. Add or remove packages in `buildInputs`:

```nix
buildInputs = with pkgs; [
  nodejs_22
  nodePackages.pnpm
  # Add your custom package
  deno
];
```

3. Rebuild your system:

```bash
cd ~/nixos
sudo nixos-rebuild switch --flake .
```

4. Reload direnv in your projects:

```bash
cd /path/to/project
direnv reload
```

### Create Project-Specific Overrides

For project-specific tweaks, create a local `shell.nix` that imports the template:

```nix
# In your project directory: shell.nix
let
  nixos = /home/jayne/nixos;
  baseShell = import "${nixos}/templates/nodejs" {
    pkgs = import <nixpkgs> {};
  };
in
baseShell.overrideAttrs (old: {
  buildInputs = old.buildInputs ++ [ pkgs.postgresql ];
  shellHook = old.shellHook + ''
    export DATABASE_URL="postgresql://localhost/mydb"
  '';
})
```

Then update `.envrc`:

```bash
use nix
```

## Troubleshooting

### direnv not activating

```bash
# Check if direnv is installed
direnv --version

# Allow the directory
cd /path/to/project
direnv allow
```

### Tools not found after activation

```bash
# Reload the shell
direnv reload

# Or rebuild the flake
cd ~/nixos
nix flake update
sudo nixos-rebuild switch --flake .
```

### Check which shell is active

```bash
# See the current environment
echo $DIRENV_DIR

# List available shells
nix flake show ~/nixos
```

### Clean up old environments

```bash
# Remove unused Nix store paths
nix-collect-garbage -d

# Optimize Nix store
nix-store --optimize
```

## Available Commands

### List all devShells

```bash
nix flake show ~/nixos
```

### Test a shell without direnv

```bash
nix develop ~/nixos#nodejs
nix develop ~/nixos#vue-nuxt
nix develop ~/nixos#flutter
nix develop ~/nixos#docker
```

### Run command in shell

```bash
nix develop ~/nixos#nodejs --command node --version
nix develop ~/nixos#flutter --command flutter doctor
```

## Tips & Best Practices

1. **Commit `.envrc` to git** - Your team can use the same environment
2. **Don't commit `.direnv/`** - Add it to `.gitignore`
3. **Use `direnv allow` after pulling** - If `.envrc` changes, re-allow it
4. **Keep templates minimal** - Only add tools you actually need
5. **Use the generic `nodejs` template** - Works for most JS/TS projects

## Template Details

For detailed information about each template:

- [vue-nuxt/README.md](./vue-nuxt/README.md)
- [nodejs/README.md](./nodejs/README.md)
- [flutter/README.md](./flutter/README.md)
- [docker/README.md](./docker/README.md)

## Need Help?

**direnv not working?**

- Make sure it's enabled in your shell config
- Check that you ran `direnv allow` in the project directory

**Package missing?**

- Search for it: `nix search nixpkgs <package-name>`
- Add it to the template's `buildInputs`
- Rebuild: `sudo nixos-rebuild switch --flake .`

**Want a new template?**

1. Copy an existing template directory
2. Modify `default.nix` with your tools
3. Add it to `flake.nix` in the `devShells` section
4. Rebuild and test
