<div align="center">
  <img src=".github/assets/logo.svg" width="140" alt="Metasploit in Termux" />

# Metasploit in Termux

**Full [Metasploit Framework](https://github.com/rapid7/metasploit-framework) on a non-rooted Android phone – one command.**

[![Platform](https://img.shields.io/badge/platform-Termux%20%7C%20Android-3DDC84?style=flat-square&logo=android&logoColor=white)](https://termux.dev)
[![Arch](https://img.shields.io/badge/arch-aarch64-2f81f7?style=flat-square)](https://github.com/gushmazuko/metasploit_in_termux/actions/workflows/termux-metasploit-arm64.yml)
[![Ruby](https://img.shields.io/badge/Ruby-4.x-CC342D?style=flat-square&logo=ruby&logoColor=white)](https://www.ruby-lang.org)
[![CI](https://github.com/gushmazuko/metasploit_in_termux/actions/workflows/termux-metasploit-arm64.yml/badge.svg?style=flat-square)](https://github.com/gushmazuko/metasploit_in_termux/actions/workflows/termux-metasploit-arm64.yml)
[![License](https://img.shields.io/badge/license-MIT-8b6cff?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/gushmazuko/metasploit_in_termux?style=flat-square&color=f8b84e)](https://github.com/gushmazuko/metasploit_in_termux/stargazers)

`bash <(curl -fsSL https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh)`

</div>

## Installation

| Needed | Why |
|---|---|
| Termux from [F-Droid](https://f-droid.org/en/packages/com.termux/) or [GitHub](https://github.com/termux/termux-app/releases) | the Play Store build is not supported |
| aarch64 phone (ARMv8) | the platform CI verifies every change on |
| ~2 GB free, 20–60 min | ruby gems with native code are compiled on-device |
| fresh Termux data | stale packages are the #1 cause of failed installs: purge Termux data in Android Settings, reinstall, open once, force-stop |

Then:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh)
```

That is the whole install. It compiles ~250 gems, patches what Android needs patched, and only prints "Installation complete" after `msfconsole` has actually booted once.

## Commands

| Command | Purpose |
|---|---|
| `msfconsole` | run Metasploit |
| `msfvenom` | build payloads |
| `msfrpcd` | run the RPC daemon |
| `msf-setup --update` | pull the latest Metasploit and rebuild in place |
| `msf-setup --uninstall` | remove Metasploit, its symlinks and the installer |
| `msf-setup --uninstall --purge` | also wipe `~/.msf4` (loot, history, database) |

`msf-setup` is copied to `$PREFIX/bin` during install and works offline; the same flags work straight from the curl one-liner too.

**Optional database:** add `--with-db` to the install command for a dedicated PostgreSQL in `~/.msf4/db` (port 5433, never touches a cluster you already run). It does not survive a reboot by itself: restart it with `pg_ctl -D ~/.msf4/db -o "-p 5433" start`.

## How it works

The script is one auditable file. Everything it does:

| Step | What happens |
|---|---|
| packages | installs the toolchain (clang, ruby, postgresql, libxml2 and friends) via `pkg` |
| source | shallow-clones upstream Metasploit master into `$PREFIX/opt/metasploit-framework` |
| gems | installed into `vendor/bundle` inside that folder; only bundler itself lands in the system gem dir |
| android fixes | `termux-fix-shebang` on the msf binaries (no `/usr/bin/env` on Android), Ruby 4.x default-gem alignment for `date` and `stringio`, relaxed `date` pin in the gemspec |
| links | `msfconsole`, `msfvenom`, `msfrpcd`, `msf-setup` symlinked into `$PREFIX/bin` |
| data | `~/.msf4` belongs to Metasploit; deleted only by `--uninstall --purge` |

`--update` re-applies the same steps after `git reset --hard` to upstream master, so the patches never go stale.
