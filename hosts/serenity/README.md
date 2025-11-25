# Serenity Server Documentation

This document provides setup and maintenance instructions for the Serenity homelab server.

## Server Information

- **Hostname**: serenity
- **Static IP**: 192.168.0.243
- **OS**: NixOS
- **Role**: Homelab server with media services, development tools, and automation

## Services Overview

The Serenity server runs various services managed through NixOS modules:

- **VPN/Networking**: Tailscale (secure mesh VPN, exit node)
- **Reverse Proxy**: Caddy (HTTPS with Cloudflare certificates)
- **Authentication**: Tinyauth, Pocket-ID
- **Media**: Immich (photos), Jellyfin, Plex, Mealie (recipes)
- **Development**: Gitea (Git hosting with CI/CD)
- **Monitoring**: Uptime Kuma, Glance Dashboard
- **File Management**: Filebrowser, Nextcloud
- **Downloads**: Deluge with VPN, Sonarr, Radarr, Prowlarr
- **Other**: Crafty (Minecraft), Music Assistant, HyperHDR

## Tailscale Setup

Tailscale provides secure, encrypted mesh VPN connectivity between all your devices. The Serenity server is configured as an exit node, allowing you to route all your internet traffic through your home network from anywhere.

### Service Configuration

- **Exit Node**: Enabled (routes internet traffic through Serenity)
- **Subnet Routes**: Advertises 192.168.0.0/24 (entire home network accessible via Tailscale)
- **Tailscale SSH**: Enabled (secure SSH access without exposing port 22)
- **Routing Features**: "both" (client and server capabilities)
- **Firewall**: UDP port 41641, trusted tailscale0 interface

### Initial Setup

#### 1. Generate Tailscale Auth Key

Before first deployment, generate an auth key from your Tailscale admin console:

1. Visit [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Click **Generate auth key**
3. Choose settings:
   - **Reusable**: Yes (allows re-registration)
   - **Ephemeral**: No (persistent node)
   - **Pre-authorized**: Yes (auto-approve)
   - **Tags**: Optional (e.g., `tag:server`)
4. Copy the generated key

#### 2. Add SOPS Secret

Add the auth key to your encrypted secrets:

```bash
sops secrets/secrets.yaml
```

Add this entry:
```yaml
tailscale:
  auth_key: "tskey-auth-XXXXXXXXXX"
```

#### 3. Deploy Configuration

The Tailscale service is already enabled in the configuration:

```bash
sudo nixos-rebuild switch --flake .#serenity
```

#### 4. Approve Exit Node (First Time Only)

After the first deployment:

1. Visit [Tailscale Admin Console](https://login.tailscale.com/admin/machines)
2. Find the "serenity" machine
3. Click **Edit route settings**
4. Approve the exit node and subnet routes

### Usage

#### Connect to Exit Node

From any device on your Tailnet:

```bash
# Use Serenity as exit node (routes all traffic through Serenity)
tailscale up --exit-node=serenity

# Stop using exit node
tailscale up --exit-node=
```

On mobile devices:
1. Open Tailscale app
2. Tap on your device name
3. Select **Use exit node** → **serenity**

#### Access Home Network Devices

With subnet routes enabled, you can access any device on your home network (192.168.0.0/24):

```bash
# Access router
ping 192.168.0.1

# Access other devices by IP
ssh user@192.168.0.x

# Access Serenity directly via Tailscale IP
ssh serenity@100.x.x.x  # Tailscale assigns 100.x.x.x addresses
```

#### SSH via Tailscale

Tailscale SSH is enabled, providing secure SSH access without exposing port 22:

```bash
# SSH using Tailscale (no port forwarding needed)
ssh serenity@serenity

# Or use the Tailscale IP
ssh serenity@100.x.x.x
```

Configure SSH ACLs in the [Tailscale Admin Console](https://login.tailscale.com/admin/acls) to control who can SSH into Serenity.

#### Check Tailscale Status

```bash
# View Tailscale status and IPs
sudo tailscale status

# View current exit node
sudo tailscale status | grep exit

# List available exit nodes
sudo tailscale exit-node list

# Check connection quality
sudo tailscale ping serenity
```

### Configuration Options

The Tailscale module is highly configurable. Current settings in `hosts/serenity/configuration.nix`:

```nix
tailscale = {
  enable = true;
  advertiseExitNode = true;           # Act as exit node
  useRoutingFeatures = "both";        # Client + server routing
  enableSsh = true;                   # Tailscale SSH
  acceptRoutes = false;               # Don't accept routes from others
  extraUpFlags = [
    "--advertise-routes=192.168.0.0/24"  # Share home network
  ];
};
```

Available options:
- `advertiseExitNode` - Advertise as exit node (default: false)
- `useRoutingFeatures` - "none", "client", "server", or "both" (default: "server")
- `acceptRoutes` - Accept routes from other nodes (default: false)
- `enableSsh` - Enable Tailscale SSH (default: true)
- `openFirewall` - Open UDP port 41641 (default: true)
- `extraUpFlags` - Additional `tailscale up` flags
- `extraSetFlags` - Additional `tailscale set` flags

### Maintenance

#### Check Service Status

```bash
# Tailscale daemon status
systemctl status tailscaled

# View Tailscale logs
journalctl -u tailscaled -f

# Check IP forwarding (should be enabled)
sysctl net.ipv4.ip_forward
sysctl net.ipv6.conf.all.forwarding
```

#### Update Auth Key

If you need to rotate the auth key:

```bash
# Edit secrets
sops secrets/secrets.yaml
# Update tailscale.auth_key

# Rebuild to apply
sudo nixos-rebuild switch --flake .#serenity
```

#### Network Performance

```bash
# Test Tailscale connection speed to another node
sudo tailscale ping another-node

# View Tailscale routes
ip route | grep tailscale

# Check network interfaces
ip addr show tailscale0
```

### Troubleshooting

#### Cannot connect to Tailscale

1. Check service is running: `systemctl status tailscaled`
2. Verify auth key is valid in SOPS secrets
3. Check logs: `journalctl -u tailscaled -n 50`
4. Ensure firewall allows UDP 41641 (auto-configured)

#### Exit node not working

1. Verify exit node is approved in Tailscale admin console
2. Check IP forwarding: `sysctl net.ipv4.ip_forward` (should be 1)
3. Verify routing features: `systemctl cat tailscaled | grep useRoutingFeatures`
4. Check for exit node advertisement: `sudo tailscale status`

#### Cannot access subnet routes

1. Verify routes are approved in Tailscale admin console
2. Check advertised routes: `sudo tailscale status`
3. On client, ensure accepting routes: `tailscale up --accept-routes`
4. Verify network connectivity: `ping 192.168.0.1` from Tailscale client

#### Tailscale SSH not working

1. Verify SSH is enabled: `sudo tailscale status | grep ssh`
2. Check Tailscale ACLs allow SSH access
3. Test connection: `tailscale ssh serenity@serenity`
4. Check logs: `journalctl -u tailscaled -f`

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
- **Age key**: `/home/serenity/.config/sops/age/keys.txt`

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
- 41641/UDP - Tailscale
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
- [Tailscale Documentation](https://tailscale.com/kb/)
- [Tailscale Exit Nodes](https://tailscale.com/kb/1103/exit-nodes/)
- [Tailscale Subnet Routers](https://tailscale.com/kb/1019/subnets/)
- [Gitea Documentation](https://docs.gitea.io/)
- [Gitea Actions](https://docs.gitea.io/en-us/actions/)
- Repository CLAUDE.md for general development guidelines
