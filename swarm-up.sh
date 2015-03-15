#!/bin/sh

# Before running this script please make sure that you have the following
# installed and setup:
#   [1] OpenSSL
#		[2] Node.js
#		[3] Azure cross platform CLI - you can simply run:
#         sudo npm install azure-cli -g

# script parameters
VNET_NAME=swarmvnet
VNET_LOCATION="Southeast Asia"
VM_SIZE=Small
CS_NAME=nerdswarm
VM_IMAGE=b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_10-amd64-server-20150202-en-us-30GB
VM_USER_NAME=avranju

# generate new ssl key
openssl req -x509 -nodes -newkey rsa:2048 -subj '/O=Microsoft Open Technologies, Inc./L=Redmond/C=US/CN=msopentech.com' -keyout swarm-ssh.key -out swarm-ssh.pem

# set permissions on key file so ssh is happy
chmod 400 swarm-ssh.key

# remove old cached ssh key from ~/.ssh/known_hosts to avoid warning
# when sshing later
ssh-keygen -R [$CS_NAME.cloudapp.net]:22000 -f ~/.ssh/known_hosts
ssh-keygen -R [$CS_NAME.cloudapp.net]:22001 -f ~/.ssh/known_hosts
ssh-keygen -R [$CS_NAME.cloudapp.net]:22002 -f ~/.ssh/known_hosts
ssh-keygen -R [$CS_NAME.cloudapp.net]:22003 -f ~/.ssh/known_hosts

# create vnet
#azure network vnet create --location="$VNET_LOCATION" --address-space=172.16.0.0 $VNET_NAME

# create master swarm node
azure vm create -n swarm-master -e 22000 -z $VM_SIZE --virtual-network-name=$VNET_NAME $CS_NAME --ssh-cert=swarm-ssh.pem --no-ssh-password --custom-data ./cloud-init.sh $VM_IMAGE $VM_USER_NAME

# create worker swarm nodes
azure vm create -n swarm-00 -e 22001 -z $VM_SIZE --virtual-network-name=$VNET_NAME $CS_NAME --ssh-cert=swarm-ssh.pem --no-ssh-password --custom-data ./cloud-init.sh --connect $VM_IMAGE $VM_USER_NAME

azure vm create -n swarm-01 -e 22002 -z $VM_SIZE --virtual-network-name=$VNET_NAME $CS_NAME --ssh-cert=swarm-ssh.pem --no-ssh-password --custom-data ./cloud-init.sh --connect $VM_IMAGE $VM_USER_NAME

azure vm create -n swarm-02 -e 22003 -z $VM_SIZE --virtual-network-name=$VNET_NAME $CS_NAME --ssh-cert=swarm-ssh.pem --no-ssh-password --custom-data ./cloud-init.sh --connect $VM_IMAGE $VM_USER_NAME

# create ssh config file
echo "Host swarm-master" > ssh.config
echo "    User $VM_USER_NAME" >> ssh.config
echo "    HostName $CS_NAME.cloudapp.net" >> ssh.config
echo "    Port 22000" >> ssh.config
echo "    IdentityFile ./swarm-ssh.key" >> ssh.config
echo "    StrictHostKeyChecking no" >> ssh.config

echo "Host swarm-00" >> ssh.config
echo "    User $VM_USER_NAME" >> ssh.config
echo "    HostName $CS_NAME.cloudapp.net" >> ssh.config
echo "    Port 22001" >> ssh.config
echo "    IdentityFile ./swarm-ssh.key" >> ssh.config
echo "    StrictHostKeyChecking no" >> ssh.config

echo "Host swarm-01" >> ssh.config
echo "    User $VM_USER_NAME" >> ssh.config
echo "    HostName $CS_NAME.cloudapp.net" >> ssh.config
echo "    Port 22002" >> ssh.config
echo "    IdentityFile ./swarm-ssh.key" >> ssh.config
echo "    StrictHostKeyChecking no" >> ssh.config

echo "Host swarm-02" >> ssh.config
echo "    User $VM_USER_NAME" >> ssh.config
echo "    HostName $CS_NAME.cloudapp.net" >> ssh.config
echo "    Port 22003" >> ssh.config
echo "    IdentityFile ./swarm-ssh.key" >> ssh.config
echo "    StrictHostKeyChecking no" >> ssh.config











