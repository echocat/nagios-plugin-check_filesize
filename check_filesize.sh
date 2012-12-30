#!/bin/bash

# --------------------------------------------------------------------
# **** BEGIN LICENSE BLOCK *****
#
# Version: MPL 2.0
#
# echocat check_filesize.sh, Copyright (c) 2011-2012 echocat
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# **** END LICENSE BLOCK *****
# --------------------------------------------------------------------

# --------------------------------------------------------------------
# Check if a file size is smaller then given parameters.
#
# @author: Daniel Werdermann / dwerdermann@web.de
# @projectsite: https://github.com/echocat/nagios-plugin-check_filesize
# @version: 1.3
# @date: 2012-12-30 14:28:21 CEST
#
# changes 1.3
#  - just update license information
# changes 1.2
#  - look for logger path via which command
#  - fiexes for solaris support
# changes 1.1
#  - add license information
# --------------------------------------------------------------------


# --------------------------------------------------------------------
# configuration
# --------------------------------------------------------------------
PROGNAME=$(basename $0)
WARN_MESG=()
CRIT_MESG=()
LOGGER="`which logger` -i -p kern.warn -t"

export PATH="/bin:/usr/local/bin:/sbin:/usr/bin:/usr/sbin:/usr/sfw/bin"
LIBEXEC="/opt/nagios/libexec /usr/lib64/nagios/plugins /usr/lib/nagios/plugins /usr/local/nagios/libexec /usr/local/libexec"
for i in ${LIBEXEC} ; do
  [ -r ${i}/utils.sh ] && . ${i}/utils.sh
done

if [ -z "$STATE_OK" ]; then
  echo "nagios utils.sh not found" &>/dev/stderr
  exit 1
fi

# --------------------------------------------------------------------


# --------------------------------------------------------------------
# functions
# --------------------------------------------------------------------
function log() {
	$LOGGER ${PROGNAME} "$@";
}

function usage() {
	echo "Usage: $PROGNAME  -w BYTESIZE -c BYTESIZE FILE [FILE2 FILE3 ...]"
	echo "Usage: $PROGNAME -h,--help"
	echo "Options:"
	echo " FILES     Check this file(s)"
	echo " -w Bytes  Warn if filesize greater then this"
	echo " -c Bytes  Critical filesize greater this"
}

function print_help() {
	echo ""
	usage
	echo ""
	echo "Check if filesize is smaller then given parameters"
	echo ""
	echo "This plugin is NOT developped by the Nagios Plugin group."
	echo "Please do not e-mail them for support on this plugin, since"
	echo "they won't know what you're talking about."
	echo ""
	echo "For contact info, read the plugin itself..."
}

# --------------------------------------------------------------------
# startup checks
# --------------------------------------------------------------------

if [ $# -eq 0 ]; then
	usage
	exit $STATE_CRITICAL
fi

while [ "$1" != "" ]
do
	case "$1" in
		--help) print_help; exit $STATE_OK;;
		-h) print_help; exit $STATE_OK;;
		-w) WARN=$2; shift 2;;
		-c) CRIT=$2; shift 2;;
		/*) FILES="${FILES} $1"; shift;;
		*) usage; exit $STATE_UNKNOWN;;
	esac
done


if [ $WARN -gt $CRIT ] ; then
	log "UNKNOWN: warn value is greater then crit value"
	exit $STATE_UNKNOWN
fi

# --------------------------------------------------------------------
# now we check if ...
#  1) ... file exists
#  2) ... has the correct filesize
# --------------------------------------------------------------------

for FILE in ${FILES} ; do
	if [ ! -f $FILE ]; then
		log "CRITICAL: $FILE don't exists"
		CRIT_MESG[${#CRIT_MESG[*]}]="${FILE} don't exists"
	fi

	SIZE=$(stat -c %s $FILE)

	if [ $SIZE -gt $CRIT ] ; then
		log "CRITICAL: ${FILE} has size ${SIZE} Byte. Critical at ${CRIT}."
		CRIT_MESG[${#CRIT_MESG[*]}]="${FILE} has size ${SIZE} Byte. Critical at ${CRIT}."
	elif [ $SIZE -gt $WARN ] ; then
		log "WARN: ${FILE} has size ${SIZE} Byte. Warn at ${CRIT}."
		WARN_MESG[${#WARN_MESG[*]}]="${FILE} has size ${SIZE} Byte. Warn at ${WARN}."
	fi
done

if [ ${#CRIT_MESG[*]} -ne 0 ]; then
	echo -n "CRITICAL: "
	for element in "${CRIT_MESG[@]}"; do
		echo -n ${element}" ; "
	done
	echo
	exit $STATE_CRITICAL
elif [ ${#WARN_MESG[*]} -ne 0 ]; then
	echo -n "WARN: "
	for element in "${WARN_MESG[@]}"; do
		echo -n ${element}" ; "
	done
	echo
	exit $STATE_WARNING
fi

echo "OK: filesize of ${FILES} is smaller then ${WARN} Bytes."
exit $STATE_OK
