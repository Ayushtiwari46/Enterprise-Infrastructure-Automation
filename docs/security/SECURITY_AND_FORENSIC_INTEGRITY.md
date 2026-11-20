# Security, Access Controls & Forensic Integrity Architecture

**Target Audience:** Enterprise Security Teams, Infrastructure Auditors, CISO Office  
**Framework Version:** 1.0.0-Enterprise  

---

## 1. Non-Destructive Forensic Guarantee
All incident collection engines (`incident-collection/*/*.yml`) operate under strict forensic safeguards:
- **Zero In-Place Mutation:** Staging occurs exclusively in temporary, permission-restricted directories (`/tmp/case_staging_<case_id>`), mode `0700`.
- **Target Clean-Up:** Upon archive transfer, all temporary staging directories on managed nodes are purged (`state: absent`).
- **Cryptographic Hashing:** Every acquired diagnostic artifact is processed with SHA-256 immediately upon controller ingestion.

---

## 2. Vault Tamper-Evidence & Chain of Custody
1. A manifest file `manifests/manifest_<hostname>.sha256` is generated directly on the controller.
2. The manifest contains the exact cryptographic signature of every log file, journal slice, process snapshot, and system configuration file.
3. The manifest provides mathematical proof to auditors, compliance officers, and incident responders that the evidence has not been tampered with or modified post-collection.

---

## 3. Least Privilege & Credential Management
- Dedicated SSH automation key pairs (`ed25519` or `rsa-4096`) are utilized.
- Read-only sudo privileges for diagnostic commands (`/sbin/dmidecode`, `/sbin/multipath`, `/bin/dmesg`, `/bin/journalctl`).
- Passwords and secrets are centralized in Ansible Vault or external secret management engines (e.g. HashiCorp Vault), referenced via variable files.
