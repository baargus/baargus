# baargus — instructions pour agents de code

> Ce fichier sert aussi d'AGENTS.md. Il s'adresse à tout agent de code intervenant sur ce repo.
> Remote Gitea : `baargus/baargus` (dépôt de profil utilisateur) ; clone local : `~/Projects/meta/baargus`.

## Objectif

Dépôt **personnel de l'opérateur** : le `README.md` sert de présentation de profil (bilingue EN/FR).
Il porte aussi la **référence de rangement du poste Aurora** (`Aurora_arborescence.md`, source de vérité de l'arborescence `~/Projects/`)
et le système de **sauvegarde hebdomadaire** d'Aurora (script Borg + KeePass et ses unités systemd user).

## Stack

- Markdown (README de profil, arborescence)
- Bash (`scripts/backup-aurora.sh`, `set -euo pipefail`) : KeePass (archive sur deux clés USB) puis BorgBackup vers un disque USB
- systemd user : `systemd/backup-aurora.service` (lance `%h/Projects/meta/baargus/scripts/backup-aurora.sh`) et `backup-aurora.timer` (`Persistent=true`)

## Commandes (LOCAL)

- **Build / Test / Lint** : À COMPLÉTER (aucun outillage ; `shellcheck` non configuré).
- **Sauvegarde** : `scripts/backup-aurora.sh` (rappel plafonné à 3/jour si la dernière sauvegarde a ≥ 7 jours) ; `--force` ignore marqueur et plafond.
- **Restauration** (en-tête du script) : définir `BORG_REPO` vers le dépôt Borg du support USB, puis `borg list` / `borg extract ::ARCHIVE`.
- **Installation des unités** : procédure dans `Aurora_arborescence.md` §10 (« Automatisation & persistance », « Réinstaller »).

## Architecture

```
README.md                  présentation de profil (visible sur la page utilisateur Gitea)
Aurora_arborescence.md     règles de rangement d'Aurora : 2 racines, catégories de ~/Projects/, dossiers spéciaux, conventions
                           secrets et machine, zones intouchables, anti-patterns, sauvegarde (§10)
scripts/backup-aurora.sh   étape 1 KeePass (2 clés), étape 2 Borg (si étape 1 OK, passphrase via KeePass)
systemd/                   backup-aurora.service, backup-aurora.timer
```

## Documents de référence à lire avant d'agir

- **Référence d'arborescence** : `Aurora_arborescence.md` (mise à jour 2026-06-08) — à lire avant de créer, déplacer ou ranger quoi que ce soit sur Aurora.
- **PRD / ADR** : aucun (dépôt personnel).

## Règles du projet

- **Cible** : LOCAL (Aurora). Préfixer chaque commande par `LOCAL`.
- Respecter les **zones intouchables** et les conventions de secrets d'`Aurora_arborescence.md` (§6, §8).
- Le README est public sur le profil : aucune donnée personnelle sensible, aucun détail d'infrastructure.
- Ne jamais lancer la sauvegarde ni une restauration Borg sans accord explicite (supports USB, écrasement possible de fichiers).
- **Aucune suppression** sans accord explicite ; pas de `git reset --hard`, `git clean`, `git push --force`.
- **Aucun secret** (passphrase Borg, fichiers KeePass, clés) dans le repo, les logs ou en argument CLI.
- Shell bash-portable ; ne pas utiliser `path`, `status`, `cdpath`, `manpath`, `fpath`, `signals` comme variables.

## État actuel

- 11 commits ; dernier `675592f` (08/06/2026, mise à jour de l'arborescence après la réorganisation `~/Projects/`).
- Sauvegarde v3 (KeePass 2 clés + Borg, rappel plafonné) versionnée le 07/06/2026.

## Points de vigilance

- **Dossier `templates/` non suivi** : `templates/CLAUDE.project.template.md` recommande de **ne pas** dupliquer les règles transverses
  du `CLAUDE.md` global dans les `CLAUDE.md` de projet ; les `CLAUDE.md`/`AGENTS.md` créés le 25/09/2026 les dupliquent volontairement
  (lus aussi par Codex, qui n'a pas le fichier global). Convention à trancher : À COMPLÉTER.
- **Pas de `.gitignore`**.
- Remote `github` désactivé (URL `DISABLED`) ; `origin` pointe vers le dépôt de profil `baargus/baargus` (namespace utilisateur, pas `devpro-sp`).
- Le script de sauvegarde codifie des chemins de supports USB (`/run/media/batewa/…`) : toute réinstallation ou changement d'utilisateur les casse.
- L'arborescence décrit `devbox/` comme « cloud seul » ; vérifier sa cohérence avec l'état réel de `~/Projects/` avant de s'y fier.
