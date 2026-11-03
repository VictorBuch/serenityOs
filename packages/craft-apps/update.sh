#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq
# Pins every craft app to its latest GitHub release: ./packages/craft-apps/update.sh
set -euo pipefail

cd "$(dirname "$0")"
apps=(photocraft filmcraft lightcraft pdfcraft figcraft vectorcraft)

out='{}'
for app in "${apps[@]}"; do
  tag=$(curl -fsSL "https://api.github.com/repos/storytold/$app/releases/latest" | jq -r .tag_name)
  version=${tag#v}
  url="https://github.com/storytold/$app/releases/download/$tag/$app-$version-linux-x86_64.tar.gz"
  hash=$(nix store prefetch-file --json "$url" | jq -r .hash)
  echo "$app $version"
  out=$(jq --arg a "$app" --arg v "$version" --arg h "$hash" '.[$a] = {version: $v, hash: $h}' <<<"$out")
done

echo "$out" >sources.json
