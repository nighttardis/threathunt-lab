# Proxmox Full-Clone
# ---
# Create a new VM from a clone

resource "proxmox_vm_qemu" "vm-name" {
    
    # VM General Settings
    target_node = "node-name"
    vmid = "300"
    name = "vm-name"

    # VM Advanced General Settings
    onboot = false 

    # VM OS Settings
    clone = "clone-name"

    # VM System Settings
    agent = 1
    
    # VM CPU Settings
    cores = 1
    sockets = 1
    cpu = "host"    
    
    # VM Memory Settings
    memory = 1024

    # VM Network Settings
    network {
        bridge = "vmbr0"
        model  = "virtio"
    }

    # VM Cloud-Init Settings
    os_type = "cloud-init"

    # (Optional) IP Address and Gateway
    # ipconfig0 = "ip=0.0.0.0/0,gw=0.0.0.0"
    
    # (Optional) Default User
    # ciuser = "user_name"
    
    # (Optional) Add your SSH KEY
    # sshkeys = <<EOF
    # SSH KEY
    # EOF
}