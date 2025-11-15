#!/bin/bash

#
# check docker image released by Espressif
#
#
#  chromium-browser --headless --disable-gpu --dump-dom 
#	https://hub.docker.com/r/espressif/idf/tags
#  | gawk -v  RS='[<>\n]' '/docker pull/ && /release/ { print $3 }'
#

#
# this software is Source code licensed MIT. 
# Copyright 2025 ike.
# Licensed under the Apache License 2.0 (the "License").  
#

#
# variable
#

_URL='https://hub.docker.com/v2/namespaces/espressif/repositories/idf/tags?platforms=true&ordering=last_updated&name='
_FILE=.Release_containers
_FILE_old=${_FILE}.old
_FILE_for_DEBUG=${_FILE}.LOG

if wget --version > /dev/null 2>&1; then
    _SCRAPER_BIN=wget
    _SCRAPER_OPTION="-q -O -"
elif curl --version > /dev/null 2>&1; then
    _SCRAPER_BIN=curl
    _SCRAPER_OPTION="-s"
else
    echo "please install wget or curl."
    exit 1
fi

_SCRAPER="$_SCRAPER_BIN $_SCRAPER_OPTION $_URL "
_TEE="tee $_FILE_for_DEBUG"

__DEBUG=0
__LOCALTIME=1
__ZULU=0
	    

print_help() {
    _pname=$(basename $0)
    echo -e "$_pname"
    echo -e " scrape docker-hub and output the list of the espressif docker image."
    echo -e ""
    echo -e " outout files are ${_FILE}, ${_FILE_old}, and ${_FILE_for_DEBUG}."
    echo -e "   ${_FILE}, ${_FILE_old} :  list of docker image"
    echo -e "   ${_FILE_for_DEBUG} :  raw output of curl/wget"
    echo -e ""
    echo -e " $_pname [--help|--utc|--with-utc] [--debug]"
    echo -e "    --help|-h \t show this message"
    echo -e "    --utc|-u \t ctime is UTC"
    echo -e "    --with-utc \t ctime is local time and UTC"
    echo -e "    --debug \t use ${_FILE_for_DEBUG} instead of accessing docker hub"
    unset _pname
}

_ac=$#
_av=$*

#
# for help
#
for i in $_av; do
    case $i in
	"--h"*|"-h"|"help"|"?")
	    print_help
	    exit
	    ;;
	"--debug")
	    __DEBUG=1
	    ;;
	"--utc"|"-u")
	    __LOCALTIME=0
	    __ZULU=1
	    ;;
	"--with-utc"|"--with-UTC")
	    __LOCALTIME=1
	    __ZULU=1
	    ;;
	*)
	    ;;
    esac	    
done

#
# for debug
#

if [ $__DEBUG -ne 0 ]; then
    if [ ! -f ${_FILE_for_DEBUG} ]; then
	echo "DEBUG: test input file $_FILE_for_DEBUG not found."
	echo "DEBUG: run $_SCRAPER > $_FILE_for_DEBUG first."
	exit
    fi
    _SCRAPER="cat ${_FILE_for_DEBUG}"
    _TEE="cat"
fi

__A_COMMAND_first_half="{if (NR%2) {line=\$1} else {"

__A_COMMAND_LTIME="(\"date --rfc-3339=seconds --date=\"\$1) | getline ldstr;"
__A_COMMAND_UTC="(\"date -u --rfc-3339=seconds --date=\"\$1) | getline udstr;"
__A_COMMAND_second_half="print line"

if [ $__LOCALTIME -eq 0 ] && [ $__ZULU -eq 0 ]; then
    __A_COMMAND="${__A_COMMAND_first_half}""${__A_COMMAND_second_half}""}}"
else
    if [ $__LOCALTIME -ne 0 ]; then
       __A_COMMAND_second_half="${__A_COMMAND_second_half}""\"\\t\"ldstr"
       __A_COMMAND="${__A_COMMAND_first_half}""${__A_COMMAND_LTIME}""${__A_COMMAND_second_half}""}}"
    fi
    if [ $__ZULU -ne 0 ]; then
       __A_COMMAND_second_half="${__A_COMMAND_second_half}""\"\\t\"udstr"
       __A_COMMAND="${__A_COMMAND_first_half}""${__A_COMMAND_LTIME}""${__A_COMMAND_UTC}""${__A_COMMAND_second_half}""}}"
    fi
fi

if [ $__DEBUG -ne 0 ]; then
    :
else
    [ -f $_FILE_old ] && rm $_FILE_old
    [ -f $_FILE ] && mv $_FILE $_FILE_old
    exec > $_FILE
fi

$_SCRAPER | $_TEE \
    | jq -r '.results[] | .name, .last_updated' \
    | gawk "${__A_COMMAND}"
