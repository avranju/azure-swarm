#!/bin/bash

# include utils.sh
source ./utils.sh

# check that deployment file name is passed in
if [ -z "$1" ];
then
	printmsg "Please pass in the deployment file name"
	exit 1
fi

# deployment id is passed as a command line param
NAME_SUFFIX=`cat $1`

# ssh configuration file
SSH_CONFIG_FILE=output/ssh-$NAME_SUFFIX.config

# number of swarm worker nodes
SWARM_WORKER_NODES=3

# name of the cloud service where the VMs will be hosted
CS_NAME=dswarm-$NAME_SUFFIX

# create the cluster id
printmsg "Creating swarm cluster ID"

# make sure that the swarm image has been pulled into docker
ssh -F $SSH_CONFIG_FILE swarm-master "docker -H=0.0.0.0:2375 pull swarm"

# create a swarm cluster id
SWARM_CLUSTER_ID=`ssh -F $SSH_CONFIG_FILE swarm-master "docker -H=0.0.0.0:2375 run --rm swarm create"`
printmsg "Created swarm cluster token://$SWARM_CLUSTER_ID"

# join each node to the cluster
SWARM_NODES_TO=`expr $SWARM_WORKER_NODES - 1`
for i in `seq 0 $SWARM_NODES_TO`;
do
	printmsg "Joining `printf "swarm-%02d" $i` to cluster"
	VM_NAME=`printf "swarm-%02d" $i`
	
	# wait for VM to become ready
	waitVMReadyRole $VM_NAME $CS_NAME
	
	EXTRACT_IP="\`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{print \$1}'\`:2375"
	ssh -F $SSH_CONFIG_FILE $VM_NAME \
		"docker -H=0.0.0.0:2375 run -d swarm join --addr=$EXTRACT_IP token://$SWARM_CLUSTER_ID"
done

printmsg "Running swarm manager on the master node"
ssh -F $SSH_CONFIG_FILE swarm-master docker -H=0.0.0.0:2375 run -d -p 2377:2375 swarm manage token://$SWARM_CLUSTER_ID

printmsg "All done. Your Docker Swarm cluster is ready. SSH into your Swarm master VM like so:"
printmsg "ssh -F $SSH_CONFIG_FILE swarm-master"
