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

RUN_CMD_RETRY_COUNT=5

function runCmd {
	_CMD=$1
	_RUN_COUNT=1
	local _STATUS=1
	
	printmsg "Running command: $_CMD"
	while [ $_STATUS != 0 ]
	do
		$_CMD
		
		# if the exit code is not zero then retry
		local _STATUS=$?
		if [[ $_STATUS -ne 0 ]]; then
			_RUN_COUNT=`expr $_RUN_COUNT + 1`
			if [[ $_RUN_COUNT -gt $RUN_CMD_RETRY_COUNT ]]; then
				printmsg "Tried running '$_CMD' $RUN_CMD_RETRY_COUNT times and failed. Giving up!"
				break
			fi

			printmsg "Retrying command $_CMD"
			sleep 3
		fi
	done
}

function runSSHCmd {
	_SSH_CONFIG_FILE=$1
	_VM_NAME=$2
	_CMD=$3
	local _STATUS=1

	printmsg "Running SSH command: $_CMD"	
	while [ $_STATUS != 0 ]
	do
		ssh -F $_SSH_CONFIG_FILE $_VM_NAME $_CMD

		# if the exit code is not zero then retry
		local _STATUS=$?
		if [[ $_STATUS -ne 0 ]]; then
			printmsg "Retrying command $_CMD"
			sleep 3
		fi
	done
}
