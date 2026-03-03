#!/usr/bin/env bash
# Pane command menu for Zellij (Alt+P)

choice=$(cat <<'MENU' | fzf --prompt="Pane ❯ " --height=100% --reverse --no-info --border=none
  [n]  New pane               ▸ zellij action new-pane
  [l]  New pane right         ▸ zellij action new-pane --direction right
  [d]  New pane down          ▸ zellij action new-pane --direction down
  [s]  New pane stacked       ▸ zellij action new-pane --direction down --stacked
  [h]  Move focus left        ▸ zellij action move-focus left
  [j]  Move focus down        ▸ zellij action move-focus down
  [k]  Move focus up          ▸ zellij action move-focus up
  [f]  Toggle fullscreen      ▸ zellij action toggle-fullscreen
  [w]  Toggle floating        ▸ zellij action toggle-floating-panes
  [e]  Toggle embed/float     ▸ zellij action toggle-pane-embed-or-floating
  [i]  Toggle pinned          ▸ zellij action toggle-pane-pinned
  [z]  Toggle pane frames     ▸ zellij action toggle-pane-frames
  [r]  Rename pane            ▸ zellij action rename-pane <name>
  [p]  Switch focus           ▸ zellij action focus-next-pane
  [x]  Close pane             ▸ zellij action close-pane
MENU
)

[ -z "$choice" ] && exit 0
cmd=$(echo "$choice" | sed 's/.*▸ //')
# Skip commands with placeholders
case "$cmd" in
  *"<"*) echo "$cmd"; sleep 1 ;;
  *) eval "$cmd" ;;
esac
