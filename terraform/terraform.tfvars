node_name    = "pve2"
pool_id      = "Staging"
datastore_id = "local-zfs"
bridge       = "vmbr0"
gateway      = "10.200.101.1"

ssh_public_key_path = "~/.ssh/iac.pub"

create_vm      = true
vm_template_id = 100
vm_id          = null
vm_name        = "iac-demo-vm"
vm_ipv4_cidr  = "10.200.101.200/24"

create_lxc = false