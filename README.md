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
