#!/bin/bash

source /usr/lib/backup-library.sh

# global vars
log_file=/var/log/backup-backblaze.log
log_hash=$(date +%s | sha256sum | base64 | head -c 16)
parameters_count=$#
parameters_count_expected=
backup_type=$1
backup_remove=
backup_dir=
backup_files_extension=
backup_file=
backup_files_list=
backup_directory=
backup_directories_list=
backup_accounts_status=
backup_bucket_name=
hestiacp_accounts=
vestacp_accounts=
cyberpanel_websites=

# process the vars
case $backup_type in
  1)
    parameters_count_expected=6
    logInvalidParametersNumber
    backup_service_name=$2
    backup_bucket_name=$3
    backup_remove=$4
    backup_accounts_status=$5
    backup_service_name=$6
    cyberpanelBackup
  ;;

  2)
    parameters_count_expected=7
    logInvalidParametersNumber
    backup_service_name=$2
    backup_bucket_name=$3
    backup_remove=$4
    backup_accounts_status=$5
    backup_service_name=$6
    backup_dir=$7
    vestacpBackup
  ;;

  3)
    parameters_count_expected=7
    logInvalidParametersNumber
    backup_service_name=$2
    backup_bucket_name=$3
    backup_remove=$4
    backup_accounts_status=$5
    backup_service_name=$6
    backup_dir=$7
    hestiacpBackup
  ;;

  4)
    parameters_count_expected=7
    logInvalidParametersNumber
    backup_service_name=$2
    backup_bucket_name=$3
    backup_remove=$4
    backup_accounts_status=$5
    backup_service_name=$6
    backup_dir=$7
    cpanelBackup
  ;;

  5)
    parameters_count_expected=4
    logInvalidParametersNumber
    backup_service_name=$2
    backup_bucket_name=$3
    backup_file=$4
    fileBackup
  ;;

  6)
    backup_service_name=$2
    backup_bucket_name=$3
    shift 3
    backup_files_list=$@
    filesBackup
  ;;

  7)
    parameters_count_expected=4
    logInvalidParametersNumber
    backup_service_name=$2
    backup_bucket_name=$3
    backup_directory=$4
    directoryBackup
  ;;

  8)
    backup_service_name=$2
    backup_bucket_name=$3
    shift 3
    backup_directories_list=$@
    directoriesBackup
  ;;

  9)
    parameters_count_expected=4
    logInvalidParametersNumber
    backup_service_name=$2
    backup_bucket_name=$2
    backup_directory=$3
    directoryBackupCompressed
  ;;

  10)
    backup_service_name=$2
    backup_bucket_name=$3
    shift 3
    backup_directories_list=$@
    directoriesBackupCompressed
  ;;

  *)
    log ERROR "The backup code >>> $backup_type << is invalid."
  ;;
esac

if [[ $parameters_count -ne $parameters_count_expected ]]
then
  exit 2
fi

main

# unknown error
log ERROR "Unknown error. Aborting with code >>> 255 <<<."
exit 255
