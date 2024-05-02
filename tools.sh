#!/bin/bash

TIMESTAMP=$(date +%Y-%m-%d)
LOG_FILE=/var/log/backup_script/script-log-$TIMESTAMP

log() {
    echo "$(date -u): $1" | tee -a $LOG_FILE
}

cont_running() {
    if [ -n "$(docker ps -f "name=$1" -f "status=running" -q )" ]; then
        log "The container $1 is running"
    else
        log "The container $1 is not running"
        exit 1
    fi
}

remove_folder () {

    rm -rf $1
    if [ $? -ne 0 ]; then 
        log "error deleting $1"
        exit 1
    fi
}
remove_files() {

    if [ "$#" -eq 0 ]; then
        echo "Usage: remove_files file1 [file2 ...]"
        return 1
    fi

    for file in "$@"; do
        if [ -e "$file" ]; then
            rm -f "$file"
            log "Removed: $file"
        else
            log "File does not exist: $file"
        fi
    done
}
