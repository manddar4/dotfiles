# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for Linux (WSL2 / Ubuntu 24.04), managed via symlinks from this repo to `~`. The primary install script creates symlinks rather than copying files, so changes here take effect immediately.

## Setup

```bash
bash install.sh   # Full setup: Linux tools, symlinks, mise tools, bun packages
```

The install script is idempotent — re-running it is safe and will update existing symlinks.

## Symlink Architecture

Configurations are symlinked into place:
- `zsh/.zshrc` → `~/.zshrc`
- `git/.gitconfig` → `~/.gitconfig`
- `starship/starship.toml` → `~/.config/starship.toml`
- `tmux/.tmux.conf` → `~/.tmux.conf`
- `nvim/` → `~/.config/nvim` (full directory, LazyVim)
- `mise/.mise.toml` → `~/.mise.toml`
- `scripts/dev` → `~/.local/bin/dev`

## The `dev` Script (`scripts/dev`)

The core workflow tool — integrates tmux + git worktrees for isolated development sessions.

Each session creates a git worktree under `.worktrees/<repo>/<name>/` and a tmux session with 3 windows: `code` (claude), `git` (lazygit), `term` (shell).

```bash
dev              # Start session in current directory (no worktree)
dev <name>       # Create worktree + tmux session named <name>
dev -l           # List all sessions for the current repo
dev -c <name>    # Clean up session + worktree
dev -c --all     # Clean all sessions for current repo
dev -c --orphans # Clean sessions with no active tmux
```

When running `dev <name>`, it detects if a session already exists and offers to attach, restart, or stop it.

## Package Management

- **apt** (`scripts/linux-tools.sh`): System packages and CLI tools
- **mise** (`mise/.mise.toml`): Runtime versions (Node LTS, Bun latest, pnpm latest)
- **Bun** (`bun/global-packages.txt`): Global JS packages (`@anthropic-ai/claude-code`)

To add a new CLI tool: add to `scripts/linux-tools.sh` install section.
To add a global JS package: add to `bun/global-packages.txt`, then `bun install -g <package>`.

## Theme & Aesthetic

Dracula theme used consistently across: tmux, delta (git diffs), fzf, and starship prompt. New tool configs should follow this convention.

## Key Tool Choices

- **Shell**: zsh with Oh My Zsh (plugins loaded via `plugins=()` array in `.zshrc`)
- **Editor**: Neovim (LazyVim) — config in `nvim/`
- **Terminal**: Cursor built-in terminal (WSL2)
- **Git diffs**: delta with side-by-side view
- **ls replacement**: eza (aliased as `ls`)
- **Version manager**: mise (replaces nvm, etc.)
- **Completion**: fzf-tab (Tab → fzf UI), zsh-autosuggestions (history suggestions)
