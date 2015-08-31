#!/bin/sh

# check that deployment file name is passed in
if [ -z "$1" ];
then
	echo "Please pass in the deployment file name"
	exit 1
fi

# deployment id is passed as a command line param
NAME_SUFFIX=`cat $1`

# script parameters
CS_NAME=nerdswarm-$NAME_SUFFIX
SSH_KEY_FILE=output/swarm-ssh-$NAME_SUFFIX.key
SSH_CERT=output/swarm-ssh-$NAME_SUFFIX.pem
SSH_CONFIG_FILE=output/ssh-$NAME_SUFFIX.config
VNET_NAME=swarmvnet-$NAME_SUFFIX

# number of swarm worker nodes to delete
SWARM_WORKER_NODES=3

# remove ssh keys
rm -f $SSH_KEY_FILE 2> /dev/null
rm -f $SSH_CERT 2> /dev/null

# remove cached ssh keys
ssh-keygen -R [$CS_NAME.cloudapp.net]:22000 -f ~/.ssh/known_hosts
ssh-keygen -R [$CS_NAME.cloudapp.net]:22001 -f ~/.ssh/known_hosts
ssh-keygen -R [$CS_NAME.cloudapp.net]:22002 -f ~/.ssh/known_hosts
ssh-keygen -R [$CS_NAME.cloudapp.net]:22003 -f ~/.ssh/known_hosts

# delete ssh config file
rm $SSH_CONFIG_FILE 2> /dev/null

# delete vms
echo azure vm delete -q swarm-master
azure vm delete -q swarm-master

SWARM_NODES_TO=`expr $SWARM_WORKER_NODES - 1`
for i in `seq 0 $SWARM_NODES_TO`;
do
	echo azure vm delete -q `printf "swarm-%02d" $i`
	azure vm delete -q `printf "swarm-%02d" $i`
done

# delete cloud service
echo azure service delete -q $CS_NAME
azure service delete -q $CS_NAME

# delete vnet
echo azure network vnet delete -q $VNET_NAME
azure network vnet delete -q $VNET_NAME
