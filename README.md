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
source <(curl -fsSL https://kutt.it/msf)
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

## Testing
This installation script is automatically tested via GitHub Actions CI on ARM64 architecture to ensure reliability:

- ✅ **Dependencies Installation**: All required packages install correctly on ARM64
- ✅ **Metasploit Framework**: Complete installation and build verification
- ✅ **msfconsole**: Startup and version check (`msfconsole -qx "version; exit"`)
- ✅ **msfvenom**: Payload generation test (`msfvenom -p windows/meterpreter/reverse_tcp`)
- ✅ **DNS Resolution**: Comprehensive hosts file for Termux container networking

The CI pipeline runs on `ubuntu-24.04-arm` with `termux/termux-docker:aarch64` to match real-world ARM64 usage scenarios.
