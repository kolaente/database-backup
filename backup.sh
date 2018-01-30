#!/bin/bash

# Copyright 2018 K. Langenberg. All rights reserved.
# Use of this source code is governed by a GPLv3-style
# license that can be found in the LICENSE file.

#########################
# Environment variables #
#########################

# TODO


########
# Passed options, any passed option will overwrite a previously set environment variable
########

while getopts ":b:c:h" opt; do
  case $opt in
    b)
      backup_folder=$OPTARG
      ;;
    c)
      backup_hosts_location=$OPTARG
      ;;
    h)
      echo "AVAILABLE OPTIONS: 

-b: Folder where to store the backups.
-c: Location of the config.json file which holds all hosts you want to backup.
-h: Print this help message.

 
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

# Load Config
backup_hosts_file=$(<$backup_hosts_location)



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
# TODO

# Save the date
date=`date +%d\-%m\-%Y\_%H\-%M\-%S`

# Delete backups older than three days if there are any
if [ "$(ls -A $backup_folder)" ]; then
	echo "Deleting Backups older than three days..."
	find $backup_folder/* -type d -ctime +3 | xargs rm -rf
	echo "Deleted."
	echo "-------------------------------"
fi

# Create new Backup folder
mkdir $backup_folder/"$date" -p

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
	mysqldump --all-databases -u ${db_user} -p${db_pw} -h ${db_host} --port ${db_port}  > $backup_folder/"$date"/${db_host}_all-databases.sql
	if [ $? -eq 0 ]; then			
		echo "Success."
	else
		echo "Error."

		# Delete the file if the backup was not successfull
		rm $backup_folder/"$date"/${db_host}_all-databases.sql -f
	fi
    echo "------------------"

done
