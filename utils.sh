#!/bin/bash

COLOR_HIGHLIGHT='\033[1;33m'
COLOR_NONE='\033[0m'

function printmsg {
	if [ -n "$1" ];
	then
		printf "${COLOR_HIGHLIGHT}$1${COLOR_NONE}\n"
	fi
}

function waitVMReadyRole {
	_VM_NAME=$1
	_DNS_NAME=$2
	
	_VM_STATUS=`azure vm show -d $_DNS_NAME $_VM_NAME --json | json -a InstanceStatus`
	while [ "$_VM_STATUS" != "ReadyRole" ]
	do
		printmsg "Waiting for VM $_VM_NAME to tranisition to ReadyRole from $_VM_STATUS..."
		sleep 3
		_VM_STATUS=`azure vm show -d $_DNS_NAME $_VM_NAME --json | json -a InstanceStatus`
	done
	
	printmsg "VM $_VM_NAME is now ready."
}

function waitVMDelete {
	_VM_NAME=$1
	_DNS_NAME=$2

	_VM_STATUS=`azure vm show -d $_DNS_NAME $_VM_NAME --json`
	while [ "$_VM_STATUS" != "No VMs found" ]
	do
		printmsg "Waiting for VM $_VM_NAME to be deleted..."
		sleep 3
		_VM_STATUS=`azure vm show -d $_DNS_NAME $_VM_NAME --json`
	done
}

