# Metasploit Framework 6 in Termux

## How to install:
```bash
source <(curl -s https://kutt.it/msf)
```
**Or manual**
```bash
wget https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh

chmod +x metasploit.sh

./metasploit.sh
```
## After install, run from terminal
```bash
# Start postgresql
./postgresql_ctl.sh start

# And run msfconsole
msfconsole
```
