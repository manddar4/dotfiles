#!/bin/bash

# ==============================================================================
# Dotfiles 설치 스크립트 (Linux / WSL2 / macOS)
# ==============================================================================
# 이 스크립트는 멱등적(idempotent)으로 설계되어 있어 반복 실행해도 안전하다.
# OS를 자동 감지하여 적절한 도구 설치 스크립트를 실행한다.
#
# 실행 순서:
#   1. OS 감지 (Linux / macOS)
#   2. 도구 설치 (scripts/linux-tools.sh 또는 scripts/macos-tools.sh)
#   3. LazyVim 초기 설정 (nvim/ 디렉토리가 비어있을 때만)
#   4. 심볼릭 링크 생성 (설정 파일들을 홈 디렉토리에 연결)
#   5. fzf 키 바인딩 설치
#   6. mise 버전 매니저 설정
#   7. bun 글로벌 패키지 설치
#   8. dev 스크립트 설치
#   9. gitconfig.local 생성 (머신별 설정)
#
# Windows: install-windows.ps1 을 사용하세요.
# ==============================================================================

set -e  # 오류 발생 시 즉시 종료

# 이 스크립트가 있는 디렉토리 = dotfiles 루트
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# OS 감지
# ==============================================================================
OS_TYPE=""
case "$(uname -s)" in
    Linux*)  OS_TYPE="linux" ;;
    Darwin*) OS_TYPE="macos" ;;
    *)       echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

echo "==> Dotfiles installation starting..."
echo "    Dotfiles directory: $DOTFILES_DIR"
echo "    OS: $OS_TYPE ($(uname -m))"

# ==============================================================================
# 헬퍼 함수
# ==============================================================================

# create_symlink <source> <target>
#   심볼릭 링크를 생성한다.
#   - 대상 경로의 부모 디렉토리가 없으면 자동 생성
#   - 기존 파일이나 링크가 있으면 덮어씀 (rm -f 후 ln -sf)
create_symlink() {
    local source="$1"
    local target="$2"

    # 부모 디렉토리가 없으면 생성 (mkdir -p는 이미 있어도 오류 없음)
    mkdir -p "$(dirname "$target")"

    # 기존 심볼릭 링크 또는 파일 제거 (덮어쓰기)
    if [[ -L "$target" ]] || [[ -f "$target" ]]; then
        rm -f "$target"
    fi

    # 심볼릭 링크 생성 (-s: symbolic, -f: force)
    ln -sf "$source" "$target"
    echo "    $target -> $source"
}

# ==============================================================================
# 1. 도구 설치 (OS별 분기)
# ==============================================================================
# Linux: scripts/linux-tools.sh (apt, .deb, AppImage 등)
# macOS: scripts/macos-tools.sh (Homebrew)
# 공통 도구는 scripts/common-tools.sh 에서 처리 (각 스크립트가 source)
case "$OS_TYPE" in
    linux)
        echo "==> Installing Linux tools..."
        bash "$DOTFILES_DIR/scripts/linux-tools.sh"
        ;;
    macos)
        echo "==> Installing macOS tools..."
        bash "$DOTFILES_DIR/scripts/macos-tools.sh"
        ;;
esac

# ==============================================================================
# 2. LazyVim 초기 설정
# ==============================================================================
# nvim/init.lua 가 없을 때만 LazyVim starter를 클론한다.
# 이미 설정이 있으면 (init.lua 존재) 건너뜀.
NVIM_DIR="$DOTFILES_DIR/nvim"
if [[ ! -f "$NVIM_DIR/init.lua" ]]; then
    echo "==> Setting up LazyVim starter..."

    # 기존 nvim 설정이 심볼릭 링크가 아닌 실제 디렉토리면 백업
    if [[ -d "$HOME/.config/nvim" ]] && [[ ! -L "$HOME/.config/nvim" ]]; then
        echo "    Backing up existing nvim config..."
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
    fi

    # LazyVim starter를 dotfiles/nvim/ 에 클론 (.git 제거하여 dotfiles repo에 통합)
    rm -rf "$NVIM_DIR"
    git clone https://github.com/LazyVim/starter "$NVIM_DIR"
    rm -rf "$NVIM_DIR/.git"
    echo "    LazyVim starter cloned"
else
    echo "==> LazyVim already configured"
fi

# ==============================================================================
# 3. 심볼릭 링크 생성
# ==============================================================================
# 설정 파일들을 홈 디렉토리에 심볼릭 링크로 연결한다.
# 변경 사항이 즉시 반영되며, dotfiles repo에서 직접 관리 가능.
echo "==> Creating symbolic links..."

# zsh: Linux 전용 설정 파일을 ~/.zshrc 로 연결
create_symlink "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

# git: 글로벌 git 설정 (~/.gitconfig)
create_symlink "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# starship: 프롬프트 설정 (~/.config/starship.toml)
create_symlink "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

# tmux: tmux 설정 (~/.tmux.conf)
create_symlink "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

# neovim: nvim 설정 디렉토리를 통째로 링크 (~/.config/nvim -> dotfiles/nvim/)
# 파일이 아닌 디렉토리이므로 create_symlink 대신 직접 처리
if [[ -d "$HOME/.config/nvim" ]] && [[ ! -L "$HOME/.config/nvim" ]]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
fi
rm -rf "$HOME/.config/nvim"
ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
echo "    $HOME/.config/nvim -> $DOTFILES_DIR/nvim"

# ghostty: macOS 전용 터미널 설정 (~/.config/ghostty/config)
if [[ "$OS_TYPE" == "macos" ]]; then
    create_symlink "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"
fi

# ==============================================================================
# 4. fzf 키 바인딩 및 자동완성 설치
# ==============================================================================
# ~/.fzf/install 로 fzf의 키 바인딩(Ctrl+R, Ctrl+T, Alt+C)과
# 셸 자동완성을 ~/.fzf.zsh 에 설치한다.
# --no-update-rc: .zshrc 자동 수정 안 함 (수동으로 source하기 때문)
# --no-bash --no-fish: zsh만 설정
echo "==> Setting up fzf key bindings..."
FZF_INSTALL=""
if [[ -f "$HOME/.fzf/install" ]]; then
    FZF_INSTALL="$HOME/.fzf/install"
elif [[ "$OS_TYPE" == "macos" ]] && command -v brew &> /dev/null; then
    # Homebrew로 설치한 fzf는 다른 경로에 install 스크립트가 있다
    BREW_FZF="$(brew --prefix)/opt/fzf/install"
    [[ -f "$BREW_FZF" ]] && FZF_INSTALL="$BREW_FZF"
fi

if [[ -n "$FZF_INSTALL" ]]; then
    "$FZF_INSTALL" --key-bindings --completion --no-update-rc --no-bash --no-fish
else
    echo "    fzf not found — skipping"
fi

# ==============================================================================
# 5. mise (버전 매니저) 설정
# ==============================================================================
# ~/.mise.toml 에 정의된 Node.js, Bun, pnpm 등의 버전을 설치한다.
# mise trust: 신뢰할 설정 파일로 등록 (activate 시 자동 적용)
echo "==> Setting up mise..."
create_symlink "$DOTFILES_DIR/mise/.mise.toml" "$HOME/.mise.toml"

if command -v mise &> /dev/null; then
    echo "==> Installing mise tools (node, bun, pnpm)..."
    mise install
    mise trust "$HOME/.mise.toml"
    # ~/workspaces 하위 프로젝트의 .mise.toml도 자동 신뢰
    mise settings set trusted_config_paths "~/workspaces"
else
    echo "    mise not found — skipping (run linux-tools.sh first)"
fi

# ==============================================================================
# 6. bun 글로벌 패키지 설치
# ==============================================================================
# bun/global-packages.txt 에 나열된 패키지를 전역 설치한다.
# 이미 설치된 패키지도 bun이 업데이트하거나 건너뜀.
echo "==> Installing bun global packages..."
if command -v bun &> /dev/null; then
    while IFS= read -r package || [[ -n "$package" ]]; do
        # # 로 시작하는 주석 줄 건너뜀
        [[ "$package" =~ ^#.*$ ]] && continue
        # 빈 줄 건너뜀
        [[ -z "$package" ]] && continue

        echo "    Installing $package..."
        bun add -g "$package" 2>/dev/null || true
    done < "$DOTFILES_DIR/bun/global-packages.txt"
else
    echo "    bun not found — skipping"
fi

# ==============================================================================
# 7. dev 스크립트 설치
# ==============================================================================
# scripts/dev를 ~/.local/bin/dev 에 심볼릭 링크로 설치한다.
# ~/.local/bin은 .zshrc에서 PATH에 포함되어 있어 어디서든 'dev' 명령 사용 가능.
#
# 주의: 기존 파일이 root 소유라면 먼저 수동 제거 필요:
#   sudo rm ~/.local/bin/dev
echo "==> Installing dev script..."
mkdir -p "$HOME/.local/bin"
create_symlink "$DOTFILES_DIR/scripts/dev" "$HOME/.local/bin/dev"

# ==============================================================================
# 8. gitconfig.local 생성 (머신별 설정)
# ==============================================================================
# user.name, user.email, credential helper 등 머신마다 다른 설정을 저장한다.
# git/.gitconfig 에서 [include] path = ~/.gitconfig.local 로 참조됨.
# 이미 존재하면 덮어쓰지 않는다.
echo "==> Setting up gitconfig.local..."
GITCONFIG_LOCAL="$HOME/.gitconfig.local"
if [[ ! -f "$GITCONFIG_LOCAL" ]]; then
    GH_PATH=""
    if command -v gh &> /dev/null; then
        GH_PATH="$(command -v gh)"
    fi

    cat > "$GITCONFIG_LOCAL" << EOF
[user]
	name =
	email =
[credential "https://github.com"]
	helper =
	helper = !${GH_PATH} auth git-credential
[credential "https://gist.github.com"]
	helper =
	helper = !${GH_PATH} auth git-credential
EOF
    echo "    Created $GITCONFIG_LOCAL (name/email을 설정하세요)"
else
    echo "    $GITCONFIG_LOCAL already exists"
fi

# ==============================================================================
# 완료
# ==============================================================================
echo ""
echo "==> Installation complete!"
echo ""
echo "    다음 단계:"
echo "      1. 터미널 재시작 또는: source ~/.zshrc"
echo "      2. ~/.gitconfig.local 에서 name/email 설정"
echo "      3. Neovim 실행 시 플러그인 자동 설치됨"
echo "      4. tmux 안에서 Ctrl+a → I 로 TPM 플러그인 설치"
echo ""
echo "    주요 명령어:"
echo "      dev              # 현재 디렉토리에서 개발 세션 시작"
echo "      dev <name>       # worktree + tmux 세션 생성"
echo "      dev -l           # 세션 목록 보기"
echo "      dev -c <name>    # 세션 정리"
echo ""
