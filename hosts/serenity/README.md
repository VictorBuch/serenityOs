# Serenity Server Documentation

This document provides setup and maintenance instructions for the Serenity homelab server.

## Server Information

- **Hostname**: serenity
- **Static IP**: 192.168.0.243
- **OS**: NixOS
- **Role**: Homelab server with media services, development tools, and automation

## Services Overview

The Serenity server runs various services managed through NixOS modules:

- **Reverse Proxy**: Caddy (HTTPS with Cloudflare certificates)
- **Authentication**: Tinyauth, Pocket-ID
- **Media**: Immich (photos), Jellyfin, Plex, Mealie (recipes)
- **Development**: Gitea (Git hosting with CI/CD)
- **Monitoring**: Uptime Kuma, Glance Dashboard
- **File Management**: Filebrowser, Nextcloud
- **Downloads**: Deluge with VPN, Sonarr, Radarr, Prowlarr
- **Other**: Crafty (Minecraft), Music Assistant, HyperHDR

## Gitea Setup

Gitea provides self-hosted Git repository hosting with CI/CD capabilities through Gitea Actions.

### Service Configuration

- **Web UI**: `https://git.victorbuch.com`
- **SSH Port**: 2222
- **Database**: PostgreSQL
- **Features**: Git LFS, Gitea Actions (CI/CD)
- **Runners**: 2 instances (docker-runner, nix-runner)

### Initial Setup

#### 1. Add SOPS Secret

Before first deployment, add the runner token placeholder to your secrets:

```bash
sops secrets/secrets.yaml
```

Add this entry:
```yaml
gitea:
  runner_token: "placeholder-will-be-replaced-after-setup"
```

#### 2. Deploy Configuration

```bash
sudo nixos-rebuild switch --flake .#serenity
```

#### 3. Complete Web Setup

1. Visit `https://git.victorbuch.com`
2. The database configuration is pre-configured (PostgreSQL)
3. Create your admin account
4. Complete the initial setup wizard

#### 4. Generate Runner Token

To enable CI/CD runners:

1. Log into Gitea as admin
2. Navigate to **Site Administration** → **Actions** → **Runners**
3. Click **Create new Runner**
4. Copy the registration token
5. Update your SOPS secret:
   ```bash
   sops secrets/secrets.yaml
   # Replace the placeholder with the real token
   ```
6. Rebuild to activate runners:
   ```bash
   sudo nixos-rebuild switch --flake .#serenity
   ```

### Usage

#### Git Operations

**Clone via SSH:**
```bash
git clone ssh://git@git.victorbuch.com:2222/username/repo.git
```

**Clone via HTTPS:**
```bash
git clone https://git.victorbuch.com/username/repo.git
```

**Add remote:**
```bash
git remote add origin ssh://git@git.victorbuch.com:2222/username/repo.git
```

#### CI/CD with Gitea Actions

Create `.gitea/workflows/build.yml` in your repository:

```yaml
name: Build
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: |
          echo "Building project..."
          # Your build commands here
```

Available runner labels:
- `ubuntu-latest` - Docker runner with Node.js 20
- `docker` - Generic Docker runner
- `nix` - Native Nix runner for Nix builds

#### Git LFS (Large File Storage)

For repositories with large binary files:

```bash
# Initialize LFS in your repo
git lfs install

# Track file types
git lfs track "*.psd"
git lfs track "*.mp4"

# Commit and push
git add .gitattributes
git commit -m "Enable LFS"
git push
```

### Maintenance

#### Check Service Status

```bash
# Gitea main service
systemctl status gitea

# PostgreSQL database
systemctl status postgresql

# Docker runner
systemctl status gitea-runner-docker

# Nix runner
systemctl status gitea-runner-nix
```

#### View Logs

```bash
# Gitea logs
journalctl -u gitea -f

# Runner logs
journalctl -u gitea-runner-docker -f
journalctl -u gitea-runner-nix -f
```

#### Backup

Gitea data is stored in `/var/lib/gitea/`. Regular backups include:
- Repositories: `/var/lib/gitea/repositories/`
- LFS files: `/var/lib/gitea/data/lfs/`
- Database: PostgreSQL database `gitea`

To create a manual backup:
```bash
sudo -u postgres pg_dump gitea > gitea-backup.sql
sudo tar -czf gitea-repos-backup.tar.gz /var/lib/gitea/repositories
```

### Troubleshooting

#### Runners not appearing

1. Check runner token is correctly set in SOPS
2. Verify runner services are running
3. Check logs for registration errors

#### SSH connection refused

1. Verify port 2222 is open in firewall (handled automatically by module)
2. Test connection: `ssh -T -p 2222 git@git.victorbuch.com`
3. Check Gitea SSH service: `systemctl status gitea`

#### Database connection issues

1. Check PostgreSQL is running: `systemctl status postgresql`
2. Verify database exists: `sudo -u postgres psql -l | grep gitea`
3. Check Gitea logs: `journalctl -u gitea -n 50`

## General Server Maintenance

### System Updates

The Serenity server has automatic updates enabled:
- **Schedule**: Daily at 02:00
- **Garbage Collection**: Weekly (keeps last 10 days)

### Manual Operations

```bash
# Rebuild configuration
sudo nixos-rebuild switch --flake .#serenity

# Update flake inputs
nix flake update

# Run garbage collection
nix-collect-garbage -d

# Check system status
systemctl status
```

### NFS Mounts

The server mounts storage from TrueNAS (192.168.0.249):
- `/mnt/data` - Media files
- `/mnt/immich` - Immich photos
- `/mnt/nextcloud` - Nextcloud data

All critical services wait for NFS mounts via `nfs-mounts-ready.target`.

### Secrets Management

Secrets are managed with SOPS and age encryption:
- **Secrets file**: `secrets/secrets.yaml`
- **Age key**: `/home/ghost/.config/sops/age/keys.txt`

Edit secrets:
```bash
sops secrets/secrets.yaml
```

### Docker Containers

Some services run as Docker containers managed by systemd:
- **Naming**: `docker-<serviceName>`
- **Control**: Use systemd commands, not docker CLI
  ```bash
  systemctl status docker-uptime-kuma
  systemctl restart docker-crafty
  ```

### Firewall

Ports are managed per-service in NixOS configuration. Currently open:
- 22 - SSH
- 80/443 - Caddy (HTTP/HTTPS)
- 2222 - Gitea SSH
- 2283 - Immich
- Various internal service ports

### Monitoring

- **Uptime Kuma**: Service availability monitoring at `status.victorbuch.com`
- **Glance Dashboard**: Service overview at `dashboard.victorbuch.com`
- **System logs**: `journalctl -f`

## Useful Commands

```bash
# Check all running services
systemctl list-units --type=service --state=running

# Check failed services
systemctl --failed

# Check NFS mount status
mount | grep nfs

# Check disk usage
df -h

# Check memory usage
free -h

# Check network status
ip addr show
ss -tulpn
```

## Configuration Files

- **Host config**: `hosts/serenity/configuration.nix`
- **Hardware config**: `hosts/serenity/hardware-configuration.nix`
- **Homelab modules**: `modules/homelab/`
- **Secrets**: `secrets/secrets.yaml` (encrypted)

## References

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Gitea Documentation](https://docs.gitea.io/)
- [Gitea Actions](https://docs.gitea.io/en-us/actions/)
- Repository CLAUDE.md for general development guidelines
