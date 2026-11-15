# Metasploit Framework 6 in Termux
[![GitHub Actions CI](https://github.com/gushmazuko/metasploit_in_termux/actions/workflows/termux-metasploit-arm64.yml/badge.svg)](https://github.com/gushmazuko/metasploit_in_termux/actions/workflows/termux-metasploit-arm64.yml) ![GitHub Repo stars](https://img.shields.io/github/stars/gushmazuko/metasploit_in_termux?style=social)

![Metasploit 6 running](https://i.imgur.com/yLFQhvP.png)

## How to Install
## Before

In order to have updated Termux:
- **Purge all data** of Termux in Android Settings
- Uninstall and reinstall latest Termux version from [F-Droid](https://f-droid.org/en/packages/com.termux/) (Version on Play Store is outdated)
- Then launch Termux to initialization, close it (force stop, not swap)
- Reopen and follow the instructions below

### Auto
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh)
```

### Manual
```bash
pkg install wget

wget https://github.com/gushmazuko/metasploit_in_termux/raw/master/metasploit.sh


chmod +x metasploit.sh

./metasploit.sh
```

## Launch metasploit
After installation start Metasploit using the command:
```bash
msfconsole
```

## Update
The installer saves itself as the `msf-setup` command, so updating is quick (no full reinstall):
```bash
msf-setup --update
```

## Uninstall
```bash
msf-setup --uninstall          # removes Metasploit, symlinks and the installer
msf-setup --uninstall --purge  # also deletes ~/.msf4 (loot, history, database!)
```

## Optional database
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh) --with-db
```
Initializes a dedicated postgres in `~/.msf4/db` on port 5433 — your existing Termux postgres, if any, is never touched.

## Testing
Every change to the installer is verified on GitHub Actions against the official `termux/termux-docker:aarch64` image on ARM64 runners:

- ✅ **Dependencies Installation**: All required packages install correctly on ARM64
- ✅ **Metasploit Framework**: Complete bundle install on current Termux (Ruby 4.x)
- ✅ **msfconsole**: Startup and version check (`msfconsole -qx "version; exit"`)
- ✅ **msfvenom**: Payload generation test (`msfvenom -p windows/meterpreter/reverse_tcp`)
- 📄 On failure, CI uploads the full install log and native gem build logs (`gem_make.out` / `mkmf.log`)

A scheduled weekly run also catches upstream drift (Ruby, gems, Metasploit itself).
