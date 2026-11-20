#!/usr/bin/env bash
# ==============================================================================
# INVENTORY REACHABILITY & VALIDATION HARNESS
# ==============================================================================
# Framework: Enterprise Infrastructure Automation Framework
# Classification: VALIDATION_HARNESS / HEALTH_VERIFICATION
# Usage:
#   ./scripts/validate-inventory.sh
#   ./scripts/validate-inventory.sh -i inventories/lab/hosts.yml -g linux_all
# ==============================================================================

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}" || exit 1

INVENTORY="${REPO_ROOT}/inventories/lab/hosts.yml"
TARGET_GROUP="all"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
REPORT_DIR="${REPO_ROOT}/reports/validation"
mkdir -p "${REPORT_DIR}"
REPORT_FILE="${REPORT_DIR}/inventory_validation_${TIMESTAMP}.txt"

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -i, --inventory PATH   Inventory file path (default: inventories/lab/hosts.yml)
  -g, --group NAME       Target group to validate (default: all)
  -h, --help             Display this help message and exit

Examples:
  $(basename "$0")
  $(basename "$0") -i inventories/production-template/hosts.yml
  $(basename "$0") -g linux_all
EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--inventory)
            INVENTORY="$2"
            shift 2
            ;;
        -g|--group)
            TARGET_GROUP="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "[-] Error: Unknown option $1"
            usage
            ;;
    esac
done

if [[ ! -f "${INVENTORY}" ]]; then
    echo "[-] Error: Inventory file not found: ${INVENTORY}"
    exit 2
fi

{
echo "=============================================================================="
echo "ENTERPRISE INFRASTRUCTURE INVENTORY VALIDATION REPORT"
echo "=============================================================================="
echo "Inventory Path : ${INVENTORY}"
echo "Target Scope   : ${TARGET_GROUP}"
echo "Audit Time     : $(date)"
echo "Controller     : $(hostname -f)"
echo "=============================================================================="
echo ""
echo "--- 1. INVENTORY STRUCTURE AUDIT ---"
ansible-inventory -i "${INVENTORY}" --graph
echo ""
echo "--- 2. HOST CONNECTIVITY PING VERIFICATION ---"
ansible -i "${INVENTORY}" "${TARGET_GROUP}" -m ansible.builtin.ping -o
echo ""
echo "--- 3. OPERATING SYSTEM DISTRIBUTION SUMMARY ---"
ansible -i "${INVENTORY}" "${TARGET_GROUP}" -m ansible.builtin.setup -a "filter=ansible_distribution*" 2>/dev/null | grep -E "(SUCCESS|ansible_distribution\"|ansible_distribution_version)" || true
echo ""
echo "=============================================================================="
echo "Validation complete. Status captured in ${REPORT_FILE}"
echo "=============================================================================="
} 2>&1 | tee "${REPORT_FILE}"

exit 0
