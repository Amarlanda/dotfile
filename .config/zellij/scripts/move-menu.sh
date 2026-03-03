#!/usr/bin/env bash
# Move command menu for Zellij (Alt+M)

choice=$(cat <<'MENU' | fzf --prompt="Move ❯ " --height=100% --reverse --no-info --border=none
  [h]    Move pane left       ▸ zellij action move-pane left
  [j]    Move pane down       ▸ zellij action move-pane down
  [k]    Move pane up         ▸ zellij action move-pane up
  [l]    Move pane right      ▸ zellij action move-pane right
  [n]    Move pane forward    ▸ zellij action move-pane
  [p]    Move pane backward   ▸ zellij action move-pane-backwards
MENU
)

[ -z "$choice" ] && exit 0
cmd=$(echo "$choice" | sed 's/.*▸ //')
eval "$cmd"
