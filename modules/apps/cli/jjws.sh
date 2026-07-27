# jjws — create a jj (jujutsu) workspace AND register it as a native herdr workspace.
#
# Usage: jjws <workspace-name>
#
# Workspaces are created under $JJ_WS_ROOT/<repo>/<name> (default root:
# ~/.herdr/worktrees). After `jj workspace add`, it calls
# `herdr workspace create --cwd <dir>` so the workspace shows up in herdr's
# sidebar instead of being invisible. Prefer this over raw `jj workspace add`
# (especially for agents) so every workspace is tracked by herdr.

name="${1:-}"
if [ -z "$name" ]; then
	echo "usage: jjws <workspace-name>" >&2
	exit 1
fi

# Must be inside a jj repo.
if ! jj root >/dev/null 2>&1; then
	echo "jjws: not inside a jj repository" >&2
	exit 1
fi

# Repo slug: prefer the git toplevel (colocated repos), else the jj workspace root.
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || jj root)"
repo="$(basename "$repo_root")"

root="${JJ_WS_ROOT:-$HOME/.herdr/worktrees}/$repo"
dir="$root/$name"

if [ -e "$dir" ]; then
	echo "jjws: $dir already exists" >&2
	exit 1
fi

mkdir -p "$root"
jj workspace add "$dir"

# Register with herdr so it appears as a native workspace.
abs="$(cd "$dir" && pwd)"
herdr workspace create --cwd "$abs" --label "$name"

echo "$abs"
