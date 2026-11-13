# Al Baraka Bank Assistant & RAGLab — Pack de déploiement autonome (`albaraka-demo`)

Pack d'exécution autonome permettant de lancer l'intégralité de la plateforme via **Docker** uniquement (sans code source et sans installer Java, Node.js ou Python), à partir des images publiées sur le compte Docker Hub d'**Ayari Farah** (`elayarifarah`) :

- `elayarifarah/albaraka-raglab:latest`
- `elayarifarah/albaraka-backend:latest`
- `elayarifarah/albaraka-frontend:latest`

---

## 1. Prérequis

- **Docker Desktop** (Windows / macOS) ou **Docker Engine + Docker Compose** (Linux) installé et démarré.
- Le port local `8080` disponible sur la machine.

---

## 2. Démarrage rapide

### Étape 1 — Clés API (avant le lancement ou depuis l'interface web)
Ouvrez le fichier `config/api-keys.env` et renseignez vos clés fournisseurs :

```env
NVIDIA_API_KEY=nvapi-...
XKIRO_API_KEY=sk-...
```

> **Astuce :** vous pouvez laisser ce fichier vide au premier lancement et saisir ou modifier vos clés directement depuis le back-office une fois l'application ouverte. Toute modification effectuée dans l'interface est automatiquement enregistrée dans `config/api-keys.env`.

### Étape 2 — Lancer la plateforme
Ouvrez un terminal (PowerShell / Bash) dans le dossier `albaraka-demo` puis exécutez :

```bash
docker compose pull
docker compose up -d
```

*(Vous pouvez également lancer `start.bat` sous Windows ou `./start.sh` sous Linux / macOS).*

Patientez environ 30 à 60 secondes jusqu'à ce que tous les conteneurs soient prêts (`docker compose ps`), puis ouvrez votre navigateur sur :

- **Application web :** `http://localhost:8080`

---

## 3. Comptes de démonstration par défaut

| Rôle | Adresse e-mail | Mot de passe |
| :--- | :--- | :--- |
| Administrateur (Back-office) | `admin@albaraka.tn` | `postgres` |
| Portail Client | `client@albaraka.tn` | `client123` |

---

## 4. Indexation initiale du corpus (une seule fois)

1. Connectez-vous sur `http://localhost:8080` avec le compte administrateur (`admin@albaraka.tn` / `postgres`).
2. Si vous n'avez pas encore renseigné vos clés API dans `config/api-keys.env`, rendez-vous dans **Administration → RAGLab → Paramètres → Clés API (`.env`)** et enregistrez vos clés.
3. Rendez-vous dans **Administration → RAGLab → Corpus / Statut** puis lancez l'indexation afin de construire l'index vectoriel sur les documents bancaires intégrés (environ une minute lors de la toute première exécution ; l'index reste ensuite conservé dans un volume Docker persistant).

---

## 5. Commandes utiles

```bash
# Vérifier l'état des conteneurs
docker compose ps

# Consulter les journaux en temps réel
docker compose logs -f

# Arrêter la plateforme en conservant la base de données et l'index vectoriel
docker compose down

# Arrêter la plateforme et réinitialiser toutes les données (remise à zéro complète)
docker compose down -v
```
