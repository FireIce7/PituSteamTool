<#
.SYNOPSIS
    SteamMenu.ps1 - Menu para Downgrade e Upgrade/Reparo da Steam
.DESCRIPTION
    Execute como Administrador.
    Detecta automaticamente o caminho da Steam via registro.
    Made by Pitu
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "Steam Menu Tool  -  by Pitu"

# --- Auto-elevar para Administrador ---------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        $scriptPath = $MyInvocation.MyCommand.Path
        if (-not $scriptPath) {
            # Rodando via iwr | iex — salvar em temp para re-lancar elevado
            $scriptPath = Join-Path $env:TEMP "PituSteamTool_temp.ps1"
            $scriptContent = $MyInvocation.MyCommand.ScriptBlock.ToString()
            Set-Content -Path $scriptPath -Value $scriptContent -Force -Encoding UTF8
        }
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    } catch {
        Write-Host ""
        Write-Host "  [!] Nao foi possivel obter privilegios de Admin." -ForegroundColor Red
        Write-Host "  Clique com botao direito no PowerShell e" -ForegroundColor Yellow
        Write-Host "  selecione 'Executar como administrador'." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "  Pressione ENTER para sair"
    }
    exit
}

# --- Configuracao ---------------------------------------------------------------
# URLs diretas dos binarios 32-bit (arquivados no GitHub)
$Steam32Url    = "https://github.com/madoiscool/lt_api_links/releases/download/unsteam/latest32bitsteam.zip"
$MillenniumUrl = "https://github.com/madoiscool/lt_api_links/releases/download/unsteam/luatoolsmilleniumbuild.zip"

# --- Funcoes de download/extracao (self-contained) ------------------------------

function Download-WithProgress {
    param([string]$Url, [string]$OutFile)
    # Cache-bust
    $ts = (Get-Date -Format 'yyyyMMddHHmmss')
    $sep = if ($Url.Contains('?')) { '&' } else { '?' }
    $dlUrl = "$Url${sep}t=$ts"

    $req = [System.Net.HttpWebRequest]::Create($dlUrl)
    $req.Timeout = 30000
    $req.ReadWriteTimeout = 30000
    $req.Headers.Add("Cache-Control", "no-cache, no-store")
    $resp = $req.GetResponse()
    $totalLen = $resp.ContentLength
    $resp.Close()

    $req2 = [System.Net.HttpWebRequest]::Create($dlUrl)
    $req2.Timeout = 300000
    $req2.ReadWriteTimeout = 300000
    $resp2 = $req2.GetResponse()
    $stream = $resp2.GetResponseStream()
    $fs = [System.IO.FileStream]::new($OutFile, [System.IO.FileMode]::Create)
    try {
        $buf = New-Object byte[] (10 * 1024)
        $downloaded = 0
        $lastUpd = Get-Date
        while (($n = $stream.Read($buf, 0, $buf.Length)) -gt 0) {
            $fs.Write($buf, 0, $n)
            $downloaded += $n
            $now = Get-Date
            if (($now - $lastUpd).TotalMilliseconds -ge 150 -and $totalLen -gt 0) {
                $pct = [math]::Round(($downloaded / $totalLen) * 100, 1)
                $barLen = [math]::Floor($pct / 2.5)
                $bar = ("=" * $barLen).PadRight(40)
                $mb = [math]::Round($downloaded / 1MB, 1)
                $tmb = [math]::Round($totalLen / 1MB, 1)
                Write-Host "`r     [$bar] $pct% ($mb/$tmb MB)  " -NoNewline -ForegroundColor $cAccent
                $lastUpd = $now
            }
        }
        if ($totalLen -gt 0) {
            $bar = "=" * 40
            $mb = [math]::Round($downloaded / 1MB, 1)
            Write-Host "`r     [$bar] 100% ($mb MB)              " -ForegroundColor $cSuccess
        }
    } finally {
        $fs.Close(); $stream.Close(); $resp2.Close()
    }
}

function Download-File {
    param([string]$Url, [string]$OutFile, [string]$Label)
    Write-Host "     Baixando $Label..." -ForegroundColor $cMuted
    try {
        Download-WithProgress -Url $Url -OutFile $OutFile
        return $true
    } catch {
        Write-Status "$CROSS" "Falha no download: $_" $cDanger
        return $false
    }
}

function Extract-ZipSafe {
    param([string]$ZipPath, [string]$Destination)
    # Validar ZIP
    $fi = Get-Item $ZipPath -ErrorAction Stop
    if ($fi.Length -eq 0) { throw "ZIP vazio" }
    $zs = [System.IO.File]::OpenRead($ZipPath)
    $hdr = New-Object byte[] 2
    $null = $zs.Read($hdr, 0, 2); $zs.Close()
    if ($hdr[0] -ne 0x50 -or $hdr[1] -ne 0x4B) { throw "Arquivo nao e um ZIP valido" }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $entries = @($zip.Entries | Where-Object { -not ($_.FullName.EndsWith('/') -or $_.FullName.EndsWith('\')) })
        $total = $entries.Count; $done = 0
        foreach ($e in $zip.Entries) {
            $rel = $e.FullName.TrimStart('/','\') -replace '^[A-Z]:\\', '' -replace '/', '\'
            $dest = Join-Path $Destination $rel
            $destFull = [System.IO.Path]::GetFullPath($dest)
            if (-not $destFull.StartsWith([System.IO.Path]::GetFullPath($Destination), [System.StringComparison]::OrdinalIgnoreCase)) { continue }
            $dir = Split-Path $dest -Parent
            if ($dir -and !(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            if ($e.FullName.EndsWith('/') -or $e.FullName.EndsWith('\')) { continue }
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $dest, $true)
            $done++
            if ($done % 20 -eq 0 -and $total -gt 0) {
                $pct = [math]::Round(($done / $total) * 100)
                Write-Host "`r     Extraindo: $pct% ($done/$total)  " -NoNewline -ForegroundColor $cAccent
            }
        }
        if ($total -gt 0) { Write-Host "`r     Extraindo: 100% ($total/$total)       " -ForegroundColor $cSuccess }
    } finally { $zip.Dispose() }
}

# --- Auto-deteccao do caminho da Steam ------------------------------------------
function Get-SteamPath {
    $regPaths = @(
        @{ Key = "HKCU:\Software\Valve\Steam";                 Prop = "SteamPath"   },
        @{ Key = "HKLM:\Software\Valve\Steam";                 Prop = "InstallPath" },
        @{ Key = "HKLM:\Software\WOW6432Node\Valve\Steam";     Prop = "InstallPath" }
    )
    foreach ($r in $regPaths) {
        if (Test-Path $r.Key) {
            $val = (Get-ItemProperty -Path $r.Key -Name $r.Prop -ErrorAction SilentlyContinue).($r.Prop)
            if ($val -and (Test-Path $val)) { return $val }
        }
    }
    $default = "${env:ProgramFiles(x86)}\Steam"
    if (Test-Path $default) { return $default }
    return $null
}

$SteamPath = Get-SteamPath
if (-not $SteamPath) { $SteamPath = "${env:ProgramFiles(x86)}\Steam" }
$SteamExe  = Join-Path $SteamPath "Steam.exe"

# --- Paleta de cores ------------------------------------------------------------
$cAccent    = "Cyan"
$cAccent2   = "DarkCyan"
$cSuccess   = "Green"
$cWarning   = "Yellow"
$cDanger    = "Red"
$cMuted     = "DarkGray"
$cText      = "White"
$cHighlight = "Magenta"

# --- Caracteres Unicode (seguros) -----------------------------------------------
$BOX_H   = [char]0x2550  # horizontal duplo
$BOX_V   = [char]0x2551  # vertical duplo
$BOX_TL  = [char]0x2554  # top-left duplo
$BOX_TR  = [char]0x2557  # top-right duplo
$BOX_BL  = [char]0x255A  # bottom-left duplo
$BOX_BR  = [char]0x255D  # bottom-right duplo
$BOX_ML  = [char]0x2560  # mid-left duplo
$BOX_MR  = [char]0x2563  # mid-right duplo
$LINE_H  = [char]0x2500  # horizontal simples
$LINE_TL = [char]0x250C  # top-left simples
$LINE_BL = [char]0x2514  # bottom-left simples
$LINE_V  = [char]0x2502  # vertical simples
$LINE_T  = [char]0x251C  # T simples
$DOT     = [char]0x00B7  # middle dot
$ARROW_R = [char]0x25B8  # small right arrow
$CHECK   = [char]0x2713  # checkmark
$CROSS   = [char]0x2717  # cross

# --- Funcao de verificacao de arquitetura ----------------------------------------
function Get-SteamArch {
    if (!(Test-Path $SteamExe)) { return "N/A" }
    try {
        $bytes = [System.IO.File]::ReadAllBytes($SteamExe)
        $peOff = [BitConverter]::ToInt32($bytes, 0x3C)
        $machine = [BitConverter]::ToUInt16($bytes, $peOff + 4)
        if ($machine -eq 0x8664)     { return "64-bit" }
        elseif ($machine -eq 0x014c) { return "32-bit" }
        else { return "Desconhecido" }
    } catch { return "N/A" }
}

# --- Funcoes de UI --------------------------------------------------------------

function Write-Blank { Write-Host "" }

function Write-Line {
    param(
        [string]$Char = $LINE_H,
        [string]$Color = $cAccent2,
        [int]$Width = 60
    )
    Write-Host ("  " + ($Char * $Width)) -ForegroundColor $Color
}

function Write-BoxTop {
    param([int]$Width = 60)
    Write-Host ("  $BOX_TL" + ($BOX_H * ($Width - 2)) + "$BOX_TR") -ForegroundColor $cAccent
}

function Write-BoxMid {
    param(
        [string]$Text,
        [int]$Width = 60,
        [string]$Color = $cText,
        [string]$BorderColor = $cAccent
    )
    $innerW = $Width - 4
    $textLen = $Text.Length
    if ($textLen -gt $innerW) { $textLen = $innerW }
    $pad = $innerW - $textLen
    $left  = [math]::Floor($pad / 2)
    $right = [math]::Ceiling($pad / 2)
    $line = (" " * ($left + 1)) + $Text + (" " * ($right + 1))
    Write-Host "  $BOX_V" -NoNewline -ForegroundColor $BorderColor
    Write-Host $line -NoNewline -ForegroundColor $Color
    Write-Host "$BOX_V" -ForegroundColor $BorderColor
}

function Write-BoxBottom {
    param([int]$Width = 60)
    Write-Host ("  $BOX_BL" + ($BOX_H * ($Width - 2)) + "$BOX_BR") -ForegroundColor $cAccent
}

function Write-BoxSeparator {
    param([int]$Width = 60)
    Write-Host ("  $BOX_ML" + ($BOX_H * ($Width - 2)) + "$BOX_MR") -ForegroundColor $cAccent
}

function Write-Status {
    param(
        [string]$Icon,
        [string]$Message,
        [string]$Color = $cText
    )
    Write-Host "  $Icon " -NoNewline -ForegroundColor $Color
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    param([string]$Number, [string]$Title)
    Write-Host ""
    Write-Host "  $ARROW_R " -NoNewline -ForegroundColor $cHighlight
    Write-Host "PASSO $Number" -NoNewline -ForegroundColor $cHighlight
    Write-Host " $DOT " -NoNewline -ForegroundColor $cMuted
    Write-Host $Title -ForegroundColor $cText
    Write-Line -Char "$DOT" -Color $cMuted -Width 50
}

function Show-Spinner {
    param([string]$Message, [int]$DurationMs = 1500)
    $frames = @("/","-","\","|")
    $endTime = (Get-Date).AddMilliseconds($DurationMs)
    $i = 0
    while ((Get-Date) -lt $endTime) {
        $f = $frames[$i % $frames.Count]
        Write-Host "`r  [$f] $Message   " -NoNewline -ForegroundColor $cAccent
        Start-Sleep -Milliseconds 120
        $i++
    }
    Write-Host "`r  [$CHECK] $Message   " -ForegroundColor $cSuccess
}

function Write-Banner {
    Clear-Host
    Write-Blank
    $art = @(
        "      ____  _                        __  __                  ",
        "     / ___|| |_ ___  __ _ _ __ ___  |  \/  | ___ _ __  _   _",
        "     \___ \| __/ _ \/ _`` | '_ `` _ \ | |\/| |/ _ \ '_ \| | | |",
        "      ___) | ||  __/ (_| | | | | | || |  | |  __/ | | | |_| |",
        "     |____/ \__\___|\__,_|_| |_| |_||_|  |_|\___|_| |_|\__,_|"
    )

    $artColors = @($cAccent2, $cAccent, $cAccent, $cAccent, $cAccent2)
    for ($i = 0; $i -lt $art.Count; $i++) {
        Write-Host $art[$i] -ForegroundColor $artColors[$i]
    }

    Write-Blank
    $tagW = 42
    Write-Host ("         $BOX_TL" + ($BOX_H * $tagW) + "$BOX_TR") -ForegroundColor $cAccent2
    Write-Host "         $BOX_V   " -NoNewline -ForegroundColor $cAccent2
    Write-Host "D O W N G R A D E   T O O L" -NoNewline -ForegroundColor $cText
    Write-Host "  $DOT  v3.0" -NoNewline -ForegroundColor $cMuted
    Write-Host "   $BOX_V" -ForegroundColor $cAccent2
    Write-Host ("         $BOX_BL" + ($BOX_H * $tagW) + "$BOX_BR") -ForegroundColor $cAccent2
    Write-Host "                           made by " -NoNewline -ForegroundColor $cMuted
    Write-Host "Pitu" -ForegroundColor $cAccent
    Write-Blank
}

function Show-SteamInfo {
    $steamFound = Test-Path $SteamPath
    $exeFound   = Test-Path $SteamExe

    Write-Host "  $LINE_TL$LINE_H " -NoNewline -ForegroundColor $cMuted
    Write-Host "Steam Info" -ForegroundColor $cAccent
    Write-Host "  $LINE_V" -ForegroundColor $cMuted

    if ($steamFound) {
        Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
        Write-Host "[Pasta]  " -NoNewline -ForegroundColor $cMuted
        Write-Host $SteamPath -ForegroundColor $cText
    } else {
        Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
        Write-Host "!  Pasta nao encontrada" -ForegroundColor $cWarning
    }

    if ($exeFound) {
        $arch = Get-SteamArch

        Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
        Write-Host "[Steam]  " -NoNewline -ForegroundColor $cMuted
        $archColor = switch ($arch) { "32-bit" { $cWarning } "64-bit" { $cSuccess } default { $cMuted } }
        Write-Host $arch -ForegroundColor $archColor
    } else {
        Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
        Write-Host "!  Steam.exe nao encontrado" -ForegroundColor $cDanger
    }

    # Verificar steam.cfg
    $cfgPath = Join-Path $SteamPath "steam.cfg"
    Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
    Write-Host "[Config] " -NoNewline -ForegroundColor $cMuted
    if (Test-Path $cfgPath) {
        Write-Host "Downgrade ativo (steam.cfg presente)" -ForegroundColor $cWarning
    } else {
        Write-Host "Padrao (sem trava de versao)" -ForegroundColor $cSuccess
    }

    Write-Host "  $LINE_V" -ForegroundColor $cMuted
    Write-Host ("  $LINE_BL" + ($LINE_H * 46)) -ForegroundColor $cMuted
}

function Pausar {
    Write-Blank
    Write-Host ("  " + ($DOT * 40)) -ForegroundColor $cMuted
    Write-Host "  Pressione " -NoNewline -ForegroundColor $cMuted
    Write-Host "ENTER" -NoNewline -ForegroundColor $cAccent
    Write-Host " para continuar..." -ForegroundColor $cMuted
    Read-Host | Out-Null
}

# --- Funcoes de acao ------------------------------------------------------------

function Fechar-Steam {
    Write-Step "0" "Encerrando processos da Steam"

    $steamProcs = Get-Process -Name "steam*" -ErrorAction SilentlyContinue
    if (-not $steamProcs) {
        Write-Status "i" "Nenhum processo da Steam em execucao" $cAccent
        return
    }

    $maxAttempts = 3
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $procs = Get-Process -Name "steam*" -ErrorAction SilentlyContinue
        if (-not $procs) {
            Write-Status "$CHECK" "Todos os processos encerrados" $cSuccess
            return
        }

        if ($attempt -gt 1) {
            Write-Status "~" "Tentativa $attempt de $maxAttempts..." $cWarning
        }

        foreach ($proc in $procs) {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                Write-Status "$CROSS" "Encerrado: $($proc.Name) (PID $($proc.Id))" $cMuted
            } catch {
                if ($proc.Name -eq "SteamService") {
                    try {
                        Stop-Service -Name "Steam Client Service" -Force -ErrorAction Stop
                        Write-Status "$CROSS" "Servico Steam encerrado" $cMuted
                    } catch {
                        Write-Status "!" "SteamService requer privilegios de admin" $cWarning
                    }
                } else {
                    Write-Status "!" "Nao foi possivel encerrar: $($proc.Name)" $cWarning
                }
            }
        }
        Start-Sleep -Seconds 2
    }

    $remaining = Get-Process -Name "steam*" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "SteamService" }
    if ($remaining) {
        Write-Status "!" "Alguns processos ainda rodando" $cWarning
    } else {
        Write-Status "$CHECK" "Steam encerrada com sucesso" $cSuccess
    }
    Start-Sleep -Seconds 1
}

function Verificar-Steam {
    if (!(Test-Path $SteamPath)) {
        Write-Blank
        Write-Status "$CROSS" "Pasta da Steam nao encontrada:" $cDanger
        Write-Host "     $SteamPath" -ForegroundColor $cMuted
        Write-Blank
        Write-Host "     Se sua Steam estiver em outra pasta, edite o script:" -ForegroundColor $cWarning
        return $false
    }
    if (!(Test-Path $SteamExe)) {
        Write-Status "$CROSS" "Steam.exe nao encontrado" $cDanger
        return $false
    }
    return $true
}

# === OPCAO 1: DOWNGRADE ========================================================
function Fazer-Downgrade {
    Clear-Host
    Write-Blank
    Write-BoxTop
    Write-BoxMid "DOWNGRADE  $DOT  Steam 32-bit" -Color $cAccent
    Write-BoxBottom
    Write-Blank

    Write-Host "  Este processo vai:" -ForegroundColor $cText
    Write-Host "  $LINE_V  1. Fechar a Steam" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  2. Baixar binarios 32-bit do GitHub" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  3. Substituir os arquivos na pasta da Steam" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  4. Criar steam.cfg para travar updates" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  5. Abrir Steam com -clearbeta" -ForegroundColor $cMuted
    Write-Blank
    Write-Status "!" "100% local - sem scripts remotos." $cAccent
    Write-Blank
    Write-Line -Char $LINE_H -Color $cMuted -Width 55
    Write-Blank

    Write-Host "  Digite " -NoNewline -ForegroundColor $cMuted
    Write-Host "SIM" -NoNewline -ForegroundColor $cAccent
    Write-Host " para confirmar: " -NoNewline -ForegroundColor $cMuted
    $confirmar = Read-Host

    if ($confirmar -ne "SIM") {
        Write-Blank
        Write-Status "$CROSS" "Downgrade cancelado pelo usuario." $cWarning
        Pausar
        return
    }

    if (!(Verificar-Steam)) { Pausar; return }

    # --- Passo 1: Fechar Steam ---
    Fechar-Steam

    # --- Passo 2: Baixar e extrair binarios 32-bit ---
    Write-Step "1" "Baixando Steam 32-bit"

    $tempZip = Join-Path $env:TEMP "latest32bitsteam.zip"
    if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }

    $dlOk = Download-File -Url $Steam32Url -OutFile $tempZip -Label "Steam 32-bit"
    if (-not $dlOk) {
        Write-Status "$CROSS" "Falha no download dos binarios." $cDanger
        Pausar
        return
    }

    Write-Step "2" "Extraindo sobre a pasta da Steam"
    try {
        Extract-ZipSafe -ZipPath $tempZip -Destination $SteamPath
        Write-Status "$CHECK" "Binarios 32-bit instalados!" $cSuccess
    } catch {
        Write-Status "$CROSS" "Erro na extracao: $_" $cDanger
        Pausar
        return
    } finally {
        if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
    }

    # --- Passo 3: Millennium (se presente) ---
    $hasMillennium = Test-Path (Join-Path $SteamPath "millennium.dll")
    $hasUser32 = Test-Path (Join-Path $SteamPath "user32.dll")

    if ($hasMillennium -or $hasUser32) {
        Write-Step "3" "Atualizando Millennium (DLLs detectadas)"
        $found = @()
        if ($hasMillennium) { $found += "millennium.dll" }
        if ($hasUser32) { $found += "user32.dll" }
        Write-Status "i" "Encontrado: $($found -join ', ')" $cAccent

        $tempMill = Join-Path $env:TEMP "luatoolsmilleniumbuild.zip"
        if (Test-Path $tempMill) { Remove-Item $tempMill -Force -ErrorAction SilentlyContinue }

        $dlOk2 = Download-File -Url $MillenniumUrl -OutFile $tempMill -Label "Millennium build"
        if ($dlOk2) {
            try {
                Extract-ZipSafe -ZipPath $tempMill -Destination $SteamPath
                Write-Status "$CHECK" "Millennium atualizado!" $cSuccess
            } catch {
                Write-Status "!" "Erro ao extrair Millennium: $_" $cWarning
            } finally {
                if (Test-Path $tempMill) { Remove-Item $tempMill -Force -ErrorAction SilentlyContinue }
            }
        } else {
            Write-Status "!" "Millennium nao foi atualizado (download falhou)" $cWarning
        }
    }

    # --- Passo 4: Criar steam.cfg ---
    $stepN = if ($hasMillennium -or $hasUser32) { "4" } else { "3" }
    Write-Step $stepN "Criando steam.cfg (trava de update)"

    $cfgPath = Join-Path $SteamPath "steam.cfg"
    $cfgContent = "BootStrapperInhibitAll=enable`nBootStrapperForceSelfUpdate=disable"
    Set-Content -Path $cfgPath -Value $cfgContent -Force
    try {
        Set-ItemProperty -Path $cfgPath -Name IsReadOnly -Value $true -ErrorAction Stop
        Write-Status "$CHECK" "steam.cfg criado e protegido (read-only)" $cSuccess
    } catch {
        Write-Status "$CHECK" "steam.cfg criado" $cSuccess
    }

    # --- Passo 5: Verificar e abrir ---
    $stepN2 = if ($hasMillennium -or $hasUser32) { "5" } else { "4" }
    Write-Step $stepN2 "Verificando e abrindo Steam"

    $archAfter = Get-SteamArch
    if ($archAfter -eq "32-bit") {
        Write-Status "$CHECK" "Steam.exe confirmado como 32-bit!" $cSuccess
    } elseif ($archAfter -eq "64-bit") {
        Write-Status "!" "Steam.exe ainda e 64-bit. Tente Reparo Profundo primeiro." $cDanger
    } else {
        Write-Status "!" "Nao foi possivel verificar arquitetura ($archAfter)" $cWarning
    }

    Start-Process $SteamExe -ArgumentList "-clearbeta"
    Write-Status "$CHECK" "Steam aberta com -clearbeta" $cSuccess

    Write-Blank
    Write-BoxTop -Width 55
    Write-BoxMid "DOWNGRADE CONCLUIDO" -Width 55 -Color $cSuccess
    Write-BoxSeparator -Width 55
    Write-BoxMid "Seus jogos e dados estao intactos." -Width 55 -Color $cText
    Write-BoxMid "A Steam vai abrir em 32-bit." -Width 55 -Color $cText
    Write-BoxMid "" -Width 55
    Write-BoxMid "NAO atualize a Steam ou o" -Width 55 -Color $cWarning
    Write-BoxMid "downgrade sera revertido!" -Width 55 -Color $cWarning
    Write-BoxBottom -Width 55

    Pausar
}

# === OPCAO 2: UPGRADE 64-BIT ===================================================
function Fazer-Upgrade64 {
    Clear-Host
    Write-Blank
    Write-BoxTop
    Write-BoxMid "UPGRADE  $DOT  Steam 64-bit" -Color $cSuccess
    Write-BoxBottom
    Write-Blank

    Write-Host "  Este processo remove a trava de downgrade" -ForegroundColor $cText
    Write-Host "  e limpa o cache para forcar a atualizacao." -ForegroundColor $cText
    Write-Blank
    Write-Host "  O que vai acontecer:" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  1. Fechar a Steam" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  2. Renomear steam.cfg (trava)" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  3. Limpar cache de pacotes" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  4. Abrir Steam (atualiza sozinha)" -ForegroundColor $cMuted
    Write-Blank
    Write-Status "i" "Seus jogos e dados nao serao afetados." $cSuccess
    Write-Blank

    if (!(Verificar-Steam)) { Pausar; return }

    # --- Passo 1: Fechar Steam (metodo direto) ---
    Write-Step "1" "Encerrando Steam"
    Stop-Process -Name steam -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    # Tentar encerrar servico tambem
    Stop-Process -Name "steamservice" -Force -ErrorAction SilentlyContinue
    Write-Status "$CHECK" "Steam encerrada" $cSuccess

    # --- Passo 2: Remover travas ---
    Write-Step "2" "Removendo travas de downgrade"

    $SteamCfg = Join-Path $SteamPath "steam.cfg"
    if (Test-Path $SteamCfg) {
        try {
            Set-ItemProperty -Path $SteamCfg -Name IsReadOnly -Value $false -ErrorAction Stop
        } catch { }
        Rename-Item $SteamCfg "steam.cfg.backup" -Force
        Write-Status "$CHECK" "steam.cfg -> steam.cfg.backup" $cSuccess
    } else {
        Write-Status "i" "steam.cfg nao encontrado (OK)" $cMuted
    }

    $BetaFile = Join-Path $SteamPath "package\beta"
    if (Test-Path $BetaFile) {
        Remove-Item $BetaFile -Force
        Write-Status "$CHECK" "package\beta removido" $cSuccess
    } else {
        Write-Status "i" "package\beta nao encontrado (OK)" $cMuted
    }

    # --- Passo 3: Limpar cache de pacotes ---
    Write-Step "3" "Limpando cache de pacotes"

    $PackagePath = Join-Path $SteamPath "package"
    if (Test-Path $PackagePath) {
        $files = Get-ChildItem $PackagePath -File -ErrorAction SilentlyContinue
        $count = 0
        if ($files) {
            $count = @($files).Count
            $files | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        if ($count -gt 0) {
            Write-Status "$CHECK" "$count arquivo(s) removido(s) da cache" $cSuccess
        } else {
            Write-Status "i" "Cache ja estava limpa" $cMuted
        }
    }

    # --- Passo 4: Abrir Steam ---
    Write-Step "4" "Abrindo Steam"

    Start-Process $SteamExe
    Write-Status "$CHECK" "Steam iniciada" $cSuccess

    Write-Blank
    Write-BoxTop -Width 58
    Write-BoxMid "UPGRADE INICIADO" -Width 58 -Color $cSuccess
    Write-BoxSeparator -Width 58
    Write-BoxMid "O QUE VOCE PRECISA FAZER AGORA:" -Width 58 -Color $cAccent
    Write-BoxMid "" -Width 58
    Write-BoxMid "1. A Steam vai baixar a atualizacao" -Width 58 -Color $cText
    Write-BoxMid "   64-bit automaticamente. Aguarde." -Width 58 -Color $cText
    Write-BoxMid "" -Width 58
    Write-BoxMid "2. Confira: Gerenciador de Tarefas" -Width 58 -Color $cText
    Write-BoxMid "   (Ctrl+Shift+Esc) > Steam Client" -Width 58 -Color $cText
    Write-BoxMid "   Se NAO tiver '(32 bits)', OK!" -Width 58 -Color $cText
    Write-BoxMid "" -Width 58
    Write-BoxMid "Se nao funcionar, use opcao 3" -Width 58 -Color $cWarning
    Write-BoxMid "(Reparo Profundo)." -Width 58 -Color $cWarning
    Write-BoxBottom -Width 58

    Pausar
}

# === OPCAO 3: REPARO PROFUNDO ===================================================
function Reparo-Profundo {
    Clear-Host
    Write-Blank
    Write-BoxTop
    Write-BoxMid "REPARO PROFUNDO  $DOT  Steam 64-bit" -Color $cWarning
    Write-BoxBottom
    Write-Blank

    if (!(Verificar-Steam)) { Pausar; return }

    Write-Host "  Este modo apaga TUDO da pasta da Steam," -ForegroundColor $cText
    Write-Host "  exceto os itens abaixo que sao " -NoNewline -ForegroundColor $cText
    Write-Host "preservados" -NoNewline -ForegroundColor $cSuccess
    Write-Host ":" -ForegroundColor $cText
    Write-Blank

    Write-Host "  $LINE_V  $CHECK  Steam.exe    (o executavel)" -ForegroundColor $cSuccess
    Write-Host "  $LINE_V  $CHECK  steamapps    (seus jogos instalados)" -ForegroundColor $cSuccess
    Write-Host "  $LINE_V  $CHECK  userdata     (saves e configuracoes)" -ForegroundColor $cSuccess
    Write-Host "  $LINE_V  $CHECK  config       (contas logadas)" -ForegroundColor $cSuccess
    Write-Blank

    Write-Host "  Tudo mais (DLLs, cache, skins, package)" -ForegroundColor $cMuted
    Write-Host "  sera apagado. A Steam vai re-baixar o" -ForegroundColor $cMuted
    Write-Host "  que precisar quando abrir." -ForegroundColor $cMuted
    Write-Blank

    Write-Line -Char $LINE_H -Color $cMuted -Width 55
    Write-Status "!" "Acao irreversivel! Faca backup se necessario." $cDanger
    Write-Blank

    Write-Host "  Digite " -NoNewline -ForegroundColor $cMuted
    Write-Host "SIM" -NoNewline -ForegroundColor $cAccent
    Write-Host " para confirmar: " -NoNewline -ForegroundColor $cMuted
    $confirmar = Read-Host

    if ($confirmar -ne "SIM") {
        Write-Blank
        Write-Status "$CROSS" "Reparo cancelado pelo usuario." $cWarning
        Pausar
        return
    }

    Fechar-Steam

    Write-Step "1" "Removendo arquivos antigos"

    $Manter  = @("Steam.exe", "steamapps", "userdata", "config")
    $items   = Get-ChildItem $SteamPath -Force
    $total   = @($items).Count
    $removed = 0

    foreach ($item in $items) {
        if ($Manter -notcontains $item.Name) {
            Remove-Item $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
            $removed++
        }
    }

    Write-Status "$CHECK" "$removed item(ns) removido(s) de $total" $cSuccess

    Write-Step "2" "Iniciando Steam para reconstrucao"
    Show-Spinner -Message "Abrindo Steam..." -DurationMs 1200

    Start-Process $SteamExe

    Write-Blank
    Write-BoxTop -Width 58
    Write-BoxMid "REPARO CONCLUIDO" -Width 58 -Color $cSuccess
    Write-BoxSeparator -Width 58
    Write-BoxMid "O QUE VOCE PRECISA FAZER AGORA:" -Width 58 -Color $cAccent
    Write-BoxMid "" -Width 58
    Write-BoxMid "1. A Steam vai abrir e baixar" -Width 58 -Color $cText
    Write-BoxMid "   todos os arquivos do zero." -Width 58 -Color $cText
    Write-BoxMid "   Isso pode demorar alguns min." -Width 58 -Color $cText
    Write-BoxMid "" -Width 58
    Write-BoxMid "2. Faca login normalmente." -Width 58 -Color $cText
    Write-BoxMid "   Seus jogos estarao na biblioteca" -Width 58 -Color $cText
    Write-BoxMid "   prontos para jogar." -Width 58 -Color $cText
    Write-BoxMid "" -Width 58
    Write-BoxMid "Seus jogos e saves estao salvos!" -Width 58 -Color $cSuccess
    Write-BoxBottom -Width 58

    Pausar
}

# === LOOP PRINCIPAL =============================================================

while ($true) {
    Write-Banner
    Show-SteamInfo

    Write-Blank
    Write-Host "  $LINE_TL$LINE_H " -NoNewline -ForegroundColor $cMuted
    Write-Host "Menu Principal" -ForegroundColor $cAccent
    Write-Host "  $LINE_V" -ForegroundColor $cMuted

    # Opcao 1
    Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
    Write-Host "[" -NoNewline -ForegroundColor $cMuted
    Write-Host "1" -NoNewline -ForegroundColor $cAccent
    Write-Host "]" -NoNewline -ForegroundColor $cMuted
    Write-Host "  >> Downgrade para Steam 32-bit" -ForegroundColor $cText

    # Opcao 2
    Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
    Write-Host "[" -NoNewline -ForegroundColor $cMuted
    Write-Host "2" -NoNewline -ForegroundColor $cSuccess
    Write-Host "]" -NoNewline -ForegroundColor $cMuted
    Write-Host "  << Upgrade / Forcar Steam 64-bit" -ForegroundColor $cText

    # Opcao 3
    Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
    Write-Host "[" -NoNewline -ForegroundColor $cMuted
    Write-Host "3" -NoNewline -ForegroundColor $cWarning
    Write-Host "]" -NoNewline -ForegroundColor $cMuted
    Write-Host "  ** Reparo profundo (preserva jogos)" -ForegroundColor $cText

    Write-Host "  $LINE_V" -ForegroundColor $cMuted

    # Opcao 0
    Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
    Write-Host "[" -NoNewline -ForegroundColor $cMuted
    Write-Host "0" -NoNewline -ForegroundColor $cDanger
    Write-Host "]" -NoNewline -ForegroundColor $cMuted
    Write-Host "  $CROSS  Sair" -ForegroundColor $cMuted

    Write-Host "  $LINE_V" -ForegroundColor $cMuted
    Write-Host ("  $LINE_BL" + ($LINE_H * 46)) -ForegroundColor $cMuted
    Write-Blank

    Write-Host "  $ARROW_R " -NoNewline -ForegroundColor $cAccent
    $opcao = Read-Host "Escolha"

    switch ($opcao) {
        "1" { Fazer-Downgrade }
        "2" { Fazer-Upgrade64 }
        "3" { Reparo-Profundo }
        "0" {
            Write-Blank
            Write-Host "  Ate mais!" -ForegroundColor $cAccent
            Write-Blank
            Start-Sleep -Milliseconds 500
            exit
        }
        default {
            Write-Blank
            Write-Status "!" "Opcao invalida. Tente novamente." $cDanger
            Start-Sleep -Seconds 1
        }
    }
}