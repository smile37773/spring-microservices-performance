#!/usr/bin/env bash

# CONSTRUCT SECOND INSTANCE of AZURE SPRING CLOUD ===

# ==== Create Resource Group ====
az group create --name ${RESOURCE_GROUP} \
    --location ${REGION}

az group lock create --lock-type CanNotDelete --name DoNotDelete \
    --notes For-Asir \
    --resource-group ${RESOURCE_GROUP}

az configure --defaults \
    group=${RESOURCE_GROUP} \
    location=${REGION} \
    spring-cloud=${SPRING_CLOUD_SERVICE_02}

# ==== Create Azure Spring Cloud ====
az spring-cloud create --name ${SPRING_CLOUD_SERVICE_02} \
    --resource-group ${RESOURCE_GROUP} \
    --location ${REGION}

# ==== Apply Config ====
az spring-cloud config-server set \
    --config-file application.yml \
    --name ${SPRING_CLOUD_SERVICE_02} \
    --resource-group ${RESOURCE_GROUP}

# ==== Create the gateway app ====
az spring-cloud app create --name gateway --instance-count 1 --is-public true \
    --memory 2 \
    --jvm-options='-Xms2048m -Xmx2048m -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:+UseG1GC -Djava.awt.headless=true' \
    --resource-group ${RESOURCE_GROUP} \
    --service ${SPRING_CLOUD_SERVICE_02}

# ==== Create the greeting-service app ====
az spring-cloud app create --name greeting-service --instance-count 1 \
    --memory 2 \
    --jvm-options='-Xms2048m -Xmx2048m -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:+UseG1GC -Djava.awt.headless=true' \
    --resource-group ${RESOURCE_GROUP} \
    --service ${SPRING_CLOUD_SERVICE_02}

# ==== Build for cloud ====
mvn clean package -DskipTests -Denv=cloud

# ==== Deploy apps ====
az spring-cloud app deploy --name gateway \
    --jar-path ${GATEWAY_JAR} \
    --resource-group ${RESOURCE_GROUP} \
    --service ${SPRING_CLOUD_SERVICE_02}

az spring-cloud app deploy --name greeting-service \
    --jar-path ${GREETING_SERVICE_JAR} \
    --resource-group ${RESOURCE_GROUP} \
    --service ${SPRING_CLOUD_SERVICE_02}

# ==== Scale apps ====
az spring-cloud app scale --name gateway --instance-count 16 \
    --resource-group ${RESOURCE_GROUP} \
    --service ${SPRING_CLOUD_SERVICE_02}

az spring-cloud app scale --name greeting-service --instance-count 16 \
    --resource-group ${RESOURCE_GROUP} \
    --service ${SPRING_CLOUD_SERVICE_02}

