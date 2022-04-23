# Proxmox Full-Clone
# ---
# Create a new VM from a clone

variable "packer_ssh_key" {
    type = string
}

variable "proxmox_host" {
    type = string
}

variable "debian_source" {
    type = string
}

variable "ubuntu_source" {
    type = string
}

variable "isolated_network_bridge" {
    type = string
}

variable "public_network_bridge" {
    type = string
}

resource "proxmox_vm_qemu" "debian-inetsim" {
    
    # VM General Settings
    target_node = var.proxmox_host
    vmid = "300"
    name = "debian-inetsim"

    # VM Advanced General Settings
    onboot = false 

    # VM OS Settings
    clone = var.debian_source

    # VM System Settings
    agent = 1
    
    # VM CPU Settings
    cores = 2
    sockets = 1
    cpu = "host"    
    
    # VM Memory Settings
    memory = 2048

    # VM Network Settings
    network {
        bridge = var.public_network_bridge
        model  = "virtio"
    }

    network {
        bridge = var.isolated_network_bridge
        model  = "virtio"
    }

    network {
        bridge = var.isolated_network_bridge
        model  = "virtio"
    }

    lifecycle {
        ignore_changes = [
            network, qemu_os, disk_gb, desc
        ]
    }

    # VM Cloud-Init Settings
    os_type = "cloud-init"

    # (Optional) IP Address and Gateway
    # ipconfig0 = "ip=0.0.0.0/0,gw=0.0.0.0"
    ipconfig1 = "ip=10.0.1.2/24"
    
    # (Optional) Default User
    # ciuser = "user_name"
    
    # (Optional) Add your SSH KEY
    # sshkeys = <<EOF
    # SSH KEY
    # EOF

    connection {
      type = "ssh"
      user = "packer"
      host = self.ssh_host
      private_key = "${file(var.packer_ssh_key)}"
    }

    # Setting up inetsim
    provisioner "file" {
        source = "files/packages/inetsim.list"
        destination = "/tmp/inetsim.list"
    }

    provisioner "remote-exec" {
      inline = [
          "sudo mv /tmp/inetsim.list /etc/apt/sources.list.d/inetsim.list",
          "wget -O /tmp/inetsim-archive-signing-key.asc https://www.inetsim.org/inetsim-archive-signing-key.asc",
          "sudo apt-key add /tmp/inetsim-archive-signing-key.asc",
          "sudo rm /tmp/inetsim-archive-signing-key.asc"
      ]
    }

    provisioner "remote-exec" {
      inline = [
        "sudo apt update",
        "sudo apt install -y curl gnupg inetsim"
      ]
    }

    provisioner "remote-exec" {
        inline = [
          "sudo sed -i 's/^#service_bind_address.*/service_bind_address 10.0.1.2/' /etc/inetsim/inetsim.conf",
          "sudo sed -i 's/^start_service https/#start_service https/' /etc/inetsim/inetsim.conf",
          "sudo systemctl start inetsim",
          "sudo systemctl enable inetsim"
        ]
    }

    # Configure PolarProxy
    provisioner "file" {
      source = "files/PolarProxy/PolarProxy.service"
      destination = "/tmp/PolarProxy.service"
    }

    provisioner "remote-exec" {
        inline = [
          "mkdir /home/packer/PolarProxy",
          "curl https://www.netresec.com/?download=PolarProxy -o /home/packer/PolarProxy/PolarProxy.tar.gz",
          "sudo mkdir -p /usr/local/bin/PolarProxy",
          "sudo tar -xzf /home/packer/PolarProxy/PolarProxy.tar.gz -C /usr/local/bin/PolarProxy",
          "sudo mv /tmp/PolarProxy.service /etc/systemd/system/PolarProxy.service",
          "sudo mkdir -p /var/log/PolarProxy",
          "sudo systemctl daemon-reload",
          "sudo systemctl start PolarProxy",
          "sudo systemctl enable PolarProxy"
        ]
    }

    # Configure TCPReplay
    provisioner "file" {
        source = "files/tcpreplay/tcpreplay.service"
        destination = "/tmp/tcpreplay.service"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo apt install -y tcpreplay",
            "sudo mv /tmp/tcpreplay.service /etc/systemd/system/tcpreplay.service",
            "sudo systemctl daemon-reload",
            "sudo systemctl start tcpreplay",
            "sudo systemctl enable tcpreplay"            
        ]      
    }

    # Setting up network sniffing interfaces
    provisioner "file" {
        source = "files/interface.d/49-sniff"
        destination = "/tmp/49-sniff"
      
    }

    provisioner "remote-exec" {
        inline = [
          "sudo cp /tmp/49-sniff /etc/network/interfaces.d/49-sniff"
        ]
    }

    # Setting up Zeek
    provisioner "file" {
        source = "files/packages/zeek.list"
        destination = "/tmp/zeek.list"
    }

    provisioner "remote-exec" {
        inline = [
          "sudo mv /tmp/zeek.list /etc/apt/sources.list.d/zeek.list",
          "curl -fsSL https://download.opensuse.org/repositories/security:zeek/Debian_11/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null",
          "sudo apt update",
          "sudo apt install -y zeek"
        ]
    }

    provisioner "file" {
        source = "files/zeek/node.cfg"
        destination = "/tmp/node.cfg"    
    }

    provisioner "file" {
        source = "files/zeek/zeek.service"
        destination = "/tmp/zeek.service"
    }

    provisioner "remote-exec" {
        inline = [
          "sudo mv /tmp/node.cfg /opt/zeek/etc/node.cfg",
          "sudo mv /tmp/zeek.service /etc/systemd/system/zeek.service",
          "echo @load tuning/json-logs | sudo tee -a /opt/zeek/share/zeek/site/local.zeek",
          "sudo systemctl daemon-reload",
          "sudo systemctl enable zeek"
        ]      
    }

    provisioner "remote-exec" {
        inline = [
          "sudo reboot"
        ]
        on_failure = continue
    }

    provisioner "local-exec" {
        command = "echo Run \"ovs-vsctl -- --id=@p get port tap${self.vmid}i2 -- --id=@m create mirror name=span1 select-all=true output-port=@p -- set bridge vmbr1 mirrors=@m\" on ${var.proxmox_host}"  
    }

}

# Logger base from detection lab
resource "proxmox_vm_qemu" "ubuntu-logger" {
    # VM General Settings
    target_node = var.proxmox_host
    vmid = "301"
    name = "ubuntu-logger"

    # VM Advanced General Settings
    onboot = false 

    # VM OS Settings
    clone = var.ubuntu_source

    # VM System Settings
    agent = 1
    
    # VM CPU Settings
    cores = 2
    sockets = 1
    cpu = "host"    
    
    # VM Memory Settings
    memory = 2048

    disk {
        size = "64G"
        type = "scsi"
        storage = "VMs"
        cache = "writeback"
        format = "qcow2"
        discard = "on"
    }

    # VM Network Settings
    network {
        bridge = var.public_network_bridge
        model  = "virtio"
    }

    network {
        bridge = var.isolated_network_bridge
        model  = "virtio"
    }
}