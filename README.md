# 🎮 PituSteamTool

> Switch Steam between 32-bit and 64-bit. | Alterne a Steam entre 32-bit e 64-bit.

## ⚡ Usage | Como usar

Open PowerShell and paste: | Abra o PowerShell e cole:

```powershell
iwr -useb "https://raw.githubusercontent.com/FireIce7/PituSteamTool/main/PituSteamTool.ps1" | iex
```

🔒 Admin is requested automatically via UAC. | Admin é solicitado automaticamente via UAC.

---

## 📥 [1] Downgrade (64-bit → 32-bit)

Downloads 32-bit Steam binaries and overwrites the current 64-bit files. Creates `steam.cfg` (read-only) to block Steam from auto-updating back to 64-bit. If Millennium is installed, it also downloads a compatible 32-bit build.

Baixa binários 32-bit da Steam e sobrescreve os arquivos 64-bit atuais. Cria `steam.cfg` (somente leitura) para impedir a Steam de atualizar de volta para 64-bit. Se o Millennium estiver instalado, também baixa um build compatível.

**🔧 Steps | Passos:**
1. 🔪 Kills all Steam processes | Encerra todos os processos da Steam
2. 📦 Downloads `latest32bitsteam.zip` (~30MB) | Baixa `latest32bitsteam.zip` (~30MB)
3. 📂 Extracts over the Steam folder (overwrites) | Extrai sobre a pasta da Steam (sobrescreve)
4. 🔐 Creates `steam.cfg` with update lock (read-only) | Cria `steam.cfg` com trava de update (somente leitura)
5. 🔍 Verifies architecture via PE header | Verifica arquitetura via PE header
6. 🚀 Launches Steam with `-clearbeta` | Abre a Steam com `-clearbeta`

---

## 📤 [2] Upgrade (32-bit → 64-bit)

Removes the downgrade lock and clears the package cache so Steam can self-update back to 64-bit. Does **not** delete any binaries — Steam handles the update itself.

Remove a trava de downgrade e limpa o cache de pacotes para a Steam se atualizar sozinha para 64-bit. **Não** apaga binários — a Steam cuida da atualização.

**🔧 Steps | Passos:**
1. 🔪 Kills Steam | Encerra a Steam
2. 📝 Renames `steam.cfg` → `steam.cfg.backup` | Renomeia `steam.cfg` → `steam.cfg.backup`
3. 🗑️ Removes `package/beta` file | Remove arquivo `package/beta`
4. 🧹 Clears all files in `package/` cache | Limpa todos os arquivos do cache `package/`
5. 🚀 Launches Steam (it downloads 64-bit update) | Abre a Steam (ela baixa a atualização 64-bit)

---

## 🛠️ [3] Deep Repair | Reparo Profundo

Nuclear option. Deletes **everything** in the Steam folder except the items below, then launches Steam to rebuild from scratch. Use this when Upgrade doesn't work.

Opção nuclear. Apaga **tudo** na pasta da Steam exceto os itens abaixo, depois abre a Steam para reconstruir do zero. Use quando o Upgrade não funcionar.

**✅ Preserved | Preservado:**
| Item | EN | PT-BR |
|------|-----|-------|
| `Steam.exe` | The launcher | O executável |
| `steamapps/` | Installed games | Jogos instalados |
| `userdata/` | Saves and settings | Saves e configurações |
| `config/` | Logged accounts | Contas logadas |

---

## 🌐 Download Sources | Fontes de Download

The 32-bit binaries are **not** custom or modified. They are archived versions of the official Steam client preserved before Valve's 64-bit migration.

Os binários 32-bit **não** são customizados ou modificados. São versões arquivadas do cliente oficial da Steam, preservadas antes da migração 64-bit da Valve.

| File | Primary | Fallback |
|------|---------|----------|
| `latest32bitsteam.zip` | [GitHub (madoiscool/lt_api_links)](https://github.com/madoiscool/lt_api_links/releases/download/unsteam/latest32bitsteam.zip) | [files.luatools.work](http://files.luatools.work/OneOffFiles/latest32bitsteam.zip) |
| `luatoolsmilleniumbuild.zip` | [GitHub (madoiscool/lt_api_links)](https://github.com/madoiscool/lt_api_links/releases/download/unsteam/luatoolsmilleniumbuild.zip) | [files.luatools.work](http://files.luatools.work/OneOffFiles/luatoolsmilleniumbuild.zip) |

If the primary URL fails, the script automatically tries the fallback. | Se a URL primária falhar, o script tenta o fallback automaticamente.

---

## 📋 Requirements | Requisitos

- 🖥️ Windows 10/11
- ⚙️ PowerShell 5.1+

## 📜 License | Licença

Free for personal use. Made by **Pitu**. | Livre para uso pessoal. Feito por **Pitu**.
