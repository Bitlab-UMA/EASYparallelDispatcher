#!/bin/bash

# PIDs are not re-used until PID_MAX_DEFAULT is reached.

# Reads a text file with commands to execute
if [ $# -lt 1 ]; then
	echo " ==== ERROR ... ====."
	echo ""
	echo "	usage:  $0 <execution file> [max cores]"
	echo ""
	echo "	MANDATORY	<execution file>: a text file containing one command per line"
	echo "	OPTIONAL	[max cores]	: number of cores to use. Default is available cores minus one"
	echo ""
	exit -1
fi

input=$1
cores=$(grep -c ^processor /proc/cpuinfo)
cores=`expr $cores - 1`
current_jobs=0
pidArray=()
jobsArray=()
totalJobs=0
executedJobs=0

if [ $# -eq 2 ]; then
	cores=$2
fi

echo "Using $cores cores"


#initialize
for ((i=0 ; i < $cores ; i++))
do
	pidArray[$i]=-1	
done

# read execution guide and launch jobs
while IFS= read -r var
do

	jobsArray[$totalJobs]=$var
	#echo "${jobsArray[$totalJobs]}"
	totalJobs=`expr $totalJobs + 1`

done < "$input"


# control them and only launch as many as specified
while [[ $executedJobs -lt $totalJobs ]]; do

	# Execute job

	if [[ $current_jobs -lt $cores ]]; then

		${jobsArray[$executedJobs]} &
		pid=$!
		for ((i=0 ; i < $cores ; i++))
		do
			

		        if [[ ${pidArray[$i]} -eq -1 ]]; then
				pidArray[$i]=$pid
				current_jobs=`expr $current_jobs + 1`
				echo "PID: $pid JOBS: $current_jobs LAUNCHING: ${jobsArray[$executedJobs]}"
				executedJobs=`expr $executedJobs + 1`
				break
			fi
		done


	fi

	for ((i=0 ; i < $cores ; i++))
	do
		pid=${pidArray[$i]}
		if [[ $pid -ne -1 ]]; then

			ps -p $pid > /dev/null
			if [[ $? == 1 ]]; then
				current_jobs=`expr $current_jobs - 1`
				echo "PID: $pid its gone!"
				pidArray[$i]=-1
			fi

		fi
	done

	sleep .01

done




#for job in `jobs -p`
#do
	#echo $job
#	wait $job
#done
