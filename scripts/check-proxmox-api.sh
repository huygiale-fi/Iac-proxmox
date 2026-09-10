#!/usr/bin/env bash
set -euo pipefail

required=(PROXMOX_VE_ENDPOINT PROXMOX_VE_API_TOKEN)
for name in "${required[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    printf 'Missing environment variable: %s\n' "${name}" >&2
    exit 1
  fi
done

endpoint="${PROXMOX_VE_ENDPOINT%/}/api2/json"
curl_args=(--fail-with-body --silent --show-error)
if [[ "${PROXMOX_VE_INSECURE:-false}" == "true" ]]; then
  curl_args+=(--insecure)
fi

auth="Authorization: PVEAPIToken=${PROXMOX_VE_API_TOKEN%%=*}=${PROXMOX_VE_API_TOKEN#*=}"

printf 'API version:\n'
curl "${curl_args[@]}" --header "${auth}" "${endpoint}/version" | jq '.data'

printf '\nVisible nodes:\n'
curl "${curl_args[@]}" --header "${auth}" "${endpoint}/nodes" \
  | jq '.data[] | {node, status, cpu, maxcpu, mem, maxmem}'

