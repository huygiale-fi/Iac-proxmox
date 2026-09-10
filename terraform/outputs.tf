locals {
  vm_ipv4 = var.create_vm ? try([
    for ip in flatten(proxmox_virtual_environment_vm.demo[0].ipv4_addresses) : ip
    if ip != "127.0.0.1"
  ][0], null) : null
}

output "vm" {
  description = "Created VM details"
  value = var.create_vm ? {
    id   = proxmox_virtual_environment_vm.demo[0].vm_id
    name = var.vm_name
    ip   = local.vm_ipv4
  } : null
}

output "lxc" {
  description = "Created LXC details"
  value = var.create_lxc ? {
    id   = proxmox_virtual_environment_container.demo[0].vm_id
    name = var.lxc_name
    ip   = split("/", var.lxc_ipv4_cidr)[0]
  } : null
}

output "demo_urls" {
  value = compact([
    local.vm_ipv4 != null ? "http://${local.vm_ipv4}" : "",
    var.create_lxc ? "http://${split("/", var.lxc_ipv4_cidr)[0]}" : ""
  ])
}

output "target_node" {
  description = "Read-only API check for the selected Proxmox node"
  value = {
    name             = var.node_name
    cpu_model        = data.proxmox_virtual_environment_node.target.cpu_model
    logical_cpus     = data.proxmox_virtual_environment_node.target.cpu_count
    total_memory_gib = floor(data.proxmox_virtual_environment_node.target.memory_total / 1024 / 1024 / 1024)
  }
}
