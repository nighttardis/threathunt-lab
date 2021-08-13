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
* When creating this VM leave the network to be the default Linux bridge
	* Disable the Firewall under the "advanced" options, not a requirement but will make things easier
* After creating the VM add a second interface on the openvswitch bridge
  * Select the VM -> Hardware -> Add -> Network Device -> Bridge (select the name of the bridge created previously)
  * Disable the Firewall under the "advanced" options
* Minimal install, with SSH server
* Install curl (as root or with sudo)
  ```bash
  apt install curl
  ```
* Install inetsim
  * Follow these directions https://www.inetsim.org/packages.html
* Run ip addr and find the name of the second interface. The interface should say "DOWN" and not have an IP address. In my case it was ens19.
* Setup static IP for ens19
  * Add the following to /etc/network/interfaces using your favoriate editor. Replacing the IP as necessary.
  ```
  auto ens19
  iface ens19 inet static
    address 10.0.1.2/24
  ```
* Update "service_bind_address" and "dns_default_ip" to 10.0.1.2 in /etc/inetsim/inetsim.conf
* If you want to use polarproxy (ssl decryption) comment out the line "start_service https"
* Starting inetsim (as root or with sudo)
```bash
inetsim
```
* Insall PolarProxy (optional)
  ```bash
  mkdir ~/PolarProxy
  cd ~/PolarProxy/
  curl https://www.netresec.com/?download=PolarProxy | tar -xzf -
  ```
* Starting PolarProxy (as root or with sudo)
  * This will list on port 443, and forward decrypted traffic over port 80 to 10.0.1.2. The cert that polarproxy will generate will be availabe at 10.0.1.2:10080 which can be added to browsers to trust these certs (more info can be found: https://www.netresec.com/?page=PolarProxy). --pcapoverip 10.0.1.2:57102 allows for retreiving the decrypted traffic, this is a hack I'm using to generate traffic across the openvswitch bridge for port mirror.
  ```bash
  cd ~/PolarProxy/
  ./PolarProxy -v -p 443,80,80 --certhttp 10080 --terminate --connect 10.0.1.2 -nosni nosni.inetsim.org --pcapoverip 10.0.1.2:57102
  ```

### VM2:
* OS: Debian
* When creating this VM leave the network to be the default Linux bridge
	* Disable the Firewall under the "advanced" options, not a requirement but will make things easier
* After creating the VM add a second and third interface on the openvswitch bridge
  * Select the VM -> Hardware -> Add -> Network Device -> Bridge (select the name of the bridge created previously)
  * Disable the Firewall under the "advanced" options
* Minimal install, with SSH server
* Run ip addr and find the name of the second interface. The interface should say "DOWN" and not have an IP address. In my case it was ens19 and ens20.
* Setup static IP for ens19
  * Add the following to /etc/network/interfaces using your favoriate editor. Replacing the IP as necessary.
		```
    auto ens19
		  iface ens19 inet static
				address 10.0.1.3/24
    ```
* Setup static IP for ens20 This will be our monitoring interface
  * Add the following to /etc/network/interfaces using your favoriate editor. Replacing the IP as necessary.
  ```
	auto ens20
		iface ens20 inet static
			address 10.0.1.4/24
			up ip link set ens20 promisc on
  ```
  
### Proxmox:

This will setup the port mirror, this can't be ran until after creating VM2. This also won't survive reboots according to reports. You will need to find the VMID for VM2 as well (if it is the second VM created the VMID will be 101). You will also need to know the number of the interface you are using as the monitor interface. If following along the interface is number 2, since it is the 3rd interface and the count starts at 0.

* ssh to Proxmox
```bash
ovs-vsctl -- --id=@p get port tap<vmid>i<interface# on device> -- --id=@m create mirror name=span1 select-all=true output-port=@p -- set bridge <bridge name from previously> mirrors=@m
```
Example:
```bash
ovs-vsctl -- --id=@p get port tap101i2 -- --id=@m create mirror name=span1 select-all=true output-port=@p -- set bridge vmbr1 mirrors=@m
```

At this point VM2 will receive a copy of all traffic going across the the OVS Bridge. If you are running polarproxy and want to also monitor that traffic run
```bash
nc 10.0.1.2 57102 > /dev/null
```
this will pull the traffic across from VM1 and then mirrored to the monitor interface. I haven't completely tested this, so I'm not 100% sure this will work the way I want it.

# References
* https://www.netresec.com/?page=Blog&tag=Pcap-over-IP
* https://www.netresec.com/?page=Blog&month=2020-01&post=Sniffing-Decrypted-TLS-Traffic-with-Security-Onion
* https://santosomar.medium.com/security-onion-redhunt-os-proxmox-and-open-vswitch-6d6fbaaf0a51
