#!/bin/bash

declare -A PROG_CMD_MAP
PROG_CMD_MAP["sleeper"]="./sleeper 0.5"
PROG_CMD_MAP["shouter"]="./shouter"
PROG_CMD_MAP["counter"]="./counter 4 30"

declare -A PROG_WKDIR_MAP
PROG_WKDIR_MAP["sleeper"]="/home/boon/Documents/git/startup_script/test_prog"
PROG_WKDIR_MAP["shouter"]="/home/boon/Documents/git/startup_script/test_prog"
PROG_WKDIR_MAP["counter"]="/home/boon/Documents/git/startup_script/test_prog"

declare -A PROG_SCREEN_MAP
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
	echo "kindle <${PROG_LIST%?}> < start | stop > "
	# echo "kindle <start | stop | status>" 
}

function startOneProg
{
	echo "[${1}]"
	echo "-> Starting Process "
	cd ${PROG_WKDIR_MAP[${1}]}
	screen -dmS ${1} bash -c "${PROG_CMD_MAP[${1}]}"
	echo "-> Started Process "

}

function stopOneProg
{
	echo test
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
	exit
fi

if [[ ${1} == "start" ]]; then
	startAllProg

elif [[ ${1} == "stop" ]]; then
	stopAllProg

elif [ ${PROG_CMD_MAP[${1}]+_} ]; then 
	echo "Found ${1}";
else
	echo "Error: Invalid command"
fi