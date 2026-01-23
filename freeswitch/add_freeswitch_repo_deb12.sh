#!/bin/bash
#--
#-- installs freeswitch repo for debian 12
#--

COMMAND=`basename $0`
cat <<EOF

==============================================
   ___           __                          
  / _/______ ___/ /__  ___  ___ ___  ___ ____
 / _/ __/ -_) _  / _ \/ _ \(_-</ _ \/ -_) __/
/_//_/  \__/\_,_/ .__/\___/___/_//_/\__/_/   
               /_/                           
==============================================

$COMMAND
(c) 2026 Fred Posner
MIT License

EOF

#-- functions
function usage() {
cat <<EOF
NAME
  $COMMAND - installs freeswitch repo for debian 12

SYNOPSIS
  $COMMAND [options]
  $COMMAND -t pat_whatever

DESCRIPTION
  This tool is a simple shell script to add the freeswitch
  repository to debian 12

OPTIONS
  -h
      Display this help text.

  -t TOKEN
      token from signalwire

AUTHOR
  Written by Fred Posner <fred@pgpx.io>

COPYRIGHT
  Copyright (C) 2026 Fred Posner

EOF
}

#-- check arguments and environment
while getopts "ht:" flag; do
	case $flag in
		t) TOKEN="$OPTARG" ;;
		h) usage; exit 0 ;;
		\?) echo "Invalid option: $OPTARG"; usage; exit 0 ;;
	esac
done

if [ -z "${TOKEN}" ]; then
    usage
    cat <<EOF
===============
TOKEN not found
-t is required 
===============

EOF
    exit 2
else
    echo "...Using token: ${TOKEN}"
fi

#-- update apt
echo "...Update apt"
AINSTALL=$(apt update)
if [ "$?" -eq "0" ]
    echo "[X] Error updaing apt: ${AINSTALL}"
    exit 1
fi

#-- check for prereqs...
if command -v curl >/dev/null 2>&1; then
    echo "...curl found"
else
    CURLRESULT=$(apt -y install curl)
    if [ "$?" -eq "0" ]
        echo "[X] Error installing curl: ${CURLRESULT}"
        exit 1
    else
        echo "...curl installed"
    fi
fi

if command -v wget >/dev/null 2>&1; then
    echo "...wget found"
else
    WGETRESULT=$(apt -y install wget)
    if [ "$?" -eq "0" ]
        echo "[X] Error installing wget: ${WGETRESULT}"
        exit 1
    else
        echo "...wget installed"
    fi
fi

if command -v lsb_release >/dev/null 2>&1; then
    echo "...lsb_release found"
else
    LSBRESULT=$(apt -y install lsb-release)
    if [ "$?" -eq "0" ]
        echo "[X] Error installing lsb_release: ${LSBRESULT}"
        exit 1
    else
        echo "...lsb_release installed"
    fi
fi

#-- awesome. install the repo
KEYRESULT=$(wget --http-user=signalwire --http-password=$TOKEN -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg)
if [ "$?" -eq "0" ]
    echo "[X] Error downloading freeswitch key: ${KEYRESULT}"
    exit 1
else
    echo "...freeswitch key downloaded to /usr/share/keyrings/signalwire-freeswitch-repo.gpg"
fi

#-- add token auth to auth.com
echo "machine freeswitch.signalwire.com login signalwire password $TOKEN" >> /etc/apt/auth.conf
echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list
echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list

REUPDATE=$(apt-get update)
if [ "$?" -eq "0" ]
    echo "[X] Error updating new repo: ${REUPDATE}"
    exit 1
else
    echo "...repo added"
fi

cat <<EOF
...done

freeswitch repo added. install via:
> apt-get install -y freeswitch-meta-all
    or
> apt -y install freeswitch-meta-vanilla

EOF
