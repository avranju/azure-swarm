#!/bin/bash

# the name of the virtual network in which the VMs will be provisioned
VNET_NAME=swarmvnet-$NAME_SUFFIX

# Azure data center where the cluster will be deployed
VNET_LOCATION="West US"

# VM size to use
VM_SIZE=Small

# name of the cloud service where the VMs will be hosted
CS_NAME=dswarm-$NAME_SUFFIX

# name of the storage account to use
STORAGE_ACCOUNT_NAME=dswarm$NAME_SUFFIX

# the Ubuntu Linux VM image to be used
VM_IMAGE=b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_3-LTS-amd64-server-20150805-en-us-30GB

# VM user name
VM_USER_NAME=avranju

# number of swarm worker nodes to create
SWARM_WORKER_NODES=2

# SSH keys for the VM
SSH_KEY_FILE=output/swarm-ssh-$NAME_SUFFIX.key
SSH_CERT=output/swarm-ssh-$NAME_SUFFIX.pem
SSH_CONFIG_FILE=output/ssh-$NAME_SUFFIX.config
