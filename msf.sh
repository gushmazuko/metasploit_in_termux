apt update -y; apt upgrade -y
if [ -d "$PREFIX/lib/ruby" ]; then   
   rm -rf $PREFIX/lib/ruby; apt remove ruby -y
fi
apt install -y binutils python autoconf bison clang coreutils curl findutils apr apr-util postgresql openssl readline libffi libgmp libpcap libsqlite libgrpc libtool libxml2 libxslt ncurses make ncurses-utils ncurses git wget unzip zip tar termux-tools termux-elf-cleaner pkg-config git ruby
wget https://github.com/dedshit/metasploit_in_termux/blob/master/nokogiri-1.14.5.gem?raw=true
gem install nokogiri-1.14.5.gem -- --use-system-libraries
git clone https://github.com/rapid7/metasploit-framework.git --depth=1
cd metasploit-framework
./msfvenom
