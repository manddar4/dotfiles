# ==============================================================================
# Zsh 설정 파일 (Linux / WSL2)
# ==============================================================================
# 이 파일은 dotfiles/zsh/.zshrc 에 있으며, ~/.zshrc 로 심볼릭 링크된다.
# Oh My Zsh를 프레임워크로 사용하며, 프롬프트는 starship이 담당한다.
# ==============================================================================

# ==============================================================================
# Oh My Zsh 설정
# ==============================================================================

export ZSH="$HOME/.oh-my-zsh"

# ZSH_THEME를 비워두면 Oh My Zsh가 프롬프트를 건드리지 않는다.
# 맨 아래에서 starship이 프롬프트를 초기화하므로 충돌 방지를 위해 반드시 비워둬야 한다.
ZSH_THEME=""

# 활성화할 Oh My Zsh 플러그인 목록
#   git: git 관련 alias와 함수 제공 (gst, gco, gp 등)
#   zsh-autosuggestions: 히스토리 기반 명령어 자동 제안 (회색 텍스트로 미리 보기)
#                        linux-tools.sh에서 ~/.oh-my-zsh/custom/plugins/ 에 설치
plugins=(git zsh-autosuggestions)

# Oh My Zsh 로드 (플러그인, 자동완성 초기화 포함)
source "$ZSH/oh-my-zsh.sh"

# ==============================================================================
# PATH 설정
# ==============================================================================
# 우선순위 순서로 앞에서부터 탐색됨:
#   ~/.local/bin    : mise, nvim AppImage, lazygit, yq, fd, bat 등 로컬 바이너리
#   ~/.bun/bin      : bun 및 bun으로 설치한 글로벌 패키지
#   ~/.fzf/bin      : fzf 바이너리
#   $PATH           : 기존 시스템 PATH 유지
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$HOME/.fzf/bin:$PATH"

# ==============================================================================
# 히스토리 설정
# ==============================================================================
# 세션 간 히스토리를 공유하고, 중복 항목을 제거하여 히스토리를 깔끔하게 유지한다.

HISTFILE=~/.zsh_history   # 히스토리 저장 파일 경로
HISTSIZE=50000             # 메모리에 유지할 최대 히스토리 수
SAVEHIST=50000             # 파일에 저장할 최대 히스토리 수

setopt EXTENDED_HISTORY       # 타임스탬프와 실행 시간을 히스토리에 기록
setopt SHARE_HISTORY          # 열린 모든 터미널 세션 간에 히스토리 실시간 공유
setopt HIST_EXPIRE_DUPS_FIRST # 히스토리가 꽉 찼을 때 중복 항목을 먼저 삭제
setopt HIST_IGNORE_DUPS       # 직전과 동일한 명령어는 히스토리에 추가 안 함
setopt HIST_IGNORE_ALL_DUPS   # 히스토리 전체에서 중복 명령어 제거
setopt HIST_FIND_NO_DUPS      # Ctrl+R 검색 시 중복 항목 표시 안 함
setopt HIST_IGNORE_SPACE      # 명령어 앞에 공백을 붙이면 히스토리에 저장 안 됨 (민감한 명령어 숨기기)
setopt HIST_SAVE_NO_DUPS      # 히스토리 파일에 중복 항목 저장 안 함
setopt HIST_VERIFY            # !! 등 히스토리 확장 후 바로 실행하지 않고 확인 요청

# ==============================================================================
# fzf-tab 플러그인 설정
# ==============================================================================
# fzf-tab은 zsh의 Tab 자동완성 메뉴를 fzf 인터페이스로 교체한다.
# Oh My Zsh source 후, fzf 키 바인딩 source 전에 로드해야 정상 동작함.
# linux-tools.sh에서 ~/.local/share/fzf-tab 에 설치됨.

if [[ -d "$HOME/.local/share/fzf-tab" ]]; then
    source "$HOME/.local/share/fzf-tab/fzf-tab.plugin.zsh"

    # cd 자동완성 시 우측에 해당 디렉토리 내용 미리 보기 (eza 사용)
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

    # fzf-tab 팝업 창 크기 및 레이아웃 설정
    zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border
fi

# ==============================================================================
# fzf 키 바인딩 및 자동완성
# ==============================================================================
# install.sh에서 ~/.fzf/install 실행 시 ~/.fzf.zsh 가 생성된다.
# 이 파일이 fzf의 키 바인딩과 자동완성을 활성화한다:
#   Ctrl+R : 히스토리 검색 (fzf 팝업)
#   Ctrl+T : 파일 검색 후 커맨드라인에 삽입
#   Alt+C  : 디렉토리 검색 후 cd

if [[ -f "$HOME/.fzf.zsh" ]]; then
    source "$HOME/.fzf.zsh"
fi

# fzf 기본 옵션 (Dracula 컬러 테마)
# 모든 fzf 호출(Ctrl+R, fzf-tab, 스크립트 내 fzf 등)에 적용됨
export FZF_DEFAULT_OPTS="
  --height=40%
  --layout=reverse
  --border
  --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9
  --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9
  --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6
  --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4
"

# ==============================================================================
# Alias 설정
# ==============================================================================

# --- 파일 탐색 (eza: ls 대체) ---
# eza는 색상, 아이콘, git 상태 등을 지원하는 현대적인 ls 대체 도구
alias ls='eza'       # 기본 목록
alias ll='eza -l'    # 상세 목록 (권한, 크기, 날짜)
alias la='eza -la'   # 숨김 파일 포함 상세 목록
alias lt='eza --tree' # 트리 구조로 표시

# --- 패키지 매니저 단축키 ---
alias p='pnpm'   # pnpm (mise로 설치됨)
alias n='npm'    # npm
alias b='bun'    # bun

# --- 개발 도구 ---
alias sb='supabase'  # Supabase CLI
alias lg='lazygit'   # lazygit TUI

# ==============================================================================
# mise (버전 매니저) 활성화
# ==============================================================================
# mise는 Node.js, Bun, pnpm 등의 버전을 프로젝트별로 관리한다.
# activate zsh: 디렉토리 이동 시 .mise.toml 을 감지하여 버전 자동 전환
if command -v mise &> /dev/null; then
    eval "$(mise activate zsh)"
fi
# mise shims를 PATH 맨 앞에 추가 (Windows npm 등보다 우선)
export PATH="$HOME/.local/share/mise/shims:$PATH"

# ==============================================================================
# bun 자동완성
# ==============================================================================
# bun 설치 시 자동으로 생성되는 자동완성 스크립트
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ==============================================================================
# Starship 프롬프트 초기화
# ==============================================================================
# 반드시 파일의 가장 마지막에 위치해야 한다.
# ZSH_THEME=""로 Oh My Zsh 테마를 비활성화했으므로 충돌 없이 동작한다.
# 프롬프트 형식은 dotfiles/starship/starship.toml 에서 설정한다.
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi
