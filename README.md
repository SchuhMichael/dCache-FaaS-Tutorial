# dCache-FaaS-Tutorial

The goal of this tutorial is to run a demo that builds on four modules.

1. dCache deployment via Docker Compose
2. Demo to emulate usage of the dCache
3. Kafka Stream Processor to handle messages generated in response to the storage events coming from dCache usage
4. Openwhisk with KafkaFeed and sample actions executed in response to events filtered in the stream processor

# Docker and Docker Compose

Note: Restarting some of the involved containers works and some configurations are persistent. This can cause trouble, when restarting with different LOCAL_ADDRESS setting. From the script, we do not run commands like the following, consider to run them manually. This will stop and rm all containers started for openwhisk and dCache.

In ow/incubator-openwhisk-devtools/docker-compose run 'make destroy'.
In dCache run 'docker-compose down'.


# OpenWhisk

OpenWhisk is a cloud-first distributed event-based programming service. It provides a programming model to upload event handlers to a cloud service, and register the handlers to respond to various events. Learn more at http://openwhisk.incubator.apache.org.

The actions used in this demo run in a CentOS as base image for OpenWhisk Docker Actions using the https://github.com/apache/incubator-openwhisk/tree/master/actionRuntimes/actionProxy. 


