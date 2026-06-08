#!/usr/bin/env bash
#
# backup-aurora.sh — Backup hebdo Aurora avec rappel plafonne
# =============================================================
# DECLENCHEMENT : a l'ouverture de session + rappels dans la journee (timer).
# LOGIQUE :
#   - backup reussi < 7j        -> silence total
#   - backup en retard (>=7j)   -> popup, MAX 3 rappels/jour, jusqu'a validation
#   - backup reussi             -> marqueur 7j a jour -> silence 7j
# PROCESS : ETAPE 1 KeePass (archive 2 cles + synchro KP_MAIN->KP_BACKUP)
#           ETAPE 2 Borg (si etape 1 OK ; passphrase via popup KeePass)
#
# SUPPORTS : KP_MAIN (source), KP_BACKUP (redondance), BACKUP_LEGION (repo Borg)
# LANCEMENT : ./backup-aurora.sh  |  ./backup-aurora.sh --force (ignore marqueur+plafond)
# RESTAURE  : export BORG_REPO=/run/media/batewa/BACKUP_LEGION/borg-legion ; borg list ; borg extract ::ARCHIVE
# =============================================================

set -euo pipefail

KPM="/run/media/batewa/KP_MAIN"
KPB="/run/media/batewa/KP_BACKUP"
BORG_REPO="/run/media/batewa/BACKUP_LEGION/borg-legion"
MARKER="$HOME/.local/share/backup-aurora-last"
NAG_FILE="$HOME/.local/share/backup-aurora-nag-$(date +%Y%m%d)"
INTERVAL_DAYS=7
MAX_NAG_PER_DAY=3
TODAY="$(date +%Y%m%d_%H%M%S)"
HOME_R="$(realpath "$HOME")"
export BORG_REPO
mkdir -p "$(dirname "$MARKER")"

notify()       { kdialog --passivepopup "$1" 6 2>/dev/null || echo "[notif] $1"; }
notify_err()   { kdialog --error "$1" 2>/dev/null || echo "[ERREUR] $1" >&2; }
ask_continue() { kdialog --title "Backup hebdo Aurora" --yesno "$1" 2>/dev/null; }

# --- 0. Marqueur 7j + plafond 3 rappels/jour ---
FORCE="${1:-}"
if [ "$FORCE" != "--force" ]; then
  if [ -f "$MARKER" ]; then
    LAST="$(cat "$MARKER" 2>/dev/null || echo 0)"
    DIFF_DAYS=$(( ( $(date +%s) - LAST ) / 86400 ))
    if [ "$DIFF_DAYS" -lt "$INTERVAL_DAYS" ]; then
      echo "Backup a jour ($DIFF_DAYS j) — silencieux."; exit 0
    fi
  fi
  NAG_COUNT="$(cat "$NAG_FILE" 2>/dev/null || echo 0)"
  if [ "$NAG_COUNT" -ge "$MAX_NAG_PER_DAY" ]; then
    echo "Plafond rappels du jour atteint ($NAG_COUNT/$MAX_NAG_PER_DAY) — silencieux."; exit 0
  fi
  find "$HOME/.local/share" -maxdepth 1 -name 'backup-aurora-nag-*' ! -name "*$(date +%Y%m%d)*" -delete 2>/dev/null || true
  echo "$(( NAG_COUNT + 1 ))" > "$NAG_FILE"
  echo "Rappel backup $(( NAG_COUNT + 1 ))/$MAX_NAG_PER_DAY."
fi

# --- 1. Supports montes ? ---
MISSING=""
[ -d "$KPM/kdbx" ]  || MISSING="$MISSING KP_MAIN"
[ -d "$KPB/kdbx" ]  || MISSING="$MISSING KP_BACKUP"
[ -d "$BORG_REPO" ] || MISSING="$MISSING BACKUP_LEGION"
if [ -n "$MISSING" ]; then
  ask_continue "Supports manquants :$MISSING\n\nBranche et deverrouille KP_MAIN + KP_BACKUP + BACKUP_LEGION, puis Continuer." \
    || { notify "Backup reporte (supports manquants) — rappel plus tard."; exit 1; }
  [ -d "$KPM/kdbx" ] && [ -d "$KPB/kdbx" ] && [ -d "$BORG_REPO" ] \
    || { notify_err "Supports toujours manquants :$MISSING. Reporte."; exit 1; }
fi

# --- ETAPE 1 : KeePass (KP_MAIN = source) ---
echo "=== ETAPE 1 : KeePass ==="
ACTIVE_MAIN="$(ls -t "$KPM"/kdbx/*.kdbx 2>/dev/null | head -1)"
[ -n "$ACTIVE_MAIN" ] || { notify_err "Aucune base .kdbx sur KP_MAIN. Annule."; exit 1; }
BASENAME="$(basename "$ACTIVE_MAIN" .kdbx)"; KDBX_NAME="$(basename "$ACTIVE_MAIN")"
mkdir -p "$KPM/archives" "$KPB/archives"
cp -p "$ACTIVE_MAIN" "$KPM/archives/${BASENAME}_MAIN_${TODAY}.kdbx"
echo "  archive MAIN   : ${BASENAME}_MAIN_${TODAY}.kdbx"
ACTIVE_BACKUP="$(ls -t "$KPB"/kdbx/*.kdbx 2>/dev/null | head -1)"
if [ -n "$ACTIVE_BACKUP" ]; then
  cp -p "$ACTIVE_BACKUP" "$KPB/archives/${BASENAME}_BACKUP_${TODAY}.kdbx"
  echo "  archive BACKUP : ${BASENAME}_BACKUP_${TODAY}.kdbx"
fi
cp -p "$ACTIVE_MAIN" "$KPB/kdbx/$KDBX_NAME"
H_SRC="$(sha256sum "$ACTIVE_MAIN" | cut -d' ' -f1)"
H_DST="$(sha256sum "$KPB/kdbx/$KDBX_NAME" | cut -d' ' -f1)"
[ "$H_SRC" = "$H_DST" ] || { notify_err "ECHEC synchro KeePass (hash != ). Borg NON lance."; exit 1; }
echo "  synchro MAIN -> BACKUP : OK"
notify "KeePass OK (2 cles + archives). Lancement Borg..."

# --- ETAPE 2 : Borg (depend de l'etape 1) ---
echo "=== ETAPE 2 : Borg ==="
ARCHIVE="legion-${TODAY}"
BORG_PASSPHRASE="$(kdialog --title "Borg Backup" --password "Passphrase du repo Borg (depuis KeePass) :" 2>/dev/null)"
[ -n "$BORG_PASSPHRASE" ] || { notify_err "Passphrase vide. Borg annule (KeePass deja sauve)."; exit 1; }
export BORG_PASSPHRASE
borg create --list --stats --compression zstd,3 "::$ARCHIVE" \
  "$HOME_R/Documents" "$HOME_R/Projects" \
  "$HOME_R/bin" "$HOME_R/scripts" "$HOME_R/.config" \
  --exclude "$HOME_R/Projects/_archives" --exclude "$HOME_R/Projects/local" \
  --exclude '*/node_modules' --exclude '*/target' --exclude '*/.cache' \
  --exclude "$HOME_R/go/pkg" --exclude '*/__pycache__' --exclude '*/.venv' \
  --exclude '*/dist' --exclude '*/.next'
borg check --archives-only --last 1 && echo "  Archive consistency OK"
unset BORG_PASSPHRASE

# --- 3. Marqueur de reussite -> silence 7j ---
date +%s > "$MARKER"
rm -f "$NAG_FILE"
notify "Backup hebdo termine : KeePass (2 cles) + Borg ($ARCHIVE)."
echo "=== Termine : $ARCHIVE ==="
