<div align="center">
  <img src=".github/assets/logo.svg" width="140" alt="Metasploit in Termux" />

# Metasploit in Termux

**Full [Metasploit Framework](https://github.com/rapid7/metasploit-framework) on a non-rooted Android phone — one command.**

[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Termux-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://termux.dev)
[![Arch](https://img.shields.io/badge/arch-aarch64-2f81f7?style=for-the-badge)](https://github.com/gushmazuko/metasploit_in_termux/actions/workflows/termux-metasploit-arm64.yml)
[![Ruby](https://img.shields.io/badge/Ruby-4.x-CC342D?style=for-the-badge&logo=ruby&logoColor=white)](https://www.ruby-lang.org)
[![CI](https://github.com/gushmazuko/metasploit_in_termux/actions/workflows/termux-metasploit-arm64.yml/badge.svg?style=for-the-badge)](https://github.com/gushmazuko/metasploit_in_termux/actions/workflows/termux-metasploit-arm64.yml)
[![License](https://img.shields.io/badge/license-MIT-8b6cff?style=for-the-badge)](LICENSE)
[![Stars](https://img.shields.io/github/stars/gushmazuko/metasploit_in_termux?style=for-the-badge&color=f8b84e)](https://github.com/gushmazuko/metasploit_in_termux/stargazers)

`bash <(curl -fsSL https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh)`

</div>

## Requirements

- **Termux from [F-Droid](https://f-droid.org/en/packages/com.termux/) or [GitHub Releases](https://github.com/termux/termux-app/releases)** — the Play Store build is not supported
- **aarch64 device** (ARMv8 — CI-verified on the official Termux image with current Ruby)
- ~2 GB free space and 20–60 minutes (native gems are compiled on-device)
- Stable network (Termux mirrors, GitHub, RubyGems)

> **Old or previously-broken Termux setup?** Purge Termux data in Android Settings, reinstall from F-Droid, open it once, force-stop, then proceed. A stale package set is the most common source of install failures.

## Install

One command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh)
```

Or manually:

```bash
curl -fsSL -o metasploit.sh https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh
chmod +x metasploit.sh
./metasploit.sh
```

The installer verifies that `msfconsole` actually boots before reporting success.

## Usage

| Command | What it does |
|---|---|
| `msfconsole` | Start Metasploit |
| `msfvenom` | Generate payloads |
| `msfrpcd` | Start the RPC daemon |
| `msf-setup --update` | Update Metasploit in place |
| `msf-setup --uninstall` | Remove Metasploit, symlinks and the installer |
| `msf-setup --uninstall --purge` | Also delete `~/.msf4` — **loot, history, database** |

`msf-setup` is installed locally as a command; the same flags also work directly from the one-liner (e.g. `... metasploit.sh --update`).

### Optional database

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh) --with-db
```

Initializes a dedicated PostgreSQL in `~/.msf4/db` on port 5433 (msfdb-style). An existing Termux PostgreSQL cluster, if you have one, is never touched. The database does not auto-start after a reboot — restart it with `pg_ctl -D ~/.msf4/db -o "-p 5433" start`.

## What the installer does

Full transparency, since this script installs packages and modifies your Termux prefix:

| Item | Detail |
|---|---|
| Installs | Termux packages (clang, ruby, postgresql, libxml2, …) and upgrades existing ones, then Metasploit via `bundle install` |
| Framework location | `$PREFIX/opt/metasploit-framework` (shallow clone of upstream master) |
| Gems | Isolated in `vendor/bundle` **inside** the framework dir — only bundler itself goes to the system gem dir |
| Commands | `msfconsole`, `msfvenom`, `msfrpcd`, `msf-setup` symlinked into `$PREFIX/bin` |
| Local patches to upstream | `termux-fix-shebang` on the three binaries (Android has no `/usr/bin/env`); Ruby-4.0 default-gem alignment (`date`, `stringio`) and a relaxed date pin in the gemspec — re-applied automatically by `--update` |
| Data | `~/.msf4` is created by Metasploit itself (and by `--with-db`) and is only removed with `--uninstall --purge` |
