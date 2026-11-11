# serenityOs

Personal NixOS / nix-darwin flake for my machines.

| Host  | Platform              | Role                                   |
| ----- | --------------------- | -------------------------------------- |
| jayne | NixOS, x86_64         | Desktop workstation                    |
| mal   | NixOS, x86_64         | Homelab server (192.168.0.243)         |
| wash  | NixOS, x86_64         | Public VPS running Pangolin            |
| inara | nix-darwin, aarch64   | MacBook                                |

## Install

New machines are installed with nixos-anywhere + disko: see
[docs/onboarding.md](docs/onboarding.md).

## Rebuild

```bash
nh os switch          # NixOS
nh darwin switch      # macOS
```

## More

- [CLAUDE.md](CLAUDE.md): repository layout, how hosts are built, adding apps
- [hosts/mal/README.md](hosts/mal/README.md): homelab operations
- [modules/homelab/STORAGE.md](modules/homelab/STORAGE.md): storage pool commands
- [docs/yubikey.md](docs/yubikey.md): YubiKey and sops setup
