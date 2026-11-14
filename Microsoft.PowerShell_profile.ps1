# MY3E PowerShell Theme - https://github.com/VitzzALT/MY3EPowerShellTheme
# ================================================
# POWERSHELL 7 PROFILE - Material You (versão rápida)
# Para medir o tempo de carregamento:  $env:PROFILE_TIMING = 1  e abra um terminal novo
# ================================================
$__sw = [System.Diagnostics.Stopwatch]::StartNew()

# ---- Opções ----
$ShowFetch = $false   # $true = mostra o fastfetch ao abrir e ao dar cls (deixa a abertura mais lenta)

# ================================================
#region Básico
# ================================================
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'

$ompConfigDir = "$HOME\.config\omp"
#endregion

# ================================================
#region Material You dinâmico (segue a cor de destaque do Windows)
# ================================================
$MYPalette = $null
$myScript  = "$ompConfigDir\MaterialYou.ps1"
if (Test-Path $myScript) {
    . $myScript
    $MYPalette = Sync-MaterialTheme    # só recalcula se a cor de destaque mudou
}
#endregion

# ================================================
#region Oh-My-Posh (tema Material You)
# ================================================
$ompTheme  = "$ompConfigDir\material-you.omp.json"
$ompFailed = $true
if (Test-Path $ompTheme) {
    try {
        oh-my-posh init pwsh --config $ompTheme | Invoke-Expression
        $ompFailed = $false
    } catch { }
}
if ($ompFailed) {
    function global:prompt {
        $loc = (Get-Location).Path.Replace($HOME, '~')
        Write-Host "PS " -NoNewline -ForegroundColor Magenta
        Write-Host $loc -NoNewline -ForegroundColor Cyan
        return ' > '
    }
}
#endregion

# ================================================
#region PSReadLine (já vem no PowerShell 7: sem Install/Import)
# ================================================
try {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Windows

    # Cores da paleta Material You (dinâmica)
    if ($MYPalette) { Set-MaterialColors $MYPalette }

    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -Function ReverseSearchHistory
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
    Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function ForwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+b' -Function BackwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
    Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo
    Set-PSReadLineKeyHandler -Chord 'Tab' -Function MenuComplete
} catch { }
#endregion

# ================================================
#region Carregamento preguiçoso (era o que mais pesava)
# ================================================
# Terminal-Icons: carrega quando o terminal fica ocioso, depois do prompt aparecer
Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    Import-Module Terminal-Icons -Global -ErrorAction SilentlyContinue
} | Out-Null

# Chocolatey: só carrega o perfil dele quando você usar o refreshenv
if ($env:ChocolateyInstall) {
    function refreshenv {
        Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1" -Global -ErrorAction SilentlyContinue
        Update-SessionEnvironment
    }
}

# Instala as dependências uma vez só (antes isso rodava a cada abertura)
function Install-ProfileDeps {
    if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
        Install-Module -Name Terminal-Icons -Force -AllowClobber -Scope CurrentUser
    }
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        winget install JanDeDobbeleer.OhMyPosh
    }
}
#endregion

# ================================================
#region Update-All (Scoop, Winget, Chocolatey)
# ================================================
function Update-All {
    Write-Host "`nATUALIZANDO TUDO..." -ForegroundColor Cyan
    $results = @()

    Write-Host "`n[1/6] PowerShell Core" -ForegroundColor Yellow
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try { winget upgrade --id Microsoft.PowerShell --silent; $results += "PowerShell"; Write-Host "   OK" -ForegroundColor Green }
        catch { Write-Host "   Falhou" -ForegroundColor Red }
    }

    Write-Host "`n[2/6] Scoop" -ForegroundColor Yellow
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        try { scoop update; scoop update *; $results += "Scoop"; Write-Host "   OK" -ForegroundColor Green }
        catch { Write-Host "   Falhou" -ForegroundColor Red }
    }

    Write-Host "`n[3/6] Winget Packages" -ForegroundColor Yellow
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try { winget upgrade --all --include-unknown --silent; $results += "Winget"; Write-Host "   OK" -ForegroundColor Green }
        catch { Write-Host "   Falhou" -ForegroundColor Red }
    }

    Write-Host "`n[4/6] Chocolatey" -ForegroundColor Yellow
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        try { choco upgrade all -y; $results += "Chocolatey"; Write-Host "   OK" -ForegroundColor Green }
        catch { Write-Host "   Falhou" -ForegroundColor Red }
    }

    Write-Host "`n[5/6] Módulos PowerShell" -ForegroundColor Yellow
    try { Get-InstalledModule | Update-Module -Force; $results += "Módulos PS"; Write-Host "   OK" -ForegroundColor Green }
    catch { Write-Host "   Falhou" -ForegroundColor Red }

    Write-Host "`n[6/6] Oh-My-Posh" -ForegroundColor Yellow
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        try { winget upgrade --id JanDeDobbeleer.OhMyPosh --silent; $results += "Oh-My-Posh"; Write-Host "   OK" -ForegroundColor Green }
        catch { Write-Host "   Falhou" -ForegroundColor Red }
    }

    Write-Host "`nRESUMO:" -ForegroundColor Cyan
    if ($results.Count -gt 0) { Write-Host "   Atualizado: $($results -join ', ')" -ForegroundColor Green }
    else { Write-Host "   Nada para atualizar" -ForegroundColor Yellow }
}
Set-Alias -Name uall -Value Update-All

function Update-Scoop  { if (Get-Command scoop  -ErrorAction SilentlyContinue) { scoop update; scoop update * } }
function Update-Winget { if (Get-Command winget -ErrorAction SilentlyContinue) { winget upgrade --all --include-unknown --silent } }
function Update-Choco  { if (Get-Command choco  -ErrorAction SilentlyContinue) { choco upgrade all -y } }
Set-Alias -Name uscoop  -Value Update-Scoop
Set-Alias -Name uwinget -Value Update-Winget
Set-Alias -Name uchoco  -Value Update-Choco
#endregion

# ================================================
#region Navegação
# ================================================
function Set-Desktop   { Set-Location "$HOME\Desktop" }
function Set-Documents { Set-Location "$HOME\Documents" }
function Set-Downloads { Set-Location "$HOME\Downloads" }
function Set-UpOne     { Set-Location .. }
function Set-UpTwo     { Set-Location ..\.. }
function Set-UpThree   { Set-Location ..\..\.. }
function Set-Home      { Set-Location $HOME }

Set-Alias -Name desk -Value Set-Desktop
Set-Alias -Name docs -Value Set-Documents
Set-Alias -Name down -Value Set-Downloads
Set-Alias -Name ..   -Value Set-UpOne
Set-Alias -Name ...  -Value Set-UpTwo
Set-Alias -Name .... -Value Set-UpThree
Set-Alias -Name ~    -Value Set-Home

function Set-QuickLocation {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Desktop', 'Documents', 'Downloads', 'Pictures', 'Music', 'Videos')]
        [string]$Location
    )
    Set-Location "$HOME\$Location"
}
Set-Alias -Name go -Value Set-QuickLocation
#endregion

# ================================================
#region Scoop
# ================================================
function Get-ScoopApps {
    if (Get-Command scoop -ErrorAction SilentlyContinue) { scoop list }
    else { Write-Host "Scoop não está instalado!" -ForegroundColor Red }
}
function Find-ScoopApp {
    param([string]$Name)
    if (Get-Command scoop -ErrorAction SilentlyContinue) { scoop search $Name }
    else { Write-Host "Scoop não está instalado!" -ForegroundColor Red }
}
Set-Alias -Name slist -Value Get-ScoopApps
Set-Alias -Name sfind -Value Find-ScoopApp
#endregion

# ================================================
#region Utilidades
# ================================================
# fastfetch (o caminho antigo era relativo e só funcionava dentro da pasta do usuário)
$ffPreset = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\Fastfetch-cli.Fastfetch_Microsoft.Winget.Source_8wekyb3d8bbwe\presets\examples\24.jsonc'
function Show-Fetch {
    if (-not (Get-Command fastfetch -ErrorAction SilentlyContinue)) { return }
    if (Test-Path $ffPreset) { fastfetch -c $ffPreset } else { fastfetch }
}
Set-Alias -Name ff -Value Show-Fetch

function Clear-Terminal {
    Clear-Host
    if ($ShowFetch) { Show-Fetch }
}
Set-Alias -Name cls -Value Clear-Terminal

function Get-SysInfo {
    Write-Host "`nSYSTEM INFORMATION" -ForegroundColor Cyan
    Write-Host "`nPowerShell:" -ForegroundColor Yellow
    Write-Host "  Version:  $($PSVersionTable.PSVersion)"
    Write-Host "  Edition:  $($PSVersionTable.PSEdition)"

    Write-Host "`nPackage Managers:" -ForegroundColor Yellow
    $mgrs = @()
    if (Get-Command scoop -ErrorAction SilentlyContinue) { $mgrs += "Scoop" }
    if (Get-Command winget -ErrorAction SilentlyContinue) { $mgrs += "Winget" }
    if (Get-Command choco -ErrorAction SilentlyContinue) { $mgrs += "Chocolatey" }
    if ($mgrs) { Write-Host "  Installed: $($mgrs -join ', ')" -ForegroundColor Green }
    else { Write-Host "  None" -ForegroundColor Gray }

    Write-Host "`nSystem:" -ForegroundColor Yellow
    Write-Host "  User:     $env:USERNAME"
    Write-Host "  Host:     $env:COMPUTERNAME"
    Write-Host "  OS:       $([System.Environment]::OSVersion.VersionString)"
}
Set-Alias -Name sysinfo -Value Get-SysInfo

function Reload-Profile {
    Write-Host "Reloading profile..." -ForegroundColor Yellow
    . $PROFILE
    Write-Host "Profile reloaded!" -ForegroundColor Green
}
Set-Alias -Name reload -Value Reload-Profile

function Get-MyHelp {
    Write-Host "`nPOWERSHELL HELP - MATERIAL YOU EDITION" -ForegroundColor Magenta
    $commands = @(
        @{Name='uall, Update-All';            Description='Atualiza TUDO'},
        @{Name='uscoop, uwinget, uchoco';     Description='Atualiza específico'},
        @{Name='slist, sfind [app]';          Description='Gerenciar Scoop'},
        @{Name='sysinfo';                     Description='Informações do sistema'},
        @{Name='ff';                          Description='Mostra o fastfetch'},
        @{Name='mytheme';                     Description='Recalcula o tema Material You pela cor do Windows'},
        @{Name='reload';                      Description='Recarrega perfil'},
        @{Name='cls';                         Description='Limpa terminal'},
        @{Name='.., ..., ....';               Description='Navegação rápida'},
        @{Name='desk, docs, down';            Description='Diretórios especiais'},
        @{Name='go [local]';                  Description='Navegação com autocomplete'},
        @{Name='Install-ProfileDeps';         Description='Instala Terminal-Icons e Oh-My-Posh'},
        @{Name='Get-OMPThemes, Set-OMPTheme'; Description='Gerenciar temas do Oh-My-Posh'}
    )
    foreach ($cmd in $commands) {
        Write-Host "  $($cmd.Name)" -ForegroundColor Yellow -NoNewline
        Write-Host " - $($cmd.Description)"
    }
}
Set-Alias -Name helpme -Value Get-MyHelp

function Get-OMPThemes {
    Write-Host "Temas em $ompConfigDir" -ForegroundColor Cyan
    Get-ChildItem $ompConfigDir -Filter *.omp.json -ErrorAction SilentlyContinue | ForEach-Object { "  " + ($_.Name -replace '\.omp\.json$', '') }
    if ($env:POSH_THEMES_PATH) {
        Write-Host "Temas oficiais em $env:POSH_THEMES_PATH" -ForegroundColor Cyan
        Get-ChildItem $env:POSH_THEMES_PATH -Filter *.omp.json -ErrorAction SilentlyContinue | ForEach-Object { "  " + ($_.Name -replace '\.omp\.json$', '') }
    }
}

function Set-OMPTheme {
    param([Parameter(Mandatory = $true)][string]$ThemeName)
    $candidates = @("$ompConfigDir\$ThemeName.omp.json")
    if ($env:POSH_THEMES_PATH) { $candidates += "$env:POSH_THEMES_PATH\$ThemeName.omp.json" }
    $themePath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($themePath) {
        oh-my-posh init pwsh --config $themePath | Invoke-Expression
        Write-Host "Tema alterado para: $ThemeName" -ForegroundColor Green
    } else {
        Write-Host "Tema não encontrado: $ThemeName (use Get-OMPThemes)" -ForegroundColor Red
    }
}

function Debug-Profile {
    Write-Host "`nPROFILE DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host "  Version: $($PSVersionTable.PSVersion)"
    Write-Host "  Profile: $PROFILE"
    foreach ($tool in 'oh-my-posh', 'scoop', 'winget', 'choco', 'fastfetch') {
        $ok = [bool](Get-Command $tool -ErrorAction SilentlyContinue)
        Write-Host "  $tool : $(if ($ok) { 'OK' } else { 'não encontrado' })" -ForegroundColor $(if ($ok) { 'Green' } else { 'Red' })
    }
    foreach ($m in 'PSReadLine', 'Terminal-Icons') {
        $ok = [bool](Get-Module $m)
        Write-Host "  $m : $(if ($ok) { 'carregado' } else { 'não carregado' })" -ForegroundColor $(if ($ok) { 'Green' } else { 'Yellow' })
    }
}
#endregion

# ================================================
#region Final
# ================================================
$host.UI.RawUI.WindowTitle = "PowerShell $($PSVersionTable.PSVersion) | $env:USERNAME"

if ($ShowFetch) { Show-Fetch }

if ($env:PROFILE_TIMING) { Write-Host "perfil carregado em $($__sw.ElapsedMilliseconds) ms" -ForegroundColor DarkGray }
#endregion
