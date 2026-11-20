# Enterprise Linux Operations Playbook Guide

**Target Audience:** L3 Infrastructure Operations Engineers, Linux Systems Administrators  
**Framework Version:** 1.0.0-Enterprise  
**Classification:** Operational Runbook  

---

## 1. Executive Summary & Architecture
The Linux Operations automation suite comprises 24 production-grade Ansible playbooks located in `playbooks/linux/`. Each playbook follows non-destructive, read-only principles designed to diagnose system health, audit security settings, analyze resource consumption, and extract telemetry without risking service disruption.

---

## 2. Playbook Inventory & Reference Matrix

| Playbook File | Primary Ansible Modules (FQCN) | Execution Mode | Output Path |
| :--- | :--- | :--- | :--- |
| `linux_system_health_check.yml` | `ansible.builtin.setup`, `ansible.builtin.command`, `ansible.builtin.copy` | Read-Only | `reports/health-checks/<host>/system_health.yml` |
| `linux_hardware_inventory.yml` | `ansible.builtin.setup`, `ansible.builtin.command` | Read-Only | Console / Structured Facts |
| `linux_cpu_memory_performance.yml` | `ansible.builtin.shell`, `ansible.builtin.setup` | Read-Only | `reports/performance/<host>/cpu_memory_metrics.txt` |
| `linux_filesystem_disk_audit.yml` | `ansible.builtin.shell`, `ansible.builtin.assert` | Read-Only | `reports/configuration-audits/<host>/filesystem_audit.txt` |
| `linux_service_status_audit.yml` | `ansible.builtin.service_facts`, `ansible.builtin.debug` | Read-Only | Systemd failed service ledger |
| `linux_network_connectivity_audit.yml` | `ansible.builtin.shell`, `ansible.builtin.command` | Read-Only | `reports/configuration-audits/<host>/network_audit.txt` |
| `linux_system_log_collection.yml` | `ansible.builtin.fetch`, `ansible.builtin.find` | Read-Only | Central log repository |
| `linux_sar_performance_collection.yml` | `ansible.builtin.find`, `ansible.builtin.fetch` | Read-Only | `reports/performance/<host>/sar/` |
| `linux_package_inventory.yml` | `ansible.builtin.package_facts`, `ansible.builtin.copy` | Read-Only | `reports/configuration-audits/<host>/packages.txt` |
| `linux_multipath_san_audit.yml` | `ansible.builtin.command`, `ansible.builtin.shell` | Read-Only | `reports/configuration-audits/<host>/multipath_status.txt` |
| `linux_process_resource_analysis.yml` | `ansible.builtin.shell`, `ansible.builtin.copy` | Read-Only | `reports/performance/<host>/top_processes.txt` |
| `linux_security_config_audit.yml` | `ansible.builtin.command`, `ansible.builtin.stat` | Read-Only | `reports/configuration-audits/<host>/security_audit.txt` |
| `linux_kernel_crash_kdump_audit.yml` | `ansible.builtin.shell`, `ansible.builtin.copy` | Read-Only | `reports/configuration-audits/<host>/kdump_audit.txt` |
| `linux_auditd_security_audit.yml` | `ansible.builtin.shell`, `ansible.builtin.copy` | Read-Only | `reports/configuration-audits/<host>/auditd_audit.txt` |
| `linux_cron_systemd_timers_audit.yml`| `ansible.builtin.command`, `ansible.builtin.shell` | Read-Only | `reports/configuration-audits/<host>/scheduled_jobs_audit.txt` |
| `linux_network_bonding_vlan_audit.yml`| `ansible.builtin.shell`, `ansible.builtin.copy` | Read-Only | `reports/configuration-audits/<host>/network_bonding_vlan_audit.txt` |
| `linux_firewalld_iptables_audit.yml` | `ansible.builtin.shell`, `ansible.builtin.copy` | Read-Only | `reports/configuration-audits/<host>/firewall_audit.txt` |
| `linux_ntp_chrony_drift_audit.yml` | `ansible.builtin.command`, `ansible.builtin.shell` | Read-Only | `reports/configuration-audits/<host>/clock_sync_drift_audit.txt` |
| `linux_zombie_defunct_process_audit.yml`| `ansible.builtin.shell`, `ansible.builtin.copy` | Read-Only | `reports/performance/<host>/zombie_process_analysis.txt` |
| `linux_nfs_iscsi_client_mount_audit.yml`| `ansible.builtin.shell`, `ansible.builtin.copy` | Read-Only | `reports/configuration-audits/<host>/nfs_iscsi_client_audit.txt` |
| `linux_syslog_rsyslog_forwarding_audit.yml`| `ansible.builtin.shell`, `ansible.builtin.copy` | Read-Only | `reports/configuration-audits/<host>/syslog_forwarding_audit.txt` |
| `linux_user_access_sudoers_audit.yml` | `ansible.builtin.shell`, `ansible.builtin.copy` | Read-Only | `reports/configuration-audits/<host>/user_access_sudoers_audit.txt` |
| `linux_hugepages_transparent_hugepages_audit.yml`| `ansible.builtin.shell`, `ansible.builtin.copy` | Read-Only | `reports/performance/<host>/hugepages_thp_audit.txt` |
| `linux_cgroups_resource_quota_audit.yml`| `ansible.builtin.shell`, `ansible.builtin.copy` | Read-Only | `reports/performance/<host>/cgroups_resource_audit.txt` |

---

## 3. Standard Operational Procedures

### 3.1 Executing Routine Health Checks
To execute a health check against the entire Linux cluster or an individual node:
```bash
# Entire Linux Estate
./scripts/run-playbook.sh -p playbooks/linux/linux_system_health_check.yml

# Specific Target Node
./scripts/run-playbook.sh -p playbooks/linux/linux_system_health_check.yml -l ansible-nfs.lab.local
```

### 3.2 Multipath & SAN LUN Path Audits
During storage maintenance or post-SAN failover verification:
```bash
./scripts/run-playbook.sh -p playbooks/linux/linux_multipath_san_audit.yml -l kvm-host-1.lab.local
```
Outputs active/passive path counts, failed paths, and device WWIDs into `reports/configuration-audits/`.

### 3.3 Historical SAR Telemetry Acquisition
To collect binary SAR metrics for forensic performance diagnosis:
```bash
./scripts/run-playbook.sh -p playbooks/linux/linux_sar_performance_collection.yml -e "n_days=7"
```

---

## 4. Troubleshooting Common Failures

1. **Missing `/var/log/sa` Directory:**
   - *Symptom:* Playbook issues warning that `/var/log/sa` is not a directory.
   - *Resolution:* Install `sysstat` package (`dnf install sysstat -y`) and enable the timer (`systemctl enable --now sysstat.timer`).
2. **SSH Public Key Rejection:**
   - *Symptom:* `UNREACHABLE! => Failed to connect to the host via ssh: Permission denied`.
   - *Resolution:* Deploy SSH public key from control node using `ssh-copy-id -i /root/.ssh/id_rsa.pub root@<target_node>`.
3. **Privilege Escalation Prompts:**
   - *Symptom:* `Missing sudo password`.
   - *Resolution:* Verify that the operations user has passwordless sudo configured in `/etc/sudoers.d/99-operations`.
