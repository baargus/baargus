# Aurora — Arborescence & règles de rangement

> Machine : **Aurora** (Fedora Kinoite atomique, hostname `legion-aurora`), opérateur **Baptiste Sobocinski (baargus)**.
> Doc de référence du rangement du PC local. Versionnée dans `baargus/baargus` (survit au déménagement, accessible partout).
> Dernière mise à jour : 2026-06-08 (réorg `infra/` per-VPS, normalisation des 35 remotes, **suppression de la racine `~/devpro/` → 2 racines**).

---

## 1. Les 2 racines — jamais les mélanger

> **Changement 2026-06-08** : la racine `~/devpro/` a été **supprimée** ; tout son contenu (docs, runtime, archives) a fusionné sous `~/Projects/`. On passe de 3 à **2 racines**.

Le poste pro s'organise en **deux racines disjointes** (+ l'outillage racine `~/`, cf. §5) :

| Racine | Rôle | Git ? |
|---|---|---|
| **`~/Projects/`** | **CODE + DOCS/DATA/RUNTIME** — repos git rangés par catégorie (§2) **+** dossiers spéciaux non-git `devops-knowledge/`, `local/`, `_archives/` (§3) | partiel |
| **`~/Documents/`** | **PRIVÉ** — perso, administratif, formations | non |

**Règle d'or** : du code = un repo git dans une catégorie de `Projects/` ; la doc transverse, le runtime et les archives = dossiers spéciaux dédiés de `Projects/` (jamais mélangés au code) ; le perso reste dans `Documents/`. En cas de doute → voir §4.

---

## 2. `~/Projects/` — le code (catégories de repos)

Convention : **`~/Projects/<catégorie>/<repo>/`**. Un repo = un dossier git. Catégories de code actuelles (les dossiers spéciaux non-git `devops-knowledge/`, `local/`, `_archives/` sont décrits en §3) :

```
devbox/            cloud · sovereign
security-projects/ clean · digital-shield · kidshield · smishguard
infra/             bootstrap · llm-stack-local · stacks · vps1-prod · vps2-monitoring-supervision · vps3-hermes · vps4-memory · windmill-automation
meta/              baargus · devprosp-skills
podcast/           podcast-stack
products/          certforge · content-studio · datahub · egide
sage/              core · ecosystem · orchestrator · security-vault
tools/             api-key-rotator · assistant-local-multi-llm · devpro_scripts · devpro-tools · llm-privacy-proxy · OSINT
web/               devpro-portal · fabienne-etiopathe/{backend,frontend}
_vendor/           aider-fork  (fork upstream externe, NE PAS ranger ailleurs)
```

**Remotes :**
- **Source de vérité = Gitea** : `ssh://git@git.devprosp.com:2222/devpro-sp/<repo>.git` — **format explicite canonique** (normalisation des 35 remotes le 8 juin 2026 : fini l'alias `gitea-self` et les variantes sans `git@`/sans port).
- Quelques repos perso sous l'org `baargus/` (ex. `baargus/baargus`).
- **GitHub = miroir uniquement** (push-mirror). Jamais la source de vérité.

**Cas particuliers :**
- `web/fabienne-etiopathe/` est un **conteneur** (pas un repo) abritant 2 repos : `backend/` + `frontend/`.
- `_vendor/` héberge les forks d'upstreams externes (remote ≠ devpro-sp), à isoler du code maison.

---

## 3. Dossiers spéciaux sous `~/Projects/` (non-git)

Depuis la suppression de `~/devpro/` (2026-06-08), les dossiers non-code vivent **directement sous `~/Projects/`**, à côté des catégories de repos :

| Dossier | Ce qui a le droit d'y vivre |
|---|---|
| **`local/`** | **runtime** des outils self-hosted locaux (config, workspaces). Le code y vivant doit être **versionné dans une catégorie de `Projects/`** ; ici seulement la copie d'exécution. Contenu au 8 juin : `appflowy-selfhosted/`, `ollama-models/`. |
| **`_archives/`** | **quarantaine datée** : `<sujet>-AAAAMMJJ/`. Tout ce qu'on retire mais ne supprime pas encore. Contient les **backups défensifs VPS2** (`archives/`, `infra-backups/`, intouchables cf. §8) et **`secrets/`** (clé Borg SOPS). |
| **`devops-knowledge/`** | savoir transverse devops (ex-`devpro/knowledge/`) : `cert-manager-architecture.md`, `gitops-cluster-pattern.md`, `cloudflare-tokens.md`, etc. |

**`local/` n'est pas la data des conteneurs** : les volumes Podman vivent ailleurs (ex. `ollama-models/` y est vide — les modèles sont dans un volume). `local/` = config + scratch.

> **Note** : l'ancien `devpro/infra-docs/` (catégorie héritée) était un **squelette vide** — supprimé le 8 juin, **rien perdu**. Son rôle est déjà couvert par `infra/stacks/docs/` (servers, adr, audits, runbooks, migration) et `devops-knowledge/` (doc transverse) ; **ne pas le recréer**. Côté secrets SOPS transverses : seul `_archives/secrets/` subsiste (clé Borg), pas de `Projects/secrets/` dédié — à clarifier si un besoin réapparaît.

---

## 4. Règles de rangement (où va quoi)

- **Nouveau projet de code** → `~/Projects/<catégorie>/<nom>/`, `git init`, remote `ssh://git@git.devprosp.com:2222/devpro-sp/<nom>.git`, push. Jamais ailleurs.
- **Doc liée à un repo** → `<repo>/docs/`. **Doc transverse** → `Projects/devops-knowledge/`.
- **Secret** → chiffré SOPS dès le départ (cf. §6). Jamais de `.env` clair committé.
- **Backup / snapshot** → `Projects/_archives/<sujet>-AAAAMMJJ/` (daté). Vérifier la redondance avant toute purge (cf. §9).
- **Donnée régénérable / cache** → `local/` ou `_archives/`, jamais dans un repo (gitignore).

**Jamais committer** — artefacts d'éditeurs/IDE régénérables (gitignore **global** `~/.config/git/ignore` via `core.excludesFile`) :
```
.cursor/
.specstory/
.cursorindexingignore
.cursorrules
```
(Résidus d'anciens éditeurs IA, non utilisés — bloqués globalement pour qu'ils ne reviennent jamais polluer un repo. `.vscode/` en revanche est **conservé** : VSCodium est l'éditeur actif, cf. §8.)

---

## 5. Outillage racine `~/` (légitime en place — ne PAS ranger dans Projects)

| Dossier | Rôle |
|---|---|
| `~/bin/` | scripts ops (hardening Fedora, audit) — appelés par services systemd user |
| `~/scripts/` | déploiement + scripts de migration HOME — référencés par systemd |
| `~/go/` | cache `GOPATH` (`pkg/mod`) — peuplé par les builds sage |
| `~/dev-sovereign-home/` | HOME sandboxé du devbox `sovereign` (runtime) |
| `~/dev-sovereign-audit/` | logs d'audit du devbox sovereign |

Ce sont des emplacements **standard** pour scripts/outillage loose. On ne les déplace pas dans `Projects/`.

---

## 6. Conventions secrets

- **SOPS + age** partout. Clé age : `~/.config/sops/age/keys.txt`.
- Chaque repo qui porte des secrets a un **`.sops.yaml`** (`creation_rules` → recipient age) et range les `*.sops` dans `secrets/`.
- **`.gitignore` durci** : `.env*` ignorés, **exception `!*.sops`** pour versionner le chiffré. Toujours valider avec `git check-ignore` que le clair est ignoré ET le `.sops` suivi.
- **Jamais de secret en clair** dans le code, un commit, un log, ou un argument CLI. Clés API via KeePassXC, sops-age, ou variable d'env système.
- **Méthode chiffrer→prouver→supprimer** : chiffrer le clair en `.sops`, prouver le round-trip (`sops -d` ≡ clair), **seulement ensuite** supprimer le clair.
- Secret découvert exposé → **signaler + rotationner**.

---

## 7. Conventions machine

- **Chemins FR** : `~/Téléchargements/` (accent + T majuscule). Repos `~/Projects/<cat>/<repo>/` ; docs/runtime/archives sous `~/Projects/` (`devops-knowledge/` · `local/` · `_archives/`).
- **OS atomique** : Fedora Kinoite (rpm-ostree). Sur Aurora → **Flatpak ou conteneur (Quadlet)** uniquement, jamais d'install manuelle (AppImage/tarball).
- **Conteneurs** : Podman rootless + SELinux Enforcing + Quadlet. Container Quadlet = `systemctl --user` only (jamais `podman restart/stop`).
- **Shell zsh** — écrire **bash/POSIX portable** :
  - **word-split** : `for x in $var` n'itère PAS en zsh (pas de découpage). Utiliser une **liste littérale** (`for x in a b c`) ou un **array** (`"${arr[@]}"`).
  - **nomatch** : un glob sans correspondance (`rm foo-*`) **annule toute la commande** en zsh. Vérifier l'existence avant, ou chemins littéraux.
  - Ne jamais utiliser comme variable de boucle : `path`, `cdpath`, `manpath`, `fpath`, `status`, `signals`.
- **Cycle PROD (zero direct edit)** : audit → local → commit → push Gitea → pull VPS → restart. Pas de `sed` direct sur les fichiers de prod. Toujours un plan de rollback.

---

## 8. Zones INTOUCHABLES

- **Outils vivants dans `local/`** (conteneurs actifs) : **AppFlowy, ollama** (seuls présents au 8 juin). Ne pas toucher config ni data. _(AnythingLLM **abandonné/retiré** le 8 juin 2026.)_
- **Backups défensifs VPS2** dans `_archives/` (`archives/`, `infra-backups/`) : filet de rollback de la **migration VPS2 AlmaLinux en cours**. Ne pas purger tant que la migration n'est pas close.
- **`.vscode/`** : config de **VSCodium** (l'éditeur de code actif sur Aurora). Ne jamais supprimer ni gitignorer globalement.
- **Supports & repo de backup** : `KP_MAIN`, `KP_BACKUP`, `BACKUP_LEGION` et le repo `borg-legion/` (cf. §10). Ne pas trafiquer manuellement.

---

## 9. Anti-patterns vécus (à ne pas reproduire)

- **Squelettes d'arbo vides** : taxonomies créées puis jamais peuplées (ex. ancien `devpro/documents/`, `litiges/` dupliquant `~/Documents/`). → ne pas échafauder à vide ; peupler ou ne pas créer.
- **Doublons `devpro/` ↔ `Projects/`** (legacy, **résolu 2026-06-08**) : on avait le même nom des deux côtés (ex. `verticals/` sans git). → racine `devpro/` supprimée, tout consolidé sous `Projects/` ; ne plus jamais recréer de copie de travail hors de `Projects/`.
- **Build cache non gitignoré** : `target/` (Rust/Tauri), `node_modules/`, outputs générés gonflant l'arbo (ex. certforge 3 G de `target/debug/`). → toujours gitignorer ; ne jamais archiver le cache de build.
- **Données générées volumineuses mêlées au code** : corpus DILA (14 G), markdown générés. → séparer data (`local/`, gitignorée) du code (Gitea) ; ne committer que le pipeline, pas ses sorties.
- **Snapshots git à `git status` non vide** : un working-tree non committé dans un backup = travail unique présent nulle part ailleurs. → **inspecter `git status` / `git stash` AVANT toute purge** ; prouver la redondance par `git merge-base --is-ancestor <sha> <branche-remote>` (pas par `ls-remote | grep`, qui ne montre que les tips).
- **Secrets en clair dans des `.env` orphelins** : credentials prod traînant dans des dossiers oubliés. → chiffrer SOPS, supprimer le clair, vérifier la diffusion git.

---

## 10. Sauvegarde — backup hebdo Aurora

Système de sauvegarde local, **hebdomadaire, chiffré, vérifié des deux côtés**. Script + units versionnés dans `meta/baargus` (réinstallables après déménagement).

### Les 3 supports physiques (USB)
| Support | Rôle |
|---|---|
| **KP_MAIN**       | base KeePass **source de vérité** (`kdbx/*.kdbx` + `archives/`) |
| **KP_BACKUP**     | copie KeePass (propagée depuis KP_MAIN, vérifiée par hash) |
| **BACKUP_LEGION** | disque du **repo Borg chiffré** `borg-legion/` (+ archives datées) |

### Composants (versionnés dans `meta/baargus/`)
- `scripts/backup-aurora.sh` — le script (lancement manuel forcé : `--force`).
- `systemd/backup-aurora.{service,timer}` — copies réinstallables des units.

### Déroulé du script (fail-closed)
1. **Garde-fou** : les 3 supports montés ? sinon popup « branche… » (kdialog) ou report.
2. **Étape KeePass** : archive datée de MAIN **et** BACKUP → propage MAIN→KP_BACKUP → **vérif sha256** ; si hash ≠ → **abort avant Borg**.
3. **Étape Borg** : `borg create` (périmètre ci-dessous) + `borg check --last 1`.
4. **Marqueur** `~/.local/share/backup-aurora-last` (timestamp du dernier succès).

### Automatisation & persistance
- **Timer** : `OnStartupSec=2min` + `OnUnitActiveSec=4h` + `Persistent=true`.
- **Service** : `graphical-session.target` + env Wayland (`WAYLAND_DISPLAY`, `DBUS_SESSION_BUS_ADDRESS`, `XDG_RUNTIME_DIR`) → popup kdialog sur Wayland.
- **Logique « tant que pas fait »** : skip si dernier backup < 7 j ; sinon popup.
- **Anti-spam** : plafond **3 rappels/jour** (`backup-aurora-nag-AAAAMMJJ`), réarmé chaque jour.

### Périmètre Borg
- **Inclus** : `Documents` · `Projects` · `bin` · `scripts` · `.config`  _(`devpro` retiré — racine supprimée)_
- **Exclus** : `Projects/_archives` · `Projects/local` · `node_modules` · `target` · `.cache` · `go/pkg` · `__pycache__` · `.venv` · `dist` · `.next`

### Clé & passphrase
- Repo Borg chiffré ; **passphrase saisie via popup** (jamais dans le script).
- Clé de récupération exportée : `Projects/_archives/secrets/borg-legion-key.txt.sops` (chiffrée SOPS).

### Réinstaller (ex. à La Réunion)
```bash
cp ~/Projects/meta/baargus/systemd/backup-aurora.* ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now backup-aurora.timer
```
Restaurer une archive : `export BORG_REPO=/run/media/batewa/BACKUP_LEGION/borg-legion` puis `borg list` et `borg extract ::<archive>`.

---

*Maintenu par Baptiste Sobocinski (baargus) — architecte-garant DevSecOps.*
