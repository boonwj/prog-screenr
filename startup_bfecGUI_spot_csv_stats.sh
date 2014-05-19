#!/bin/bash
# Script to start, stop and check status of Transcoder program in VoiCER

####################################### CONFIG #########################################
VOICER_AWAS="/Data2/AWAS/voicer.psf"
VOICER_PROJID="01"
VOICER_SYSNAME="VOICER_VB138"
VOICER_ERRORCODE_TD_DEAD="0001"
VOICER_ERRORCODE_SDB_DEAD="0002"
VOICER_ERRORCODE_HARDDISK_LOW="0003"
VOICER_LOGFILE="/root/voicerLog"

HARDDISK_UPPER_BOUND=85
HARDDISK_LOWER_BOUND=75
MAIN_PARTITION="/dev/sda1"

export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/etc/init.d"

SCHEDULER="/var/www/html/web2py/web2py.py -K bfec"
SCHEDULER_DIR="/var/www/html/web2py/"
SCREEN_SCHEDULER="BFEC_GUI_SCHEDULER"

STATS_UPLOADER="/home/nrpe_plugins/stats_parser_v2/standalone_stats_collector.py"
SCREEN_STATS_UPLOADER="STATS_UPLOADER"

CSVPROCESS="/home/BEACON_CSVPROCESS/CSVPostProcess"
SCREEN_CSVPROCESS="CSVPROCESS"

SPOT="./SPOT2 -c "
SPOT_PATH="/home/SPOT"
SPOT_CONF_PATTERN="/tmp/SPOT_config/spot*"
SCREEN_SPOT="SPOT_"

#################################### START PROCESSES ####################################
#arg1: command to start
#arg2: set debug mode

function startProcess
{
	if (($# >= 2)); then
		proc=$(echo "${2}" | cut -d ' ' -f1)	#get the program name without any arguments
		processes=$(pidof -x "${proc}" | wc -w)
		
		if ((processes != 0)); then
			echo "-> Process is already running"
		else	
			echo "-> Starting process..."
			screen -dmS ${1} bash -c "${2}"
			echo "-> Process started"
		fi

	else
		echo "Unable to start process because arguments are not given"
		
	fi
}

function startScheduler
{
	echo "[BFEC Scheduler]"
	cd $SCHEDULER_DIR
	pwd
	startProcess "$SCREEN_SCHEDULER" "${SCHEDULER}"
	proc=$(echo "${SCHEDULER}" | cut -d ' ' -f1)	#get the program name without any arguments
	processes=$(pidof -x "${proc}" | wc -w)
	echo $proc	
	echo $processes	
	cd -
	pwd
}


function startCSVprocess
{
	echo "[CSV Process]"
	startProcess "$SCREEN_CSVPROCESS" "${CSVPROCESS}"
}

function startStatsUploader
{
	echo "[STATS UPLOADER]"
	startProcess "$SCREEN_STATS_UPLOADER" "${STATS_UPLOADER}"
}

function startSpot
{
	echo "[SPOT]"
	spot_conf_files=$(echo "${SPOT_CONF_PATTERN}")
	counter=1
	cd $SPOT_PATH
	for i in $spot_conf_files; do
		testfunc "$SCREEN_SPOT$counter" "$SPOT$i" 5
		counter=$[counter+1]
	done
	cd -
	
}

function testfunc
{
	echo $1
	echo $2
	echo $3
	proc=$(echo "${2}" | cut -d ' ' -f1)
	cd $SPOT_PATH
	pwd
	echo screen -dmS ${1} bash -c "${2}"
	screen -dmS ${1} bash -c "${2}"
}

#################################### STOP PROCESSES ####################################

function stopProcess
{
	if (($# >= 1)); then
		#Check if program has been started.
		proc=$(echo "${1}" | cut -d ' ' -f1) #get the program name without any arguments
		processes=$(pidof -x "${proc}" | wc -w)
		if ((processes == 0)); then
			echo "-> Process is not running"
		else
			echo "-> Stopping process..."
			kill $(pidof -x "${proc}")
			while (( processes > 0 )); do
				processes=$(pidof -x "${proc}" | wc -w)
				sleep 1
			done
			echo "-> Process is stopped"
		fi
	else
		echo "Unable to stop process because process name is not given."
	fi
}

function stopStatsLog
{
	echo "[STATSLOG]"
	stopProcess "${STATSLOG}"
}

function stopStatsUploader
{
	echo "[STATS UPLOADER]"
	stopProcess "${STATS_UPLOADER}"
}

function stopTargeting
{
	echo "[TARGETING]"
	stopProcess "${TARGETING}"
}

function stopAPD
{
	echo "[APD]"
	stopProcess "${APD}"
}
#################################### CHECK STATUS OF PROCESSES##########################

function checkStatus
{
	if (($# >= 1)); then
		#Check if program has been started.
		proc=$(echo "${1}" | cut -d ' ' -f1) #get the program name without any arguments
		processes=$(pidof -x "${proc}" | wc -w)
		if ((processes == 0)); then
			echo "-> ${1}: Process is not running"
		else
			echo "-> ${1}: Process is running"
		fi
	else
		echo "Unable to check status of process because process name is not given."
	fi
}


function statusStatsLog
{
	echo "[STATSLOG]"
	checkStatus "${STATSLOG}"
}

function statusStatsUploader
{
	echo "[STATS UPLOADER]"
	checkStatus "${STATS_UPLOADER}"
}

function statusAPD
{
	echo "[APD]"
	checkStatus "${APD}"
}

function statusTargeting
{
	echo "[TARGETING]"
	checkStatus "${TARGETING}"
}

function getHardDiskUsage
{
	echo $(df -h | grep $MAIN_PARTITION | awk '{print $5}' | cut -d '%' -f1)
}

function getMemoryUsage
{
	total=$( free -m | grep Mem | awk '{print $2}')
	used=$( free -m | grep Mem | awk '{print $3}')
	percent=$(echo $used $total | awk '{ printf("%0.2f",($1/$2)*100) }')
	echo $percent
}

function allStatus
{
	echo
	statusStatsLog

	echo
	statusStatsUploader
	echo
	
	statusTargeting
	echo
	statusAPD
	echo
	
	echo "[TD]"
	echo "--> $(service td status)"
	echo

	echo "[SDB]"
	echo "--> $(service voip-sdb status)"
	echo

	echo "[HARD DISK]"
	echo "--> Hard disk used: $(getHardDiskUsage)%"
	echo

	echo "[MEMORY]"
	echo "--> Memory used: $(getMemoryUsage)%"
	echo
}


#################################### CLEAN MEMORY ####################################
function cleanMemory
{
	if (($(getHardDiskUsage) > $HARDDISK_UPPER_BOUND)); then
		echo Cleaning up memory...
		#delete files older than user-specified days in all folders
		arr=$(echo $MEM_FOLDERS | tr ";" "\n")
		for folder in $arr
		do
			find $folder -type f -mtime +$MEM_REMOVE_DAY_OLD | xargs rm -rf
		done
	
		# Checks if memory used is still above lower bound. 
		# if so, delete files from 1st folder in MEM_FOLDERS until below lower bound	
		firstFolder=$(echo $arr | cut -d ' ' -f1)
		while (($(getHardDiskUsage) > $HARDDISK_LOWER_BOUND)); do
			ls -rt $firstFolder | head -$MEM_FILES_PER_ITERATION | xargs rm -f
			sleep 1
		done 
		echo Clean up completed

	else
		echo Memory usage $(getHardDiskUsage)% is less than upper bound of $HARDDISK_UPPER_BOUND
	fi
}


#################################### AWAS ####################################
function awas
{
	date=$(date +"%Y%m%d %H%M")
	AWAS_MSG=""
	okflag=1

	#Check SDB status
	SDBStatus=$(voip-sdb status | grep -i "stop" | wc -l)

	# Check td status
	TDStatus=$(td status | grep -i "stop" | wc -l)
	
	# If TD is dead, log awas
	if (( $TDStatus == 1 )); then
		
		# If only error, clear the log file first before adding error	
		if (( $okflag == 1 )); then
			echo "" > $VOICER_AWAS
			okflag=0
		fi

#		echo "${VOICER_PROJID}${VOICER_ERRORCODE_TD_DEAD};${VOICER_SYSNAME};${date};"$'\n' >> $VOICER_AWAS	
		echo "${VOICER_PROJID}${VOICER_ERRORCODE_TD_DEAD};${VOICER_SYSNAME};${date};" >> $VOICER_AWAS	

		# log into voicer log file and restart cs
		echo "${date} TD stopped" >> $VOICER_LOGFILE
		cat /var/log/messages | tail -n50 >> $VOICER_LOGFILE

		td start
	fi
	
	#If SDB is dead, log awas
	if (( $SDBStatus == 1 )); then

		# If only error, clear the log file first before adding error	
		if (( $okflag == 1 )); then
			echo "" > $VOICER_AWAS
			okflag=0
		fi

		echo "${VOICER_PROJID}${VOICER_ERRORCODE_SDB_DEAD};${VOICER_SYSNAME};${date};" >> $VOICER_AWAS	

		# log into voicer log file and restart cs
		echo "${date} SDB stopped" >> $VOICER_LOGFILE
		cat /var/log/messages | tail -n50 >> $VOICER_LOGFILE

		voip-sdb start
	fi
	
	if (($(getHardDiskUsage) > $HARDDISK_UPPER_BOUND)); then
		# If only error, clear the log file first before adding error	
		if (( $okflag == 1 )); then
			echo "" > $VOICER_AWAS
			okflag=0
		fi

		echo "${VOICER_PROJID}${VOICER_ERRORCODE_HARDDISK_LOW};${VOICER_SYSNAME};${date};" >> $VOICER_AWAS	
	fi

	if (($okflag == 1)); then
		echo "OK;${VOICER_SYSNAME};${date};"$'\n' > $VOICER_AWAS
	fi
}

#################################### WATCH ####################################
function watchStatsLog
{
	${STATSLOG} watch
}

#################################### MAIN ####################################
if(($# < 1)); then
	echo "Usage: "
	echo "voicer < targeting | statslog | statsUploader | APD> <start | stop > "
	echo "voicer <start | stop | status>" 
	exit
fi

# Need to have space before and after the '==' 
# can have spaces between the if elif statements
if [[ ${1} == "statslog" ]]; then
	if [[ ${2} == "start" ]]; then
		startStatsLog
	elif [[ ${2} == "stop" ]]; then
		stopStatsLog
	elif [[ ${2} == "watch" ]]; then
		watchStatsLog
	else
		echo "Error: Invalid command"
	fi

elif [[ ${1} == "statsUploader" ]]; then
	if [[ ${2} == "start" ]]; then
		startStatsUploader
	elif [[ ${2} == "stop" ]]; then
		stopStatsUploader
	else
		echo "Error: Invalid command"
	fi

elif [[ ${1} == "APD" ]]; then
	if [[ ${2} == "start" ]]; then
		startAPD
	elif [[ ${2} == "stop" ]]; then
		stopAPD
	else
		echo "Error: Invalid command"
	fi

elif [[ ${1} == "spot" ]]; then
	if [[ ${2} == "start" ]]; then
		startSpot
	elif [[ ${2} == "stop" ]]; then
		stopTargeting
	else
		echo "Error: Invalid command"
	fi

elif [[ ${1} == "status" ]]; then
	allStatus
	echo "[THROUGHPUT]"
	tdcli capmyr stats verbose | tail -1
	
elif [[ ${1} == "awas" ]]; then
	awas

elif [[ ${1} == "start" ]]; then
	modprobe myri10ge
	service td start
	service voip-sdb start
	startAPD
	startTargeting
	startStatsLog
	startStatsUploader

elif [[ ${1} == "stop" ]]; then
	stopStatsLog
	stopStatsUploader
	service voip-sdb stop
	service td stop
elif [[ ${1} == "test" ]]; then
	startSpot
else
	echo "Error: Invalid command"
fi