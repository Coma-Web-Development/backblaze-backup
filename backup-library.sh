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
    while [ $tries_num -ne 0 ]
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
  for vestacp_account in $vestacp_accounts
  do
    backup_file_path=$(/usr/local/vesta/bin/v-backup-user admin | egrep Local | awk '{print $4}')
    selectS3ServiceAndSend $backup_file_path
  done
}

# create and send hestiacp backup
createAndSendHestiacpBackup()
{
  for hestiacp_account in $hestiacp_accounts
  do
    backup_file_path=$(/usr/local/hestia/bin/v-backup-user admin | egrep Local | awk '{print $4}')
    selectS3ServiceAndSend $backup_file_path
  done
}

# create and send cyberpanel backup
createAndSendCyberpanelBackup()
{
  for cyberpanel_website in $cyberpanel_websites
  do
    # TODO fix where is the file and the file name
    /usr/bin/cyberpanel createBackup --domainName $cyberpanel_website &> /dev/null
    backup_file_path=$(ls -hrt /home/${cyberpanel_website}/backup/*.tar.gz | tail -n 1)
    selectS3ServiceAndSend $backup_file_path
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
  cyberpanel_websites=$(/usr/bin/cyberpanel listWebsitesJson | jq -r 'fromjson[] | .domain')
}

getActiveUsersCyberpanel()
{
  cyberpanel_websites=$(/usr/bin/cyberpanel listWebsitesJson | jq -r 'fromjson[] | select(.state=="Active") | .domain')
}

hestiacpBackup()
{
  # check if there is a hestia script
  if [ -f /usr/local/hestia/bin/v-list-users ]
  then
    # get all users to create the backup
    if echo $backup_accounts_status | egrep -iq "^active$"
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
    if echo $backup_accounts_status | egrep -iq "^active$"
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
    if echo $backup_accounts_status | egrep -iq "^active$"
    then    
      getActiveUsersCyberpanel
    else
      getAllUsersCyberpanel
    fi
  else
    log ERROR "Not seems to be a cyberpanel server. Aborting with return code >>> 6 <<<."
    exit 6
  fi

  # create backup and send to s3
  createAndSendCyberpanelBackup
}

findFilesAndUploadToS3()
{
  # TODO
  exit 0
}

directoriesBackup()
{
  for backup_dir_path in $backup_type
  do
    # save the directory structure
    backup_dir_path_without_slash=$(echo $backup_dir_path | sed 's#\/#_#g')
    directory_structure_file=$(mktemp /tmp/XXXXXX_directory_structure_${backup_dir_path_without_slash})
    find $backup_dir_path "*${backup_files_extension}" > $directory_structure_file
    selectS3ServiceAndSend $directory_structure_file
    rm -f $directory_structure_file 
    
    # upload all files
    findFilesAndUploadToS3 $backup_dir_path
  done
}

testBackupDefaultDir()
{
  if [[ "$backup_dir" == "default" ]]
  then
    if [ ! -d /backup ]
    then
      mkdir /backup
      chmod 750 /backup
    fi
      backup_dir=/backup
  else
    if [ ! -d $backup_dir ]
    then
      log ERROR "The provided directory to create temp files >>> $backup_dir <<< does not exist. Aborting with return code error >>> 7 <<<."
    fi
  fi
}

main()
{
  testRootPermission
  testBackupDefaultDir
 
  # go to the provided dir to create temp files, if they are needed 
  cd $backup_dir

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
