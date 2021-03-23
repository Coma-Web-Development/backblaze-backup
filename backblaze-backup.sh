#1/bin/bash

# functions

# remove files
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

main()
{
  
  exit 0
}

# global vars
backup_type=1
