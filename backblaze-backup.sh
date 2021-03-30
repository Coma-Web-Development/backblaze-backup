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
backup_service_name=backblaze
hestiacp_accounts=
vestacp_accounts=
cyberpanel_websites=

# process the vars
case $backup_type in
  1)
    parameters_count_expected=5
    logInvalidParametersNumber
    backup_remove=$3
    backup_accounts_status=$4
    backup_service_name=$5
    cyberpanelBackup
  ;;

  2)
    parameters_count_expected=6
    logInvalidParametersNumber
    backup_remove=$3
    backup_accounts_status=$4
    backup_service_name=$5
    backup_dir=$6
    vestacpBackup
  ;;

  3)
    parameters_count_expected=6
    logInvalidParametersNumber
    backup_remove=$3
    backup_accounts_status=$4
    backup_service_name=$5
    backup_dir=$6
    hestiacpBackup
  ;;

  4)
    parameters_count_expected=6
    logInvalidParametersNumber
    backup_remove=$3
    backup_accounts_status=$4
    backup_service_name=$5
    backup_dir=$6
    cpanelBackup
  ;;

  5)
    parameters_count_expected=3
    logInvalidParametersNumber
    backup_file=$3
    fileBackup
  ;;

  6)
    shift 2
    backup_files_list=$@
    filesBackup
  ;;

  7)
    parameters_count_expected=3
    logInvalidParametersNumber
    backup_directory=$3
    directoryBackup
  ;;

  8)
    shift 2
    backup_directories_list=$@
    directoriesBackup
  ;;

  9)
    parameters_count_expected=3
    logInvalidParametersNumber
    backup_directory=$3
    directoryBackupCompressed
  ;;

  10)
    shift 2
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
