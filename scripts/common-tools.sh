#!/bin/bash

# ==============================================================================
# 공통 도구 설치 스크립트 (Linux / macOS 공유)
# ==============================================================================
# OS에 관계없이 동일하게 설치되는 도구들을 모아놓은 스크립트.
# git clone, curl 설치 등 플랫폼 독립적인 방식으로 설치한다.
# 각 플랫폼별 스크립트(linux-tools.sh, macos-tools.sh)에서 source하여 사용한다.
#
# 설치 목록:
#   [git clone]     fzf, fzf-tab, Oh My Zsh, zsh-autosuggestions, TPM
#   [curl 설치]     starship (프롬프트)
# ==============================================================================

set -e  # 오류 발생 시 즉시 종료

# ==============================================================================
# 9. fzf (퍼지 파인더)
# ==============================================================================
# fzf는 명령줄 퍼지 파인더로, Ctrl+R(히스토리), Ctrl+T(파일), Alt+C(디렉토리)
# 키 바인딩을 제공한다. 패키지 매니저(brew 등)로 이미 설치된 경우 건너뛴다.
# 없으면 ~/.fzf 에 git clone으로 설치하고, install.sh에서
# ~/.fzf/install 을 실행하여 ~/.fzf.zsh 키 바인딩 파일을 생성한다.
if command -v fzf &> /dev/null; then
    echo "==> fzf already installed ($(fzf --version | head -1))"
elif [[ ! -d "$HOME/.fzf" ]]; then
    echo "==> Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    echo "    fzf cloned (key bindings will be installed by install.sh)"
else
    echo "==> fzf already installed (~/.fzf)"
fi

# ==============================================================================
# 10. Oh My Zsh
# ==============================================================================
# Oh My Zsh는 zsh 설정 프레임워크로, 플러그인·테마 관리를 담당한다.
# RUNZSH=no : 설치 후 zsh로 자동 전환하지 않음 (스크립트 계속 실행)
# CHSH=no   : 기본 쉘을 자동으로 변경하지 않음
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "==> Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    echo "    Oh My Zsh installed"
else
    echo "==> Oh My Zsh already installed"
fi

# ==============================================================================
# 11. starship (프롬프트)
# ==============================================================================
# starship은 빠르고 커스터마이즈 가능한 크로스 쉘 프롬프트다.
# .zshrc 에서 eval "$(starship init zsh)" 으로 활성화된다.
# 설정은 dotfiles/starship/starship.toml → ~/.config/starship.toml 로 링크됨.
if ! command -v starship &> /dev/null; then
    echo "==> Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
    echo "    starship installed"
else
    echo "==> starship already installed"
fi

# ==============================================================================
# 12. fzf-tab (zsh 플러그인, git clone)
# ==============================================================================
# fzf-tab은 zsh의 기본 Tab 자동완성 UI를 fzf 인터페이스로 교체한다.
# Homebrew로 설치할 수 없어 git clone으로 설치한다.
# .zshrc 에서 source하여 로드한다.
FZF_TAB_DIR="$HOME/.local/share/fzf-tab"
if [[ ! -d "$FZF_TAB_DIR" ]]; then
    echo "==> Installing fzf-tab..."
    git clone https://github.com/Aloxaf/fzf-tab "$FZF_TAB_DIR"
    echo "    fzf-tab installed"
else
    echo "==> fzf-tab already installed"
fi

# ==============================================================================
# 13. zsh-autosuggestions (Oh My Zsh 커스텀 플러그인, git clone)
# ==============================================================================
# 히스토리 기반으로 명령어를 회색 텍스트로 미리 제안한다.
# → 방향키 오른쪽(→) 또는 Ctrl+F 로 제안 수락
# Oh My Zsh custom 플러그인 디렉토리에 설치하면 plugins=() 목록에 추가만 하면 된다.
ZSH_AUTOSUGGEST_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
if [[ ! -d "$ZSH_AUTOSUGGEST_DIR" ]]; then
    echo "==> Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGEST_DIR"
    echo "    zsh-autosuggestions installed"
else
    echo "==> zsh-autosuggestions already installed"
fi

# ==============================================================================
# 14. TPM (Tmux Plugin Manager, git clone)
# ==============================================================================
# TPM은 tmux 플러그인을 관리하는 도구다.
# tmux 내에서 Ctrl+a → I 로 .tmux.conf 에 정의된 플러그인을 설치한다.
# 현재 .tmux.conf 에서 사용하는 플러그인:
#   - tmux-resurrect : 세션 저장/복구
#   - tmux-continuum : 15분마다 자동 저장, 부팅 시 자동 복구
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
    echo "==> Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    echo "    TPM installed"
else
    echo "==> TPM already installed"
fi
