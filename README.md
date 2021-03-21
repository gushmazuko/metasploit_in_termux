# Metasploit Framework 6 in Termux

![Metasploit 6 running](https://i.imgur.com/yLFQhvP.png)

## How to:
### Auto
```bash
source <(curl -fsSL https://kutt.it/msf)
```

### Manual
```bash
pkg install wget

wget https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh

chmod +x metasploit.sh

./metasploit.sh
```

## After installation complete
Start `postgresql`
```bash
./postgresql_ctl.sh start
```
And run `msfconsole`
```bash
msfconsole
```
