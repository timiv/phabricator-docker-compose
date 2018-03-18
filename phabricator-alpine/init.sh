#!/bin/sh
# Configure Phabricator on startup from environment variables.
MYSQL_HOST="${MYSQL_HOST:-mariadb}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_PASSWORD="${MYSQL_PASSWORD}"
REPOSITORY_LOCAL_PATH="${REPOSITORY_LOCAL_PATH:-/shared/repo}"
PHABRICATOR_URI="${PHABRICATOR_URI:-http://127.0.0.1}"

set -ex

cd phabricator

#Wait for mysql
/app/wait-for-mysql.sh

./bin/config set mysql.host ${MYSQL_HOST}
./bin/config set mysql.port ${MYSQL_PORT}
./bin/config set mysql.user ${MYSQL_USER}

#set +x

test -n "${MYSQL_PASS}" && ./bin/config set mysql.pass ${MYSQL_PASS}

# Upgrade database and also create one if it does not exist
DO_DATABASE=0
./bin/storage status > /dev/null 2>&1
if [ ! -z "$(./bin/storage status | grep -i 'not (applied|initialized)')" ]; then
    ./bin/storage upgrade --force
fi

#set +e

# Set the local repository
if [ -n "${REPOSITORY_LOCAL_PATH}" ]; then
    if [ ! -d "${REPOSITORY_LOCAL_PATH}" ]; then
        mkdir -p "${REPOSITORY_LOCAL_PATH}"
    fi
    ./bin/config set repository.default-local-path "${REPOSITORY_LOCAL_PATH}"
    else
    echo "No REPOSITORY_LOCAL_PATH set"
    exit
fi

# You should set the base URI to the URI you will use to access Phabricator,
# like "http://phabricator.example.com/".

# Include the protocol (http or https), domain name, and port number if you are
# using a port other than 80 (http) or 443 (https).
test -n "${PHABRICATOR_URI}" \
    && ./bin/config set phabricator.base-uri "${PHABRICATOR_URI}"

# Set recommended runtime configuration values to silence setup warnings.
./bin/config set storage.mysql-engine.max-size 8388608
./bin/config set pygments.enabled true
./bin/config set phabricator.timezone UTC

# Ensure that we have an updated static resources map
# Required so extension resources are accounted for and available
./bin/celerity map

# Start phd and php
./bin/phd start && /usr/local/sbin/php-fpm -F

