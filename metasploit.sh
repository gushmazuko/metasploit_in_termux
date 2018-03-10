#!/data/data/com.termux/files/usr/bin/bash
echo "##############################################"
echo " "
echo "Original source: https://github.com/Hax4us/Metasploit_termux"
echo "##############################################"

# Metasploit version
msf_ver=4.16.38

echo "WAIT UNTIL INSTALLING............" 

echo "####################################"
pkg install -y autoconf bison clang coreutils curl findutils git apr apr-util libffi-dev libgmp-dev libpcap-dev postgresql-dev readline-dev libsqlite-dev openssl-dev libtool libxml2-dev libxslt-dev ncurses-dev pkg-config postgresql-contrib wget make ruby-dev libgrpc-dev termux-tools ncurses-utils ncurses unzip zip tar postgresql termux-elf-cleaner
pkg upgrade
echo "####################################"

echo "Downloading & Extracting....."

cd $HOME
curl -LO https://github.com/rapid7/metasploit-framework/archive/$msf_ver.tar.gz
tar -xf $HOME/$msf_ver.tar.gz
mv $HOME/metasploit-framework-$msf_ver $HOME/metasploit-framework
rm $HOME/$msf_ver.tar.gz
cd $HOME/metasploit-framework
sed '/rbnacl/d' -i Gemfile.lock
sed '/rbnacl/d' -i metasploit-framework.gemspec
gem install bundler
sed 's|nokogiri (1.*)|nokogiri (1.8.0)|g' -i Gemfile.lock

gem install nokogiri -v 1.8.0 -- --use-system-libraries
 
#sed 's|grpc (.*|grpc (1.4.1)|g' -i $HOME/metasploit-framework/Gemfile.lock
#gem unpack grpc -v 1.4.1
#cd grpc-1.4.1
#curl -LO https://raw.githubusercontent.com/grpc/grpc/v1.4.1/grpc.gemspec
#curl -L https://raw.githubusercontent.com/Hax4us/Hax4us.github.io/master/extconf.patch
#patch -p1 < extconf.patch
#gem build grpc.gemspec
#gem install grpc-1.4.1.gem
#cd ..
#rm -r grpc-1.4.1


cd $HOME/metasploit-framework
bundle install -j5
$PREFIX/bin/find -type f -executable -exec termux-fix-shebang \{\} \;
rm ./modules/auxiliary/gather/http_pdf_authors.rb
if [ -e $PREFIX/bin/msfconsole ];then
	rm $PREFIX/bin/msfconsole
fi
if [ -e $PREFIX/bin/msfvenom ];then
	rm $PREFIX/bin/msfvenom
fi
ln -s $HOME/metasploit-framework/msfconsole /data/data/com.termux/files/usr/bin/
ln -s $HOME/metasploit-framework/msfvenom /data/data/com.termux/files/usr/bin/
termux-elf-cleaner /data/data/com.termux/files/usr/lib/ruby/gems/2.4.0/gems/pg-0.20.0/lib/pg_ext.so
echo "Creating database"

cd $HOME/metasploit-framework/config
curl -LO https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/database.yml

mkdir -p $PREFIX/var/lib/postgresql
initdb $PREFIX/var/lib/postgresql

pg_ctl -D $PREFIX/var/lib/postgresql start
createuser msf
createdb msf_database

echo "####################################"
echo "Thanx  To  Hax4us"
echo "####################################"
echo " NOW YOU CAN LAUNCH METASPLOIT BY JUST EXECUTE THE COMMAND :=> msfconsole"
echo "####################################"
