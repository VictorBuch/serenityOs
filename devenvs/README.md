# Development Environment Templates

Portable, reproducible development environments using [devenv](https://devenv.sh) and direnv for automatic activation.

## Why devenv?

**Benefits over traditional approaches:**

- ✅ **Portable** - Copy templates to any project, no dependency on this flake
- ✅ **Team-friendly** - Teammates only need `nix` + `devenv` installed
- ✅ **Reproducible** - Exact same environment across all machines
- ✅ **Auto-activation** - Environments activate automatically with `direnv`
- ✅ **Rich features** - Language modules, services, git hooks, custom scripts
- ✅ **Service management** - PostgreSQL, Redis, and more with `devenv up`

## Available Templates

| Template             | Use Case                  | Key Features                                    |
| -------------------- | ------------------------- | ----------------------------------------------- |
| **nodejs**           | Next.js, React, any JS/TS | Node.js 22, all package managers, Prettier     |
| **vue-nuxt**         | Vue 3 & Nuxt 3 projects   | Node.js 20 LTS, pnpm, Vue language server       |
| **flutter**          | Flutter mobile/web apps   | Flutter, Android SDK, Dart formatter            |
| **flutter-appwrite** | Flutter + Appwrite        | Everything in flutter + Appwrite CLI            |
| **docker**           | Docker Compose projects   | Docker, Node.js, PostgreSQL, Redis (via devenv) |
| **go**               | Backend APIs, CLI tools   | Latest Go, gopls, delve, golangci-lint, sqlc    |

## Prerequisites

Your teammates only need:

```bash
# 1. Install Nix (if not already installed)
sh <(curl -L https://nixos.org/nix/install)

# 2. Install devenv
nix-env -iA nixpkgs.devenv

# 3. Install direnv (optional, but recommended)
nix-env -iA nixpkgs.direnv

# 4. Add direnv hook to your shell
# For bash: add to ~/.bashrc
eval "$(direnv hook bash)"

# For zsh: add to ~/.zshrc
eval "$(direnv hook zsh)"
```

## Quick Start

### Starting a New Project

**Next.js / React Project:**

```bash
# Create your Next.js app
npx create-next-app@latest my-app
cd my-app

# Copy the nodejs template
cp -r ~/serenityOs/devshells/nodejs/* .

# Allow direnv to activate
direnv allow

# Environment is now active!
npm install
npm run dev
```

**Vue / Nuxt Project:**

```bash
# Create your Vue app
npm create vue@latest my-vue-app
cd my-vue-app

# Copy the vue-nuxt template
cp -r ~/serenityOs/devshells/vue-nuxt/* .

# Allow direnv
direnv allow

# Ready to go!
pnpm install
pnpm dev
```

**Flutter Project:**

```bash
# Create Flutter app
flutter create my_flutter_app
cd my_flutter_app

# Copy the flutter template
cp -r ~/serenityOs/devshells/flutter/* .

# Allow direnv
direnv allow

# Verify setup
doctor  # Custom script from template
flutter run
```

**Docker Compose Project:**

```bash
# Create project directory
mkdir my-fullstack-app && cd my-fullstack-app

# Copy the docker template
cp -r ~/serenityOs/devshells/docker/* .

# Allow direnv
direnv allow

# Start local PostgreSQL + Redis
devenv up -d

# Your services are now running!
```

## How It Works

1. **Templates are standalone** - Each template contains all configuration needed
2. **direnv watches for `.envrc`** - Automatically loads environment when you `cd` into project
3. **devenv manages everything** - Packages, services, git hooks, scripts all defined in `devenv.nix`
4. **No coupling** - Projects don't depend on your NixOS/Darwin configuration

## Template Features

### Automatic Formatting (Pre-commit Hooks)

All templates include git hooks that run formatters before each commit:

- **nodejs/vue-nuxt**: Prettier (JavaScript, TypeScript, Vue, JSON)
- **flutter/flutter-appwrite**: Dart format
- **docker**: Prettier (for JS/JSON files)

Formatters run automatically on `git commit` - no manual formatting needed!

### Custom Scripts

Each template includes helpful scripts:

**nodejs template:**

```bash
dev      # Start development server (auto-detects pnpm/yarn/bun/npm)
build    # Build for production
test     # Run tests
format   # Manually format code with Prettier
```

**vue-nuxt template:**

```bash
dev      # Start dev server with pnpm
build    # Build for production
preview  # Preview production build
format   # Format code with Prettier
```

**flutter templates:**

```bash
doctor       # Run flutter doctor
devices      # List available devices
clean        # Clean and get dependencies
run-android  # Run on Android device
run-web      # Run in Chrome
analyze      # Analyze Dart code
```

**flutter-appwrite template** (includes all flutter scripts plus):

```bash
appwrite-login   # Login to Appwrite
appwrite-deploy  # Deploy Appwrite function
```

**docker template:**

```bash
up         # Start docker-compose services
down       # Stop docker-compose services
logs       # Follow logs
ps         # List containers
db-reset   # Reset local PostgreSQL
db-connect # Connect to PostgreSQL
```

### Services (Docker Template)

The docker template includes built-in services managed by devenv:

```bash
# Start services in background
devenv up -d

# Services now running:
# - PostgreSQL: localhost:5432 (database: devdb)
# - Redis: localhost:6379

# Stop services
devenv down
```

Services persist data in `.devenv/state/` directory.

## Usage Examples

### Team Collaboration

**Developer 1 (you):**

```bash
# Create project and add devenv template
npx create-next-app@latest awesome-app
cd awesome-app
cp -r ~/serenityOs/devshells/nodejs/* .
git add .
git commit -m "Add devenv configuration"
git push
```

**Developer 2 (teammate):**

```bash
# Clone and setup (only needs nix + devenv installed)
git clone <repo>
cd awesome-app
direnv allow

# Environment automatically loads!
npm install
npm run dev
```

### Switching Between Projects

```bash
# Working on a Flutter app
cd ~/projects/my-flutter-app
# Flutter tools automatically available
doctor

# Switch to a Next.js project
cd ~/projects/my-next-app
# Node.js tools automatically available, Flutter unloaded
dev

# Switch to a project with services
cd ~/projects/my-fullstack-app
devenv up -d  # Start PostgreSQL + Redis
dev           # Start app server
```

### Using Without direnv

If you prefer manual control:

```bash
# Enter the environment manually
devenv shell

# Run a single command
devenv shell dev

# Exit the environment
exit
```

## Customizing Templates

### Per-Project Customization

Each project can customize its own `devenv.nix`:

```nix
{ pkgs, ... }:

{
  # Extend the template
  languages.javascript.enable = true;

  # Add project-specific packages
  packages = with pkgs; [
    postgresql  # Add PostgreSQL client
  ];

  # Add project-specific environment variables
  env.DATABASE_URL = "postgresql://localhost/mydb";

  # Override or add scripts
  scripts.migrate.exec = ''
    npm run migrate
  '';
}
```

### Adding Services

Any project can add services to its `devenv.nix`:

```nix
{
  # ... existing config ...

  services.postgres = {
    enable = true;
    initialDatabases = [{ name = "myapp"; }];
  };

  services.redis.enable = true;
}
```

Then start with: `devenv up -d`

## Available Services

devenv supports many services out of the box:

- **Databases**: PostgreSQL, MySQL, MongoDB, CouchDB
- **Cache/Queue**: Redis, Memcached, RabbitMQ, Kafka
- **Search**: Elasticsearch, Meilisearch
- **And many more**: See [devenv.sh/services](https://devenv.sh/services/)

## Troubleshooting

### direnv not activating

```bash
# Check if direnv is installed
direnv version

# Allow the directory
cd /path/to/project
direnv allow
```

### devenv not found

```bash
# Install devenv
nix-env -iA nixpkgs.devenv

# Or use nix-shell temporarily
nix-shell -p devenv
```

### Services not starting

```bash
# Check service status
devenv up  # Run in foreground to see errors

# Check service state
ls .devenv/state/

# Reset services (deletes data!)
rm -rf .devenv/state/
devenv up
```

### Git hooks not running

```bash
# Reinstall hooks
devenv shell
# Hooks are automatically installed on shell entry

# Or manually install
pre-commit install
```

## Migrating Existing Projects

To add devenv to an existing project:

```bash
# 1. Choose the appropriate template
cd my-existing-project

# 2. Copy template files (don't overwrite your files!)
cp ~/serenityOs/devshells/nodejs/devenv.nix .
cp ~/serenityOs/devshells/nodejs/devenv.yaml .
cp ~/serenityOs/devshells/nodejs/.envrc .
cat ~/serenityOs/devshells/nodejs/.gitignore >> .gitignore

# 3. Customize devenv.nix for your project

# 4. Activate
direnv allow
```

## Cleaning Up

```bash
# Remove unused devenv generations
devenv gc

# Remove old direnv cache
rm -rf .direnv/

# Remove service data
rm -rf .devenv/state/
```

## Tips & Best Practices

1. **Commit devenv files to git** - Team can use the same environment
2. **Don't commit `.devenv/` or `.direnv/`** - Already in `.gitignore`
3. **Use `direnv allow` after pulling** - If `devenv.nix` changes, re-allow
4. **Keep templates minimal** - Add packages as needed per-project
5. **Use services sparingly** - Only enable services you actively use
6. **Document custom scripts** - Add comments in `devenv.nix`

## Need Help?

- **devenv documentation**: [devenv.sh](https://devenv.sh)
- **Language modules**: [devenv.sh/languages](https://devenv.sh/languages/)
- **Services**: [devenv.sh/services](https://devenv.sh/services/)
- **Git hooks**: [devenv.sh/git-hooks](https://devenv.sh/git-hooks/)

## Template Details

Each template has its own README with specific documentation:

- [nodejs/README.md](./nodejs/README.md)
- [vue-nuxt/README.md](./vue-nuxt/README.md)
- [flutter/README.md](./flutter/README.md)
- [flutter-appwrite/README.md](./flutter-appwrite/README.md)
- [docker/README.md](./docker/README.md)
- [go/README.md](./go/README.md)
