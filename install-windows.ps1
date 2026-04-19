# install-windows.ps1
# Windows 네이티브 환경 설치 스크립트 (PowerShell + Scoop)
# 관리자 권한 없이 실행 가능. 멱등적(idempotent) 설계.
# PowerShell 7(pwsh) 전용 — profile.ps1이 PSReadLine 최신 API와 mise activate pwsh 등을 사용.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# PowerShell 7 가드: $PROFILE 경로와 프로필 API가 5.1과 달라 반드시 pwsh로 실행해야 한다.
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "[ERROR] 이 스크립트는 PowerShell 7 이상에서 실행해야 합니다." -ForegroundColor Red
    Write-Host "        현재 버전: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    Write-Host ""
    Write-Host "PowerShell 7 설치 방법 (택 1):" -ForegroundColor Yellow
    Write-Host "  winget install --id Microsoft.PowerShell --source winget" -ForegroundColor Yellow
    Write-Host "  또는 https://aka.ms/powershell-release-windows 에서 수동 설치" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "설치 후 'pwsh'로 셸을 연 뒤 이 스크립트를 다시 실행하세요." -ForegroundColor Yellow
    exit 1
}

$DotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==> Dotfiles installation starting (Windows)..."
Write-Host "    Dotfiles directory: $DotfilesDir"
Write-Host "    PowerShell: $($PSVersionTable.PSVersion)"

# --- Helper ---
function Create-Symlink {
    param([string]$Source, [string]$Target)
    $parentDir = Split-Path -Parent $Target
    if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
    if (Test-Path $Target) {
        $item = Get-Item $Target -Force
        $isSymlink = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
        # 이미 심볼릭 링크면 그대로 교체한다. 실제 파일/디렉토리면 백업을 남긴 뒤 제거한다.
        if (-not $isSymlink) {
            $backupPath = "$Target.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
            Write-Host "    Backing up: $Target -> $backupPath" -ForegroundColor Cyan
            Copy-Item $Target $backupPath -Recurse -Force
        }
        Remove-Item $Target -Force -Recurse
    }
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
    "tree",
    "gitleaks"
)

# 설치 여부는 `scoop export`의 JSON에서 판정한다.
# Get-Command 방식은 (1) Windows 기본 tree.com을 탐지해 scoop tree 설치를 건너뛰고
# (2) 실행 파일명이 패키지명과 다른 도구(ripgrep→rg, neovim→nvim)를 오탐지하므로 쓰지 않는다.
function Get-ScoopInstalledApps {
    try {
        $exportJson = scoop export | ConvertFrom-Json -ErrorAction Stop
        return @($exportJson.apps | ForEach-Object { $_.Name })
    } catch {
        Write-Host "    [WARN] scoop export 파싱 실패. 모든 도구에 대해 install 재시도합니다." -ForegroundColor Yellow
        return @()
    }
}
$installedApps = Get-ScoopInstalledApps

foreach ($tool in $tools) {
    if ($installedApps -contains $tool) {
        Write-Host "    $tool already installed"
    } else {
        Write-Host "    Installing $tool..."
        scoop install $tool
    }
}

# 3-a. PSFzf 모듈 설치 (fzf Ctrl+t / Ctrl+r 키 바인딩 활성화에 필요)
# fzf CLI가 있어도 PSFzf 모듈이 없으면 profile.ps1의 키 바인딩 블록이 스킵된다.
Write-Host "==> Installing PSFzf module..."
if (-not (Get-Module -ListAvailable -Name PSFzf)) {
    try {
        Install-Module -Name PSFzf -Scope CurrentUser -Force -AllowClobber
        Write-Host "    PSFzf installed"
    } catch {
        Write-Host "    [WARN] PSFzf 설치 실패: $_" -ForegroundColor Yellow
        Write-Host "    수동 설치: Install-Module -Name PSFzf -Scope CurrentUser" -ForegroundColor Yellow
    }
} else {
    Write-Host "    PSFzf already installed"
}

# 4. JetBrainsMono Nerd Font
# Starship, tmux, LazyVim 등이 Nerd Font 전용 글리프를 사용하므로 반드시 필요하다.
# nerd-fonts 버킷은 위 2번 단계에서 이미 추가되어 있다.
Write-Host "==> Installing JetBrainsMono Nerd Font..."
if ($installedApps -notcontains "JetBrainsMono-NF") {
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
    # 이 경로 하위의 .mise.toml은 자동으로 trust되어 `mise trust` 수동 확인이 생략된다.
    # Windows 기본 작업 경로(D:\workspace) 기준. 다른 경로를 쓰면 이 줄을 조정하거나
    # `mise settings add trusted_config_paths <path>`로 추가한다.
    mise settings set trusted_config_paths "D:/workspace"
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

# Git 글로벌 gitignore
Create-Symlink "$DotfilesDir\git\.gitignore_global" "$env:USERPROFILE\.gitignore_global"

# Git template 디렉토리 (pre-commit 훅 포함 — gitleaks 시크릿 스캔)
Create-Symlink "$DotfilesDir\git\git-templates" "$env:USERPROFILE\.git-templates"

# Starship 설정
Create-Symlink "$DotfilesDir\starship\starship.toml" "$env:USERPROFILE\.config\starship.toml"

# Neovim 설정
Create-Symlink "$DotfilesDir\nvim" "$env:LOCALAPPDATA\nvim"

# PowerShell 프로파일 (기존 파일/디렉토리는 Create-Symlink가 .bak.<timestamp>로 자동 백업)
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

# 9. Windows Terminal 설정 (Stable / Preview 경로 모두 시도)
$wtCandidates = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState"
)
$wtSettingsDir = $wtCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($wtSettingsDir) {
    Write-Host "==> Windows Terminal settings found: $wtSettingsDir"
    Write-Host "    To apply Dracula theme, merge windows-terminal/settings.json manually"
    Write-Host "    or copy: Copy-Item '$DotfilesDir\windows-terminal\settings.json' '$wtSettingsDir\settings.json'"
} else {
    Write-Host "==> Windows Terminal (Stable/Preview) not detected"
    Write-Host "    If installed later, manually copy: $DotfilesDir\windows-terminal\settings.json" -ForegroundColor Yellow
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
