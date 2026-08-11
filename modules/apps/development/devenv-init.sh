#!/usr/bin/env bash
# devenv-init — scaffold a project devenv that imports the shared modules from
# serenityOs, instead of copying them.
set -euo pipefail

REPO_URL="${DEVENV_INIT_REPO:-github:VictorBuch/serenityOs}"
LOCAL_PATH="${DEVENV_INIT_LOCAL_PATH:-$HOME/serenityOs}"
REMOTE_MODULE_ROOT="serenity/devenvs/modules"
LOCAL_MODULE_ROOT="serenity/modules"

NIX_DIRENV_VERSION="3.2.0"
NIX_DIRENV_SHA="sha256-hW6NC1JHue3IjZN3uDM6l6I2PMaauqd2D7hXYJ1Zfr4="

use_local=0
force=0
target="."
stack=""

known_modules=(base nodejs vue-nuxt go docker postgres redis flutter appwrite work)

usage() {
  cat <<'USAGE'
devenv-init — scaffold a devenv that imports serenityOs's shared modules.

Usage:
  devenv-init [options] <preset|mod,mod,...> [directory]

Presets:
  node              nodejs
  vue               nodejs, vue-nuxt
  go                go
  docker            docker
  fullstack         nodejs, docker, postgres, redis
  flutter           flutter
  flutter-appwrite  flutter, nodejs, appwrite
  work              nodejs, docker, work

Modules (compose freely, comma-separated):
  nodejs vue-nuxt go docker postgres redis flutter appwrite work
  ("base" is always included)

Options:
  --local     Point the input at a local checkout instead of GitHub, so edits
              to the shared modules apply without pushing. Not portable —
              switch back before committing.
  --force     Overwrite existing devenv.yaml / devenv.nix / .envrc.
  --list      List presets and modules, then exit.
  -h, --help  Show this help.

Examples:
  devenv-init node
  devenv-init fullstack ~/projects/my-app
  devenv-init nodejs,postgres
  devenv-init --local work
USAGE
}

resolve_stack() {
  case "$1" in
    node) echo "nodejs" ;;
    vue) echo "nodejs vue-nuxt" ;;
    go) echo "go" ;;
    docker) echo "docker" ;;
    fullstack) echo "nodejs docker postgres redis" ;;
    flutter) echo "flutter" ;;
    flutter-appwrite) echo "flutter nodejs appwrite" ;;
    work) echo "nodejs docker work" ;;
    *) echo "${1//,/ }" ;;
  esac
}

contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --local) use_local=1; shift ;;
    --force) force=1; shift ;;
    --list)
      echo "Presets: node vue go docker fullstack flutter flutter-appwrite work"
      echo "Modules: ${known_modules[*]}"
      exit 0
      ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "devenv-init: unknown option $1" >&2; usage >&2; exit 2 ;;
    *)
      if [ -z "$stack" ]; then stack="$1"; else target="$1"; fi
      shift
      ;;
  esac
done

if [ -z "$stack" ]; then
  usage >&2
  exit 2
fi

read -r -a modules <<<"$(resolve_stack "$stack")"

for m in "${modules[@]}"; do
  if ! contains "$m" "${known_modules[@]}"; then
    echo "devenv-init: unknown module '$m'" >&2
    echo "devenv-init: known modules: ${known_modules[*]}" >&2
    exit 2
  fi
done

mkdir -p "$target"
cd "$target"

for f in devenv.yaml devenv.nix .envrc; do
  if [ -e "$f" ] && [ "$force" -eq 0 ]; then
    echo "devenv-init: $f already exists in $(pwd); pass --force to overwrite" >&2
    exit 1
  fi
done

if [ "$use_local" -eq 1 ]; then
  if [ ! -d "$LOCAL_PATH/devenvs/modules" ]; then
    echo "devenv-init: --local given but $LOCAL_PATH/devenvs/modules does not exist" >&2
    exit 1
  fi
  # Point at devenvs/ rather than the repo root so nix doesn't copy .git on
  # every evaluation.
  input_url="path:$LOCAL_PATH/devenvs"
  module_root="$LOCAL_MODULE_ROOT"
else
  input_url="$REPO_URL"
  module_root="$REMOTE_MODULE_ROOT"
fi

{
  echo "inputs:"
  echo "  nixpkgs:"
  echo "    url: github:cachix/devenv-nixpkgs/rolling"
  if contains nodejs "${modules[@]}" || contains go "${modules[@]}" || contains flutter "${modules[@]}"; then
    echo "  git-hooks:"
    echo "    url: github:cachix/git-hooks.nix"
    echo "    inputs:"
    echo "      nixpkgs:"
    echo "        follows: nixpkgs"
  fi
  echo "  serenity:"
  echo "    url: $input_url"
  echo "    flake: false"
  echo ""
  echo "imports:"
  echo "  - $module_root/base"
  for m in "${modules[@]}"; do
    echo "  - $module_root/$m"
  done
  if contains flutter "${modules[@]}"; then
    echo ""
    echo "allowUnfree: true"
  fi
} >devenv.yaml

cat >devenv.nix <<'NIXEOF'
{ pkgs, lib, ... }:

{
  # Shared setup comes from the imports in devenv.yaml.
  # Anything specific to this project goes here.
}
NIXEOF

cat >.envrc <<ENVRCEOF
#!/usr/bin/env bash

if ! has nix_direnv_version || ! nix_direnv_version $NIX_DIRENV_VERSION; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/$NIX_DIRENV_VERSION/direnvrc" "$NIX_DIRENV_SHA"
fi

use devenv
ENVRCEOF

ignores=(".devenv/" ".devenv.flake.nix" "devenv.local.nix" ".direnv/" ".pre-commit-config.yaml")
touch .gitignore
had_content=0
[ -s .gitignore ] && had_content=1
missing=()
for entry in "${ignores[@]}"; do
  if ! grep -qxF "$entry" .gitignore; then
    missing+=("$entry")
  fi
done
if [ "${#missing[@]}" -gt 0 ]; then
  {
    [ "$had_content" -eq 1 ] && echo ""
    echo "# devenv / direnv"
    printf '%s\n' "${missing[@]}"
  } >>.gitignore
fi

echo "Scaffolded devenv in $(pwd)"
echo "  modules: base ${modules[*]}"
echo "  source:  $input_url"
if [ "$use_local" -eq 1 ]; then
  echo "  note:    --local input is machine-specific; switch to $REPO_URL before committing"
fi
echo ""
echo "Next: direnv allow    (or: devenv shell)"
