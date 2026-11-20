# Repository File Inventory & Manifest

**Framework:** Enterprise Infrastructure Automation Framework  
**Verification Standard:** SHA-256 Hashed & Syntax Tested  
**Total Playbooks:** 104  
**Total Scripts:** 7  
**Total Vars Files:** 16  
**Total Doc Guides:** 13  

---

## 1. Root Configuration & Packaging
- `ansible.cfg`: Central Ansible configuration (forks=20, pipelining, JSON fact caching, logging)
- `README.md`: Architecture overview and onboarding guide
- `CHANGELOG.md`: Framework version history
- `requirements.yml`: Ansible Galaxy collection dependencies
- `requirements.txt`: Python package requirements
- `requirements-system.txt`: Operating system package requirements
- `PROJECT_COMPLETION_REPORT.md`: Comprehensive final project handover report

---

## 2. Project Management Core (`project-management/`)
- `PROJECT_MASTER_PLAN.md`: 15-phase architectural blueprint
- `PROJECT_STATUS.md`: Phase status dashboard (100% complete)
- `PROJECT_CHECKPOINT.md`: Active checkpoint pointer (`CHK-015`)
- `PROJECT_CHANGELOG.md`: Chronological task ledger
- `TASK_REGISTER.md`: Complete register of all 37 core tasks
- `FILE_INVENTORY.md`: This file
- `VALIDATION_STATUS.md`: Test matrix & live validation results
- `RESUME_INSTRUCTIONS.md`: Disaster recovery & resumption runbook
- `checkpoints/checkpoint_001.md` through `checkpoint_015.md`: Persistent milestone checkpoints

---

## 3. Operational Playbooks (`playbooks/`) - 86 Playbooks
### Linux (24 Playbooks)
- `playbooks/linux/linux_system_health_check.yml`
- `playbooks/linux/linux_hardware_inventory.yml`
- `playbooks/linux/linux_cpu_memory_performance.yml`
- `playbooks/linux/linux_filesystem_disk_audit.yml`
- `playbooks/linux/linux_service_status_audit.yml`
- `playbooks/linux/linux_network_connectivity_audit.yml`
- `playbooks/linux/linux_system_log_collection.yml`
- `playbooks/linux/linux_sar_performance_collection.yml`
- `playbooks/linux/linux_package_inventory.yml`
- `playbooks/linux/linux_multipath_san_audit.yml`
- `playbooks/linux/linux_process_resource_analysis.yml`
- `playbooks/linux/linux_security_config_audit.yml`
- `playbooks/linux/linux_kernel_crash_kdump_audit.yml`
- `playbooks/linux/linux_auditd_security_audit.yml`
- `playbooks/linux/linux_cron_systemd_timers_audit.yml`
- `playbooks/linux/linux_network_bonding_vlan_audit.yml`
- `playbooks/linux/linux_firewalld_iptables_audit.yml`
- `playbooks/linux/linux_ntp_chrony_drift_audit.yml`
- `playbooks/linux/linux_zombie_defunct_process_audit.yml`
- `playbooks/linux/linux_nfs_iscsi_client_mount_audit.yml`
- `playbooks/linux/linux_syslog_rsyslog_forwarding_audit.yml`
- `playbooks/linux/linux_user_access_sudoers_audit.yml`
- `playbooks/linux/linux_hugepages_transparent_hugepages_audit.yml`
- `playbooks/linux/linux_cgroups_resource_quota_audit.yml`

### IBM AIX (5 Playbooks)
- `playbooks/aix/aix_system_health_check.yml`
- `playbooks/aix/aix_hardware_lpar_inventory.yml`
- `playbooks/aix/aix_performance_collection.yml`
- `playbooks/aix/aix_filesystem_lvm_audit.yml`
- `playbooks/aix/aix_errpt_log_collection.yml`

### Windows Server (4 Playbooks)
- `playbooks/windows/windows_server_health_check.yml`
- `playbooks/windows/windows_event_log_collection.yml`
- `playbooks/windows/windows_service_process_audit.yml`
- `playbooks/windows/windows_disk_network_inventory.yml`

### Virtualization: VMware vSphere (5 Playbooks)
- `playbooks/vmware/vmware_vcenter_inventory.yml`
- `playbooks/vmware/vmware_esxi_host_health.yml`
- `playbooks/vmware/vmware_datastore_capacity_audit.yml`
- `playbooks/vmware/vmware_vm_resource_inventory.yml`
- `playbooks/vmware/vmware_snapshot_audit.yml`

### Virtualization: OLVM / OKVM (17 Playbooks)
- `playbooks/olvm/olvm_manager_inventory.yml`
- `playbooks/olvm/olvm_cluster_host_health.yml`
- `playbooks/olvm/olvm_vm_inventory.yml`
- `playbooks/olvm/olvm_datastore_audit.yml`
- `playbooks/olvm/olvm_network_audit.yml`
- `playbooks/olvm/olvm_snapshot_inventory.yml`
- `playbooks/olvm/olvm_vm_resource_audit.yml`
- `playbooks/olvm/olvm_engine_system_health_audit.yml`
- `playbooks/olvm/olvm_affinity_groups_audit.yml`
- `playbooks/olvm/olvm_storage_pool_manager_spm_audit.yml`
- `playbooks/olvm/olvm_mac_pool_ip_allocation_audit.yml`
- `playbooks/olvm/olvm_vm_ha_reservation_audit.yml`
- `playbooks/olvm/olvm_storage_domain_luns_audit.yml`
- `playbooks/olvm/olvm_vnic_profiles_qos_audit.yml`
- `playbooks/olvm/olvm_event_log_audit.yml`
- `playbooks/olvm/olvm_vm_migration_policy_audit.yml`
- `playbooks/olvm/olvm_template_disk_leak_audit.yml`

### Virtualization: Enterprise KVM (9 Playbooks)
- `playbooks/kvm/kvm_host_resource_audit.yml`
- `playbooks/kvm/kvm_qemu_guest_agent_audit.yml`
- `playbooks/kvm/kvm_cpu_pinning_numa_audit.yml`
- `playbooks/kvm/kvm_virtio_scsi_disk_performance_audit.yml`
- `playbooks/kvm/kvm_bridge_sriov_network_audit.yml`
- `playbooks/kvm/kvm_qcow2_disk_integrity_audit.yml`
- `playbooks/kvm/kvm_live_migration_network_audit.yml`
- `playbooks/kvm/kvm_guest_panic_crash_audit.yml`
- `playbooks/kvm/kvm_hugepages_memory_backing_audit.yml`

### Cloud & IaC: Terraform (3 Playbooks)
- `playbooks/terraform/terraform_environment_validation.yml`
- `playbooks/terraform/terraform_plan_review.yml`
- `playbooks/terraform/terraform_state_inventory.yml`

### Storage Arrays (6 Playbooks)
- `playbooks/storage/ibm/storage_ibm_inventory.yml`
- `playbooks/storage/ibm/storage_ibm_health_capacity.yml`
- `playbooks/storage/hpe/storage_hpe_inventory.yml`
- `playbooks/storage/hpe/storage_hpe_health_capacity.yml`
- `playbooks/storage/dell/storage_dell_inventory.yml`
- `playbooks/storage/dell/storage_dell_health_capacity.yml`

### SAN Switches (5 Playbooks)
- `playbooks/san-switches/brocade/san_brocade_switch_inventory.yml`
- `playbooks/san-switches/brocade/san_brocade_port_health.yml`
- `playbooks/san-switches/brocade/san_brocade_fabric_health.yml`
- `playbooks/san-switches/cisco/san_cisco_mds_inventory.yml`
- `playbooks/san-switches/cisco/san_cisco_fabric_port_audit.yml`

### High Availability Clustering (4 Playbooks)
- `playbooks/clustering/powerha/cluster_ibm_powerha_audit.yml`
- `playbooks/clustering/gpfs/cluster_ibm_gpfs_audit.yml`
- `playbooks/clustering/veritas/cluster_veritas_vcs_audit.yml`
- `playbooks/clustering/cluster_node_resource_audit.yml`

### Enterprise Backup & DR (4 Playbooks)
- `playbooks/backup-dr/backup_ibm_spectrum_protect_audit.yml`
- `playbooks/backup-dr/backup_veritas_netbackup_audit.yml`
- `playbooks/backup-dr/backup_dell_networker_audit.yml`
- `playbooks/backup-dr/backup_dr_readiness_audit.yml`

---

## 4. Incident Evidence Collection Suite (`incident-collection/`) - 10 Playbooks
- `incident-collection/linux/collect_linux_evidence.yml`
- `incident-collection/aix/collect_aix_evidence.yml`
- `incident-collection/windows/collect_windows_evidence.yml`
- `incident-collection/vmware/collect_vmware_evidence.yml`
- `incident-collection/olvm/collect_olvm_evidence.yml`
- `incident-collection/kvm/collect_kvm_evidence.yml`
- `incident-collection/storage/collect_storage_evidence.yml`
- `incident-collection/san-switches/collect_san_evidence.yml`
- `incident-collection/clustering/collect_cluster_evidence.yml`
- `incident-collection/backup-dr/collect_backup_evidence.yml`

---

## 5. Change Management & Verification (`operations/`) - 8 Playbooks
- `operations/changes/linux/change_linux_kernel_sysctl.yml`
- `operations/changes/linux/change_linux_extend_lvm.yml`
- `operations/changes/vmware/change_vmware_snapshot_consolidation.yml`
- `operations/changes/olvm/change_olvm_vm_disk_extend.yml`
- `operations/changes/storage/change_storage_volume_expand.yml`
- `operations/changes/clustering/change_cluster_maintenance_mode.yml`
- `operations/validation/pre_change_validation.yml`
- `operations/post-change-verification/post_change_verification.yml`

---

## 6. Operational Scripts (`scripts/`) - 7 Executable Shell Utilities
- `scripts/run-playbook.sh`
- `scripts/collect-incident-evidence.sh`
- `scripts/validate-inventory.sh`
- `scripts/install-dependencies.sh`
- `scripts/generate-report.sh`
- `scripts/backup-config.sh`
- `scripts/project-resume.sh`
