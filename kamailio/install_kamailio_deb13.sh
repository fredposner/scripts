#!/bin/bash
#-- install script for kamailio 6.0 via git on debian 13
COMMAND=`basename $0`

#-- functions
function usage() {
cat <<EOF
NAME
  $COMMAND - Kamailio Installer Script

SYNOPSIS
  $COMMAND [options]
  $COMMAND -a lksdjfhsdkljhfdskljhfdslksdhflksdhflskh

DESCRIPTION
  This tool is a simple shell script to install Kamailio, RTPENGINE, 
  sngrep, and other software/configuration files needed for telecom.

OPTIONS
  -h, --help
      Display this help text.

  -a APIBANKEY
      The APIBAN APIKEY to use

  -j
	  Keep Journal (default deletes it and installs rsyslog)

  -r
      Skip RTPENGINE (default is to install)

AUTHOR
  Written by Fred Posner <fred@qxork.com>

COPYRIGHT
  Copyright (C) 2025 Fred Posner

EOF
}

function valid_ip() {
  local  ip=$1
  local  stat=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
      && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
    stat=$?
  fi
  return $stat
}

cat<<!
    >=>                       >=>       >=>              >=> 
  >>                          >=>       >=>              >=> 
>=>> >> >> >==>   >==>        >=>     >=>>==>   >==>     >=> 
  >=>    >=>    >>   >=>   >=>>=>       >=>   >>   >=>   >=> 
  >=>    >=>    >>===>>=> >>  >=>       >=>   >>===>>=>  >=> 
  >=>    >=>    >>        >>  >=>       >=>   >>         >=> 
  >=>   >==>     >====>    >=>>=> >=>    >=>   >====>   >==> 
                                                             
support: https://fred.tel
(c) 2025
!

#-- check arguments and environment
while getopts "hjra:" flag; do
	case $flag in
		a) APIBANKEY="$OPTARG" ;;
		j) KEEPJOURNAL=true ;;
		r) SKIPRTPENGINE=true ;;
		h) usage; exit 0 ;;
		\?) echo "Invalid option: $OPTARG"; usage; exit 0 ;;
	esac
done

MYIP=$(/bin/hostname -I)
MYIP=${MYIP::-1}
MYHOST=$(/bin/hostname)
MYSERVERID=`echo $MYIP | cut -d . -f 4`
DT=$(date '+%d%m%Y-%H%M%S');
LTAG=$0
logger -t $LTAG "starting"
logger -t $LTAG  "running in ${RUNDIR}"
echo "-> ${DT} starting"
echo "-> I am =${MYHOST}= and =${MYIP}="
echo " -> update/upgrade via apt"
apt update &>/dev/null

#-- linux headers
HINSTALL=$(apt-get -y install linux-headers-$(uname -r))
if [ "$?" -eq "0" ]
then
  echo "  -o linux-headers installed"
else
  echo " -x installation FAILED!! (linux-headers)"
  echo "    Error was:"
  echo $HINSTALL
  logger -t $LTAG  "${HINSTALL}"
  exit 1
fi

#-- nftables
NFINSTALL=$(apt-get -y install nftables)
if [ "$?" -eq "0" ]
then
  echo "  -o nftables installed"
else
  echo " -x installation FAILED!! (nftables)"
  echo "    Error was:"
  echo $NFINSTALL
  logger -t $LTAG  "${NFINSTALL}"
  exit 1
fi

#-- get external ip
AINSTALL=$(apt-get -y install dnsutils)
if [ "$?" -eq "0" ]
then
  echo "  -o dnsutils installed"
else
  echo " -x installation FAILED!! (dnsutils)"
  echo "    Error was:"
  echo $AINSTALL
  logger -t $LTAG  "${AINSTALL}"
  exit 1
fi

PUBLICIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
if valid_ip $PUBLICIP
then
  echo " -o Public IP is $PUBLICIP"
else
  echo " -x Public IP $PUBLICIP is not valid"
  logger -t $LTAG  "${PUBLICIP} not valid"
  echo " -x installation FAILED!! (PUBLICIP)"
  exit 1
fi

echo " -> running dist-upgrade..."
apt -y dist-upgrade &>/dev/null

#-- "fix" logging on bookworm by restoring syslog 
if [ "$KEEPJOURNAL" = true ] ; then
  echo "-> skipping install of rsyslog (keep journal selected)..."
else
  echo " -> installing rsyslog and removing journal..."
  apt -y install rsyslog &>/dev/null
  rm -rf /var/log/journal
fi

#-- install rtpengine via apt
if [ "$SKIPRTPENGINE" = true ] ; then
  echo " -> skipping rtpengine"
  RTPENGINE_STATUS="[x] skipped"
else
  echo " -> installing rtpengine"
  RESULT_RTP=$(apt-get install -y rtpengine)
  if [ "$?" -eq "0" ]
  then
    echo "  -o rtpengine installed"
    RTPENGINE_STATUS="[+] installed"
  else
    echo "  -x rtpengine installation FAILED!!"
    echo "    Error was:"
    echo $RESULT_RTP
    RTPENGINE_STATUS="[x] failed"
    echo " moving on..."
  fi
fi

#-- Installing Kamailio prerequisites
echo " -> Installing Kamailio prerequisites..."
KAM_PREREQ="mariadb-client default-libmysqlclient-dev git-core gcc g++ pkg-config flex bison make libssl-dev libev-dev libevent-dev libcurl4-openssl-dev libxml2-dev libpcre2-dev psmisc libexpat1-dev libpcap-dev libjson-c-dev libtool automake libuv1-dev libjansson-dev libjansson4 uuid uuid-dev libunistring-dev net-tools gnupg2 net-tools"
RESULT_KAM_PREREQ=$(apt-get install -y $KAM_PREREQ)
if [ "$?" -eq "0" ]
then
  echo "  -o Kamailio prerequisites installed"
else
  echo "  -x Kamailio installation FAILED!!"
  echo "    Error was:"
  logger -t $LTAG  "${RESULT_KAM_PREREQ}"
  echo $RESULT_KAM_PREREQ
  exit 1
fi

#-- download kamailio via git
cd /usr/local/src/
echo " -> ${DT} Getting Kamailio via git ..."
git clone https://github.com/kamailio/kamailio kamailio &>/dev/null
if [ "$?" -eq "0" ]
then
   echo "  -o Kamailio downloaded"
else
   echo "  -x Kamailio installation FAILED!!"
   echo "    Error whilst downloading Kamailio"
   logger -t $LTAG  "couldnt download kamailio. does folder alreader exist..."
   exit 1
fi

#-- make config file
cd kamailio
git checkout -b 6.0 origin/6.0 &>/dev/null
echo " -> Making config ..."
make cfg
make include_modules="outbound http_client http_async_client jansson uuid utils websocket tls db_mysql json" cfg

if [ "$?" -eq "0" ]
then
   echo "  -o Make config ... done."
else
   echo "  -x Kamailio installation FAILED!!"
   echo "    Error whilst creating Kamailio make config"
   logger -t $LTAG  "Error whilst creating Kamailio make config"
   exit 1
fi

#-- compile and build
echo " -> ${DT} Compiling Kamailio.... Hold tight this might take a while ..."
make all &>/dev/null
echo " -> ${DT} Installing Kamailio.... Hold tight this might take a while ..."
make install &>/dev/null

#-- make log
echo " -> ${DT} Creating kamailio log file ..."
KAM_LOG="/var/log/kamailio.log"
if [ -e ${KAM_LOG} ]
then
    echo "  -o Kamailio log file exists"
else
    touch /var/log/kamailio.log
    echo "# Kamailio logging" >> /etc/rsyslog.conf
    echo "local0.* -/var/log/kamailio.log" >> /etc/rsyslog.conf
fi

cat > /etc/logrotate.d/kamailio << EOF
/var/log/kamailio.log {
  daily
  copytruncate
  rotate 7
  compress
}
EOF

if [ "$KEEPJOURNAL" = true ] ; then
    echo " -> No restart of syslog needed"
else
  echo " -> Restarting syslog"
  systemctl restart rsyslog.service
fi

MEMORY=$(expr $(sed -n '/^MemTotal:/ s/[^0-9]//gp' /proc/meminfo) / 1024 / 1024)

#-- copy service
echo " -> ${DT} Setting up kamailio service"
cp /usr/local/src/kamailio/pkg/kamailio/deb/debian/kamailio.init /etc/init.d/kamailio
chmod 755 /etc/init.d/kamailio
sed -i '/^OPTIONS=.*/i ulimit -n 100000' /etc/init.d/kamailio
sed -i "s#CFGFILE=/etc/\$NAME/kamailio.cfg#CFGFILE=/usr/local/etc/kamailio/kamailio.cfg#g" /etc/init.d/kamailio
sed -i "s#DAEMON=/usr/sbin/kamailio#DAEMON=/usr/local/sbin/kamailio#g" /etc/init.d/kamailio
sed -i "s#PATH=/sbin:/bin:/usr/sbin:/usr/bin#PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin#g" /etc/init.d/kamailio
cp /usr/local/src/kamailio/pkg/kamailio/deb/buster/kamailio.default /etc/default/kamailio
sed -i 's#\#RUN_KAMAILIO=yes#RUN_KAMAILIO=yes#g' /etc/default/kamailio
if [ "$MEMORY" = "0" ] ; then
  sed -i 's#\#SHM_MEMORY=64#SHM_MEMORY=512#g' /etc/default/kamailio
else
  sed -i 's#\#SHM_MEMORY=64#SHM_MEMORY=2048#g' /etc/default/kamailio
fi

if [ "$MEMORY" = "0" ] ; then
  sed -i 's#\#PKG_MEMORY=8#PKG_MEMORY=64#g' /etc/default/kamailio
else
  sed -i 's#\#PKG_MEMORY=8#PKG_MEMORY=256#g' /etc/default/kamailio
fi

#-- add user
echo " -> ${DT} Setting up kamailio user"
mkdir -p /var/run/kamailio
adduser --quiet --system --group --disabled-password --shell /bin/false --gecos "Kamailio" --home /var/run/kamailio kamailio
chown kamailio:kamailio /var/run/kamailio

#-- add sngrep
echo " -> install sngrep"
apt -y install sngrep
if [ "$?" -eq "0" ]
then
  echo "  -o sngrep installed"
  SNGREP_STATUS="[+] installed"
else
  echo "  -x sngrep installation FAILED!!"
  SNGREP_STATUS="[x] failed"
  echo " ... moving on"
fi

#-- start kamailio
echo " -> start kamailio"
systemctl daemon-reload
systemctl start kamailio
systemctl enable kamailio

echo " -> ${DT} downloading nftables-api"
mkdir /usr/local/src/nftables-api
cd /usr/local/src/nftables-api
wget https://github.com/apiban/nftables-api/raw/main/nftables-api &>/dev/null
if [ "$?" -eq "0" ]
then
  echo "  -o downloaded"
  #-- make local folder and service
  echo ""
  echo " -> making run directory and service"
  mkdir /usr/local/nftables-api
  cp /usr/local/src/nftables-api/nftables-api /usr/local/nftables-api/nftables-api
  chmod 755 /usr/local/nftables-api/nftables-api
  cat > /lib/systemd/system/nftables-api.service << EOT
[Unit]
Description=nftables-api

[Service]
Type=simple
Restart=always
RestartSec=5s
ExecStart=/usr/local/nftables-api/nftables-api

[Install]
WantedBy=multi-user.target
EOT

  #-- log rotate
  echo " -> set up log rotate"
  cat > /etc/logrotate.d/nftables-api << EOF
/var/log/nftables-api.log {
        daily
        copytruncate
        rotate 12
        compress
}
EOF

  #-- reload / start service
  echo " -> start service"
  systemctl daemon-reload &>/dev/null
  systemctl enable nftables-api &>/dev/null
  systemctl start nftables-api &>/dev/null
  IPTAPI_STATUS="[+] installed"
else
  echo "  -x download FAILED!!"
  IPTAPI_STATUS="[x] failed"
  echo " ... moving on"
fi

#-- os tuning debian 13
#-- functions

echo " -> ${DT} tuning"
FILELIMIT=`grep -o '# lod tuning mod' /etc/security/limits.conf | wc -l`
if [ "$FILELIMIT" = "0" ]; then
    sed -i '/# End of file/i # lod tuning mod'  /etc/security/limits.conf
    sed -i '/# End of file/i *                hard       nofile          65535'  /etc/security/limits.conf
    sed -i '/# End of file/i *                soft       nofile          65535'  /etc/security/limits.conf
    sed -i '/# End of file/i root             hard       nofile          65535'  /etc/security/limits.conf
    sed -i '/# End of file/i root             soft       nofile          65535'  /etc/security/limits.conf
    sed -i s/#DefaultLimitNOFILE=/DefaultLimitNOFILE=65535/g /etc/systemd/system.conf
    sed -i s/#DefaultLimitNOFILE=/DefaultLimitNOFILE=65535/g /etc/systemd/user.conf
else 
    echo "-> security limits already tuned"
fi

SYSTUNECOUNT=`grep -o '# lod tuning mod' /etc/sysctl.conf | wc -l`
if [ "$SYSTUNECOUNT" = "0" ]; then
    cat >> /etc/sysctl.conf << EOT
# lod tuning mod
vm.swappiness=0
vm.dirty_expire_centisecs=200
vm.dirty_writeback_centisecs=100
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_fin_timeout = 15
net.core.rmem_default = 31457280
net.core.rmem_max = 33554432
net.core.wmem_default = 31457280
net.core.wmem_max = 33554432
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65536
net.ipv4.tcp_mem = 786432 1048576 26777216
net.ipv4.udp_mem = 65536 131072 262144
net.ipv4.tcp_rmem = 8192 87380 33554432
net.ipv4.udp_rmem_min = 16384
net.ipv4.tcp_wmem = 8192 65536 33554432
net.ipv4.udp_wmem_min = 16384
net.ipv4.tcp_window_scaling = 1
EOT
    sysctl -p
else 
    echo "-> sysctl already tuned"
fi

if [ -z "${APIBANKEY}" ]; then
  echo "skipping APIBAN install (no key provided)"
  IPTAPIBAN_STATUS="[x] skipped"
else
  APIBANFOLDER="/usr/local/bin/apiban"
  CLIENT="apiban-client-nftables"
  if [ -e ${APIBANFOLDER} ]
  then
      echo "  -o /usr/local/bin/apiban exists"
  else
      mkdir /usr/local/bin/apiban 
  fi

  cd /usr/local/bin/apiban    

  if [ -e ${CLIENT} ]
  then
      echo "  -x apiban-client-nftables exists"
      exit 1
  fi

  wget https://github.com/apiban/apiban-client-nftables/raw/refs/heads/main/apiban-client-nftables  
  if [ "$?" -eq "0" ]
  then
    echo "  -o downloaded"
  else
    echo "  -x download FAILED!!"
    exit 1
  fi

  echo "-> setting configuration to use your apikey"
  echo "{\"apikey\":\"$APIBANKEY\",\"lkid\":\"100\",\"verison\":\"nft1.0\",\"dataset\":\"all\",\"flush\":\"200\",\"setname\":\"APIBAN\"}" > config.json

  chmod +x /usr/local/bin/apiban/apiban-client-nftables
  echo "-> setting log rotation"
  cat > /etc/logrotate.d/apiban-client-nftables << EOF
/var/log/apiban-nft-client.log {
        daily
        copytruncate
        rotate 7
        compress
}
EOF
  echo "-> setting up service"
  cat > /lib/systemd/system/apiban-nftables.service << EOF
[Unit]
Description=APIBAN blocker for nftables
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/apiban/apiban-client-nftables

[Install]
WantedBy=multi-user.target
EOF

  cat > /lib/systemd/system/apiban-nftables.timer << EOF
[Unit]
Description=APIBan nftables service schedule

[Timer]
OnUnitActiveSec=300

[Install]
WantedBy=timers.target
EOF
  systemctl enable apiban-nftables.timer
  systemctl enable apiban-nftables.service

  echo "-> starting services. this can take a bit if there are many ips"

  systemctl start apiban-nftables.timer
  systemctl start apiban-nftables.service
  IPTAPIBAN_STATUS="[+] installed"

fi

echo " -> done."
echo ""
echo "status:"
echo "kamailio: [+] installed"
echo "rtpengine: ${RTPENGINE_STATUS}"
echo "sngrep: ${SNGREP_STATUS}"
echo "nftables-api: ${IPTAPI_STATUS}"
echo "apiban: ${IPTAPIBAN_STATUS}"
echo ""
logger -t $LTAG  "kamailio: [+] installed"
logger -t $LTAG  "rtpengine: ${RTPENGINE_STATUS}"
logger -t $LTAG  "sngrep: ${SNGREP_STATUS}"
logger -t $LTAG  "nftables-api: ${IPTAPI_STATUS}"
logger -t $LTAG  "apiban: ${IPTAPIBAN_STATUS}"
