#!/usr/bin/env bash
# Session command menu for Zellij (Alt+O)

choice=$(cat <<'MENU' | fzf --prompt="Session ❯ " --height=100% --reverse --no-info --border=none
  [d]  Detach                 ▸ zellij action detach
  [r]  Session manager        ▸ zellij action launch-or-focus-plugin session-manager --floating
  [c]  Configuration          ▸ zellij action launch-or-focus-plugin configuration --floating
  [p]  Plugin manager         ▸ zellij action launch-or-focus-plugin plugin-manager --floating
  [a]  About                  ▸ zellij action launch-or-focus-plugin zellij:about --floating
MENU
)

[ -z "$choice" ] && exit 0
cmd=$(echo "$choice" | sed 's/.*▸ //')
eval "$cmd"
