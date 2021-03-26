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
sendToBackblazeS3Service()
{
  for backup_file in $@
  do
    tries_num=3
    while [ $tries -ne 0 ]
    do
      /usr/bin/backblaze upload_file $backup_bucket_name ${backup_file} $(basename "${backup_file%.*}")
      backblaze_return=$?

      if [[ $backblaze_return -eq 0 ]]
      then
        tries_num=0
        if [[ "$backup_remove" == "yesRemoveAfterSent" ]]
        then
          removeFiles $backup_file
        fi
      else
        log ERROR "Failed to upload the file >>> ${backup_file} <<< with return code >>> $backblaze_return <<<. Attempt number >>> $tries_num <<<."
        tries_num=$(($tries_num-1))
      fi
    done

    if [ $tries_num -eq 0 ] && [ $backblaze_return -ne 0 ]
    then
      log ERROR "Failed to upload the file >>> ${backup_file} <<< with return code >>> $backblaze_return <<<. No more attempts will be done."
    fi
  done
}

# general function to send the backup based on service
selectS3ServiceAndSend()
{
  file_to_be_sent=$1
  case $backup_service_name in
    backblaze)
      sendToBackblazeS3Service $file_to_be_sent
    ;;
  esac
}

# create and send vestacp backup
createAndSendVestacpBackup()
{
  #TODO create backup and send the file absolut path
}

# create and send hestiacp backup
createAndSendHestiacpBackup()
{
  #TODO create backup and send the file absolut path
}

# create and send cyberpanel backup
createAndSendCyberpanelBackup()
{
  #TODO create backup and send the file absolut path
}


# find backup files
findBackupFiles()
{
  for backup_local_dir in $backup_type
  do
    find $backup_local_dir -type f -iname "*${backup_files_extension}" -exec bash -c 'sendToBackblazeS3Service "$1"' _ {} \;
  done
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
  # check if there is a hestia script
  if [ -f /usr/local/hestia/bin/v-list-users ]
  then
    # get all users to create the backup
    if cat $backup_accounts_status | egrep -iq "^active$"
    then
      getActiveUsersHestiacp
    else
      getAllUsersHestiacp
    fi
  else
    log ERROR "Not seems to be a hestiacp server. Aborting with return code >>> 4 <<<."
    exit 4
  fi

  # create backup and send to s3
  createAndSendHestiacpBackup
}

vestacpBackup()
{
  # check if there is a vesta script
  if [ -f /usr/local/vesta/bin/v-list-users ]
  then
    # get all users to create the backup
    if cat $backup_accounts_status | egrep -iq "^active$"
    then    
      getActiveUsersVestacp
    else
      getAllUsersVestacp
    fi
  else
    log ERROR "Not seems to be a vestacp server. Aborting with return code >>> 5 <<<."
    exit 5
  fi

  # create backup and send to s3
  createAndSendVestacpBackup
}

cyberpanelBackup()
{
  # check if there is a cyberpanel script
  if [ -f /usr/bin/cyberpanel ]
  then
    # get all users to create the backup
    if cat $backup_accounts_status | egrep -iq "^active$"
    then    
      getActiveUsersVestacp
    else
      getAllUsersVestacp
    fi
  else
    log ERROR "Not seems to be a cyberpanel server. Aborting with return code >>> 6 <<<."
    exit 6
  fi

  # create backup and send to s3
  createAndSendCyberpanelBackup
}

directoriesBackup()
{
  # TODO
}

testBackupDefaultDir()
{
  if [[ "$backup_dir" == "default" ]]
  then
    if [ ! -d /backup ]
    then
      mkdir /backup
      chmod 750 /backup
      backup_dir=/backup
    fi
  fi
}

main()
{
  testRootPermission
  testBackupDefaultDir
  export -f selectS3ServiceAndSend

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
