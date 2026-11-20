# Enterprise Clustering & Backup/DR Automation Guide

**Target Audience:** L3 High Availability Engineers, Backup Administrators, Disaster Recovery Specialists  
**Framework Version:** 1.0.0-Enterprise  
**Classification:** Operational Runbook  

---

## 1. High Availability Clustering Suite (4 Playbooks)
Located in `playbooks/clustering/`, these playbooks automate health audits and topology verification across the industry's four major clustering solutions:

### 1.1 IBM PowerHA SystemMirror
- **Playbook:** `powerha/cluster_ibm_powerha_audit.yml`
- **Commands:** `clstat -a`, `cldump`, `lssrc -g cluster`
- **Verification:** Node communication daemons (`clstrmgrES`), cluster networks, heartbeat rings, and resource group online states.

### 1.2 IBM Spectrum Scale (GPFS)
- **Playbook:** `gpfs/cluster_ibm_gpfs_audit.yml`
- **Commands:** `mmgetstate -a`, `mmlscluster`, `mmlsdisk`, `mmlsmount`
- **Verification:** Daemon active quorum, file system mount states across all NSD servers, and disk failure group availability.

### 1.3 Veritas InfoScale / VCS
- **Playbook:** `veritas/cluster_veritas_vcs_audit.yml`
- **Commands:** `hastatus -sum`, `gabconfig -a`, `lltstat -nvv`
- **Verification:** GAB (Group Membership Services) port memberships (port 'a' kernel, port 'h' VCS), LLT heartbeat link health, and service group state.

### 1.4 Cross-Platform Node Audit
- **Playbook:** `cluster_node_resource_audit.yml`
- **Verification:** Audits asymmetric CPU/memory resources between primary and failover nodes to prevent OOM panics during failover.

---

## 2. Enterprise Backup & Disaster Recovery Suite (4 Playbooks)
Located in `playbooks/backup-dr/`, these playbooks verify client agent health, scheduler services, and DR readiness.

### 2.1 IBM Spectrum Protect (TSM)
- **Playbook:** `backup_ibm_spectrum_protect_audit.yml`
- **Scope:** `dsmc query session`, `dsmc query filespace`, client scheduler daemon (`dsmcad` / `dsmsched`).

### 2.2 Veritas NetBackup
- **Playbook:** `backup_veritas_netbackup_audit.yml`
- **Scope:** `bpclntcmd -pn` (PBX server communication), client process verification (`vnetd`, `bpcd`).

### 2.3 Dell NetWorker
- **Playbook:** `backup_dell_networker_audit.yml`
- **Scope:** `nsrexecd` daemon verification, port range connectivity (ports 7937-9936), and server directive synchronization.

### 2.4 Disaster Recovery (DR) Readiness Audit
- **Playbook:** `backup_dr_readiness_audit.yml`
- **Scope:** Verifies point-in-time snapshot replication lag, RPO adherence, and network link latency between primary and DR data centers.
