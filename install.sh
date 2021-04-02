#!/bin/bash

installBinary()
{
  wget -q https://github.com/Backblaze/B2_Command_Line_Tool/releases/latest/download/b2-linux -O /usr/bin/backblaze
  chmod +x /usr/bin/backblaze
}

installScript()
{
  cp backblaze-backup.sh /usr/bin/
  chmod +x /usr/bin/backblaze-backup.sh
  cp library.sh /usr/lib/backup-library.sh
}

authorizeAccount()
{
  echo "Now please execute the follow command:"
  echo "backblaze authorize-account applicationKeyId applicationKey"
  echo "Note: change the applicationKeyId and applicationKey to the respective credentials"
}

requirementsPackages()
{
  if [ ! -f /usr/bin/jq ]
  then
    echo "Please install jq package."
    ccho "Centos/redhat: yum -y install jq"
    echo "Ubuntu/debian: apt update && apt -y install jq" 
  fi
}

main()
{
  installBinary
  installScript
  authorizeAccount
  requirementsPackages
  exit 0
}

main

# unknown error
exit 255
