#!/bin/bash
# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o nounset

usage() { 
    echo "Usage:"
    echo "  -r|--repository <repository>"
    echo "  -p|--passphrase <passphrase>"
    echo "  -a|--archive <archive>"
    echo "  -h|--help"
}

# -allow a command to fail with !’s side effect on errexit
# -use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi

OPTIONS=r:p:a:h
LONGOPTS=repository,passphrase,archive

# -regarding ! and PIPESTATUS see above
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

repository=
passphrase=
archive=
# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -r|--repository)
            repository="$2"
            shift 2
            ;;
        -p|--passphrase)
            passphrase="$2"
            shift 2
            ;;
        -a|--archive)
            archive="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

# handle non-option arguments
if [[ $# -ne 1 ]]; then
    echo "A directory to backup is needed."
    usage
    exit 4
fi
if [[ -z "$repository" ]]; then
    echo "A repository is needed."
    usage
    exit 4
fi
if [[ -z "$archive" ]]; then
    echo "An archive is needed."
    usage
    exit 4
fi
if [[ -z "$passphrase" ]]; then
    echo "A passphrase is needed."
    usage
    exit 4
fi

cd $1
borgmatic init --encryption repokey-blake2 \
    --override "location.repositories=[$repository]" "storage.encryption_passphrase=$passphrase" "storage.archive_name_format=$archive-{now}" "retention.prefix=$archive-" "consistency.prefix=$archive-"

LAST_BACKUP=$(borgmatic list --successful --last 1 --json \
        --override "location.repositories=[$repository]" "storage.encryption_passphrase=$passphrase" "storage.archive_name_format=$archive-{now}" "retention.prefix=$archive-" "consistency.prefix=$archive-" \
        | jq -r .[0].archives[0].archive)
if [[ $LAST_BACKUP != "null" ]] && ([[ ! -f ".last-backup" ]] || [[ $(< .last-backup) != "$LAST_BACKUP" ]]); then
    echo "Extracting archive $LAST_BACKUP from $repository"
    borgmatic extract --progress --archive latest \
        --override "location.repositories=[$repository]" "storage.encryption_passphrase=$passphrase" "storage.archive_name_format=$archive-{now}" "retention.prefix=$archive-" "consistency.prefix=$archive-"
    echo "$LAST_BACKUP" > .last-backup
else
    echo "Up to date with $LAST_BACKUP from $repository"
fi
