# This sets up a demo application to show how to integrate dCache - Kafka - OpenWhisk
# We'll play a little dice game and visualize results
# Contact: michael.schuh@desy.de
# www.desy.de www.dcache.org www.eoscpilot.eu


# set your local ip address as LOCAL_ADDRESS
# __DO NOT USE__ 127.0.0.0 addresses, they resolve to localhost also in containers

: "${LOCAL_ADDRESS:?Need to set LOCAL_ADDRESS non-empty}"

DEMO_HOME=`pwd`

# 1. set up dCache

cd $DEMO_HOME/dCache
#The settings used allow anonymous up- and download! This is only for local development, not for production!
#change the chimera password manually in the layout file, if you change in the docker-compose file.
#visit localhost:3880 in your browser to check out dCache view

docker-compose up -d

# health check 
# <ToDo>: use container functionality provided for healthchecks
echo "waiting for dCache to come up ... "
echo test > test
until curl -sf --upload test $LOCAL_ADDRESS:8080; curl -sf  $LOCAL_ADDRESS:8080/test; do printf '.'; sleep 5; done
rm test 
curl -X DELETE $LOCAL_ADDRESS:8080/test
#</ToDo>



# 2. set up openwhisk

rm -rf $DEMO_HOME/ow
mkdir $DEMO_HOME/ow
cd $DEMO_HOME/ow
export OPENWHISK_HOME=$DEMO_HOME/ow/incubator-openwhisk-devtools/docker-compose/openwhisk-master 
export OPENWHISK_CLIENT_HOME=$OPENWHISK_HOME/bin
export PATH=$PATH:$OPENWHISK_CLIENT_HOME
export DOCKER_HOST_IP=localhost
git clone https://github.com/apache/incubator-openwhisk-devtools.git
cd incubator-openwhisk-devtools/docker-compose

make download download-cli docker_pull 
#now self-signed certificates are in ~/tmp, optionally add them to system certs
make setup start-docker-compose init-couchdb init-whisk-cli init-api-management add-catalog

export WSK_AUTH_SYS=`cat $OPENWHISK_HOME/ansible/files/auth.whisk.system`
export WSK_AUTH=`cat $OPENWHISK_HOME/ansible/files/auth.guest`


# 3. run the kafka stream processor 

cd $DEMO_HOME/kafka-stream
docker-compose up -d
STREAM_DOCKER_ID=`docker ps -aqf "name=kafka-stream_stream-kafka_1"`
cp __KafkaStreamProcessor__.java KafkaStreamProcessor.java
sed -i "s/__LOCAL_ADDRESS__/$LOCAL_ADDRESS/g" KafkaStreamProcessor.java

#<ToDo> this should be done in the docker build process, it is a quick and dirty workaround at this point in development
docker exec -w /opt/streams $STREAM_DOCKER_ID bash -c ./maven-generate.sh
docker exec $STREAM_DOCKER_ID bash -c 'rm -f /opt/streams/streams.examples/src/main/java/myapps/*.java'
docker cp pom.xml $STREAM_DOCKER_ID:/opt/streams/streams.examples/
docker cp KafkaStreamProcessor.java $STREAM_DOCKER_ID:/opt/streams/streams.examples/src/main/java/myapps/
docker exec -w /opt/streams/streams.examples $STREAM_DOCKER_ID bash -c 'mvn clean package'
docker exec -d -w /opt/streams/streams.examples $STREAM_DOCKER_ID bash -c 'nohup mvn exec:java -Dexec.mainClass=myapps.KafkaStreamProcessor &'
#</ToDo>

# 4. install the kafka feed package in OpenWhisk

cd $DEMO_HOME/ow-kafka

git clone https://github.com/apache/incubator-openwhisk-package-kafka.git
cd incubator-openwhisk-package-kafka

docker build -t kafkafeedprovider .

APIHOST=$LOCAL_ADDRESS
EDGEHOST=$LOCAL_ADDRESS
LOCAL_DEV=true
DB_PREFIX=whisk_local_
DB_USER=whisk_admin
DB_PASS=some_passw0rd
DB_URL=http://$LOCAL_ADDRESS:5984
DB_URL_FULL=http://$DB_USER:$DB_PASS@$LOCAL_ADDRESS:5984

docker run -id -e DB_PREFIX=$DB_PREFIX -e DB_URL=$DB_URL -e DB_USER=$DB_USER -e DB_PASS=$DB_PASS -e LOCAL_DEV=$LOCAL_DEV -p 81:5000 kafkafeedprovider

./installKafka.sh $WSK_AUTH_SYS $EDGEHOST $DB_URL_FULL $DB_PREFIX $APIHOST


# 5. plug in the dice app

# you can optionally edit the codes in $DEMO_HOME/dice-game/, build from Dockerfile and push to your own repository, then you'd need to edit the '--docker /schuhm/x' links below 

cd $DEMO_HOME/dice-game/docker-check-fraud
sed -i "s/__LOCAL_ADDRESS__/$LOCAL_ADDRESS/g" check_fraud.py

docker build -t schuhm/dice-demo-check .
docker push schuhm/dice-demo-check

wsk -i property set --auth $WSK_AUTH

wsk -i action create dice-demo-throw --docker schuhm/dice-demo-throw
wsk -i action create dice-demo-check --docker schuhm/dice-demo-check

# at first attempt this fails, no idea why
wsk -i trigger create dcache-write-trigger -f /whisk.system/messaging/kafkaFeed -p brokers $LOCAL_ADDRESS:9098 -p topic billing-write -p isJSONData True 
# so we do it twice --- how ugly --- bug: (https://github.com/SchuhMichael/dCache-FaaS-Tutorial/issues/2)

wsk -i rule create dcache-write-rule dcache-write-trigger dice-demo-check

# 6. run it, check that it worked:

RUN_N_TIMES=2
for ((i=0;i<$RUN_N_TIMES;i++)); do wsk -i action invoke dice-demo-throw -p path $LOCAL_ADDRESS:8080/data/ -b || break ; done

# check 'wsk -i activation list' to observe triggers are fired and actions are invoked
# the visualization script takes some time esp. on first activation
# there is a convenience script to download results from cmd line 
# Warning: previewing .dat file might trouble GUI based tools, use cmd-line tools like head, tail, less
# $DEMO_HOME/dice-game/retrieve-images/get-data.sh
# $DEMO_HOME/dice-game/retrieve-images/get-images.sh

# check dCache View: http://localhost:3880/

# read the kafka messages issued by dCache: 
# kafka_2.11-2.0.0/bin/kafka-console-consumer.sh --bootstrap-server localhost:9098 --topic billing-write --from-beginning
# kafka_2.11-2.0.0/bin/kafka-console-consumer.sh --bootstrap-server localhost:9099 --topic billing --from-beginning






