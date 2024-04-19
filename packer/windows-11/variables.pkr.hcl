# https://github.com/proxmox/qemu-server/blob/9b1971c5c991540f27270022e586aec5082b0848/PVE/QemuServer.pm#L412
variable "os" {
  type    = string
  default = "win11"
}

variable "os_type" {
    type = string
    description = "ent or pro"
    validation {
      condition = contains(["ent","pro"], var.os_type)
      error_message = "Valid values are: ent, pro this is a period because packer is so stupid and requires a period."
    }
}

variable "vm_cpu_cores" {
  type    = string
  default = "2"
}

variable "vm_disk_size" {
  type    = string
  default = "100G"
}

variable "vm_memory" {
  type    = string
  default = "4096"
}

variable "vm_name" {
  type    = string
}

variable "vm_id" {
    type = string
}

variable "vm_iso" {
    type = string
}

variable "winrm_password" {
  type    = string
  default = "vagrant"
}

variable "winrm_username" {
  type    = string
  default = "vagrant"
}

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

variable "iso_storage_pool" {
  type = string
  default = "local"
}

variable "proxmox_skip_tls_verify" {
  type = bool
  default = true
}

variable "proxmox_storage_pool" {
  type = string
  default = "local-lvm"
}

variable "proxmox_storage_format" {
  type = string
  default = "raw"
}

variable "proxmox_host" {
  type = string
}