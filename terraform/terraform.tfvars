node_name    = "pve2"
pool_id      = "Staging"
datastore_id = "local-zfs"
bridge       = "vmbr1"
gateway      = null

ssh_public_key_path = "~/.ssh/id_ed25519.pub"

create_vm      = true
vm_template_id = 100
vm_id          = null
vm_name        = "iac-demo-vm"
vm_ipv4_cidr   = "dhcp"

create_lxc = false