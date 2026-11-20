#!/usr/bin/env bash
# ==============================================================================
# REPOSITORY CONFIGURATION & AUTOMATION BACKUP UTILITY
# ==============================================================================
# Framework: Enterprise Infrastructure Automation Framework
# Classification: DISASTER_RECOVERY / BACKUP_UTILITY
# Usage:
#   ./scripts/backup-config.sh
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}" || exit 1

BACKUP_DIR="${REPO_ROOT}/Legacy-Archive/backups"
mkdir -p "${BACKUP_DIR}"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
ARCHIVE_NAME="infra_repo_backup_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_NAME}"

echo "=============================================================================="
echo "ENTERPRISE AUTOMATION REPOSITORY BACKUP ENGINE"
echo "=============================================================================="
echo "Source Workspace : ${REPO_ROOT}"
echo "Target Backup    : ${ARCHIVE_PATH}"
echo "Timestamp        : ${TIMESTAMP}"
echo "=============================================================================="

# Create compressed tarball of critical framework assets
tar --exclude='*.pyc' --exclude='__pycache__' --exclude='*.log' \
    -czf "${ARCHIVE_PATH}" \
    ansible.cfg \
    inventories \
    vars \
    project-management \
    playbooks \
    incident-collection \
    operations \
    scripts \
    templates \
    requirements.yml \
    requirements.txt

# Calculate SHA-256 Checksum for Integrity Verification
sha256sum "${ARCHIVE_PATH}" > "${ARCHIVE_PATH}.sha256"

ARCHIVE_SIZE=$(du -h "${ARCHIVE_PATH}" | cut -f1)
CHECKSUM=$(cat "${ARCHIVE_PATH}.sha256" | awk '{print $1}')

echo "[+] Backup successfully created!"
echo "    Archive Path : ${ARCHIVE_PATH}"
echo "    Archive Size : ${ARCHIVE_SIZE}"
echo "    SHA-256 Hash : ${CHECKSUM}"

# Keep only the last 10 backups, rotate older ones
echo -e "\n[*] Rotating backup archives (retaining last 10)..."
cd "${BACKUP_DIR}"
ls -t infra_repo_backup_*.tar.gz 2>/dev/null | tail -n +11 | while read -r old_backup; do
    echo "    Removing aged backup: ${old_backup}"
    rm -f "${old_backup}" "${old_backup}.sha256"
done

echo "=============================================================================="
echo "Backup and rotation cycle completed successfully."
echo "=============================================================================="

exit 0
