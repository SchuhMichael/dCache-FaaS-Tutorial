# dCache-FaaS-Tutorial

The goal of this tutorial is to run a demo that builds on four modules.

1. dCache deployment via Docker Compose
2. Demo to emulate usage of the dCache
3. Kafka Consumer and Kafka Stream Processor to handle messages generated in response to the emulated dCache usage
4. Openwhisk with KafkaFeed and sample actions executed in response to file system events in dCache

# OpenWhisk

OpenWhisk is a cloud-first distributed event-based programming service. It provides a programming model to upload event handlers to a cloud service, and register the handlers to respond to various events. Learn more at http://openwhisk.incubator.apache.org.

We use CentOS as base image for OpenWhisk Docker Actions based on https://github.com/apache/incubator-openwhisk/tree/master/actionRuntimes/actionProxy. To build the image in ow-docker-centos:


```
docker login
#enter Username and Password on hub.docker.com
export DOCKER_USER=<Username on hub.docker.com>
./buildAndPush.sh
```


