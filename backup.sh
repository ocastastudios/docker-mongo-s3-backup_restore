#!/bin/bash
#
set -euo pipefail

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_PASSWORD' 'example'
# (will allow for "$XYZ_PASSWORD_FILE" to fill in the value of
#  "$XYZ_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
        export "$var"="$val"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
        export "$var"="$val"
	fi
	unset "$fileVar"
}


envs=(
	MONGODB_USER
    MONGODB_PASSWORD
    MONGODB_NAME
	AUTH_DB
    MONGODB_HOST
    BACKUP_FILENAME
    EXTRA_OPTS
    AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY
    AWS_DEFAULT_REGION
    S3_BUCKET
    S3_PATH
)

for e in "${envs[@]}"; do
	file_env "$e"
done

now=`date '+%Y%m%d%H%M%S'`

: ${AUTH_DB:="admin"}
: ${BACKUP_FILENAME:="backup-"${now}".gz"}
: ${EXTRA_OPTIONS:=""}

if [ -z ${MONGODB_HOST+x} ]; then echo "You must provide a host: MONGODB_HOST"; exit 1; fi
if [ -z ${MONGODB_USER+x} ]; then echo "You must provide a database user: MONGODB_USER"; exit 1; fi
if [ -z ${MONGODB_PASSWORD+x} ]; then echo "You must provide a password: MONGODB_PASSWORD"; exit 1; fi
if [ -z ${MONGODB_NAME} ]; then echo "You must provide a database name to backup: MONGODB_NAME"; exit 1; fi
if [ -z ${AWS_ACCESS_KEY_ID} ]; then echo "You must provide an AWS Access Key: AWS_ACCESS_KEY_ID"; exit 1; fi
if [ -z ${AWS_SECRET_ACCESS_KEY} ]; then echo "You must provide an AWS Secret key: AWS_SECRET_ACCESS_KEY"; exit 1; fi
if [ -z ${AWS_DEFAULT_REGION} ]; then echo "You must provide an AWS Region: AWS_DEFAULT_REGION"; exit 1; fi
[[ ( -n "${MONGODB_USER}" ) ]] && USER_STR=" --username ${MONGODB_USER}"
[[ ( -n "${MONGODB_PASSWORD}" ) ]] && PASSWORD_BACKUP_STR=" --password ${MONGODB_PASSWORD}"
[[ ( -n "${MONGODB_NAME}" ) ]] && USER_BACKUP_STR=" --db ${MONGODB_NAME}"

mongodump --quiet --archive=$BACKUP_FILENAME --gzip --host ${MONGODB_HOST} -u ${MONGODB_USER} -p ${MONGODB_PASSWORD} --db ${MONGODB_NAME} --authenticationDatabase ${AUTH_DB} ${EXTRA_OPTIONS}

/usr/local/bin/aws s3 cp --region ${AWS_DEFAULT_REGION} $BACKUP_FILENAME s3://$S3_BUCKET/$S3_PATH/
rm $BACKUP_FILENAME

