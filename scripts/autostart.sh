#!/bin/bash
logfile="${1}"
mountpoint="${2}"
# Path and file name
#  - ${mountpoint}/autostart.sh - coded in utf-8

#                Autostart for external usb devices
#
#                  Developed by tommes (toafez)
#              MIT License https://mit-license.org/
#        Member of the German UGREEN Forum - DACH Community
#
#        This script was developed specifically for use on 
#                UGREEN-NAS systems that use the
#                   operating system UGOS Pro.


#---------------------------------------------------------------------
#                   !!! USER INPUT !!!
#---------------------------------------------------------------------

# Target directory
#---------------------------------------------------------------------
# Syntax pattern: target="/[VOLUME]/[SHARE]/[FOLDER]"
#---------------------------------------------------------------------
# The path to the target directory must always be preceded by the variable
# ${mountpoint} must always be prefixed. Further subdirectories are
# are possible. If the target directory does not exist, it is created during the
# first data backup. Invalid characters in file and
# directory names are ~ “ # % & * : < > ? / \ { | }
#---------------------------------------------------------------------
target="${mountpoint}/"

# Data backup source(s)
#---------------------------------------------------------------------
# Syntax pattern: sources="/[SHARE1]/[FOLDER1] & /[SHARE2]/[FOLDER2]”
#---------------------------------------------------------------------
# The complete path to the source directory must be specified.
# If more than one source directory is specified, the paths must be
# must be separated by the & symbol, e.g.
# “/volume1/photo & /volume1/music/compilation & /volume1/video/series”
# Invalid characters in file and directory names are
# ~ " # % & * : < > ? / \ { | }
#---------------------------------------------------------------------
sources=""

# Delete contents of the recycle bin /@recycle that are older than...
#---------------------------------------------------------------------
# Syntax pattern: recycle=“false”, “30” (default selection) or “true”
#---------------------------------------------------------------------
# If the value “false” is specified for recycle=, all data that has been
# data from the backup source(s) that has been deleted in the meantime will also be
# irrevocably deleted in the backup destination. If for recycle= a
# numeric value of at least 1 is specified for recycle=, then
# data from the backup source(s) that has # been deleted in the meantime will be stored in the
# specified time in days is moved to the recycle bin under /@recycle of the
# destination folder before they are irrevocably deleted.
# If the value “true” is specified for recycle=, then
# data from the backup source(s) that has been deleted in the meantime is always moved to
# moved to the recycle bin under /@recycle of the destination folder without being # deleted in the future.
# they will be deleted in the future.
#---------------------------------------------------------------------
recycle="30"

# rsync Optionen
#---------------------------------------------------------------------
# Syntax pattern: syncopt="-ah" (Default selection)
#---------------------------------------------------------------------
syncopt="-ah --info=progress2"

# Exclude files and directories
#---------------------------------------------------------------------
# Syntax pattern: exclude="--delete-excluded --exclude=[FILE-OR-DIRECTORY]”
#---------------------------------------------------------------------
exclude="--delete-excluded --exclude=@eaDir/*** --exclude=@Logfiles/*** --exclude=#recycle/*** --exclude=#snapshot/*** --exclude=.DS_Store/***"


#---------------------------------------------------------------------
#       !!! FROM HERE ON PLEASE DO NOT CHANGE ANYTHING !!!
#---------------------------------------------------------------------

# --------------------------------------------------------------
#  Set environment variables
# --------------------------------------------------------------

	# Securing the Internal Field Separator (IFS) as well as the separation
	if [ -z "${backupIFS}" ]; then
		backupIFS="${IFS}"
		readonly backupIFS
	fi

	# Set timestamp
	timestamp() {
		date +"%Y-%m-%d %H:%M:%S"
	}

	# Set the current date and time
	datetime=$(date "+%Y-%m-%d_%Hh-%Mm-%Ss")

	# Reset exit code
	exit_code=

# --------------------------------------------------------------
# Create target folder on the external device
# --------------------------------------------------------------

	# Make sure that the target path ends with a slash
	if [[ "${target:${#target}-1:1}" != "/" ]]; then
		target="${target}/"
	fi

	# Create target path
	if [ ! -d "${target}" ]; then
		mkdir -p "${target}"
		exit_mkdir=${?}
	fi

	# If the target folder could not be created
	if [[ "${exit_mkdir}" -ne 0 ]]; then
		echo "# $(timestamp) Start synchronous rsync data backup to an external storage medium..." | tee -a "${logfile}"
		echo " - Warning: The target folder could not be created." | tee -a "${logfile}"
		exit_code=1
	else
		echo "# $(timestamp) Start synchronous rsync data backup to an external storage medium..." | tee -a "${logfile}"
		exit_code=0

	fi

# --------------------------------------------------------------
# Configure @recycle bin
# --------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then
	# If the number of days in the recycle bin is a number and not 0 or true, create a restore point.
	is_number="^[0-9]+$"
	if [ -n "${recycle}" ] && [[ "${recycle}" -ne 0 ]] && [[ "${recycle}" =~ ${is_number} ]]; then
		backup="--backup --backup-dir=@recycle/${datetime}"
	elif [ -n "${recycle}" ] && [[ "${recycle}" == "true" ]]; then
		backup="--backup --backup-dir=@recycle/${datetime}"
	fi
fi

# --------------------------------------------------------------
# Configure ionice
# --------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then
	# If the ionice program is installed, use it, otherwise use the rsync bandwidth limitation
	if command -v ionice 2>&1 >/dev/null; then
		echo " - The [ ionice ] program optimizes the read and write speed of the rsync process" | tee -a "${logfile}"
		echo "   to ensure the availability of the system during the data backup!" | tee -a "${logfile}"
		ionice="ionice -c 3"
	fi
fi

# --------------------------------------------------------------
# Read in the sources and pass them to the rsync script
# --------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then
	IFS='&'
	read -r -a all_sources <<< "${sources}"
	IFS="${backupIFS}"
	for source in "${all_sources[@]}"; do
		source=$(echo "${source}" | sed 's/^[ \t]*//;s/[ \t]*$//')

		# ------------------------------------------------------
		# Beginn rsync loop
		# ------------------------------------------------------
		echo "" | tee -a "${logfile}"
		echo "# $(timestamp) Schreibe rsync-Protokoll..." | tee -a "${logfile}"
		echo " - Source directory: ${source}" | tee -a "${logfile}"
		echo " - Target directory: ${target}${source##*/}" | tee -a "${logfile}"
		${ionice} \
		rsync \
		${syncopt} \
		--stats \
		--delete \
		${backup} \
		${exclude} \
		"${source}" "${target}" > >(tee -a "${logfile}") 2>&1
		rsync_exit_code=${?}

		# ------------------------------------------------------
		# rsync error analysis after rsync run...
		# ------------------------------------------------------
		if [[ "${rsync_exit_code}" -ne 0 ]]; then
			echo "" | tee -a "${logfile}"
			echo "Warning: Rsync reports error code ${rsync_exit_code}!" | tee -a "${logfile}"
			echo " - Check the log for more information." | tee -a "${logfile}"
			echo "" | tee -a "${logfile}"
			exit_code=1
		else
			exit_code=0
		fi
	done
	echo "" | tee -a "${logfile}"
	echo "# $(timestamp) The task is being completed..." | tee -a "${logfile}"
fi

# --------------------------------------------------------------
# Rotation cycle for deleting /@recycle
# --------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then
	if [ -n "${recycle}" ] && [[ "${recycle}" -ne 0 ]] && [[ "${recycle}" =~ ${is_number} ]]; then
		echo " - Data from the backup source(s) that has been deleted in the meantime is saved in the" | tee -a "${logfile}"
		echo "   folder /@recycle, from the backup target shifted." | tee -a "${logfile}"
		if [ -d "${target%/*}/@recycle" ]; then
			find "${target%/*}/@recycle/"* -maxdepth 0 -type d -mtime +${recycle} -print0 | xargs -0 rm -r 2>/dev/null
			if [[ ${?} -eq 0 ]]; then
				echo " - Data from the /@recycle folder that was older than ${recycle} days have been deleted." | tee -a "${logfile}"
			fi
		fi
	fi
fi

# ------------------------------------------------------------------------
# Notification of success or failure and exit script
# ------------------------------------------------------------------------
if [[ "${exit_code}" -eq 0 ]]; then
	# Notification that the backup job was successfully executed
	echo " - The backup job was executed successfully." | tee -a "${logfile}"
	exit 0
else
	# Notification that the backup job contained errors
	echo " - Warning: The backup job failed or was canceled." | tee -a "${logfile}"
	exit 1
fi
