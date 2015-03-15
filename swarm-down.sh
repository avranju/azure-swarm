#!/bin/sh

# script parameters
VNET_NAME=swarmvnet
VNET_LOCATION="Southeast Asia"
VM_SIZE=Small
CS_NAME=nerdswarm
VM_IMAGE=b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_10-amd64-server-20150202-en-us-30GB

# remove ssh keys
rm -f swarm-ssh.key 2> /dev/null
rm -f swarm-ssh.pem 2> /dev/null

# remove cached ssh keys
ssh-keygen -R [$CS_NAME.cloudapp.net]:22000 -f ~/.ssh/known_hosts
ssh-keygen -R [$CS_NAME.cloudapp.net]:22001 -f ~/.ssh/known_hosts
ssh-keygen -R [$CS_NAME.cloudapp.net]:22002 -f ~/.ssh/known_hosts
ssh-keygen -R [$CS_NAME.cloudapp.net]:22003 -f ~/.ssh/known_hosts

# delete ssh config file
rm ssh.config 2> /dev/null

# delete vms
azure vm delete -q swarm-master
azure vm delete -q swarm-00
azure vm delete -q swarm-01
azure vm delete -q swarm-02

# delete cloud service
azure service delete -q $CS_NAME

# delete vnet
azure network vnet delete -q swarmvnet
