#!/usr/bin/env bash
# Resize command menu for Zellij (Alt+N)

choice=$(cat <<'MENU' | fzf --prompt="Resize ❯ " --height=100% --reverse --no-info --border=none
  [h]  Increase left          ▸ zellij action resize increase left
  [j]  Increase down          ▸ zellij action resize increase down
  [k]  Increase up            ▸ zellij action resize increase up
  [l]  Increase right         ▸ zellij action resize increase right
  [H]  Decrease left          ▸ zellij action resize decrease left
  [J]  Decrease down          ▸ zellij action resize decrease down
  [K]  Decrease up            ▸ zellij action resize decrease up
  [L]  Decrease right         ▸ zellij action resize decrease right
  [+]  Increase all           ▸ zellij action resize increase
  [-]  Decrease all           ▸ zellij action resize decrease
MENU
)

[ -z "$choice" ] && exit 0
cmd=$(echo "$choice" | sed 's/.*▸ //')
eval "$cmd"
