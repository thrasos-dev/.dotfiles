#!/usr/bin/env bash
#
# Warn when ~/.claude/settings.json has drifted from the copy tracked in this repo.
#
# Claude Code rewrites ~/.claude/settings.json in place whenever a setting changes
# (/config toggles, `claude doctor`, ...). Those writes are temp-file-plus-rename, which
# replaces the Stow symlink with a regular file — after which the repo copy silently
# goes stale. This check surfaces that drift instead of letting it accumulate.
#
# Usage:
#   check-claude-settings-sync.sh         report drift, exit 1 if any
#   check-claude-settings-sync.sh --fix   copy the live file over the tracked copy

set -euo pipefail

usage() {
	echo "usage: $(basename "$0") [--fix]"
}

fix=false
case "${1:-}" in
	--fix) fix=true ;;
	-h | --help)
		usage
		exit 0
		;;
	"") ;;
	*)
		echo "unknown argument: $1" >&2
		usage >&2
		exit 2
		;;
esac

repo_root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
tracked="$repo_root/claude/.claude/settings.json"
live="$HOME/.claude/settings.json"

# Nothing to compare on a machine without Claude Code.
[ -e "$live" ] || exit 0

# Still symlinked into the repo (same inode) — it cannot drift.
[ "$live" -ef "$tracked" ] && exit 0

cmp -s "$live" "$tracked" && exit 0

# Byte-different. Claude Code may have only reordered or reindented keys, so compare the
# parsed JSON before reporting. Without python3 we fall back to the byte comparison above.
if command -v python3 > /dev/null 2>&1; then
	if python3 - "$live" "$tracked" << 'PY'
import json, sys
try:
    with open(sys.argv[1]) as live, open(sys.argv[2]) as tracked:
        sys.exit(0 if json.load(live) == json.load(tracked) else 1)
except (OSError, ValueError):
    sys.exit(1)
PY
	then
		exit 0
	fi
fi

if [ "$fix" = true ]; then
	cp "$live" "$tracked"
	echo "Updated ${tracked#"$repo_root"/} from $live"
	exit 0
fi

echo "warning: Claude settings have drifted from this repo" >&2
echo >&2
diff -u --label "repo   ${tracked#"$repo_root"/}" --label "live   $live" \
	"$tracked" "$live" >&2 || true
echo >&2
echo "  Adopt the live settings:  scripts/check-claude-settings-sync.sh --fix" >&2
echo "  Or restore the symlink:   stow -R --no-folding claude" >&2
exit 1
