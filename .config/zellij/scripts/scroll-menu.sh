#!/usr/bin/env bash
# Scroll command menu for Zellij (Alt+S)

choice=$(cat <<'MENU' | fzf --prompt="Scroll ❯ " --height=100% --reverse --no-info --border=none
  [j]      Scroll down        ▸ zellij action scroll-down
  [k]      Scroll up          ▸ zellij action scroll-up
  [d]      Half page down     ▸ zellij action half-page-scroll-down
  [u]      Half page up       ▸ zellij action half-page-scroll-up
  [Ctrl+f] Page down          ▸ zellij action page-scroll-down
  [Ctrl+b] Page up            ▸ zellij action page-scroll-up
  [e]      Edit scrollback    ▸ zellij action edit-scrollback
  [s]      Search             ▸ zellij action switch-mode search
MENU
)

[ -z "$choice" ] && exit 0
cmd=$(echo "$choice" | sed 's/.*▸ //')
eval "$cmd"
