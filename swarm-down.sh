#!/bin/bash

# check that deployment file name is passed in
if [ -z "$1" ];
then
	printmsg "Please pass in the deployment file name"
	exit 1
fi

# deployment id is passed as a command line param
NAME_SUFFIX=`cat $1`

# include options.sh for all the variables
source ./options.sh

# include utils.sh
source ./utils.sh

# remove ssh keys
rm -f $SSH_KEY_FILE 2> /dev/null
rm -f $SSH_CERT 2> /dev/null

# remove cached ssh keys
for i in `seq 0 $SWARM_WORKER_NODES`;
do
	ssh-keygen -R [$CS_NAME.cloudapp.net]:`expr 22000 + $i` -f ~/.ssh/known_hosts
done

# delete ssh config file
rm $SSH_CONFIG_FILE 2> /dev/null

# delete vms
printmsg "azure vm delete -b -q -d $CS_NAME swarm-master"
azure vm delete -b -q -d $CS_NAME swarm-master

SWARM_NODES_TO=`expr $SWARM_WORKER_NODES - 1`
for i in `seq 0 $SWARM_NODES_TO`;
do
	printmsg "azure vm delete -b -q -d $CS_NAME `printf "swarm-%02d" $i`"
	azure vm delete -b -q -d $CS_NAME `printf "swarm-%02d" $i`
done

# delete cloud service
printmsg "azure service delete -q $CS_NAME"
azure service delete -q $CS_NAME

# delete vnet
printmsg "azure network vnet delete -q $VNET_NAME"
azure network vnet delete -q $VNET_NAME

# wait for VMs to all be deleted before deleting the storage accounts
for i in `seq 0 $SWARM_NODES_TO`;
do
	waitVMDelete `printf "swarm-%02d" $i` $CS_NAME
done

# delete storage account
printmsg "azure storage account delete -q $STORAGE_ACCOUNT_NAME"
azure storage account delete -q $STORAGE_ACCOUNT_NAME
