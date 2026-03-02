#!/usr/bin/env bash
set -euo pipefail

# install.sh - Symlink dotfiles from this repo into $HOME
#
# Usage:
#   ./install.sh          # interactive - prompts before each symlink
#   ./install.sh --force  # overwrite existing files without prompting
#
# What it does:
#   1. For each tracked dotfile, creates a symlink from ~/<path> -> <repo>/<path>
#   2. Backs up any existing file to <file>.bak.pre-symlink before replacing
#   3. Creates parent directories if they don't exist

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
FORCE=false
[[ "${1:-}" == "--force" ]] && FORCE=true

# Every file tracked by this repo (relative to $HOME)
FILES=(
  .zshrc
  .gitconfig
  .config/starship.toml
  .config/ghostty/config
  .config/zellij/config.kdl
  .config/zellij/layouts/default.kdl
  .config/zellij/layouts/htop-all.kdl
  .config/zellij/layouts/tree.kdl
  .config/zellij/layouts/vtab-new-tab.kdl
  .config/zellij/scripts/move-menu.sh
  .config/zellij/scripts/pane-menu.sh
  .config/zellij/scripts/resize-menu.sh
  .config/zellij/scripts/scroll-menu.sh
  .config/zellij/scripts/session-menu.sh
  .config/zellij/scripts/tab-menu.sh
  .claude/CLAUDE.md
  .claude/settings.json
  .zprofile
)

# Files that need sudo to install to system paths
SUDO_FILES=(
  "sudoers.d/route:/etc/sudoers.d/route"
)

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

link_file() {
  local rel="$1"
  local src="$REPO_DIR/$rel"
  local dst="$HOME/$rel"

  if [[ ! -f "$src" ]]; then
    echo -e "${RED}SKIP${RESET} $rel (not in repo)"
    return
  fi

  # Already correctly linked
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo -e "${GREEN}  OK${RESET} $rel (already linked)"
    return
  fi

  # Existing file or wrong symlink - back up
  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ "$FORCE" == false ]]; then
      echo -en "${YELLOW}REPLACE${RESET} $dst? [y/N] "
      read -r answer
      [[ "$answer" != "y" && "$answer" != "Y" ]] && echo "  skipped" && return
    fi
    mv "$dst" "${dst}.bak.pre-symlink"
    echo -e "${YELLOW}BACKUP${RESET} $dst -> ${dst}.bak.pre-symlink"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo -e "${GREEN}LINKED${RESET} $dst -> $src"
}

echo ""
echo "Dotfile installer - linking from $REPO_DIR into $HOME"
echo "======================================================"
echo ""

for f in "${FILES[@]}"; do
  link_file "$f"
done

# Install sudo-required files
echo ""
echo "System files (require sudo):"
for entry in "${SUDO_FILES[@]}"; do
  src="${REPO_DIR}/${entry%%:*}"
  dst="${entry##*:}"
  if [[ ! -f "$src" ]]; then
    echo -e "${RED}SKIP${RESET} ${entry%%:*} (not in repo)"
    continue
  fi
  if [[ -f "$dst" ]] && diff -q "$src" "$dst" &>/dev/null; then
    echo -e "${GREEN}  OK${RESET} $dst (already installed)"
    continue
  fi
  if [[ "$FORCE" == false ]]; then
    echo -en "${YELLOW}INSTALL${RESET} $src -> $dst? [y/N] "
    read -r answer
    [[ "$answer" != "y" && "$answer" != "Y" ]] && echo "  skipped" && continue
  fi
  sudo cp "$src" "$dst"
  sudo chown root:wheel "$dst"
  sudo chmod 440 "$dst"
  echo -e "${GREEN}INSTALLED${RESET} $dst"
done

echo ""
echo -e "${GREEN}Done.${RESET} Secret files (.env, .git_credentials, machines.conf) are NOT managed by this repo."
echo ""
