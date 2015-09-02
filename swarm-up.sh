#!/bin/bash

# Before running this script please make sure that you have the following
# installed and setup:
#
#   [1] OpenSSL
#	[2] Node.js
#	[3] Azure cross platform CLI - you can simply run:
#         sudo npm install -g azure-cli
#	[4] JSON CLI parser. Install with:
#		  sudo npm install -g json
#
# And if you're on Windows you'll need a bash shell. I've used the Git bash
# with great success.

# randomly generated string used as a prefix for all Azure resource names
NAME_SUFFIX=`node -e 'console.log(require("crypto").randomBytes(4).toString("hex"))'`

# include options.sh for all the variables
source ./options.sh

# include utils.sh
source ./utils.sh

# create the 'output' folder if it doesn't exist
mkdir -p output

# save the prefix into a file
echo $NAME_SUFFIX > output/swarm-$NAME_SUFFIX.deployment

# generate new ssl key; this needs to be run with slightly
# different syntax if we're on Windows in a MINGW bash; if
# check below taken from: http://stackoverflow.com/a/31990313/8080
if [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
	openssl req -x509 -nodes -newkey rsa:2048 -subj '//O=Microsoft Open Technologies, Inc.\L=Redmond\C=US\CN=msopentech.com' -keyout $SSH_KEY_FILE -out $SSH_CERT
else
	openssl req -x509 -nodes -newkey rsa:2048 -subj '/O=Microsoft Open Technologies, Inc./L=Redmond/C=US/CN=msopentech.com' -keyout $SSH_KEY_FILE -out $SSH_CERT
fi

# set permissions on key file so ssh is happy
chmod 400 $SSH_KEY_FILE

# create storage account
printmsg "Creating storage account $STORAGE_ACCOUNT_NAME"
azure storage account create -l "$VNET_LOCATION" --type LRS $STORAGE_ACCOUNT_NAME

# fetch storage account key
printmsg "Getting storage account key for $STORAGE_ACCOUNT_NAME"
STORAGE_KEY=`azure storage account keys list $STORAGE_ACCOUNT_NAME --json | json -a primaryKey`

# create a container for vhds
printmsg "Creating container 'vhds' in storage account $STORAGE_ACCOUNT_NAME"
azure storage container create -a $STORAGE_ACCOUNT_NAME -k $STORAGE_KEY vhds

# create vnet
printmsg "Creating vnet $VNET_NAME"
azure network vnet create --location="$VNET_LOCATION" \
	--address-space=172.16.0.0 $VNET_NAME

# create master swarm node
printmsg "Creating docker swarm master node swarm-master"
azure vm create -n swarm-master -e 22000 -z $VM_SIZE \
	--virtual-network-name=$VNET_NAME $CS_NAME \
	--ssh-cert=$SSH_CERT --no-ssh-password \
	--custom-data ./cloud-init.sh $VM_IMAGE $VM_USER_NAME \
	-u https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/vhds/swarm-master-$NAME_SUFFIX.vhd

# create worker swarm nodes
SWARM_NODES_TO=`expr $SWARM_WORKER_NODES - 1`
for i in `seq 0 $SWARM_NODES_TO`;
do
	printmsg "Creating docker swarm worker node `printf "swarm-%02d" $i`"
	azure vm create -n `printf "swarm-%02d" $i` -e `expr 22001 + $i` -z $VM_SIZE \
		--virtual-network-name=$VNET_NAME $CS_NAME \
		--ssh-cert=$SSH_CERT --no-ssh-password \
		--custom-data ./cloud-init.sh --connect $VM_IMAGE $VM_USER_NAME \
		-u https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/vhds/`printf "swarm-%02d-$NAME_SUFFIX" $i`.vhd
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

# create the swarm cluster
/bin/bash ./create-cluster.sh output/swarm-$NAME_SUFFIX.deployment
