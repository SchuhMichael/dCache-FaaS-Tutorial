#!/bin/bash

docker build -t kafkafeedprovider .

WSK_IP=$LOCAL_ADDRESS

AUTHSYS=`cat $OPENWHISK_HOME/ansible/files/auth.whisk.system`
AUTH=`cat $OPENWHISK_HOME/ansible/files/auth.guest`
APIHOST=$WSK_IP
EDGEHOST=$WSK_IP
LOCAL_DEV=true
DB_PREFIX=whisk_local_
DB_USER=whisk_admin
DB_PASS=some_passw0rd
DB_URL=http://$WSK_IP:5984
DB_URL_FULL=http://$DB_USER:$WSK_PASS@$DB_IP:5984

docker run -id -e DB_PREFIX=$DB_PREFIX -e DB_URL=$DB_URL -e DB_USER=$DB_USER -e DB_PASS=$DB_PASS -e LOCAL_DEV=true -p 81:5000 kafkafeedprovider

./installKafka.sh $AUTHSYS $EDGEHOST $DB_URL_FULL $DB_PREFIX $APIHOST

wsk -i --auth $AUTH trigger create dcache-full-trigger -f /whisk.system/messaging/kafkaFeed -p brokers $WSK_IP:9099 -p topic billing -p isJSONData True 
wsk -i --auth $AUTH rule create dcache-full-rule dcache-full-trigger /whisk.system/utils/echo
wsk -i --auth $AUTH trigger fire dcache-full-trigger -p "dcache-full-trigger creation_time" "`date`"

wsk -i --auth $AUTH trigger create dcache-write-trigger -f /whisk.system/messaging/kafkaFeed -p brokers $WSK_IP:9099 -p topic billing -p isJSONData True 
wsk -i --auth $AUTH rule create dcache-write-rule dcache-write-trigger /whisk.system/utils/echo
wsk -i --auth $AUTH trigger fire dcache-write-trigger -p "dcache-write-trigger creation_time" "`date`"
