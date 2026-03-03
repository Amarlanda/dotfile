# dotfile

My macOS dotfiles managed with symlinks.

## How it works

This repo is the single source of truth. Every config file in `$HOME` is a **symlink** pointing into this repo:

```
~/.zshrc  ->  ~/git/pers/dotfile/.zshrc
~/.config/ghostty/config  ->  ~/git/pers/dotfile/.config/ghostty/config
...etc
```

Edit any config file as normal (e.g. `vi ~/.zshrc`). Because it's a symlink, you're editing the repo copy directly. Run `git diff` in this repo to see your changes, then commit and push.

## What's tracked

See `dotfiles.json` for the full list with descriptions. Summary:

| File | What |
|------|------|
| `.zshrc` | Shell config (aliases, m1/m2, PATH, vim mode) |
| `.gitconfig` | Git global settings |
| `.config/starship.toml` | Prompt theme |
| `.config/ghostty/config` | Terminal settings |
| `.config/zellij/config.kdl` | Multiplexer config |
| `.config/zellij/layouts/*.kdl` | Zellij layouts (default, htop-all, tree, vtab) |
| `.config/zellij/scripts/*.sh` | Zellij helper scripts |
| `.claude/CLAUDE.md` | Claude Code global instructions |
| `.claude/settings.json` | Claude Code settings |

## What's NOT tracked (secrets)

These files contain passwords/tokens and are in `.gitignore`:

- `.env` - API tokens
- `.git_credentials` - GitHub PAT
- `.bobski` - encoded password
- `.config/machines.conf` - machine IPs and passwords
- `.voicemode/voicemode.env` - voice service config

## Setup on a new machine

```bash
git clone https://github.com/Amarlanda/dotfile.git ~/git/pers/dotfile
cd ~/git/pers/dotfile
./install.sh          # interactive - prompts before replacing each file
./install.sh --force  # overwrite without prompting
```

The install script backs up any existing file to `<file>.bak.pre-symlink` before creating the symlink.

## Adding a new dotfile

1. Copy the file into this repo (mirror the home directory path)
2. Add it to the `FILES` array in `install.sh`
3. Add it to `dotfiles.json`
4. Replace the original with a symlink: `ln -s ~/git/pers/dotfile/<path> ~/<path>`
