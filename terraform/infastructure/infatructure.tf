# INetSim/Router
resource "proxmox_vm_qemu" "debian-inetsim" {
    
    # VM General Settings
    target_node = var.proxmox_host
    vmid = "300"
    name = "inetsim"

    # VM Advanced General Settings
    onboot = false 
    automatic_reboot = false

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

    disks {
        sata {
            sata0 {
                disk {
                    storage = "local-lvm"
                    size = "20"
                    backup = "false"
                    discard = "true"
                    emulatessd= "true"
                }
            }
        }
    }

    cloudinit_cdrom_storage = "local-lvm"

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
            network, qemu_os, desc, disk, numa, scsihw, clone_wait, additional_wait, automatic_reboot, 
        ]
    }

    # VM Cloud-Init Settings
    os_type = "cloud-init"

    # (Optional) IP Address and Gateway
    ipconfig0 = "ip=dhcp"
    ipconfig1 = "ip=10.0.1.2/24"

    provisioner "local-exec" {
        command = "echo Run \"ovs-vsctl -- --id=@p get port tap${self.vmid}i2 -- --id=@m create mirror name=span1 select-all=true output-port=@p -- set bridge vmbr2 mirrors=@m\" on ${var.proxmox_host}"  
    }

}

resource "ansible_host" "debian-inetsim" {
    name = proxmox_vm_qemu.debian-inetsim.name
    groups = ["inetsim_role","polarproxy_role","gateway_role","elastic_role"]
    variables = {
        set_hostname = "${var.inetsiem_hostname}",
        inetsim = "${var.inetsiem_inetsim}",
        polar_proxy = "${var.inetsiem_polar_proxy}",
        setup_gateway = "${var.inetsiem_setup_gateway}",
        logstash_port = "${var.logstash_port}",
        logstash_host = "${var.logstash_host}",
        vmid = "${proxmox_vm_qemu.debian-inetsim.vmid}"
        ansible_user = "packer",
        ansible_ssh_private_key_file = "~/.ssh/packer",
        ansible_host = "${proxmox_vm_qemu.debian-inetsim.ssh_host}"
    }
}

# Logger base for elk
resource "proxmox_vm_qemu" "debian-logger-elastic" {

    count = var.install_siem == "elastic" ? 1 : 0

    # VM General Settings
    target_node = var.proxmox_host
    vmid = "301"
    name = "logger"

    # VM Advanced General Settings
    onboot = false 
    automatic_reboot = false

    # VM OS Settings
    clone = var.debian_source

    # VM System Settings
    agent = 1
    
    # VM CPU Settings
    cores = 2
    sockets = 1
    cpu = "host"    
    
    # VM Memory Settings
    memory = 8192
    balloon = 3072

    cloudinit_cdrom_storage = "local-lvm"

    disks {
        sata {
            sata0 {
                disk {
                    storage = "local-lvm"
                    size = "20"
                    backup = "false"
                    discard = "true"
                    emulatessd= "true"

                }
            }
        }
        scsi {
            scsi0 {
                disk {
                    size = "64"
                    storage = "local-lvm"
                    cache = "writeback"
                    backup = "false"
                    discard = "true"
                    emulatessd= "true"
                }
            }
        }
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

    lifecycle {
        ignore_changes = [
            network, qemu_os, desc, disk, numa, scsihw, clone_wait, additional_wait, automatic_reboot, 
        ]
    }
}

resource "ansible_host" "debian-logger-elastic" {
    count = var.install_siem == "elastic" ? 1 : 0

    name = proxmox_vm_qemu.debian-logger-elastic[count.index].name
    groups = ["logger_role","elastic_siem_role","elastic_role","docker_role","logstash_role","elastic_repo_role","opensearch_output_role"]
    variables = {
        elastic_docker = "1",
        kibana_docker = "1",
        elastic_version = "${var.elastic_version}",
        vmid = "${proxmox_vm_qemu.debian-logger-elastic[count.index].vmid}"
        ansible_user = "packer",
        ansible_ssh_private_key_file = "~/.ssh/packer",
        ansible_host = "${proxmox_vm_qemu.debian-logger-elastic[count.index].ssh_host}"
    }
}