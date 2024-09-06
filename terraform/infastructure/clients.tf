resource "proxmox_vm_qemu" "windows-10-client" {
    count=var.windows_10_count
    # VM General Settings
    target_node = var.proxmox_host
    vmid = 310 - (count.index)
    name = "win10-${count.index}"

    # VM Advanced General Settings
    onboot = false 
    automatic_reboot = false

    # VM OS Settings
    clone = var.windows_10_client_source

    # VM System Settings
    agent = 1
    
    # VM CPU Settings
    cores = 2
    sockets = 2
    cpu = "host"    
    
    # VM Memory Settings
    memory = 4096
    balloon = 2048

    # VM Network Settings
    network {
        bridge = var.isolated_network_bridge
        model  = "e1000"
    }

    lifecycle {
        ignore_changes = [
            network, qemu_os, desc, disk, numa, scsihw, clone_wait, additional_wait, automatic_reboot, 
        ]
    }

    
    #provisioner "local-exec" {
    #    working_dir = "../ansible"
    #    command = "ansible-venv/bin/ansible-playbook -i '${self.ssh_host},' --extra-vars 'ansible_user=vagrant ansible_password=vagrant verbose_win_security_logging=${var.verbose_win_security_logging} win_sysmon_url=${var.win_sysmon_url} win_install_sysmon=${var.win_install_sysmon} win_sysmon_template=${var.win_sysmon_template} win_4688_cmd_line=${var.win_4688_cmd_line} win_sysinternal_url=${var.win_sysinternal_url} win_install_sysinternals=${var.win_install_sysinternals} polarproxy=${var.win_polarproxy} polarproxyhost=${var.win_polarproxyhost} polarproxycaport=${var.win_polarproxycaport} winlogbeat_download_file=${var.winlogbeat_download_file} logstash_port=${var.logstash_port} logstash_host=${var.logstash_host} file_ext=${var.winlogbeat_file_ext} winlogbeat_download_url_base=${var.winlogbeat_download_url_base} winlogbeat_install_location=\"${var.winlogbeat_install_location}\" win_install_winlogbeat=${var.win_install_winlogbeat} winlogbeat_logstash=${var.winlogbeat_logstash}' playbooks/windows_client.yml"
    #}

}

resource "ansible_host" "windows-10-client" {
    count = var.windows_10_count
    name = proxmox_vm_qemu.windows-10-client[count.index].name

    groups = ["windows_client"]
    variables = {
        ansible_host = "${proxmox_vm_qemu.windows-10-client[count.index].ssh_host}"
        #verbose_win_security_logging=var.verbose_win_security_logging, 
        #win_sysmon_url=var.win_sysmon_url,
        #win_install_sysmon=var.win_install_sysmon, 
        #win_sysmon_template=var.win_sysmon_template, 
        #win_4688_cmd_line=var.win_4688_cmd_line,
        #win_sysinternal_url=var.win_sysinternal_url, 
        #win_install_sysinternals=var.win_install_sysinternals,
        #polarproxy=var.win_polarproxy,
        #polarproxyhost=var.win_polarproxyhost,
        #polarproxycaport=var.win_polarproxycaport,
        #winlogbeat_download_file=var.winlogbeat_download_file,
        #logstash_port=var.logstash_port,
        #logstash_host=var.logstash_host,
        #file_ext=var.winlogbeat_file_ext,
        #winlogbeat_download_url_base=var.winlogbeat_download_url_base,
        #winlogbeat_install_location="${var.winlogbeat_install_location}",
        #win_install_winlogbeat=var.win_install_winlogbeat,
        #winlogbeat_logstash=var.winlogbeat_logstash
    }
  
}

resource "proxmox_vm_qemu" "windows-11-ent-client" {
    count=var.windows_11_ent_count
    # VM General Settings
    target_node = var.proxmox_host
    vmid = 340 - (count.index)
    name = "win11-ent-${count.index}"
    qemu_os = "win11"

    bios = "ovmf"

    # VM Advanced General Settings
    onboot = false 
    automatic_reboot = false

    # VM OS Settings
    clone = var.windows_11_ent_client_source

    # VM System Settings
    agent = 1
    
    # VM CPU Settings
    cores = 2
    sockets = 2
    cpu = "host"    
    
    # VM Memory Settings
    memory = 4096
    balloon = 2048

    # VM Network Settings
    network {
        bridge = var.isolated_network_bridge
        model  = "e1000"
    }

    lifecycle {
        ignore_changes = [
            network, qemu_os, desc, disk, numa, scsihw, clone_wait, additional_wait, automatic_reboot, machine,
        ]
    }

    scsihw = "virtio-scsi-single"

    disks {
        scsi {
            scsi0 {
                disk {
                    storage = "local-lvm"
                    size = "100"
                    backup = "false"
                    discard = "true"
                    emulatessd= "true"
                }
            }
        }
    }
  
}

resource "ansible_host" "windows-11-ent-client" {
    count = var.windows_11_ent_count
    name = proxmox_vm_qemu.windows-11-ent-client[count.index].name

    groups = ["windows_client","window_11_ent"]
    variables = {
      ansible_host = "${proxmox_vm_qemu.windows-11-ent-client[count.index].ssh_host}"
      vm_count = count.index
      os = "win"
      os_type = "ent11"
    }
}

resource "proxmox_vm_qemu" "windows-11-pro-client" {
    count=var.windows_11_pro_count
    # VM General Settings
    target_node = var.proxmox_host
    vmid = 350 - (count.index)
    name = "win11-pro-${count.index}"
    qemu_os = "win11"

    bios = "ovmf"

    # VM Advanced General Settings
    onboot = false 
    automatic_reboot = false

    # VM OS Settings
    clone = var.windows_11_pro_client_source

    # VM System Settings
    agent = 1
    
    # VM CPU Settings
    cores = 2
    sockets = 2
    cpu = "host"    
    
    # VM Memory Settings
    memory = 4096
    balloon = 2048

    # VM Network Settings
    network {
        bridge = var.isolated_network_bridge
        model  = "e1000"
    }

    lifecycle {
        ignore_changes = [
            network, qemu_os, desc, disk, numa, scsihw, clone_wait, additional_wait, automatic_reboot, machine,
        ]
    }

    scsihw = "virtio-scsi-single"

    disks {
        scsi {
            scsi0 {
                disk {
                    storage = "local-lvm"
                    size = "100"
                    backup = "false"
                    discard = "true"
                    emulatessd= "true"
                }
            }
        }
    }
  
}

resource "ansible_host" "windows-11-pro-client" {
    count = var.windows_11_pro_count
    name = proxmox_vm_qemu.windows-11-pro-client[count.index].name

    groups = ["windows_client","windows_11_pro"]
    variables = {
      ansible_host = "${proxmox_vm_qemu.windows-11-pro-client[count.index].ssh_host}"
      vm_count = count.index
      os = "win"
      os_type = "pro11"
    }
}

resource "proxmox_vm_qemu" "windows-11-pro-client-custom" {
    count=var.windows_11_pro_c_count
    # VM General Settings
    target_node = var.proxmox_host
    vmid = 360 - (count.index)
    name = "win11-pro-c-${count.index}"
    qemu_os = "win11"

    bios = "ovmf"

    # VM Advanced General Settings
    onboot = false 
    automatic_reboot = false

    # VM OS Settings
    clone = var.windows_11_pro_client_source

    # VM System Settings
    agent = 1
    
    # VM CPU Settings
    cores = 2
    sockets = 2
    cpu = "host"    
    
    # VM Memory Settings
    memory = 4096
    balloon = 2048

    # VM Network Settings
    network {
        bridge = var.isolated_network_bridge
        model  = "e1000"
    }

    lifecycle {
        ignore_changes = [
            network, qemu_os, desc, disk, numa, scsihw, clone_wait, additional_wait, automatic_reboot, machine,
        ]
    }

    scsihw = "virtio-scsi-single"

    disks {
        scsi {
            scsi0 {
                disk {
                    storage = "local-lvm"
                    size = "100"
                    backup = "false"
                    discard = "true"
                    emulatessd= "true"
                }
            }
        }
    }
  
}

resource "ansible_host" "windows-11-pro-client-custom" {
    count = var.windows_11_pro_c_count
    name = proxmox_vm_qemu.windows-11-pro-client-custom[count.index].name

    groups = ["windows_client","windows_11_pro"]
    variables = {
      ansible_host = "${proxmox_vm_qemu.windows-11-pro-client-custom[count.index].ssh_host}"
      vm_count = count.index
      os = "win"
      os_type = "pro11c"
    }
}