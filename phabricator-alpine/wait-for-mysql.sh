# Wait for MYSQL to become ready

TRIES=0
while ! mysqladmin ping -h"$MYSQL_HOST" --silent ; do
    echo "Wating for MYSQL to become ready"
    sleep 1
    TRIES=$[$TRIES+1]
    if [ $TRIES -gt 30 ]; then
        echo "Max tries reached. Connection failed!"
        exit 1
    fi
done

echo "MYSQL Connection ready!"
exit 0
