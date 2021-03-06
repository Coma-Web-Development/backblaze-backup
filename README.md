# backblaze-backup
This is not a BackBlaze official script. This script is published to help the community backup their files inside of BackBlaze service.

This backup script is capable of create, send and remove backups of the following hosting panels:
- VestaCP
- HestiaCP
- Cyberpanel

If you do not want to use any hosting panel schema, we will also provide a way to you give one or more directories and the script will take care.

# Features implemented and TO DO
| Feature | Status |
| - | - |
| hestiacp backup | DONE |
| vestacp backup | DONE |
| cyberpanel backup | DONE |
| cpanel backup | TO DO |
| multiple extensions | TO DO |
| log to audit the backup | DONE |
| zabbix notification script | TO DO |
| backblaze-backup script examples | DONE |
| upgrade blackbaze binary script | DONE |
| script to remove backblaze setup | DONE |
| how to create crontab | DONE |
| single directory backup | TO DO |
| multiple directories backup | TO DO |
| single file backup | DONE |
| multiple files backup | TO DO |
| nextcloud backup | TO DO |
| rocketchat backup | TO DO |

# how to install
1. Execute the installer. It will install the latest stable and official backblaze binary for Linux x85_64
```bash
bash install.sh
```
2. Configure the BackBlaze credentials. Change the "applicationKeyId" and "applicationKey" to the respective credentials that you created inside of BackBlaze dashboard.
```bash
backblaze authorize-account applicationKeyId applicationKey
```

# how to remove
```bash
bash uninstall.sh
```

# how to upgrade backblaze
Just execute the installer again! You do not need to authrorize the s3 credentials again.
```bash
bash install.sh
```

# where is the logs
Generic name:
```bash
/var/log/backup-*.log
```

Backblaze example:
```bash
/var/log/backblaze-backup.log
```

# backblaze-backup.sh parameters explained
- The script backblaze-backup need some parameters to understand what you want to do
- the first parameter is the code that identify the backup method that you want (directory, file, compressed files, vestacp panel, cyberpanel, hestiacp panel etc)
- All parameters are mandatory
- After you create and test your backup, you can create a cronjob under root credentials to automatically execute the backup

Generic use of the script:
```bash
/usr/bin/bash /usr/bin/backblaze-backup.sh codeID parameter1 parameter2 parameter3 parameter4 etc
```

## codeID
The code will identify which kind of backup you want. Maybe you need to just send a file or one directory or more than one directory. Maybe you want to send cyberpanel (web panel) backups or maybe the vestacp backups. This codeID will identify what type the backup do you want and based on this codeID you will give the right parameters. 

| codeID | backup description |
| --- | --- |
| 1 | cyberpanel backups |
| 2 | vestacp backups |
| 3 | hestiacp backups |
| 4 | cpanel backups |
| 5 | single file |
| 6 | multiple files |
| 7 | single directory: find the files and send  |
| 8 | multiples directories: find the files and send |
| 9 | single directory: create tar, compress and send |
| 10 | multiples directories: create tar, compress and send |
| 11 | nextcloud instance backup |
| 12 | rocketchat instance backup |

### general script all

The basic script call will have this standard:

```bash
/usr/bin/backblaze-backup.sh parameter1 parameter2 parameter3 ...  parameterN
```

The parameters number will be defined based in every backup method. And the method depends about the codeID. The codeID, as explained before, identify the backup type that will be used.

When the parameter has more than one option, the "Parameter number" column will have more than one line to clarify what the parameter does. However pay attention that the parameterN with P options, only one option can be used at the same time. This is obvious, but you have to guarantee that you are not adding extra parameters.

### codeID: 1

| Parameter number | options | what this mean |
| --- | --- | --- |
| 1 | 1 | cyberpanel codeID |
| 2 | bacbklaze | which s3 service will be used |
| 3 | yesRemoveAfterSent | remove the files after successfully send the backup |
| 3 | notReMoveAfterSent | do not remove the files after send |
| 4 | all | create and send backup of all accounts |
| 4 | active | create and send backup of all accounts, except suspended accounts |
| 5 | bucketname | the s3 bucket name |

Example:
```bash
/usr/bin/backblaze-backup.sh 1 backblaze yesRemoveAfterSent all mybucketname
```
- "1": cyberpanel backup method
- "backblaze" : s3 service that will be used
- "yesRemoveAfterSent" : the file will be removed after send
- "all" : create and send backup of all accounts
- "mybucketname" : the bucketname

### codeID: 2

| Parameter number | options | what this mean |
| --- | --- | --- |
| 1 | 2 | vestacp codeID  | 
| 2 | bacbklaze | which s3 service will be used |
| 3 | yesRemoveAfterSent | remove the files after successfully send the backup |
| 3 | notReMoveAfterSent | do not remove the files after send |
| 4 | all | create and send backup of all accounts |
| 5 | active | create and send backup of all accounts, except suspended accounts |
| 5 | bucketname | the name of the s3 bucket |
| 6 | directory | which directory the temp files and the final backup will be stored |

Example:
```bash
/usr/bin/backblaze-backup.sh 2 backblaze yesRemoveAfterSent all mybucketname /path/to/store/tmp/files/
```
- "2": vestacp backup method
- "backblaze" : s3 service that will be used
- "yesRemoveAfterSent" : the file will be removed after send
- "all" : create and send backup of all accounts
- "mybucketname" : the bucketname
- "/path/to/store/tmp/files/" : path to store the temp files OR path to store the backup files if you will not remove them after sent

### codeID 3

| Parameter number | options | what this mean |
| --- | --- | --- |
| 1 | 3 | hestiacp codeID |
| 1 | bacbklaze | which s3 service will be used |
| 2 | yesRemoveAfterSent | remove the files after successfully send the backup |
| 2 | notReMoveAfterSent | do not remove the files after send |
| 3 | all | create and send backup of all accounts |
| 3 | active | create and send backup of all accounts, except suspended accounts |
| 4 | bucketname | the name of the s3 bucket |
| 5 | directory | which directory the temp files and the final backup will be stored |

Example:
```bash
/usr/bin/backblaze-backup.sh 3 backblaze yesRemoveAfterSent all mybucketname /path/to/store/tmp/files/
```
- "3": hestiacp backup method
- "backblaze" : s3 service that will be used
- "yesRemoveAfterSent" : the file will be removed after send
- "all" : create and send backup of all accounts
- "mybucketname" : the bucketname
- "/path/to/store/tmp/files/" : path to store the temp files OR path to store the backup files if you will not remove them after sent

### codeID 4

| Parameter number | options | what this mean |
| --- | --- | --- |
| 1 | 4 | cpanel codeID |
| 2 | bacbklaze | which s3 service will be used |
| 3 | bucketname | the name of the s3 bucket |
| 4 | yesRemoveAfterSent | remove the files after successfully send the backup |
| 4 | notReMoveAfterSent | do not remove the files after send |
| 5 | all | create and send backup of all accounts |
| 5 | active | create and send backup of all accounts, except suspended accounts |
| 6 | directory | which directory the temp files and the final backup will be stored |

### codeID 5
| Parameter number | options | what this mean |
| --- | --- | --- |
| 1 | 5 | single file codeID |
| 2 | bacbklaze | which s3 service will be used |
| 3 | bucketname | the name of the s3 bucket |
| 4 | yesRemoveAfterSent | remove the files after successfully send the backup |
| 4 | notReMoveAfterSent | do not remove the files after send |
| 5 | file | absolut path of the filename |

Example:
```bash
/usr/bin/backblaze-backup.sh 5 backblaze mybucketname yesRemoveAfterSent /home/backup/myfile.tar.gz
```
- "5": single file
- "backblaze" : s3 service that will be used
- "mybucketname" : the bucketname
- "yesRemoveAfterSent" : the file will be removed after send
- "/home/backup/myfile.tar.gz" : the file absolut path

### codeID 6
| Parameter number | options | what this mean |
| --- | --- | --- |
| 1 | 6 | multiple files codeID |
| 2 | bacbklaze | which s3 service will be used |
| 3 | bucketname | the name of the s3 bucket |
| 4 | yesRemoveAfterSent | remove the files after successfully send the backup |
| 4 | notReMoveAfterSent | do not remove the files after send |
| 5...N | file1 file2 ... fileN | absolut path of the files |

### codeID 7
| Parameter number | options | what this mean |
| --- | --- | --- |
| 1 | 7 | single directory codeID |
| 2 | bacbklaze | which s3 service will be used |
| 3 | bucketname | the name of the s3 bucket |
| 4 | yesRemoveAfterSent | remove the files after successfully send the backup |
| 4 | notReMoveAfterSent | do not remove the files after send |
| 5 | directory | absolut path of the directory |

### codeID 8
| Parameter number | options | what this mean |
| --- | --- | --- |
| 1 | 8 | multiple directories codeID |
| 2 | bacbklaze | which s3 service will be used |
| 3 | bucketname | the name of the s3 bucket |
| 4 | yesRemoveAfterSent | remove the files after successfully send the backup |
| 4 | notReMoveAfterSent | do not remove the files after send |
| 5...N | dir1 dir2 ... dirN | absolut path of the directories |

### codeID 9
| Parameter number | options | what this mean |
| --- | --- | --- |
| 1 | 9 | single directory with compression codeID |
| 2 | bacbklaze | which s3 service will be used |
| 3 | bucketname | the name of the s3 bucket |
| 4 | yesRemoveAfterSent | remove the files after successfully send the backup |
| 4 | notReMoveAfterSent | do not remove the files after send |
| 5 | directory | absolut path of the directory |

### codeID 10
| Parameter number | options | what this mean |
| --- | --- | --- |
| 1 | 10 | multiple directories with compression codeID |
| 2 | bacbklaze | which s3 service will be used |
| 3 | bucketname | the name of the s3 bucket |
| 4 | yesRemoveAfterSent | remove the files after successfully send the backup |
| 4 | notReMoveAfterSent | do not remove the files after send |
| 5...N | dir1 dir1 ... dirN | absolut path of the directories |

# How to add to cronjob
You need to execute the script as root. So add the cronjob to root crontab. You can manually edit the file

```bash
/var/spool/cron/root
```

or

```bash
crontab -e
```

Crontab exampple executing everyday 4AM:
```bash
0 4 * * * /usr/bin/backblaze-backup.sh cyberpanel yesRemoveAfterSent default default all myserver-backup
```

If you do not want to receive e-mails about every time that the script execute, please use:
```bash
0 4 * * * /usr/bin/backblaze-backup.sh cyberpanel yesRemoveAfterSent default default all myserver-backup &> /dev/null
```

More crontab configuration info/tips:
- https://en.wikipedia.org/wiki/Cron
- https://crontab.guru/
- https://cron.help/
