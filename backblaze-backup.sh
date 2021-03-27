#!/bin/bash

source /usr/lib/backup-library.sh

# global vars
log_file=/var/log/backup-backblaze.log
log_hash=$(date +%s | sha256sum | base64 | head -c 16)
parameters_count=$#
parameters_count_expected=6
backup_type=$1
backup_remove=$2
backup_dir=$3
backup_files_extension=$4
backup_accounts_status=$5
backup_bucket_name=$6
backup_service_name=backblaze
hestiacp_accounts=
vestacp_accounts=
cyberpanel_websites=

# test parameters number
if [[ $parameters_count -ne $parameters_count_expected ]]
then
  log ERROR "Parameters number expected is >>> $parameters_count_expected <<< but >>> $parameters_count <<< were given instead. Aborting with return code >>> 2 <<<."
  exit 2
fi

main

# unknown error
log ERROR "Unknown error. Aborting with code >>> 255 <<<."
exit 255
