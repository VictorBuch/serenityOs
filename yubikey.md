# YubiKey 5C Nano Integration Plan

## Summary

Transform your YubiKey 5C Nano into a central security key across your fleet: FIDO2 SSH authentication, touch-to-sudo, YubiKey-backed sops-nix secrets on all hosts, git commit signing, screen locking, and more.

---

## Phase 1: YubiKey Initial Setup (Manual, one-time)

These steps happen on `jayne` (your primary machine) with the YubiKey plugged in, **before** any Nix changes.

### 1a. Set FIDO2 PIN on YubiKey

```bash
nix-shell -p yubikey-manager
ykman fido access change-pin  # Set a strong FIDO2 PIN
```

### 1b. Generate FIDO2 SSH Key (resident, on-device)

```bash
ssh-keygen -t ed25519-sk -O resident -O verify-required -C "jayne@yubikey-5c-nano"
# Saves handle to ~/.ssh/id_ed25519_sk (this is just a reference, not the private key)
# The actual private key never leaves the YubiKey
```

### 1c. Register YubiKey for PAM U2F

```bash
nix-shell -p pam_u2f
mkdir -p ~/.config/Yubico
pamu2fcfg -o pam://serenityOs -i pam://serenityOs > ~/.config/Yubico/u2f_keys
# Uses a fixed origin/appid so the same registration works across all machines
```

### 1d. Set up age-plugin-yubikey for sops

```bash
nix-shell -p age-plugin-yubikey
age-plugin-yubikey  # Generates a new age identity tied to the YubiKey PIV slot
# Outputs a recipient string like: age1yubikey1q...
# Save this - you'll add it to .sops.yaml
```

### 1e. Copy registrations to other machines

- The `~/.config/Yubico/u2f_keys` file needs to be on each machine (can be managed via home-manager or sops)
- The SSH public key (`~/.ssh/id_ed25519_sk.pub`) goes into `authorized_keys` on serenity
- On new machines, recover the resident SSH key with `ssh-keygen -K`

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

The `/etc/u2f-mappings` file will be deployed via `environment.etc` with contents from sops or directly from the u2f_keys data.

### 2c. SSH hardening on serenity: `hosts/serenity/configuration.nix`

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
  # Your FIDO2 SSH public key (from step 1b)
  "sk-ssh-ed25519@openssh.com AAAA... jayne@yubikey-5c-nano"
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

### 3a. Update `.sops.yaml` with new keys

```yaml
keys:
  - &primary age1zteescyshskm3n35s23875vjj2358zkejtcyxaeah5p46q4xk5qqjq2nzt
  - &yubikey age1yubikey1q...   # YubiKey-backed age key

creation_rules:
  - path_regex: secrets/secrets.yaml$
    key_groups:
      - age:
          - *primary
          - *yubikey

  # Host-specific secrets (optional, for per-host secret files)
  - path_regex: secrets/jayne\.yaml$
    key_groups:
      - age:
          - *primary
          - *yubikey

  - path_regex: secrets/inara\.yaml$
    key_groups:
      - age:
          - *primary
          - *yubikey
```

### 3b. Add secrets for jayne and inara

Add to `secrets/secrets.yaml` (or create per-host files):

- `ssh/authorized_keys` - Your FIDO2 public key
- `tailscale/jayne_auth_key` - Tailscale auth key for jayne
- `tailscale/inara_auth_key` - Tailscale auth key for inara
- `u2f/mappings` - The U2F key registration data

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

### 3e. Re-encrypt secrets with new key

```bash
# After updating .sops.yaml with the YubiKey age recipient:
sops updatekeys secrets/secrets.yaml
# This adds the YubiKey as a decryption recipient
```

---

## Phase 4: Additional YubiKey Capabilities

### 4a. Git commit signing with SSH key

Since you're using FIDO2 SSH keys, you can also sign git commits with them (no GPG needed):

```nix
# In home/cli/git.nix, add:
programs.git = {
  signing = {
    key = "~/.ssh/id_ed25519_sk.pub";
    signByDefault = true;
    format = "ssh";
  };
  extraConfig.gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";
};
```

### 4b. OATH/TOTP codes on YubiKey

Your YubiKey 5C Nano can store TOTP codes (like Google Authenticator) directly on the hardware:

```bash
# Store TOTP secrets on YubiKey instead of a phone app
ykman oath accounts add -t GitHub <secret>
ykman oath accounts code GitHub  # Touch to get code
```

Install `yubioath-flutter` for a GUI, or use `ykman oath` CLI.

### 4c. WebAuthn/Passkeys for web services

The YubiKey already works as a FIDO2 authenticator for websites. Consider registering it as a passkey for:

- GitHub, GitLab, Gitea (your self-hosted instance)
- Google, Microsoft, Cloudflare
- Any service supporting WebAuthn

This is browser-native, no NixOS config needed.

### 4d. Disk encryption unlock (future)

Your YubiKey can be used to unlock LUKS-encrypted drives at boot via `systemd-cryptenroll`:

```bash
systemd-cryptenroll /dev/nvme0n1p2 --fido2-device=auto
```

This is more advanced and can be added later.

---

## Phase 5: macOS-Specific (inara)

### 5a. SSH with YubiKey on macOS

macOS needs Homebrew's OpenSSH for FIDO2 support (Apple's bundled version is too old):

```nix
# In homebrew.nix or inara's config:
homebrew.brews = [ "openssh" ];
```

The resident key can be recovered on inara with `ssh-keygen -K`.

### 5b. Touch ID + YubiKey for sudo

You already have Touch ID for sudo on inara. The YubiKey can be an additional option alongside it.

---

## File Changes Summary

| File | Change |
|------|--------|
| `modules/common/yubikey.nix` | **New** - Cross-platform YubiKey packages/services |
| `modules/common/default.nix` | Import `yubikey.nix` |
| `modules/nixos/system/security.nix` | **New** - PAM U2F, sudo with YubiKey, screen lock |
| `modules/nixos/system/default.nix` | Import `security.nix` |
| `hosts/serenity/configuration.nix` | SSH hardening, authorized keys |
| `hosts/jayne/configuration.nix` | sops config, Tailscale |
| `hosts/inara/configuration.nix` | sops config |
| `.sops.yaml` | Add YubiKey age recipient |
| `secrets/secrets.yaml` | Add SSH keys, Tailscale keys, U2F mappings |
| `flake.nix` | Add `sops-nix.darwinModules.sops` to Darwin hosts |
| `home/cli/git.nix` | SSH commit signing |

---

## Implementation Order

1. **Manual**: Set up YubiKey (FIDO2 PIN, SSH key, U2F registration, age identity)
2. **Code**: Create `yubikey.nix` module with packages/udev/pcscd
3. **Code**: Create security module with PAM U2F config
4. **Code**: Harden SSH on serenity + add authorized keys
5. **Code**: Expand sops-nix to jayne, inara, and flake.nix
6. **Code**: Update `.sops.yaml` and re-encrypt secrets
7. **Code**: Add git commit signing config
8. **Code**: Add screen lock udev rule
9. **Test**: Build and switch on jayne first, then serenity, then inara
10. **Manual**: Register YubiKey for web services (GitHub passkey, etc.)

---

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Locked out of sudo if YubiKey lost | `control = "sufficient"` falls back to password |
| Locked out of SSH to serenity | Keep Tailscale SSH as backup path; also keep password auth during transition |
| Can't rebuild without YubiKey for sops | Keep the existing age key file (`&primary`) as a co-recipient |
| macOS OpenSSH doesn't support FIDO2 | Install Homebrew OpenSSH |
| YubiKey PIN forgotten | Document PIN securely; 8 attempts before lockout |

---

## Decisions Made

- **SSH auth method**: FIDO2 `ed25519-sk` (modern, simple, hardware-bound)
- **Sudo mode**: `sufficient` with password fallback (touch YubiKey OR type password)
- **sops decryption**: YubiKey-backed age (touch required during rebuilds)
- **SSH daemon**: Only on serenity (hardened); desktops use Tailscale SSH
- **Backup YubiKey**: Planning to get one; enroll it when acquired
- **Secrets needed**: SSH authorized keys + Tailscale auth keys for jayne and inara
