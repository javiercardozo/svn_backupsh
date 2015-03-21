# svn_backupsh
A script that allow make full and incremental backups of SVN's repositories.

This script was made to run in the same server where the SVN is running. It makes a backup from a local folder to other local folder. You may the steps for setup remote backup. (i.e: mount a remote folder -smb, nts, etc.- as destination folder for backups files)

Use
---
- Edit the file svn_backup.sh and setup the variables
SVN_FOLDER_FROM: Main SVN's repository folder.
BACKUP_FOLDER_TO: Destination folder for the backup files.
TMP_FOLDER: Temporal folder where this scripts will needs write a DUMP file.
PREFIX: A string to concatenate at the beginning of the name of the backup file.
DAYS_LIVE: Days that will last the backup files, then those files will be deleted.

-  Give execution permission and run.
$ chmod 775 svn_backup.sh
$ ./svn_backup.sh

- Or, run with sh command 
$ sh svn_backup.sh

- Parameter for FULL or INCREMENTAL backup
$ ./svn_backup.sh full    # Same without parameter FULL
$ ./svn_backup.sh incr    # Make an INCREMENTAL backup


Tips
----
- Mount an external folder on server for put your backup files.
- Setup a crondjob for automation backup.
- Alternative, setup two crondjobs: Everyday for incremental backup and once a week full backup.
