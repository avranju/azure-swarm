#!/bin/bash

# check that deployment file name is passed in
if [ -z "$1" ];
then
	echo "Please pass in the deployment file name"
	exit 1
fi

# deployment id is passed as a command line param
NAME_SUFFIX=`cat $1`

# ssh configuration file
SSH_CONFIG_FILE=output/ssh-$NAME_SUFFIX.config

# number of swarm worker nodes
SWARM_WORKER_NODES=3

# create the cluster id
echo Creating swarm cluster ID

# make sure that the swarm image has been pulled into docker
ssh -F $SSH_CONFIG_FILE swarm-master "docker -H=0.0.0.0:2375 pull swarm"

# create a swarm cluster id
SWARM_CLUSTER_ID=`ssh -F $SSH_CONFIG_FILE swarm-master "docker -H=0.0.0.0:2375 run --rm swarm create"`
echo Created swarm cluster token://$SWARM_CLUSTER_ID

# join each node to the cluster
SWARM_NODES_TO=`expr $SWARM_WORKER_NODES - 1`
for i in `seq 0 $SWARM_NODES_TO`;
do
	echo Joining `printf "swarm-%02d" $i` to cluster
	ssh -F $SSH_CONFIG_FILE `printf "swarm-%02d" $i` \
		"docker -H=0.0.0.0:2375 run -d swarm join "\
		"--addr=\`ifconfig eth0 | grep 'inet add r :' "\
		"| cut -d: -f2 | awk '{ print $1}'\`:2375 token://$SWARM_CLUSTER_ID"
done

echo Running swarm manager on the master node
ssh -F $SSH_CONFIG_FILE swarm-master docker -H=0.0.0.0:2375 run -d -p 2377:2375 swarm manage token://$SWARM_CLUSTER_ID
