apt install tcpdump sngrep vim
apt install build-essential
apt install git-core subversion libjansson-dev libsqlite3-dev autoconf automake libxml2-dev libncurses5-dev libtool libedit-dev uuid-dev
cd /usr/local/src
wget downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-16.30.1.tar.gz
tar -xzvf asterisk-16.30.1.tar.gz 
cd asterisk-16*/
./contrib/scripts/install_prereq 
./contrib/scripts/install_prereq test
./contrib/scripts/install_prereq install
./bootstrap.sh 
df -ah
./contrib/scripts/get_mp3_source.sh
./configure
make menuselect.makeopts
menuselect/menuselect --enable format_mp3 --enable CORE-SOUNDS-EN-WAV --enable CORE-SOUNDS-EN-ULAW --enable CORE-SOUNDS-EN-G722 menuselect.makeopts
make
make install
make config
make samples
make install-logrotate
