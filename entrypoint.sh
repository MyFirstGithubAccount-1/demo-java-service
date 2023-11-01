#!/bin/bash
echo "Executing entrypoint"
echo "Copying /tmp-pre-boot into /tmp"
cp -fr /tmp-pre-boot/. /tmp/
java -javaagent:/app/opentelemetry-javaagent.jar -jar /app/demo-java-service.jar
