FROM wurstmeister/kafka

RUN mkdir /opt/streams && mkdir /opt/files
RUN apk add --no-cache maven
COPY maven-generate.sh /opt/streams
RUN chmod +x /opt/streams/maven-generate.sh

