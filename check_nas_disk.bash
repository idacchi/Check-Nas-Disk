#!/bin/bash

######################################################################
# check_nas_disk.bash
#
# This is Nagios plugin which check NAS usage.(%) 
######################################################################

######################################################################
# Nagios status code
######################################################################
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

######################################################################
# default values
######################################################################
USAGE_WARN=50
USAGE_CRITICAL=80
NFS_HOST=192.168.1.1
NFS_DIRECTORY=/usr/local/pub
MOUNT_POINT=/var/mountpoint

######################################################################
# show help
######################################################################
function show_usage(){
	CMDNAME=`basename $0`
	echo "Usage: $CMDNAME [-w WARNING VALUE] [-c CRITICAL VALUE] [-H nfs server host] [-d nfs server directory] [-m mount point]" 1>&2
}

######################################################################
# analize command line options
######################################################################
while getopts hw:c:H:d:m: OPT
do
	case $OPT in
		"h" ) # show help
			show_usage
			exit 0
			;;

		"w" ) # Warning value
			USAGE_WARN="$OPTARG"
			;;

		"c" ) # Critical value
			USAGE_CRITICAL="$OPTARG"
			;;

		"H" ) # nfs server host (server:/usr/local/pub) <server>
			NFS_HOST="$OPTARG"
			;;

		"d" ) # nfs server directory (server:/usr/local/pub) </usr/local/pub>
			NFS_DIRECTORY="$OPTARG"
			;;

		"m" ) # mount point
			MOUNT_POINT="$OPTARG"
			;;

		 *  ) 
			show_usage;
			exit 1
			;;
	esac
done

#echo $USAGE_WARN	# debug
#echo $USAGE_CRITICAL	# debug
#echo $NFS_HOST		# debug
#echo $NFS_DIRECTORY	# debug
#echo $MOUNT_POINT	# debug

######################################################################
# mount NAS and check disk usage
######################################################################
# mount
#echo "mount -t nfs $NFS_HOST:$NFS_DIRECTORY $MOUNT_POINT 1> /dev/null 2> /dev/null" # debug
mount -t nfs $NFS_HOST:$NFS_DIRECTORY $MOUNT_POINT 1> /dev/null 2> /dev/null
mount_result=$?

# mount success
if [ $mount_result -eq 0 ]
then
	
	# check disk usage (%)
	disk_usage_str=`df -h $MOUNT_POINT 2> /dev/null | awk '{print $4}' | grep -G [0-9]`
	df_result=$?

	# unmount
	umount $MOUNT_POINT

	# check df succeed?
	if [ $df_result -ne 0 ]
	then
		echo "NAS WARNING - Maybe wrong mount point."
		exit $WARNING

	elif [ -z "$disk_usage_str" ]
	then
		echo "NAS WARNING - Maybe wrong mount point."
		exit $WARNING
	fi

	# get integer value disk_usage
	disk_usage=${disk_usage_str%%%} # omit %
	
	# OK ($disk_usage < $USAGE_WARN)
	if [ $disk_usage -lt $USAGE_WARN ]
	then
		echo "NAS OK - usage $disk_usage_str"
		exit $OK

	# WARNING ($disk_usage > $USAGE_WARN AND $disk_usage < $USAGE_CRITICAL)
	elif [ $disk_usage -lt $USAGE_CRITICAL ]
	then
		echo "NAS WARNING - usage $disk_usage_str"
		exit $WARNING

	# CRITICAL ($disk_usage > $USAGE_CRITICAL)
	else
		echo "NAS CRITICAL - usage $disk_usage_str"
		exit $CRITICAL
	fi

# mount failure
else
	echo "NAS WARNING - mount failure"
	exit $WARNING
fi
