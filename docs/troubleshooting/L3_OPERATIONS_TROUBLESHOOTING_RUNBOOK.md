# L3 Operations Troubleshooting Runbook & Diagnostics Manual

**Target Audience:** L3 Infrastructure Engineers, On-Call Escalation Engineers  
**Framework Version:** 1.0.0-Enterprise  

---

## 1. High CPU Saturation & Process Starvation (Linux / AIX)
When alerts trigger for CPU load > 10x physical core count:
1. Run `./scripts/run-playbook.sh -p playbooks/linux/linux_process_resource_analysis.yml -l <target>`.
2. Inspect `reports/performance/<target>/top_processes.txt`.
3. Check `wchan` states in the output:
   - If processes are in `D` state (uninterruptible sleep) waiting on `io_schedule`, the root cause is storage I/O stall (SAN congestion or slow NFS mount).
   - If processes are in `R` state consuming 100% CPU, check command line arguments for runaway worker loops.
4. For AIX systems, run `./scripts/run-playbook.sh -p playbooks/aix/aix_performance_collection.yml -l <target>` and evaluate `vmstat -v` for client pages stealing computational frames.

---

## 2. Storage Path Failover & Multipath Degraded State
When host reports path degradation or SAN disconnect:
1. Run `./scripts/run-playbook.sh -p playbooks/linux/linux_multipath_san_audit.yml -l <target>`.
2. Review failed paths in `/etc/multipath.conf` device mappings:
   - Check if paths are marked `failed faulty running` or `ghost`.
3. Concurrently execute Brocade SAN audit:
   `./scripts/run-playbook.sh -p playbooks/san-switches/brocade/san_brocade_port_health.yml`.
4. Cross-reference switch port index with host HBA WWPN. Inspect `crc_err` and optical dBm levels.

---

## 3. High Availability Cluster Split-Brain / Quorum Loss
1. Run `./scripts/run-playbook.sh -p playbooks/clustering/veritas/cluster_veritas_vcs_audit.yml` (or `powerha/cluster_ibm_powerha_audit.yml`).
2. Verify heartbeat links (LLT / disk heartbeat):
   - In VCS: Check `gabconfig -a` for port `a` and port `h` membership bitmasks across all cluster nodes.
   - If port `a` is missing a node, verify private interconnect interfaces (`lltstat -nvv`).
3. Under no circumstances force online a resource group (`hagrp -online -force`) until physical network heartbeat connectivity is re-established.
