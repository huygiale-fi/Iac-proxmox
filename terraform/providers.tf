provider "proxmox" {
  # Endpoint, API token, and TLS mode are read from PROXMOX_VE_* variables.
  # Random IDs reduce collisions when several demos run concurrently.
  random_vm_ids = true
}
