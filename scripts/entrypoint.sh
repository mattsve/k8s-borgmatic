#!/bin/bash

echo "$@"
if [[ "$1" == "backup" ]]; then
    shift
    /scripts/backup.sh "$@" 
elif [[ "$1" == "restore" ]]; then
    shift
    /scripts/restore.sh "$@"
elif [[ "$1" == "cron" ]]; then
    shift
    /scripts/cron.sh "$@"
else
    echo "$0: first argument must be 'backup' or 'restore'"
fi
