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
    sensitive = true
    default = "secret"
}

variable "proxmox_vault_root" {
    type = string
    default = "secrets/data/proxmox/token"
    sensitive = true
}

local "proxmox_token" {
    expression = vault("${var.proxmox_vault_root}", "${var.proxmox_api_token_id}")
    sensitive = true
}

local "proxmox_secret" {
    expression = vault("${var.proxmox_vault_root}", "${var.proxmox_api_token_secret}")
    sensitive = true
}

variable "autounattended_cd" {
    type = string
}

variable "autounattended_hash" {
    type = string
}