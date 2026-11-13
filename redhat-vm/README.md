# Al Baraka Bank Tunisia — Red Hat / Rocky Linux 9 Cloud VM Appliance (`redhat-vm`)

Machine virtuelle Linux d'entreprise **minimale, compressée et prête au transport/déploiement** (100 % compatible binaire **Red Hat Enterprise Linux 9** via *Rocky Linux 9 Minimal Cloud*), intégrant directement le moteur Docker et les **4 conteneurs pré-embarqués** de la plateforme Al Baraka (`postgres` pgvector 16, `albaraka-raglab`, `albaraka-backend`, `albaraka-frontend`).

---

## 1. Fichiers générés (prêts à transporter et importer)

| Fichier | Format | Hyperviseurs cibles | Contenu |
| :--- | :--- | :--- | :--- |
| `albaraka-rhel9-appliance.ova` | **OVA (OVF 1.0 + VMDK compressé)** | **VMware ESXi / vSphere**, **VMware Workstation**, **VirtualBox** | OS Rocky/RHEL 9 minimal + Docker CE + 4 images pré-embarquées + démarrage auto `systemd` |
| `albaraka-rhel9-cloud.qcow2` | **QCOW2 compressé (`zlib`)** | **KVM / QEMU**, **Proxmox VE**, **OpenStack**, **Red Hat OpenShift Virtualization** | Même disque compressé compatible `cloud-init` (`NoCloud`, `ConfigDrive`, `OVF`) |
| `SHA256SUMS.txt` | **SHA-256** | Vérification d'intégrité | Empreintes cryptographiques des images générées |

### Caractéristiques techniques de la VM
- **Système :** Rocky Linux 9 Minimal Cloud (`x86_64`, compatible RHEL 9, `SELinux Enforcing`, `firewalld` actif : seuls `22/tcp` SSH et `8080/tcp` Web sont exposés).
- **Ressources par défaut :** `2 vCPU`, `4 Go RAM`, disque finement provisionné (*thin-provisioned*) de `16 Go` (taille du fichier transporté réduite par `fstrim` + compression `zlib`/`streamOptimized`).
- **Fonctionnement hors-ligne (Pre-baked) :** Les 4 images Docker (`pgvector/pgvector:pg16` + `elayarifarah/albaraka-{raglab,backend,frontend}:latest`) sont déjà stockées dans `/var/lib/docker`. Dès la mise sous tension, `albaraka-stack.service` démarre toute la plateforme automatiquement sans nécessiter d'accès à Docker Hub.
- **Détection automatique d'adresse IP & CORS :** À chaque démarrage ou changement DHCP, `/usr/local/bin/albaraka-boot-sync.sh` affiche l'URL exacte `http://<IP-DE-LA-VM>:8080` directement sur l'écran console de la VM et met à jour `CORS_ALLOWED_ORIGINS`.

---

## 2. Déploiement rapide de la VM transportée

### Option A — VMware ESXi / vSphere / Workstation ou VirtualBox (`.ova`)
1. Importez le fichier **`albaraka-rhel9-appliance.ova`** (*Deploy OVF Template* dans vSphere/ESXi ou *Importer un appareil virtuel* dans VirtualBox / Workstation).
2. Choisissez le réseau souhaité (*Bridged* / réseau LAN de la banque pour un accès direct depuis d'autres postes, ou *NAT* avec redirection du port `8080` vers `8080`).
3. Démarrez la VM et patientez ~30 secondes : l'écran de la console affiche automatiquement l'adresse IP attribuée, par exemple `http://192.168.1.50:8080`.
4. Ouvrez cette URL dans votre navigateur.

### Option B — KVM / Proxmox VE / OpenStack (`.qcow2`)
```bash
# Exemple direct avec QEMU / KVM (redirige le port local 8080 vers la VM) :
qemu-system-x86_64 -enable-kvm -cpu host -smp 2 -m 4096 \
  -drive file=albaraka-rhel9-cloud.qcow2,format=qcow2,if=virtio \
  -nic user,hostfwd=tcp::8080-:8080,hostfwd=tcp::2222-:22
```
Sur **Proxmox VE** :
```bash
qm create 900 --name albaraka-rhel9 --memory 4096 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 900 albaraka-rhel9-cloud.qcow2 local-lvm
qm set 900 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-900-disk-0 --boot order=scsi0
qm start 900
```

---

## 3. Identifiants par défaut & Configuration des clés API

### Accès Système (Console VM / SSH)
- **Utilisateur Linux (`sudo` + `docker`) :** `albaraka`
- **Mot de passe initial :** `ChangeMe-AlBaraka-2026!` *(à modifier après déploiement via `passwd`)*

### Accès Application Web (`http://<IP-VM>:8080`)
- **Administrateur (Back-office) :** `admin@albaraka.tn` / `postgres`
- **Client Démo :** `client@albaraka.tn` / `client123`

### Saisie des clés API (`NVIDIA_API_KEY` / `XKIRO_API_KEY`)
1. **Depuis le navigateur (sans SSH) :** Connectez-vous en administrateur puis ouvrez **Administration → RAGLab → Paramètres → Clés API (`.env`)** (`/admin/raglab/settings?tab=keys`).
2. **Ou depuis le terminal de la VM :**
   ```bash
   sudo albaraka-ctl set-keys
   ```

### Commandes d'administration intégrées (`albaraka-ctl`)
```bash
sudo albaraka-ctl status         # Affiche l'IP, l'URL et l'état des 4 conteneurs
sudo albaraka-ctl logs           # Suit les journaux en direct
sudo albaraka-ctl restart        # Redémarre proprement les 4 conteneurs
sudo albaraka-ctl update-images  # Met à jour les images depuis Docker Hub (si connecté)
```

---

## 4. Reconstruire la VM (Cloud GitHub Actions ou Localement)

### A. Téléchargement / Génération automatique via GitHub Actions
Le workflow `.github/workflows/build-redhat-vm.yml` construit automatiquement les deux images (`.ova` et `.qcow2`) sur une machine cloud KVM et les publie dans :
- **GitHub Releases** (`redhat-vm-latest`) pour un téléchargement direct en un clic,
- **GitHub Actions Artifacts** sur l'exécution du workflow.

### B. Construction locale sous Linux / WSL2
```bash
chmod +x redhat-vm/build-vm.sh
./redhat-vm/build-vm.sh
# Pour utiliser une image Red Hat Enterprise Linux 9 officielle (Red Hat Developer) :
# ./redhat-vm/build-vm.sh --base-image /chemin/vers/rhel-9-x86_64-kvm.qcow2
```
