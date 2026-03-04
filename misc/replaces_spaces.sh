#! /bin/bash
# Always be kind.
COMMAND=`basename $0`
cat<<!

    .::                      .::                                                   
  .:                         .::                                                   
.:.: .:.: .:::   .::         .::.: .::     .::     .:::: .:: .::     .::    .: .:::
  .::   .::    .:   .::  .:: .::.:  .::  .::  .:: .::     .::  .:: .:   .::  .::   
  .::   .::   .::::: .::.:   .::.:   .::.::    .::  .:::  .::  .::.::::: .:: .::   
  .::   .::   .:        .:   .::.:: .::  .::  .::     .:: .::  .::.:         .::   
  .::  .:::     .::::    .:: .::.::        .::    .:: .::.:::  .::  .::::   .:::   
                                .::                                                

(c) 2025,2026 Fred Posner
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

  -p PREFIX
      add a prefix to the filename

  -l LOWERCASE
      convert to lowercase

AUTHOR
  Written by Fred Posner <fred@pgpx.io>

COPYRIGHT
  Copyright (C) 2025,2026 Fred Posner

EOF
}

#-- check arguments and environment
while getopts "ouhld:p:" flag; do
	case $flag in
		o) KEEPORIG=true ;;
		h) usage; exit 0 ;;
        d) DIRECTORY="$OPTARG" ;;
		p) PREFIX="$OPTARG" ;;
        u) USEUNDERSCORE=true;;
        l) USELOWERCASE=true;;
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
    echo -e "\t...handling $f"
    if [ "$USELOWERCASE" = true ] ; then 
        fname=$(echo "$f" | tr '[:upper:]' '[:lower:]')
    else
        fname=$f
    fi

    if [ "$KEEPORIG" = true ] ; then 
        CMD="cp"
    else
        CMD="mv"
    fi

    if [[ -f "$f" && "$f" == *" "* ]]; then
        echo -e "\t\t... spaces need to be removed"
        if [ "$USEUNDERSCORE" = true ] ; then 
			if [ -z "${PREFIX}" ]; then
				$CMD "$f" "${fname// /_}"
			else
                echo -e "\t\t... adding prefix"
				$CMD "$f" "${PREFIX}_${fname// /_}"
			fi
        else
			if [ -z "${PREFIX}" ]; then
				$CMD "$f" "${fname// /-}"
			else
                echo -e "\t\t... adding prefix"
				$CMD "$f" "${PREFIX}-${fname// /-}"
			fi
        fi
    else
        echo -e "\t\t... no spaces"
        if [ "$f" != "$fname" ]; then
            if [ -z "${PREFIX}" ]; then
                echo -e "\t\t... making lowercase"
                $CMD "$f" "$fname"
            else 
                echo -e "\t\t... adding prefix"
                $CMD "$f" "${PREFIX}-${fname}"
            fi
        else
            if [ -z "${PREFIX}" ]; then
                echo -e "\t\t... moving on"
            else 
                echo -e "\t\t... adding prefix"
                $CMD "$f" "${PREFIX}-${fname}"
            fi
        fi
    fi
done

echo "[+] done"
