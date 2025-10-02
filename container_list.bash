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

_SCRAPER_BIN=chromium-browser
_SCRAPER_OPTION="--headless --disable-gpu --dump-dom"
_URL="https://hub.docker.com/r/espressif/idf/tags"

_FILE=.Release_containers
_FILE_old=${_FILE}.old
_FILE_for_DEBUG=${_FILE}.LOG

_SCRAPER="$_SCRAPER_BIN $_SCRAPER_OPTION $_URL "
_TEE="tee $_FILE_for_DEBUG"

print_help() {
    echo " scrape docker-hub and output the list of the espressif docker image."
    echo " outout files are ${_FILE}, ${_FILE_old}, and ${_FILE_for_DEBUG}."
    echo "   ${_FILE}  list of docker image"
    echo "   ${_FILE_old}  old list of docker image"
    echo "   ${_FILE_for_DEBUG}  raw output of chromium-brouser"
    echo ""
    echo "  this script uses \"chromium-browser --headless\"."
    echo "  set limit to execute once a day"
    echo "  because chromium-brouser errors when executed in short period."
}

#
# for help
#
if [ x"$1" == "x--help" ]; then
    print_help
    exit
fi

#
# for debug
#
if [ x"$1" == "x--debug" ]; then
    __DEBUG=1
else
    __DEBUG=0
fi


_PERIOD=$((24 * 60 * 60))
_now=$(date +"%s")
[ -f $_FILE ] || touch --date="-2 day" $_FILE
_FILE_CTIME=$(stat --print="%Y\n" $_FILE)
_diff=$((_now - _FILE_CTIME))

if [ $__DEBUG -ne 0 ]; then
    if [ ! -f ${_FILE_for_DEBUG} ]; then
	echo "DEBUG: test input file $_FILE_for_DEBUG not found."
	echo "DEBUG: run $_SCRAPER > $_FILE_for_DEBUG first."
	exit
    fi
    _SCRAPER="cat ${_FILE_for_DEBUG}"
    _TEE="cat"
    _PERIOD=0
fi

if [ $_diff -lt $_PERIOD ]; then
    echo "ERROR: too early to execute 'chrome-browser --headless'"
    echo "ERROR: wait for 24hrs (or rm $_FILE and retry.)"
    exit
else

    if [ $__DEBUG -ne 0 ]; then
        :
    else
	[ -f $_FILE_old ] && rm $_FILE_old
	[ -f $_FILE ] && mv $_FILE $_FILE_old
	exec > $_FILE
    fi

    $_SCRAPER | $_TEE \
    | gawk -v  RS='[<>\n]' '
#    BEGIN {OFS = "\t"}
    /dateFromContent/{
        date_str_in_file=gensub(/at /, "", "g", gensub(/^.* aria-label=(".+")/, "\\1", "g",$0))
	("date -u --rfc-3339=seconds --date="date_str_in_file) | getline date_str
	gsub(/\+.*$/, "", date_str)
    }
    /docker pull/ {
	name=$3; datelist[name]=date_str
	if (name ~ /:release/) {
	    rlist[++rn]=name;
	} else if (name ~ /:latest$/) {
	    latest[++ln]=name;
	} else {
	    vlist[++vn]=name;
	}
    }
    END {
	OFS = "\t"
	asort(rlist);asort(vlist);
	for(ii=length(latest);ii > 0;ii--) print latest[ii], datelist[latest[ii]];
	for(ii=length(rlist);ii > 0;ii--) print rlist[ii], datelist[rlist[ii]];
	for(ii=length(vlist);ii > 0;ii--) print vlist[ii], datelist[vlist[ii]];
    }
    '
fi

