#!/usr/bin/env bash
#
# backup-aurora.sh — Backup Borg du poste Aurora (legion-aurora)
# ---------------------------------------------------------------
# Sauvegarde chiffrée et dédupliquée du travail + outillage + configs
# vers le repo Borg existant sur le disque BACKUP_LEGION.
#
# CONVENTION : archives nommées legion-AAAAMMJJ_HHMMSS (continuité de l'historique).
#
# PÉRIMÈTRE :
#   ~/devpro      (docs/data/runtime — hors _archives et local volumes)
#   ~/Documents   (perso : litiges, patrimoine, admin)
#   ~/Projects    (code — capture l'untracked/non-poussé ; le reste est sur Gitea)
#   ~/bin ~/scripts (outillage ops)
#   ~/.config     (configs + clé age SOPS — indispensable au disaster-recovery)
#
# EXCLUSIONS : régénérables (caches, node_modules, target, go/pkg, venvs, _archives, local).
#
# LANCEMENT :
#   ./backup-aurora.sh
#   (demande le passphrase du repo Borg en interactif)
#
# RESTAURATION :
#   export BORG_REPO=/run/media/batewa/BACKUP_LEGION/borg-legion
#   borg list                              # voir les archives
#   borg extract ::legion-AAAAMMJJ_HHMMSS  # restaurer (depuis le dossier cible)
#   borg mount ::legion-... /mnt/restore   # ou monter pour parcourir
#
# AUTOMATISATION (a La Reunion, une fois reinstalle) :
#   Pour un timer systemd --user, remplacer le passphrase interactif par :
#     export BORG_PASSPHRASE="$(keepassxc-cli show -a Password ~/coffre.kdbx 'Borg Legion')"
#   ou un fichier 0600 reference par BORG_PASSCOMMAND. NE JAMAIS mettre le
#   passphrase en clair dans ce script ni dans l'unit systemd.
# ---------------------------------------------------------------

set -euo pipefail

# --- Configuration ---
BORG_REPO="/run/media/batewa/BACKUP_LEGION/borg-legion"
ARCHIVE="legion-$(date +%Y%m%d_%H%M%S)"
HOME_R="$(realpath "$HOME")"

export BORG_REPO

# --- Garde-fou : le disque est-il monte ? ---
if [ ! -d "$BORG_REPO" ]; then
  echo "ERREUR : repo Borg introuvable ($BORG_REPO)." >&2
  echo "  -> Branche et deverrouille le disque BACKUP_LEGION, puis relance." >&2
  exit 1
fi

echo "=== Backup Aurora -> $ARCHIVE ==="
echo "Repo : $BORG_REPO"
echo

# --- Creation de l'archive ---
borg create --list --stats --compression zstd,3 "::$ARCHIVE" \
  "$HOME_R/devpro" \
  "$HOME_R/Documents" \
  "$HOME_R/Projects" \
  "$HOME_R/bin" \
  "$HOME_R/scripts" \
  "$HOME_R/.config" \
  --exclude "$HOME_R/devpro/_archives" \
  --exclude "$HOME_R/devpro/local" \
  --exclude '*/node_modules' \
  --exclude '*/target' \
  --exclude '*/.cache' \
  --exclude "$HOME_R/go/pkg" \
  --exclude '*/__pycache__' \
  --exclude '*/.venv' \
  --exclude '*/dist' \
  --exclude '*/.next'

echo
echo "=== Verification d'integrite (derniere archive) ==="
borg check --archives-only --last 1 && echo "Archive consistency OK"

echo
echo "=== Archives presentes ==="
borg list | tail -5

# --- Elagage optionnel (DESACTIVE par defaut — decommenter a La Reunion si besoin d'espace) ---
# borg prune --list --keep-daily=7 --keep-weekly=4 --keep-monthly=6
# borg compact

echo
echo "=== Backup termine : $ARCHIVE ==="
