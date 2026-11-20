#!/usr/bin/env bash
# ==============================================================================
# ENTERPRISE PLAYBOOK EXECUTION ENGINE & OPERATIONAL WRAPPER
# ==============================================================================
# Framework: Enterprise Infrastructure Automation Framework
# Classification: OPERATIONAL_UTILITY / PRODUCTION_HARNESS
# Usage:
#   ./scripts/run-playbook.sh -p playbooks/linux/linux_system_health_check.yml
#   ./scripts/run-playbook.sh -p playbooks/linux/linux_system_health_check.yml -i inventories/lab/hosts.yml -l ansible-nfs.lab.local
#   ./scripts/run-playbook.sh -p operations/changes/linux/change_linux_kernel_sysctl.yml -e "confirm_change=true"
# ==============================================================================

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}" || exit 1

PLAYBOOK=""
INVENTORY="${REPO_ROOT}/inventories/lab/hosts.yml"
LIMIT=""
EXTRA_VARS=""
CHECK_MODE=false
SYNTAX_CHECK=false
VERBOSITY=""
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

usage() {
    cat <<EOF
Usage: $(basename "$0") -p <playbook_path> [options]

Required:
  -p, --playbook PATH        Path to the Ansible playbook to execute

Options:
  -i, --inventory PATH       Inventory file path (default: inventories/lab/hosts.yml)
  -l, --limit SUBSET         Limit execution to specified hosts/groups
  -e, --extra-vars "VARS"    Additional variables (e.g. -e "confirm_change=true")
  -c, --check                Execute in check mode (--check / dry run)
  -s, --syntax               Perform syntax check prior to execution
  -v, --verbose              Increase Ansible verbosity (-v, -vv, -vvv)
  -h, --help                 Display this help message and exit

Examples:
  $(basename "$0") -p playbooks/linux/linux_system_health_check.yml
  $(basename "$0") -p playbooks/linux/linux_system_health_check.yml -l ansible-nfs.lab.local
  $(basename "$0") -p operations/changes/linux/change_linux_kernel_sysctl.yml -e "confirm_change=true"
EOF
    exit 1
}

# Parse Command Line Arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--playbook)
            PLAYBOOK="$2"
            shift 2
            ;;
        -i|--inventory)
            INVENTORY="$2"
            shift 2
            ;;
        -l|--limit)
            LIMIT="$2"
            shift 2
            ;;
        -e|--extra-vars)
            EXTRA_VARS="$2"
            shift 2
            ;;
        -c|--check)
            CHECK_MODE=true
            shift
            ;;
        -s|--syntax)
            SYNTAX_CHECK=true
            shift
            ;;
        -v|--verbose)
            VERBOSITY="-v"
            shift
            ;;
        -vv)
            VERBOSITY="-vv"
            shift
            ;;
        -vvv)
            VERBOSITY="-vvv"
            shift
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

if [[ -z "${PLAYBOOK}" ]]; then
    echo "[-] Error: Playbook (-p) parameter is mandatory."
    usage
fi

if [[ ! -f "${PLAYBOOK}" ]]; then
    echo "[-] Error: Specified playbook does not exist: ${PLAYBOOK}"
    exit 2
fi

if [[ ! -f "${INVENTORY}" ]]; then
    echo "[-] Error: Specified inventory does not exist: ${INVENTORY}"
    exit 2
fi

# Guard Change Playbooks against Accidental Execution
if [[ "${PLAYBOOK}" == *"operations/changes/"* ]]; then
    if [[ "${EXTRA_VARS}" != *"confirm_change=true"* ]] && [[ "${CHECK_MODE}" != "true" ]]; then
        echo "=============================================================================="
        echo "[!] CRITICAL SAFEGUARD TRIGGERED: MUTATING CHANGE PLAYBOOK DETECTED"
        echo "=============================================================================="
        echo "Playbook: ${PLAYBOOK}"
        echo "This playbook performs state modifications on managed infrastructure."
        echo "Execution requires explicit confirmation via -e 'confirm_change=true' or --check mode."
        echo "Execution aborted for safety."
        exit 3
    fi
fi

PLAYBOOK_NAME="$(basename "${PLAYBOOK}" .yml)"
LOG_DIR="${REPO_ROOT}/logs/execution"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/${PLAYBOOK_NAME}_${TIMESTAMP}.log"

# Build Ansible Command
CMD=(ansible-playbook -i "${INVENTORY}" "${PLAYBOOK}")

if [[ -n "${LIMIT}" ]]; then
    CMD+=(-l "${LIMIT}")
fi

if [[ -n "${EXTRA_VARS}" ]]; then
    CMD+=(-e "${EXTRA_VARS}")
fi

if [[ "${CHECK_MODE}" == "true" ]]; then
    CMD+=(--check --diff)
fi

if [[ -n "${VERBOSITY}" ]]; then
    CMD+=("${VERBOSITY}")
fi

# Perform Syntax Check if requested
if [[ "${SYNTAX_CHECK}" == "true" ]]; then
    echo "[*] Performing pre-flight syntax check for ${PLAYBOOK}..."
    if ! ansible-playbook -i "${INVENTORY}" "${PLAYBOOK}" --syntax-check > /dev/null 2>&1; then
        echo "[-] SYNTAX CHECK FAILED: ${PLAYBOOK}"
        ansible-playbook -i "${INVENTORY}" "${PLAYBOOK}" --syntax-check
        exit 4
    fi
    echo "[+] Syntax check passed."
fi

echo "=============================================================================="
echo "ENTERPRISE ANSIBLE PLAYBOOK EXECUTION HARNESS"
echo "=============================================================================="
echo "Playbook   : ${PLAYBOOK}"
echo "Inventory  : ${INVENTORY}"
echo "Limit      : ${LIMIT:-ALL}"
echo "Check Mode : ${CHECK_MODE}"
echo "Timestamp  : ${TIMESTAMP}"
echo "Log File   : ${LOG_FILE}"
echo "Command    : ${CMD[*]}"
echo "=============================================================================="

# Execute and stream output to both console and log file
"${CMD[@]}" 2>&1 | tee "${LOG_FILE}"
EXIT_CODE="${PIPESTATUS[0]}"

echo "=============================================================================="
if [[ "${EXIT_CODE}" -eq 0 ]]; then
    echo "[+] EXECUTION SUCCESSFUL (Exit Code: ${EXIT_CODE})"
else
    echo "[-] EXECUTION COMPLETED WITH ERRORS (Exit Code: ${EXIT_CODE})"
fi
echo "Execution Log Preserved: ${LOG_FILE}"
echo "=============================================================================="

exit "${EXIT_CODE}"
