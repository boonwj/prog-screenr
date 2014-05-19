#!/bin/bash

#################################### NOTE ####################################
# Associative Arrays Utilised. Only avaliable for on BASH Version 4 onwards.

#################################### CONF ####################################
declare -A PROG_CMD_MAP
PROG_CMD_MAP["sleeper"]="./sleeper 0.5"
PROG_CMD_MAP["shouter"]="./shouter"
PROG_CMD_MAP["counter"]="./counter 4 30"

declare -A PROG_WKDIR_MAP
PROG_WKDIR_MAP["sleeper"]="/home/boon/Documents/git/startup_script/test_prog"
PROG_WKDIR_MAP["shouter"]="/home/boon/Documents/git/startup_script/test_prog"
PROG_WKDIR_MAP["counter"]="/home/boon/Documents/git/startup_script/test_prog"

#################################### MISC ####################################
function helpMessage
{
	echo "Usage: "
	PROG_LIST=""
	for prog in "${!PROG_CMD_MAP[@]}"; do 
		PROG_LIST+=" "
		PROG_LIST+=$prog
		PROG_LIST+=" |"
	done
	me=`basename $0`
	echo "   $me <${PROG_LIST%?}> < start | stop > "
	exit
}

function checkOneProg
{	
	echo "Checking process: ${1}"
	proc=$(ps -ef | grep "${1}" | grep -v SCREEN | grep -v grep | awk '{print $2}')
	processes=$(echo $proc | wc -w)
	if [ $processes -eq 0 ]; then
		echo "-> Process is yet to be started."
		return 0
	else
		echo "-> Process is already running with the following PID value(s):"
		echo "${proc}"
		return 1
	fi
}

function startOneProg
{	
	echo "[${1}]"
	PROG_CMD=${PROG_CMD_MAP[${1}]}
	if checkOneProg $PROG_CMD; then
		echo "-> Starting Process "
		cd ${PROG_WKDIR_MAP[${1}]}
		echo screen -dmS ${1} bash -c $PROG_CMD
		screen -dmS ${1} bash -c "$PROG_CMD"
		echo "-> Started Process "
	fi
}

function stopOneProg
{
	echo test
}

function checkAllProg
{
	for prog in "${!PROG_CMD_MAP[@]}"; do
		checkOneProg $prog
	done	
}

function startAllProg
{
	for prog in "${!PROG_CMD_MAP[@]}"; do
		startOneProg $prog
	done
}

function stopAllProg
{
	echo test
}

#################################### MAIN ####################################
if(($# < 1)); then
	helpMessage
fi

if [[ ${1} == "start" ]]; then
	startAllProg

elif [[ ${1} == "stop" ]]; then
	stopAllProg

elif [[ ${1} == "check" ]]; then
	checkAllProg

elif [ ${PROG_CMD_MAP[${1}]+_} ]; then 
	if [[ ${2} == "start" ]]; then
		startOneProg ${1}
	elif [[ ${2} == "stop" ]]; then
		stopOneProg ${1}
	else
		echo "Error: Invalid command provided"
		helpMessage	
	fi
else
	echo "Error: Invalid command provided"
	helpMessage
fi