# Module-to-Playbook Verification Matrix

This matrix documents the exact Fully Qualified Collection Names (FQCN) used across all operational playbooks in this repository, verifying compliance with the strict Ansible module verification mandate.

---

## 1. Linux Operations Playbooks (Phase 5)

| Playbook | Primary Modules Used (FQCN) | Operational Classification |
|---|---|---|
| `linux_system_health_check.yml` | `ansible.builtin.setup`, `ansible.builtin.command`, `ansible.builtin.stat`, `ansible.builtin.template` | READ_ONLY |
| `linux_hardware_inventory.yml` | `ansible.builtin.setup`, `ansible.builtin.command`, `ansible.builtin.copy` | READ_ONLY |
| `linux_cpu_memory_performance.yml` | `ansible.builtin.command`, `ansible.builtin.slurp`, `ansible.builtin.template` | PERFORMANCE_COLLECTION |
| `linux_filesystem_disk_audit.yml` | `ansible.builtin.setup`, `ansible.builtin.command`, `ansible.builtin.stat` | CONFIGURATION_AUDIT |
| `linux_service_status_audit.yml` | `ansible.builtin.service_facts`, `ansible.builtin.command` | READ_ONLY |
| `linux_network_connectivity_audit.yml` | `ansible.builtin.setup`, `ansible.builtin.command`, `ansible.builtin.uri` | READ_ONLY |
| `linux_system_log_collection.yml` | `ansible.builtin.find`, `ansible.builtin.fetch`, `ansible.builtin.command` | LOG_COLLECTION |
| `linux_sar_performance_collection.yml` | `ansible.builtin.find`, `ansible.builtin.fetch`, `ansible.builtin.command` | PERFORMANCE_COLLECTION |
| `linux_package_inventory.yml` | `ansible.builtin.package_facts`, `ansible.builtin.command` | CONFIGURATION_AUDIT |
| `linux_multipath_san_audit.yml` | `ansible.builtin.command`, `ansible.builtin.stat`, `ansible.builtin.find` | CONFIGURATION_AUDIT |
| `linux_process_resource_analysis.yml`| `ansible.builtin.command`, `ansible.builtin.slurp` | PERFORMANCE_COLLECTION |
| `linux_security_config_audit.yml` | `ansible.builtin.command`, `ansible.builtin.stat`, `ansible.builtin.slurp` | CONFIGURATION_AUDIT |

---

## 2. AIX and Windows Playbooks (Phase 6)

| Playbook | Primary Modules Used (FQCN) | Operational Classification |
|---|---|---|
| `aix_system_health_check.yml` | `ansible.builtin.setup`, `ansible.builtin.command`, `ansible.builtin.template` | READ_ONLY |
| `aix_hardware_lpar_inventory.yml` | `ansible.builtin.command`, `ansible.builtin.copy` | READ_ONLY |
| `aix_performance_collection.yml` | `ansible.builtin.command`, `ansible.builtin.template` | PERFORMANCE_COLLECTION |
| `aix_filesystem_lvm_audit.yml` | `ansible.builtin.command`, `community.general.lvol` | CONFIGURATION_AUDIT |
| `aix_errpt_log_collection.yml` | `ansible.builtin.command`, `ansible.builtin.fetch` | LOG_COLLECTION |
| `windows_server_health_check.yml` | `ansible.windows.win_command`, `ansible.windows.win_service_info` | READ_ONLY |
| `windows_event_log_collection.yml` | `ansible.windows.win_shell`, `ansible.builtin.fetch` | LOG_COLLECTION |
| `windows_service_process_audit.yml` | `ansible.windows.win_service_info`, `ansible.windows.win_shell` | READ_ONLY |
| `windows_disk_network_inventory.yml` | `ansible.windows.win_shell`, `ansible.windows.win_command` | CONFIGURATION_AUDIT |

---

## 3. Virtualization Playbooks (VMware, OLVM, KVM - Phase 7)

| Playbook | Primary Modules Used (FQCN) | Operational Classification |
|---|---|---|
| `vmware_vcenter_inventory.yml` | `community.vmware.vmware_vm_info`, `community.vmware.vmware_host_info` | READ_ONLY |
| `vmware_esxi_host_health.yml` | `community.vmware.vmware_host_facts`, `ansible.builtin.uri` | READ_ONLY |
| `vmware_datastore_capacity_audit.yml`| `community.vmware.vmware_datastore_info` | CONFIGURATION_AUDIT |
| `vmware_vm_resource_inventory.yml` | `community.vmware.vmware_vm_info` | PERFORMANCE_COLLECTION |
| `vmware_snapshot_audit.yml` | `community.vmware.vmware_guest_snapshot_info` | CONFIGURATION_AUDIT |
| `olvm_manager_inventory.yml` | `ovirt.ovirt.ovirt_vm_info`, `ansible.builtin.uri` | READ_ONLY |
| `olvm_cluster_host_health.yml` | `ovirt.ovirt.ovirt_host_info`, `ansible.builtin.uri` | READ_ONLY |
| `olvm_vm_inventory.yml` | `ovirt.ovirt.ovirt_vm_info` | READ_ONLY |
| `olvm_datastore_audit.yml` | `ovirt.ovirt.ovirt_storage_domain_info`, `ansible.builtin.uri` | CONFIGURATION_AUDIT |
| `olvm_network_audit.yml` | `ovirt.ovirt.ovirt_network_info` | CONFIGURATION_AUDIT |
| `olvm_snapshot_inventory.yml` | `ovirt.ovirt.ovirt_snapshot_info` | CONFIGURATION_AUDIT |
| `kvm_host_resource_audit.yml` | `ansible.builtin.command`, `ansible.builtin.stat` | PERFORMANCE_COLLECTION |

---

## 4. Terraform, Storage & SAN Playbooks (Phase 8)

| Playbook | Primary Modules Used (FQCN) | Operational Classification |
|---|---|---|
| `terraform_environment_validation.yml`| `ansible.builtin.command`, `ansible.builtin.stat` | CONFIGURATION_AUDIT |
| `terraform_plan_review.yml` | `ansible.builtin.command` (with `-lock=false`) | READ_ONLY |
| `terraform_state_inventory.yml` | `ansible.builtin.command`, `ansible.builtin.slurp` | READ_ONLY |
| `storage_ibm_inventory.yml` | `ansible.builtin.command` (CLI over SSH) / `ansible.builtin.uri` | READ_ONLY |
| `storage_ibm_health_capacity.yml` | `ansible.builtin.command` / `ansible.builtin.uri` | CONFIGURATION_AUDIT |
| `storage_hpe_inventory.yml` | `ansible.builtin.uri` (REST WSAPI) | READ_ONLY |
| `storage_hpe_health_capacity.yml` | `ansible.builtin.uri` (REST WSAPI) | CONFIGURATION_AUDIT |
| `storage_dell_inventory.yml` | `ansible.builtin.uri` (REST API) | READ_ONLY |
| `storage_dell_health_capacity.yml` | `ansible.builtin.uri` (REST API) | CONFIGURATION_AUDIT |
| `san_brocade_switch_inventory.yml` | `ansible.builtin.command` (FOS CLI) / `ansible.builtin.uri` | READ_ONLY |
| `san_brocade_port_health.yml` | `ansible.builtin.command` (`porterrshow`, `sfpshow`) | PERFORMANCE_COLLECTION |
| `san_brocade_fabric_health.yml` | `ansible.builtin.command` (`fabricshow`, `cfgshow`) | CONFIGURATION_AUDIT |
| `san_cisco_mds_inventory.yml` | `cisco.nxos.nxos_command`, `ansible.builtin.command` | READ_ONLY |
| `san_cisco_fabric_port_audit.yml` | `cisco.nxos.nxos_command`, `ansible.builtin.command` | CONFIGURATION_AUDIT |

---

## 5. Clustering & Backup / DR Playbooks (Phase 9)

| Playbook | Primary Modules Used (FQCN) | Operational Classification |
|---|---|---|
| `cluster_ibm_powerha_audit.yml` | `ansible.builtin.command` (`clshowres`, `cldump`) | CONFIGURATION_AUDIT |
| `cluster_ibm_gpfs_audit.yml` | `ansible.builtin.command` (`mmgetstate`, `mmlsdisk`, `mmlscluster`)| CONFIGURATION_AUDIT |
| `cluster_veritas_vcs_audit.yml` | `ansible.builtin.command` (`hastatus -sum`, `gabconfig -a`) | CONFIGURATION_AUDIT |
| `cluster_node_resource_audit.yml` | `ansible.builtin.command`, `ansible.builtin.setup` | READ_ONLY |
| `backup_ibm_spectrum_protect_audit.yml`| `ansible.builtin.command` (`dsmc query schedule`), `ansible.builtin.slurp` | READ_ONLY |
| `backup_veritas_netbackup_audit.yml` | `ansible.builtin.command` (`bpclntcmd`, `bpps`) | READ_ONLY |
| `backup_dell_networker_audit.yml` | `ansible.builtin.command` (`nsradmin`, `nsrwatch`) | READ_ONLY |
| `backup_dr_readiness_audit.yml` | `ansible.builtin.command`, `ansible.builtin.stat` | CONFIGURATION_AUDIT |

---

## 6. Incident Evidence Collection Playbooks (Phase 10)

All Incident Collection playbooks utilize:
- `ansible.builtin.setup` (Core environment facts)
- `ansible.builtin.find` (Time-windowed log file discovery: Mode 1 & Mode 2)
- `ansible.builtin.stat` (File size, mtime, ownership, permission audit)
- `ansible.builtin.command` (System state, process tables, SAR dumps, hardware logs)
- `ansible.builtin.fetch` (Secure transfer to controller `case-output/` vault)
- `ansible.builtin.copy` / `ansible.builtin.template` (SHA-256 manifests, retention logs, HTML summaries)
