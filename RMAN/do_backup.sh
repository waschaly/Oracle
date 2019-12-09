#!/bin/ksh

# 
# Author:
#		(C) 2009, 2010, 2011, 2012
#		Wolf-Agathon Schalý
#		Gneisenaustrasse 39
# 		41539 Dormagen
#
INSTANCE="TESTDB"
PROGNAME=$(basename $0)
echo $PROGNAME | sed -e 's/do_\(.*\)_\(.*\).sh/\1 \2/g' | read BACKUP_NAME BACKUP_DEVICE

DEBUG="N"
COLDRUN="N"
ERROR=0
RSTAT=0
SETTINGS=$(pwd)/settings

while getopts 'ci:u:d:v' OPTION
do

	case $OPTION in

	c)
		COLDRUN="Y"
		;;
	d)
		BACKUP_DEVICE=${OPTARG}
		;;
	i)
		INSTANCE=${OPTARG}
		;;
	u)
		ORACLE_USER=${OPTARG}
		;;
	v)
		DEBUG="Y"
		;;

	esac

done

if [ ${BACKUP_DEVICE:=N} = "N" ]
then
	echo "Backup device not set or ${PROGNAME} was started direct"
	echo "please consult the README and correct accordingly"
	exit 1
fi

if [ ${DEBUG} = "Y" ]
then
	set -xv
fi

if [ -f ${SETTINGS} ]
then

	. ${SETTINGS}

else 

	ERROR=125;
	echo "couldn't find 'settings' file"
	echo "... or 'settings' file is not readable"
	exit ${ERROR}

fi

function remove_archived_logfiles {

	cd ${RMANLOGS}

	${RM} *.a

}

function mark_as_archived {

	TAR_FILE=backup_*_${CUR_YEAR}${CUR_MONTH}*

	cd ${RMANLOGS}

	for i in `ls $TAR_FILE`
	do
		mv ${i} ${i}.a
	done

}

function tarflags {

	if [ ! -f ${ARCHIVE_FILE} ]
	then
		#
		##
		## existiert noch kein Monatsarchiv 
		## c == create Flag setzen
		##
		#
		TAR_FLAGS="cf"
	else
		#
		##
		## existiert schon ein Monatsarchiv
		## r == appent Flag setzen 
		##
		#
		TAR_FLAGS="rf"
	fi

}


function to_tararch {

	TAR_FILE=backup_*_${CUR_YEAR}${CUR_MONTH}*

	cd ${RMANLOGS}

	if [ -f ${TAR_FILE} ]
	then
		${TAR} ${TAR_FLAGS} ${ARCHIVE_FILE} ${TAR_FILE}
	fi

}


function adrci_housekeeping {

	${ADRCI} script=${ADRCI_SCRIPT} >> ${ADRCI_LOG}

}

function chk_logdir {

	#
	##
	## existiert das Logdirectory: Nein -> kreiere es 
	##
	#

	if [ ! -d ${RMANLOGS} ]
	then
		${MKDIR} ${RMANLOGS}
	fi

}

function chk_archive_dir {
	
	#
	##
	## extiert das ArchivDirectory: Nein -> kreiere es
	##
	#

	if [ ! -d ${ARCHIVE_DIR} ]
	then
		${MKDIR} ${ARCHIVE_DIR}
	fi

}


#
##
## ARDCI Housekeeping
##
#
adrci_housekeeping


#
## 
## Log- und ArchivDirectories 
##
#
chk_logdir
chk_archive_dir


#
## 
## die richtigen TAR-Flags zusammenstellen
##
#
tarflags


remove_archived_logfiles
to_tararch
mark_as_archived





#
##
## run rman command using as parameter a RMAN-Script
##
#

if [ ${LOGNAME} = ${ORACLE_USER} ]
then

	if [ -f ${RMANBASE}/${RMAN_PRE_SCRIPT} ]
	then
		RSTAT=${RSTAT} | ${RMAN} @${RMANBASE}/${RMAN_PRE_SCRIPT} > ${RMANLOGF} 2>&1
	fi

	if [ ${COLDRUN} = "Y" ]
	then
		true
	else
		if [ ${RSTAT} = "0" ]
		then
			RSTAT=${RSTAT} | ${RMAN} @${RMANBASE}/${RMAN_SCRIPT} >> ${RMANLOGF} 2>&1
		fi
	fi

	if [ -f ${RMANBASE}/${RMAN_POST_SCRIPT} ]
	then
		${RMAN} @${RMANBASE}/${RMAN_POST_SCRIPT} >> ${RMANLOGF} 2>&1
	fi

else


	if [ -f ${RMANBASE}/${RMAN_PRE_SCRIPT} ]
	then
		RSTAT=${RSTAT} | su - ${ORACLE_USER} -c "${RMAN} @${RMANBASE}/${RMAN_PRE_SCRIPT}" \
			> ${RMANLOGF} 2>&1
	fi

	
	if [ ${RSTAT} = "0" ]
	then
		RSTAT=${RSTAT} | su - ${ORACLE_USER} -c "${RMAN} @${RMANBASE}/${RMAN_SCRIPT}" \
			>> ${RMANLOGF} 2>&1
	fi

	if [ -f ${RMANBASE}/${RMAN_POST_SCRIPT} ]
	then
		RSTAT=${RSTAT} | su - ${ORACLE_USER} -c "${RMAN} @${RMANBASE}/${RMAN_POST_SCRIPT}" \
			>> ${RMANLOGF} 2>&1
	fi

fi

#
## report the status to the logfile
#
if [ ${RSTAT} = "0" ]
then
	echo backup successful >> ${RMANLOGF}
else
	echo backup failed >> ${RMANLOGF}
fi

exit $RSTAT
