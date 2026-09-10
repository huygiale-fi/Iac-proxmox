# Demo IaC trên Proxmox: Terraform + Ansible + REST API

Demo tạo một QEMU VM và một LXC trên Proxmox bằng Terraform, sau đó Ansible cài Nginx và xuất bản trang xác nhận. Script REST API minh họa cách hệ thống bên ngoài có thể truy vấn và điều khiển cùng hạ tầng.

Mặc định hiện tại dành cho cluster `lvs-demo`: target `pve2`, pool `Staging`, và chỉ tạo LXC trước. Xem checklist an toàn tại [`docs/lab-setup.md`](docs/lab-setup.md).

## Kiến trúc demo

```text
Người trình bày
   ├── Terraform ── Proxmox API ──> VM + LXC
   ├── Ansible   ── SSH ──────────> Nginx + trang demo
   └── REST API  ── HTTPS ────────> list/status/start/stop/reboot/clone/create
```

Terraform giữ **desired state** và phát hiện drift. Ansible đảm bảo cấu hình bên trong máy là idempotent. REST API cho thấy lớp nền mà các công cụ tự động hóa có thể tích hợp trực tiếp.

## Chuẩn bị

- Terraform >= 1.6, Ansible, `curl`, `jq`.
- Một Proxmox node và API token đủ quyền trên pool/storage dùng cho demo.
- VM template hỗ trợ cloud-init, có `qemu-guest-agent` đang bật.
- Một Ubuntu LXC template đã tải vào Proxmox.
- DHCP reservation hoặc hai địa chỉ IP tĩnh còn trống; máy chạy demo phải SSH được tới chúng.

Không commit token hoặc `terraform.tfvars`. Với môi trường thật, dùng chứng thư TLS tin cậy và để `proxmox_insecure = false`.

## Chạy demo

```bash
cd proxmox-iac-demo
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Sửa storage, bridge, template ID, template LXC, IP và gateway.

export PROXMOX_VE_ENDPOINT='https://10.200.101.21:8006/'
export PROXMOX_VE_API_TOKEN='terraform-demo@pve!iac-demo=REPLACE_WITH_SECRET'
export PROXMOX_VE_INSECURE='true' # Chỉ dùng khi cluster dùng TLS tự ký.

make check-api
make init
make validate
make plan
make apply
make configure
```

Mở các URL từ lệnh sau để thấy trang được Ansible cấu hình:

```bash
terraform -chdir=terraform output demo_urls
```

Chạy lại `make plan` để chứng minh tính idempotent: kỳ vọng **No changes**. Có thể sửa `memory.dedicated`, chạy lại plan/apply và cho khán giả xem thay đổi có kiểm soát.

## Demo REST API

```bash
export PVE_ENDPOINT='https://pve.lab.local:8006'
export PVE_TOKEN_ID='terraform@pve!provider'
export PVE_TOKEN_SECRET='REPLACE_WITH_SECRET'
export PVE_INSECURE=true # Chỉ dùng trong lab có TLS tự ký.

./scripts/proxmox-api.sh list
./scripts/proxmox-api.sh status pve qemu 201
./scripts/proxmox-api.sh reboot pve qemu 201
```

Hai ví dụ tạo tài nguyên trực tiếp qua API (trả về UPID để theo dõi tác vụ):

```bash
./scripts/proxmox-api.sh clone-vm pve 9000 211 api-demo-vm local-lvm
./scripts/proxmox-api.sh create-lxc pve 212 api-demo-lxc \
  'local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst' local-lvm
```

Không tạo cùng ID bằng cả Terraform và script API. Nếu một tài nguyên đã được tạo ngoài Terraform, hãy import nó trước khi quản lý bằng Terraform.

## Kịch bản thuyết trình 7 phút

1. **30 giây:** mở `terraform/main.tf`, giải thích desired state và API token.
2. **90 giây:** chạy `make plan`; nhấn mạnh Terraform cho biết trước những gì sẽ thay đổi.
3. **2 phút:** chạy `make apply`; quan sát VM và LXC xuất hiện trên giao diện Proxmox.
4. **1 phút:** chạy `make configure`; mở hai URL Nginx và chỉ ra VM/LXC được cấu hình giống nhau.
5. **1 phút:** chạy lại `make plan` để thấy `No changes` — idempotency.
6. **1 phút:** chạy API `list` và `status`; giải thích tích hợp portal, chatbot hoặc pipeline.
7. **30 giây:** kết luận lợi ích: lặp lại được, review được, giảm thao tác tay, dễ audit và rollback bằng Git.

## Dọn lab

Xem kỹ plan trước khi xóa, sau đó:

```bash
make destroy
```

Tài nguyên tạo trực tiếp bằng REST API không nằm trong Terraform state và phải được dọn riêng hoặc import vào Terraform.

## Lưu ý thực tế

- API token chịu quyền của cả user và token khi bật privilege separation. Hãy cấp quyền tối thiểu cần thiết.
- Một số thao tác Proxmox đặc quyền không hoạt động qua API token dù role rộng; tránh các feature LXC đặc quyền trong demo.
- Nếu VM apply chờ lâu, kiểm tra `qemu-guest-agent` trong template. Provider cần agent hoạt động để đọc trạng thái/IP.
- File inventory Ansible được sinh từ Terraform output và bị bỏ qua bởi Git.
