#!/bin/bash

# ==============================================================================
# macOS 도구 설치 스크립트 (Homebrew 기반)
# ==============================================================================
# 이 스크립트는 멱등적(idempotent)으로 설계되어 있다.
# Homebrew를 통해 필요한 도구를 설치하며, 이미 설치된 패키지는 건너뜀.
# install.sh 에서 자동으로 호출되며, 단독 실행도 가능하다.
#
# 설치 목록:
#   [brew]          neovim, eza, git-delta, lazygit, gh, yq, fzf, bat,
#                   ripgrep, fd, tmux, tree
#   [curl 설치]     mise (버전 매니저)
#   [common-tools]  starship, fzf-tab, Oh My Zsh, zsh-autosuggestions, TPM
# ==============================================================================

set -e  # 오류 발생 시 즉시 종료

echo "==> Installing macOS tools..."

# ==============================================================================
# 1. Homebrew 설치
# ==============================================================================
# Homebrew는 macOS의 패키지 매니저로, 대부분의 CLI 도구를 설치하는 데 사용한다.
# Apple Silicon(M1/M2/M3)과 Intel Mac에서 설치 경로가 다르다.
#   Apple Silicon : /opt/homebrew/bin/brew
#   Intel Mac     : /usr/local/bin/brew

# Homebrew 경로 결정
BREW_PATH=""
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    BREW_PATH="/opt/homebrew/bin/brew"
elif [[ -f "/usr/local/bin/brew" ]]; then
    BREW_PATH="/usr/local/bin/brew"
fi

if ! command -v brew &>/dev/null; then
    echo "==> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # 설치 후 경로 다시 확인
    if [[ -z "$BREW_PATH" ]]; then
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            BREW_PATH="/opt/homebrew/bin/brew"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            BREW_PATH="/usr/local/bin/brew"
        fi
    fi

    # 현재 스크립트에서 사용할 수 있도록 PATH 추가
    if [[ -n "$BREW_PATH" ]]; then
        eval "$("$BREW_PATH" shellenv)"
    fi
else
    echo "==> Homebrew already installed"
fi

# ==============================================================================
# 2. brew 패키지 설치
# ==============================================================================
# Homebrew로 CLI 도구를 한 번에 설치한다.
# brew install은 이미 설치된 패키지는 자동으로 건너뛰므로 멱등적이다.
#   neovim    : 텍스트 에디터 (LazyVim 설정과 함께 사용)
#   eza       : ls 대체 도구. 색상, 아이콘, git 상태 표시 지원
#   git-delta : git diff를 더 읽기 좋게 표시하는 pager
#   lazygit   : git 터미널 UI 도구
#   gh        : GitHub 공식 CLI 도구
#   yq        : YAML/JSON/TOML 파일 커맨드라인 파싱·편집 도구
#   fzf       : 커맨드라인 퍼지 파인더
#   bat       : cat 대체. 문법 강조, 줄 번호, git diff 표시 지원
#   ripgrep   : grep 대체 (rg). 매우 빠른 정규식 파일 내용 검색
#   fd        : find 대체 도구. 직관적 문법, 빠른 검색
#   tmux      : 터미널 멀티플렉서. 세션·윈도우·패인 관리
#   tree      : 디렉토리 구조를 트리 형태로 출력
echo "==> [brew] Installing packages..."
brew install \
    neovim \
    eza \
    git-delta \
    lazygit \
    gh \
    yq \
    fzf \
    bat \
    ripgrep \
    fd \
    tmux \
    tree

# ==============================================================================
# 2-1. Ghostty (터미널 에뮬레이터, cask)
# ==============================================================================
# Ghostty는 GPU 가속 터미널 에뮬레이터다.
# CLI 도구가 아닌 GUI 앱이므로 brew cask로 설치한다.
if ! brew list --cask ghostty &>/dev/null; then
    echo "==> [brew cask] Installing Ghostty..."
    brew install --cask ghostty
else
    echo "==> Ghostty already installed"
fi

# ==============================================================================
# 2-2. JetBrainsMono Nerd Font (cask)
# ==============================================================================
# Starship, tmux, LazyVim 등이 Nerd Font 전용 글리프를 사용하므로 반드시 필요하다.
# macOS는 ~/Library/Fonts/ 에 설치되며, 터미널 앱(Ghostty 등)에서 폰트 선택 가능.
if ! brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
    echo "==> [brew cask] Installing JetBrainsMono Nerd Font..."
    brew install --cask font-jetbrains-mono-nerd-font
else
    echo "==> JetBrainsMono Nerd Font already installed"
fi

# ==============================================================================
# 3. mise (버전 매니저)
# ==============================================================================
# mise는 Node.js, Bun, pnpm 등 언어 런타임의 버전을 관리한다.
# nvm, rbenv, pyenv를 대체하는 통합 버전 매니저다.
# 설치 후 ~/.local/bin/mise 에 위치하며, .zshrc 에서 activate된다.
# 글로벌 버전은 ~/.mise.toml (dotfiles/mise/.mise.toml 링크)에서 설정한다.
if ! command -v mise &>/dev/null; then
    echo "==> Installing mise..."
    curl https://mise.run | sh
    echo "    mise installed"
else
    echo "==> mise already installed"
fi

# ==============================================================================
# 4. 공통 도구 설치 (common-tools.sh)
# ==============================================================================
# OS에 관계없이 동일하게 설치되는 도구들을 공통 스크립트에서 처리한다.
#   - starship (프롬프트)
#   - Oh My Zsh
#   - fzf-tab (zsh 플러그인)
#   - zsh-autosuggestions (zsh 플러그인)
#   - TPM (Tmux Plugin Manager)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-tools.sh"

# ==============================================================================
# 완료
# ==============================================================================
echo ""
echo "==> macOS tools installation complete!"
echo ""
