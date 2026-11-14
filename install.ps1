# MY3E PowerShell Theme - instalador para Windows
# Uso:   powershell -ExecutionPolicy Bypass -File .\install.ps1
# Opções: -Uninstall     remove o tema (e restaura o perfil antigo, se houver backup)
#         -SkipProfile   instala o tema e a paleta, mas não mexe no seu perfil
param([switch]$Uninstall, [switch]$SkipProfile)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Raw  = 'https://raw.githubusercontent.com/VitzzALT/MY3EPowerShellTheme/main'
$Mark = '# MY3E PowerShell Theme'

$ompDir      = Join-Path $HOME '.config\omp'
$psDir       = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell'
$profilePath = Join-Path $psDir 'Microsoft.PowerShell_profile.ps1'
$fragDir     = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\MaterialYou'

function Test-MyProfile {
    (Test-Path $profilePath) -and (Select-String -Path $profilePath -Pattern $Mark -SimpleMatch -Quiet)
}

# ---------- Desinstalar ----------
if ($Uninstall) {
    foreach ($f in 'material-you.omp.json', 'MaterialYou.ps1', 'material-you.palette.json') {
        $p = Join-Path $ompDir $f
        if (Test-Path $p) { Remove-Item $p -Force }
    }
    if (Test-Path $fragDir) { Remove-Item $fragDir -Recurse -Force }
    if (Test-MyProfile) {
        $bak = Get-ChildItem "$profilePath.bak-*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        Remove-Item $profilePath -Force
        if ($bak) {
            Copy-Item $bak.FullName $profilePath
            Write-Host "Perfil anterior restaurado de: $($bak.FullName)"
        }
    }
    Write-Host 'Tema removido. Abra um terminal novo.' -ForegroundColor Green
    exit 0
}

# ---------- 1) Pré-requisitos ----------
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    Write-Host 'PowerShell 7 não encontrado. Instale com:  winget install Microsoft.PowerShell' -ForegroundColor Yellow
    exit 1
}

if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host 'Instalando o Oh-My-Posh...'
        winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements
    } else {
        Write-Host 'Oh-My-Posh não encontrado e o winget não está disponível. Instale o Oh-My-Posh manualmente.' -ForegroundColor Yellow
    }
}

# Terminal-Icons (opcional, ícones no ls) instalado para o PowerShell 7
try {
    & pwsh -NoProfile -Command "if (-not (Get-Module -ListAvailable Terminal-Icons)) { Install-Module Terminal-Icons -Scope CurrentUser -Force }"
} catch {
    Write-Host 'Não consegui instalar o Terminal-Icons (opcional). Segue sem ele.' -ForegroundColor Yellow
}

# ---------- 2) Arquivos ----------
New-Item -ItemType Directory -Force -Path $ompDir, $psDir | Out-Null

function Get-ThemeFile($Name, $Dest) {
    $local = if ($PSScriptRoot) { Join-Path $PSScriptRoot $Name } else { $null }
    if ($local -and (Test-Path $local)) { Copy-Item $local $Dest -Force }
    else { Invoke-WebRequest -Uri "$Raw/$Name" -OutFile $Dest -UseBasicParsing }
    Unblock-File $Dest
}

Get-ThemeFile 'material-you.omp.json' (Join-Path $ompDir 'material-you.omp.json')
Get-ThemeFile 'MaterialYou.ps1'       (Join-Path $ompDir 'MaterialYou.ps1')

if (-not $SkipProfile) {
    # Backup do perfil que já existir (só se não for o do próprio tema)
    if ((Test-Path $profilePath) -and -not (Test-MyProfile)) {
        $bak = "$profilePath.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
        Copy-Item $profilePath $bak
        Write-Host "Backup do perfil anterior: $bak"
    }
    Get-ThemeFile 'Microsoft.PowerShell_profile.ps1' $profilePath
}

# ---------- 3) Gera a paleta com a cor de destaque atual ----------
& pwsh -NoProfile -Command ". '$ompDir\MaterialYou.ps1'; Sync-MaterialTheme -Force | Out-Null"

Write-Host ''
Write-Host 'Pronto! Abra um terminal novo (PowerShell 7).' -ForegroundColor Green
Write-Host 'Falta só:'
Write-Host '  1) Uma Nerd Font no terminal (ex.: oh-my-posh font install) para os ícones.'
Write-Host '  2) Opcional: Windows Terminal > Configurações > Padrões > Aparência > Esquema de cores: "Material You".'
