variable "node_name" {
  description = "Target Proxmox node"
  type        = string
  default     = "pve2"
}

variable "pool_id" {
  description = "Existing Proxmox resource pool dedicated to the demo"
  type        = string
  default     = "Staging"
}

variable "datastore_id" {
  description = "Storage for VM disks, LXC rootfs, and cloud-init"
  type        = string

  validation {
    condition     = trimspace(var.datastore_id) != "" && !startswith(var.datastore_id, "REPLACE_")
    error_message = "datastore_id must be replaced with an approved pve2 storage ID."
  }
}

variable "bridge" {
  description = "Proxmox Linux bridge"
  type        = string

  validation {
    condition     = trimspace(var.bridge) != "" && !startswith(var.bridge, "REPLACE_")
    error_message = "bridge must be replaced with the approved Staging bridge or VNet."
  }
}

variable "gateway" {
  description = "IPv4 gateway used by both demo guests"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.gateway == null || can(cidrhost("${var.gateway}/32", 0))
    error_message = "gateway must be null or a valid IPv4 address."
  }
}

variable "ssh_public_key_path" {
  description = "Public key injected into both guests"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "create_vm" {
  description = "Create the QEMU VM part of the demo"
  type        = bool
  default     = false
}

variable "vm_template_id" {
  description = "Cloud-init-ready VM template ID; qemu-guest-agent must be installed"
  type        = number
  default     = null
  nullable    = true
}

variable "vm_id" {
  description = "Requested VM ID; set null to let the provider choose"
  type        = number
  default     = null
  nullable    = true
}

variable "vm_name" {
  type    = string
  default = "iac-demo-vm"
}

variable "vm_ipv4_cidr" {
  description = "VM address in CIDR notation, or dhcp"
  type        = string
  default     = "dhcp"

  validation {
    condition = !var.create_vm || (
      var.vm_ipv4_cidr == "dhcp" || (
        can(cidrhost(var.vm_ipv4_cidr, 0)) &&
        !startswith(var.vm_ipv4_cidr, "192.0.2.")
      )
    )
    error_message = "vm_ipv4_cidr must be a real, approved lab CIDR; documentation addresses are rejected."
  }
}

variable "create_lxc" {
  description = "Create the LXC part of the demo"
  type        = bool
  default     = false
}

variable "lxc_template_file_id" {
  description = "Existing LXC template volume"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = !var.create_lxc || try(strcontains(var.lxc_template_file_id, ":vztmpl/"), false)
    error_message = "lxc_template_file_id must look like storage:vztmpl/template-file.tar.zst."
  }
}

variable "lxc_id" {
  description = "Requested LXC ID; set null to let the provider choose"
  type        = number
  default     = null
  nullable    = true
}

variable "lxc_name" {
  type    = string
  default = "iac-demo-lxc"
}

variable "lxc_ipv4_cidr" {
  description = "LXC address in CIDR notation, or dhcp"
  type        = string
  default     = "192.0.2.202/24"

  validation {
    condition = !var.create_lxc || var.lxc_ipv4_cidr == "dhcp" || (
      can(cidrhost(var.lxc_ipv4_cidr, 0)) &&
      !startswith(var.lxc_ipv4_cidr, "192.0.2.")
    )
    error_message = "lxc_ipv4_cidr must be a real, approved lab CIDR; documentation addresses are rejected."
  }
}
