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
}

authorizeAccount()
{
  echo "Now please execute the follow command:"
  echo "backblaze authorize-account applicationKeyId applicationKey"
  echo "Note: change the applicationKeyId and applicationKey to the respective credentials"
}

main()
{
  installBinary
  installScript
  authorizeAccount
  exit 0
}

main

# unknown error
exit 255
