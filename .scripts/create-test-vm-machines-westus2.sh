#!/usr/bin/env bash


# CONSTRUCT CLIENT TEST MACHINES ===

# ==== Create Resource Group ====
az group create --name ${TEST_VM_RESOURCE_GROUP} \
    --location ${REGION}

# ==== Place a delete lock ====
az group lock create --lock-type CanNotDelete --name DoNotDelete \
    --notes For-Asir \
    --resource-group ${TEST_VM_RESOURCE_GROUP}

# ==== Create network resources VNET, Subnets, NSG and NICs ====

az network vnet create \
    --resource-group ${TEST_VM_RESOURCE_GROUP} \
    --name ${TEST_VNET} \
    --address-prefix 10.0.0.0/16 \
    --subnet-name ${TEST_SUBNET_BACKEND} \
    --subnet-prefix 10.0.1.0/24

az network nsg create \
    --resource-group ${TEST_VM_RESOURCE_GROUP} \
    --name ${TEST_NSG}

az network public-ip create \
    --name ${TEST_VM_ONE_SSH_IP_ADDRESS_01} \
    --resource-group ${TEST_VM_RESOURCE_GROUP} \
    --allocation-method Static \
    --sku Standard

az network public-ip create \
    --name ${TEST_VM_TWO_SSH_IP_ADDRESS_02} \
    --resource-group ${TEST_VM_RESOURCE_GROUP} \
    --allocation-method Static \
    --sku Standard

az network public-ip create \
    --name ${TEST_VM_TWO_SSH_IP_ADDRESS_03} \
    --resource-group ${TEST_VM_RESOURCE_GROUP} \
    --allocation-method Static \
    --sku Standard

az network nic create \
    --resource-group ${TEST_VM_RESOURCE_GROUP} \
    --name myNic1BE \
    --vnet-name ${TEST_VNET} \
    --subnet ${TEST_SUBNET_BACKEND} \
    --network-security-group ${TEST_NSG} \
    --public-ip-address ${TEST_VM_ONE_SSH_IP_ADDRESS_01}

az network nic create \
    --resource-group ${TEST_VM_RESOURCE_GROUP} \
    --name myNic2BE \
    --vnet-name ${TEST_VNET} \
    --subnet ${TEST_SUBNET_BACKEND} \
    --network-security-group ${TEST_NSG} \
    --public-ip-address ${TEST_VM_TWO_SSH_IP_ADDRESS_02}

az network nic create \
    --resource-group ${TEST_VM_RESOURCE_GROUP} \
    --name myNic3BE \
    --vnet-name ${TEST_VNET} \
    --subnet ${TEST_SUBNET_BACKEND} \
    --network-security-group ${TEST_NSG} \
    --public-ip-address ${TEST_VM_TWO_SSH_IP_ADDRESS_03}

az vm create \
    --resource-group ${TEST_VM_RESOURCE_GROUP} \
    --name ${TEST_VM_1} \
    --image UbuntuLTS \
    --size Standard_D4s_v3 \
    --admin-username selvasingh \
    --generate-ssh-keys \
    --nics myNic1BE \
    --location ${REGION}

az vm create \
    --resource-group ${TEST_VM_RESOURCE_GROUP} \
    --name ${TEST_VM_2} \
    --image UbuntuLTS \
    --size Standard_D4s_v3 \
    --admin-username selvasingh \
    --generate-ssh-keys \
    --nics myNic2BE \
    --location ${REGION}

az vm create \
    --resource-group ${TEST_VM_RESOURCE_GROUP} \
    --name ${TEST_VM_3} \
    --image UbuntuLTS \
    --size Standard_D4s_v3 \
    --admin-username selvasingh \
    --generate-ssh-keys \
    --nics myNic3BE \
    --location ${REGION}

# ==== Configure Guest OS for multiple NICs ====

az network nsg rule create \
    --resource-group ${TEST_VM_RESOURCE_GROUP} \
    --nsg-name ${TEST_NSG} \
    --name allow_ssh \
    --priority 100 \
    --destination-port-ranges 22


# ==== Log into Linux virtual machine ====

ssh selvasingh@${TEST_VM_ONE}
ssh selvasingh@${TEST_VM_TWO}
ssh selvasingh@${TEST_VM_THREE}

# ==== Check Internet Bandwidth =====
sudo snap install fast
# download speed
fast

sudo apt install speedtest-cli
# both download and upload

speedtest

# ==== Install wrk ====
sudo apt-get install build-essential libssl-dev git -y
git clone https://github.com/wg/wrk.git wrk
cd wrk
make
# move the executable to somewhere in your PATH, ex:
sudo cp wrk /usr/local/bin

# ==== Install Cron ====
# Before installing cron on an Ubuntu machine, update the computer’s local package index:

sudo apt update
# Then install cron with the following command:

sudo apt install cron
#You’ll need to make sure it’s set to run in the background too:

sudo systemctl enable cron

# ==== Create a command to execute tests ====
cd
mkdir tests
cd tests

mkdir app-service
mkdir spring-cloud

sudo nano command-azure-app-service.sh
/usr/local/bin/wrk -t12 -c400 -d600s --latency \
    https://spring-boot-javase-performance.azurewebsites.net \
    > /home/selvasingh/tests/app-service/performance-spring-ms-azure-app-service-$(date +%y%m%d_%H%M%S).txt 2>&1

sudo nano command-azure-spring-cloud.sh
/usr/local/bin/wrk -t12 -c400 -d600s --latency \
    https://spring-ms-perf-westus2-05-2020-gateway.azuremicroservices.io/greeting/hello/world \
    > /home/selvasingh/tests/spring-cloud/performance-spring-ms-azure-spring-cloud-$(date +%y%m%d_%H%M%S).txt 2>&1

sudo chmod 757 command*

# ==== Create a cron job ====

crontab -e
# Edit this file to introduce tasks to be run by cron.
#
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
#
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').#
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
#
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
#
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# For more information see the manual pages of crontab(5) and cron(8)
#
# m h  dom mon dow   command
0,30 * * * * /home/selvasingh/tests/command-azure-spring-cloud.sh
15,45 * * * * /home/selvasingh/tests/command-azure-app-service.sh

# ==== view cron job ====
crontab -l


# ==== extended story ====

mkdir spring-cloud-32

sudo nano command-azure-spring-cloud-32.sh
/usr/local/bin/wrk -t12 -c400 -d600s --latency \
    https://spring-ms-perf-westus2-05-2020-2-gateway.azuremicroservices.io/greeting/hello/32 \
    > /home/selvasingh/tests/spring-cloud-32/performance-spring-ms-azure-spring-cloud-32-$(date +%y%m%d_%H%M%S).txt 2>&1

sudo chmod 757 command-azure-spring-cloud-32.sh

crontab -e

# Edit this file to introduce tasks to be run by cron.
#
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
#
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').#
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
#
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
#
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# For more information see the manual pages of crontab(5) and cron(8)
#
# m h  dom mon dow   command
12,24,48 * * * * /home/selvasingh/tests/command-azure-spring-cloud.sh
0,48 * * * * /home/selvasingh/tests/command-azure-app-service.sh
36 * * * * /home/selvasingh/tests/command-azure-spring-cloud-32.sh