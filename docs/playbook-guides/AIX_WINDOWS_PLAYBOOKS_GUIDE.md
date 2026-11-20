# Enterprise IBM AIX & Windows Server Playbook Guide

**Target Audience:** L3 Infrastructure Operations Engineers, Unix/AIX Specialists, Windows Systems Administrators  
**Framework Version:** 1.0.0-Enterprise  
**Classification:** Operational Runbook  

---

## 1. IBM AIX Playbook Suite (5 Playbooks)
Located in `playbooks/aix/`, these playbooks automate critical operations on IBM POWER systems running AIX 6.1, 7.1, 7.2, and 7.3.

| Playbook File | Key AIX Commands / Modules | Operational Focus |
| :--- | :--- | :--- |
| `aix_system_health_check.yml` | `oslevel -s`, `uptime`, `errpt -d H,S`, `df -g` | Overall LPAR health, boot image, firmware levels |
| `aix_hardware_lpar_inventory.yml` | `prtconf`, `lscfg -vp`, `lsdev -Cc disk` | POWER processor entitlement, SMT threads, VIO vSCSI/NPIV |
| `aix_performance_collection.yml` | `vmstat -v`, `iostat -D 1 3`, `topas -P` | Memory pool saturation, paging space usage, disk queues |
| `aix_filesystem_lvm_audit.yml` | `lsvg -o`, `lsvg -l <vg>`, `lspv` | Volume Group states, stale PPs, mirror synchronization |
| `aix_errpt_log_collection.yml` | `errpt -a`, `errlogger` | Error report acquisition, hardware failovers, disk sense errors |

### Execution Syntax:
```bash
# Execute full AIX health check against LPARs
./scripts/run-playbook.sh -p playbooks/aix/aix_system_health_check.yml -l aix_power_all

# Extract hardware inventory
./scripts/run-playbook.sh -p playbooks/aix/aix_hardware_lpar_inventory.yml -l mock-aix-p9-01.lab.local
```

---

## 2. Microsoft Windows Server Playbook Suite (4 Playbooks)
Located in `playbooks/windows/`, these playbooks utilize `ansible.windows` and WinRM/PowerShell to manage Windows Server 2012 R2 through 2025.

| Playbook File | Primary Ansible Modules (FQCN) | Operational Focus |
| :--- | :--- | :--- |
| `windows_server_health_check.yml` | `ansible.windows.win_service_info`, `ansible.windows.win_command` | Pending reboots, system uptime, critical services |
| `windows_event_log_collection.yml` | `ansible.windows.win_powershell`, `ansible.builtin.fetch` | Application, System, and Security Event log export |
| `windows_service_process_audit.yml`| `ansible.windows.win_service_info`, `ansible.windows.win_powershell`| Automatic delayed-start services, thread bottlenecks |
| `windows_disk_network_inventory.yml`| `ansible.windows.win_disk_facts`, `ansible.windows.win_powershell`| NTFS/ReFS volumes, BitLocker status, NIC teaming |

### Execution Syntax:
```bash
# Run Windows health check
./scripts/run-playbook.sh -p playbooks/windows/windows_server_health_check.yml -l windows_all

# Export Windows Event Logs for incident review
./scripts/run-playbook.sh -p playbooks/windows/windows_event_log_collection.yml -e "hours=24"
```

---

## 3. L3 Operations Best Practices
1. **AIX Error Log (errpt):** Always filter by permanent hardware (`-T PERM -d H`) and system errors (`-d S`) to identify failing adapter paths or deconfigured memory banks.
2. **Windows Pending Reboots:** Windows updates frequently trigger `Component Based Servicing (CBS)` or `Windows Update` pending reboot registry flags. `windows_server_health_check.yml` detects these flags before scheduling production maintenance windows.
