#!/bin/bash
cd ~/backup
source tools.sh

#------------VARIABLES-------------
MYSSQL_CONTAINER="MYSQLCONTAINERNAME"
GHOST_CONTAINER="GHOSTCONTAINERNAME"
TIMESTAMP=$(date +%Y-%m-%d)
REMOTE_BACKUP_LOCATION="/bck"
LOG_FILE=/var/log/backup_script/script-log-$TIMESTAMP
    # --- CONTENT ---
GHOST_DIR="GHOSTCONTAINERDIRECTORY" #where the bind-mount /content is accessible
GHOST_CONTENT_BACKUP_FILENAME="backup-from-ghost-$TIMESTAMP.tar.gz"
GHOST_SAVE_CONTENT="save-ghost-content-$TIMESTAMP"
    # --- MYSQL ---
GHOST_MYSQL_BACKUP_FILENAME="backup-from-mysql-$TIMESTAMP.sql.gz" 
GHOST_MYSQL_DIRECTORY="MYSQLCONTAINERDIRECTORY" #where the bind-mount /dump is accessible

#------------FUNCTIONS-------------

pre-bckup-check() {

    if [ ! -f $LOG ]; then
        touch $LOG
    fi
    log "----RUN OF THE BACKUP SCRIPT STARTS HERE----"
    log "Running Pre-Backup checks"

    if [ ! -d $GHOST_DIR ]; then
        log "Ghost directory does not exist"
        exit 1
    fi
    
    cont_running $MYSSQL_CONTAINER
    if [ $? -ne 0 ]; then 
        exit 1
    fi
    
    cont_running $GHOST_CONTAINER
    if [ $? -ne 0 ]; then 
        exit 1
    fi
    
}

bcp_content() {

    cd $GHOST_DIR

    cp content -r $REMOTE_BACKUP_LOCATION/$GHOST_SAVE_CONTENT
    if [ $? -ne 0 ]; then 
        log "Error while copying the content folder into the backup directory"
        exit 1
    fi
    log "The size of the content directory is `du -sh $REMOTE_BACKUP_LOCATION/$GHOST_SAVE_CONTENT`"

    cd $REMOTE_BACKUP_LOCATION
    tar -zcf $GHOST_CONTENT_BACKUP_FILENAME $GHOST_SAVE_CONTENT
    if [ $? -ne 0 ]; then 
        log "error while compressing the content folder"
        exit 1
    else
        log "Archive $GHOST_CONTENT_BACKUP_FILENAME successfully created"
    fi
}

bcp_mysql () {

    cd ~/backup
    docker exec --env-file=db.env $MYSSQL_CONTAINER bash -c 'mysql -u"$GHOST_DUMP_USER" -p"$GHOST_DUMP_PWD" -e quit'

    if [ $? -ne 0 ]; then 
        log "Error while connecting to database with user $GHOST_DUMP_USER"
        exit 1
    else
        log "Connection to databtase OK with $GHOST_DUMP_USER"
    fi

    docker exec --env-file=db.env -e TIMESTAMP=$(date +%Y-%m-%d) $MYSSQL_CONTAINER bash -c 'mysqldump -u"$GHOST_DUMP_USER" -p"$GHOST_DUMP_PWD" $DB_NAME | gzip > /dump/backup-from-mysql-$TIMESTAMP.sql.gz'
    mv $GHOST_MYSQL_DIRECTORY/$GHOST_MYSQL_BACKUP_FILENAME $REMOTE_BACKUP_LOCATION/$GHOST_MYSQL_BACKUP_FILENAME
    if [ $? -ne 0 ]; then 
        log "Error while copying $GHOST_MYSQL_DIRECTORY/$GHOST_MYSQL_BACKUP_FILENAME"
        exit 1
    else
        log "Copy of $GHOST_MYSQL_DIRECTORY/$GHOST_MYSQL_BACKUP_FILENAME OK"
    fi
}
#------------MAIN-------------

pre-bckup-check
bcp_mysql
bcp_content
remove_folder $GHOST_SAVE_CONTENT
remove_files $GHOST_CONTENT_BACKUP_FILENAME $GHOST_MYSQL_BACKUP_FILENAME
log "----END OF THE BACKUP SCRIPT----"
