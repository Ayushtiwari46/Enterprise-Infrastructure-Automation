#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: collect-incident-evidence.sh
# ==============================================================================
# Enterprise Incident Evidence Collection Interactive CLI Intake
# Audience: IT Infrastructure Engineer – L3 / Incident Management Operations
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

echo "=============================================================================="
echo "    ENTERPRISE INFRASTRUCTURE INCIDENT EVIDENCE COLLECTION FRAMEWORK          "
echo "=============================================================================="
echo " Interactive Intake Engine - IT Infrastructure Operations L3                  "
echo "=============================================================================="

# 1. ServiceNow Case Number
read -rp "Enter ServiceNow Case Number [e.g. INC0012345]: " CASE_ID
CASE_ID="${CASE_ID:-INC0012345}"

# 2. Customer / Environment Identifier
read -rp "Enter Customer / Environment ID [e.g. CUST-PROD-01]: " CUSTOMER_ID
CUSTOMER_ID="${CUSTOMER_ID:-CUST-PROD-01}"

# 3. Technology Selection
echo ""
echo "Select Target Technology Domain:"
echo "  1) Linux Operating Systems (RHEL, Oracle Linux, SLES, Ubuntu)"
echo "  2) IBM AIX (LPAR, Power Systems)"
echo "  3) Microsoft Windows Server"
echo "  4) VMware vSphere (vCenter & ESXi)"
echo "  5) Oracle Linux Virtualization Manager (OLVM / oVirt)"
echo "  6) Enterprise KVM Hypervisor"
echo "  7) Enterprise Storage (IBM, HPE, Dell)"
echo "  8) SAN Fabric Switches (Brocade, Cisco MDS)"
echo "  9) High-Availability Clustering (PowerHA, GPFS, Veritas VCS)"
echo " 10) Enterprise Backup & DR (TSM, NetBackup, NetWorker)"
read -rp "Choice [1-10, default: 1]: " TECH_CHOICE
TECH_CHOICE="${TECH_CHOICE:-1}"

case "$TECH_CHOICE" in
    1) TECH="linux"; PLAYBOOK="incident-collection/linux/collect_linux_evidence.yml"; DEFAULT_TARGET="linux_all" ;;
    2) TECH="aix"; PLAYBOOK="incident-collection/aix/collect_aix_evidence.yml"; DEFAULT_TARGET="aix_enterprise" ;;
    3) TECH="windows"; PLAYBOOK="incident-collection/windows/collect_windows_evidence.yml"; DEFAULT_TARGET="windows_enterprise" ;;
    4) TECH="vmware"; PLAYBOOK="incident-collection/vmware/collect_vmware_evidence.yml"; DEFAULT_TARGET="vmware_vcenter" ;;
    5) TECH="olvm"; PLAYBOOK="incident-collection/olvm/collect_olvm_evidence.yml"; DEFAULT_TARGET="virtualization_managers" ;;
    6) TECH="kvm"; PLAYBOOK="incident-collection/kvm/collect_kvm_evidence.yml"; DEFAULT_TARGET="kvm_hypervisors" ;;
    7) TECH="storage"; PLAYBOOK="incident-collection/storage/collect_storage_evidence.yml"; DEFAULT_TARGET="storage_enterprise" ;;
    8) TECH="san"; PLAYBOOK="incident-collection/san-switches/collect_san_evidence.yml"; DEFAULT_TARGET="brocade_san" ;;
    9) TECH="clustering"; PLAYBOOK="incident-collection/clustering/collect_cluster_evidence.yml"; DEFAULT_TARGET="clustering_enterprise" ;;
   10) TECH="backup"; PLAYBOOK="incident-collection/backup-dr/collect_backup_evidence.yml"; DEFAULT_TARGET="backup_enterprise" ;;
    *) echo "Invalid choice. Defaulting to Linux."; TECH="linux"; PLAYBOOK="incident-collection/linux/collect_linux_evidence.yml"; DEFAULT_TARGET="linux_all" ;;
esac

# 4. Target Hosts
read -rp "Enter Target Hosts or Group [default: $DEFAULT_TARGET]: " TARGETS
TARGETS="${TARGETS:-$DEFAULT_TARGET}"

# 5. Collection Mode
echo ""
echo "Select Collection Mode:"
echo "  1) MODE 1: Last N Days (Rolling historical window: 3, 5, 10, 15, 30 days)"
echo "  2) MODE 2: Incident-Centric Window (Incident Date with +/- N days before & after)"
read -rp "Mode [1-2, default: 1]: " MODE_CHOICE
MODE_CHOICE="${MODE_CHOICE:-1}"

if [ "$MODE_CHOICE" == "1" ]; then
    MODE="MODE_1"
    read -rp "Enter number of days (3, 5, 10, 15, 30, or custom) [default: 7]: " DAYS
    DAYS="${DAYS:-7}"
    INC_DATE=""
    DAYS_BEFORE="0"
    DAYS_AFTER="0"
else
    MODE="MODE_2"
    DAYS="0"
    read -rp "Enter Incident Date (YYYY-MM-DD) [default: $(date +%Y-%m-%d)]: " INC_DATE
    INC_DATE="${INC_DATE:-$(date +%Y-%m-%d)}"
    read -rp "Enter Days Before Incident to collect [default: 2]: " DAYS_BEFORE
    DAYS_BEFORE="${DAYS_BEFORE:-2}"
    read -rp "Enter Days After Incident to collect [default: 4]: " DAYS_AFTER
    DAYS_AFTER="${DAYS_AFTER:-4}"
fi

# 6. Collection Profile
echo ""
echo "Select Collection Profile:"
echo "  1) Quick (Immediate errors, recent journal, critical services)"
echo "  2) Standard (Full system logs, 7-day SAR, filesystem, network)"
echo "  3) Comprehensive (Complete log archives, historical telemetry, hardware traces)"
read -rp "Profile [1-3, default: 2]: " PROFILE_CHOICE
PROFILE_CHOICE="${PROFILE_CHOICE:-2}"

case "$PROFILE_CHOICE" in
    1) PROFILE="quick" ;;
    2) PROFILE="standard" ;;
    3) PROFILE="comprehensive" ;;
    *) PROFILE="standard" ;;
esac

SESSION_ID="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="case-output/${CASE_ID}/session_${SESSION_ID}"

echo ""
echo "=============================================================================="
echo "CONFIRMATION SUMMARY:"
echo "  ServiceNow Case ID : $CASE_ID"
echo "  Customer ID        : $CUSTOMER_ID"
echo "  Technology Domain  : $TECH"
echo "  Target Hosts       : $TARGETS"
echo "  Collection Mode    : $MODE"
if [ "$MODE" == "MODE_1" ]; then
echo "  Time Window Scope  : Last $DAYS Days"
else
echo "  Incident Date      : $INC_DATE (-$DAYS_BEFORE days to +$DAYS_AFTER days)"
fi
echo "  Collection Profile : $PROFILE"
echo "  Output Vault Path  : $OUTPUT_DIR"
echo "=============================================================================="
read -rp "Proceed with Evidence Acquisition? (y/n) [default: y]: " CONFIRM
CONFIRM="${CONFIRM:-y}"

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Collection aborted by user."
    exit 0
fi

echo ""
echo "[+] Initializing Ansible Evidence Acquisition Execution..."

ansible-playbook -i inventories/lab/hosts.yml "$PLAYBOOK" \
    --limit "$TARGETS" \
    -e "case_number=$CASE_ID" \
    -e "customer_name=$CUSTOMER_ID" \
    -e "mode=$MODE" \
    -e "days=$DAYS" \
    -e "inc_date=$INC_DATE" \
    -e "inc_days_before=$DAYS_BEFORE" \
    -e "inc_days_after=$DAYS_AFTER" \
    -e "profile=$PROFILE" \
    -e "session_id=$SESSION_ID"

echo ""
echo "=============================================================================="
echo "[+] SUCCESS: Incident Evidence Acquisition Completed for Case $CASE_ID"
echo "[+] Artifacts Vault: $OUTPUT_DIR"
echo "[+] Cryptographic Manifest: $OUTPUT_DIR/manifests/"
echo "[+] Executive HTML Report: $OUTPUT_DIR/reports/"
echo "=============================================================================="
