# Development Environments

Shared [devenv](https://devenv.sh) modules, imported by projects rather than copied into them.

## The idea

A project does **not** get a copy of the config. It gets a short `devenv.yaml` that
imports modules from this repo:

```yaml
inputs:
  nixpkgs:
    url: github:cachix/devenv-nixpkgs/rolling
  serenity:
    url: github:VictorBuch/serenityOs
    flake: false

imports:
  - serenity/devenvs/modules/base
  - serenity/devenvs/modules/nodejs
```

Consequences:

- **One place to fix things.** Edit `devenvs/modules/nodejs/devenv.nix`, push, and every
  project picks it up on its next `devenv update`.
- **Projects stay pinned.** `devenv.lock` records the exact commit each project fetched, so
  nothing changes under a project until you deliberately update it.
- **Portable.** Unlike a symlink into `~/serenityOs`, this resolves on a teammate's machine
  and in CI — the repo is public and the input is fetched, not linked.

---

# Workflow

## Starting a new project

```bash
npx create-next-app@latest my-app     # scaffold the app first
cd my-app

devenv-init node                       # writes devenv.yaml, devenv.nix, .envrc, .gitignore
direnv allow                           # builds the env, activates it

cmds                                   # see what commands you got
pnpm install
dev
```

Order matters: run the app's own scaffolder first. `create-next-app` and friends refuse to
run in a non-empty directory, and `devenv-init` won't clobber existing files without
`--force`.

Then commit all four files. That is what makes the environment work for anyone else who
clones the project.

## Choosing what to pass

If a preset fits, use it:

| Preset             | Modules                         |
| ------------------ | ------------------------------- |
| `node`             | nodejs                          |
| `vue`              | nodejs, vue-nuxt                |
| `go`               | go                              |
| `docker`           | docker                          |
| `fullstack`        | nodejs, docker, postgres, redis |
| `flutter`          | flutter                         |
| `flutter-appwrite` | flutter, nodejs, appwrite       |
| `work`             | nodejs, docker, work            |

Otherwise compose modules directly:

```bash
devenv-init go,postgres           # Go API with a local database
devenv-init nodejs,docker         # Node app, Docker for services
devenv-init --list                # remind yourself what exists
devenv-init fullstack ~/proj/x    # scaffold somewhere other than the current directory
```

`base` is always included. Adding a module later is just another line under `imports:` in
`devenv.yaml`, followed by `direnv reload`.

## Project-specific configuration

Goes in the project's own `devenv.nix`, which starts empty:

```nix
{ pkgs, lib, ... }:

{
  packages = [ pkgs.awscli2 ];

  env.DATABASE_URL = "postgresql://localhost:5432/myapp";

  # Shared modules use mkDefault, so plain assignment overrides them.
  languages.javascript.package = pkgs.nodejs_22;

  scripts.deploy.exec = ''
    exec ./scripts/deploy.sh "$@"
  '';
}
```

Never edit the `imports:` list to work around a shared module. Override it here, or fix the
shared module for everyone.

## Services

Modules that declare services (`postgres`, `redis`) do not start automatically:

```bash
devenv up -d     # start in the background
devenv down      # stop
```

## Pulling in shared-module fixes

```bash
devenv update            # everything
devenv update serenity   # only the shared modules
```

Nothing changes until you run this. That is the point — a project you set up a year ago
keeps building.

## Editing the shared modules

Changes need to be pushed before other projects see them. To iterate without pushing:

```bash
devenv-init --local node
```

This points the input at `path:~/serenityOs/devenvs` instead of GitHub, and devenv picks up
edits automatically with no re-lock. The path is machine-specific — switch the `serenity`
input back to `github:VictorBuch/serenityOs` before committing the project.

## Adding a new module

1. Create `devenvs/modules/<name>/devenv.nix`.
2. Add `<name>` to `known_modules` in `modules/apps/development/devenv-init.sh`.
3. `git add` it — flakes only see git-tracked files.

Modules describe themselves through the `serenity.cmds` option declared in `base`, so
`cmds` stays accurate:

```nix
serenity.cmds = ''
  deploy            Ship it
'';
```

Use `lib.mkDefault` for anything a project might reasonably want to override.

---

# Reference

## Modules

| Module     | Provides                                                            | Commands                                                 |
| ---------- | ------------------------------------------------------------------- | -------------------------------------------------------- |
| `base`     | jq, the `cmds` help listing                                         | `cmds`                                                   |
| `nodejs`   | Node 24, npm/pnpm/yarn/bun, TypeScript, prettier + pre-commit hook  | `pm` `dev` `build` `check` `fmt`                         |
| `vue-nuxt` | Vue language server, defaults to pnpm — needs `nodejs`              | `preview`                                                |
| `go`       | Go, gopls, delve, golangci-lint, sqlc, gofmt + govet hooks          | `dev` `build` `check` `cover` `lint` `mod-init`          |
| `docker`   | docker client, compose, lazydocker                                  | `compose` `up` `down` `logs` `ps`                        |
| `postgres` | PostgreSQL 17 service on 127.0.0.1:5432, database `devdb`           | `db` `db-reset`                                          |
| `redis`    | Redis service on 6379                                               | `cache`                                                  |
| `flutter`  | Flutter, Android SDK/NDK, JDK 17, gradle, dart-format hook          | `emu` `doctor` `devices` `check` `analyze` `fmt` `reset` |
| `appwrite` | Appwrite CLI, installed into `.devenv` on first use — needs `nodejs` | `appwrite` `appwrite-deploy`                             |
| `work`     | gcloud, Prisma 6 + engine env vars — needs `nodejs` and `docker`    | `db-push` `db-generate` `db-studio`                      |

Run `cmds` inside any environment to see what it provides.

## Gotchas

- Imported modules cannot declare their own `inputs`. Anything a module needs
  (`git-hooks`, `allowUnfree`) has to be in the project's root `devenv.yaml`; `devenv-init`
  handles this. A missing `git-hooks` input is a hard evaluation failure, not a warning.
- Script names avoid shell builtins — hence `check` rather than `test` and `cmds` rather
  than `help`. A `scripts.test` is shadowed by bash's `test` builtin and never runs.
- `work` replaces what used to be a system-wide module, so those tools exist only inside
  work projects.
- The `nodePackages.*` attribute set no longer exists in nixpkgs. Use top-level names
  (`pkgs.pnpm`, `pkgs.typescript`, `pkgs.prettier`).

## Prerequisites

Only needed by people who aren't on this NixOS config:

```bash
sh <(curl -L https://nixos.org/nix/install)   # nix
nix profile install nixpkgs#devenv            # devenv
nix profile install nixpkgs#direnv            # direnv (optional)
eval "$(direnv hook bash)"                    # or zsh/fish, in your shell rc
```

Without direnv, use `devenv shell` to enter an environment manually.

## Troubleshooting

**Environment doesn't activate.** `direnv allow`. Re-run it after `devenv.yaml` changes.

**`To use 'git-hooks', run ...`.** The project's `devenv.yaml` is missing the `git-hooks`
input. Re-scaffold, or copy the input block from the example at the top.

**Services won't start.** Run `devenv up` in the foreground to see errors. To wipe service
data: `rm -rf .devenv/state/`.

**Stale packages.** `devenv update`, then `direnv reload`.

**Reclaiming disk.** `devenv gc`.
