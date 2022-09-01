# threathunt-lab

# Proxmox Threat Hunting Lab

## Goal
Create an environment that can be to learn/test threat hunting processes and procedures. That can be done within an isolated environment.
	
## Requirements
Proxmox
Familiarty with the commandline
Familiarty with Packer and Terraform
Debian ISO
	
## Setup
Most of this could be done with Security Onion if you wanted.
	
This likely could also be done on a single host but would need more zeek experense that I have, as capturing the loopback interface is required and running zeek in cluster mode there is some extra logs that needs to be filtered.

### Easier way:
* Based off the ideas https://github.com/clong/DetectionLab with help from https://github.com/xcad2k/boilerplates
* So far this will just create template using packer of either Ubuntu 20.04 or Debian 11. From there it is possible to use terraform deploy the VMs.

### Packer
Install packer from Hashicorp directions https://learn.hashicorp.com/tutorials/packer/get-started-install-cli

This will also require the machine you run packer to be able to recieve connections from the VM it setups.

Using the provided packer config files it will build templates within Proxmox that can be used with cloud-init to clone and setup username, password, ssh keys and network information.

Rename (or edit if you aren't commiting to source control) packer/credentials.pkr.hcl.sample. Update the variables as needed, this will require having an API token. If you do not want to give this token/user full access it needs the following permissions:
* VM.Config.HWType
* VM.Config.CDROM
* VM.Monitor
* Datastore.AllocateSpace
* VM.Console
* VM.Snapshot.Rollback
* VM.Config.Cloudinit
* VM.Config.Options
* VM.Config.Disk
* VM.Allocate
* VM.Config.Network
* VM.PowerMgmt
* VM.Audit
* VM.Snapshot
* VM.Migrate
* VM.Backup
* VM.Config.CPU
* VM.Clone
* Datastore.Audit
* VM.Config.Memory

With the packer installed and credentials file updated from either (or both) of the packer/debian-bullseye or packer/ubuntu-server-focal and run ```packer build -var-file=../credentials.pkr.hcl debian-bullseye.pkr.hcl``` or ```packer build -var-file=../credentials.pkr.hcl ubuntu-server-focal.pkr.hcl```.

### Terraform
Install terraform from Hashicorp directions https://www.terraform.io/downloads

Rename (or edit if you aren't commiting to source control) terraform/credentials.auto.tfvars.sample. Update the variables as needed, this will require having an API token. The API token need similar permissions to the packer token.

Update/copy full-clone.tf to build the VMs you want. The following fields would need to be update:
* node-name (name of the proxmox node)
* vm-name
* clone-name (this is the name of the template in proxmox)

Optionally you can setup the following fields
* ciuser (create a new user)
* sshkeys (ssh key for the new user)
* ipconfig (default will be dhcp)


You will need to run ```terraform init``` from the terraform directory to pull in the needed proxmox provider, then ```terraform plan``` to see what will happen and finally ```terraform deploy``` to deploy the a VM. This will build through the process of setting up PolarProxy, InetSim and TCPReplay.

## Manual Directions

These are the steps that aren't ran by terraform if you want to see the full manual steps see [MANUAL.md](MANUAL.mda)

### Proxmox:
* Leave the default Linux Bridge
* Create a OVS Bridge

  * Select the proxmox host->network->Create->OVS Bridge
  * Leave Bridge Ports empty, this does mean this bridge won't have access to the broader network, but will keep your work isolated
  * Make note of the bridge name as it will be needed in the future
	
### VM1:
* After running the ```terraform apply``` command you will stand up the first VM with InetSim, PolarProxy and Zeek.
  
### Proxmox:

This will setup the port mirror, this can't be ran until after creating VM1. This also won't survive reboots according to reports. You will need to find the VMID for VM1 as well (if it is the second VM created the VMID will be 101). You will also need to know the number of the interface you are using as the monitor interface. If following along the interface is number 2, since it is the 3rd interface and the count starts at 0.

* ssh to Proxmox
```bash
ovs-vsctl -- --id=@p get port tap<vmid>i<interface# on device> -- --id=@m create mirror name=span1 select-all=true output-port=@p -- set bridge <bridge name from previously> mirrors=@m
```
Example:
```bash
ovs-vsctl -- --id=@p get port tap101i2 -- --id=@m create mirror name=span1 select-all=true output-port=@p -- set bridge vmbr1 mirrors=@m
```

# References
* https://www.netresec.com/?page=Blog&tag=Pcap-over-IP
* https://www.netresec.com/?page=Blog&month=2020-01&post=Sniffing-Decrypted-TLS-Traffic-with-Security-Onion
* https://santosomar.medium.com/security-onion-redhunt-os-proxmox-and-open-vswitch-6d6fbaaf0a51
* https://holdmybeersecurity.com/2020/10/03/creating-a-windows-10-64-bit-vm-on-proxmox-with-packer-v1-6-3-and-vault/ (Windows Packer)