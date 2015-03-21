#!/bin/bash

# Use
# ---
# - Edit the file svn_backup.sh and setup the variables
# SVN_FOLDER_FROM: Main SVN's repository folder.
# BACKUP_FOLDER_TO: Destination folder for the backup files.
# TMP_FOLDER: Temporal folder where this scripts will needs write a DUMP file.
# PREFIX: A string to concatenate at the beginning of the name of the backup file.
# DAYS_LIVE: Days that will last the backup files, then those files will be deleted.

# -  Give execution permission and run.
# $ chmod 775 svn_backup.sh
# $ ./svn_backup.sh

# - Or, run with sh command
# $ sh svn_backup.sh

# - Parameter for FULL or INCREMENTAL backup
# $ ./svn_backup.sh full    # Same without parameter FULL
# $ ./svn_backup.sh incr    # Make an INCREMENTAL backup

#----------------------------------------------------------------
#  Parameters
#----------------------------------------------------------------
SVN_FOLDER_FROM="/var/subversion"
BACKUP_FOLDER_TO="/mnt/backups/"
TMP_FOLDER="/var/tmp/"
PREFIX="all-svn-"
DAYS_LIVE=60

#----------------------------------------------------------------
TYPE="full"
if [ "incr" == "$1" ]; then
    TYPE="incr"
fi
DATESTR=`date '+%Y%m%d%H%M%S'`
cd "$SVN_FOLDER_FROM"
for repo in *; do
    if [ -d ${repo} ]; then
        NAME_ID=$PREFIX$DATESTR"-$TYPE-"$repo
        LOG_FILE=$BACKUP_FOLDER_TO$NAME_ID".log"
        SUCCESS_DUMP=0

        echo "Starting "$TYPE" backup process SVN..." > ${LOG_FILE}
        echo "-----------------------------------" >> ${LOG_FILE}
        echo "BEGIN: " `date '+%d-%m-%Y %H:%M:%S'` >> ${LOG_FILE}
        echo ""  >> ${LOG_FILE}

        echo "Starting dump: " >> ${LOG_FILE}
        CURR_REV=`svnlook youngest ${SVN_FOLDER_FROM}"/"${repo}`
        if [ "full" == "$TYPE" ]; then
            svnadmin dump --quiet ${SVN_FOLDER_FROM}"/"${repo} > ${TMP_FOLDER}${NAME_ID}".dump"
            SUCCESS_DUMP=1
        else
            #Incremental
            REP_LAST_BK_REV=0
            #Ask if the file exist
            if [ -e ${BACKUP_FOLDER_TO}/status/revisions/${repo}.rev ]; then
                REP_LAST_BK_REV=`cat ${BACKUP_FOLDER_TO}/status/revisions/${repo}.rev`
            else
                #If not exist
                mkdir -p ${BACKUP_FOLDER_TO}/status/revisions/            #Build folder
                touch ${BACKUP_FOLDER_TO}/status/revisions/${repo}.rev    #Build an empty file
            fi
            echo "Backup incremental. Last backup revision: $REP_LAST_BK_REV. Current revision: $CURR_REV" >> ${LOG_FILE}
            if [ ${CURR_REV} -gt ${REP_LAST_BK_REV} ] ; then
                echo "Incremental backup will continue..." >> ${LOG_FILE}
                NAME_ID=$NAME_ID"-"$REP_LAST_BK_REV"-"$CURR_REV
                svnadmin dump --quiet ${SVN_FOLDER_FROM}"/"${repo} --incremental -r${REP_LAST_BK_REV}:${CURR_REV} > ${TMP_FOLDER}${NAME_ID}".dump"
                SUCCESS_DUMP=1
            fi
        fi

        if [ $SUCCESS_DUMP -gt 0 ]; then
            echo "Dump succesful." >> ${LOG_FILE}
            echo ${CURR_REV} > ${BACKUP_FOLDER_TO}/status/revisions/${repo}.rev
            echo ""  >> ${LOG_FILE}

            echo "Starting file compression in: " ${BACKUP_FOLDER_TO}${NAME_ID}".tgz" >> ${LOG_FILE}
            tar -cvzf ${BACKUP_FOLDER_TO}${NAME_ID}".tgz" ${TMP_FOLDER}${NAME_ID}".dump" >> ${LOG_FILE}
            echo "Backup Done!." >> ${LOG_FILE}
            echo ""  >> ${LOG_FILE}

            echo "Deleting original dump file: " ${TMP_FOLDER}${NAME_ID}".dump" >> ${LOG_FILE}
            rm -fR ${TMP_FOLDER}${NAME_ID}".dump" >> ${LOG_FILE}
            echo "Dump file succesful deleted." >> ${LOG_FILE}
            echo ""  >> ${LOG_FILE}

            echo "END: " `date '+%d-%m-%Y %H:%M:%S'` >> ${LOG_FILE}

            #Only old files will erase if a backup process was made successful
            qty_to_delete=`find ${BACKUP_FOLDER_TO}"*" -mtime +${DAYS_LIVE} -name "*${repo}*" | wc -l`
            echo "" >> ${LOG_FILE}
            echo $qty_to_delete" files will delete, because have more than "$DAYS_LIVE" days" >> ${LOG_FILE}
            `find ${BACKUP_FOLDER_TO}* -mtime +${DAYS_LIVE} -name "*${repo}*" -exec rm {} +`
        fi
        echo "---------------------------------------" >> ${LOG_FILE}
        echo "Finalizando el proceso de backup SVN..." >> ${LOG_FILE}
    fi
done