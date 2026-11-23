# Oncall Checks & Triage Runbooks

This directory contains standardized on-call operational runbooks and manual diagnostics procedures for enterprise infrastructure triage:

- **[Oncall_S1_S2_Runbook.md](Oncall_S1_S2_Runbook.md)**: Comprehensive high-severity (S1 / S2) incident triage, layer-by-layer cross-platform diagnosis (RHEL, Oracle Linux, AIX, VIOS, OLVM, SAN, Storage, Network, Firewalls, Blade enclosures, IBM Power frames), evidence collection, and incident response guidelines.
- **[Performance_and_Disk_Checks.md](Performance_and_Disk_Checks.md)**: Deep-dive performance diagnostics, sysstat/sar metrics, CPU/memory saturation, filesystem & inode exhaustion, network socket analysis, and disk troubleshooting.

---

> [!NOTE]
> **Automation Roadmap:**
> The manual triage workflows, queries, and health-check procedures documented in this directory are currently staged as operational reference runbooks. We will automate these checks into our enterprise Ansible playbooks and automated incident evidence collection framework in some time as well.
