#!/bin/bash

# ==============================================================================
# Linux 도구 설치 스크립트 (Ubuntu 24.04 / WSL2 전용)
# ==============================================================================
# 이 스크립트는 멱등적(idempotent)으로 설계되어 있다.
# 각 도구를 설치하기 전에 이미 설치되어 있는지 확인하고, 있으면 건너뜀.
# install.sh 에서 자동으로 호출되며, 단독 실행도 가능하다.
#
# Linux 전용 설치 목록 (apt, .deb, 바이너리 등):
#   [apt]           build-essential, curl, wget, unzip, tree, xclip,
#                   fontconfig, fd-find, bat, ripgrep
#   [GitHub 릴리즈] Neovim stable (AppImage)
#   [apt 공식 저장소] eza (eza-community)
#   [.deb 패키지]   git-delta v0.18.2
#   [tar.gz]        lazygit v0.44.1
#   [apt 공식 저장소] gh (GitHub CLI)
#   [바이너리]       yq v4.44.3
#   [curl 설치]     mise (버전 매니저)
#   [GitHub 릴리즈] JetBrainsMono Nerd Font v3.3.0
#
# 공통 도구 (common-tools.sh에서 설치):
#   [curl 설치]     starship (프롬프트)
#   [git clone]     fzf, fzf-tab, Oh My Zsh, zsh-autosuggestions, TPM
# ==============================================================================

set -e  # 오류 발생 시 즉시 종료

# 로컬 바이너리 디렉토리 (~/.local/bin)
# PATH에 포함되어 있어 여기 있는 바이너리는 어디서든 실행 가능
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

# 아키텍처 감지 (x86_64 / aarch64)
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  DEB_ARCH="amd64"; BINARY_ARCH="x86_64" ;;
    aarch64) DEB_ARCH="arm64"; BINARY_ARCH="aarch64" ;;
    *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

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
    zsh \
    git \
    fontconfig \
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
    curl -fsSL "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-${BINARY_ARCH}.appimage" \
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
    DELTA_DEB="/tmp/git-delta_${DELTA_VERSION}_${DEB_ARCH}.deb"
    curl -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_${DEB_ARCH}.deb" \
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
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${BINARY_ARCH}.tar.gz" \
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
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${DEB_ARCH}" \
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
# 9. JetBrainsMono Nerd Font
# ==============================================================================
# Starship, tmux, LazyVim 등이 Nerd Font 전용 글리프를 사용하므로 반드시 필요하다.
# GitHub 릴리즈에서 tar.xz를 다운받아 ~/.local/share/fonts/ 에 설치한다.
#
# 주의 (WSL2): 실제 렌더링은 Windows Terminal이 담당하므로,
#   이 설치는 네이티브 Linux 터미널(Alacritty, Kitty 등) 용이다.
#   WSL2에서 Windows Terminal 글리프를 고치려면 install-windows.ps1 도 실행해야 한다.
NERD_FONT_VERSION="v3.3.0"
FONT_DIR="$HOME/.local/share/fonts"
if fc-list | grep -qi "JetBrainsMono"; then
    echo "==> JetBrainsMono Nerd Font already installed"
else
    echo "==> Installing JetBrainsMono Nerd Font $NERD_FONT_VERSION..."
    mkdir -p "$FONT_DIR"
    curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/JetBrainsMono.tar.xz" \
        -o /tmp/JetBrainsMono.tar.xz
    tar -xf /tmp/JetBrainsMono.tar.xz -C "$FONT_DIR"
    rm -f /tmp/JetBrainsMono.tar.xz
    fc-cache -fv > /dev/null
    echo "    JetBrainsMono Nerd Font installed"
fi

# ==============================================================================
# 공통 도구 설치 (Oh My Zsh, fzf, starship, fzf-tab, zsh-autosuggestions, TPM)
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-tools.sh"

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
echo "    WSL2 사용자 주의: 글리프(아이콘)를 올바르게 표시하려면"
echo "      Windows 쪽에서도 install-windows.ps1 을 실행하여"
echo "      JetBrainsMono Nerd Font를 Windows에 설치해야 합니다."
echo ""
