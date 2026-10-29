#!/bin/sh
# Opens a new tab beside the current one and starts Claude Code in it.
# Bound to prefix+c in config.toml; herdr passes the HERDR_ACTIVE_* variables.

herdr="${HERDR_BIN_PATH:-herdr}"
set -- --cwd "${HERDR_ACTIVE_PANE_CWD:-$HOME}" --focus
[ -n "${HERDR_ACTIVE_WORKSPACE_ID:-}" ] && set -- --workspace "$HERDR_ACTIVE_WORKSPACE_ID" "$@"

pane=$("$herdr" tab create "$@" | jq -r '.result.root_pane.pane_id // empty')
[ -n "$pane" ] && "$herdr" pane run "$pane" claude
