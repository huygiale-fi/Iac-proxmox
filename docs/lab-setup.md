# Chuẩn bị lab trên cluster `lvs-demo`

## Phạm vi đã chốt

- API endpoint dự kiến: `https://10.200.101.21:8006/` (xác nhận bằng URL trình duyệt).
- Target node: `pve2`.
- Resource pool: `Staging`.
- Triển khai LXC trước; chỉ bật VM sau khi xác nhận template cloud-init.

Không dùng pool `Production`, storage `BACKUP`, hoặc thay đổi network của node trong demo.

## Thông tin quản trị viên cần xác nhận

Chạy trên `pve2`:

```bash
pvesh get /nodes/pve2/status
pvesh get /nodes/pve2/storage
pvesh get /nodes/pve2/network --type bridge
cat /etc/network/interfaces
ip route
pveam list local
pvesh get /cluster/resources --type vm --output-format yaml
pvesh get /cluster/nextid
```

Chốt năm giá trị trước khi chạy `terraform plan` có tài nguyên:

1. `datastore_id`: storage hỗ trợ `images,rootdir` trên `pve2`.
2. `bridge`: bridge/VNet dành cho Staging, không phải mạng Ceph/cluster.
3. `gateway`: gateway của subnet guest.
4. `lxc_template_file_id`: Ubuntu template đã có trên node/storage.
5. IP chưa sử dụng cho VM và LXC.

## Quyền API tối thiểu theo phạm vi

Tạo user/token riêng cho demo. Gán quyền quản lý VM vào `/pool/Staging`, quyền cấp phát vào đúng storage, quyền đọc `pve2`, và quyền clone vào đúng template VM. Không gán `Administrator` ở `/`.

Token được truyền qua biến môi trường và không ghi vào Git:

```bash
export PROXMOX_VE_ENDPOINT='https://10.200.101.21:8006/'
export PROXMOX_VE_API_TOKEN='terraform-demo@pve!iac-demo=REPLACE_WITH_SECRET'
export PROXMOX_VE_INSECURE='true'
```

Kiểm tra API trước:

```bash
./scripts/check-proxmox-api.sh
```

## Hai cổng kết nối khác nhau

- Terraform gọi Proxmox API qua TCP `8006`.
- Ansible SSH vào IP của guest qua TCP `22`.

Máy Windows/WSL chạy demo phải truy cập được cả endpoint Proxmox và subnet guest. Nếu chỉ API hoạt động nhưng guest SSH không tới được, Terraform vẫn tạo được máy nhưng Ansible sẽ không chạy.

