# Metasploit Framework 5 in Termux

**How to install:**
```bash
bash <(curl -s https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh)
```
OR
```bash
wget https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh

chmod +x metasploit.sh

./metasploit.sh
```
**After install, run from terminal**
```bash
# Start postgresql
./postgresql_ctl.sh restart

# And run msfconsole
msfconsole
```


> Original source: https://github.com/Hax4us/Metasploit_termux
