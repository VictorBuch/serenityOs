# Docker + Node.js Development Template

Development environment for Docker Compose projects with local PostgreSQL and Redis services.

## What's Included

- **Docker & Docker Compose** - Container management
- **Node.js 20** - For fullstack development
- **npm, pnpm, yarn** - All package managers
- **PostgreSQL 15** - Local database (via devenv)
- **Redis** - Local cache/queue (via devenv)
- **PostgreSQL client** - psql command-line tool
- **Utilities** - jq, curl, netcat
- **Git hooks** - Prettier for JS/JSON files
- **Custom scripts** - Docker workflow helpers

## Quick Start

```bash
# Create project directory
mkdir my-fullstack-app
cd my-fullstack-app

# Copy this template
cp -r ~/serenityOs/devshells/docker/* .

# Allow direnv
direnv allow

# Start local services (PostgreSQL + Redis)
devenv up -d

# Services are now running!
# PostgreSQL: localhost:5432 (database: devdb)
# Redis: localhost:6379
```

## Available Scripts

- **`up`** - Start docker-compose services (or devenv services if no docker-compose.yml)
- **`down`** - Stop docker-compose services
- **`logs`** - Follow docker-compose logs
- **`ps`** - List running containers
- **`db-reset`** - Reset local PostgreSQL database
- **`db-connect`** - Connect to local PostgreSQL with psql

## Two Modes of Operation

### Mode 1: Docker Compose (External Containers)

If you have a `docker-compose.yml` file, the scripts manage those containers:

```bash
# Start your docker-compose services
up

# View logs
logs

# Stop services
down
```

### Mode 2: devenv Services (Built-in PostgreSQL + Redis)

If no `docker-compose.yml` exists, use built-in devenv services:

```bash
# Start PostgreSQL + Redis
devenv up -d

# Stop services
devenv down

# Services persist data in .devenv/state/
```

## Local Services

### PostgreSQL

- **Host**: localhost
- **Port**: 5432
- **Database**: devdb
- **User**: postgres (no password for local dev)

Connect:
```bash
# Using script
db-connect

# Manual connection
psql -h localhost -p 5432 -U postgres -d devdb
```

### Redis

- **Host**: localhost
- **Port**: 6379

Test:
```bash
redis-cli ping
```

## Typical Workflow

### New Fullstack Project

```bash
# 1. Create project with template
mkdir my-app && cd my-app
cp -r ~/serenityOs/devshells/docker/* .
direnv allow

# 2. Create a Next.js app (or any Node.js app)
npx create-next-app@latest .

# 3. Start local services
devenv up -d

# 4. Configure your app to use local services
# DATABASE_URL=postgresql://postgres@localhost:5432/devdb
# REDIS_URL=redis://localhost:6379

# 5. Start dev server
npm run dev
```

### Existing Docker Compose Project

```bash
# 1. Copy template to existing project
cd my-existing-project
cp -r ~/serenityOs/devshells/docker/* .
direnv allow

# 2. Start docker-compose services
up

# 3. View logs
logs
```

## Customization

### Add More Services

Edit `devenv.nix` to add more services:

```nix
{ pkgs, ... }:

{
  # ... existing config ...

  # Add MongoDB
  services.mongodb = {
    enable = true;
    port = 27017;
  };

  # Add MySQL instead of PostgreSQL
  services.mysql = {
    enable = true;
    package = pkgs.mysql80;
    initialDatabases = [{ name = "mydb"; }];
  };

  # Add RabbitMQ
  services.rabbitmq.enable = true;
}
```

Available services: PostgreSQL, MySQL, MongoDB, Redis, Memcached, RabbitMQ, Kafka, Elasticsearch, and [many more](https://devenv.sh/services/).

### Add More Scripts

```nix
{ pkgs, ... }:

{
  # ... existing config ...

  scripts = {
    seed.exec = ''
      psql -h localhost -p 5432 -U postgres -d devdb -f seed.sql
    '';

    backup.exec = ''
      pg_dump -h localhost -p 5432 -U postgres devdb > backup.sql
    '';
  };
}
```

## Service Data

Services persist data in `.devenv/state/`:

- PostgreSQL data: `.devenv/state/postgres/`
- Redis data: `.devenv/state/redis/`

To reset services:

```bash
# Stop services
devenv down

# Delete data
rm -rf .devenv/state/

# Restart services
devenv up -d
```

## Troubleshooting

**Port already in use?**
```bash
# Check what's using the port
lsof -i :5432
lsof -i :6379

# Change port in devenv.nix
services.postgres.port = 5433;
services.redis.port = 6380;
```

**Can't connect to PostgreSQL?**
```bash
# Check if service is running
devenv ps

# View service logs
devenv up  # Run in foreground to see errors
```

**System Docker daemon not running?**
```bash
# The template requires system Docker for docker-compose
# Check Docker daemon status:
# Linux: systemctl status docker
# macOS: open Docker Desktop
```

**Want to use both docker-compose AND devenv services?**
- devenv services run alongside docker-compose
- Use different ports to avoid conflicts
- devenv services are for local data (PostgreSQL, Redis)
- docker-compose is for your application containers

## Tips

1. **Commit `devenv.nix`** - Team members get the same services
2. **Don't commit `.devenv/`** - Already in `.gitignore`
3. **Use environment variables** - Configure app to use localhost services
4. **Reset data frequently** - Use `db-reset` to start fresh
5. **Services are optional** - Disable in `devenv.nix` if using docker-compose exclusively
