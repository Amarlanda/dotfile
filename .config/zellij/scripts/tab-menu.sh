#!/usr/bin/env bash
# Tab command menu for Zellij (Alt+T)

choice=$(cat <<'MENU' | fzf --prompt="Tab ❯ " --height=100% --reverse --no-info --border=none
  [n]    New tab              ▸ zellij action new-tab
  [r]    Rename tab           ▸ zellij action rename-tab <name>
  [x]    Close tab            ▸ zellij action close-tab
  [h]    Previous tab         ▸ zellij action go-to-previous-tab
  [l]    Next tab             ▸ zellij action go-to-next-tab
  [1-9]  Go to tab #          ▸ zellij action go-to-tab <n>
  [b]    Break pane to tab    ▸ zellij action break-pane
  [[]    Break pane left      ▸ zellij action break-pane-left
  []]    Break pane right     ▸ zellij action break-pane-right
  [s]    Toggle sync tab      ▸ zellij action toggle-active-sync-tab
MENU
)

[ -z "$choice" ] && exit 0
cmd=$(echo "$choice" | sed 's/.*▸ //')
case "$cmd" in
  *"<"*) echo "$cmd"; sleep 1 ;;
  *) eval "$cmd" ;;
esac
