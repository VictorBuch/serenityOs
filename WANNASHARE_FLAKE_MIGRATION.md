# WannaShare Flake Migration Guide

Migrate the WannaShare NixOS service module from a local definition in serenityOs
to an external Nix flake in the WannaShare project repo. This allows the team to
update the service definition without SSH access to the server.

## Overview

| Component | Before | After |
|---|---|---|
| Module definition | `modules/homelab/services/wannashare.nix` | WannaShare project repo `nix/module.nix` |
| How serenityOs gets it | Local file import | Flake input (`inputs.wannashare`) |
| Updating the service | SSH + edit nix file + rebuild | Push to WannaShare repo + `nix flake lock --update-input wannashare` |

## Part 1: WannaShare Project Repo Changes

### 1a. Create `flake.nix` in the WannaShare project root

```nix
{
  description = "WannaShare PocketBase backend service";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    # NixOS module for deploying WannaShare as a systemd service
    nixosModules.default = import ./nix/module.nix;
    nixosModules.wannashare = import ./nix/module.nix;
  };
}
```

### 1b. Create `nix/module.nix` in the WannaShare project

This is the exact content from the current `modules/homelab/services/wannashare.nix`:

```nix
{
  config,
  pkgs,
  lib,
  ...
}:

let
  dataDir = "/var/lib/wannashare";
  user = "wannashare";
  group = "wannashare";
  port = 8099;
in
{
  options.wannashare.enable = lib.mkEnableOption "Enables WannaShare PocketBase backend";

  config = lib.mkIf config.wannashare.enable {

    environment.systemPackages = with pkgs; [
      go
    ];

    users.users.wanna-share-releaser = {
      isNormalUser = true;
      group = "wanna-share-releaser";
      description = "WannaShare Deployment User";
      shell = pkgs.bashInteractive;
      extraGroups = [ "wannashare" "docker" ];
    };
    users.groups.wanna-share-releaser = { };

    security.sudo.extraRules = [
      {
        users = [ "wanna-share-releaser" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/systemctl stop wannashare";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemctl start wannashare";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/install -m 640 -o wannashare -g wannashare /tmp/firebase-credentials.json /var/lib/wannashare/firebase-credentials.json";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/rm -f /tmp/firebase-credentials.json";
            options = [ "NOPASSWD" ];
          }
        ];
      }
      {
        users = [ "gitea-runner" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/systemctl stop wannashare";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemctl start wannashare";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/mv /tmp/wannashare-new /var/lib/wannashare/wannashare-backend";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/chmod +x /var/lib/wannashare/wannashare-backend";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/rm -rf /var/lib/wannashare/web";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/mv /tmp/wannashare-web-new /var/lib/wannashare/web";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    users.groups.${group} = { };
    users.users.${user} = {
      isSystemUser = true;
      group = group;
      home = dataDir;
    };

    users.users.caddy.extraGroups = [ "wannashare" ];

    systemd.tmpfiles.rules = [
      "d ${dataDir} 0770 ${user} ${group}"
      "d ${dataDir}/pb_data 0750 ${user} ${group}"
    ];

    systemd.services.wannashare = {
      description = "WannaShare PocketBase Backend";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = user;
        Group = group;
        WorkingDirectory = dataDir;
        ExecStart = "${dataDir}/wannashare-backend serve --http=127.0.0.1:${toString port}";

        # Hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ dataDir ];
      };
    };
  };
}
```

### 1c. Commit and push

```bash
cd /path/to/wannashare-project
git add flake.nix nix/module.nix
git commit -m "Add NixOS flake module for WannaShare service deployment"
git push
```

## Part 2: serenityOs Changes

### 2a. Add wannashare flake input to `flake.nix`

Add this to the `inputs` block (after `llm-agents`):

```nix
    # WannaShare service (external flake from project repo)
    wannashare = {
      url = "github:your-org/wannashare";  # TODO: Update with actual repo URL
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

**URL format reference:**
- GitHub: `"github:<org>/<repo>"`
- GitHub private (SSH): `"git+ssh://git@github.com/<org>/<repo>.git"`
- Gitea (HTTPS): `"git+https://your-gitea.com/<org>/wannashare.git"`
- Gitea (SSH): `"git+ssh://git@your-gitea.com/<org>/wannashare.git"`
- Local (dev only): `"path:/home/you/wannashare-project"`

### 2b. Add the module to serenity's extraModules in `flake.nix`

Change the serenity host definition:

```diff
         {
           name = "serenity";
           extraModules = [
             ./modules/homelab
+            inputs.wannashare.nixosModules.default
           ];
         }
```

### 2c. Remove local module from `modules/homelab/default.nix`

Remove these two lines:

```diff
   imports = [
     ...
-    ./services/wannashare.nix
     ...
   ];

   ...
-  wannashare.enable = lib.mkDefault false;
```

### 2d. Delete the local module file

```bash
rm modules/homelab/services/wannashare.nix
```

### 2e. Lock the new input and rebuild

```bash
cd ~/serenityOs
git add -A
nix flake lock
sudo nixos-rebuild switch --flake .#serenity
```

## What stays in serenityOs

These items are deployment-specific and remain in serenityOs:

- **`hosts/serenity/configuration.nix`**: `wannashare.enable = true;` -- unchanged
- **`modules/homelab/services/caddy.nix`**: Caddy reverse proxy config for
  `db-wannashare.smoothless.org`, `wannashare.smoothless.org`, and `suboptimal.smoothless.org`
- **Sops secrets in `caddy.nix`**: SSL certs for `*.smoothless.org`
  (`cloudflare/wannashare/ssl/origin_certificate` and `origin_private_key`)

## FAQ

### Does the WannaShare repo need to be public?

No. The machine running `nix flake update` just needs git access (SSH key or
token) to fetch it. Since Gitea runs on serenity itself, localhost access works.

### How do I update the service after making changes?

```bash
# In the WannaShare project repo:
git commit -am "Update service config"
git push

# In serenityOs:
nix flake lock --update-input wannashare
sudo nixos-rebuild switch --flake .#serenity
```

### What about sops secrets?

The `wannashare.nix` module itself does NOT use sops secrets directly. The SSL
certificates for wannashare subdomains are managed by `caddy.nix` in serenityOs,
which is the correct separation -- the WannaShare flake defines "how to run
WannaShare" while serenityOs defines "how it's exposed to the network."

### Can I test locally before pushing?

Yes, use a local path input during development:

```nix
wannashare = {
  url = "path:/home/you/wannashare-project";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Then switch back to the remote URL before committing.
