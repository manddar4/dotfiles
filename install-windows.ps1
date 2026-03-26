# install-windows.ps1
# Windows 네이티브 환경 설치 스크립트 (PowerShell + Scoop)
# 관리자 권한 없이 실행 가능. 멱등적(idempotent) 설계.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==> Dotfiles installation starting (Windows)..."
Write-Host "    Dotfiles directory: $DotfilesDir"

# --- Helper ---
function Create-Symlink {
    param([string]$Source, [string]$Target)
    $parentDir = Split-Path -Parent $Target
    if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
    if (Test-Path $Target) { Remove-Item $Target -Force -Recurse }
    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force | Out-Null
        Write-Host "    $Target -> $Source"
    } catch {
        Write-Host "    [ERROR] 심볼릭 링크 생성 실패: $Target" -ForegroundColor Red
        Write-Host "    Windows 설정 > 개발자 모드를 활성화하거나, 관리자 권한으로 실행하세요." -ForegroundColor Yellow
        Write-Host "    (설정 > 시스템 > 개발자용 > 개발자 모드 켜기)" -ForegroundColor Yellow
    }
}

# 1. Scoop 설치
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "==> Installing Scoop..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

# 2. Scoop buckets 추가
Write-Host "==> Adding Scoop buckets..."
scoop bucket add extras 2>$null
scoop bucket add nerd-fonts 2>$null

# 3. 도구 설치
Write-Host "==> Installing tools via Scoop..."
$tools = @(
    "neovim",
    "eza",
    "delta",
    "lazygit",
    "gh",
    "yq",
    "fzf",
    "bat",
    "ripgrep",
    "fd",
    "starship",
    "mise",
    "bun",
    "tree"
)
foreach ($tool in $tools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host "    Installing $tool..."
        scoop install $tool
    } else {
        Write-Host "    $tool already installed"
    }
}

# 4. JetBrainsMono Nerd Font
# Starship, tmux, LazyVim 등이 Nerd Font 전용 글리프를 사용하므로 반드시 필요하다.
# nerd-fonts 버킷은 위 2번 단계에서 이미 추가되어 있다.
Write-Host "==> Installing JetBrainsMono Nerd Font..."
if (-not (scoop list | Select-String "JetBrainsMono-NF")) {
    scoop install JetBrainsMono-NF
    Write-Host "    JetBrainsMono Nerd Font installed"
} else {
    Write-Host "    JetBrainsMono Nerd Font already installed"
}

# 5. mise 설정
Write-Host "==> Setting up mise..."
Create-Symlink "$DotfilesDir\mise\.mise.toml" "$env:USERPROFILE\.mise.toml"
if (Get-Command mise -ErrorAction SilentlyContinue) {
    mise install
    mise trust "$env:USERPROFILE\.mise.toml"
    mise settings set trusted_config_paths "~/workspaces"
}

# 6. bun 글로벌 패키지
Write-Host "==> Installing bun global packages..."
if (Get-Command bun -ErrorAction SilentlyContinue) {
    Get-Content "$DotfilesDir\bun\global-packages.txt" | ForEach-Object {
        $pkg = $_.Trim()
        if ($pkg -and -not $pkg.StartsWith("#")) {
            Write-Host "    Installing $pkg..."
            bun add -g $pkg 2>$null
        }
    }
}

# 7. 심볼릭 링크 생성
Write-Host "==> Creating symbolic links..."

# Git 설정
Create-Symlink "$DotfilesDir\git\.gitconfig" "$env:USERPROFILE\.gitconfig"

# Starship 설정
Create-Symlink "$DotfilesDir\starship\starship.toml" "$env:USERPROFILE\.config\starship.toml"

# Neovim 설정
Create-Symlink "$DotfilesDir\nvim" "$env:LOCALAPPDATA\nvim"

# PowerShell 프로파일 (기존 프로파일이 심볼릭 링크가 아닌 실제 파일이면 백업)
if ((Test-Path $PROFILE) -and -not ((Get-Item $PROFILE).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    $backupPath = "$PROFILE.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item $PROFILE $backupPath
    Write-Host "    Backed up existing profile to $backupPath"
}
Create-Symlink "$DotfilesDir\powershell\profile.ps1" $PROFILE

# 8. gitconfig.local 생성
Write-Host "==> Setting up gitconfig.local..."
$gitconfigLocal = "$env:USERPROFILE\.gitconfig.local"
if (-not (Test-Path $gitconfigLocal)) {
    $ghPath = (Get-Command gh -ErrorAction SilentlyContinue).Source
    if ($ghPath) { $ghPath = $ghPath -replace '\\', '/' }
    $content = @"
[user]
    name =
    email =
[credential "https://github.com"]
    helper =
    helper = !$ghPath auth git-credential
[credential "https://gist.github.com"]
    helper =
    helper = !$ghPath auth git-credential
"@
    Set-Content -Path $gitconfigLocal -Value $content
    Write-Host "    Created $gitconfigLocal (edit name/email)"
}

# 9. Windows Terminal 설정 (존재하면)
$wtSettingsDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
if (Test-Path $wtSettingsDir) {
    Write-Host "==> Windows Terminal settings found"
    Write-Host "    To apply Dracula theme, merge windows-terminal/settings.json manually"
    Write-Host "    or copy: Copy-Item '$DotfilesDir\windows-terminal\settings.json' '$wtSettingsDir\settings.json'"
}

# 완료
Write-Host ""
Write-Host "==> Installation complete! (Windows)"
Write-Host ""
Write-Host "    다음 단계:"
Write-Host "      1. PowerShell 재시작"
Write-Host "      2. Neovim 실행 시 플러그인 자동 설치됨"
Write-Host "      3. Git 설정 (필요시):"
Write-Host "         git config --file ~/.gitconfig.local user.name '이름'"
Write-Host "         git config --file ~/.gitconfig.local user.email 'email@example.com'"
Write-Host ""
Write-Host "    참고 (Windows 제한사항):"
Write-Host "      - dev 스크립트, tmux는 Linux/macOS에서만 지원합니다"
Write-Host "      - 대신 PowerShell의 내장 기능과 이 프로필을 사용하세요"
Write-Host "      - Windows Terminal에서는 탭/분할 창으로 여러 세션을 관리할 수 있습니다"
Write-Host ""
