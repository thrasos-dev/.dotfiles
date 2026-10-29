#!/bin/sh
# Names herdr tabs after their Claude Code sessions' titles, the way Zed names
# its agent threads, keeping the tab's number in front ("2 · Fix the build").
# The sidebar shows the same name as $tab_name, without the number when the
# space has only one agent.
#
# Runs as a Stop and SessionStart hook and updates every Claude Code tab in the
# space, so numbers catch up after tabs move or close. Tabs you named yourself
# are left alone: only a numbered tab, or one this hook named, gets renamed.

[ "${HERDR_ENV:-}" = "1" ] && [ -n "${HERDR_PANE_ID:-}" ] || exit 0
command -v herdr >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 || exit 0

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/herdr-tab-title"
max_length=32
sep=$(printf '\037')

# Until Claude Code has named the session, its title is just "Claude Code".
# A resumed session sets its title a moment after it starts.
if [ "${1:-}" = "session" ]; then
  i=0
  while [ "$i" -lt 10 ]; do
    title=$(herdr pane get "$HERDR_PANE_ID" 2>/dev/null |
      jq -r '.result.pane.terminal_title_stripped // ""')
    [ -n "$title" ] && [ "$title" != "Claude Code" ] && break
    sleep 1
    i=$((i + 1))
  done
fi

panes=$(herdr pane list 2>/dev/null) || exit 0
workspace=$(printf '%s' "$panes" | jq -r --arg pane "$HERDR_PANE_ID" '
  .result.panes[] | select(.pane_id == $pane) | .workspace_id')
[ -n "$workspace" ] || exit 0
tabs=$(herdr tab list --workspace "$workspace" 2>/dev/null) || exit 0

# One line per Claude Code pane in the space, grouped by tab: pane, tab, the
# tab's number in the tab bar, its label, the session title and how many agents
# the space has. herdr's own tab "number" stays put when tabs before it close.
printf '%s' "$panes" | jq -r --arg ws "$workspace" --argjson tabs "$tabs" \
  --argjson max "$max_length" --arg sep "$sep" '
  ($tabs.result.tabs | to_entries
    | map({key: .value.tab_id, value: (.value + {position: (.key + 1)})})
    | from_entries) as $tab
  | [.result.panes[] | select(.workspace_id == $ws and .agent != null)] as $agents
  | $agents | sort_by(.tab_id)[] | select(.agent == "claude")
  | [.pane_id, .tab_id, ($tab[.tab_id].position // "" | tostring),
     ($tab[.tab_id].label // ""),
     (.terminal_title_stripped // ""
       | if . == "Claude Code" then ""
         elif length > $max then .[:$max - 1] + "…" else . end),
     ($agents | length | tostring)]
  | join($sep)' |
  while IFS=$sep read -r pane tab number label title agents; do
    # A tab nobody named has its number as its label.
    case "$label" in *[!0-9]*) ;; *) label="" ;; esac
    if [ "$tab" = "${named_tab:-}" ]; then
      label=$named_label
    elif [ -n "$title" ]; then
      name="${number:+$number · }$title"
      if [ "$label" != "$name" ] &&
        { [ -z "$label" ] || [ "$label" = "$(cat "$state_dir/$tab" 2>/dev/null)" ]; } &&
        herdr tab rename "$tab" "$name" >/dev/null 2>&1; then
        label=$name
        mkdir -p "$state_dir" && printf '%s' "$name" >"$state_dir/$tab"
      fi
    fi
    named_tab=$tab
    named_label=$label

    [ "$agents" -gt 1 ] || label=${label#"$number · "}
    herdr pane report-metadata "$pane" --source user:herdr-tab-title \
      --token "tab_name=$label" >/dev/null 2>&1
  done
