#1/bin/bash

# functions

# remove files
log()
{
  log_type=$1
  shift 1
  log_date=$(date -R)
  echo "|$log_type|$log_date|$log_hash|$@" >> $log_file
}

removeFiles()
{
  rm -f $@
}

# send files to blackbaze s3 service
sendToBackBlazeS3Service()
{
  for backup_file in $@
  do
    tries_num=3
    while [ $tries -ne 0 ]
    do
      /usr/bin/backblaze upload_file $bucket_name ${backup_file} $(basename "${backup_file%.*}")
      backblaze_return=$?

      if [[ $backblaze_return -eq 0 ]]
      then
        tries_num=0
        if [[ "$backup_remove" == "yesRemoveAfterSent" ]]
        then
          removeFiles $backup_file
        fi
      else
        tries_num=$(($tries_num-1))
      fi
    done
  done
}

# find backup files
findBackupFiles()
{
  # TO DO
}

testRootPermission()
{
  if ((${EUID:-0} || "$(id -u)"))
  then
    log ERROR "backblaze-backup not executed with root permiission. Aborting with return code >>> 1 <<<."
    exit 1
  fi
}

getAllUsersVestacp()
{
  vestacp_accounts=$(/usr/local/vesta/bin/v-list-users | tail -n +3 | awk '{print $1}')
}

getActiveUsersVestacp()
{
  vestacp_accounts=$(/usr/local/vesta/bin/v-list-users | tail -n +3 | egrep -i "[a-zA-Z0-9]+[ ]+[a-zA-Z0-9]+[ ]+[0-9]+[ ]+[0-9]+[ ]+[0-9]+[ ]+[0-9]+[ ]+[0-9]+[ ]+[0-9]+[ ]+no[ ]+[0-9]+-[0-9]+-[0-9]+" | awk '{print $1}')
}

getAllUsersHestiacp()
{
  hestiacp_accounts=$(/usr/local/hestia/bin/v-list-users | tail -n +3 | awk '{print $1}')
}

getActiveUsersHestiacp()
{
  hestiacp_accounts=$(/usr/local/hestia/bin/v-list-users | tail -n +3 | egrep -i "[a-zA-Z0-9]+[ ]+[a-zA-Z0-9]+[ ]+[0-9]+[ ]+[0-9]+[ ]+[0-9]+[ ]+[0-9]+[ ]+[0-9]+[ ]+[0-9]+[ ]+no[ ]+[0-9]+-[0-9]+-[0-9]+" | awk '{print $1}')
}


getAllUsersCyberpanel()
{
  cyberpanel_accounts=$(/usr/bin/cyberpanel listWebsitesJson | jq -r 'fromjson[] | .admin')
}

getActiveUsersCyberpanel()
{
  cyberpanel_accounts=$(/usr/bin/cyberpanel listWebsitesJson | jq -r 'fromjson[] | select(.state=="Active") | .admin')
}



hestiacpBackup()
{
    # TO DO
}

vestacpBackup()
{
  # TO DO
}

cyberpanelBackup()
{
  # TO DO
}

directoriesBackup()
{
  # TO DO
}

main()
{
  testRootPermission

  case $backup_type in
    hestiacp)
      hestiacpBackup
      ;;
    vestacp)
      vestacpBackup
      ;;
    cyberpanel)
      cyberpanelBackup
      ;;
    *)
        # test if all directories are valid
        for dir_test in $backup_type
        do
          if [ ! -d $dir_test ]
          then
            log ERROR "Directory or directories given: >>> $backup_type <<<. The directory >>> $dir_test <<< is not valid. Aborting with return code >>> 3 <<<."
            exit 3
          fi
        done

        # if they are valid, continue
        directoriesBackup
      ;;
  esac

  exit 0
}

# global vars
log_file=/var/log/backblaze-backup.log
log_hash=\$(date +%s | sha256sum | base64 | head -c 16)
parameters_count=$#
parameters_count_expected=6
backup_type=$1
backup_remove=$2
backup_dir=$3
backup_files_extension=$4
backup_accounts_status=$5
backblaze_bucket_name=$6
hestiacp_accounts=
vestacp_accounts=
cyberpanel_accounts=

# test parameters number
if [[ $parameters_count -ne $parameters_count_expected ]]
then
  log ERROR "Parameters number expected is >>> $parameters_count_expected <<< but >>> $parameters_count <<< were given instead. Aborting with return code >>> 2 <<<."
  exit 2
fi

main

# unknown error
exit 255
