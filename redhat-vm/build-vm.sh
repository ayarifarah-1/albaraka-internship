#!/usr/bin/env bash
# =============================================================================
# Al Baraka Bank Tunisia — Minimal Portable Red Hat (Rocky 9) Cloud VM Builder
# =============================================================================
# Produces BOTH:
#   1. out/albaraka-rhel9-cloud.qcow2      (Compressed QCOW2 for KVM/Proxmox/OpenStack)
#   2. out/albaraka-rhel9-appliance.ova    (Portable OVA for VMware ESXi/Workstation/VirtualBox)
#   3. out/SHA256SUMS.txt                  (Cryptographic checksums)
#
# Usage:
#   ./redhat-vm/build-vm.sh                         # Full pre-baked OVA + QCOW2
#   ./redhat-vm/build-vm.sh --slim                  # OS + Docker only (~650 MB, pulls on 1st boot)
#   ./redhat-vm/build-vm.sh --format ova            # Only .ova
#   ./redhat-vm/build-vm.sh --format qcow2          # Only .qcow2
#   ./redhat-vm/build-vm.sh --base-image rhel9.qcow2 # Custom RHEL 9 KVM qcow2
# =============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="${SCRIPT_DIR}/.cache"
WORK_DIR="${SCRIPT_DIR}/.build"
OUT_DIR="${SCRIPT_DIR}/out"

ROCKY_URL="https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
ROCKY_CHECKSUM_URL="${ROCKY_URL}.CHECKSUM"

PREBAKE_IMAGES="1"
FORMAT="both"
BASE_IMAGE=""
DISK_GB="16"
BUILD_CPUS="2"
BUILD_RAM_MB="4096"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --slim) PREBAKE_IMAGES="0"; shift ;;
    --format) FORMAT="${2:-both}"; shift 2 ;;
    --base-image) BASE_IMAGE="${2:-}"; shift 2 ;;
    --out-dir) OUT_DIR="${2:-}"; shift 2 ;;
    --disk-gb) DISK_GB="${2:-16}"; shift 2 ;;
    --cpus) BUILD_CPUS="${2:-2}"; shift 2 ;;
    --ram-mb) BUILD_RAM_MB="${2:-4096}"; shift 2 ;;
    -h|--help)
      sed -n '2,17p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

for bin in qemu-system-x86_64 qemu-img python3 curl tar; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "[ERROR] Missing required host tool: $bin" >&2
    echo "On Ubuntu/Debian: sudo apt-get install -y qemu-system-x86 qemu-utils cloud-image-utils xorriso curl python3" >&2
    echo "On RHEL/Rocky/Fedora: sudo dnf install -y qemu-kvm qemu-img xorriso curl python3" >&2
    exit 1
  fi
done

build_seed_iso() {
  local out_iso="$1"
  local user_data="$2"
  local meta_data="$3"
  if command -v cloud-localds >/dev/null 2>&1; then
    cloud-localds "${out_iso}" "${user_data}" "${meta_data}"
  elif command -v xorriso >/dev/null 2>&1; then
    xorriso -as mkisofs -output "${out_iso}" -volid cidata -joliet -rock "${user_data}" "${meta_data}" >/dev/null 2>&1
  elif command -v genisoimage >/dev/null 2>&1; then
    genisoimage -output "${out_iso}" -volid cidata -joliet -rock "${user_data}" "${meta_data}" >/dev/null 2>&1
  elif command -v mkisofs >/dev/null 2>&1; then
    mkisofs -output "${out_iso}" -volid cidata -joliet -rock "${user_data}" "${meta_data}" >/dev/null 2>&1
  else
    echo "[ERROR] Install one of: cloud-localds, xorriso, genisoimage, or mkisofs" >&2
    exit 1
  fi
}

mkdir -p "${CACHE_DIR}" "${OUT_DIR}"
rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}"

if [ -z "${BASE_IMAGE}" ]; then
  BASE_IMAGE="${CACHE_DIR}/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
  if [ ! -f "${BASE_IMAGE}" ]; then
    echo "[HOST] Downloading minimal Rocky Linux 9 Cloud base image (RHEL 9 binary-compatible)..."
    curl -fL --retry 3 -o "${BASE_IMAGE}.part" "${ROCKY_URL}"
    if curl -fsSL "${ROCKY_CHECKSUM_URL}" -o "${CACHE_DIR}/CHECKSUM" 2>/dev/null; then
      EXPECTED_SHA="$(awk '/^SHA256 \(Rocky-9-GenericCloud-Base.*\.x86_64\.qcow2\) = [0-9a-fA-F]{64}$/ {print $NF; exit}' "${CACHE_DIR}/CHECKSUM")"
      if [ -n "${EXPECTED_SHA}" ]; then
        ACTUAL_SHA="$(sha256sum "${BASE_IMAGE}.part" | awk '{print $1}')"
        if [ "${EXPECTED_SHA}" != "${ACTUAL_SHA}" ]; then
          echo "[ERROR] SHA256 mismatch on downloaded Rocky 9 image! Expected ${EXPECTED_SHA}, got ${ACTUAL_SHA}" >&2
          rm -f "${BASE_IMAGE}.part"
          exit 1
        fi
        echo "[HOST] Verified Rocky 9 base image SHA256: ${ACTUAL_SHA}"
      fi
    fi
    mv "${BASE_IMAGE}.part" "${BASE_IMAGE}"
  else
    echo "[HOST] Reusing cached base image: ${BASE_IMAGE}"
  fi
fi

WORK_QCOW2="${WORK_DIR}/working.qcow2"
cp "${BASE_IMAGE}" "${WORK_QCOW2}"
qemu-img resize "${WORK_QCOW2}" "${DISK_GB}G"

# Archive stack & guest management scripts into a compact base64 payload for cloud-init.
PAYLOAD_TGZ="${WORK_DIR}/albaraka-payload.tar.gz"
tar -C "${SCRIPT_DIR}" -czf "${PAYLOAD_TGZ}" stack guest
PAYLOAD_B64="$(base64 -w0 "${PAYLOAD_TGZ}")"
PROVISION_B64="$(base64 -w0 "${SCRIPT_DIR}/guest/provision-guest.sh")"

META_DATA="${WORK_DIR}/meta-data"
USER_DATA="${WORK_DIR}/user-data"
SEED_ISO="${WORK_DIR}/seed-cidata.iso"

cat > "${META_DATA}" <<'EOF'
instance-id: albaraka-build-seed-v1
local-hostname: albaraka-vm
EOF

cat > "${USER_DATA}" <<EOF
#cloud-config
output:
  all: '| tee -a /var/log/cloud-init-output.log > /dev/console'
write_files:
  - path: /var/lib/albaraka-bootstrap/albaraka-payload.tar.gz
    permissions: '0644'
    encoding: b64
    content: ${PAYLOAD_B64}
  - path: /var/lib/albaraka-bootstrap/provision-guest.sh
    permissions: '0755'
    encoding: b64
    content: ${PROVISION_B64}
  - path: /etc/systemd/system/albaraka-provision.service
    permissions: '0644'
    content: |
      [Unit]
      Description=Al Baraka Appliance Image Provisioner
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=simple
      Environment=PREBAKE_IMAGES=${PREBAKE_IMAGES}
      Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
      ExecStart=/bin/bash /var/lib/albaraka-bootstrap/provision-guest.sh
      StandardOutput=journal+console
      StandardError=journal+console
runcmd:
  - [ /bin/bash, -c, '/sbin/restorecon -Rv /etc/systemd/system /var/lib/albaraka-bootstrap || true; /usr/bin/systemctl daemon-reload; /usr/bin/systemctl start --no-block albaraka-provision.service || { echo "===ALBARAKA_VM_BUILD_FAILED===" > /dev/console; /sbin/poweroff -f; }' ]
EOF

build_seed_iso "${SEED_ISO}" "${USER_DATA}" "${META_DATA}"

ACCEL_ARGS=(-accel tcg -cpu max)
if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
  echo "[HOST] Hardware KVM acceleration detected (/dev/kvm)."
  ACCEL_ARGS=(-enable-kvm -cpu host)
else
  echo "[HOST] /dev/kvm not writable; falling back to QEMU TCG emulation (-cpu max)."
fi

SERIAL_LOG="${WORK_DIR}/serial.log"
echo "[HOST] Booting Rocky Linux 9 VM to install Docker, pre-bake images & shrink disk..."
set +e
timeout --foreground 2100 qemu-system-x86_64 \
  -machine q35 \
  "${ACCEL_ARGS[@]}" \
  -smp "${BUILD_CPUS}" \
  -m "${BUILD_RAM_MB}" \
  -display none \
  -serial stdio \
  -no-reboot \
  -device virtio-scsi-pci,id=scsi0 \
  -drive "file=${WORK_QCOW2},if=none,id=hd0,format=qcow2,discard=unmap,detect-zeroes=unmap" \
  -device scsi-hd,drive=hd0,bus=scsi0.0 \
  -drive "file=${SEED_ISO},if=none,id=cidata0,format=raw,readonly=on" \
  -device scsi-cd,drive=cidata0,bus=scsi0.0 \
  -netdev user,id=net0 \
  -device virtio-net-pci,netdev=net0 | tee "${SERIAL_LOG}"
set -e

if ! grep -q "===ALBARAKA_VM_BUILD_SUCCESS===" "${SERIAL_LOG}"; then
  echo "" >&2
  echo "[ERROR] Guest provisioning did not complete cleanly! Check serial log tail:" >&2
  tail -n 60 "${SERIAL_LOG}" >&2 || true
  exit 1
fi

echo "[HOST] Guest provisioning & live container smoke check succeeded!"

OUT_ARTIFACTS=()

if [ "${FORMAT}" = "both" ] || [ "${FORMAT}" = "qcow2" ]; then
  OUT_QCOW2="${OUT_DIR}/albaraka-rhel9-cloud.qcow2"
  echo "[HOST] Exporting compressed QCOW2 -> ${OUT_QCOW2} ..."
  qemu-img convert -p -c -O qcow2 -o compression_type=zlib "${WORK_QCOW2}" "${OUT_QCOW2}"
  chmod 0644 "${OUT_QCOW2}"
  OUT_ARTIFACTS+=("$(basename "${OUT_QCOW2}")")
fi

if [ "${FORMAT}" = "both" ] || [ "${FORMAT}" = "ova" ]; then
  OUT_OVA="${OUT_DIR}/albaraka-rhel9-appliance.ova"
  python3 "${SCRIPT_DIR}/scripts/export-ova.py" \
    --qcow2 "${WORK_QCOW2}" \
    --out "${OUT_OVA}" \
    --name "albaraka-rhel9-appliance" \
    --cpus 2 \
    --memory-mb 4096 \
    --disk-gb "${DISK_GB}"
  OUT_ARTIFACTS+=("$(basename "${OUT_OVA}")")
fi

# Free temporary uncompressed working qcow2 immediately.
rm -rf "${WORK_DIR}"

(
  cd "${OUT_DIR}"
  sha256sum "${OUT_ARTIFACTS[@]}" > SHA256SUMS.txt
  ls -lh "${OUT_ARTIFACTS[@]}" SHA256SUMS.txt
  cat SHA256SUMS.txt
)

echo ""
echo "[DONE] Portable Red Hat / Rocky Linux 9 Cloud VM artifacts ready in: ${OUT_DIR}"
