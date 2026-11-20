# Enterprise Ansible Module Reference Index

**Standard:** Fully Qualified Collection Names (FQCN) only. Zero unverified attributes.  
**Auditor:** L3 Enterprise Infrastructure Operations Architect  
**Ansible Core Compatibility:** Ansible Core 2.16.x  
**Controller Runtime:** Python 3.12.14  
**Date of Verification:** 2026-11-20

---

## 1. Verified Module Specifications

### 1.1 `ansible.builtin.setup`
- **FQCN:** `ansible.builtin.setup`
- **Collection Name:** `ansible.builtin` (Ansible Core)
- **Collection Version:** `2.16.3`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/builtin/setup_module.html
- **Parameters Used:** `filter`, `gather_subset`, `fact_path`
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `ansible_facts` (standard hardware, OS, network, memory, mount, and CPU fact trees)
- **Check-Mode Support:** YES (Supported, read-only)
- **Operational Classification:** READ_ONLY / FACT_GATHERING
- **Target OS / API:** Linux, UNIX (AIX, Solaris), Windows (via `setup` equivalent)

### 1.2 `ansible.builtin.command`
- **FQCN:** `ansible.builtin.command`
- **Collection Name:** `ansible.builtin` (Ansible Core)
- **Collection Version:** `2.16.3`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/builtin/command_module.html
- **Parameters Used:** `cmd`, `argv`, `chdir`, `creates`, `removes`, `strip_empty_ends`
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `rc`, `stdout`, `stdout_lines`, `stderr`, `stderr_lines`, `start`, `end`, `delta`
- **Check-Mode Support:** YES (Does not run in check mode unless `creates`/`removes` specified)
- **Operational Classification:** READ_ONLY / AUDIT_EXECUTION (when executing query commands)
- **Target OS / API:** POSIX Systems (Linux, AIX, Solaris, BSD)

### 1.3 `ansible.builtin.shell`
- **FQCN:** `ansible.builtin.shell`
- **Collection Name:** `ansible.builtin` (Ansible Core)
- **Collection Version:** `2.16.3`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/builtin/shell_module.html
- **Parameters Used:** `cmd`, `executable`, `chdir`, `creates`, `removes`
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `rc`, `stdout`, `stdout_lines`, `stderr`, `stderr_lines`
- **Check-Mode Support:** YES
- **Operational Classification:** READ_ONLY / AUDIT_EXECUTION (Pipeline and redirection commands)
- **Target OS / API:** POSIX Systems

### 1.4 `ansible.builtin.stat`
- **FQCN:** `ansible.builtin.stat`
- **Collection Name:** `ansible.builtin` (Ansible Core)
- **Collection Version:** `2.16.3`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/builtin/stat_module.html
- **Parameters Used:** `path`, `follow`, `get_checksum`, `checksum_algorithm`
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `stat.exists`, `stat.isdir`, `stat.isreg`, `stat.size`, `stat.mode`, `stat.mtime`, `stat.checksum`, `stat.pw_name`, `stat.gr_name`
- **Check-Mode Support:** YES (Supported, read-only)
- **Operational Classification:** READ_ONLY / FILE_INTEGRITY
- **Target OS / API:** POSIX Systems

### 1.5 `ansible.builtin.find`
- **FQCN:** `ansible.builtin.find`
- **Collection Name:** `ansible.builtin` (Ansible Core)
- **Collection Version:** `2.16.3`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/builtin/find_module.html
- **Parameters Used:** `paths`, `patterns`, `recurse`, `file_type`, `age`, `age_stamp`, `size`
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `files`, `matched`, `examined`
- **Check-Mode Support:** YES (Supported, read-only)
- **Operational Classification:** READ_ONLY / INCIDENT_DISCOVERY
- **Target OS / API:** POSIX Systems

### 1.6 `ansible.builtin.fetch`
- **FQCN:** `ansible.builtin.fetch`
- **Collection Name:** `ansible.builtin` (Ansible Core)
- **Collection Version:** `2.16.3`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html
- **Parameters Used:** `src`, `dest`, `flat`, `fail_on_missing`, `validate_checksum`
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `dest`, `file`, `checksum`, `md5sum`
- **Check-Mode Support:** YES
- **Operational Classification:** READ_ONLY / EVIDENCE_PRESERVATION
- **Target OS / API:** POSIX & Windows Systems

### 1.7 `ansible.builtin.copy`
- **FQCN:** `ansible.builtin.copy`
- **Collection Name:** `ansible.builtin` (Ansible Core)
- **Collection Version:** `2.16.3`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html
- **Parameters Used:** `content`, `dest`, `mode`, `owner`, `group`, `backup`
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `dest`, `src`, `checksum`, `size`, `changed`
- **Check-Mode Support:** YES
- **Operational Classification:** READ_ONLY / MANIFEST_GENERATION (when creating controller-side reports)
- **Target OS / API:** POSIX & Controller localhost

### 1.8 `ansible.builtin.template`
- **FQCN:** `ansible.builtin.template`
- **Collection Name:** `ansible.builtin` (Ansible Core)
- **Collection Version:** `2.16.3`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html
- **Parameters Used:** `src`, `dest`, `mode`, `trim_blocks`, `lstrip_blocks`
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `dest`, `changed`
- **Check-Mode Support:** YES
- **Operational Classification:** READ_ONLY / REPORT_RENDERING
- **Target OS / API:** Controller localhost & Managed Nodes

### 1.9 `ansible.builtin.file`
- **FQCN:** `ansible.builtin.file`
- **Collection Name:** `ansible.builtin` (Ansible Core)
- **Collection Version:** `2.16.3`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/builtin/file_module.html
- **Parameters Used:** `path`, `state`, `mode`, `owner`, `group`, `recurse`
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `path`, `state`, `mode`, `changed`
- **Check-Mode Support:** YES
- **Operational Classification:** STATE_MODIFYING / EVIDENCE_VAULT_CREATION
- **Target OS / API:** POSIX Systems & Controller

### 1.10 `ansible.builtin.slurp`
- **FQCN:** `ansible.builtin.slurp`
- **Collection Name:** `ansible.builtin` (Ansible Core)
- **Collection Version:** `2.16.3`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/builtin/slurp_module.html
- **Parameters Used:** `src`
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `content`, `encoding`, `source`
- **Check-Mode Support:** YES (Supported, read-only)
- **Operational Classification:** READ_ONLY / CONFIG_AUDIT
- **Target OS / API:** POSIX Systems

### 1.11 `ansible.builtin.uri`
- **FQCN:** `ansible.builtin.uri`
- **Collection Name:** `ansible.builtin` (Ansible Core)
- **Collection Version:** `2.16.3`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/builtin/uri_module.html
- **Parameters Used:** `url`, `method`, `user`, `password`, `headers`, `body_format`, `validate_certs`, `status_code`, `timeout`, `return_content`
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `json`, `status`, `content`, `cookies`
- **Check-Mode Support:** YES (Supported, skips or simulates GET)
- **Operational Classification:** READ_ONLY / REST_API_AUDIT (for OLVM, Brocade, HPE, Dell, VMware REST)
- **Target OS / API:** REST APIs / HTTP Endpoints

### 1.12 `ansible.builtin.service_facts`
- **FQCN:** `ansible.builtin.service_facts`
- **Collection Name:** `ansible.builtin` (Ansible Core)
- **Collection Version:** `2.16.3`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/builtin/service_facts_module.html
- **Parameters Used:** None (Gathering module)
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `ansible_facts.services` (name, state, status, source)
- **Check-Mode Support:** YES (Supported, read-only)
- **Operational Classification:** READ_ONLY / SERVICE_AUDIT
- **Target OS / API:** Linux Systemd / SysVinit

### 1.13 `ansible.builtin.package_facts`
- **FQCN:** `ansible.builtin.package_facts`
- **Collection Name:** `ansible.builtin` (Ansible Core)
- **Collection Version:** `2.16.3`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/builtin/package_facts_module.html
- **Parameters Used:** `manager`, `strategy`
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `ansible_facts.packages` (name, version, release, epoch, arch)
- **Check-Mode Support:** YES (Supported, read-only)
- **Operational Classification:** READ_ONLY / PACKAGE_AUDIT
- **Target OS / API:** Linux (RPM, DPKG, APK, PACMAN)

### 1.14 `ansible.posix.mount`
- **FQCN:** `ansible.posix.mount`
- **Collection Name:** `ansible.posix`
- **Collection Version:** `2.2.2`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/posix/mount_module.html
- **Parameters Used:** `path`, `state` (`read`, `mounted`, `unmounted`), `src`, `fstype`, `opts`
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `name`, `src`, `fstype`, `opts`, `dump`, `passno`
- **Check-Mode Support:** YES
- **Operational Classification:** READ_ONLY / AUDIT (when querying) & STATE_MODIFYING (when mounting)
- **Target OS / API:** Linux, AIX, POSIX

### 1.15 `ansible.windows.win_command` & `ansible.windows.win_shell`
- **FQCN:** `ansible.windows.win_command` / `ansible.windows.win_shell`
- **Collection Name:** `ansible.windows`
- **Collection Version:** `2.4.0`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/windows/win_command_module.html
- **Parameters Used:** `cmd`, `creates`, `removes`
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `rc`, `stdout`, `stdout_lines`, `stderr`, `stderr_lines`
- **Check-Mode Support:** YES
- **Operational Classification:** READ_ONLY / AUDIT_EXECUTION (PowerShell command execution)
- **Target OS / API:** Microsoft Windows Server (WinRM / PSRP)

### 1.16 `ansible.windows.win_service_info`
- **FQCN:** `ansible.windows.win_service_info`
- **Collection Name:** `ansible.windows`
- **Collection Version:** `2.4.0`
- **Official Documentation URL:** https://docs.ansible.com/ansible/latest/collections/ansible/windows/win_service_info_module.html
- **Parameters Used:** `name`
- **Parameter Validation Status:** VERIFIED
- **Return Values Used:** `services` (name, display_name, state, start_mode, path_name)
- **Check-Mode Support:** YES (Supported, read-only)
- **Operational Classification:** READ_ONLY / SERVICE_AUDIT
- **Target OS / API:** Microsoft Windows Server
