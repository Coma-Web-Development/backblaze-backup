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
backup_procedure_name=
hestiacp_accounts=
vestacp_accounts=
cyberpanel_websites=
cpanel_accounts=

# process the vars
case $backup_type in
  1)
    parameters_count_expected=6
    logInvalidParametersNumber
    backup_service_name=$2
    backup_bucket_name=$3
    backup_remove=$4
    backup_accounts_status=$5
    backup_procedure_name=cyberpanelBackup
  ;;

  2)
    parameters_count_expected=7
    logInvalidParametersNumber
    backup_service_name=$2
    backup_bucket_name=$3
    backup_remove=$4
    backup_accounts_status=$5
    backup_dir=$6
    backup_procedure_name=vestacpBackup
  ;;

  3)
    parameters_count_expected=7
    logInvalidParametersNumber
    backup_service_name=$2
    backup_bucket_name=$3
    backup_remove=$4
    backup_accounts_status=$5
    backup_dir=$6
    backup_procedure_name=hestiacpBackup
  ;;

  4)
    parameters_count_expected=7
    logInvalidParametersNumber
    backup_service_name=$2
    backup_bucket_name=$3
    backup_remove=$4
    backup_accounts_status=$5
    backup_dir=$6
    backup_procedure_name=cpanelBackup
  ;;

  5)
    parameters_count_expected=5
    logInvalidParametersNumber
    backup_service_name=$2
    backup_bucket_name=$3
    backup_remove=$4
    backup_file=$5
    backup_procedure_name=fileBackup
  ;;

  6)
    backup_service_name=$2
    backup_bucket_name=$3
    backup_remove=$4
    shift 4
    backup_files_list=$@
    backup_procedure_name=filesBackup
  ;;

  7)
    parameters_count_expected=6
    logInvalidParametersNumber
    backup_service_name=$2
    backup_bucket_name=$3
    backup_remove=$4
    backup_directory=$5
    backup_procedure_name=directoryBackup
  ;;

  8)
    backup_service_name=$2
    backup_bucket_name=$3
    backup_remove=$3
    shift 4
    backup_directories_list=$@
    backup_procedure_name=directoriesBackup
  ;;

  9)
    parameters_count_expected=6
    logInvalidParametersNumber
    backup_service_name=$2
    backup_bucket_name=$3
    backup_remove=$4
    backup_directory=$5
    backup_procedure_name=directoryBackupCompressed
  ;;

  10)
    backup_service_name=$2
    backup_bucket_name=$3
    backup_remove=$4
    shift 4
    backup_directories_list=$@
    backup_procedure_name=directoriesBackupCompressed
  ;;

  *)
    log ERROR "The backup code >>> $backup_type << is invalid."
  ;;
esac

main

# unknown error
log ERROR "Unknown error. Aborting with code >>> 255 <<<."
exit 255
