# 🎮 PituSteamTool

> Switch Steam between 32-bit and 64-bit in seconds.

```powershell
iwr -useb "https://raw.githubusercontent.com/FireIce7/PituSteamTool/main/PituSteamTool.ps1" | iex
```

🔒 Admin is requested automatically via UAC.
🌐 Language selection at startup: 🇺🇸 English · 🇧🇷 Português · 🇷🇺 Русский

---

## 🇺🇸 English

### [1] Downgrade (64→32-bit)
Downloads official archived 32-bit Steam binaries and overwrites the current 64-bit files. Creates `steam.cfg` (read-only) to prevent Steam from auto-updating back.

### [2] Upgrade (32→64-bit)
Removes the downgrade lock and clears the package cache. Steam self-updates to 64-bit on next launch.

### [3] Deep Repair
Deletes **everything** except `Steam.exe`, `steamapps/`, `userdata/`, and `config/`. Steam rebuilds from scratch.

---

## 🇧🇷 Português

### [1] Downgrade (64→32-bit)
Baixa binários oficiais 32-bit da Steam (arquivados) e sobrescreve os 64-bit. Cria `steam.cfg` (somente leitura) pra impedir a Steam de atualizar de volta.

### [2] Upgrade (32→64-bit)
Remove a trava e limpa o cache de pacotes. A Steam se atualiza sozinha pra 64-bit.

### [3] Reparo Profundo
Apaga **tudo** exceto `Steam.exe`, `steamapps/`, `userdata/` e `config/`. A Steam reconstroi do zero.

---

## 🇷🇺 Русский

### [1] Downgrade (64→32-bit)
Скачивает официальные архивные 32-bit файлы Steam и перезаписывает текущие 64-bit. Создаёт `steam.cfg` (только чтение) для блокировки автообновления.

### [2] Upgrade (32→64-bit)
Снимает блокировку downgrade и очищает кеш пакетов. Steam обновляется сама до 64-bit.

### [3] Глубокое восстановление
Удаляет **всё** кроме `Steam.exe`, `steamapps/`, `userdata/` и `config/`. Steam перестраивает всё с нуля.

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
