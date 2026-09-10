#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tf_dir="${project_dir}/terraform"
inventory="${project_dir}/ansible/inventory.ini"
private_key="${SSH_PRIVATE_KEY_PATH:-${HOME}/.ssh/id_ed25519}"

outputs="$(terraform -chdir="${tf_dir}" output -json)"
vm_ip="$(jq -r '.vm.value.ip // empty' <<<"${outputs}")"
lxc_ip="$(jq -r '.lxc.value.ip // empty' <<<"${outputs}")"

{
  printf '[vm]\n'
  if [[ -n "${vm_ip}" ]]; then
    printf 'iac-demo-vm ansible_host=%s ansible_user=ubuntu proxmox_guest_type=QEMU-VM\n' "${vm_ip}"
  fi
  printf '\n[lxc]\n'
  if [[ -n "${lxc_ip}" ]]; then
    printf 'iac-demo-lxc ansible_host=%s ansible_user=root ansible_become=false proxmox_guest_type=LXC\n' "${lxc_ip}"
  fi
  printf '\n[iac_demo:children]\nvm\nlxc\n'
  printf '\n[iac_demo:vars]\nansible_ssh_private_key_file=%s\n' "${private_key}"
} > "${inventory}"

printf 'Generated %s\n' "${inventory}"
