# ==============================================================================
# PowerShell 프로파일 (Windows 네이티브)
# ==============================================================================
# zsh/.zshrc의 Windows 대응 버전.
# dotfiles/powershell/profile.ps1 → $PROFILE 로 심볼릭 링크된다.
# ==============================================================================

# ==============================================================================
# PSReadLine 설정 (Dracula 테마 + Vi 모드 대안)
# ==============================================================================
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView

    # Dracula 색상
    Set-PSReadLineOption -Colors @{
        Command          = '#50fa7b'
        Parameter        = '#ffb86c'
        Operator         = '#ff79c6'
        Variable         = '#f8f8f2'
        String           = '#f1fa8c'
        Number           = '#bd93f9'
        Type             = '#8be9fd'
        Comment          = '#6272a4'
        Keyword          = '#ff79c6'
        Error            = '#ff5555'
        Selection        = '#44475a'
        InlinePrediction = '#6272a4'
    }
}

# ==============================================================================
# fzf 설정
# ==============================================================================
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    # PSFzf 모듈이 있으면 키 바인딩 활성화
    if (Get-Module -ListAvailable -Name PSFzf) {
        Import-Module PSFzf
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    }

    # Dracula 테마
    $env:FZF_DEFAULT_OPTS = "--height=40% --layout=reverse --border --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"
}

# ==============================================================================
# Alias 설정
# ==============================================================================

# 파일 탐색 (eza)
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    function ls { eza @args }
    function ll { eza -l @args }
    function la { eza -la @args }
    function lt { eza --tree @args }
}

# 패키지 매니저 단축키
Set-Alias -Name p -Value pnpm -ErrorAction SilentlyContinue
Set-Alias -Name n -Value npm -ErrorAction SilentlyContinue
Set-Alias -Name b -Value bun -ErrorAction SilentlyContinue

# 개발 도구
Set-Alias -Name lg -Value lazygit -ErrorAction SilentlyContinue

# ==============================================================================
# mise (버전 매니저) 활성화
# ==============================================================================
if (Get-Command mise -ErrorAction SilentlyContinue) {
    mise activate pwsh | Out-String | Invoke-Expression
}

# ==============================================================================
# bun 자동완성
# ==============================================================================
if (Get-Command bun -ErrorAction SilentlyContinue) {
    # bun completions (if available)
    $bunCompletion = "$env:USERPROFILE\.bun\_bun.ps1"
    if (Test-Path $bunCompletion) { . $bunCompletion }
}

# ==============================================================================
# Starship 프롬프트 초기화 (반드시 마지막에 위치)
# ==============================================================================
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
