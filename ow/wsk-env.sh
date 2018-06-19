OPENWHISK_HOME=`pwd`/ow/incubator-openwhisk-devtools/docker-compose/openwhisk-master 
OPENWHISK_CLIENT_HOME=$OPENWHISK_HOME/bin \
PATH=$PATH:$OPENWHISK_CLIENT_HOME \
WSK_AUTH_SYS=`cat $OPENWHISK_HOME/ansible/files/auth.whisk.system` \
WSK_AUTH=`cat $OPENWHISK_HOME/ansible/files/auth.guest`

