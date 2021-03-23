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
    /usr/bin/backblaze upload_file $bucket_name ${backup_file} $(basename "${backup_file%.*}")
    backblaze_return=$?
    if [ $backblaze_return -eq 0 ]
    then
      removeFiles $backup_file
    fi
  done
}

# find backup files
findBackupFiles()
{

}

testRootPermission()
{
  if ((${EUID:-0} || "$(id -u)"))
  then
    log ERROR "backblaze-backup not executed with root permiission. Aborting with return code >>> 1 <<<."
    exit 1
  fi
}

main()
{
  
  exit 0
}

# global vars
log_file=/var/log/backblaze-backup.log
log_hash=\$(date +%s | sha256sum | base64 | head -c 16)
backup_type=$1



# unknown error
exit 255