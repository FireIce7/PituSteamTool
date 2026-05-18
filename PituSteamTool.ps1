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
        Write-Host "  $($S.AdminFail)" -ForegroundColor Red
        Write-Host "  $($S.AdminTip1)" -ForegroundColor Yellow
        Write-Host "  $($S.AdminTip2)" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "  $($S.PressEnter)"
    }
    exit
}

# --- Configuracao ---------------------------------------------------------------
# URLs diretas dos binarios 32-bit (arquivados no GitHub)
$Steam32Url    = "https://github.com/FireIce7/PituSteamTool/releases/download/v3.0/latest32bitsteam.zip"
$MillenniumUrl = "https://github.com/FireIce7/PituSteamTool/releases/download/v3.0/luatoolsmilleniumbuild.zip"

# --- Selecao de idioma ----------------------------------------------------------
Clear-Host
Write-Host ""
Write-Host "  Select language / Selecione o idioma:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [1]  English" -ForegroundColor White
Write-Host "  [2]  Portugues (BR)" -ForegroundColor White
Write-Host "  [3]  Russkiy" -ForegroundColor White
Write-Host ""
$langChoice = Read-Host "  > "
$lang = switch ($langChoice) { "2" { "pt" } "3" { "ru" } default { "en" } }

$S = @{}
if ($lang -eq "pt") {
    $S.AdminFail        = "[!] Nao foi possivel obter privilegios de Admin."
    $S.AdminTip1        = "Clique com botao direito no PowerShell e"
    $S.AdminTip2        = "selecione 'Executar como administrador'."
    $S.PressEnter       = "Pressione ENTER para sair"
    $S.SteamInfo        = "Steam Info"
    $S.Folder           = "[Pasta]  "
    $S.FolderNotFound   = "!  Pasta nao encontrada"
    $S.Steam            = "[Steam]  "
    $S.SteamExeNF       = "!  Steam.exe nao encontrado"
    $S.CfgLabel         = "[Config] "
    $S.CfgActive        = "Downgrade ativo (steam.cfg presente)"
    $S.CfgDefault       = "Padrao (sem trava de versao)"
    $S.MainMenu         = "Menu Principal"
    $S.Opt1             = ">> Downgrade para Steam 32-bit"
    $S.Opt2             = "<< Upgrade / Forcar Steam 64-bit"
    $S.Opt3             = "** Reparo profundo (preserva jogos)"
    $S.OptExit          = "Sair"
    $S.Choose           = "Escolha"
    $S.Bye              = "Ate mais!"
    $S.InvalidOpt       = "Opcao invalida. Tente novamente."
    $S.Step             = "PASSO"
    $S.Downloading      = "Baixando"
    $S.DlFail           = "Falha no download:"
    $S.ZipEmpty         = "ZIP vazio"
    $S.ZipInvalid       = "Arquivo nao e um ZIP valido"
    $S.Extracting       = "Extraindo:"
    $S.Unknown          = "Desconhecido"
    # Fechar-Steam
    $S.ClosingSteam     = "Encerrando processos da Steam"
    $S.NoSteamProc      = "Nenhum processo da Steam em execucao"
    $S.AllClosed        = "Todos os processos encerrados"
    $S.Attempt          = "Tentativa"
    $S.Of               = "de"
    $S.Killed           = "Encerrado:"
    $S.SvcStopped       = "Servico Steam encerrado"
    $S.SvcNeedAdmin     = "SteamService requer privilegios de admin"
    $S.CantKill         = "Nao foi possivel encerrar:"
    $S.StillRunning     = "Alguns processos ainda rodando"
    $S.SteamClosed      = "Steam encerrada com sucesso"
    # Verificar-Steam
    $S.PathNotFound     = "Pasta da Steam nao encontrada:"
    $S.EditTip          = "Se sua Steam estiver em outra pasta, edite o script:"
    $S.ExeNotFound      = "Steam.exe nao encontrado"
    # Downgrade
    $S.DgTitle          = "DOWNGRADE"
    $S.DgSub            = "Steam 32-bit"
    $S.DgIntro          = "Este processo vai:"
    $S.DgS1             = "1. Fechar a Steam"
    $S.DgS2             = "2. Baixar binarios 32-bit do GitHub"
    $S.DgS3             = "3. Substituir os arquivos na pasta da Steam"
    $S.DgS4             = "4. Criar steam.cfg para travar updates"
    $S.DgS5             = "5. Abrir Steam com -clearbeta"
    $S.LocalOnly        = "100% local - sem scripts remotos."
    $S.TypeYes          = "SIM"
    $S.TypeConfirm      = "para confirmar: "
    $S.Cancelled        = "cancelado pelo usuario."
    $S.DlBinFail        = "Falha no download dos binarios."
    $S.DlSteam32        = "Baixando Steam 32-bit"
    $S.ExtractOver      = "Extraindo sobre a pasta da Steam"
    $S.BinsInstalled    = "Binarios 32-bit instalados!"
    $S.ExtractErr       = "Erro na extracao:"
    $S.UpdMill          = "Atualizando Millennium (DLLs detectadas)"
    $S.Found            = "Encontrado:"
    $S.MillUpdated      = "Millennium atualizado!"
    $S.MillExtErr       = "Erro ao extrair Millennium:"
    $S.MillDlFail       = "Millennium nao foi atualizado (download falhou)"
    $S.CreatingCfg      = "Criando steam.cfg (trava de update)"
    $S.CfgCreatedRO     = "steam.cfg criado e protegido (read-only)"
    $S.CfgCreated       = "steam.cfg criado"
    $S.VerifyOpen       = "Verificando e abrindo Steam"
    $S.Confirmed32      = "Steam.exe confirmado como 32-bit!"
    $S.Still64          = "Steam.exe ainda e 64-bit. Tente Reparo Profundo primeiro."
    $S.CantVerify       = "Nao foi possivel verificar arquitetura"
    $S.OpenedClear      = "Steam aberta com -clearbeta"
    $S.DgDone           = "DOWNGRADE CONCLUIDO"
    $S.DgMsg1           = "Seus jogos e dados estao intactos."
    $S.DgMsg2           = "A Steam vai abrir em 32-bit."
    $S.DgWarn1          = "NAO atualize a Steam ou o"
    $S.DgWarn2          = "downgrade sera revertido!"
    # Upgrade
    $S.UpTitle          = "UPGRADE"
    $S.UpSub            = "Steam 64-bit"
    $S.UpIntro1         = "Este processo remove a trava de downgrade"
    $S.UpIntro2         = "e limpa o cache para forcar a atualizacao."
    $S.UpWhatHappens    = "O que vai acontecer:"
    $S.UpS1             = "1. Fechar a Steam"
    $S.UpS2             = "2. Renomear steam.cfg (trava)"
    $S.UpS3             = "3. Limpar cache de pacotes"
    $S.UpS4             = "4. Abrir Steam (atualiza sozinha)"
    $S.UpSafe           = "Seus jogos e dados nao serao afetados."
    $S.CloseSteam       = "Encerrando Steam"
    $S.SteamDone        = "Steam encerrada"
    $S.RemoveLocks      = "Removendo travas de downgrade"
    $S.CfgRenamed       = "steam.cfg -> steam.cfg.backup"
    $S.CfgNotFound      = "steam.cfg nao encontrado (OK)"
    $S.BetaRemoved      = "package\beta removido"
    $S.BetaNotFound     = "package\beta nao encontrado (OK)"
    $S.ClearCache       = "Limpando cache de pacotes"
    $S.FilesRemoved     = "arquivo(s) removido(s) da cache"
    $S.CacheClean       = "Cache ja estava limpa"
    $S.OpenSteam        = "Abrindo Steam"
    $S.SteamStarted     = "Steam iniciada"
    $S.UpDone           = "UPGRADE INICIADO"
    $S.UpNow            = "O QUE VOCE PRECISA FAZER AGORA:"
    $S.UpTip1           = "1. A Steam vai baixar a atualizacao"
    $S.UpTip2           = "   64-bit automaticamente. Aguarde."
    $S.UpTip3           = "2. Confira: Gerenciador de Tarefas"
    $S.UpTip4           = "   (Ctrl+Shift+Esc) > Steam Client"
    $S.UpTip5           = "   Se NAO tiver '(32 bits)', OK!"
    $S.UpFallback1      = "Se nao funcionar, use opcao 3"
    $S.UpFallback2      = "(Reparo Profundo)."
    # Reparo
    $S.RpTitle          = "REPARO PROFUNDO"
    $S.RpIntro1         = "Este modo apaga TUDO da pasta da Steam,"
    $S.RpIntro2         = "exceto os itens abaixo que sao "
    $S.RpPreserved      = "preservados"
    $S.RpExe            = "Steam.exe    (o executavel)"
    $S.RpApps           = "steamapps    (seus jogos instalados)"
    $S.RpUser           = "userdata     (saves e configuracoes)"
    $S.RpCfg            = "config       (contas logadas)"
    $S.RpElse1          = "Tudo mais (DLLs, cache, skins, package)"
    $S.RpElse2          = "sera apagado. A Steam vai re-baixar o"
    $S.RpElse3          = "que precisar quando abrir."
    $S.RpWarn           = "Acao irreversivel! Faca backup se necessario."
    $S.RpCancelled      = "Reparo cancelado pelo usuario."
    $S.RpRemoving       = "Removendo arquivos antigos"
    $S.RpRemoved        = "item(ns) removido(s) de"
    $S.RpRebuilding     = "Iniciando Steam para reconstrucao"
    $S.RpSpinner        = "Abrindo Steam..."
    $S.RpDone           = "REPARO CONCLUIDO"
    $S.RpNow            = "O QUE VOCE PRECISA FAZER AGORA:"
    $S.RpTip1           = "1. A Steam vai abrir e baixar"
    $S.RpTip2           = "   todos os arquivos do zero."
    $S.RpTip3           = "   Isso pode demorar alguns min."
    $S.RpTip4           = "2. Faca login normalmente."
    $S.RpTip5           = "   Seus jogos estarao na biblioteca"
    $S.RpTip6           = "   prontos para jogar."
    $S.RpSafe           = "Seus jogos e saves estao salvos!"
    $S.PressEnterCont   = "para continuar..."
    $S.Type             = "Digite "
} elseif ($lang -eq "ru") {
    $S.AdminFail        = "[!] Ne udalos poluchit prava administratora."
    $S.AdminTip1        = "Shchelknite pravoy knopkoy myshi po PowerShell i"
    $S.AdminTip2        = "vyberite 'Zapustit ot imeni administratora'."
    $S.PressEnter       = "Nazhmite ENTER dlya vykhoda"
    $S.SteamInfo        = "Steam Info"
    $S.Folder           = "[Papka]  "
    $S.FolderNotFound   = "!  Papka ne naydena"
    $S.Steam            = "[Steam]  "
    $S.SteamExeNF       = "!  Steam.exe ne nayden"
    $S.CfgLabel         = "[Config] "
    $S.CfgActive        = "Downgrade aktiven (steam.cfg prisutstvuyet)"
    $S.CfgDefault       = "Standartno (bez blokirovki versii)"
    $S.MainMenu         = "Glavnoye menyu"
    $S.Opt1             = ">> Downgrade do Steam 32-bit"
    $S.Opt2             = "<< Upgrade / Steam 64-bit"
    $S.Opt3             = "** Glubokoye vosstanovleniye (sokhranit igry)"
    $S.OptExit          = "Vykhod"
    $S.Choose           = "Vybor"
    $S.Bye              = "Do vstrechi!"
    $S.InvalidOpt       = "Nepravilnyy variant. Poprobuy snova."
    $S.Step             = "SHAG"
    $S.Downloading      = "Zagruzka"
    $S.DlFail           = "Oshibka zagruzki:"
    $S.ZipEmpty         = "Pustoy ZIP"
    $S.ZipInvalid       = "Fayl ne yavlyayetsya ZIP"
    $S.Extracting       = "Raspakovka:"
    $S.Unknown          = "Neizvestno"
    $S.ClosingSteam     = "Zavershenie protsessov Steam"
    $S.NoSteamProc      = "Net protsessov Steam"
    $S.AllClosed        = "Vse protsessy zaversheny"
    $S.Attempt          = "Popytka"
    $S.Of               = "iz"
    $S.Killed           = "Zavershon:"
    $S.SvcStopped       = "Sluzhba Steam ostanovlena"
    $S.SvcNeedAdmin     = "SteamService trebuyet prav administratora"
    $S.CantKill         = "Ne udalos zavershit:"
    $S.StillRunning     = "Nekotoryye protsessy yeshchyo rabotayut"
    $S.SteamClosed      = "Steam uspeshno zakryta"
    $S.PathNotFound     = "Papka Steam ne naydena:"
    $S.EditTip          = "Yesli Steam v drugoy papke, izmeni skript:"
    $S.ExeNotFound      = "Steam.exe ne nayden"
    $S.DgTitle          = "DOWNGRADE"
    $S.DgSub            = "Steam 32-bit"
    $S.DgIntro          = "Etot protsess vypolnit:"
    $S.DgS1             = "1. Zakroyet Steam"
    $S.DgS2             = "2. Skachayet 32-bit fayly s GitHub"
    $S.DgS3             = "3. Zameniayet fayly v papke Steam"
    $S.DgS4             = "4. Sozdast steam.cfg dlya blokirovki obnovleniy"
    $S.DgS5             = "5. Otkroyet Steam s -clearbeta"
    $S.LocalOnly        = "100% lokal'no - bez udalonnykh skriptov."
    $S.TypeYes          = "DA"
    $S.TypeConfirm      = "dlya podtverzhdeniya: "
    $S.Cancelled        = "otmeneno pol'zovatelem."
    $S.DlBinFail        = "Ne udalos skachat fayly."
    $S.DlSteam32        = "Zagruzka Steam 32-bit"
    $S.ExtractOver      = "Raspakovka v papku Steam"
    $S.BinsInstalled    = "32-bit fayly ustanovleny!"
    $S.ExtractErr       = "Oshibka raspakovki:"
    $S.UpdMill          = "Obnovleniye Millennium (DLL obnaruzheny)"
    $S.Found            = "Naydeno:"
    $S.MillUpdated      = "Millennium obnovlon!"
    $S.MillExtErr       = "Oshibka raspakovki Millennium:"
    $S.MillDlFail       = "Millennium ne obnovlon (zagruzka ne udalas)"
    $S.CreatingCfg      = "Sozdaniye steam.cfg (blokirovka obnovleniy)"
    $S.CfgCreatedRO     = "steam.cfg sozdan i zashchishchon (tolko chtenie)"
    $S.CfgCreated       = "steam.cfg sozdan"
    $S.VerifyOpen       = "Proverka i zapusk Steam"
    $S.Confirmed32      = "Steam.exe podtverzhdon kak 32-bit!"
    $S.Still64          = "Steam.exe vsyo yeshchyo 64-bit. Poprobuy Glubokoye vosstanovleniye."
    $S.CantVerify       = "Ne udalos proverit arkhitekturu"
    $S.OpenedClear      = "Steam otkryta s -clearbeta"
    $S.DgDone           = "DOWNGRADE ZAVERSHON"
    $S.DgMsg1           = "Vashi igry i dannyye v bezopasnosti."
    $S.DgMsg2           = "Steam otkroyetsya v 32-bit."
    $S.DgWarn1          = "NE obnovlyayte Steam inache"
    $S.DgWarn2          = "downgrade budet otmenon!"
    $S.UpTitle          = "UPGRADE"
    $S.UpSub            = "Steam 64-bit"
    $S.UpIntro1         = "Etot protsess snimayet blokirovku downgrade"
    $S.UpIntro2         = "i ochishchayet kesh dlya obnovleniya."
    $S.UpWhatHappens    = "Chto proizoydet:"
    $S.UpS1             = "1. Zakroyet Steam"
    $S.UpS2             = "2. Pereimenuyet steam.cfg (blokirovku)"
    $S.UpS3             = "3. Ochistit kesh paketov"
    $S.UpS4             = "4. Otkroyet Steam (obnovitsya sama)"
    $S.UpSafe           = "Vashi igry i dannyye ne budut zatronuty."
    $S.CloseSteam       = "Zakrytiye Steam"
    $S.SteamDone        = "Steam zakryta"
    $S.RemoveLocks      = "Snyatiye blokirovki downgrade"
    $S.CfgRenamed       = "steam.cfg -> steam.cfg.backup"
    $S.CfgNotFound      = "steam.cfg ne nayden (OK)"
    $S.BetaRemoved      = "package\beta udalen"
    $S.BetaNotFound     = "package\beta ne nayden (OK)"
    $S.ClearCache       = "Ochistka kesha paketov"
    $S.FilesRemoved     = "fayl(ov) udaleno iz kesha"
    $S.CacheClean       = "Kesh uzhe byl chistym"
    $S.OpenSteam        = "Zapusk Steam"
    $S.SteamStarted     = "Steam zapushchena"
    $S.UpDone           = "UPGRADE ZAPUSHCHEN"
    $S.UpNow            = "CHTO VAM NUZHNO SDELAT SEYCHAS:"
    $S.UpTip1           = "1. Steam skachayet obnovleniye"
    $S.UpTip2           = "   64-bit avtomaticheski. Zhdite."
    $S.UpTip3           = "2. Proverte: Dispetcher Zadach"
    $S.UpTip4           = "   (Ctrl+Shift+Esc) > Steam Client"
    $S.UpTip5           = "   Yesli NET '(32-bit)' - vsyo OK!"
    $S.UpFallback1      = "Yesli ne rabotayet, ispolzuyte optsiya 3"
    $S.UpFallback2      = "(Glubokoye vosstanovleniye)."
    $S.RpTitle          = "GLUBOKOYE VOSSTANOVLENIYE"
    $S.RpIntro1         = "Etot rezhim udalayet VSYO iz papki Steam,"
    $S.RpIntro2         = "krome elementov nizhe kotoryye "
    $S.RpPreserved      = "sokhraneny"
    $S.RpExe            = "Steam.exe    (ispolnyayemyy fayl)"
    $S.RpApps           = "steamapps    (ustanovlennyye igry)"
    $S.RpUser           = "userdata     (sokhraneniya i nastroyki)"
    $S.RpCfg            = "config       (akkauntnyye dannyye)"
    $S.RpElse1          = "Vsyo ostalnoye (DLL, kesh, skiny, package)"
    $S.RpElse2          = "budet udaleno. Steam zanovo skachayet"
    $S.RpElse3          = "to chto nuzhno pri otkrytii."
    $S.RpWarn           = "Neobratimaya operatsiya! Sdelayte beykap."
    $S.RpCancelled      = "Vosstanovleniye otmeneno pol'zovatelem."
    $S.RpRemoving       = "Udaleniye starykh faylov"
    $S.RpRemoved        = "element(ov) udaleno iz"
    $S.RpRebuilding     = "Zapusk Steam dlya vosstanovleniya"
    $S.RpSpinner        = "Zapusk Steam..."
    $S.RpDone           = "VOSSTANOVLENIYE ZAVERSHENO"
    $S.RpNow            = "CHTO VAM NUZHNO SDELAT SEYCHAS:"
    $S.RpTip1           = "1. Steam otkroyetsya i skachayet"
    $S.RpTip2           = "   vse fayly s nulya."
    $S.RpTip3           = "   Eto mozhet zanyat neskolko minut."
    $S.RpTip4           = "2. Voydite v akkount."
    $S.RpTip5           = "   Vashi igry budut v biblioteke"
    $S.RpTip6           = "   gotovy k igre."
    $S.RpSafe           = "Vashi igry i sokhraneniya v bezopasnosti!"
    $S.PressEnterCont   = "dlya prodolzheniya..."
    $S.Type             = "Vvedite "
} else {
    $S.AdminFail        = "[!] Could not obtain Admin privileges."
    $S.AdminTip1        = "Right-click PowerShell and select"
    $S.AdminTip2        = "'Run as administrator'."
    $S.PressEnter       = "Press ENTER to exit"
    $S.SteamInfo        = "Steam Info"
    $S.Folder           = "[Path]   "
    $S.FolderNotFound   = "!  Folder not found"
    $S.Steam            = "[Steam]  "
    $S.SteamExeNF       = "!  Steam.exe not found"
    $S.CfgLabel         = "[Config] "
    $S.CfgActive        = "Downgrade active (steam.cfg present)"
    $S.CfgDefault       = "Default (no version lock)"
    $S.MainMenu         = "Main Menu"
    $S.Opt1             = ">> Downgrade to Steam 32-bit"
    $S.Opt2             = "<< Upgrade / Force Steam 64-bit"
    $S.Opt3             = "** Deep repair (preserves games)"
    $S.OptExit          = "Exit"
    $S.Choose           = "Choice"
    $S.Bye              = "See you!"
    $S.InvalidOpt       = "Invalid option. Try again."
    $S.Step             = "STEP"
    $S.Downloading      = "Downloading"
    $S.DlFail           = "Download failed:"
    $S.ZipEmpty         = "Empty ZIP"
    $S.ZipInvalid       = "File is not a valid ZIP"
    $S.Extracting       = "Extracting:"
    $S.Unknown          = "Unknown"
    $S.ClosingSteam     = "Closing Steam processes"
    $S.NoSteamProc      = "No Steam processes running"
    $S.AllClosed        = "All processes closed"
    $S.Attempt          = "Attempt"
    $S.Of               = "of"
    $S.Killed           = "Killed:"
    $S.SvcStopped       = "Steam service stopped"
    $S.SvcNeedAdmin     = "SteamService requires admin privileges"
    $S.CantKill         = "Could not kill:"
    $S.StillRunning     = "Some processes still running"
    $S.SteamClosed      = "Steam closed successfully"
    $S.PathNotFound     = "Steam folder not found:"
    $S.EditTip          = "If Steam is in another folder, edit the script:"
    $S.ExeNotFound      = "Steam.exe not found"
    $S.DgTitle          = "DOWNGRADE"
    $S.DgSub            = "Steam 32-bit"
    $S.DgIntro          = "This process will:"
    $S.DgS1             = "1. Close Steam"
    $S.DgS2             = "2. Download 32-bit binaries from GitHub"
    $S.DgS3             = "3. Overwrite files in the Steam folder"
    $S.DgS4             = "4. Create steam.cfg to block updates"
    $S.DgS5             = "5. Open Steam with -clearbeta"
    $S.LocalOnly        = "100% local - no remote scripts."
    $S.TypeYes          = "YES"
    $S.TypeConfirm      = "to confirm: "
    $S.Cancelled        = "cancelled by user."
    $S.DlBinFail        = "Binary download failed."
    $S.DlSteam32        = "Downloading Steam 32-bit"
    $S.ExtractOver      = "Extracting over Steam folder"
    $S.BinsInstalled    = "32-bit binaries installed!"
    $S.ExtractErr       = "Extraction error:"
    $S.UpdMill          = "Updating Millennium (DLLs detected)"
    $S.Found            = "Found:"
    $S.MillUpdated      = "Millennium updated!"
    $S.MillExtErr       = "Millennium extraction error:"
    $S.MillDlFail       = "Millennium not updated (download failed)"
    $S.CreatingCfg      = "Creating steam.cfg (update lock)"
    $S.CfgCreatedRO     = "steam.cfg created and protected (read-only)"
    $S.CfgCreated       = "steam.cfg created"
    $S.VerifyOpen       = "Verifying and opening Steam"
    $S.Confirmed32      = "Steam.exe confirmed as 32-bit!"
    $S.Still64          = "Steam.exe is still 64-bit. Try Deep Repair first."
    $S.CantVerify       = "Could not verify architecture"
    $S.OpenedClear      = "Steam opened with -clearbeta"
    $S.DgDone           = "DOWNGRADE COMPLETE"
    $S.DgMsg1           = "Your games and data are intact."
    $S.DgMsg2           = "Steam will open in 32-bit."
    $S.DgWarn1          = "DO NOT update Steam or the"
    $S.DgWarn2          = "downgrade will be reverted!"
    $S.UpTitle          = "UPGRADE"
    $S.UpSub            = "Steam 64-bit"
    $S.UpIntro1         = "This process removes the downgrade lock"
    $S.UpIntro2         = "and clears the cache to force the update."
    $S.UpWhatHappens    = "What will happen:"
    $S.UpS1             = "1. Close Steam"
    $S.UpS2             = "2. Rename steam.cfg (lock)"
    $S.UpS3             = "3. Clear package cache"
    $S.UpS4             = "4. Open Steam (it updates itself)"
    $S.UpSafe           = "Your games and data will not be affected."
    $S.CloseSteam       = "Closing Steam"
    $S.SteamDone        = "Steam closed"
    $S.RemoveLocks      = "Removing downgrade locks"
    $S.CfgRenamed       = "steam.cfg -> steam.cfg.backup"
    $S.CfgNotFound      = "steam.cfg not found (OK)"
    $S.BetaRemoved      = "package\beta removed"
    $S.BetaNotFound     = "package\beta not found (OK)"
    $S.ClearCache       = "Clearing package cache"
    $S.FilesRemoved     = "file(s) removed from cache"
    $S.CacheClean       = "Cache was already clean"
    $S.OpenSteam        = "Opening Steam"
    $S.SteamStarted     = "Steam started"
    $S.UpDone           = "UPGRADE STARTED"
    $S.UpNow            = "WHAT YOU NEED TO DO NOW:"
    $S.UpTip1           = "1. Steam will download the 64-bit"
    $S.UpTip2           = "   update automatically. Wait."
    $S.UpTip3           = "2. Check: Task Manager"
    $S.UpTip4           = "   (Ctrl+Shift+Esc) > Steam Client"
    $S.UpTip5           = "   If it does NOT say '(32-bit)', OK!"
    $S.UpFallback1      = "If it doesn't work, use option 3"
    $S.UpFallback2      = "(Deep Repair)."
    $S.RpTitle          = "DEEP REPAIR"
    $S.RpIntro1         = "This mode deletes EVERYTHING in the Steam folder,"
    $S.RpIntro2         = "except the items below which are "
    $S.RpPreserved      = "preserved"
    $S.RpExe            = "Steam.exe    (the executable)"
    $S.RpApps           = "steamapps    (your installed games)"
    $S.RpUser           = "userdata     (saves and settings)"
    $S.RpCfg            = "config       (logged accounts)"
    $S.RpElse1          = "Everything else (DLLs, cache, skins, package)"
    $S.RpElse2          = "will be deleted. Steam will re-download"
    $S.RpElse3          = "what it needs when it opens."
    $S.RpWarn           = "Irreversible action! Backup if needed."
    $S.RpCancelled      = "Repair cancelled by user."
    $S.RpRemoving       = "Removing old files"
    $S.RpRemoved        = "item(s) removed out of"
    $S.RpRebuilding     = "Starting Steam for rebuild"
    $S.RpSpinner        = "Opening Steam..."
    $S.RpDone           = "REPAIR COMPLETE"
    $S.RpNow            = "WHAT YOU NEED TO DO NOW:"
    $S.RpTip1           = "1. Steam will open and download"
    $S.RpTip2           = "   all files from scratch."
    $S.RpTip3           = "   This may take a few minutes."
    $S.RpTip4           = "2. Log in normally."
    $S.RpTip5           = "   Your games will be in the library"
    $S.RpTip6           = "   ready to play."
    $S.RpSafe           = "Your games and saves are safe!"
    $S.PressEnterCont   = "to continue..."
    $S.Type             = "Type "
}

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
    Write-Host "     $($S.Downloading) $Label..." -ForegroundColor $cMuted
    try {
        Download-WithProgress -Url $Url -OutFile $OutFile
        return $true
    } catch {
        Write-Status "$CROSS" "$($S.DlFail) $_" $cDanger
        return $false
    }
}

function Extract-ZipSafe {
    param([string]$ZipPath, [string]$Destination)
    # Validar ZIP
    $fi = Get-Item $ZipPath -ErrorAction Stop
    if ($fi.Length -eq 0) { throw $S.ZipEmpty }
    $zs = [System.IO.File]::OpenRead($ZipPath)
    $hdr = New-Object byte[] 2
    $null = $zs.Read($hdr, 0, 2); $zs.Close()
    if ($hdr[0] -ne 0x50 -or $hdr[1] -ne 0x4B) { throw $S.ZipInvalid }

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
                Write-Host "`r     $($S.Extracting) $pct% ($done/$total)  " -NoNewline -ForegroundColor $cAccent
            }
        }
        if ($total -gt 0) { Write-Host "`r     $($S.Extracting) 100% ($total/$total)       " -ForegroundColor $cSuccess }
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
        else { return $S.Unknown }
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
    Write-Host "$($S.Step) $Number" -NoNewline -ForegroundColor $cHighlight
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
    Write-Host $S.SteamInfo -ForegroundColor $cAccent
    Write-Host "  $LINE_V" -ForegroundColor $cMuted

    if ($steamFound) {
        Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
        Write-Host $S.Folder -NoNewline -ForegroundColor $cMuted
        Write-Host $SteamPath -ForegroundColor $cText
    } else {
        Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
        Write-Host $S.FolderNotFound -ForegroundColor $cWarning
    }

    if ($exeFound) {
        $arch = Get-SteamArch

        Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
        Write-Host $S.Steam -NoNewline -ForegroundColor $cMuted
        $archColor = switch ($arch) { "32-bit" { $cWarning } "64-bit" { $cSuccess } default { $cMuted } }
        Write-Host $arch -ForegroundColor $archColor
    } else {
        Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
        Write-Host $S.SteamExeNF -ForegroundColor $cDanger
    }

    # Verificar steam.cfg
    $cfgPath = Join-Path $SteamPath "steam.cfg"
    Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
    Write-Host $S.CfgLabel -NoNewline -ForegroundColor $cMuted
    if (Test-Path $cfgPath) {
        Write-Host $S.CfgActive -ForegroundColor $cWarning
    } else {
        Write-Host $S.CfgDefault -ForegroundColor $cSuccess
    }

    Write-Host "  $LINE_V" -ForegroundColor $cMuted
    Write-Host ("  $LINE_BL" + ($LINE_H * 46)) -ForegroundColor $cMuted
}

function Pausar {
    Write-Blank
    Write-Host ("  " + ($DOT * 40)) -ForegroundColor $cMuted
    Write-Host "  $($S.Type)" -NoNewline -ForegroundColor $cMuted
    Write-Host "ENTER" -NoNewline -ForegroundColor $cAccent
    Write-Host " $($S.PressEnterCont)" -ForegroundColor $cMuted
    Read-Host | Out-Null
}

# --- Funcoes de acao ------------------------------------------------------------

function Fechar-Steam {
    Write-Step "0" $S.ClosingSteam

    $steamProcs = Get-Process -Name "steam*" -ErrorAction SilentlyContinue
    if (-not $steamProcs) {
        Write-Status "i" $S.NoSteamProc $cAccent
        return
    }

    $maxAttempts = 3
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $procs = Get-Process -Name "steam*" -ErrorAction SilentlyContinue
        if (-not $procs) {
            Write-Status "$CHECK" $S.AllClosed $cSuccess
            return
        }

        if ($attempt -gt 1) {
            Write-Status "~" "$($S.Attempt) $attempt $($S.Of) $maxAttempts..." $cWarning
        }

        foreach ($proc in $procs) {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                Write-Status "$CROSS" "$($S.Killed) $($proc.Name) (PID $($proc.Id))" $cMuted
            } catch {
                if ($proc.Name -eq "SteamService") {
                    try {
                        Stop-Service -Name "Steam Client Service" -Force -ErrorAction Stop
                        Write-Status "$CROSS" $S.SvcStopped $cMuted
                    } catch {
                        Write-Status "!" $S.SvcNeedAdmin $cWarning
                    }
                } else {
                    Write-Status "!" "$($S.CantKill) $($proc.Name)" $cWarning
                }
            }
        }
        Start-Sleep -Seconds 2
    }

    $remaining = Get-Process -Name "steam*" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "SteamService" }
    if ($remaining) {
        Write-Status "!" $S.StillRunning $cWarning
    } else {
        Write-Status "$CHECK" $S.SteamClosed $cSuccess
    }
    Start-Sleep -Seconds 1
}

function Verificar-Steam {
    if (!(Test-Path $SteamPath)) {
        Write-Blank
        Write-Status "$CROSS" "$($S.PathNotFound)" $cDanger
        Write-Host "     $SteamPath" -ForegroundColor $cMuted
        Write-Blank
        Write-Host "     $($S.EditTip)" -ForegroundColor $cWarning
        return $false
    }
    if (!(Test-Path $SteamExe)) {
        Write-Status "$CROSS" $S.ExeNotFound $cDanger
        return $false
    }
    return $true
}

# === OPCAO 1: DOWNGRADE ========================================================
function Fazer-Downgrade {
    Clear-Host
    Write-Blank
    Write-BoxTop
    Write-BoxMid "$($S.DgTitle)  $DOT  $($S.DgSub)" -Color $cAccent
    Write-BoxBottom
    Write-Blank

    Write-Host "  $($S.DgIntro)" -ForegroundColor $cText
    Write-Host "  $LINE_V  $($S.DgS1)" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  $($S.DgS2)" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  $($S.DgS3)" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  $($S.DgS4)" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  $($S.DgS5)" -ForegroundColor $cMuted
    Write-Blank
    Write-Status "!" $S.LocalOnly $cAccent
    Write-Blank
    Write-Line -Char $LINE_H -Color $cMuted -Width 55
    Write-Blank

    Write-Host "  $($S.Type)" -NoNewline -ForegroundColor $cMuted
    Write-Host $S.TypeYes -NoNewline -ForegroundColor $cAccent
    Write-Host " $($S.TypeConfirm)" -NoNewline -ForegroundColor $cMuted
    $confirmar = Read-Host

    if ($confirmar -ne $S.TypeYes) {
        Write-Blank
        Write-Status "$CROSS" "$($S.DgTitle) $($S.Cancelled)" $cWarning
        Pausar
        return
    }

    if (!(Verificar-Steam)) { Pausar; return }

    # --- Passo 1: Fechar Steam ---
    Fechar-Steam

    # --- Passo 2: Baixar e extrair binarios 32-bit ---
    Write-Step "1" $S.DlSteam32

    $tempZip = Join-Path $env:TEMP "latest32bitsteam.zip"
    if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }

    $dlOk = Download-File -Url $Steam32Url -OutFile $tempZip -Label "Steam 32-bit"
    if (-not $dlOk) {
        Write-Status "$CROSS" $S.DlBinFail $cDanger
        Pausar
        return
    }

    Write-Step "2" $S.ExtractOver
    try {
        Extract-ZipSafe -ZipPath $tempZip -Destination $SteamPath
        Write-Status "$CHECK" $S.BinsInstalled $cSuccess
    } catch {
        Write-Status "$CROSS" "$($S.ExtractErr) $_" $cDanger
        Pausar
        return
    } finally {
        if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
    }

    # --- Passo 3: Millennium (se presente) ---
    $hasMillennium = Test-Path (Join-Path $SteamPath "millennium.dll")
    $hasUser32 = Test-Path (Join-Path $SteamPath "user32.dll")

    if ($hasMillennium -or $hasUser32) {
        Write-Step "3" $S.UpdMill
        $found = @()
        if ($hasMillennium) { $found += "millennium.dll" }
        if ($hasUser32) { $found += "user32.dll" }
        Write-Status "i" "$($S.Found) $($found -join ', ')" $cAccent

        $tempMill = Join-Path $env:TEMP "luatoolsmilleniumbuild.zip"
        if (Test-Path $tempMill) { Remove-Item $tempMill -Force -ErrorAction SilentlyContinue }

        $dlOk2 = Download-File -Url $MillenniumUrl -OutFile $tempMill -Label "Millennium build"
        if ($dlOk2) {
            try {
                Extract-ZipSafe -ZipPath $tempMill -Destination $SteamPath
                Write-Status "$CHECK" $S.MillUpdated $cSuccess
            } catch {
                Write-Status "!" "$($S.MillExtErr) $_" $cWarning
            } finally {
                if (Test-Path $tempMill) { Remove-Item $tempMill -Force -ErrorAction SilentlyContinue }
            }
        } else {
            Write-Status "!" $S.MillDlFail $cWarning
        }
    }

    # --- Passo 4: Criar steam.cfg ---
    $stepN = if ($hasMillennium -or $hasUser32) { "4" } else { "3" }
    Write-Step $stepN $S.CreatingCfg

    $cfgPath = Join-Path $SteamPath "steam.cfg"
    $cfgContent = "BootStrapperInhibitAll=enable`nBootStrapperForceSelfUpdate=disable"
    Set-Content -Path $cfgPath -Value $cfgContent -Force
    try {
        Set-ItemProperty -Path $cfgPath -Name IsReadOnly -Value $true -ErrorAction Stop
        Write-Status "$CHECK" $S.CfgCreatedRO $cSuccess
    } catch {
        Write-Status "$CHECK" $S.CfgCreated $cSuccess
    }

    # --- Passo 5: Verificar e abrir ---
    $stepN2 = if ($hasMillennium -or $hasUser32) { "5" } else { "4" }
    Write-Step $stepN2 $S.VerifyOpen

    $archAfter = Get-SteamArch
    if ($archAfter -eq "32-bit") {
        Write-Status "$CHECK" $S.Confirmed32 $cSuccess
    } elseif ($archAfter -eq "64-bit") {
        Write-Status "!" $S.Still64 $cDanger
    } else {
        Write-Status "!" "$($S.CantVerify) ($archAfter)" $cWarning
    }

    Start-Process $SteamExe -ArgumentList "-clearbeta"
    Write-Status "$CHECK" $S.OpenedClear $cSuccess

    Write-Blank
    Write-BoxTop -Width 55
    Write-BoxMid $S.DgDone -Width 55 -Color $cSuccess
    Write-BoxSeparator -Width 55
    Write-BoxMid $S.DgMsg1 -Width 55 -Color $cText
    Write-BoxMid $S.DgMsg2 -Width 55 -Color $cText
    Write-BoxMid "" -Width 55
    Write-BoxMid $S.DgWarn1 -Width 55 -Color $cWarning
    Write-BoxMid $S.DgWarn2 -Width 55 -Color $cWarning
    Write-BoxBottom -Width 55

    Pausar
}

# === OPCAO 2: UPGRADE 64-BIT ===================================================
function Fazer-Upgrade64 {
    Clear-Host
    Write-Blank
    Write-BoxTop
    Write-BoxMid "$($S.UpTitle)  $DOT  $($S.UpSub)" -Color $cSuccess
    Write-BoxBottom
    Write-Blank

    Write-Host "  $($S.UpIntro1)" -ForegroundColor $cText
    Write-Host "  $($S.UpIntro2)" -ForegroundColor $cText
    Write-Blank
    Write-Host "  $($S.UpWhatHappens)" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  $($S.UpS1)" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  $($S.UpS2)" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  $($S.UpS3)" -ForegroundColor $cMuted
    Write-Host "  $LINE_V  $($S.UpS4)" -ForegroundColor $cMuted
    Write-Blank
    Write-Status "i" $S.UpSafe $cSuccess
    Write-Blank

    if (!(Verificar-Steam)) { Pausar; return }

    # --- Passo 1: Fechar Steam (metodo direto) ---
    Write-Step "1" $S.CloseSteam
    Stop-Process -Name steam -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    # Tentar encerrar servico tambem
    Stop-Process -Name "steamservice" -Force -ErrorAction SilentlyContinue
    Write-Status "$CHECK" $S.SteamDone $cSuccess

    # --- Passo 2: Remover travas ---
    Write-Step "2" $S.RemoveLocks

    $SteamCfg = Join-Path $SteamPath "steam.cfg"
    if (Test-Path $SteamCfg) {
        try {
            Set-ItemProperty -Path $SteamCfg -Name IsReadOnly -Value $false -ErrorAction Stop
        } catch { }
        Rename-Item $SteamCfg "steam.cfg.backup" -Force
        Write-Status "$CHECK" $S.CfgRenamed $cSuccess
    } else {
        Write-Status "i" $S.CfgNotFound $cMuted
    }

    $BetaFile = Join-Path $SteamPath "package\beta"
    if (Test-Path $BetaFile) {
        Remove-Item $BetaFile -Force
        Write-Status "$CHECK" $S.BetaRemoved $cSuccess
    } else {
        Write-Status "i" $S.BetaNotFound $cMuted
    }

    # --- Passo 3: Limpar cache de pacotes ---
    Write-Step "3" $S.ClearCache

    $PackagePath = Join-Path $SteamPath "package"
    if (Test-Path $PackagePath) {
        $files = Get-ChildItem $PackagePath -File -ErrorAction SilentlyContinue
        $count = 0
        if ($files) {
            $count = @($files).Count
            $files | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        if ($count -gt 0) {
            Write-Status "$CHECK" "$count $($S.FilesRemoved)" $cSuccess
        } else {
            Write-Status "i" $S.CacheClean $cMuted
        }
    }

    # --- Passo 4: Abrir Steam ---
    Write-Step "4" $S.OpenSteam

    Start-Process $SteamExe
    Write-Status "$CHECK" $S.SteamStarted $cSuccess

    Write-Blank
    Write-BoxTop -Width 58
    Write-BoxMid $S.UpDone -Width 58 -Color $cSuccess
    Write-BoxSeparator -Width 58
    Write-BoxMid $S.UpNow -Width 58 -Color $cAccent
    Write-BoxMid "" -Width 58
    Write-BoxMid $S.UpTip1 -Width 58 -Color $cText
    Write-BoxMid $S.UpTip2 -Width 58 -Color $cText
    Write-BoxMid "" -Width 58
    Write-BoxMid $S.UpTip3 -Width 58 -Color $cText
    Write-BoxMid $S.UpTip4 -Width 58 -Color $cText
    Write-BoxMid $S.UpTip5 -Width 58 -Color $cText
    Write-BoxMid "" -Width 58
    Write-BoxMid $S.UpFallback1 -Width 58 -Color $cWarning
    Write-BoxMid $S.UpFallback2 -Width 58 -Color $cWarning
    Write-BoxBottom -Width 58

    Pausar
}

# === OPCAO 3: REPARO PROFUNDO ===================================================
function Reparo-Profundo {
    Clear-Host
    Write-Blank
    Write-BoxTop
    Write-BoxMid "$($S.RpTitle)  $DOT  $($S.UpSub)" -Color $cWarning
    Write-BoxBottom
    Write-Blank

    if (!(Verificar-Steam)) { Pausar; return }

    Write-Host "  $($S.RpIntro1)" -ForegroundColor $cText
    Write-Host "  $($S.RpIntro2)" -NoNewline -ForegroundColor $cText
    Write-Host $S.RpPreserved -NoNewline -ForegroundColor $cSuccess
    Write-Host ":" -ForegroundColor $cText
    Write-Blank

    Write-Host "  $LINE_V  $CHECK  $($S.RpExe)" -ForegroundColor $cSuccess
    Write-Host "  $LINE_V  $CHECK  $($S.RpApps)" -ForegroundColor $cSuccess
    Write-Host "  $LINE_V  $CHECK  $($S.RpUser)" -ForegroundColor $cSuccess
    Write-Host "  $LINE_V  $CHECK  $($S.RpCfg)" -ForegroundColor $cSuccess
    Write-Blank

    Write-Host "  $($S.RpElse1)" -ForegroundColor $cMuted
    Write-Host "  $($S.RpElse2)" -ForegroundColor $cMuted
    Write-Host "  $($S.RpElse3)" -ForegroundColor $cMuted
    Write-Blank

    Write-Line -Char $LINE_H -Color $cMuted -Width 55
    Write-Status "!" $S.RpWarn $cDanger
    Write-Blank

    Write-Host "  $($S.Type)" -NoNewline -ForegroundColor $cMuted
    Write-Host $S.TypeYes -NoNewline -ForegroundColor $cAccent
    Write-Host " $($S.TypeConfirm)" -NoNewline -ForegroundColor $cMuted
    $confirmar = Read-Host

    if ($confirmar -ne $S.TypeYes) {
        Write-Blank
        Write-Status "$CROSS" $S.RpCancelled $cWarning
        Pausar
        return
    }

    Fechar-Steam

    Write-Step "1" $S.RpRemoving

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

    Write-Status "$CHECK" "$removed $($S.RpRemoved) $total" $cSuccess

    Write-Step "2" $S.RpRebuilding
    Show-Spinner -Message $S.RpSpinner -DurationMs 1200

    Start-Process $SteamExe

    Write-Blank
    Write-BoxTop -Width 58
    Write-BoxMid $S.RpDone -Width 58 -Color $cSuccess
    Write-BoxSeparator -Width 58
    Write-BoxMid $S.RpNow -Width 58 -Color $cAccent
    Write-BoxMid "" -Width 58
    Write-BoxMid $S.RpTip1 -Width 58 -Color $cText
    Write-BoxMid $S.RpTip2 -Width 58 -Color $cText
    Write-BoxMid $S.RpTip3 -Width 58 -Color $cText
    Write-BoxMid "" -Width 58
    Write-BoxMid $S.RpTip4 -Width 58 -Color $cText
    Write-BoxMid $S.RpTip5 -Width 58 -Color $cText
    Write-BoxMid $S.RpTip6 -Width 58 -Color $cText
    Write-BoxMid "" -Width 58
    Write-BoxMid $S.RpSafe -Width 58 -Color $cSuccess
    Write-BoxBottom -Width 58

    Pausar
}

# === LOOP PRINCIPAL =============================================================

while ($true) {
    Write-Banner
    Show-SteamInfo

    Write-Blank
    Write-Host "  $LINE_TL$LINE_H " -NoNewline -ForegroundColor $cMuted
    Write-Host $S.MainMenu -ForegroundColor $cAccent
    Write-Host "  $LINE_V" -ForegroundColor $cMuted

    # Opcao 1
    Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
    Write-Host "[" -NoNewline -ForegroundColor $cMuted
    Write-Host "1" -NoNewline -ForegroundColor $cAccent
    Write-Host "]" -NoNewline -ForegroundColor $cMuted
    Write-Host "  >> $($S.Opt1)" -ForegroundColor $cText

    # Opcao 2
    Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
    Write-Host "[" -NoNewline -ForegroundColor $cMuted
    Write-Host "2" -NoNewline -ForegroundColor $cSuccess
    Write-Host "]" -NoNewline -ForegroundColor $cMuted
    Write-Host "  << $($S.Opt2)" -ForegroundColor $cText

    # Opcao 3
    Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
    Write-Host "[" -NoNewline -ForegroundColor $cMuted
    Write-Host "3" -NoNewline -ForegroundColor $cWarning
    Write-Host "]" -NoNewline -ForegroundColor $cMuted
    Write-Host "  ** $($S.Opt3)" -ForegroundColor $cText

    Write-Host "  $LINE_V" -ForegroundColor $cMuted

    # Opcao 0
    Write-Host "  $LINE_V  " -NoNewline -ForegroundColor $cMuted
    Write-Host "[" -NoNewline -ForegroundColor $cMuted
    Write-Host "0" -NoNewline -ForegroundColor $cDanger
    Write-Host "]" -NoNewline -ForegroundColor $cMuted
    Write-Host "  $CROSS  $($S.OptExit)" -ForegroundColor $cMuted

    Write-Host "  $LINE_V" -ForegroundColor $cMuted
    Write-Host ("  $LINE_BL" + ($LINE_H * 46)) -ForegroundColor $cMuted
    Write-Blank

    Write-Host "  $ARROW_R " -NoNewline -ForegroundColor $cAccent
    $opcao = Read-Host $S.Choose

    switch ($opcao) {
        "1" { Fazer-Downgrade }
        "2" { Fazer-Upgrade64 }
        "3" { Reparo-Profundo }
        "0" {
            Write-Blank
            Write-Host "  $($S.Bye)" -ForegroundColor $cAccent
            Write-Blank
            Start-Sleep -Milliseconds 500
            exit
        }
        default {
            Write-Blank
            Write-Status "!" $S.InvalidOpt $cDanger
            Start-Sleep -Seconds 1
        }
    }
}