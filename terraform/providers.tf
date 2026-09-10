provider "proxmox" {
  endpoint      = "https://10.200.101.22:8006/"
  insecure      = true
  random_vm_ids = true
}