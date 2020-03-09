#!/bin/sh

list=$(curl -s $TRACKER_URL)
if [ -z "${list}" ]
then
    echo Failed to update bt trackers.
    date > /app/lastupdatefailed.txt
    exit 1;
fi

url_list=$(echo ${list} | sed 's/[ ][ ]*/,/g')
ARIA2_TOKEN=`grep -Eo "^rpc-secret=.*" /conf/aria2.conf | cut -d '=' -f 2`

# pack json
uuid=$(cat /proc/sys/kernel/random/uuid)
json='{
    "jsonrpc": "2.0",
    "method": "aria2.changeGlobalOption",
    "id": "'${uuid}'",
    "params": [
        "token:'${ARIA2_TOKEN}'",
        {
            "bt-tracker": "'${url_list}'"
        }
    ]
}'

# post json
curl -H "Accept: application/json" \
    -H "Content-type: application/json" \
    -X POST \
    -d "$json" \
    -s "http://localhost:6800/jsonrpc"

if [ -z `grep "bt-tracker" /conf/aria2.conf` ]
then
    sed -i '$a bt-tracker='"${url_list}" /conf/aria2.conf
    echo Succeed to add bt trackers.
else
    sed -i 's@bt-tracker.*@bt-tracker='"${url_list}"'@g' /conf/aria2.conf
    echo Succeed to update bt trackers.
fi
date > /app/lastupdatesuccess.txt