#!/usr/bin/env bash
# ==============================================================================
# DEPENDENCY INSTALLATION AND ENVIRONMENT VERIFICATION ENGINE
# ==============================================================================
# Framework: Enterprise Infrastructure Automation Framework
# Classification: INSTALLATION / SYSTEM_PREPARATION
# Usage:
#   ./scripts/install-dependencies.sh
#   ./scripts/install-dependencies.sh --check-only
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}" || exit 1

CHECK_ONLY=false
if [[ "$1" == "--check-only" ]]; then
    CHECK_ONLY=true
fi

AUDIT_DIR="${REPO_ROOT}/reports/dependency-audit"
mkdir -p "${AUDIT_DIR}"
AUDIT_LOG="${AUDIT_DIR}/DEPENDENCY_INSTALL_$(date +%Y%m%d_%H%M%S).log"

echo "=============================================================================="
echo "ENTERPRISE AUTOMATION DEPENDENCY INSTALLATION & VERIFICATION"
echo "=============================================================================="
echo "Workspace Root : ${REPO_ROOT}"
echo "Check Only     : ${CHECK_ONLY}"
echo "Audit Log      : ${AUDIT_LOG}"
echo "=============================================================================="

{
echo "=== 1. VERIFYING PYTHON RUNTIME ==="
python3 --version
pip3 --version
ansible --version | head -n 3

echo -e "\n=== 2. AUDITING INSTALLED ANSIBLE COLLECTIONS ==="
ansible-galaxy collection list

if [[ "${CHECK_ONLY}" == "false" ]]; then
    echo -e "\n=== 3. INSTALLING ANSIBLE GALAXY COLLECTIONS ==="
    if [[ -f "${REPO_ROOT}/requirements.yml" ]]; then
        ansible-galaxy collection install -r "${REPO_ROOT}/requirements.yml"
    else
        echo "requirements.yml not found, skipping."
    fi

    echo -e "\n=== 4. INSTALLING PYTHON DEPENDENCIES ==="
    if [[ -f "${REPO_ROOT}/requirements.txt" ]]; then
        pip3 install --user -r "${REPO_ROOT}/requirements.txt"
    else
        echo "requirements.txt not found, skipping."
    fi
else
    echo -e "\n=== CHECK ONLY MODE: SKIPPING INSTALLATION ==="
fi

echo -e "\n=== 5. POST-INSTALLATION COLLECTION AUDIT ==="
ansible-galaxy collection list

echo "=============================================================================="
echo "Dependency verification process completed successfully."
echo "=============================================================================="
} 2>&1 | tee "${AUDIT_LOG}"

exit 0
