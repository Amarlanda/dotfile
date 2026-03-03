# Homebrew Packages

This directory tracks all Homebrew packages installed on this machine.

## Files

- `packages.json` — Full inventory of formulae and casks with descriptions

## Keeping this up to date

**This must be run regularly** to keep the package list in sync with what's actually installed.

Run the export script after installing or removing any brew packages:

```bash
# Export current formulae and casks to a Brewfile
brew bundle dump --file=~/git/pers/dotfile/brew/Brewfile --force

# Then commit the changes
cd ~/git/pers/dotfile && git add brew/ && git commit -m "Update brew packages"
```

## Restoring on a new machine

```bash
# Install everything from the Brewfile
brew bundle --file=~/git/pers/dotfile/brew/Brewfile
```

## Generating a Brewfile now

```bash
brew bundle dump --file=~/git/pers/dotfile/brew/Brewfile --force
```
