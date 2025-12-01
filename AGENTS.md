# AGENTS.md - Guidelines for AI Coding Agents

## Build & Test Commands
```bash
# NixOS: sudo nixos-rebuild switch --flake .#<hostname>
# macOS: darwin-rebuild switch --flake .#<hostname>  
# Check: nix flake check
# Test without switching: nixos-rebuild build --flake .
# Test single package: nix-shell -p <packageName>
```

## Code Style & Conventions
- **Indentation**: 2 spaces for Nix files
- **Module Pattern**: Use `mkApp`/`mkHomeModule` helpers, NOT manual modules
- **Critical**: Home modules MUST use `args@{...}: ... } args` pattern
- **Naming**: lowercase-hyphen.nix files, camelCase vars, dot.notation.options
- **Imports**: Group by category (system/apps/home), sort alphabetically
- **Platform**: Use `isLinux` param for cross-platform; handle at import level
- **Enable Options**: Every module needs `<category>.<name>.enable` option

## Module Placement
- `modules/apps/`: System-wide applications (use mkApp helper)
- `home/`: User configs & dotfiles (use mkHomeModule helper)  
- `modules/homelab/`: Serenity server services ONLY

## Important Rules
- Git add ALL new files before testing (flakes only see tracked files)
- NEVER use docker commands on serenity - use `systemctl restart docker-<service>`
- Use helper scripts: `./scripts/add-package.sh` for new packages
- Test with `nix flake check` before any commits

## PostgreSQL Database Recreation
When manually dropping PostgreSQL databases/users, NixOS won't automatically recreate them because `postgresql-setup.service` is a oneshot that already ran. To force recreation:
```bash
# Force PostgreSQL to re-run setup scripts
sudo systemctl restart postgresql-setup.service
# Then restart the dependent service
sudo systemctl start <service-name>
```
This is needed after manually running `DROP DATABASE` or `DROP USER` commands.

## Paperless-ngx Troubleshooting
If paperless services fail after database reset with "relation auth_user does not exist":
```bash
# Run migrations manually first
sudo paperless-manage migrate
# Then start the services
sudo systemctl reset-failed paperless-scheduler
sudo systemctl start paperless-scheduler
```
The `paperless-manage` command is available system-wide for Django management tasks:
- `sudo paperless-manage migrate` - Run database migrations
- `sudo paperless-manage createsuperuser` - Create admin user interactively
- `sudo paperless-manage changepassword <username>` - Reset user password