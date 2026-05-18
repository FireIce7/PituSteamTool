# 🎮 PituSteamTool

> Switch Steam between 32-bit and 64-bit in seconds.

```powershell
iwr -useb "https://raw.githubusercontent.com/FireIce7/PituSteamTool/main/PituSteamTool.ps1" | iex
```

🔒 Admin is requested automatically via UAC.
🌐 Language selection at startup: English · Português · Русский

---

## ![US](https://flagcdn.com/24x18/us.png) English

### [1] Downgrade (64→32-bit)
In late 2024, Valve migrated Steam to 64-bit only. Some mods, plugins and legacy tools (like Millennium) still require the 32-bit client to work.

This option downloads the **last official 32-bit Steam binaries** released by Valve before the migration. These files are digitally signed by Valve Corp. and their Authenticode signatures can be verified at any time (see [Binary Verification](#-binary-verification) below).

The script closes Steam, extracts the 32-bit files over your current installation, and creates a `steam.cfg` file set to read-only to block Steam from auto-updating back to 64-bit. If Millennium DLLs are detected, they get updated too.

Your games, saves, and account data are not touched.

### [2] Upgrade (32→64-bit)
Removes the `steam.cfg` lock and clears the package cache. Steam self-updates to 64-bit on next launch. Nothing is deleted.

### [3] Deep Repair
Deletes **everything** in the Steam folder except `Steam.exe`, `steamapps/`, `userdata/`, and `config/`. Steam rebuilds itself from scratch on next launch. Use this when Upgrade alone doesn't work.

---

## ![BR](https://flagcdn.com/24x18/br.png) Português

### [1] Downgrade (64→32-bit)
No final de 2024, a Valve migrou a Steam pra 64-bit exclusivo. Alguns mods, plugins e ferramentas antigas (como o Millennium) ainda precisam do cliente 32-bit pra funcionar.

Essa opção baixa os **últimos binários oficiais 32-bit da Steam** lançados pela Valve antes da migração. Esses arquivos são assinados digitalmente pela Valve Corp. e a assinatura Authenticode pode ser verificada a qualquer momento (veja [Verificação dos Binários](#-binary-verification) abaixo).

O script fecha a Steam, extrai os arquivos 32-bit sobre a instalação atual, e cria um arquivo `steam.cfg` em modo somente-leitura pra bloquear a Steam de atualizar de volta pro 64-bit. Se DLLs do Millennium forem detectadas, elas também são atualizadas.

Seus jogos, saves e dados da conta não são alterados.

### [2] Upgrade (32→64-bit)
Remove a trava do `steam.cfg` e limpa o cache de pacotes. A Steam se atualiza sozinha pra 64-bit na próxima abertura. Nada é deletado.

### [3] Reparo Profundo
Apaga **tudo** da pasta da Steam exceto `Steam.exe`, `steamapps/`, `userdata/` e `config/`. A Steam se reconstroi do zero na próxima abertura. Use quando o Upgrade sozinho não funcionar.

---

## ![RU](https://flagcdn.com/24x18/ru.png) Русский

### [1] Downgrade (64→32-bit)
В конце 2024 года Valve перевела Steam исключительно на 64-bit. Некоторые моды, плагины и устаревшие инструменты (например Millennium) по-прежнему требуют 32-bit клиент.

Эта опция скачивает **последние официальные 32-bit файлы Steam**, выпущенные Valve до миграции. Эти файлы имеют цифровую подпись Valve Corp., и их подлинность через Authenticode можно проверить в любой момент (см. [Проверка файлов](#-binary-verification) ниже).

Скрипт закрывает Steam, извлекает 32-bit файлы поверх текущей установки и создаёт файл `steam.cfg` с атрибутом "только чтение", чтобы заблокировать автообновление до 64-bit. Если обнаружены DLL Millennium, они тоже обновляются.

Ваши игры, сохранения и данные аккаунта не затрагиваются.

### [2] Upgrade (32→64-bit)
Снимает блокировку `steam.cfg` и очищает кеш пакетов. Steam обновляется сама до 64-bit при следующем запуске. Ничего не удаляется.

### [3] Глубокое восстановление
Удаляет **всё** из папки Steam кроме `Steam.exe`, `steamapps/`, `userdata/` и `config/`. Steam перестраивает себя с нуля при следующем запуске. Используйте, когда Upgrade не помог.

---

## 🔐 Binary Verification

The 32-bit binaries in this repo are **official Valve files** archived before the 64-bit migration. Not modified in any way.

**✅ Digital signature verified via Windows Authenticode:**

| File | Signer | Status |
|------|--------|--------|
| `steam.exe` | Valve Corp. (Bellevue, WA, US) | ✅ Valid |
| `steamclient.dll` | Valve Corp. (Bellevue, WA, US) | ✅ Valid |
| `steamclient64.dll` | Valve Corp. (Bellevue, WA, US) | ✅ Valid |

Verify yourself:
```powershell
Get-AuthenticodeSignature "C:\Program Files (x86)\Steam\steam.exe"
```

All binaries are in this repo's [GitHub Release (v3.0)](https://github.com/FireIce7/PituSteamTool/releases/tag/v3.0). Downloads come directly from `github.com`, no third-party servers.

---

## 📋 Requirements

- Windows 10/11 · PowerShell 5.1+

## 📜 License

Free for personal use. Made by **Pitu**.
