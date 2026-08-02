# Dotfiles

This repository contains my personal [dotfiles](https://wiki.archlinux.org/title/Dotfiles) configuration, managed using [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Each directory represents a "package" that can be independently managed:

- `vim/` - Vim configuration (.vimrc)
- `nvim/` - Neovim configuration 
- `ghostty/` - Ghostty terminal configuration
- `claude/` - Claude Code global config (`~/.claude/CLAUDE.md` and `settings.json`)

## Setup

```bash
git clone https://github.com/thrasos-dev/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Install all packages
stow vim nvim ghostty

# The claude package must be stowed with --no-folding (see note at the bottom)
stow --no-folding claude

# Or install individual packages
stow vim
stow nvim
stow ghostty

# Enable the repo's hooks (see "Claude settings drift" below)
git config core.hooksPath hooks
```

## Managing Packages

```bash
# Add a new package
stow package_name

# Remove a package  
stow -D package_name

# Restow (useful after adding new files)
stow -R package_name
```

> **Note:** When adding new packages, update `.gitignore` to include the new package directory and its contents.

> **Note:** The `claude/` package targets `~/.claude`, which Claude Code actively writes to (sessions, history, projects, caches). Always stow it with `--no-folding` so only the individual config files are symlinked and `~/.claude` stays a real directory — otherwise, on a machine where `~/.claude` doesn't exist yet, Stow would symlink the entire directory into this repo and Claude would write all its state there.

## Claude settings drift

Claude Code rewrites `~/.claude/settings.json` in place whenever a setting changes — a
`/config` toggle, `claude doctor`, and so on. Those writes are temp-file-plus-rename, so
they **replace the Stow symlink with a regular file**, and from then on the copy tracked
here silently goes stale. Re-stowing restores the link but only until the next write.

Rather than fight it, `scripts/check-claude-settings-sync.sh` reports the drift:

```bash
# Report drift (exit 1 if any)
scripts/check-claude-settings-sync.sh

# Adopt the live settings into the repo
scripts/check-claude-settings-sync.sh --fix
```

`hooks/pre-commit` runs the check on every commit and prints a warning without ever
blocking. Enable the hooks once per clone:

```bash
git config core.hooksPath hooks
```

The check compares parsed JSON, so reordered or reindented keys don't trip it, and it
stays quiet when `~/.claude/settings.json` is absent or still symlinked into the repo.
