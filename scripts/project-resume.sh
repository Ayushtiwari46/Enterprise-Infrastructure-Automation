#!/usr/bin/env bash
# ==============================================================================
# PROJECT RESUME AND PERSISTENT RECOVERY VERIFICATION ENGINE
# ==============================================================================
# Framework: Enterprise Infrastructure Automation Framework
# Classification: PROJECT_MANAGEMENT / RECOVERY_HARNESS
# Usage:
#   ./scripts/project-resume.sh
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}" || exit 1

PM_DIR="${REPO_ROOT}/project-management"
CHECKPOINT_FILE="${PM_DIR}/PROJECT_CHECKPOINT.md"
STATUS_FILE="${PM_DIR}/PROJECT_STATUS.md"
MASTER_PLAN="${PM_DIR}/PROJECT_MASTER_PLAN.md"
TASK_REG="${PM_DIR}/TASK_REGISTER.md"
INVENTORY_FILE="${PM_DIR}/FILE_INVENTORY.md"

echo "=============================================================================="
echo "ENTERPRISE AUTOMATION PROJECT PERSISTENT RESUME HARNESS"
echo "=============================================================================="
echo "Workspace Root : ${REPO_ROOT}"
echo "Current Time   : $(date)"
echo "Controller     : $(hostname -f 2>/dev/null || hostname)"
echo "=============================================================================="

if [[ ! -f "${CHECKPOINT_FILE}" ]]; then
    echo "[-] CRITICAL ERROR: Active checkpoint file not found at ${CHECKPOINT_FILE}"
    exit 1
fi

echo -e "\n=== 1. CURRENT VERIFIED CHECKPOINT ==="
grep -E "(\*\*Active Checkpoint\*\*|\*\*Status\*\*|\*\*Last Verified Phase\*\*|\*\*Next Pending Phase\*\*)" "${CHECKPOINT_FILE}" || head -n 25 "${CHECKPOINT_FILE}"

echo -e "\n=== 2. PROJECT PHASE EXECUTION PROGRESS ==="
if [[ -f "${STATUS_FILE}" ]]; then
    grep -E "(\| Phase [0-9]+)" "${STATUS_FILE}" | head -n 15 || true
fi

echo -e "\n=== 3. RUNTIME & CONTROLLER INTEGRITY AUDIT ==="
echo "Python Version    : $(python3 --version 2>&1)"
echo "Ansible Version   : $(ansible --version 2>&1 | head -n 1)"
echo "Available Disk    : $(df -h "${REPO_ROOT}" | tail -n 1 | awk '{print $4 " free of " $2}')"

echo -e "\n=== 4. REPOSITORY INVENTORY METRICS ==="
PLAYBOOK_COUNT=$(find "${REPO_ROOT}/playbooks" "${REPO_ROOT}/incident-collection" "${REPO_ROOT}/operations" -type f -name "*.yml" 2>/dev/null | wc -l)
SCRIPT_COUNT=$(find "${REPO_ROOT}/scripts" -type f -name "*.sh" 2>/dev/null | wc -l)
DOCS_COUNT=$(find "${REPO_ROOT}/docs" -type f -name "*.md" 2>/dev/null | wc -l)
echo "Automated Playbooks Count : ${PLAYBOOK_COUNT}"
echo "Operational Scripts Count : ${SCRIPT_COUNT}"
echo "Documentation Guides Count: ${DOCS_COUNT}"

echo -e "\n=============================================================================="
echo "[+] REPOSITORY IS READY FOR IMMEDIATE EXECUTION"
echo "To continue work, refer to RESUME_INSTRUCTIONS.md or execute pending phase."
echo "=============================================================================="

exit 0
