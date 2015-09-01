#!/bin/bash

COLOR_HIGHLIGHT='\033[1;33m'
COLOR_NONE='\033[0m'

function printmsg {
	if [ -n "$1" ];
	then
		printf "${COLOR_HIGHLIGHT}$1${COLOR_NONE}\n"
	fi
}
