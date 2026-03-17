#!/bin/bash

# ==============================================================================
# Linux 도구 설치 스크립트 (Ubuntu 24.04 / WSL2 전용)
# ==============================================================================
# 이 스크립트는 멱등적(idempotent)으로 설계되어 있다.
# 각 도구를 설치하기 전에 이미 설치되어 있는지 확인하고, 있으면 건너뜀.
# install.sh 에서 자동으로 호출되며, 단독 실행도 가능하다.
#
# 설치 목록:
#   [apt]           build-essential, curl, wget, unzip, tree, xclip,
#                   fd-find, bat, ripgrep
#   [GitHub 릴리즈] Neovim stable (AppImage)
#   [apt 공식 저장소] eza (eza-community)
#   [.deb 패키지]   git-delta v0.18.2
#   [tar.gz]        lazygit v0.44.1
#   [apt 공식 저장소] gh (GitHub CLI)
#   [바이너리]       yq v4.44.3
#   [curl 설치]     mise (버전 매니저), starship (프롬프트)
#   [git clone]     fzf, fzf-tab, Oh My Zsh, zsh-autosuggestions, TPM
# ==============================================================================

set -e  # 오류 발생 시 즉시 종료

# 로컬 바이너리 디렉토리 (~/.local/bin)
# PATH에 포함되어 있어 여기 있는 바이너리는 어디서든 실행 가능
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

echo "==> Installing Linux tools..."

# ==============================================================================
# 1. apt 패키지 설치
# ==============================================================================
# 기본 개발 도구와 CLI 유틸리티를 apt로 설치한다.
#   build-essential : gcc, make 등 C 컴파일 도구 (일부 도구 빌드 시 필요)
#   curl / wget     : URL로 파일 다운로드 (각종 설치 스크립트에 사용)
#   unzip           : .zip 파일 압축 해제
#   tree            : 디렉토리 구조를 트리 형태로 출력
#   xclip           : X11 클립보드 접근 도구
#   fd-find         : find 대체 도구 (Ubuntu에서는 'fdfind'로 설치됨 → fd 링크 생성)
#   bat             : cat 대체. 문법 강조, 줄 번호, git diff 표시 지원
#   ripgrep         : grep 대체 (rg). 매우 빠른 정규식 파일 내용 검색
echo "==> [apt] Installing base packages..."
sudo apt-get update -qq
sudo apt-get install -y \
    build-essential \
    curl \
    wget \
    unzip \
    tree \
    xclip \
    fd-find \
    bat \
    ripgrep

# Ubuntu에서 fd-find는 'fdfind' 이름으로 설치됨 → ~/.local/bin/fd 링크 생성
# 이렇게 하면 fd 명령어로 사용 가능
if ! command -v fd &> /dev/null; then
    if command -v fdfind &> /dev/null; then
        ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
        echo "    Created symlink: fd -> fdfind"
    fi
fi

# Ubuntu 22.04 이전에서는 bat이 'batcat' 이름으로 설치됨 → ~/.local/bin/bat 링크 생성
# Ubuntu 24.04에서는 'bat'으로 직접 설치되지만, 혹시 모르니 fallback 처리
if ! command -v bat &> /dev/null; then
    if command -v batcat &> /dev/null; then
        ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
        echo "    Created symlink: bat -> batcat"
    fi
fi

# ==============================================================================
# 2. Neovim (AppImage)
# ==============================================================================
# 공식 GitHub 릴리즈에서 AppImage를 다운받아 설치한다.
# AppImage는 단일 실행 파일로 별도 설치 없이 바로 실행 가능하다.
#
# FUSE 이슈:
#   WSL2에서 AppImage 실행에 FUSE가 필요할 수 있다.
#   FUSE가 없으면 --appimage-extract 로 파일을 추출하여 실행한다.
NVIM_VERSION="stable"
if ! command -v nvim &> /dev/null; then
    echo "==> Installing Neovim ($NVIM_VERSION)..."
    NVIM_APPIMAGE="$LOCAL_BIN/nvim.appimage"

    # AppImage 다운로드
    curl -fsSL "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.appimage" \
        -o "$NVIM_APPIMAGE"
    chmod +x "$NVIM_APPIMAGE"

    # FUSE 사용 가능 여부 테스트
    if "$NVIM_APPIMAGE" --version &> /dev/null; then
        # FUSE 정상 → AppImage를 직접 nvim으로 링크
        ln -sf "$NVIM_APPIMAGE" "$LOCAL_BIN/nvim"
        echo "    Neovim installed (AppImage with FUSE)"
    else
        # FUSE 없음 → AppImage를 디렉토리로 추출 후 내부 바이너리를 링크
        echo "    FUSE not available — extracting AppImage..."
        cd "$HOME/.local"
        "$NVIM_APPIMAGE" --appimage-extract > /dev/null
        # 추출된 디렉토리 이름을 nvim-extracted 로 변경
        mv squashfs-root nvim-extracted 2>/dev/null || true
        ln -sf "$HOME/.local/nvim-extracted/usr/bin/nvim" "$LOCAL_BIN/nvim"
        cd - > /dev/null
        echo "    Neovim installed (extracted AppImage)"
    fi
else
    echo "==> Neovim already installed ($(nvim --version | head -1))"
fi

# ==============================================================================
# 3. eza (공식 apt 저장소)
# ==============================================================================
# eza는 ls 대체 도구로, 색상, 아이콘, git 상태 표시를 지원한다.
# eza-community 공식 apt 저장소를 추가하여 설치한다.
if ! command -v eza &> /dev/null; then
    echo "==> Installing eza..."
    sudo apt-get install -y gpg  # GPG 키 처리 도구
    sudo mkdir -p /etc/apt/keyrings

    # eza 저장소의 GPG 서명 키 등록
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg

    # apt 소스 목록에 eza 저장소 추가
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
        | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null

    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt-get update -qq
    sudo apt-get install -y eza
    echo "    eza installed"
else
    echo "==> eza already installed"
fi

# ==============================================================================
# 4. git-delta (.deb 패키지)
# ==============================================================================
# delta는 git diff를 더 읽기 좋게 표시하는 pager다.
# side-by-side 보기, 문법 강조, 줄 번호 표시 등을 지원한다.
# git/.gitconfig 에서 core.pager = delta 로 설정되어 있다.
DELTA_VERSION="0.18.2"
if ! command -v delta &> /dev/null; then
    echo "==> Installing git-delta $DELTA_VERSION..."
    DELTA_DEB="/tmp/git-delta_${DELTA_VERSION}_amd64.deb"
    curl -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb" \
        -o "$DELTA_DEB"
    sudo dpkg -i "$DELTA_DEB"
    rm -f "$DELTA_DEB"
    echo "    git-delta installed"
else
    echo "==> git-delta already installed"
fi

# ==============================================================================
# 5. lazygit (tar.gz)
# ==============================================================================
# lazygit은 git을 위한 터미널 UI 도구다.
# 스테이징, 커밋, 브랜치 관리 등을 키보드로 빠르게 처리할 수 있다.
# .zshrc 에서 lg='lazygit' alias로 사용한다.
LAZYGIT_VERSION="0.44.1"
if ! command -v lazygit &> /dev/null; then
    echo "==> Installing lazygit $LAZYGIT_VERSION..."
    LAZYGIT_TMP="/tmp/lazygit.tar.gz"
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
        -o "$LAZYGIT_TMP"
    # tar에서 lazygit 바이너리만 추출하여 ~/.local/bin 에 저장
    tar -xzf "$LAZYGIT_TMP" -C "$LOCAL_BIN" lazygit
    rm -f "$LAZYGIT_TMP"
    echo "    lazygit installed"
else
    echo "==> lazygit already installed"
fi

# ==============================================================================
# 6. gh (GitHub CLI, 공식 apt 저장소)
# ==============================================================================
# gh는 GitHub의 공식 CLI 도구로, PR 생성·조회, issue 관리,
# 저장소 클론 등 GitHub 작업을 터미널에서 처리할 수 있다.
if ! command -v gh &> /dev/null; then
    echo "==> Installing GitHub CLI..."
    # GitHub CLI GPG 키 등록
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

    # GitHub CLI apt 저장소 추가
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    sudo apt-get update -qq
    sudo apt-get install -y gh
    echo "    gh installed"
else
    echo "==> gh already installed"
fi

# ==============================================================================
# 7. yq (YAML 처리 도구, 바이너리)
# ==============================================================================
# yq는 jq의 YAML 버전으로, YAML/JSON/TOML 파일을 커맨드라인에서 파싱·편집한다.
# 설정 파일 조작이나 CI/CD 스크립트에서 유용하게 쓰인다.
YQ_VERSION="v4.44.3"
if ! command -v yq &> /dev/null; then
    echo "==> Installing yq $YQ_VERSION..."
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
        -o "$LOCAL_BIN/yq"
    chmod +x "$LOCAL_BIN/yq"
    echo "    yq installed"
else
    echo "==> yq already installed"
fi

# ==============================================================================
# 8. mise (버전 매니저)
# ==============================================================================
# mise는 Node.js, Bun, pnpm 등 언어 런타임의 버전을 관리한다.
# nvm, rbenv, pyenv를 대체하는 통합 버전 매니저다.
# 설치 후 ~/.local/bin/mise 에 위치하며, .zshrc 에서 activate된다.
# 글로벌 버전은 ~/.mise.toml (dotfiles/mise/.mise.toml 링크)에서 설정한다.
if ! command -v mise &> /dev/null; then
    echo "==> Installing mise..."
    # 공식 설치 스크립트. ~/.local/bin/mise 에 설치됨
    curl https://mise.run | sh
    echo "    mise installed"
else
    echo "==> mise already installed"
fi

# ==============================================================================
# 9. fzf (퍼지 파인더)
# ==============================================================================
# fzf는 명령줄 퍼지 파인더로, Ctrl+R(히스토리), Ctrl+T(파일), Alt+C(디렉토리)
# 키 바인딩을 제공한다. ~/.fzf 에 git clone으로 설치하고, install.sh에서
# ~/.fzf/install 을 실행하여 ~/.fzf.zsh 키 바인딩 파일을 생성한다.
if [[ ! -d "$HOME/.fzf" ]]; then
    echo "==> Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    echo "    fzf cloned (key bindings will be installed by install.sh)"
else
    echo "==> fzf already installed"
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

# ==============================================================================
# 완료
# ==============================================================================
echo ""
echo "==> Linux tools installation complete!"
echo ""
echo "    참고: Neovim AppImage 실행이 안 될 경우 수동 추출:"
echo "      ~/.local/bin/nvim.appimage --appimage-extract"
echo "      mv \$HOME/.local/squashfs-root \$HOME/.local/nvim-extracted"
echo "      ln -sf \$HOME/.local/nvim-extracted/usr/bin/nvim \$HOME/.local/bin/nvim"
echo ""
