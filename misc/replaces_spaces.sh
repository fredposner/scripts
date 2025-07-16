#! /bin/bash
# Always be kind.
COMMAND=`basename $0`
cat<<!
          __              _                                 
   ____  / _|            | |                                
  / __ \| |_ _ __ ___  __| |_ __   ___  ___ _ __   ___ _ __ 
 / / _` |  _| '__/ _ \/ _` | '_ \ / _ \/ __| '_ \ / _ \ '__|
| | (_| | | | | |  __/ (_| | |_) | (_) \__ \ | | |  __/ |   
 \ \__,_|_| |_|  \___|\__,_| .__/ \___/|___/_| |_|\___|_|   
  \____/                   | |                              
                           |_|                              
(c) 2025 Fred Posner
This program comes with ABSOLUTELY NO WARRANTY;
This is free software, and you are welcome to redistribute it under
certain conditions. MIT License

!
#-- date
DT=$(date '+%Y%m%d-%H%M%S');
CURRDIR=`echo $PWD`
usage() {
cat <<EOF
NAME
  $COMMAND - Rename files with spaces using a hyphen

SYNOPSIS
  $COMMAND [options]
  $COMMAND -o -d

DESCRIPTION
  This tool is a simple shell script to rename files in a directory.
  Files with spaces have the spaces replaced with a hyphen or underscore.

OPTIONS
  -h HELP
      Display this help text.

  -o KEEP ORIGINALS
      use copy instad of mv

  -u USE UNDERSCORE
      use _ instead of - in file replacement

  -d DIRECTORY
      specify directory. Default is current directory

AUTHOR
  Written by Fred Posner <fred@pgpx.io>

COPYRIGHT
  Copyright (C) 2025 Fred Posner

EOF
}

#-- check arguments and environment
while getopts "od:" flag; do
	case $flag in
		o) KEEPORIG=true ;;
		h) usage; exit 0 ;;
        d) DIRECTORY="$OPTARG" ;;
        u) USEUNDERSCORE=true;;
		\?) usage; echo "Invalid option: $OPTARG"; exit 0 ;;
	esac
done

echo "[o] start"
echo "[-] current directory: $CURRDIR"
if [ -z "${DIRECTORY}" ]; then
    DIRECTORY=$CURRDIR
else
	echo "[-] using custom directory"
fi

if [ -d "$DIRECTORY" ]; then
    echo "[-] directory $DIRECTORY exists"
else
    echo "[x] directory $DIRECTORY does not exist"
    exit 2
fi

cd $DIRECTORY
echo "[-] starting"
for f in *; do
    if [[ -f "$f" && "$f" == *" "* ]]; then
        echo -e "\t...handling $f"
        if [ "$KEEPORIG" = true ] ; then 
            CMD="cp"
        else
            CMD="mv"
        fi

        if [ "$USEUNDERSCORE" = true ] ; then 
            $CMD "$f" "${f// /_}"
        else
            $CMD "$f" "${f// /-}"
        fi
    fi
done

echo "[+] done"
