# azure-swarm

Bash scripts for automating creation of a Docker Swarm cluster on Microsoft Azure. There's a blog post from yours truly about this now. Here's where it's at:

> http://blogorama.nerdworks.in/using-docker-swarm-clusters-on-azure/

Before you can run the scripts you'll need to do the following:

1. If you're on Windows, then install Git so that you get the Git Bash console. If you're on Mac/Linux, well, you already have bash.
2. Install [Node.js](https://nodejs.org/en/) using your favorite method. I myself like [Node Version Manager](https://github.com/creationix/nvm) (NVM) to manage my node.js versions (there's a [Windows version](https://github.com/coreybutler/nvm-windows) available too).
3. Install [Git](http://www.git-scm.com/) if you don't have it already. 
4. Install **json** from [NPM](https://www.npmjs.com/package/json) from a terminal like so: **npm install -g json**
5. Install the Azure CLI like so: **npm install -g azure-cli**. Configure the Azure CLI with a valid Azure Subscription. If you don't know how to do that then [this handy guide](https://azure.microsoft.com/en-us/documentation/articles/xplat-cli-connect/) should help.
6. Clone this repo somewhere

### Running the scripts

Running the script isn't very hard. To setup a cluster with default [options](https://github.com/avranju/azure-swarm/blob/master/options.sh) (1 *small* master VM and 2 *small* worker node VMs located in "West US") just run this:

```
./swarm-up.sh
```

This will do the following:

1. Generate new SSH keys
2. Create a new storage account and container
3. Create a new Azure virtual network
4. Spin up a VM to run the Swarm Manager service in the virtual network created in step 3
5. Spin up as many worker node VMs as needed (again, in the same virtual network)
6. Create a bunch of files in a folder called *output*.

If everything goes well you should have a Docker Swarm cluster of your own with everything hooked up.

### Output files

Each run of the script is identified by a randomly generated 8 character long hex string. For e.g. you might get this: **35f8fa98**. A file containing this ID is produced in the *output* folder. For instance, for the ID **35f8fa98**, the file would be called **swarm-35f8fa98.deployment**. You'll see in a bit why this is important.

Another file that you'll be interested in is a file containing SSH cofiguration information. For the same deployment ID as before, this file will be called **ssh-35f8fa98.config**. You can use this file to SSH into any of the VMs. For example, to SSH into the *swarm-master* VM, you'd run the following command:

```
ssh -F output/ssh-35f8fa98.config swarm-master
```

The same command will work for any of the worker node VMs (just change *swarm-master* to *swarm-00* or *swarm-01* and so forth).

### Tearing down the cluster

The whole *deployment ID* shebang that I described above pays off when it comes to tearing down everything because having a deployment ID allows us to cleanly delete the deployment. Continuing with the same deployment ID as before, bringing a cluster down involves running the following script:

```
./swarm-down.sh output/swarm-35f8fa98.deployment
```

*swarm-down.sh* will attempt to delete everything that *swarm-up.sh* created - virtual network, cloud service, VMs and storage account. This will work even with partially deployed clusters (for e.g. you started running the script and then stopped it mid-way because, well, let's just say you had your reasons) because in that case the script will simply attempt to delete something that doesn't exist which is, well, harmless.

### Customize your deployment

There are a few options that you can customize by editing the value of various variables in the *options.sh* file. Here're the ones you're likely to be interested in:

* `VNET_LOCATION` - The [Azure data center](http://azure.microsoft.com/en-us/regions/) where your VMs will be provisioned. This is "West US" by default.
* `VM_SIZE` - The size of the VMs. Accepts any valid size string that [designates a VM size](http://azure.microsoft.com/en-us/pricing/details/virtual-machines/). This is "Small" by default.
* `VM_IMAGE` - This is the name of the Linux VM image to use. By default this is Ubuntu 14.04 LTS. Ubuntu 15 doesn't work with this script at this point since Ubuntu has switched to *systemd* for running system services from v15 onwards while the script relies on it being *upstart*.
* `VM_USER_NAME` - The SSH user name. "avranju" by default.
* `SWARM_WORKER_NODES` - The number of worker VMs to spin up. This is 2 by default.
