#!/bin/sh
# Names herdr tabs after their Claude Code sessions' titles, the way Zed names
# its agent threads, keeping the tab's number in front ("2 · Fix the build").
# The sidebar shows the same name as $tab_name, without the number when the
# space has only one agent.
#
# herdr runs this whenever a tab opens, closes or moves or an agent appears or
# goes (see herdr-plugin.toml), so numbers follow right away. Claude Code runs
# it too, from hooks in ~/.claude/settings.json, when a session starts, when
# you send a message and when Claude finishes replying, because herdr can't
# tell plugins when a title changes. Tabs you named yourself are left alone:
# only a numbered tab, or one this script named, gets renamed.

[ "${HERDR_ENV:-}" = "1" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

herdr="${HERDR_BIN_PATH:-herdr}"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/herdr-tab-title"
max_length=32
sep=$(printf '\037')

# Claude Code names a new session a few seconds after the first message, and a
# resumed one a moment after it starts, so its hooks pass "wait".
if [ "${1:-}" = "wait" ] && [ -n "${HERDR_PANE_ID:-}" ]; then
  i=0
  while [ "$i" -lt 30 ]; do
    title=$("$herdr" pane get "$HERDR_PANE_ID" 2>/dev/null |
      jq -r '.result.pane.terminal_title_stripped // ""')
    [ -n "$title" ] && [ "$title" != "Claude Code" ] && break
    sleep 1
    i=$((i + 1))
  done
fi

panes=$("$herdr" pane list 2>/dev/null) || exit 0

for workspace in $(printf '%s' "$panes" | jq -r '
  [.result.panes[] | select(.agent == "claude") | .workspace_id] | unique[]'); do
  tabs=$("$herdr" tab list --workspace "$workspace" 2>/dev/null) || continue

  # One line per Claude Code pane in the space, grouped by tab: pane, tab, the
  # tab's number in the tab bar, its label, the session title, the sidebar name
  # it has now and how many agents the space has. herdr's own tab "number"
  # stays put when tabs before it close.
  printf '%s' "$panes" | jq -r --arg ws "$workspace" --argjson tabs "$tabs" \
    --argjson max "$max_length" --arg sep "$sep" '
    ($tabs.result.tabs | to_entries
      | map({key: .value.tab_id, value: (.value + {position: (.key + 1)})})
      | from_entries) as $tab
    | [.result.panes[] | select(.workspace_id == $ws and .agent != null)] as $agents
    | $agents | sort_by(.tab_id)[] | select(.agent == "claude")
    | [.pane_id, .tab_id, ($tab[.tab_id].position // "" | tostring),
       ($tab[.tab_id].label // ""),
       # Until Claude Code has named the session, its title is "Claude Code".
       (.terminal_title_stripped // ""
         | if . == "Claude Code" then ""
           elif length > $max then .[:$max - 1] + "…" else . end),
       (.tokens.tab_name // ""),
       ($agents | length | tostring)]
    | join($sep)' |
    while IFS=$sep read -r pane tab number label title shown agents; do
      # A tab nobody named has its number as its label.
      case "$label" in *[!0-9]*) ;; *) label="" ;; esac
      if [ "$tab" = "${named_tab:-}" ]; then
        label=$named_label
      elif [ -n "$title" ]; then
        name="${number:+$number · }$title"
        if [ "$label" != "$name" ] &&
          { [ -z "$label" ] || [ "$label" = "$(cat "$state_dir/$tab" 2>/dev/null)" ]; } &&
          "$herdr" tab rename "$tab" "$name" >/dev/null 2>&1; then
          label=$name
          mkdir -p "$state_dir" && printf '%s' "$name" >"$state_dir/$tab"
        fi
      fi
      named_tab=$tab
      named_label=$label

      # With other agents in the space, every entry shows its number, even
      # before its session has a name.
      label=${label#"$number · "}
      [ "$agents" -gt 1 ] && label="$number${label:+ · $label}"
      [ "$label" = "$shown" ] ||
        "$herdr" pane report-metadata "$pane" --source user:herdr-tab-title \
          --token "tab_name=$label" >/dev/null 2>&1
    done
done
