# Metasploit Framework 6 in Termux

![Metasploit 6 running](https://i.imgur.com/yLFQhvP.png)

## How to install:
```bash
source <(curl -s https://kutt.it/msf)
```
**Or manual**

-apt install wget

- then download it type `wget https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh`

- give it permission type`chmod +x metasploit.sh`

- ./metasploit.sh
```
Note- This process will take your 300-400 Mb of mobile data and storage
## After install, run from terminal
```bash
# Start postgresql
./postgresql_ctl.sh start

# And run msfconsole
msfconsole
```
