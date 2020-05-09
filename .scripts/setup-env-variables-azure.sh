#!/usr/bin/env bash

# ==== Resource Group ====
export RESOURCE_GROUP=spring-microservices-performance-05-2020-test
export REGION=westus2

# ==== First Instance ====
export SPRING_CLOUD_SERVICE_01=spring-ms-perf-westus2-05-2020
export SPRING_CLOUD_SERVICE_02=spring-ms-perf-westus2-05-2020-2

# ==== JARS ====
export GREETING_SERVICE_JAR=greeting-service/target/greeting-service-1.0.0.jar
export GATEWAY_JAR=gateway/target/gateway-1.0.0.jar
