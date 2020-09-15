#!/bin/bash
set -e

if [[ -z "$1" ]]; then
    echo "Usage: $0 crontabfile"
    exit 0
fi

/usr/bin/crontab "$1"
/usr/sbin/crond -f -L /dev/stdout
