# Proxmox Provider
# ---
# Initial Provider Configuration for Proxmox

terraform {

    required_version = ">= 0.13.0"

    required_providers {
        proxmox = {
            source = "telmate/proxmox"
            version = "2.9.3"
        }
        vault = {
            source = "vault"
        }
    }
}

variable "proxmox_api_url" {
    type = string
}

variable "vault_address" {
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
    default = "secrets/proxmox/token"
    sensitive = true
}

variable "packer_vault_ssh_key" {
    type = string
    default = "secrets/packer/user"
    sensitive = true
}

variable "splunk_vault_root" {
    type = string
    sensitive = true
    default = "secrets/data/splunk"
}

variable "splunk_admin_password" {
    type = string
    sensitive = true
    default = "key"
}

provider "vault" {
    address = var.vault_address
}

data "vault_generic_secret" "proxmox" {
    path = var.proxmox_vault_root
}

data "vault_generic_secret" "packer" {
    path = var.packer_ssh_key + "/ssh_private"
}

data "vault_generic_secret" "splunk" {
    path = var.splunk_vault_root
}

provider "proxmox" {

    pm_api_url = var.proxmox_api_url
    pm_api_token_id = data.vault_generic_secret.proxmox.data[var.proxmox_api_token_id]
    pm_api_token_secret = data.vault_generic_secret.proxmox.data[var.proxmox_api_token_secret]

    # (Optional) Skip TLS Verification
    pm_tls_insecure = true

}