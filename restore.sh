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
    MONGODB_NEWNAME
	AUTH_DB
    MONGODB_HOST
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



: ${AUTH_DB:="admin"}
: ${EXTRA_OPTIONS:=""}

if [ -z ${MONGODB_HOST+x} ]; then echo "You must provide a host: MONGODB_HOST"; exit 1; fi
if [ -z ${MONGODB_USER+x} ]; then echo "You must provide a database user: MONGODB_USER"; exit 1; fi
if [ -z ${MONGODB_PASSWORD+x} ]; then echo "You must provide a password: MONGODB_PASSWORD"; exit 1; fi
if [ -z ${MONGODB_NEWNAME+x} ]; then echo "You must provide a database name to backup: MONGODB_NEWNAME"; exit 1; fi
if [ -z ${RESTORE_FILE+x} ]; then echo "You must provide a filename to restore: RESTORE_FILE"; exit 1; fi
if [ -z ${AWS_ACCESS_KEY_ID+x} ]; then echo "You must provide an AWS Access Key: AWS_ACCESS_KEY_ID"; exit 1; fi
if [ -z ${AWS_SECRET_ACCESS_KEY+x} ]; then echo "You must provide an AWS Secret key: AWS_SECRET_ACCESS_KEY"; exit 1; fi
if [ -z ${AWS_DEFAULT_REGION+x} ]; then echo "You must provide an AWS Region: AWS_DEFAULT_REGION"; exit 1; fi


/usr/local/bin/aws s3 cp --region ${AWS_DEFAULT_REGION} s3://$S3_BUCKET/$S3_PATH/$RESTORE_FILE restorethis.gz

mongorestore --gzip --archive=restorethis.gz --host ${MONGODB_HOST} -u ${MONGODB_USER} -p ${MONGODB_PASSWORD} --nsFrom '$db$.$collection$' --nsTo ${MONGODB_NEWNAME}'.$collection$'  --authenticationDatabase ${AUTH_DB} ${EXTRA_OPTIONS}

rm restorethis.gz

