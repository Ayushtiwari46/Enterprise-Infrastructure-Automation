# Enterprise Ansible Collection Reference Index

**Specification:** Verified Fully Qualified Collection Names (FQCN), Version Alignment, and Installation Paths.  
**Auditor:** L3 Enterprise Infrastructure Operations Architect  
**Ansible Core:** 2.16.3  
**Verification Date:** 2026-11-20

---

## 1. Verified Collections Register

| Collection Name | Verified Version | Official Galaxy / Repo URL | Scope & Primary Use Cases |
|---|---|---|---|
| `ansible.builtin` | 2.16.3 (Core) | https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ | Core POSIX commands, setup, fetch, find, copy, stat, template, uri, package_facts, service_facts |
| `ansible.posix` | 2.2.2 | https://galaxy.ansible.com/ui/repo/published/ansible/posix/ | Linux/POSIX sysctl, mount, firewalld, authorized_key, at, selinux |
| `community.general` | 14.0.1 | https://galaxy.ansible.com/ui/repo/published/community/general/ | AIX (`aix_devices`, `lvol`, `mksysb`), Solaris, LVM, SAR, disk partitioning, logrotate, VCS |
| `community.vmware` | >=4.4.0 | https://galaxy.ansible.com/ui/repo/published/community/vmware/ | VMware vCenter, ESXi hosts, clusters, datastores, VM guest info, snapshots |
| `ovirt.ovirt` | >=3.2.0 | https://galaxy.ansible.com/ui/repo/published/ovirt/ovirt/ | Oracle Linux Virtualization Manager (OLVM) / oVirt REST engine VM and cluster management |
| `cisco.nxos` | >=6.2.0 | https://galaxy.ansible.com/ui/repo/published/cisco/nxos/ | Cisco MDS 9000 Series Fabric and port management via NX-API / SSH |
| `ansible.windows` | >=2.4.0 | https://galaxy.ansible.com/ui/repo/published/ansible/windows/ | Microsoft Windows Server core modules (`win_command`, `win_shell`, `win_service_info`, `win_stat`, `win_copy`) |
| `community.windows` | >=2.2.0 | https://galaxy.ansible.com/ui/repo/published/community/windows/ | Windows event log management (`win_eventlog`, `win_scheduled_task`) |
| `ibm.storage_virtualize` | >=2.2.0 | https://galaxy.ansible.com/ui/repo/published/ibm/storage_virtualize/ | IBM FlashSystem / SVC SAN Volume Controller configuration and telemetry |

---

## 2. Air-Gapped / Offline Staging Strategy

For air-gapped enterprise customer data centers:
1. Download collections as `.tar.gz` artifacts using `ansible-galaxy collection download -r requirements.yml -p dependencies/galaxy-collections`.
2. Transfer `dependencies/galaxy-collections` to the target customer bastion / control node.
3. Install offline via:
   ```bash
   ansible-galaxy collection install dependencies/galaxy-collections/*.tar.gz -p /root/.ansible/collections
   ```
4. The local `ansible.cfg` is pre-configured with:
   `collections_path = dependencies/galaxy-collections:/root/.ansible/collections:/usr/share/ansible/collections`
   ensuring transparent fallback to bundled dependencies.
