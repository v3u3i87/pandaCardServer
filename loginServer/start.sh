#!/bin/sh
BEXIST=`pgrep -f openresty`
if [ -n "$BEXIST" ]
        then
        echo "wait 2s for kill openresty"
        sudo pkill -f openresty
        sleep 2
fi

sudo  /usr/local/openresty/bin/openresty -p ./nginx -c conf/nginx.conf

BEXIST=`pgrep -f openresty`
if [ -n "$BEXIST" ]
        then
        echo "openresty restart success"
fi