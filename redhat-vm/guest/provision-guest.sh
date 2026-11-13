#!/usr/bin/env bash
# =============================================================================
# Al Baraka Red Hat / Rocky Linux 9 Cloud Appliance — Guest Provisioner
# =============================================================================
# Executed inside QEMU/KVM during image build via cloud-init NoCloud seed.
# Streams all output over /dev/ttyS0 to the host builder and emits an explicit
# sentinel before powering off so partial builds can never pass silently.
# =============================================================================
set -Eeuo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

on_error() {
  local exit_code=$?
  local line_no="${1:-unknown}"
  echo ""
  echo "[FATAL] Guest provisioning failed at line ${line_no} (exit=${exit_code})"
  echo "===ALBARAKA_VM_BUILD_FAILED==="
  sync || true
  /usr/sbin/poweroff -f || true
  exit "${exit_code}"
}
trap 'on_error ${LINENO}' ERR

PREBAKE="${PREBAKE_IMAGES:-1}"
VM_ADMIN_USER="${VM_ADMIN_USER:-albaraka}"
VM_ADMIN_PASS="${VM_ADMIN_PASS:-ChangeMe-AlBaraka-2026!}"

echo "========================================================================"
echo "[1/9] Starting Al Baraka Red Hat / Rocky Linux 9 Appliance Provisioning"
echo "========================================================================"
uname -a
cat /etc/redhat-release || true
df -h /

# Ensure root filesystem spans the resized virtual disk.
ROOT_SRC="$(findmnt -n -o SOURCE / || true)"
if [[ "${ROOT_SRC}" =~ ^/dev/([a-z]+)([0-9]+)$ ]]; then
  DISK_DEV="/dev/${BASH_REMATCH[1]}"
  PART_NUM="${BASH_REMATCH[2]}"
  growpart "${DISK_DEV}" "${PART_NUM}" || true
  xfs_growfs / || resize2fs "${ROOT_SRC}" || true
fi
df -h /

echo "========================================================================"
echo "[2/9] Configuring hostname, admin account (${VM_ADMIN_USER}) & SSH"
echo "========================================================================"
hostnamectl set-hostname albaraka-vm || echo "albaraka-vm" > /etc/hostname

if ! id -u "${VM_ADMIN_USER}" >/dev/null 2>&1; then
  useradd -m -s /bin/bash -G wheel "${VM_ADMIN_USER}"
fi
echo "${VM_ADMIN_USER}:${VM_ADMIN_PASS}" | chpasswd
echo "${VM_ADMIN_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-albaraka
chmod 0440 /etc/sudoers.d/90-albaraka

# OpenSSH in RHEL 9 / Rocky 9 uses first-match-wins across sshd_config.d/*.conf.
# Naming 01-albaraka.conf ensures PasswordAuthentication overrides 50-cloud-init.conf.
mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/01-albaraka.conf <<'EOF'
PasswordAuthentication yes
KbdInteractiveAuthentication yes
PermitRootLogin no
UseDNS no
EOF
systemctl reload sshd || true

echo "========================================================================"
echo "[3/9] Installing minimal system packages, firewalld & Docker CE"
echo "========================================================================"
dnf install -y --setopt=install_weak_deps=False --nodocs \
  dnf-plugins-core \
  firewalld \
  tar \
  curl \
  iproute \
  procps-ng \
  ca-certificates

# Configure and start firewalld BEFORE Docker so Docker registers its chains cleanly.
# Keep external NIC in `public` zone (only 22/tcp SSH and 8080/tcp Web open), while
# trusting Docker's internal bridge range (172.16.0.0/12) so RHEL 9 nftables never
# blocks inter-container traffic (frontend -> backend -> postgres/raglab).
systemctl enable --now firewalld
firewall-cmd --set-default-zone=public
firewall-cmd --permanent --zone=public --add-service=ssh
firewall-cmd --permanent --zone=public --add-port=8080/tcp
firewall-cmd --permanent --zone=public --add-masquerade
firewall-cmd --permanent --zone=trusted --add-source=172.20.0.0/14
firewall-cmd --reload
firewall-cmd --list-all
firewall-cmd --zone=trusted --list-all

dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y --setopt=install_weak_deps=False --nodocs \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-compose-plugin

usermod -aG docker "${VM_ADMIN_USER}"

mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-address-pools": [
    {
      "base": "172.20.0.0/14",
      "size": 24
    }
  ]
}
EOF

systemctl enable --now docker
docker --version
docker compose version

echo "========================================================================"
echo "[4/9] Installing Al Baraka stack, helper CLI & systemd units"
echo "========================================================================"
mkdir -p /tmp/albaraka-stage
tar -xzf /var/lib/albaraka-bootstrap/albaraka-payload.tar.gz -C /tmp/albaraka-stage

mkdir -p /opt/albaraka/config
cp /tmp/albaraka-stage/stack/docker-compose.yml /opt/albaraka/docker-compose.yml
cp /tmp/albaraka-stage/stack/.env.example /opt/albaraka/.env
cp /tmp/albaraka-stage/stack/config/api-keys.env /opt/albaraka/config/api-keys.env
chmod 0777 /opt/albaraka/config
chmod 0666 /opt/albaraka/config/api-keys.env
chmod 0644 /opt/albaraka/docker-compose.yml /opt/albaraka/.env

install -o root -g root -m 0755 /tmp/albaraka-stage/guest/albaraka-boot-sync.sh /usr/local/bin/albaraka-boot-sync.sh
install -o root -g root -m 0755 /tmp/albaraka-stage/guest/albaraka-ctl /usr/local/bin/albaraka-ctl
mkdir -p /etc/NetworkManager/dispatcher.d
install -o root -g root -m 0755 /tmp/albaraka-stage/guest/90-albaraka-ip /etc/NetworkManager/dispatcher.d/90-albaraka-ip
install -o root -g root -m 0644 /tmp/albaraka-stage/guest/albaraka-stack.service /etc/systemd/system/albaraka-stack.service

systemctl daemon-reload
systemctl enable albaraka-stack.service
/usr/local/bin/albaraka-boot-sync.sh

if [ "${PREBAKE}" = "1" ]; then
  echo "========================================================================"
  echo "[5/9] Pre-pulling all 4 container images into VM disk (offline-ready)"
  echo "========================================================================"
  docker compose --project-directory /opt/albaraka -f /opt/albaraka/docker-compose.yml pull
  docker images

  echo "========================================================================"
  echo "[6/9] Running live end-to-end verification inside Rocky Linux 9 VM"
  echo "========================================================================"
  systemctl start albaraka-stack.service

  READY=0
  for attempt in $(seq 1 45); do
    if curl -fsS http://127.0.0.1:8080/ >/dev/null 2>&1 \
       && curl -fsS http://127.0.0.1:8080/api/news/active >/dev/null 2>&1; then
      READY=1
      echo "[OK] Full 4-container stack verified healthy at attempt ${attempt}!"
      break
    fi
    sleep 4
  done

  docker compose --project-directory /opt/albaraka -f /opt/albaraka/docker-compose.yml ps
  if [ "${READY}" -ne 1 ]; then
    echo "[ERROR] Stack did not become ready during live guest verification!"
    docker compose --project-directory /opt/albaraka -f /opt/albaraka/docker-compose.yml logs --tail=80 || true
    exit 1
  fi

  # Reset ephemeral volumes so every deployed VM starts with a clean database & fresh runtime state,
  # while keeping 100% of the 4 container images pre-baked in /var/lib/docker.
  systemctl stop albaraka-stack.service
  docker compose --project-directory /opt/albaraka -f /opt/albaraka/docker-compose.yml down -v
  docker images
else
  echo "[5/9] Skipping image pre-bake (slim mode: images will pull on first boot)."
  echo "[6/9] Skipping live container smoke test in slim mode."
fi

echo "========================================================================"
echo "[7/9] Enabling multi-hypervisor boot drivers (VMware, VirtualBox & KVM)"
echo "========================================================================"
# Remove redundant unstripped rescue initramfs (~100 MB) to shrink boot partition.
rm -f /boot/*-rescue-* || true

KVER="$(uname -r)"
NEED_KMODS=0
for req_mod in ahci e1000 e1000e vmxnet3 vmw_pvscsi; do
  if ! modinfo -k "${KVER}" "${req_mod}" >/dev/null 2>&1; then
    NEED_KMODS=1
  fi
done
if [ "${NEED_KMODS}" -eq 1 ]; then
  dnf install -y --setopt=install_weak_deps=False --nodocs "kernel-modules-${KVER}" \
    || dnf install -y --setopt=install_weak_deps=False --nodocs kernel-modules \
    || true
fi

mkdir -p /etc/dracut.conf.d
for kdir in /lib/modules/*; do
  [ -d "${kdir}" ] || continue
  kver="$(basename "${kdir}")"
  AVAIL_MODS=""
  for mod in virtio_blk virtio_scsi virtio_net virtio_pci ahci libahci ata_piix sd_mod sr_mod vmw_pvscsi mptspi mptsas vmxnet3 e1000 e1000e nvme; do
    if modinfo -k "${kver}" "${mod}" >/dev/null 2>&1; then
      AVAIL_MODS="${AVAIL_MODS} ${mod}"
    fi
  done
  cat > /etc/dracut.conf.d/99-hypervisors.conf <<EOF
hostonly="no"
add_drivers+=" ${AVAIL_MODS} "
EOF
  dracut -f "/boot/initramfs-${kver}.img" "${kver}"
done

echo "========================================================================"
echo "[8/9] Sealing network, cloud-init, SELinux contexts & logs"
echo "========================================================================"
# Ensure any virtual NIC (e1000, vmxnet3, virtio) gets DHCP automatically on any hypervisor.
rm -f /etc/NetworkManager/system-connections/cloud-init-*.nmconnection || true
rm -f /etc/NetworkManager/conf.d/*no-auto-default* || true
rm -f /var/lib/NetworkManager/no-auto-default.state || true
rm -f /etc/sysconfig/network-scripts/ifcfg-eth* || true

# Prevent 2-minute EC2 metadata waits when booting offline in VirtualBox / VMware,
# while still supporting NoCloud / ConfigDrive / OVF in OpenStack, Proxmox & vSphere.
mkdir -p /etc/cloud/cloud.cfg.d
cat > /etc/cloud/cloud.cfg.d/99-albaraka-appliance.cfg <<'EOF'
datasource_list: [ NoCloud, ConfigDrive, OVF, None ]
ssh_pwauth: true
preserve_hostname: false
EOF

# Refresh generic pre-boot console banner before IP assignment.
sed -i 's|^CORS_ALLOWED_ORIGINS=.*|CORS_ALLOWED_ORIGINS=http://localhost:8080,http://127.0.0.1:8080,http://localhost:4200|' /opt/albaraka/.env
cat > /etc/issue <<'EOF'
========================================================================
  Al Baraka Bank Tunisia — Governed AI Platform (Red Hat / Rocky 9 VM)
------------------------------------------------------------------------
  Web Portal & Admin Console : http://<VM-IP>:8080
  VM Console / SSH Login     : albaraka  (initial pass: ChangeMe-AlBaraka-2026!)
  Stack Management CLI       : sudo albaraka-ctl status
========================================================================

EOF

restorecon -Rv /etc/ssh /etc/sudoers.d /etc/systemd/system /opt/albaraka /usr/local/bin /etc/NetworkManager/dispatcher.d /etc/issue /etc/motd || true

echo "========================================================================"
echo "[9/9] Shrinking filesystem (cleaning caches, logs & fstrim)"
echo "========================================================================"
# Remove temporary build-only bootstrap service & payload before sealing image.
rm -f /etc/systemd/system/albaraka-provision.service
rm -rf /var/lib/albaraka-bootstrap
systemctl daemon-reload || true

dnf clean all
rm -rf /var/cache/dnf/* /var/lib/dnf/repos/* /tmp/* /var/tmp/*
cloud-init clean --logs || true
rm -f /etc/ssh/ssh_host_* || true
journalctl --rotate || true
journalctl --vacuum-time=1s || true
find /var/log -type f -exec truncate -s 0 {} + || true
rm -f /root/.bash_history "/home/${VM_ADMIN_USER}/.bash_history" || true

sync
fstrim -av || true
df -h /

echo "===ALBARAKA_VM_BUILD_SUCCESS==="
sync
sleep 1
systemctl --no-block poweroff || /usr/sbin/poweroff -f
