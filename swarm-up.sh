#!/bin/sh

# Before running this script please make sure that you have the following
# installed and setup:
#   [1] OpenSSL
#		[2] Node.js
#		[3] Azure cross platform CLI - you can simply run:
#         sudo npm install azure-cli -g

# randomly generated string used as a prefix for all Azure resource names
NAME_SUFFIX=`node -e 'console.log(require("crypto").randomBytes(4).toString("hex"))'`

# the name of the virtual network in which the VMs will be provisioned
VNET_NAME=swarmvnet-$NAME_SUFFIX

# Azure data center where the cluster will be deployed
VNET_LOCATION="West US"

# VM size to use
VM_SIZE=Small

# name of the cloud service where the VMs will be hosted
CS_NAME=dswarm-$NAME_SUFFIX

# the Ubuntu Linux VM image to be used
VM_IMAGE=b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_3-LTS-amd64-server-20150805-en-us-30GB

# VM user name
VM_USER_NAME=avranju

# number of swarm worker nodes to create
SWARM_WORKER_NODES=3

# SSH keys for the VM
SSH_KEY_FILE=output/swarm-ssh-$NAME_SUFFIX.key
SSH_CERT=output/swarm-ssh-$NAME_SUFFIX.pem
SSH_CONFIG_FILE=output/ssh-$NAME_SUFFIX.config

# create the 'output' folder if it doesn't exist
mkdir -p output

# save the prefix into a file
echo $NAME_SUFFIX > output/swarm-$NAME_SUFFIX.deployment

# generate new ssl key
openssl req -x509 -nodes -newkey rsa:2048 -subj '/O=Microsoft Open Technologies, Inc./L=Redmond/C=US/CN=msopentech.com' -keyout $SSH_KEY_FILE -out $SSH_CERT

# set permissions on key file so ssh is happy
chmod 400 $SSH_KEY_FILE

# create vnet
echo Creating vnet $VNET_NAME
azure network vnet create --location="$VNET_LOCATION" \
	--address-space=172.16.0.0 $VNET_NAME

# create master swarm node
echo Creating docker swarm master node swarm-master
azure vm create -n swarm-master -e 22000 -z $VM_SIZE \
	--virtual-network-name=$VNET_NAME $CS_NAME \
	--ssh-cert=$SSH_CERT --no-ssh-password \
	--custom-data ./cloud-init.sh $VM_IMAGE $VM_USER_NAME

# create worker swarm nodes

SWARM_NODES_TO=`expr $SWARM_WORKER_NODES - 1`
for i in `seq 0 $SWARM_NODES_TO`;
do
	echo Creating docker swarm worker node `printf "swarm-%02d" $i`
	azure vm create -n `printf "swarm-%02d" $i` -e `expr 22001 + $i` -z $VM_SIZE \
		--virtual-network-name=$VNET_NAME $CS_NAME \
		--ssh-cert=$SSH_CERT --no-ssh-password \
		--custom-data ./cloud-init.sh --connect $VM_IMAGE $VM_USER_NAME
done

# create ssh config file
echo "Host swarm-master" > $SSH_CONFIG_FILE
echo "    User $VM_USER_NAME" >> $SSH_CONFIG_FILE
echo "    HostName $CS_NAME.cloudapp.net" >> $SSH_CONFIG_FILE
echo "    Port 22000" >> $SSH_CONFIG_FILE
echo "    IdentityFile ./$SSH_KEY_FILE" >> $SSH_CONFIG_FILE
echo "    StrictHostKeyChecking no" >> $SSH_CONFIG_FILE

for i in `seq 0 $SWARM_NODES_TO`;
do
	HOST_PORT=`expr 22001 + $i`
	echo `printf "Host swarm-%02d" $i` >> $SSH_CONFIG_FILE
	echo "    User $VM_USER_NAME" >> $SSH_CONFIG_FILE
	echo "    HostName $CS_NAME.cloudapp.net" >> $SSH_CONFIG_FILE
	echo "    Port $HOST_PORT" >> $SSH_CONFIG_FILE
	echo "    IdentityFile ./$SSH_KEY_FILE" >> $SSH_CONFIG_FILE
	echo "    StrictHostKeyChecking no" >> $SSH_CONFIG_FILE	
done
