# YubiKey 5C Nano Integration Plan

## Summary

Transform your two YubiKey 5C Nanos into central security keys across your fleet: FIDO2 SSH authentication, touch-to-sudo, YubiKey-backed sops-nix secrets, git commit signing, screen locking, and more. Each YubiKey is dedicated to one machine -- one for `jayne` (desktop) and one for `inara` (laptop). Hosts without a physical YubiKey (like `mal`) continue using the file-based age key for sops decryption.

---

## Phase 1: YubiKey Initial Setup (Manual, one-time per key)

Each YubiKey must be set up independently. Repeat steps 1a-1d for **both** keys.

### 1a. Set FIDO2 PIN on each YubiKey

**On jayne** (with jayne's YubiKey plugged in):

```bash
nix-shell -p yubikey-manager
ykman fido access change-pin  # Set a strong FIDO2 PIN for jayne's key
```

**On inara** (with inara's YubiKey plugged in):

```bash
nix-shell -p yubikey-manager
ykman fido access change-pin  # Set a strong FIDO2 PIN for inara's key
```

Use different PINs for each key so a compromised PIN doesn't affect both.

### 1b. Generate FIDO2 SSH Key on each YubiKey (resident, on-device)

**On jayne:**

```bash
ssh-keygen -t ed25519-sk -O resident -O verify-required -C "jayne@yubikey-5c-nano"
# Saves handle to ~/.ssh/id_ed25519_sk
# The actual private key never leaves the YubiKey
```

**On inara:**

```bash
ssh-keygen -t ed25519-sk -O resident -O verify-required -C "inara@yubikey-5c-nano"
# Saves handle to ~/.ssh/id_ed25519_sk
# The actual private key never leaves the YubiKey
```

You now have **two** distinct FIDO2 SSH public keys. Both will be added to mal's `authorized_keys`.

### 1c. Register each YubiKey for PAM U2F

**On jayne** (with jayne's YubiKey):

```bash
nix-shell -p pam_u2f
mkdir -p ~/.config/Yubico
pamu2fcfg -o pam://serenityOs -i pam://serenityOs > ~/.config/Yubico/u2f_keys
# Uses a fixed origin/appid so the registration works across all NixOS machines
```

**On inara** (with inara's YubiKey):

```bash
nix-shell -p pam_u2f
mkdir -p ~/.config/Yubico
pamu2fcfg -o pam://serenityOs -i pam://serenityOs > ~/.config/Yubico/u2f_keys
```

**Combining both keys for cross-machine use:**

The U2F mappings file supports multiple keys per user. To allow either YubiKey to authenticate on any NixOS machine, combine both registrations into a single line:

```bash
# Format: <username>:<keydata1>:<keydata2>
# After registering the first key, append the second key's data to the same user line.
# The pamu2fcfg output for each key looks like:
#   jayne:<KeyHandle1>,<UserKey1>,<CoseType1>,<Options1>
# Combine them as:
#   jayne:<KeyHandle1>,<UserKey1>,<CoseType1>,<Options1>:<KeyHandle2>,<UserKey2>,<CoseType2>,<Options2>
```

This combined mapping will be stored in sops and deployed to `/etc/u2f-mappings` via Nix.

### 1d. Set up age-plugin-yubikey for sops (on each key)

**On jayne** (with jayne's YubiKey):

```bash
nix-shell -p age-plugin-yubikey
age-plugin-yubikey  # Generates a new age identity tied to jayne's YubiKey PIV slot
# Outputs a recipient string like: age1yubikey1qJAYNE...
# Save this -- it becomes &yubikey-jayne in .sops.yaml
```

**On inara** (with inara's YubiKey):

```bash
nix-shell -p age-plugin-yubikey
age-plugin-yubikey  # Generates a new age identity tied to inara's YubiKey PIV slot
# Outputs a recipient string like: age1yubikey1qINARA...
# Save this -- it becomes &yubikey-inara in .sops.yaml
```

### 1e. Cross-machine registration

- **U2F mappings**: The combined `u2f_keys` file (with both keys) gets stored in sops and deployed to `/etc/u2f-mappings` on all NixOS hosts.
- **SSH public keys**: Both `id_ed25519_sk.pub` keys go into `authorized_keys` on mal.
- **Resident key recovery**: On a fresh machine (or after reinstall), recover the resident SSH key with `ssh-keygen -K` while the YubiKey for that machine is plugged in.

---

## Phase 2: NixOS Module Changes

### 2a. New shared security module: `modules/common/yubikey.nix`

A cross-platform module that sets up YubiKey support everywhere:

```nix
# What it configures:
- services.udev.packages = [ pkgs.yubikey-personalization ];  # udev rules (Linux)
- services.pcscd.enable = true;                                # Smart card daemon (Linux)
- programs.gnupg.agent.enable = true;                          # GPG agent
- environment.systemPackages = [
    yubikey-manager          # ykman CLI
    yubikey-personalization  # ykinfo
    age-plugin-yubikey       # age encryption with YubiKey
    pam_u2f                  # PAM U2F tools (pamu2fcfg)
    yubikey-touch-detector   # Desktop notification when touch needed
  ];
```

### 2b. PAM U2F for sudo: `modules/nixos/system/` changes

Add to the NixOS system modules (Linux only):

```nix
security.pam.u2f = {
  enable = true;
  control = "sufficient";           # YubiKey touch replaces password
  settings = {
    cue = true;                      # "Please touch your YubiKey" prompt
    origin = "pam://serenityOs";     # Fixed origin for cross-machine compatibility
    appid = "pam://serenityOs";
    authfile = "/etc/u2f-mappings";  # Central auth file managed by Nix/sops
  };
};

security.pam.services = {
  sudo.u2fAuth = true;
  login.u2fAuth = true;
};
```

The `/etc/u2f-mappings` file contains both YubiKey registrations (from step 1c) and is deployed via `environment.etc` with contents from sops. Either YubiKey can authenticate `sudo` on any NixOS machine.

### 2c. SSH hardening on mal: `hosts/mal/configuration.nix`

```nix
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;       # Key-only auth
    PermitRootLogin = "no";               # No root SSH
    KbdInteractiveAuthentication = false;
    PubkeyAuthentication = true;
    AuthenticationMethods = "publickey";
  };
};

users.users.serenity.openssh.authorizedKeys.keys = [
  # Both FIDO2 SSH public keys -- one per YubiKey
  "sk-ssh-ed25519@openssh.com AAAA... jayne@yubikey-5c-nano"
  "sk-ssh-ed25519@openssh.com AAAA... inara@yubikey-5c-nano"
];
```

### 2d. Screen lock on YubiKey removal (jayne/kaylee)

```nix
services.udev.extraRules = ''
  ACTION=="remove",\
   ENV{ID_BUS}=="usb",\
   ENV{ID_MODEL_ID}=="0407",\
   ENV{ID_VENDOR_ID}=="1050",\
   ENV{ID_VENDOR}=="Yubico",\
   RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
'';
```

---

## Phase 3: sops-nix Expansion

### 3a. Update `.sops.yaml` with all keys

Three age recipients -- the file-based key plus one per YubiKey:

```yaml
keys:
  - &primary age1zteescyshskm3n35s23875vjj2358zkejtcyxaeah5p46q4xk5qqjq2nzt
  - &yubikey-jayne age1yubikey1q... # YubiKey on jayne (desktop)
  - &yubikey-inara age1yubikey1q... # YubiKey on inara (laptop)

creation_rules:
  - path_regex: secrets/secrets.yaml$
    key_groups:
      - age:
          - *primary
          - *yubikey-jayne
          - *yubikey-inara

  # Host-specific secrets (optional, for per-host secret files)
  - path_regex: secrets/jayne\.yaml$
    key_groups:
      - age:
          - *primary
          - *yubikey-jayne
          - *yubikey-inara

  - path_regex: secrets/inara\.yaml$
    key_groups:
      - age:
          - *primary
          - *yubikey-jayne
          - *yubikey-inara
```

All three keys are encryption targets. Only **one** is needed to decrypt:

| Host                | Decrypts with                                             |
| ------------------- | --------------------------------------------------------- |
| **mal**             | `&primary` file-based age key                             |
| **jayne**           | jayne's YubiKey touch OR `&primary` (if key file present) |
| **inara**           | inara's YubiKey touch OR `&primary` (if key file present) |
| **kaylee/shepherd** | `&primary` file-based age key                             |

### 3b. Add secrets for jayne and inara

Add to `secrets/secrets.yaml` (or create per-host files):

- `ssh/jayne_authorized_key` - jayne's FIDO2 public key
- `ssh/inara_authorized_key` - inara's FIDO2 public key
- `tailscale/jayne_auth_key` - Tailscale auth key for jayne
- `tailscale/inara_auth_key` - Tailscale auth key for inara
- `u2f/mappings` - Combined U2F key registration data (both keys)

### 3c. Configure sops on jayne host

```nix
# hosts/jayne/configuration.nix
sops = {
  defaultSopsFile = "${inputs.self}/secrets/secrets.yaml";
  defaultSopsFormat = "yaml";
  age.keyFile = "/home/jayne/.config/sops/age/keys.txt";
  # OR for YubiKey-only:
  # age.sshKeyPaths = [];  # Don't use SSH keys
  # Uses age-plugin-yubikey automatically if installed

  secrets = {
    "tailscale/jayne_auth_key" = { mode = "0400"; };
  };
};
```

### 3d. Configure sops on inara (macOS)

This requires adding `sops-nix` to the Darwin configuration in `flake.nix`:

```nix
# In darwinConfigurations modules list, add:
inputs.sops-nix.darwinModules.sops
```

Then in `hosts/inara/configuration.nix`:

```nix
sops = {
  defaultSopsFile = "${inputs.self}/secrets/secrets.yaml";
  defaultSopsFormat = "yaml";
  age.keyFile = "/Users/victorbuch/.config/sops/age/keys.txt";

  secrets = {
    "tailscale/inara_auth_key" = { mode = "0400"; };
  };
};
```

### 3e. Re-encrypt secrets with new keys

```bash
# After updating .sops.yaml with both YubiKey age recipients:
sops updatekeys secrets/secrets.yaml
# This adds both YubiKeys as decryption recipients alongside the primary key
```

---

## Phase 4: Additional YubiKey Capabilities

### 4a. Git commit signing with SSH key

Since each machine has its own FIDO2 SSH key, configure git to use the local key:

```nix
# In home/cli/git.nix, add:
programs.git = {
  signing = {
    key = "~/.ssh/id_ed25519_sk.pub";  # Points to whichever YubiKey's key is on this machine
    signByDefault = true;
    format = "ssh";
  };
  extraConfig.gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";
};
```

The `allowed_signers` file must contain **both** public keys so commits from either machine verify correctly:

```
# ~/.config/git/allowed_signers
jayne@serenityos.dev sk-ssh-ed25519@openssh.com AAAA... jayne@yubikey-5c-nano
jayne@serenityos.dev sk-ssh-ed25519@openssh.com AAAA... inara@yubikey-5c-nano
```

This file can be managed via home-manager and deployed to both machines.

### 4b. OATH/TOTP codes on YubiKey

Your YubiKey 5C Nanos can store TOTP codes (like Google Authenticator) directly on the hardware:

```bash
# Store TOTP secrets on YubiKey instead of a phone app
ykman oath accounts add -t GitHub <secret>
ykman oath accounts code GitHub  # Touch to get code
```

Install `yubioath-flutter` for a GUI, or use `ykman oath` CLI. Each YubiKey stores its own set of OATH credentials, so you may want to register the same TOTP secrets on both keys for services you access from either machine.

### 4c. WebAuthn/Passkeys for web services

Each YubiKey works as a FIDO2 authenticator for websites. Register **both** keys as passkeys for critical services:

- GitHub, GitLab, Gitea (your self-hosted instance)
- Google, Microsoft, Cloudflare
- Any service supporting WebAuthn

Most services allow multiple security keys. Register both so you can log in from either machine. This is browser-native, no NixOS config needed.

### 4d. Disk encryption unlock (future)

Your YubiKeys can be used to unlock LUKS-encrypted drives at boot via `systemd-cryptenroll`:

```bash
systemd-cryptenroll /dev/nvme0n1p2 --fido2-device=auto
```

This is more advanced and can be added later. Only relevant for jayne (NixOS desktop with LUKS).

---

## Phase 5: macOS-Specific (inara)

### 5a. SSH with YubiKey on macOS

macOS needs Homebrew's OpenSSH for FIDO2 support (Apple's bundled version is too old):

```nix
# In homebrew.nix or inara's config:
homebrew.brews = [ "openssh" ];
```

The resident key can be recovered on inara with `ssh-keygen -K` (using inara's YubiKey).

### 5b. Touch ID + YubiKey for sudo

You already have Touch ID for sudo on inara. The YubiKey can be an additional option alongside it. On macOS, either Touch ID or YubiKey touch can authorize `sudo`.

---

## File Changes Summary

| File                                | Change                                                               |
| ----------------------------------- | -------------------------------------------------------------------- |
| `modules/common/yubikey.nix`        | **New** - Cross-platform YubiKey packages/services                   |
| `modules/common/default.nix`        | Import `yubikey.nix`                                                 |
| `modules/nixos/system/security.nix` | **New** - PAM U2F (both keys), sudo with YubiKey, screen lock        |
| `modules/nixos/system/default.nix`  | Import `security.nix`                                                |
| `hosts/mal/configuration.nix`       | SSH hardening, both FIDO2 authorized keys                            |
| `hosts/jayne/configuration.nix`     | sops config, Tailscale                                               |
| `hosts/inara/configuration.nix`     | sops config                                                          |
| `.sops.yaml`                        | Add both YubiKey age recipients (`&yubikey-jayne`, `&yubikey-inara`) |
| `secrets/secrets.yaml`              | Add both SSH keys, Tailscale keys, combined U2F mappings             |
| `flake.nix`                         | Add `sops-nix.darwinModules.sops` to Darwin hosts                    |
| `home/cli/git.nix`                  | SSH commit signing + `allowed_signers` with both keys                |

---

## Implementation Order

1. **Manual**: Set up jayne's YubiKey (FIDO2 PIN, SSH key, U2F registration, age identity)
2. **Manual**: Set up inara's YubiKey (same steps, on inara with its own key)
3. **Manual**: Combine U2F registrations into a single mappings entry
4. **Code**: Create `yubikey.nix` module with packages/udev/pcscd
5. **Code**: Create security module with PAM U2F config (both keys in mappings)
6. **Code**: Harden SSH on mal + add both authorized keys
7. **Code**: Expand sops-nix to jayne, inara, and flake.nix
8. **Code**: Update `.sops.yaml` with both YubiKey recipients and re-encrypt secrets
9. **Code**: Add git commit signing config + shared `allowed_signers`
10. **Code**: Add screen lock udev rule
11. **Test**: Build and switch on jayne first, then mal, then inara
12. **Manual**: Register both YubiKeys for web services (GitHub passkeys, etc.)

---

## Risks & Mitigations

| Risk                                      | Mitigation                                                                                            |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Locked out of sudo if YubiKey lost/broken | `control = "sufficient"` falls back to password                                                       |
| Locked out of SSH to mal                  | Keep Tailscale SSH as backup path; both YubiKeys are authorized; keep password auth during transition |
| Can't rebuild without YubiKey for sops    | `&primary` file-based age key is always a co-recipient on every host                                  |
| One YubiKey lost or damaged               | The other YubiKey + `&primary` key still work; re-enroll a replacement key                            |
| macOS OpenSSH doesn't support FIDO2       | Install Homebrew OpenSSH                                                                              |
| YubiKey PIN forgotten                     | Document PINs securely (separately); 8 attempts before lockout                                        |
| TOTP codes only on one key                | Register same TOTP secrets on both keys for critical services                                         |

---

## Decisions Made

- **Two YubiKeys**: One dedicated to jayne (desktop), one to inara (laptop) -- not shared between machines
- **SSH auth method**: FIDO2 `ed25519-sk` (modern, simple, hardware-bound) -- one key pair per YubiKey
- **Sudo mode**: `sufficient` with password fallback (touch YubiKey OR type password)
- **sops decryption**: Three recipients per secret -- `&primary` (file-based) + both YubiKeys
- **mal sops**: Continues using file-based `&primary` key only (no YubiKey plugged in)
- **SSH daemon**: Only on mal (hardened, both FIDO2 keys authorized); desktops use Tailscale SSH
- **Git signing**: Per-machine key with shared `allowed_signers` containing both public keys
- **Secrets needed**: Both SSH authorized keys + Tailscale auth keys + combined U2F mappings
