# Windows 10

# Variable Definitions
variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
    default = "id"
}

variable "proxmox_api_token_secret" {
    type = string
    default = "secret"
    sensitive = true
}

variable "proxmox_vault_root" {
    type = string
    default = "secrets/data/proxmox/token"
    sensitive = true
}

locals {
    proxmox_api_token_id = vault("${var.proxmox_vault_root}", "${var.proxmox_api_token_id}")
    proxmox_api_token_secret = vault("${var.proxmox_vault_root}", "${var.proxmox_api_token_secret}")
}

# Resource Definiation for the VM Template
source "proxmox" "windows-10" {
 
    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${local.proxmox_api_token_id}"
    token = "${local.proxmox_api_token_secret}"
    insecure_skip_tls_verify = true

    # TODO: Update

    node = "kvm"
    vm_id = "902"
    vm_name = "window-10"
    template_description = "Windows 10 Image"

    # TODO: Update

    # VM OS Settings
    # (Option 1) Local ISO File
    iso_file = "ISO-Windows:iso/Win10_21H2_English_x64.iso"
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
        storage_pool_type = "nfs"
        type = "sata"
    }

    # VM CPU Settings
    cores = "4"

    # VM Memory Settings
    memory = "4096" 

     # VM Network Settings
    network_adapters {
        model = "e1000"
        bridge = "vmbr0"
        firewall = "false"
    } 

    http_directory = "http" 

    additional_iso_files {
            device = "sata3"
            iso_file = "ISO-Windows:iso/Autounattend.iso"
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

    name = "windows-10"
    sources = ["source.proxmox.windows-10"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "windows-shell" {
        scripts = [
            "files/disablewinupdate.bat"
        ]
    }

    provisioner "powershell" {
        scripts = [ 
            "files/disable-hibernate.ps1"
        ]
    }

}