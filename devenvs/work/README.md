# Work Development Template

Development environment for work projects using Node.js, Prisma, Google Cloud SDK, and pnpm.

Replaces the system-wide `modules/apps/work.nix` module so these tools are only available inside work project directories.

## What's Included

- **Node.js 22** - Latest Node.js runtime
- **pnpm** - Package manager
- **Prisma** - ORM with all engine binaries configured
- **Google Cloud SDK** - `gcloud` CLI
- **OpenSSL** - With `PKG_CONFIG_PATH` configured

## Quick Start

```bash
# Copy this template to your work project
cp -r ~/serenityOs/devenvs/work/* /path/to/your/project/

# Navigate to project and allow direnv
cd /path/to/your/project
direnv allow

# Install dependencies and start developing
pnpm install
pnpm dev
```

## Environment Variables

The following are automatically set when entering the shell:

- `PKG_CONFIG_PATH` - Points to OpenSSL pkgconfig
- `PRISMA_SCHEMA_ENGINE_BINARY` - Prisma schema engine path
- `PRISMA_QUERY_ENGINE_BINARY` - Prisma query engine path
- `PRISMA_QUERY_ENGINE_LIBRARY` - Prisma query engine library path
- `PRISMA_FMT_BINARY` - Prisma formatter path

## Available Scripts

- **`dev`** - Start development server via pnpm
- **`build`** - Build for production
- **`test`** - Run tests
- **`db-push`** - Push Prisma schema to database
- **`db-generate`** - Generate Prisma client
- **`db-studio`** - Open Prisma Studio

## Customization

Edit `devenv.nix` to add project-specific configuration:

```nix
{ pkgs, ... }:

{
  # ... existing config ...

  # Add more packages
  packages = with pkgs; [
    redis  # Add Redis client
  ];

  # Add environment variables
  env.DATABASE_URL = "postgresql://localhost:5432/mydb";

  # Add services
  services.postgres = {
    enable = true;
    initialDatabases = [{ name = "myapp"; }];
  };
}
```
