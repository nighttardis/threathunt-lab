# threathunt-lab

# Proxmox Threat Hunting Lab

## Goal
Create an environment that can be to learn/test threat hunting processes and procedures. That can be done within an isolated environment.
	
## Requirements
Proxmox
Familiarty with the commandline
Debian ISO
	
## Setup
Most of this could be done with Security Onion if you wanted.
	
This likely could also be done on a single host but would need more zeek experense that I have, as capturing the loopback interface is required and running zeek in cluster mode there is some extra logs that needs to be filtered.
	
### Proxmox:
* Leave the default Linux Bridge
* Create a OVS Bridge

  * Select the proxmox host->network->Create->OVS Bridge
  * Leave Bridge Ports empty, this does mean this bridge won't have access to the broader network, but will keep your work isolated
  * Make note of the bridge name as it will be needed in the future
	
### VM1:
* OS: Debian
