#!/usr/bin/env bash
set -euo pipefail

required=(PVE_ENDPOINT PVE_TOKEN_ID PVE_TOKEN_SECRET)
for name in "${required[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    printf 'Missing environment variable: %s\n' "${name}" >&2
    exit 1
  fi
done

endpoint="${PVE_ENDPOINT%/}/api2/json"
auth_header="Authorization: PVEAPIToken=${PVE_TOKEN_ID}=${PVE_TOKEN_SECRET}"
curl_args=(--fail-with-body --silent --show-error --header "${auth_header}")
if [[ "${PVE_INSECURE:-false}" == "true" ]]; then
  curl_args+=(--insecure)
fi

request() {
  local method="$1"
  local path="$2"
  shift 2
  curl "${curl_args[@]}" --request "${method}" "${endpoint}${path}" "$@" | jq
}

usage() {
  cat <<'USAGE'
Usage:
  proxmox-api.sh list
  proxmox-api.sh status <node> <qemu|lxc> <vmid>
  proxmox-api.sh start|stop|reboot <node> <qemu|lxc> <vmid>
  proxmox-api.sh clone-vm <node> <template-id> <new-id> <name> [storage]
  proxmox-api.sh create-lxc <node> <new-id> <hostname> <template-volume> [storage]

Required environment variables:
  PVE_ENDPOINT=https://pve.example.local:8006
  PVE_TOKEN_ID=terraform@pve!provider
  PVE_TOKEN_SECRET=...
Optional for a lab with self-signed TLS: PVE_INSECURE=true
USAGE
}

action="${1:-}"
case "${action}" in
  list)
    request GET "/cluster/resources?type=vm"
    ;;
  status)
    [[ $# -eq 4 ]] || { usage; exit 2; }
    request GET "/nodes/$2/$3/$4/status/current"
    ;;
  start|stop|reboot)
    [[ $# -eq 4 ]] || { usage; exit 2; }
    request POST "/nodes/$2/$3/$4/status/${action}"
    ;;
  clone-vm)
    [[ $# -ge 5 && $# -le 6 ]] || { usage; exit 2; }
    post_args=(--data-urlencode "newid=$4" --data-urlencode "name=$5" --data-urlencode "full=1")
    [[ -n "${6:-}" ]] && post_args+=(--data-urlencode "storage=$6")
    request POST "/nodes/$2/qemu/$3/clone" "${post_args[@]}"
    ;;
  create-lxc)
    [[ $# -ge 5 && $# -le 6 ]] || { usage; exit 2; }
    storage="${6:-local-lvm}"
    ssh_key_file="${SSH_PUBLIC_KEY_PATH:-${HOME}/.ssh/id_ed25519.pub}"
    [[ -r "${ssh_key_file}" ]] || { printf 'Cannot read SSH public key: %s\n' "${ssh_key_file}" >&2; exit 1; }
    request POST "/nodes/$2/lxc" \
      --data-urlencode "vmid=$3" \
      --data-urlencode "hostname=$4" \
      --data-urlencode "ostemplate=$5" \
      --data-urlencode "rootfs=${storage}:8" \
      --data-urlencode "cores=1" \
      --data-urlencode "memory=1024" \
      --data-urlencode "unprivileged=1" \
      --data-urlencode "net0=name=eth0,bridge=vmbr0,ip=dhcp" \
      --data-urlencode "ssh-public-keys@${ssh_key_file}" \
      --data-urlencode "start=1"
    ;;
  *)
    usage
    exit 2
    ;;
esac

