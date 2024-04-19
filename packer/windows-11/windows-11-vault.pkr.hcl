locals {
    proxmox_api_token_id = vault("${var.proxmox_vault_root}", "${var.proxmox_api_token_id}")
    proxmox_api_token_secret = vault("${var.proxmox_vault_root}", "${var.proxmox_api_token_secret}")
    template_description = "Windows 11 23H2 64-bit ${var.os_type} template built ${legacy_isotime("2006-01-02 03:04:05")}"
}

source "proxmox-iso" "win11-23h2-x64" {

  vm_id = "${var.vm_id}"
  
  # Hit the "Press any key to boot from CD ROM"
  boot_wait = "-1s" # To set boot_wait to 0s, use a negative number, such as "-1s"
  boot_command = [  # 120 seconds of enters to cover all different speeds of disks as windows boots
    "<return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait>",
    "<return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait>",
    "<return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait>",
    "<return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait>",
    "<return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait>",
    "<return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait>",
    "<return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait>",
    "<return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait>",
    "<return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait>",
    "<return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait>",
    "<return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait>",
    "<return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait><return><wait>"
  ]
  additional_iso_files {
    device           = "sata3"
    iso_storage_pool = "${var.iso_storage_pool}"
    unmount          = true
    cd_label         = "PROVISION"
    cd_files = [
      "../scripts/windows",
#      "files/${var.os_type}/Autounattend.xml",
    ]
    cd_content = {
      "autounattend.xml" = templatefile("files/${var.os_type}/Autounattend.pkrtpl.hcl", {
        winrm_password = var.winrm_password
        winrm_username = var.winrm_username
      })
    }
  }
  additional_iso_files {
    device           = "sata4"
    iso_file = "local:iso/virtio-win-0.1.240.iso"
    unmount          = true
  }

  # VM Cloud-Init Settings
  #cloud_init = true
  #cloud_init_storage_pool = "local-lvm"

  # Required for Win11
  bios = "ovmf"
  efi_config {
    efi_storage_pool  = "local-lvm"
    pre_enrolled_keys = true
    efi_type          = "4m"
  }
  # End Win11 required option

  communicator    = "winrm"
  cores           = "${var.vm_cpu_cores}"
  cpu_type        = "host"
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size         = "${var.vm_disk_size}"
    format            = "${var.proxmox_storage_format}"
    storage_pool      = "${var.proxmox_storage_pool}"
    type              = "scsi"
    ssd               = true
    discard           = true
    io_thread         = true
  }
  insecure_skip_tls_verify = "${var.proxmox_skip_tls_verify}"
  iso_file = "local:iso/${var.vm_iso}"
  memory                   = "${var.vm_memory}"
  network_adapters {
    bridge = "vmbr1"
    firewall = "false"
    model  = "e1000"
  }

  proxmox_url = "${var.proxmox_api_url}"
  username = "${local.proxmox_api_token_id}"
  token = "${local.proxmox_api_token_secret}"

  node                 = "${var.proxmox_host}"
  os                   = "${var.os}"
  template_description = "${local.template_description}"
  vm_name              = "${var.vm_name}"
  winrm_insecure       = true
  winrm_password       = "${var.winrm_password}"
  winrm_use_ssl        = true
  winrm_username       = "${var.winrm_username}"
  winrm_timeout        = "60m"
  unmount_iso          = true
  task_timeout         = "20m" // On slow disks the imgcopy operation takes > 1m
}

build {
  sources = ["source.proxmox-iso.win11-23h2-x64"]

  #provisioner "powershell" {
  #  elevated_user = "vagrant"
  #  elevated_password = "vagrant"
  #  timeout = "30m"
  #  scripts = ["../scripts/windows/cloudinit/install-cloudbaseinit.ps1"]
  #}

  #provisioner "powershell" {
  #  elevated_user = "vagrant"
  #  elevated_password = "vagrant"
  #  scripts = ["../scripts/windows/cloudinit/config-cloudbaseinit.ps1"]
  #}

#  provisioner "windows-shell" {
#    scripts = ["scripts/disablewinupdate.bat"]
#  }

#  provisioner "powershell" {
#    scripts = ["scripts/disable-hibernate.ps1"]
#  }

#  provisioner "powershell" {
#    scripts = ["scripts/install-virtio-drivers.ps1"]
#  }

}

