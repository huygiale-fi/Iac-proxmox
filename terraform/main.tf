locals {
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
}

resource "proxmox_virtual_environment_vm" "demo" {
  count = var.create_vm ? 1 : 0

  name        = var.vm_name
  description = "IaC demo: provisioned by Terraform, configured by Ansible"
  tags        = ["iac", "terraform", "demo"]
  node_name   = var.node_name
  pool_id     = var.pool_id
  vm_id       = var.vm_id
  started     = true
  on_boot     = true

  clone {
    vm_id        = var.vm_template_id
    datastore_id = var.datastore_id
    full         = true
  }

  agent {
    enabled = true

    wait_for_ip {
      ipv4 = true
    }
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  initialization {
    datastore_id = var.datastore_id
    upgrade      = false

    ip_config {
      ipv4 {
        address = var.vm_ipv4_cidr
        gateway = var.vm_ipv4_cidr == "dhcp" ? null : var.gateway
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [local.ssh_public_key]
    }
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  lifecycle {
    precondition {
      condition     = var.vm_template_id != null
      error_message = "vm_template_id is required when create_vm is true."
    }

    precondition {
      condition     = var.vm_id == null || var.lxc_id == null || var.vm_id != var.lxc_id
      error_message = "vm_id and lxc_id must be different."
    }
  }
}

resource "proxmox_virtual_environment_container" "demo" {
  count = var.create_lxc ? 1 : 0

  node_name     = var.node_name
  pool_id       = var.pool_id
  vm_id         = var.lxc_id
  description   = "IaC demo: provisioned by Terraform, configured by Ansible"
  tags          = ["iac", "terraform", "demo"]
  started       = true
  start_on_boot = true
  unprivileged  = true

  cpu {
    cores = 1
  }

  memory {
    dedicated = 1024
    swap      = 512
  }

  disk {
    datastore_id = var.datastore_id
    size         = 8
  }

  operating_system {
    template_file_id = var.lxc_template_file_id
    type             = "ubuntu"
  }

  initialization {
    hostname = var.lxc_name

    ip_config {
      ipv4 {
        address = var.lxc_ipv4_cidr
        gateway = var.lxc_ipv4_cidr == "dhcp" ? null : var.gateway
      }
    }

    user_account {
      keys = [local.ssh_public_key]
    }
  }

  network_interface {
    name   = "veth0"
    bridge = var.bridge
  }

  wait_for_ip {
    ipv4 = true
  }
}
