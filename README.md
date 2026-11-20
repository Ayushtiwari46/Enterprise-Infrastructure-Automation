# Enterprise Infrastructure Automation & Incident Evidence Management Framework

An enterprise-grade, multi-platform infrastructure automation repository engineered for **IT Infrastructure Engineers – L3**, Operations Architects, and Incident Responders.

---

## 1. Supported Technology Domains

- **Linux Operating Systems:** Red Hat Enterprise Linux (RHEL 5–10), Oracle Linux Server (8.x/9.x), SUSE Linux Enterprise Server (SLES), Ubuntu LTS.
- **UNIX Systems:** IBM AIX (6.1, 7.1, 7.2, 7.3) on IBM Power Systems.
- **Windows Server:** Windows Server 2012 R2, 2016, 2019, 2022, 2025.
- **Virtualization & Hypervisors:** VMware vSphere 7/8 (vCenter & ESXi), Oracle Linux Virtualization Manager (OLVM 4.4/4.5 / oVirt), Enterprise KVM / libvirt.
- **Infrastructure as Code:** HashiCorp Terraform environment validation, speculative plan reviews, and state audits.
- **Enterprise Storage:** IBM FlashSystem / SAN Volume Controller (SVC), HPE 3PAR / Primera / Alletra, Dell PowerStore / PowerMax.
- **Storage Area Networks (SAN):** Brocade Fabric OS (FOS) switches, Cisco MDS 9000 Series (NX-OS) Director switches.
- **High-Availability Clustering:** IBM PowerHA SystemMirror, IBM GPFS / Spectrum Scale, Veritas InfoScale / Cluster Server (VCS).
- **Enterprise Backup & Disaster Recovery:** IBM Spectrum Protect (TSM), Veritas NetBackup, Dell EMC NetWorker, DR Readiness.

---

## 2. Repository Structure

```
Infrastructure-Automation/
|-- ansible.cfg                  # Enterprise controller tuning & defaults
|-- requirements.yml             # Verified Galaxy collection manifest
|-- requirements.txt             # Python dependency manifest
|-- requirements-system.txt      # System RPM/DEB package manifest
|-- project-management/          # Checkpoint & persistent progress ledger
|-- inventories/                 # Lab and Production template inventories
|-- playbooks/                   # 55+ production-grade operational playbooks
|-- incident-collection/         # Forensic incident evidence engines
|-- operations/                  # Segregated operational activities (Health, Audit, Changes)
|-- roles/                       # Reusable infrastructure roles
|-- vars/                        # Central variable hierarchy
|-- scripts/                     # Shell wrappers & automation intake CLI
|-- logs/                        # Timestamped execution audit logs
|-- reports/                     # HTML/JSON/Markdown health and incident reports
|-- case-output/                 # Case-centric evidence vaults (SHA-256 verified)
|-- dependencies/                # Air-gapped collections and offline documentation
|-- docs/                        # 20-point playbook guides and module references
|-- templates/                   # Jinja2 report and notification templates
`-- tests/                       # Syntax, mock inventory, and static validation tests
```

---

## 3. Quick Start & Execution

### 3.1 Lab Environment Ping Test
```bash
ansible -i inventories/lab/hosts.yml linux_all -m ansible.builtin.ping
```

### 3.2 Running an Operational Playbook
```bash
ansible-playbook -i inventories/lab/hosts.yml playbooks/linux/linux_system_health_check.yml
```

### 3.3 Interactive Incident Evidence Collection
```bash
./scripts/collect-incident-evidence.sh
```

---

## 4. Safety & Governance Architecture
- **Read-Only Baseline:** 95% of playbooks are purely diagnostic, gathering, and auditing.
- **Change Isolation:** All mutating tasks are restricted to `operations/changes/` and require explicit `-e "confirm_change=true"`.
- **Forensic Evidence:** Incident collections produce tamper-evident bundles with SHA-256 checksum manifests and retention analysis.
