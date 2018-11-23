#!/bin/sh

# Copyright 2018 K. Langenberg. All rights reserved.
# Use of this source code is governed by a GPLv3-style
# license that can be found in the LICENSE file.

#########################
# Environment variables #
#########################

# Backup folder
if [ -n $DB_BACKUP_FOLDER ]
then
	backup_folder=$DB_BACKUP_FOLDER
fi

# Backup hosts file
if [ -n $DB_BACKUP_HOSTS_FILE ]
then
	backup_hosts_location=$DB_BACKUP_HOSTS_FILE
fi

# Max backups to keep
if [ -n $DB_BACKUP_MAX ]
then
	max_backups=$DB_BACKUP_MAX
fi

########
# Passed options, any passed option will overwrite a previously set environment variable
########

while getopts ":b:c:d:h" opt; do
  case $opt in
    b)
      backup_folder=$OPTARG
      ;;
    c)
      backup_hosts_location=$OPTARG
      ;;
    d)
      max_backups=$OPTARG
      ;;
    h)
      echo "Available Options:
-b: Folder where to store the backups. Defaults to \$PWD/backups.
-c: Location of the config.json file which holds all hosts you want to backup. Defaults to \$PWD/backup_hosts.json.
-d: Maximum number of backups to keep. Defaults to 24.
-h: Print this help message.

Environment Variables:
- DB_BACKUP_FOLDER: Where to store the backups.
- DB_BACKUP_HOSTS_FILE: Location of the config.json file which holds all hosts you want to backup.
- DB_BACKUP_MAX: Maximum number of backups to keep. Defaults to 24.
 
Copyright 2018 K. Langenberg. All rights reserved.
Use of this source code is governed by a GPLv3-style
license that can be found in the LICENSE file."
	  exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG. Use -h to print all available options." >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument. Use -h to print all available options." >&2
      exit 1
      ;;
  esac
done

############
# Defaults #
############

# Backup configuration file
if [ -z $backup_hosts_location ]
then 
	backup_hosts_location=$PWD/backup_hosts.json
fi

# Backup folder
if [ -z $backup_folder ]
then
	backup_folder=$PWD/backups
fi

# Max number of backups to keep
if [ -z $max_backups ]
then
	max_backups=24
fi

# Save the date
date=`date +%d\-%m\-%Y\_%H\-%M\-%S`

###############
# File Checks #
###############

# Check if the backup folder exists
if [ ! -d $backup_folder ]; then
	echo "Backup folder does not exist, trying to create it..."
	mkdir -p $backup_folder

	if [ ! $? -eq 0 ]; then
		echo "Could not create Backup folder. Please make sure you have sufficent rights to create $backup_folder"
		exit 1
	fi
	echo "-------------------------------"
fi

# Check if the config file exists
if [ ! -f $backup_hosts_location ]; then
	echo "Config file $backup_hosts_location does not exist."
	exit 1
fi

# Load Config
backup_hosts_file=$(cat $backup_hosts_location)

######################
# Delete old backups #
######################

if [ -n "${max_backups}" ] && [ "$(ls -A $backup_folder)" ]; then
	deleted=false

	# While there are > $max_backups, delete every old backup
    while [ $(ls $backup_folder -1 | wc -l) -gt $max_backups ]; do
	    BACKUP_TO_BE_DELETED=$(ls $backup_folder -1tr | head -n 1)
        echo "Deleted old backup $BACKUP_TO_BE_DELETED"
        rm -rf $backup_folder/$BACKUP_TO_BE_DELETED

		deleted=true
    done

	if $deleted ; then
		echo "--------------------------------------"
	fi
fi

####################
# Start the backup #
####################

# Create new Backup folder
mkdir $backup_folder/"$date" -p

# Print start time
echo "Started Backup at `date`"
echo "----------------------------------------------"

# Loop through all backupfolders and convert them
for row in $(echo "${backup_hosts_file}" | jq -r '.[] | @base64'); do  
	_jq() {
		echo ${row} | base64 -d | jq -r ${1}
	}

	# Check if we have a host, use localhost if not
	db_host=localhost
	if [ "$(_jq '.host')" != "null" ]
		then
			db_host=$(_jq '.host')
	fi

	# Check for a user, set to root if none exists
    db_user=root
	if [ "$(_jq '.user')" != "null" ]
		then
			db_user=$(_jq '.user')
	fi

	# Check for a user password, set to empty if none exists
	db_pw=
	if [ "$(_jq '.password')" != "null" ]
		then
			db_pw=$(_jq '.password')
	fi

	# Check for a database port, set to 3306 if none exists
	db_port=3306
	if [ "$(_jq '.port')" != "null" ]
		then
			db_port=$(_jq '.port')
	fi

	# Do the backup
	echo "Backing up $db_host"
	mysqldump --all-databases -u ${db_user} -p${db_pw} -h ${db_host} --port ${db_port} –-lock-tables=0  > $backup_folder/"$date"/${db_host}_all-databases.sql
	if [ $? -eq 0 ]; then			
		echo "Success."
	else
		echo "Error."

		# Delete the file if the backup was not successfull
		rm $backup_folder/"$date"/${db_host}_all-databases.sql -f
	fi
    echo "-------------------------"

done

# Print end time
echo "Finished Backup at `date`"
echo "-----------------------------------------------"
