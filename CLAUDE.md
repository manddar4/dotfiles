# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for Linux (WSL2 / Ubuntu 24.04), macOS, and Windows, managed via symlinks from this repo to `~`. The install scripts create symlinks rather than copying files, so changes here take effect immediately.

## Setup

```bash
# Linux / WSL2 / macOS
bash install.sh

# Windows (PowerShell, 관리자 권한 불필요)
.\install-windows.ps1
```

All install scripts are idempotent — re-running is safe and will update existing symlinks.

## Cross-Platform Architecture

### OS별 도구 설치

| OS | 스크립트 | 패키지 매니저 |
|----|----------|---------------|
| Linux/WSL2 | `scripts/linux-tools.sh` | apt, .deb, AppImage |
| macOS | `scripts/macos-tools.sh` | Homebrew |
| Windows | `install-windows.ps1` | Scoop |
| 공통 (Linux/macOS) | `scripts/common-tools.sh` | git clone, curl |

`install.sh`가 OS를 자동 감지하여 `linux-tools.sh` 또는 `macos-tools.sh`를 실행한다. 두 스크립트 모두 `common-tools.sh`를 source하여 공통 도구(Oh My Zsh, fzf, starship, fzf-tab, zsh-autosuggestions, TPM)를 설치한다.

### 셸 프로파일

| OS | 셸 | 프로파일 |
|----|-----|----------|
| Linux/macOS | zsh | `zsh/.zshrc` → `~/.zshrc` |
| Windows | PowerShell 7 | `powershell/profile.ps1` → `$PROFILE` |

### Windows 제한사항

Windows 네이티브에서는 tmux, Oh My Zsh, dev 스크립트를 사용할 수 없다. 대신:
- `windows-terminal/settings.json`: Windows Terminal 설정 (Dracula 테마, 키바인딩)
- `powershell/profile.ps1`: PowerShell 프로파일 (starship, eza alias, fzf, mise)

## Symlink Architecture

### Linux / macOS (install.sh)
- `zsh/.zshrc` → `~/.zshrc`
- `git/.gitconfig` → `~/.gitconfig`
- `starship/starship.toml` → `~/.config/starship.toml`
- `tmux/.tmux.conf` → `~/.tmux.conf`
- `nvim/` → `~/.config/nvim` (full directory, LazyVim)
- `mise/.mise.toml` → `~/.mise.toml`
- `scripts/dev` → `~/.local/bin/dev`
- `ghostty/config` → `~/.config/ghostty/config` (macOS only)

### Windows (install-windows.ps1)
- `git/.gitconfig` → `~/.gitconfig`
- `starship/starship.toml` → `~/.config/starship.toml`
- `nvim/` → `~/AppData/Local/nvim`
- `mise/.mise.toml` → `~/.mise.toml`
- `powershell/profile.ps1` → `$PROFILE`

## Git Configuration

`git/.gitconfig`에는 공통 설정만 포함. 머신별 설정은 `~/.gitconfig.local`에서 관리:
- `[include] path = ~/.gitconfig.local` 로 참조
- `~/.gitconfig.local`은 install 스크립트에서 자동 생성 (user.name, email, credential helper)
- `.gitconfig.local`은 git에 커밋하지 않음

## The `dev` Script (`scripts/dev`)

The core workflow tool — integrates tmux + git worktrees for isolated development sessions. Linux/macOS only.

Each session creates a git worktree under `.worktrees/<repo>/<name>/` and a tmux session with 4 windows: `code` (claude), `gemini` (gemini), `term` (shell), `git` (lazygit).

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

- **apt** (`scripts/linux-tools.sh`): Linux system packages and CLI tools
- **Homebrew** (`scripts/macos-tools.sh`): macOS packages and CLI tools
- **Scoop** (`install-windows.ps1`): Windows packages and CLI tools
- **mise** (`mise/.mise.toml`): Runtime versions (Node LTS, Bun latest, pnpm latest)
- **Bun** (`bun/global-packages.txt`): Global JS packages (`@anthropic-ai/claude-code`)

To add a new CLI tool: add to the appropriate OS-specific script (`linux-tools.sh`, `macos-tools.sh`, or `install-windows.ps1`).
To add a global JS package: add to `bun/global-packages.txt`, then `bun install -g <package>`.

## Theme & Aesthetic

Dracula theme used consistently across all platforms:
- tmux status bar, delta (git diffs), fzf, starship prompt
- Windows Terminal color scheme (`windows-terminal/settings.json`)
- PowerShell PSReadLine colors (`powershell/profile.ps1`)

New tool configs should follow this convention.

## Key Tool Choices

- **Shell**: zsh with Oh My Zsh (Linux/macOS), PowerShell 7 (Windows)
- **Editor**: Neovim (LazyVim) — config in `nvim/`
- **Terminal**: Cursor built-in terminal (WSL2), Windows Terminal (Windows)
- **Git diffs**: delta with side-by-side view
- **ls replacement**: eza (aliased as `ls`)
- **Version manager**: mise (replaces nvm, etc.)
- **Completion**: fzf-tab (Tab → fzf UI), zsh-autosuggestions (history suggestions)
