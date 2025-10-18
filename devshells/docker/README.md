# Docker + Node.js Development Shell

Development environment for Docker Compose projects with Node.js support, ideal for fullstack applications with databases, Redis, etc.

## Included Tools

- **Docker** - Container runtime
- **Docker Compose** - Multi-container orchestration
- **Node.js 20** - For fullstack development
- **pnpm** - Fast package manager
- **npm** - Node package manager
- **yarn** - Alternative package manager
- **PostgreSQL client** - Database CLI (`psql`)
- **jq** - JSON processor
- **curl** - HTTP client for API testing
- **netcat** - Network utility
- **Git** - Version control

## Prerequisites

Docker must be enabled in your NixOS configuration. If not already enabled:

```nix
# In your configuration.nix
virtualisation.docker.enable = true;

# Add your user to docker group
users.users.youruser.extraGroups = [ "docker" ];
```

Then rebuild and reboot (or restart Docker):
```bash
sudo nixos-rebuild switch
sudo systemctl restart docker
```

## Usage in a Project

1. Copy the `.envrc` file to your project root:
   ```bash
   cp ~/nixos/templates/docker/.envrc /path/to/your/project/
   ```

2. Allow direnv:
   ```bash
   cd /path/to/your/project
   direnv allow
   ```

## Example Project Setup

**Fullstack app with PostgreSQL and Redis:**

1. Create `docker-compose.yml`:
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
      POSTGRES_DB: myapp
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  app:
    build: .
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis
    environment:
      DATABASE_URL: postgresql://dev:dev@postgres:5432/myapp
      REDIS_URL: redis://redis:6379

volumes:
  postgres_data:
```

2. Set up the project:
```bash
cp ~/nixos/templates/docker/.envrc .
direnv allow
npm install
docker-compose up -d
npm run dev
```

## Common Commands

**Docker Compose:**
```bash
docker-compose up              # Start services (foreground)
docker-compose up -d           # Start services (background)
docker-compose down            # Stop and remove containers
docker-compose down -v         # Stop and remove volumes too
docker-compose logs -f         # Follow logs
docker-compose logs -f app     # Follow logs for specific service
docker-compose ps              # List running services
docker-compose exec app sh     # Open shell in container
docker-compose restart app     # Restart specific service
```

**Docker:**
```bash
docker ps                      # List running containers
docker ps -a                   # List all containers
docker images                  # List images
docker system prune            # Clean up unused resources
docker system prune -a         # Clean up everything unused
```

**Database:**
```bash
# Connect to PostgreSQL
psql postgresql://dev:dev@localhost:5432/myapp

# Or use docker-compose
docker-compose exec postgres psql -U dev -d myapp
```

## Troubleshooting

**Permission denied accessing Docker:**
Make sure your user is in the `docker` group:
```bash
groups $USER  # Should show 'docker'
```

If not, add it in your NixOS config and rebuild.

**Port already in use:**
```bash
# Find what's using the port
sudo netstat -tulpn | grep :3000

# Or change the port in docker-compose.yml
ports:
  - "3001:3000"
```

**Clean up Docker resources:**
```bash
docker system df               # Check disk usage
docker system prune -a --volumes  # Clean everything (careful!)
```

## Customization

Edit `~/nixos/templates/docker/default.nix` to add tools like:
- `mongodb` - MongoDB client
- `redis` - Redis CLI
- `mysql80` - MySQL client
- `k9s` - Kubernetes CLI (if using k8s)

Then rebuild:
```bash
cd ~/nixos
sudo nixos-rebuild switch --flake .
```
