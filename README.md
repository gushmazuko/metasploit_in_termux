# Metasploit Framework 6 in Termux

![Metasploit 6 running](https://i.imgur.com/yLFQhvP.png)

## How to install:
```bash
source <(curl -s https://kutt.it/msf)
```
**Or manual**

-apt install wget

-wget https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh

-chmod +x metasploit.sh

./metasploit.sh
```
## After install, run from terminal
```bash
# Start postgresql
./postgresql_ctl.sh start

# And run msfconsole
msfconsole
```
