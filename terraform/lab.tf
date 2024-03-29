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

variable "windows_client_source" {
    type = string
}

variable "isolated_network_bridge" {
    type = string
}

variable "public_network_bridge" {
    type = string
}

variable "splunk_binary" {
    type = string
}

variable "splunk_url" {
    type = string
}

variable "inetsiem_hostname" {
    type = string
}

variable "inetsiem_inetsim" {
  type = string
}

variable "inetsiem_polar_proxy" {
  type = string
}

variable "inetsiem_setup_gateway" {
  type = string
}

variable "logstash_host" {
    type = string
    default = "10.0.1.3"
    description = "IP of logger's isolated_network interface"
}

variable "logstash_port" {
    type = string
    default = "5044"
}

variable "winlogbeat_file_ext" {
    type = string
    default = "zip"
}

variable "winlogbeat_download_url_base" {
    type = string
    default = "https://artifacts.elastic.co/downloads/beats/winlogbeat/"
}

variable "winlogbeat_download_file" {
    type = string
}

variable "winlogbeat_install_location" {
    type = string
    default = "c:\\\\program files\\\\ansible\\\\winlogbeat"
}

variable "verbose_win_security_logging" {
    type = string
}

variable "win_sysmon_url" {
    type = string
}

variable "win_install_sysmon" {
    type = string
}

variable "win_sysmon_template" {
    type = string
}

variable "win_4688_cmd_line" {
    type = string
}

variable "win_sysinternal_url" {
    type = string
}

variable "win_install_sysinternals" {
    type = string
}

variable "win_polarproxy" {
    type = string
}

variable "win_polarproxyhost" {
    type = string
    default = "10.0.1.2"
    description = "IP of Debian Inetsiem's isolated_network interface"
}

variable "win_polarproxycaport" {
    type = string
    default = "10080"
    description = "Port to download polarproxy's CA from"
}

variable "win_install_winlogbeat" {
    type = string
}

variable "winlogbeat_logstash" {
    type = string
    default = "1"
    description = "Configure winlogbeat to foward to logstash"
}

### Uncomment this for vault
# variable "splunk_admin_password" {
#    type = string
# }
###

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
            network, qemu_os, desc
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

    provisioner "remote-exec" {
        inline = [
          "echo booted"
        ]

        connection {
          type = "ssh"
          user = "packer"
          host = self.ssh_host
          private_key = data.vault_generic_secret.packer.data["key"]
          timeout = "10m"
        }
    }

    provisioner "local-exec" {
        command = "echo '${data.vault_generic_secret.packer.data["key"]}' >> ~/.ssh/packer"
    }

    provisioner "local-exec" {
        command = "chmod 600 ~/.ssh/packer"
    }

    provisioner "local-exec" {
        working_dir = "../ansible"
        command = "ansible-venv/bin/ansible-playbook -u packer --private-key ~/.ssh/packer -i '${self.ssh_host},' --extra-vars 'set_hostname=${var.inetsiem_hostname} inetsim=${var.inetsiem_inetsim} polar_proxy=${var.inetsiem_polar_proxy} setup_gateway=${var.inetsiem_setup_gateway} logstash_port=${var.logstash_port} logstash_host=${var.logstash_host} elastic_non_oss=1 zeek_filebeat=1' playbooks/inetsim.yml"
    }

    provisioner "local-exec" {
        command = "rm ~/.ssh/packer"
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

    ipconfig1 = "ip=10.0.1.3/24"

    provisioner "remote-exec" {
        inline = [
          "echo \"$(date -Is) booted\"",
          "sleep 60",
          "while ! tail -10 /var/log/cloud-init-output.log| grep \"Cloud-init .* finished\"; do echo \"$(date -Is) waiting for cloud-init\"; sleep 2; done"
        ]

        connection {
          type = "ssh"
          user = "packer"
          host = self.ssh_host
          private_key = data.vault_generic_secret.packer.data["key"]
          timeout = "10m"
        }
    }

    provisioner "local-exec" {
        command = "echo '${data.vault_generic_secret.packer.data["key"]}' >> ~/.ssh/packer"
    }

    provisioner "local-exec" {
        command = "chmod 600 ~/.ssh/packer"
    }

    provisioner "local-exec" {
        working_dir = "../ansible"
        command = "ansible-venv/bin/ansible-playbook -u packer --private-key ~/.ssh/packer -i '${self.ssh_host},' playbooks/logger.yml -e 'splunk_url=${var.splunk_url} splunk_binary=${var.splunk_binary} splunk_admin_password=${data.vault_generic_secret.splunk.data[var.splunk_admin_password]} set_hostname=0 install_logstash=1'"
    }

    provisioner "local-exec" {
        command = "rm ~/.ssh/packer"
    }

}

resource "proxmox_vm_qemu" "windows-client" {
    count=1
    # VM General Settings
    target_node = var.proxmox_host
    vmid = 310 - (count.index)
    name = "win10-${count.index}"

    # VM Advanced General Settings
    onboot = false 

    # VM OS Settings
    clone = var.windows_client_source

    # VM System Settings
    agent = 1
    
    # VM CPU Settings
    cores = 2
    sockets = 2
    cpu = "host"    
    
    # VM Memory Settings
    memory = 4096

    # VM Network Settings
    network {
        bridge = var.isolated_network_bridge
        model  = "e1000"
    }

    lifecycle {
        ignore_changes = [
            network, qemu_os, desc
        ]
    }
    
    provisioner "local-exec" {
        working_dir = "../ansible"
        command = "ansible-venv/bin/ansible-playbook -i '${self.ssh_host},' --extra-vars 'ansible_user=vagrant ansible_password=vagrant verbose_win_security_logging=${var.verbose_win_security_logging} win_sysmon_url=${var.win_sysmon_url} win_install_sysmon=${var.win_install_sysmon} win_sysmon_template=${var.win_sysmon_template} win_4688_cmd_line=${var.win_4688_cmd_line} win_sysinternal_url=${var.win_sysinternal_url} win_install_sysinternals=${var.win_install_sysinternals} polarproxy=${var.win_polarproxy} polarproxyhost=${var.win_polarproxyhost} polarproxycaport=${var.win_polarproxycaport} winlogbeat_download_file=${var.winlogbeat_download_file} logstash_port=${var.logstash_port} logstash_host=${var.logstash_host} file_ext=${var.winlogbeat_file_ext} winlogbeat_download_url_base=${var.winlogbeat_download_url_base} winlogbeat_install_location=\"${var.winlogbeat_install_location}\" win_install_winlogbeat=${var.win_install_winlogbeat} winlogbeat_logstash=${var.winlogbeat_logstash}' playbooks/windows_client.yml"
    }

}