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
* After creating the VM add a second and third interface on the openvswitch bridge
  * Select the VM -> Hardware -> Add -> Network Device -> Bridge (select the name of the bridge created previously)
  * Disable the Firewall under the "advanced" options
* Minimal install, with SSH server
* Install curl (as root or with sudo)
  ```bash
  apt install curl gnupg
  ```
* Install inetsim
  * Follow these directions https://www.inetsim.org/packages.html
* Run ip addr and find the name of the second interface. The interface should say "DOWN" and not have an IP address. In my case it was ens19 and ens20.
* Setup static IP for ens19
  * Add the following to /etc/network/interfaces using your favoriate editor. Replacing the IP and ens interfaces as necessary.
  ```
  auto ens19
  iface ens19 inet static
    address 10.0.1.2/24
    
  auto ens20
  iface ens20 inet manual
    up ip link set ens20 promisc on
    
  auto decrypted
  iface decrypted inet manual
    pre-up ip link add decrypted type dummy
    up ip link set decrypted arp off up
  ```
* Update "service_bind_address" and "dns_default_ip" to 10.0.1.2 in /etc/inetsim/inetsim.conf
* If you want to use polarproxy (ssl decryption) comment out the line "start_service https"
* Starting inetsim (as root or with sudo)
```bash
systemctl start inetsim
systemctl enable inetsim
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
  cp ~/PolarProxy/PolarProxy.service /etc/systemd/system/PolarProxy.service
  ```
  * Update ```/etc/systemd/system/PolarProxy.service``` 
    * The location of the binary and who to run the service as
    * Update ExecStart
      * -p from ```10443,80,443``` to ```443,80,80```
      * Remove the -o variable and the path assuming you don't want it to write out pcaps
      * Add
        * ```--terminate --connect 10.0.1.2 -nosni nosni.inetsim.org --pcapoverip 57102```
  ```bash
  mkdir /var/log/PolarProxy
  systemctl daemon-reload
  systemctl start PolarProxy
  systemstl enable PolarProxy
  ```
* Install tcpreplay
  ```bash
  apt install tcpreplay
  ```
* Run tcpreplay
  * Create ```/etc/systemd/system/tcpreplay.service``` with the following content
```
[Unit]
Description=Tcpreplay of decrypted traffic from PolarProxy
After=PolarProxy.service

[Service]
Type=simple
ExecStart=/bin/sh -c 'nc localhost 57102 | tcpreplay -i decrypted -t -'
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
```
  * Enable/Start tcpreplay
  ```bash
  systemctl daemon-reload
  systemctl start tcpreplay
  systemctl enable tcpreplay
  ```
* Install Zeek
  ```bash
  echo 'deb http://download.opensuse.org/repositories/security:/zeek/Debian_10/ /' | tee /etc/apt/sources.list.d/security:zeek.list
  curl -fsSL https://download.opensuse.org/repositories/security:zeek/Debian_10/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
  apt update
  apt install zeek
  ```
* Configure Zeek
  * Edit `/opt/zeek/etc/node.cfg` and setup multiple workers for the multiple interfaces
    * Comment out the [zeek] section, Uncomment out the other sections, updating the two workers for the proper interfaces.
  ```
  #[zeek]
  #type=standalone
  #host=localhost
  #interface=ens20
  ```

  ```
  [logger-1]
  type=logger
  host=localhost
  #
  [manager]
  type=manager
  host=localhost
  #
  [proxy-1]
  type=proxy
  host=localhost
  #
  [worker-1]
  type=worker
  host=localhost
  interface=decrypted
  #
  [worker-2]
  type=worker
  host=localhost
  interface=ens20
  ```
  * Change zeek logs to be json formated
  ```bash
  cat "@load tuning/json-logs" >> /opt/zeek/share/zeek/site/local.zeek
  ```
  * Setup ```/etc/systemd/system/zeek.service``` with the following
  ```
  Description=Zeek NSM Engine
  After=network.target
  
  [Service]
  Type=forking
  ExecStartPre=/opt/zeek/bin/zeekctl config
  ExecStartPre=/opt/zeek/bin/zeekctl install
  ExecStart=/opt/zeek/bin/zeekctl start
  ExecStop=/opt/zeek/bin/zeekctl stop
  
  [Install]
  WantedBy=multi-user.target
  ```
  * Start/Enable Zeek
  ```bash
  systemctl daemon-reload
  systemctl start zeek
  systemctl enable zeek
  ```
  
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