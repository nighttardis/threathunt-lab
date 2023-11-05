# Windows Server 2022

# Resource Definiation for the VM Template
source "proxmox-iso" "windows-server-2022" {
 
    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${local.proxmox_token}"
    token = "${local.proxmox_secret}"
    insecure_skip_tls_verify = true

    # TODO: Update

    node = "kvm"
    vm_id = "905"
    vm_name = "window-server-2022"
    template_description = "Windows Server 2022 Template"

    # TODO: Update

    # VM OS Settings
    # (Option 1) Local ISO File
    iso_file = "ISO-Windows:iso/SERVER_EVAL_x64FRE_en-us_2022.iso"
    # - or -
    # (Option 2) Download ISO
    # iso_url = "https://releases.ubuntu.com/20.04/ubuntu-20.04.3-live-server-amd64.iso"
    # iso_checksum = "f8e3086f3cea0fb3fefb29937ab5ed9d19e767079633960ccb50e76153effc98"
    iso_storage_pool = "local"
    unmount_iso = true

     # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size = "60G"
        format = "qcow2"
        storage_pool = "VMs"
        type = "sata"
    }

    # VM CPU Settings
    cores = "2"

    # VM Memory Settings
    memory = "2048" 

     # VM Network Settings
    network_adapters {
        model = "e1000"
        bridge = "vmbr0"
        firewall = "false"
    } 

#    http_directory = "http" 

    additional_iso_files {
            device = "sata3"
            iso_url = "${var.autounattended_cd}"
            iso_storage_pool = "ISO-Windows"
            iso_checksum = "${var.autounattended_hash}"
            unmount = true
    }
    additional_iso_files {
            device = "sata4"
            iso_file = "ISO-Windows:iso/virtio-win-0.1.217.iso"
            unmount = true
    }

    communicator = "winrm"
    winrm_username = "vagrant"
    winrm_password = "vagrant"
    winrm_insecure = true
    winrm_use_ssl = true
   
}

build {

    name = "windows-sever-2022"
    sources = ["source.proxmox-iso.windows-server-2022"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
#    provisioner "windows-shell" {
#        scripts = [
#            "files/disablewinupdate.bat"
#        ]
#    }

#    provisioner "powershell" {
#        scripts = [ 
#            "files/disable-hibernate.ps1"
#        ]
#    }

}