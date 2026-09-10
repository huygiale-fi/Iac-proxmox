# This data source makes every plan verify API access to the selected node
# before Terraform proposes any guest changes.
data "proxmox_virtual_environment_node" "target" {
  node_name = var.node_name
}

