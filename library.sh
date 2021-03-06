#1/bin/bash

# functions

# remove files
log()
{
  log_type=$1
  shift 1
  log_date=$(date -R)
  echo "|$log_type|$log_date|$log_hash|$backup_service_name|$@" >> $log_file
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
      /usr/bin/backblaze upload_file $backup_bucket_name ${backup_file} $(basename ${backup_file})
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
      log ERROR "Failed to upload the file >>> ${backup_file} <<< with return code >>> $backblaze_return <<<. No more attempts will be done. The backup file >>> $backup_file <<< will note be removed."
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
    backup_file_path=$(/usr/local/vesta/bin/v-backup-user $vestacp_account | egrep Local | awk '{print $4}')
    
    if [[ "{$backup_file_path}x" == "x" ]]
    then
      log ERROR "The VestaCP backup procedure failed to create the backup to the account >>> $backup_file_path <<<."
    else
      if [ ! -f $backup_file_path ]
      then
        log ERROR "The VestaCP backup procedure of account >>> $vestacp_account <<< failed because the file >>> $backup_file_path <<< is not found."
      else
        # standardize the file name to have file versioning control under s3
        mv $backup_file_path ${backup_dir}/${vestacp_account}.tar
        backup_file_path=${backup_dir}/${vestacp_account}.tar
        selectS3ServiceAndSend $backup_file_path
      fi
    fi
  done
}

# create and send hestiacp backup
createAndSendHestiacpBackup()
{
  for hestiacp_account in $hestiacp_accounts
  do
    backup_file_path=$(/usr/local/hestia/bin/v-backup-user $hestiacp_account | egrep Local | awk '{print $4}')

    if [[ "{$backup_file_path}x" == "x" ]]
    then
      log ERROR "The HestiaCP backup procedure failed to create the backup to the account >>> $backup_file_path <<<."
    else
      if [ ! -f $backup_file_path ]
      then
        log ERROR "The HestiaCP backup procedure of account >>> $hestiacp_account <<< failed because the file >>> $backup_file_path <<< is not found."
      else
        # standardize the file name to have file versioning control under s3
        mv $backup_file_path ${backup_dir}/${hestiacp_account}.tar
        backup_file_path=${backup_dir}/${hestiacp_account}.tar
        selectS3ServiceAndSend $backup_file_path
      fi
    fi
  done
}

# create and send cyberpanel backup
createAndSendCyberpanelBackup()
{
  for cyberpanel_website in $cyberpanel_websites
  do
    /usr/bin/cyberpanel createBackup --domainName $cyberpanel_website &> /dev/null
    backup_file_path=$(ls -hrt /home/${cyberpanel_website}/backup/*.tar.gz | tail -n 1)
    
    if [[ "{$backup_file_path}x" == "x" ]]
    then
      log ERROR "The Cyberpanel backup procedure failed to create the backup to the account >>> $cyberpanel_website <<<."
    else
      if [ ! -f $backup_file_path ]
      then
        log ERROR "The Cyberpanel backup procedure of account >>> $cyberpanel_website <<< failed because the file >>> $backup_file_path <<< is not found."
      else
        # standardize the file name to have file versioning control under s3
        mv $backup_file_path /home/${cyberpanel_website}/backup/${cyberpanel_website}.tar.gz
        backup_file_path=/home/${cyberpanel_website}/backup/${cyberpanel_website}.tar.gz
        selectS3ServiceAndSend $backup_file_path
      fi
    fi
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
  # avoid to use v-list-users due possible environment variables changes
  # using the same method used by v-list-users
  vestacp_possible_accounts=$(cat /etc/passwd | egrep @ | cut -f1 -d:)
  for vesta_user in $vestacp_possible_accounts
  do
    vestacp_accounts="$vesta_user $vestacp_accounts"
  done
}

getActiveUsersVestacp()
{
  # avoid to use v-list-users due possible environment variables changes
  # using the same method used by v-list-users
  vestacp_possible_accounts=$(cat /etc/passwd | egrep @ | cut -f1 -d:)

  for vesta_user in $vestacp_possible_accounts
  do
    if [ -f "/usr/local/vesta/data/users/$vesta_user/user.conf" ]
    then
      if cat /usr/local/vesta/data/users/$vesta_user/user.conf | egrep -qi "^suspended.*\=.*no.*"
      then
        vestacp_accounts="$vesta_user $vestacp_accounts"
      fi
    fi
  done
}

getAllUsersHestiacp()
{
  # avoid to use v-list-users due possible environment variables changes
  # using the same method used by v-list-users
  hestiacp_possible_accounts=$(cat /etc/passwd | egrep @ | cut -f1 -d:)

  for hestia_user in $hestiacp_possible_accounts
  do
    if [ -f "/usr/local/hestia/data/users/$hestia_user/user.conf" ]
    then
      hestiacp_accounts="$hestia_user $hestiacp_accounts"
    fi
  done
}

getActiveUsersHestiacp()
{
  # avoid to use v-list-users due possible environment variables changes
  # using the same method used by v-list-users
  hestiacp_possible_accounts=$(cat /etc/passwd | egrep @ | cut -f1 -d:)

  for hestia_user in $hestiacp_possible_accounts
  do
    if [ -f "/usr/local/hestia/data/users/$hestia_user/user.conf" ]
    then
      if cat /usr/local/hestia/data/users/$hestia_user/user.conf | egrep -qi "^suspended.*\=.*no.*"
      then
        hestiacp_accounts="$hestia_user $hestiacp_accounts"
      fi
    fi
  done
}


getAllUsersCyberpanel()
{
  cyberpanel_websites=$(/usr/bin/cyberpanel listWebsitesJson | jq -r 'fromjson[] | .domain')
}

getActiveUsersCyberpanel()
{
  cyberpanel_websites=$(/usr/bin/cyberpanel listWebsitesJson | jq -r 'fromjson[] | select(.state=="Active") | .domain')
}

cpanelBackup()
{
  # TODO
  exit 0
}

fileBackup()
{
  selectS3ServiceAndSend $backup_file
}

filesBackup()
{
  # TODO
  exit 0
}

directoryBackup()
{
  # TODO
  exit 0
}

directoriesBackup()
{
  # TODO
  exit 0
}

directoryBackupCompressed()
{
  # TODO
  exit 0
}

directoriesBackupCompressed()
{
  # TODO
  exit 0
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
      exit 7
    fi
  fi
}

testBinary()
{
  command -v "$1" >/dev/null 2>&1
}

checkRequiredPackages()
{
  packages_list="jq"
  for package_name in $packages_list
  do
    if ! testBinary $package_name
    then
      echo "Package >>> $package_name <<< not installed. Aborting..."
      exit 1
    fi
  done
}

logInvalidParametersNumber()
{
  if [[ $parameters_count -ne $parameters_count_expected ]]
  then
    log ERROR "Invalid parameters number. Exepected: >>> $parameters_count_expected <<<. Given: >>> $parameters_count <<<. Aborting with return code >>> 1 <<<."
    exit 1
  fi
}

main()
{
  testRootPermission
  checkRequiredPackages
  testBackupDefaultDir
 
  # go to the provided dir to create temp files, if they are needed 
  cd $backup_dir

  # execute the backup procedure
  $backup_procedure_name

  exit 0
}
