# Onboarding a new machine

Primary path: install a new NixOS host from your laptop using
[nixos-anywhere](https://github.com/nix-community/nixos-anywhere) and
[disko](https://github.com/nix-community/disko).

No custom ISO. No manual partitioning. One command.

## Prerequisites

- A target machine booted into any Linux with SSH reachable as `root` (the
  official NixOS minimal ISO is the easiest option, Hetzner rescue mode
  also works).
- The target's IP address, reachable from your laptop.
- This repo cloned locally.

## One-time: define the new host

Say you want to install a host called `mal` on an x86_64 machine with an
NVMe disk.

1. Create the host directory:

   ```
   mkdir -p hosts/mal
   ```

2. Write `hosts/mal/configuration.nix`:

   ```nix
   {
     config,
     pkgs,
     inputs,
     pkgs-stable,
     ...
   }:
   let
     username = "mal";
   in
   {
     imports = [
       ./hardware-configuration.nix
       ./disko.nix
       ../profiles/shepherd.nix
       inputs.home-manager.nixosModules.default
     ];

     networking.hostName = "mal";
     user.userName = username;

     home-manager = {
       extraSpecialArgs = { inherit username; };
       users."${username}" = import ../../home/default.nix;
     };

     system.stateVersion = "25.05";
   }
   ```

3. Write `hosts/mal/disko.nix` (pick the right disk device for the target):

   ```nix
   (import ../profiles/disko-btrfs.nix { device = "/dev/nvme0n1"; })
   ```

   Common device paths:

   - NVMe SSD: `/dev/nvme0n1`
   - SATA SSD / HDD: `/dev/sda`
   - SD card (Raspberry Pi etc.): `/dev/mmcblk0`
   - Virtio (QEMU/KVM): `/dev/vda`

4. Register the host in `flake.nix` by adding an entry to `nixosHosts`:

   ```nix
   {
     name = "mal";
     extraModules = [
       (import-tree ./modules/nixos)
       inputs.disko.nixosModules.disko
     ];
   }
   ```

   For ARM hosts also set `system = "aarch64-linux";`.

5. `git add hosts/mal flake.nix` (flakes only see Git-tracked files).

## Seed the sops age key (hosts that use sops-nix only)

If the host will use `sops-nix` for secrets (e.g., the `serenity` homelab
profile), its age key must exist on disk before the first boot, otherwise
activation fails when services try to decrypt secrets.

The pattern: build a small staging directory on your laptop that mirrors
the target's filesystem layout, drop the age key in the right place,
and hand it to nixos-anywhere via `--extra-files`.

1. Generate a fresh age key for the new host (on your laptop):

   ```
   nix shell nixpkgs#age -c age-keygen -o /tmp/mal-age.key
   ```

   Note the public key printed on stderr — you'll add it to `.sops.yaml`
   in step 3.

2. Stage the key at the path the host's sops config expects. For
   system-level keys (readable before any user exists) the convention is
   `/var/lib/sops-nix/key.txt`:

   ```
   mkdir -p /tmp/mal-extra-files/var/lib/sops-nix
   cp /tmp/mal-age.key /tmp/mal-extra-files/var/lib/sops-nix/key.txt
   chmod 600 /tmp/mal-extra-files/var/lib/sops-nix/key.txt
   ```

   Confirm the host's sops config points at the same path:

   ```nix
   sops.age.keyFile = "/var/lib/sops-nix/key.txt";
   ```

3. Add the new host's age public key to `.sops.yaml` under
   `creation_rules`, then re-encrypt every secret file that this host
   needs to read:

   ```
   sops updatekeys secrets/secrets.yaml
   ```

4. Commit the `.sops.yaml` + re-encrypted secrets before running the
   install.

5. After install, shred the staging copy:

   ```
   shred -u /tmp/mal-age.key /tmp/mal-extra-files/var/lib/sops-nix/key.txt
   ```

For hosts that don't use sops (shepherd-derived defaults), skip this
section entirely — `--extra-files` is optional.

## Install

From your laptop, with the target booted into a Linux environment with
SSH:

```
nix run github:nix-community/nixos-anywhere -- \
  --flake .#mal \
  --generate-hardware-config nixos-generate-config \
    hosts/mal/hardware-configuration.nix \
  --extra-files /tmp/mal-extra-files \
  root@192.168.x.y
```

Drop the `--extra-files` line if the host doesn't use sops.

What happens:

1. nixos-anywhere SSHes into the target.
2. Runs `nixos-generate-config` on the target, writes the result into
   `hosts/mal/hardware-configuration.nix` locally.
3. Wipes the target disk and partitions it per `hosts/mal/disko.nix`.
4. Copies `--extra-files` contents into the target's root filesystem
   (so the age key lands at `/var/lib/sops-nix/key.txt`).
5. Builds the shepherd-derived configuration and installs it.
6. Reboots the target.

Total time: ~5 to 15 minutes on mid-spec hardware.

## After install

1. Commit the auto-generated `hardware-configuration.nix`:
   `git add hosts/mal/hardware-configuration.nix && git commit`.
2. SSH into the new machine as the target user.
3. Set the user password: `sudo passwd mal`.
4. Future rebuilds from the machine itself: `sudo nixos-rebuild switch --flake .#mal`.

## Fallback: `install.sh`

`install.sh` is kept for cases where nixos-anywhere isn't an option (no
network access, no secondary machine, etc.). It expects you to have
booted into NixOS, partitioned disks by hand, and cloned this repo onto
the target. See the script itself for details.

## Notes

- `hosts/profiles/shepherd.nix` is the reusable base profile. Edit it to
  change defaults for all shepherd-derived hosts (locale, desktop env,
  base apps).
- `hosts/profiles/disko-btrfs.nix` defines the shared btrfs layout with
  `@` / `@home` / `@nix` / `@log` subvolumes. Per-host `disko.nix` only
  overrides the device path.
- Secrets (sops-nix) are seeded via `--extra-files` during install —
  see the "Seed the sops age key" section above. The age key must
  live where the host's `sops.age.keyFile` points.
- Alternative to pre-generated keys: derive the age identity from the
  host's SSH host key (`ssh-to-age`) and use nixos-anywhere's
  `--copy-host-keys` flag to preserve the installer's SSH keys through
  to the installed system. Set `sops.age.sshKeyPaths = [
  "/etc/ssh/ssh_host_ed25519_key" ]` on the host. Avoids managing a
  separate age keyfile per machine.
