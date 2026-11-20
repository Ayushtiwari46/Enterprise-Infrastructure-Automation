# Project Master Changelog

All notable changes to the Enterprise Infrastructure Automation Framework will be documented in this file.

---

## [1.1.0-Enterprise] - 2026-11-20
### Added
- **Phase 15 (Expansion Suite - 30 Advanced Playbooks):**
  - **12 Advanced Linux Playbooks:** `linux_kernel_crash_kdump_audit.yml`, `linux_auditd_security_audit.yml`, `linux_cron_systemd_timers_audit.yml`, `linux_network_bonding_vlan_audit.yml`, `linux_firewalld_iptables_audit.yml`, `linux_ntp_chrony_drift_audit.yml`, `linux_zombie_defunct_process_audit.yml`, `linux_nfs_iscsi_client_mount_audit.yml`, `linux_syslog_rsyslog_forwarding_audit.yml`, `linux_user_access_sudoers_audit.yml`, `linux_hugepages_transparent_hugepages_audit.yml`, `linux_cgroups_resource_quota_audit.yml`.
  - **10 Advanced OLVM / OKVM Playbooks:** `olvm_engine_system_health_audit.yml`, `olvm_affinity_groups_audit.yml`, `olvm_storage_pool_manager_spm_audit.yml`, `olvm_mac_pool_ip_allocation_audit.yml`, `olvm_vm_ha_reservation_audit.yml`, `olvm_storage_domain_luns_audit.yml`, `olvm_vnic_profiles_qos_audit.yml`, `olvm_event_log_audit.yml`, `olvm_vm_migration_policy_audit.yml`, `olvm_template_disk_leak_audit.yml`.
  - **8 Advanced Enterprise KVM Playbooks:** `kvm_qemu_guest_agent_audit.yml`, `kvm_cpu_pinning_numa_audit.yml`, `kvm_virtio_scsi_disk_performance_audit.yml`, `kvm_bridge_sriov_network_audit.yml`, `kvm_qcow2_disk_integrity_audit.yml`, `kvm_live_migration_network_audit.yml`, `kvm_guest_panic_crash_audit.yml`, `kvm_hugepages_memory_backing_audit.yml`.
- Total repository playbooks expanded from 74 to **104 Playbooks**.
- Full test suite execution: **104/104 PASSED (100% syntax compliance, 0 failures)**.
- Multi-domain live lab execution verified against `ansible-nfs.lab.local`, `olvm-engine.lab.local`, and `kvm-host-1.lab.local`.
- Checkpoint `CHK-015` recorded.

---

## [1.0.0-Enterprise] - 2026-11-20
### Added
- **Phase 1:** Environment discovery report cataloging 4 live nodes (`192.168.242.132` ansible-nfs, `192.168.242.133` olvm-engine, `192.168.242.134` kvm-host-1, `192.168.242.135` kvm-host-2).
- **Phase 2:** Complete 75-subdirectory architecture across Windows workspace and remote controller.
- **Phase 3:** Production-tuned `ansible.cfg` (forks=20, pipelining, JSON fact caching), `lab/hosts.yml`, `production-template/hosts.yml`, and 16 central variable files in `vars/`.
- **Phase 4:** Official Ansible Galaxy collections (`ansible.posix`, `community.general`, `ansible.windows`, `community.vmware`, `ovirt.ovirt`, `cisco.nxos`, `ansible.netcommon`, `ansible.utils`). Documented module and collection references.
- **Phase 5:** 12 Enterprise Linux operations playbooks (`linux_system_health_check.yml`, hardware inventory, CPU/RAM, filesystems, systemd services, networking, logs, SAR, packages, multipath, processes, security audit). Tested live with YAML reporting.
- **Phase 6:** 5 IBM AIX playbooks (`errpt`, `lpar`, `perf`, `lvm`, `system_health`) + 4 Windows Server playbooks (`win_service`, `win_eventlog`, `win_disk`, `win_health`).
- **Phase 7:** 13 Virtualization playbooks: 5 VMware vSphere playbooks, 7 OLVM playbooks, 1 KVM playbook. Tested live against KVM hypervisor.
- **Phase 8:** 3 Terraform playbooks, 6 Storage playbooks (IBM FlashSystem, HPE Primera, Dell PowerStore), and 5 SAN switch playbooks (Brocade FOS, Cisco MDS NX-OS).
- **Phase 9:** 4 High Availability clustering playbooks (PowerHA, GPFS, VCS, node audit) and 4 Enterprise Backup/DR playbooks (Spectrum Protect, NetBackup, NetWorker, DR readiness). Reached 56 operational playbooks.
- **Phase 10:** Interactive CLI intake wrapper (`scripts/collect-incident-evidence.sh`) + 10 technology-specific collection playbooks in `incident-collection/`. Verified live incident evidence collection with SHA-256 manifests and HTML executive dossiers.
- **Phase 11:** 7 operational shell wrappers (`run-playbook.sh`, `collect-incident-evidence.sh`, `validate-inventory.sh`, `install-dependencies.sh`, `generate-report.sh`, `backup-config.sh`, `project-resume.sh`) and 3 Jinja2 templates (`incident_evidence_report.html.j2`, `health_check_summary.html.j2`, `configuration_audit.html.j2`).
- **Phase 12:** 6 mutating change playbooks in `operations/changes/` protected by `-e "confirm_change=true"` safeguard + full `--check` mode support + pre-change baseline and post-change verification playbooks. Tested safeguard blocking and check mode dry-runs.
- **Phase 13:** Comprehensive playbook guides, troubleshooting runbooks, security guides, and end-to-end workflow examples in `docs/`. Authored and executed `run_all_syntax_tests.py` passing 74/74 playbooks (100%).
- **Phase 14:** Root `PROJECT_COMPLETION_REPORT.md` and final audit checkpoint `CHK-014`.
