# Enterprise Automation End-to-End Workflow Examples

**Target Audience:** L3 Operations Engineers, Automation Practitioners  
**Framework Version:** 1.0.0-Enterprise  

---

## 1. Scenario A: Responding to a Production P1 Incident
**Incident Ticket:** INC0094821 - Database Server Slowdown & Intermittent Timeouts  
**Target:** `ansible-nfs.lab.local` (Oracle Linux / Production NFS Host)  

### Step 1: Execute Forensic Evidence Intake
```bash
./scripts/collect-incident-evidence.sh
# Select: Domain: 1 (Linux)
# Mode: 1 (Last 3 Days)
# Profile: standard
# Target: ansible-nfs.lab.local
```
**Outcome:** Artifacts extracted, SHA-256 manifest recorded, HTML evidence dossier generated in `case-output/INC0094821/`.

### Step 2: Run Real-time CPU and Memory Analysis
```bash
./scripts/run-playbook.sh -p playbooks/linux/linux_process_resource_analysis.yml -l ansible-nfs.lab.local
```
**Outcome:** Review `reports/performance/ansible-nfs.lab.local/top_processes.txt` for rogue threads.

### Step 3: Run Multipath & Disk I/O Verification
```bash
./scripts/run-playbook.sh -p playbooks/linux/linux_multipath_san_audit.yml -l ansible-nfs.lab.local
```
**Outcome:** Confirm all storage paths are active and no path thrashing is occurring.

---

## 2. Scenario B: Planned Production Change Execution
**Change Ticket:** CHG008123 - Kernel Tunable `vm.swappiness` Optimization  
**Target:** `linux_all`  

### Step 1: Pre-Change Baseline Capture
```bash
ansible-playbook -i inventories/lab/hosts.yml operations/validation/pre_change_validation.yml -e "chg_id=CHG008123"
```
**Outcome:** Baseline snapshot of uptime, load, services, ports, and filesystems saved.

### Step 2: Dry-Run Verification (Check Mode)
```bash
./scripts/run-playbook.sh -p operations/changes/linux/change_linux_kernel_sysctl.yml -c -l linux_all
```
**Outcome:** Verifies configuration syntax and shows preview diff of `/etc/sysctl.conf`.

### Step 3: Authorized Change Execution
```bash
./scripts/run-playbook.sh -p operations/changes/linux/change_linux_kernel_sysctl.yml -e "chg_id=CHG008123 confirm_change=true" -l linux_all
```
**Outcome:** Kernel parameter applied, verified live in `/proc/sys/vm/swappiness`, change audit record created.

### Step 4: Post-Change Verification & Drift Audit
```bash
ansible-playbook -i inventories/lab/hosts.yml operations/post-change-verification/post_change_verification.yml -e "chg_id=CHG008123"
```
**Outcome:** Verifies no services dropped, filesystem health is intact, and asserts complete success.

---

## 3. Scenario C: Daily Morning Infrastructure Health Audit
**Schedule:** Every morning at 06:00 AM  

```bash
# Validate Inventory Connectivity
./scripts/validate-inventory.sh

# Execute Multi-Platform Health Audits
./scripts/run-playbook.sh -p playbooks/linux/linux_system_health_check.yml
./scripts/run-playbook.sh -p playbooks/olvm/olvm_cluster_host_health.yml
./scripts/run-playbook.sh -p playbooks/kvm/kvm_host_resource_audit.yml

# Aggregate Consolidated Executive Report
./scripts/generate-report.sh
```
**Outcome:** Generates `reports/execution/CONSOLIDATED_SUMMARY_<timestamp>.html` ready for IT operations standup.
