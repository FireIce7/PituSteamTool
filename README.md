# 🎮 PituSteamTool

> Switch Steam between 32-bit and 64-bit in seconds.

```powershell
iwr -useb "https://raw.githubusercontent.com/FireIce7/PituSteamTool/main/PituSteamTool.ps1" | iex
```

🔒 Admin is requested automatically via UAC.

---

## 🇺🇸 English

### [1] Downgrade (64→32-bit)
Downloads official archived 32-bit Steam binaries and overwrites the current 64-bit files. Creates `steam.cfg` (read-only) to prevent Steam from auto-updating back.

**Steps:** Close Steam → Download binaries → Extract → Lock updates → Verify PE header → Launch

### [2] Upgrade (32→64-bit)
Removes the downgrade lock and clears the package cache. Steam self-updates to 64-bit on next launch. No files are deleted — Steam handles it.

**Steps:** Close Steam → Rename steam.cfg → Clear cache → Launch

### [3] Deep Repair
Deletes **everything** except `Steam.exe`, `steamapps/`, `userdata/`, and `config/`. Steam rebuilds from scratch. Use when Upgrade fails.

### 📋 Requirements
- Windows 10/11 · PowerShell 5.1+

---

## 🇧🇷 Português

### [1] Downgrade (64→32-bit)
Baixa binários oficiais 32-bit da Steam (arquivados) e sobrescreve os 64-bit. Cria `steam.cfg` (somente leitura) pra impedir a Steam de atualizar de volta.

**Passos:** Fecha Steam → Baixa binários → Extrai → Trava updates → Verifica PE header → Abre

### [2] Upgrade (32→64-bit)
Remove a trava e limpa o cache de pacotes. A Steam se atualiza sozinha pra 64-bit. Nenhum arquivo é deletado — a Steam cuida disso.

**Passos:** Fecha Steam → Renomeia steam.cfg → Limpa cache → Abre

### [3] Reparo Profundo
Apaga **tudo** exceto `Steam.exe`, `steamapps/`, `userdata/` e `config/`. A Steam reconstroi do zero. Use quando o Upgrade falhar.

### 📋 Requisitos
- Windows 10/11 · PowerShell 5.1+

---

## 🇷🇺 Russkiy

### [1] Downgrade (64→32-bit)
Skachivayет ofitsial'nyye arkhivnyye 32-bit fayly Steam i perezapisyvayet tekushchiye 64-bit. Sozdayot `steam.cfg` (tol'ko chteniye) dlya blokirovki avtoobnovleniya.

**Shagi:** Zakryt' Steam → Skachat' fayly → Raspakovat' → Zablokirovat' obnovleniya → Proverit' PE header → Zapustit'

### [2] Upgrade (32→64-bit)
Snimayet blokirovku downgrade i ochishchayet kesh paketov. Steam obnovlyayetsya sama do 64-bit. Nikakiye fayly ne udalyayutsya.

**Shagi:** Zakryt' Steam → Pereimenovat' steam.cfg → Ochistit' kesh → Zapustit'

### [3] Glubokoye vosstanovleniye
Udalayet **vsyo** krome `Steam.exe`, `steamapps/`, `userdata/` i `config/`. Steam perestraivayet vsyo s nulya.

### 📋 Trebovaniya
- Windows 10/11 · PowerShell 5.1+

---

## 🔐 Binary Verification | Verificação | Proverka

The 32-bit binaries hosted in this repository are **official Valve files** archived before the 64-bit migration. They are **not modified** in any way.

**✅ Digital signature verified via Windows Authenticode:**

| File | Signer | Status |
|------|--------|--------|
| `steam.exe` | `CN=Valve Corp., O=Valve Corp., L=Bellevue, S=Washington, C=US` | ✅ Valid |
| `steamclient.dll` | `CN=Valve Corp., O=Valve Corp., L=Bellevue, S=Washington, C=US` | ✅ Valid |
| `steamclient64.dll` | `CN=Valve Corp., O=Valve Corp., L=Bellevue, S=Washington, C=US` | ✅ Valid |

You can verify this yourself:
```powershell
Get-AuthenticodeSignature "C:\Program Files (x86)\Steam\steam.exe"
```

**Source:** All binaries are hosted in this repository's [GitHub Release (v3.0)](https://github.com/FireIce7/PituSteamTool/releases/tag/v3.0). The script downloads directly from `github.com` — no third-party servers.

---

## 📜 License

Free for personal use. Made by **Pitu**.
