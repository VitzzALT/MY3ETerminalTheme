# ================================================
# Material You dinâmico - PowerShell 7 + Oh-My-Posh + Windows Terminal
# Lê a cor de destaque do Windows (no modo "Automático" ela acompanha o papel de parede)
# e gera a mesma paleta tonal do userChrome.css do Firefox (OKLCH, tema escuro).
# Só recalcula quando a cor muda; no resto do tempo usa um cache.
# Salve em: $HOME\.config\omp\MaterialYou.ps1
# ================================================

function Get-WindowsAccent {
    # Retorna @(R,G,B). Tenta 3 lugares do registro; se nenhum der certo, usa o roxo padrão do Material.
    $fontes = @(
        @{ Caminho = 'HKCU:\Software\Microsoft\Windows\DWM';                              Nome = 'AccentColor';       Ordem = 'ABGR' },
        @{ Caminho = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent'; Nome = 'AccentColorMenu';   Ordem = 'ABGR' },
        @{ Caminho = 'HKCU:\Software\Microsoft\Windows\DWM';                              Nome = 'ColorizationColor'; Ordem = 'ARGB' }
    )
    foreach ($fonte in $fontes) {
        try {
            $v = Get-ItemPropertyValue -Path $fonte.Caminho -Name $fonte.Nome -ErrorAction Stop
            # O registro devolve o DWORD como número sem sinal (ex.: 4287198813), que não cabe em [int]
            $bytes = [BitConverter]::GetBytes([uint32]([int64]$v -band 0xFFFFFFFFL))    # little-endian: ABGR -> R,G,B,A | ARGB -> B,G,R,A
            if ($fonte.Ordem -eq 'ABGR') { return @([int]$bytes[0], [int]$bytes[1], [int]$bytes[2]) }
            else                         { return @([int]$bytes[2], [int]$bytes[1], [int]$bytes[0]) }
        } catch { }
    }
    return @(0x67, 0x50, 0xA4)
}

function ConvertTo-OkLCH {
    # (PowerShell não diferencia maiúsculas de minúsculas nas variáveis: por isso os nomes todos distintos)
    param([int]$Red, [int]$Green, [int]$Blue)
    $lin = { param($x) $x = $x / 255.0; if ($x -le 0.04045) { $x / 12.92 } else { [math]::Pow(($x + 0.055) / 1.055, 2.4) } }
    $lr = & $lin $Red; $lg = & $lin $Green; $lb = & $lin $Blue
    $cl = [math]::Cbrt(0.4122214708 * $lr + 0.5363325363 * $lg + 0.0514459929 * $lb)
    $cm = [math]::Cbrt(0.2119034982 * $lr + 0.6806995451 * $lg + 0.1073969566 * $lb)
    $cs = [math]::Cbrt(0.0883024619 * $lr + 0.2817188376 * $lg + 0.6299787005 * $lb)
    $labL = 0.2104542553 * $cl + 0.7936177850 * $cm - 0.0040720468 * $cs
    $labA = 1.9779984951 * $cl - 2.4285922050 * $cm + 0.4505937099 * $cs
    $labB = 0.0259040371 * $cl + 0.7827717662 * $cm - 0.8086757660 * $cs
    $hue = [math]::Atan2($labB, $labA) * 180 / [math]::PI
    if ($hue -lt 0) { $hue += 360 }
    [pscustomobject]@{ L = $labL; C = [math]::Sqrt($labA * $labA + $labB * $labB); H = $hue }
}

function ConvertFrom-OkLCH {
    # Converte OKLCH em #RRGGBB, reduzindo o croma até caber no sRGB
    param([double]$Lum, [double]$Chroma, [double]$Hue)
    $rad = $Hue * [math]::PI / 180
    $enc = { param($x) $x = [math]::Min(1.0, [math]::Max(0.0, $x)); if ($x -le 0.0031308) { 12.92 * $x } else { 1.055 * [math]::Pow($x, 1 / 2.4) - 0.055 } }
    for ($i = 0; $i -lt 24; $i++) {
        $la = $Chroma * [math]::Cos($rad)
        $lb = $Chroma * [math]::Sin($rad)
        $q1 = $Lum + 0.3963377774 * $la + 0.2158037573 * $lb
        $q2 = $Lum - 0.1055613458 * $la - 0.0638541728 * $lb
        $q3 = $Lum - 0.0894841775 * $la - 1.2914855480 * $lb
        $c1 = $q1 * $q1 * $q1; $c2 = $q2 * $q2 * $q2; $c3 = $q3 * $q3 * $q3
        $outR =  4.0767416621 * $c1 - 3.3077115913 * $c2 + 0.2309699292 * $c3
        $outG = -1.2684380046 * $c1 + 2.6097574011 * $c2 - 0.3413193965 * $c3
        $outB = -0.0041960863 * $c1 - 0.7034186147 * $c2 + 1.7076147010 * $c3
        if ($outR -ge -0.001 -and $outR -le 1.001 -and $outG -ge -0.001 -and $outG -le 1.001 -and $outB -ge -0.001 -and $outB -le 1.001) { break }
        $Chroma = $Chroma * 0.92
    }
    '#{0:X2}{1:X2}{2:X2}' -f [int][math]::Round((& $enc $outR) * 255), [int][math]::Round((& $enc $outG) * 255), [int][math]::Round((& $enc $outB) * 255)
}

function Get-MaterialPalette {
    param([int[]]$Rgb)
    $ok = ConvertTo-OkLCH $Rgb[0] $Rgb[1] $Rgb[2]
    $h  = $ok.H
    $t  = ($h + 60) % 360
    # Acento quase cinza => paleta quase neutra (em vez de colorir à força)
    $k  = if ($ok.C -lt 0.025) { 0.25 } else { 1.0 }
    $c  = { param($l, $ch, $hh) ConvertFrom-OkLCH $l ($ch * $k) $hh }

    # Mesmos valores (L, C) do tema escuro do userChrome.css
    $p = [ordered]@{
        surface        = & $c 0.17 0.012 $h
        surfaceHigh    = & $c 0.24 0.018 $h
        surfaceHighest = & $c 0.29 0.020 $h
        onSurface      = & $c 0.92 0.010 $h
        onVariant      = & $c 0.80 0.020 $h
        outline        = & $c 0.62 0.020 $h
        primary        = & $c 0.80 0.120 $h
        onPrimary      = & $c 0.25 0.090 $h
        primaryC       = & $c 0.36 0.100 $h
        onPrimaryC     = & $c 0.91 0.050 $h
        secondary      = & $c 0.80 0.040 $h
        secondaryC     = & $c 0.38 0.040 $h
        onSecondaryC   = & $c 0.91 0.030 $h
        tertiary       = & $c 0.80 0.080 $t
        tertiaryC      = & $c 0.38 0.080 $t
        onTertiaryC    = & $c 0.91 0.050 $t
    }

    # Esquema de cores do Windows Terminal (cores ANSI com matizes fixos para continuarem reconhecíveis)
    $s = [ordered]@{
        name                = 'Material You'
        foreground          = $p.onSurface
        background          = $p.surface
        cursorColor         = $p.primary
        selectionBackground = $p.primaryC
        black               = & $c 0.30 0.020 $h
        red                 = ConvertFrom-OkLCH 0.75 0.13 25
        green               = ConvertFrom-OkLCH 0.78 0.14 145
        yellow              = ConvertFrom-OkLCH 0.85 0.13 95
        blue                = ConvertFrom-OkLCH 0.74 0.12 255
        purple              = & $c 0.78 0.13 $h
        cyan                = ConvertFrom-OkLCH 0.82 0.10 200
        white               = $p.onVariant
        brightBlack         = & $c 0.52 0.020 $h
        brightRed           = ConvertFrom-OkLCH 0.83 0.10 25
        brightGreen         = ConvertFrom-OkLCH 0.86 0.13 145
        brightYellow        = ConvertFrom-OkLCH 0.91 0.12 95
        brightBlue          = ConvertFrom-OkLCH 0.83 0.10 255
        brightPurple        = & $c 0.86 0.10 $h
        brightCyan          = ConvertFrom-OkLCH 0.89 0.09 200
        brightWhite         = $p.onSurface
    }
    [pscustomobject]@{ Palette = $p; Scheme = $s }
}

function Set-MaterialColors {
    # Aplica a paleta nas cores do PSReadLine (comandos, parâmetros, strings, previsão...)
    param($P)
    $hex = $P.primaryC.TrimStart('#')
    $r = [Convert]::ToInt32($hex.Substring(0, 2), 16)
    $g = [Convert]::ToInt32($hex.Substring(2, 2), 16)
    $b = [Convert]::ToInt32($hex.Substring(4, 2), 16)
    Set-PSReadLineOption -Colors @{
        Command                = $P.primary
        Parameter              = $P.secondary
        Operator               = $P.onVariant
        Variable               = $P.onSecondaryC
        String                 = $P.tertiary
        Number                 = $P.onTertiaryC
        Type                   = $P.onPrimaryC
        Member                 = $P.onVariant
        Keyword                = $P.primary
        Comment                = $P.outline
        Error                  = '#F2B8B5'
        InlinePrediction       = $P.outline
        ListPrediction         = $P.onVariant
        ListPredictionSelected = "`e[48;2;$r;$g;${b}m"
    }
}

function Sync-MaterialTheme {
    # Recalcula só se a cor de destaque mudou (ou com -Force). Devolve a paleta.
    param([switch]$Force)
    $dir    = "$HOME\.config\omp"
    $theme  = "$dir\material-you.omp.json"
    $cache  = "$dir\material-you.palette.json"
    $rgb    = Get-WindowsAccent
    $accent = '#{0:X2}{1:X2}{2:X2}' -f $rgb[0], $rgb[1], $rgb[2]

    if (-not $Force -and (Test-Path $cache)) {
        try {
            $c = Get-Content $cache -Raw | ConvertFrom-Json -AsHashtable
            if ($c.accent -eq $accent -and $c.colors) { return $c.colors }
        } catch { }
    }

    $m = Get-MaterialPalette $rgb

    # 1) Tema do Oh-My-Posh: troca só o bloco "palette"
    try {
        if (Test-Path $theme) {
            $obj = Get-Content $theme -Raw | ConvertFrom-Json
            $obj | Add-Member -NotePropertyName palette -NotePropertyValue ([pscustomobject]$m.Palette) -Force
            $obj | ConvertTo-Json -Depth 20 | Set-Content $theme -Encoding utf8NoBOM
        }
    } catch { }

    # 2) Windows Terminal: esquema "Material You" via fragmento (não mexe no seu settings.json)
    try {
        $frag = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\MaterialYou'
        New-Item -ItemType Directory -Force -Path $frag | Out-Null
        @{ schemes = @($m.Scheme) } | ConvertTo-Json -Depth 5 | Set-Content "$frag\material-you.json" -Encoding utf8NoBOM
    } catch { }

    # 3) Cache
    try {
        [ordered]@{ accent = $accent; colors = $m.Palette } | ConvertTo-Json -Depth 5 | Set-Content $cache -Encoding utf8NoBOM
    } catch { }

    return $m.Palette
}

function Update-MaterialTheme {
    # Força o recálculo e reaplica as cores nesta sessão
    $p = Sync-MaterialTheme -Force
    Set-MaterialColors $p
    Write-Host "Tema atualizado. Abra uma aba nova para ver tudo (inclusive o Windows Terminal)." -ForegroundColor Green
}
Set-Alias -Name mytheme -Value Update-MaterialTheme
