git clone https://github.com/apache/incubator-openwhisk-devtools.git
cd incubator-openwhisk-devtools/docker-compose

make download download-cli docker_pull 
#now self-signed certificates are in ~/tmp, optionally add them to system certs
export DOCKER_HOST_IP=localhost
#ToDo consider using LOCAL_ADDRESS here 
make setup start-docker-compose init-couchdb init-whisk-cli init-api-management add-catalog




