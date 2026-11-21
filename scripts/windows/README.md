# Windows VMware Workstation Lab Orchestration Scripts

This directory contains one-click PowerShell and Batch orchestrators to manage the enterprise lab on Windows 11 / VMware Workstation.

## Files
- `Start-Lab.ps1`: Core orchestrator. Boots VMs in proper dependency order, waits for SSH (port 22) availability, verifies system services, and automatically restarts any failed daemons.
- `Start-Lab.bat`: Double-clickable Batch launcher for `Start-Lab.ps1 -Mode Start`.
- `Stop-Lab.bat`: Clean ACPI soft shutdown for all 4 lab VMs before gaming or sleep to free 100% of RAM and CPU.
- `Lab-Status.bat`: Instant status dashboard without modifying VM states.

## Node Topology & Monitored Daemons
| Host | IP | Role | Monitored & Self-Healed Services |
| :--- | :--- | :--- | :--- |
| `ansible-nfs` | `192.168.242.132` | Controller & Storage | `nfs-server`, `rpcbind`, `sshd`, NFS exports |
| `olvm-engine` | `192.168.242.133` | OLVM Management Engine | `postgresql`, `ovirt-engine`, `httpd`, `sshd` |
| `kvm-host-1` | `192.168.242.134` | Enterprise KVM Node 1 | `libvirtd`, `supervdsmd`, `vdsmd`, `sanlock`, `sshd` |
| `kvm-host-2` | `192.168.242.135` | Enterprise KVM Node 2 | `libvirtd`, `supervdsmd`, `vdsmd`, `sanlock`, `sshd` |

## Quick Execution
Double click `Start-Lab.bat` on the Desktop or run in PowerShell:
```powershell
.\Start-Lab.ps1 -Mode Start
```
To cleanly shut down before gaming:
```powershell
.\Start-Lab.ps1 -Mode Stop
```
