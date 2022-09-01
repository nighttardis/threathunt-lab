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
source "proxmox" "debian-bullseye" {
 
    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${local.proxmox_api_token_id}"
    token = "${local.proxmox_api_token_secret}"
    insecure_skip_tls_verify = true

    # TODO: Update

    node = "kvm"
    vm_id = "901"
    vm_name = "debian-bullseye"
    template_description = "Debian Bullseye Image"

    iso_file = "ISO-Linux:iso/debian-11.3.0-amd64-netinst.iso"

    iso_storage_pool = "local"
    unmount_iso = true

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "local-lvm"

     # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size = "20G"
        format = "qcow2"
        storage_pool = "VMs"
        storage_pool_type = "nfs"
        type = "sata"
    }

    # VM CPU Settings
    cores = "2"

    # VM Memory Settings
    memory = "2048" 

     # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
    } 

    # PACKER Boot Commands
    boot_command = [
         "<esc><wait>",
         "install <wait>",
         " auto=true",
         " priority=critical",
         " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
         "<enter><wait>"
    ]
    boot = "c"
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_directory = "http" 
    # (Optional) Bind IP Address and Port
    # http_bind_address = "0.0.0.0"
    # http_port_min = 8802
    # http_port_max = 8802

    ssh_username = "packer"

    ssh_private_key_file = "~/.ssh/packer_ed25519"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "120m"
}

build {

    name = "debian-bullseye"
    sources = ["source.proxmox.debian-bullseye"]

    provisioner "shell" {
        inline = [
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
        ]
    }

    provisioner "file" {
        source = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

#    provisioner "file" {
#        source = "files/99-nocloud-datasource.cfg"
#        destination = "/tmp/99-nocloud-datasource.cfg"
#    }

    provisioner "shell" {
        inline = [
            "sudo cp /tmp/99*.cfg /etc/cloud/cloud.cfg.d/.",
            "sudo systemctl add-wants multi-user.target cloud-init.target",
            "sudo cloud-init clean",
            "sudo sync"
        ]
    }

    provisioner "shell" {
        inline = [
            "sudo fstrim --all --verbose"
        ]
    }
}