#!/bin/bash

rm -f /usr/bin/backblaze-backup.sh /usr/lib/backup-library.sh /usr/bin/backblaze
return_rm=$?

if [ $return_rm -eq 0 ]
then
  echo "Removed with success. Please manually remove the log files:"
  echo "- /var/log/backblaze-backup.log"
else
  echo "Impossible to remove. The return code error was >>> $return_rm <<<"
fi
