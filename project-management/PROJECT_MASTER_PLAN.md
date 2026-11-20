# Enterprise Infrastructure Automation & Incident Evidence Management Framework
## Master Architecture and Implementation Plan

---

## 1. Project Overview & Role Definition

**Architect:** L3 Enterprise Infrastructure Operations Architect & Automation Lead  
**Scope:** Multi-Platform Enterprise Infrastructure Automation, Incident Evidence Acquisition, Diagnostics, and Lifecycle Operations  
**Target Environments:** Linux (RHEL 5–10, Oracle Linux, SLES, Ubuntu), IBM AIX (6.1–7.3), Microsoft Windows Server (2012–2025), Virtualization (VMware vSphere 7/8, OLVM 4.4/4.5, Enterprise KVM), Infrastructure as Code (Terraform), Enterprise SAN/Storage (IBM FlashSystem/SVC, HPE 3PAR/Primera/Alletra, Dell PowerStore/PowerMax, Brocade Fabric OS, Cisco MDS NX-OS), High-Availability Clustering (IBM PowerHA, IBM GPFS/Spectrum Scale, Veritas InfoScale/VCS), and Enterprise Data Protection (IBM Spectrum Protect/TSM, Veritas NetBackup, Dell EMC NetWorker).

---

## 2. Core Architectural Principles: Think – Plan – Simulate – Build

```
  +------------------+      +------------------+      +------------------+      +------------------+
  |      THINK       | ---> |       PLAN       | ---> |     SIMULATE     | ---> |      BUILD       |
  | Discover, Verify |      | Master Specs,    |      | Check-mode, Mock |      | Modular FQCNs,   |
  | Target Platforms |      | Task Register    |      | Syntax & Dry-run |      | Evidence Engine  |
  +------------------+      +------------------+      +------------------+      +------------------+
```

1. **Safety First & Read-Only Default:** All baseline playbooks, health checks, and log collection engines are non-destructive and read-only.
2. **Strict FQCN Verification:** Every Ansible module used must be officially documented, verified in Ansible Galaxy, and addressed via Fully Qualified Collection Name (FQCN). No guessed parameters or invented attributes.
3. **Change Management Isolation:** All state-modifying tasks are isolated under `operations/changes/` and require explicit target confirmation, pre-flight validation, and automated rollback capability.
4. **Deterministic Incident Evidence Preservation:** The Incident Evidence Framework handles timestamped, tamper-evident case evidence with SHA-256 hashing, forensic log retention analysis, and multi-format reporting.
5. **Persistent Resumability:** State is permanently maintained in `project-management/` with numbered atomic checkpoints. An interruption at any stage can be recovered seamlessly.

---

## 3. Project Phase Roadmap

| Phase | Description | Deliverables | Status |
|---|---|---|---|
| **PHASE 1** | Environment Discovery & Safety | Discovery report, inventory validation, network audit | **COMPLETED** |
| **PHASE 2** | Architecture & Checkpoint Mechanism | Master plan, status register, changelog, checkpoint 001 | **ACTIVE** |
| **PHASE 3** | Ansible Config, Inventories & Dependencies | `ansible.cfg`, lab & prod inventories, requirements | PENDING |
| **PHASE 4** | Module & Galaxy Collection Verification | FQCN documentation, module-to-playbook mappings | PENDING |
| **PHASE 5** | Linux Operations Playbooks (12 Playbooks) | Health, disk, CPU/mem, SAR, security, multipath, etc. | PENDING |
| **PHASE 6** | AIX (5) & Windows (4) Playbooks | errpt, LVM, perf, WinEvent, WinRM/PSRP services | PENDING |
| **PHASE 7** | Virtualization: VMware (5), OLVM (7), KVM | vCenter, ESXi, OLVM API, KVM hypervisors, VM audit | PENDING |
| **PHASE 8** | Terraform (3), SAN (5), Storage (6) Playbooks | IBM, HPE, Dell, Brocade FOS, Cisco MDS, TF plan review | PENDING |
| **PHASE 9** | Clustering (4) & Backup / DR (4) Playbooks | PowerHA, GPFS, Veritas VCS, TSM, NetBackup, NetWorker | PENDING |
| **PHASE 10** | Incident Evidence Collection Framework | Interactive intake, Mode 1/2, SHA-256, retention engine | PENDING |
| **PHASE 11** | Logging, Reporting & Execution Wrappers | Timestamped logs, HTML/JSON reports, CLI wrappers | PENDING |
| **PHASE 12** | Change Management Separation & Verification | Pre/Post change engines, rollback, safety locks | PENDING |
| **PHASE 13** | Playbook Documentation & Quality Assurance | 20-point playbook documentation, test execution | PENDING |
| **PHASE 14** | Repository Audit & Final Completion Report | Validation report, inventory signoff, handover doc | PENDING |

---

## 4. Operational Playbook Inventory Breakdown (~55 Target Playbooks)

### 4.1 Linux Operations (12 Playbooks)
1. `linux_system_health_check.yml`: High-level host availability, load, zombie processes, dmesg errors.
2. `linux_hardware_inventory.yml`: DMI/SMBIOS, CPU flags, PCI devices, BIOS firmware versions.
3. `linux_cpu_memory_performance.yml`: Real-time saturation metrics, swap thrashing, NUMA balance, slab usage.
4. `linux_filesystem_disk_audit.yml`: Inode exhaustion, mount options, RO-remount detection, LVM integrity.
5. `linux_service_status_audit.yml`: Systemd/SysVinit failed states, socket activation, enablement status.
6. `linux_network_connectivity_audit.yml`: Interface packet drops, duplex, MTU, default routing, DNS latency.
7. `linux_system_log_collection.yml`: Extraction of `/var/log/messages`, `journalctl`, `secure`, and `audit.log`.
8. `linux_sar_performance_collection.yml`: Binary SAR extraction, `sadf` tabular output, historical CPU/disk/net.
9. `linux_package_inventory.yml`: RPM/DEB repository drift, installed packages, kernel security advisories.
10. `linux_multipath_san_audit.yml`: Device-mapper multipath paths, active/passive states, WWPNs, HBA queue depths.
11. `linux_process_resource_analysis.yml`: Top CPU/memory consumers, unkillable D-state processes, thread counts.
12. `linux_security_config_audit.yml`: SELinux/AppArmor enforcing state, SSH hardening, sysctl compliance, sudoers.

### 4.2 IBM AIX Operations (5 Playbooks)
13. `aix_system_health_check.yml`: AIX kernel state, dump device status, LED code alerts, maintenance level.
14. `aix_hardware_lpar_inventory.yml`: LPAR configuration, shared processor pool utilization, micro-partitioning.
15. `aix_performance_collection.yml`: `vmstat`, `iostat`, `svmon`, and `lparstat` comprehensive sampling.
16. `aix_filesystem_lvm_audit.yml`: Volume groups, logical volumes, physical volume stale partitions, JFS2 sanity.
17. `aix_errpt_log_collection.yml`: Detailed `errpt -a` hardware and software error log acquisition.

### 4.3 Microsoft Windows Server Operations (4 Playbooks)
18. `windows_server_health_check.yml`: Windows OS build, uptime, system reboot pending flags, BSOD bugchecks.
19. `windows_event_log_collection.yml`: System, Application, and Security event log export (EVTX/CSV).
20. `windows_service_process_audit.yml`: Automatic services in stopped state, handle leaks, thread analysis.
21. `windows_disk_network_inventory.yml`: ReFS/NTFS volumes, VSS shadow copy health, NIC teaming, SMB shares.

### 4.4 VMware vSphere Operations (5 Playbooks)
22. `vmware_vcenter_inventory.yml`: Datacenter, cluster, resource pool, and distributed switch topology.
23. `vmware_esxi_host_health.yml`: ESXi hardware sensor alarms, vSAN node status, host disconnected states.
24. `vmware_datastore_capacity_audit.yml`: VMFS/NFS/vSAN storage exhaustion, SIOC latency, uncommitted space.
25. `vmware_vm_resource_inventory.yml`: vCPU/RAM over-commitment, ballooning, CPU ready %, VM tools status.
26. `vmware_snapshot_audit.yml`: Snapshot tree depth, age older than 72 hours, orphan disk identification.

### 4.5 Oracle Linux Virtualization Manager (OLVM) / oVirt / KVM (7 Playbooks)
27. `olvm_manager_inventory.yml`: REST API engine inventory of clusters, data centers, networks, and storage domains.
28. `olvm_cluster_host_health.yml`: Hypervisor host status, CPU pinning, SPM status, power management fencing.
29. `olvm_vm_inventory.yml`: Detailed VM states, boot devices, MAC allocations, operating system types.
30. `olvm_datastore_audit.yml`: NFS, iSCSI, and FC storage domain allocation, thin-provisioning thresholds.
31. `olvm_network_audit.yml`: Logical networks, bond configurations, VLAN tagging, VM network QoS.
32. `olvm_snapshot_inventory.yml`: Active snapshots, consolidation requirements, preview states.
33. `kvm_host_resource_audit.yml`: Direct QEMU/libvirt hypervisor audit, `virsh` domain resource utilization.

### 4.6 Terraform Operations (3 Playbooks)
34. `terraform_environment_validation.yml`: Working directory lock check, backend S3/consul reachability, provider versions.
35. `terraform_plan_review.yml`: Automated speculative execution of `terraform plan` with resource change quantification.
36. `terraform_state_inventory.yml`: State file parsing, managed resource counts, drift detection audit.

### 4.7 Enterprise Storage Operations (IBM, HPE, Dell) (6 Playbooks)
37. `storage_ibm_inventory.yml`: IBM FlashSystem / SVC enclosure, canister, array, and mdisk group discovery.
38. `storage_ibm_health_capacity.yml`: Canister fault analysis, tier capacity distribution, flash drive wear metrics.
39. `storage_hpe_inventory.yml`: HPE 3PAR / Primera / Alletra CPG, node, cage, and physical drive inventory.
40. `storage_hpe_health_capacity.yml`: Node failover readiness, deduplication savings, chunklet allocation health.
41. `storage_dell_inventory.yml`: Dell PowerStore / PowerMax appliance, storage pool, and volume group catalog.
42. `storage_dell_health_capacity.yml`: Node battery backup unit health, thin-provisioning alerts, compression ratios.

### 4.8 SAN Fabric Switch Operations (Brocade & Cisco MDS) (5 Playbooks)
43. `san_brocade_switch_inventory.yml`: Brocade FOS chassis, blade, sensor, and firmware audit.
44. `san_brocade_port_health.yml`: SFP optical power (TX/RX dBm), CRC errors, invalid words, link resets.
45. `san_brocade_fabric_health.yml`: Fabric principal switch verification, ISL trunking, zone database integrity.
46. `san_cisco_mds_inventory.yml`: Cisco MDS 9000 supervisor, linecard, VSAN, and module audit.
47. `san_cisco_fabric_port_audit.yml`: VSAN membership, port-channel status, slow drain / credit loss detection.

### 4.9 High-Availability Clustering (PowerHA, GPFS, Veritas) (4 Playbooks)
48. `cluster_ibm_powerha_audit.yml`: Cluster topology, network heartbeat, resource group states, fallover policies.
49. `cluster_ibm_gpfs_audit.yml`: Spectrum Scale cluster state, quorum status, NSD availability, mount state.
50. `cluster_veritas_vcs_audit.yml`: InfoScale/VCS LLT/GAB communication, heartbeat links, service group states.
51. `cluster_node_resource_audit.yml`: Cross-platform quorum analysis, split-brain fence validation, VIP status.

### 4.10 Enterprise Backup & Disaster Recovery (4 Playbooks)
52. `backup_ibm_spectrum_protect_audit.yml`: TSM client scheduler daemon, node session health, backup completion.
53. `backup_veritas_netbackup_audit.yml`: NBU client daemons (`bpcd`, `vnetd`), certificate status, backup exit codes.
54. `backup_dell_networker_audit.yml`: NetWorker `nsrexecd` daemon, client index save status, client configuration.
55. `backup_dr_readiness_audit.yml`: RPO/RTO compliance audit, disaster recovery replication status, snapshot validity.

---

## 5. Change Management Governance & Isolation

```
Infrastructure-Automation/
|-- operations/
|   |-- health-checks/             <-- 100% Read-Only Status & Metrics
|   |-- log-collection/            <-- Read-Only Forensic Extraction
|   |-- performance-reports/       <-- Read-Only Telemetry & Analysis
|   |-- configuration-audits/      <-- Read-Only State Comparison
|   |-- infrastructure-inventory/  <-- Read-Only Topology Discovery
|   |-- changes/                   <-- STATE-MODIFYING AUTOMATION (Restricted)
|   |   |-- pre-change-checks/     <-- Automated pre-flight validation
|   |   |-- execution/             <-- Explicit confirmation, check-mode gates
|   |   |-- post-change-checks/    <-- Immediate SLA & stability validation
|   |   `-- rollback/              <-- Deterministic reversal procedures
```

Every playbook classified as `CHANGE` requires:
- Pre-execution confirmation prompt or variable (`confirm_change=true`)
- Pre-change snapshot / configuration backup
- Check-mode dry-run verification
- Immediate post-change verification tasks
- Documented manual and automated rollback procedures

---

## 6. Incident Evidence Collection Framework

The Incident Collection Engine provides enterprise L3 engineers with rapid, forensically sound evidence gathering for critical ServiceNow incident tickets.

1. **Intake Profiles:**
   - `quick`: Critical alerts, immediate system logs, recent crashes, service failures.
   - `standard`: Full system logs, SAR metrics for 7 days, service status, network tables, filesystem maps.
   - `comprehensive`: Complete log archives, all historical SAR data, core dumps metadata, kernel traces, hardware diagnostics.
2. **Time Modes:**
   - `MODE 1 (N-Days)`: Collect past 3, 5, 10, 15, or 30 days.
   - `MODE 2 (Incident-Centric Window)`: Collect $T_{incident} - N_{before}$ to $T_{incident} + N_{after}$.
3. **Forensic Integrity:**
   - Manifest generated with SHA-256 checksums for every collected file.
   - Forensic log retention analysis (evaluates logrotate, journal retention, compressed logs, missing files).
   - Timestamped case output: `case-output/INCXXXXXXX/session_<TIMESTAMP>/`.
   - Comprehensive HTML and text incident summary reports.
