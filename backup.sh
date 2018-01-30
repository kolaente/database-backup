#!/bin/bash


# Config
backup_hosts_location=$PWD/backup_hosts.json
backup_hosts_file=$(<$backup_hosts_location)

# Backup folder
backup_folder=$PWD/backups

# Check if the backup folder exists
if [ ! -d $backup_folder ]; then
	echo "Backup folder does not exist, trying to create it..."
	mkdir -p $backup_folder

	if [ ! $? -eq 0 ]; then
		echo "Could not create Backup folder. Please make sure you have sufficent rights to create $backup_folder"
		exit 1
	fi
fi

# Save the date
date=`date +%d\-%m\-%Y\_%H\-%M\-%S`

# Delete backups older than three days
echo "Deleting Backups older than three days..."
find $backup_folder/* -type d -ctime +3 | xargs rm -rf
echo "Deleted."
echo "-------------------------------"

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
