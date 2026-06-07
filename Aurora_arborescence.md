# Aurora — Arborescence & règles de rangement

> Machine : **Aurora** (Fedora Kinoite atomique, hostname `legion-aurora`), opérateur **Baptiste Sobocinski (baargus)**.
> Doc de référence du rangement du PC local. Versionnée dans `baargus/baargus` (survit au déménagement, accessible partout).
> Dernière mise à jour : 2026-06-07.

---

## 1. Les 3 racines — jamais les mélanger

Le poste pro s'organise en **trois racines disjointes**, chacune avec un rôle unique :

| Racine | Rôle | Git ? |
|---|---|---|
| **`~/Projects/`** | **CODE** — uniquement des repos git | oui (1 repo = 1 dossier) |
| **`~/devpro/`** | **DOCS / DATA / RUNTIME** — docs, données, config d'outils locaux | **non** |
| **`~/Documents/`** | **PRIVÉ** — perso, administratif, formations | non |

**Règle d'or** : ne jamais mélanger. Du code ne descend pas dans `devpro/` ; une donnée runtime ne monte pas dans `Projects/` ; le perso reste dans `Documents/`. En cas de doute sur où ranger → voir §4.

---

## 2. `~/Projects/` — le code (11 catégories)

Convention : **`~/Projects/<catégorie>/<repo>/`**. Un repo = un dossier git. Catégories actuelles :

```
devbox/         cloud · sovereign
digital-shield/ clean · digital-shield · kidshield · smishguard
infra/          bootstrap · full-vps · llm-stack-local · stacks · vps2-docker-stacks · windmill-automation
meta/           baargus · devprosp-skills
podcast/        podcast-stack
products/       certforge · content-studio · datahub · egide
sage/           core · ecosystem · orchestrator · security-vault
tools/          api-key-rotator · assistant-local-multi-llm · devpro_scripts · devpro-tools · llm-privacy-proxy · OSINT
web/            devpro-portal · fabienne-etiopathe/{backend,frontend}
_vendor/        aider-fork  (fork upstream externe, NE PAS ranger ailleurs)
```

**Remotes :**
- **Source de vérité = Gitea** : `ssh://git@git.devprosp.com:2222/devpro-sp/<repo>.git` (alias SSH `gitea-self`).
- Quelques repos perso sous l'org `baargus/` (ex. `baargus/baargus`, `baargus/vps2-docker-stacks`).
- **GitHub = miroir uniquement** (push-mirror). Jamais la source de vérité.

**Cas particuliers :**
- `web/fabienne-etiopathe/` est un **conteneur** (pas un repo) abritant 2 repos : `backend/` + `frontend/`.
- `_vendor/` héberge les forks d'upstreams externes (remote ≠ devpro-sp), à isoler du code maison.

---

## 3. `~/devpro/` — docs, data, runtime (pas de git)

| Sous-dossier | Ce qui a le droit d'y vivre |
|---|---|
| **`local/`** | **runtime** des outils self-hosted locaux (config, `.env`+`.env.sops`, workspaces). Le code y vivant doit être **versionné dans `Projects/`** ; ici seulement la copie d'exécution. |
| **`_archives/`** | **quarantaine datée** : `<sujet>-AAAAMMJJ/`. Tout ce qu'on retire mais ne supprime pas encore. Contient aussi les **backups défensifs VPS2** (intouchables, cf. §8). |
| **`secrets/`** | secrets **chiffrés SOPS** (`*.sops`) uniquement. Jamais de clair. |
| **`knowledge/`** | savoir transverse (devops, références). |
| **`infra-docs/`** | docs infra : audits sécu, templates, runbooks. |
| `README.md` | index. |

**`local/` n'est pas la data des conteneurs** : les volumes Podman vivent ailleurs (ex. `ollama-models/` y est vide — les modèles sont dans un volume). `local/` = config + scratch.

---

## 4. Règles de rangement (où va quoi)

- **Nouveau projet de code** → `~/Projects/<catégorie>/<nom>/`, `git init`, remote `gitea-self:devpro-sp/<nom>.git`, push. Jamais ailleurs.
- **Doc liée à un repo** → `<repo>/docs/`. **Doc transverse** → `devpro/knowledge/` ou `devpro/infra-docs/`.
- **Secret** → chiffré SOPS dès le départ (cf. §6). Jamais de `.env` clair committé.
- **Backup / snapshot** → `devpro/_archives/<sujet>-AAAAMMJJ/` (daté). Vérifier la redondance avant toute purge (cf. §9).
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

- **Chemins FR** : `~/Téléchargements/` (accent + T majuscule). Repos `~/Projects/<cat>/<repo>/`, docs/notes `~/devpro/`.
- **OS atomique** : Fedora Kinoite (rpm-ostree). Sur Aurora → **Flatpak ou conteneur (Quadlet)** uniquement, jamais d'install manuelle (AppImage/tarball).
- **Conteneurs** : Podman rootless + SELinux Enforcing + Quadlet. Container Quadlet = `systemctl --user` only (jamais `podman restart/stop`).
- **Shell zsh** — écrire **bash/POSIX portable** :
  - **word-split** : `for x in $var` n'itère PAS en zsh (pas de découpage). Utiliser une **liste littérale** (`for x in a b c`) ou un **array** (`"${arr[@]}"`).
  - **nomatch** : un glob sans correspondance (`rm foo-*`) **annule toute la commande** en zsh. Vérifier l'existence avant, ou chemins littéraux.
  - Ne jamais utiliser comme variable de boucle : `path`, `cdpath`, `manpath`, `fpath`, `status`, `signals`.
- **Cycle PROD (zero direct edit)** : audit → local → commit → push Gitea → pull VPS → restart. Pas de `sed` direct sur les fichiers de prod. Toujours un plan de rollback.

---

## 8. Zones INTOUCHABLES

- **Outils vivants dans `local/`** (conteneurs actifs) : **AppFlowy, AnythingLLM, ollama, qdrant, searxng, api-key-rotator**. Ne pas toucher config ni data.
- **Backups défensifs VPS2** dans `_archives/` (`archives/`, `infra-backups/`) : filet de rollback de la **migration VPS2 AlmaLinux en cours**. Ne pas purger tant que la migration n'est pas close.
- **`.vscode/`** : config de **VSCodium** (l'éditeur de code actif sur Aurora). Ne jamais supprimer ni gitignorer globalement.

---

## 9. Anti-patterns vécus (à ne pas reproduire)

- **Squelettes d'arbo vides** : taxonomies créées puis jamais peuplées (ex. ancien `devpro/documents/`, `litiges/` dupliquant `~/Documents/`). → ne pas échafauder à vide ; peupler ou ne pas créer.
- **Doublons `devpro/` ↔ `Projects/`** : même nom des deux côtés (legacy `verticals/` sans git). → le code vit dans `Projects/`, la doc dans `devpro/` ; pas de copie de travail dans `devpro/`.
- **Build cache non gitignoré** : `target/` (Rust/Tauri), `node_modules/`, outputs générés gonflant l'arbo (ex. certforge 3 G de `target/debug/`). → toujours gitignorer ; ne jamais archiver le cache de build.
- **Données générées volumineuses mêlées au code** : corpus DILA (14 G), markdown générés. → séparer data (`local/`, gitignorée) du code (Gitea) ; ne committer que le pipeline, pas ses sorties.
- **Snapshots git à `git status` non vide** : un working-tree non committé dans un backup = travail unique présent nulle part ailleurs. → **inspecter `git status` / `git stash` AVANT toute purge** ; prouver la redondance par `git merge-base --is-ancestor <sha> <branche-remote>` (pas par `ls-remote | grep`, qui ne montre que les tips).
- **Secrets en clair dans des `.env` orphelins** : credentials prod traînant dans des dossiers oubliés. → chiffrer SOPS, supprimer le clair, vérifier la diffusion git.

---

*Maintenu par Baptiste Sobocinski (baargus) — architecte-garant DevSecOps.*
