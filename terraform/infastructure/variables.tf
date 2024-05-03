## Imaging Settings

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

variable "isolated_network_bridge" {
    type = string
}

variable "public_network_bridge" {
    type = string
}

## Install a SIEM

variable "install_siem" {
    type = string
    description = "What SIEM you want to deploy"
    validation {
      condition = contains(["none","splunk","elastic"], var.install_siem)
      error_message = "Valid values are: none, splunk, elastic"
    }
}

# Splunk things

variable "splunk_binary" {
    type = string
}

variable "splunk_url" {
    type = string
}

# INetsim 

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

# Winlogbeat -- through logstash

variable "logstash_host" {
    type = string
    default = "10.0.1.3"
    description = "IP of logger's isolated_network interface"
}

variable "logstash_port" {
    type = string
    default = "5044"
}

# ELK

variable "elastic_version" {
    type = string
    description = "Version of elasticsearch/kibana to install"
}

# Windows Client

variable "windows_10_client_source" {
    type = string
    default = ""
}

variable "windows_10_count" {
    type = number
    default = 0
    description = "Number of Windows 10 Clients to create"
}

variable "windows_11_ent_client_source" {
    type = string
    default = ""
}

variable "windows_11_ent_count" {
    type = number
    default = 0
    description = "Number of Windows 11 Clients to create" 
}

variable "windows_11_pro_client_source" {
    type = string
    default = ""
}

variable "windows_11_pro_count" {
    type = number
    default = 0
    description = "Number of Windows 11 Clients to create" 
}