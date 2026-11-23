# Oncall S1 / S2 Health-Check Runbook

Untagged commands only display information. `[LOAD]` can be heavy or hang. `[PROBE]` sends test traffic. `[EVIDENCE]` writes a support file. `[CAUTION]` changes the system. Slow host or a full disk: [Performance_and_Disk_Checks.md](Performance_and_Disk_Checks.md).

## Map

| What is in front of you | Open |
| --- | --- |
| Just paged | [First 10 minutes](#first-10) · [Symptom](#matrix) · [Evidence](#evidence) · [Status text](#status) · [Close the case](#closure) |
| RHEL / Oracle Linux | [Crash](#rhel-uptime) · [CPU](#rhel-cpu) · [Logs](#rhel-logs) · [Disk](#rhel-fs) · [Multipath](#rhel-san) · [Network](#rhel-net) · [Pacemaker](#rhel-pcs) |
| AIX | [errpt](#aix-errpt) · [CPU](#aix-cpu) · [VG](#aix-disk) · [MPIO](#aix-san) · [Network](#aix-net) · [PowerHA](#powerha) · [snap](#aix-evidence) |
| VIOS | [padmin checks](#vios) |
| OLVM | [Portal](#olvm-gui) · [Engine](#olvm-engine) · [Host](#olvm-host) |
| SAN switch | [Brocade](#brocade) · [MDS](#mds) |
| Storage array | [Any array](#storage-any) · [SVC](#svc) · [NetApp](#netapp) · [3PAR](#3par) · [Pure](#pure) · [Dell / Hitachi](#dell) |
| Network switch | [IOS / NX-OS](#switch) |
| Firewall | [Palo Alto](#pan) · [FortiGate](#forti) · [Check Point](#checkpoint) · [ASA](#asa) |
| HPE blade or DL | [iLO](#ilo) · [OA](#oa) · [Virtual Connect](#vc) · [OneView](#oneview) |
| IBM Power frame | [HMC](#hmc-gui) · [HMC CLI](#hmc-cli) · [ASMI](#asmi) |

| Symptom | Start |
| --- | --- |
| One server, no ping | [Console](#first-10), then [iLO](#ilo) or [HMC](#hmc-gui), then [switch port](#switch) |
| Many servers, one VLAN | [Switch](#switch) or [firewall](#fw) |
| Whole blade enclosure | [OA](#oa) and [Virtual Connect](#vc) |
| All LPARs on one frame | [HMC](#hmc-gui) and [VIOS](#vios) |
| Slow, high wait, D-state | [Performance](Performance_and_Disk_Checks.md) and [array](#storage-any) |
| Disk 100% or "no space" | [Find it](Performance_and_Disk_Checks.md#large-files) · [Delete it](Performance_and_Disk_Checks.md#delete) |
| Ping works, app port does not | [Firewall](#fw) and [listeners](Performance_and_Disk_Checks.md#linux-netstat) |
| Logins fail for many users | [DNS, NTP, AD](#shared) |

Click a link in the preview or on GitHub. In the editor, Ctrl+Shift+O jumps by heading.

## How to read a command

- Untagged commands are **query-only**: they display information and do not change configuration, state, counters or logs.
  They still create normal login/audit entries, like any session does.
- `[LOAD]` = query-only, but can be slow, heavy, interactive (exit with `q` / Ctrl+C) or can **hang** on a sick
  storage/NFS path. Run in a separate SSH session, prefer `timeout`, avoid on an already overloaded box.
- `[PROBE]` = sends test traffic (ping, traceroute, port test, FC ping, DNS query). Harmless in normal use,
  but visible to IDS / remote logs. Keep counts small.
- `[EVIDENCE]` = generates a support bundle / file on the device or host (needs free space, adds CPU/IO),
  and in some cases **sends data to the vendor**. Run when the IM / vendor asks for it.
- `[CAUTION]` = changes state (config, sessions, console take-over, capture objects, traces, failover, restart,
  clearing). Get approval from the incident manager before running it.
- GUI tables: *viewing* pages is safe; clicking action buttons (Fix / Run, Power, Mount, Generate, Reset) is not.
- `# remark` after a command = what to look for.
- `<...>` = replace with your value.
- **GUI** sections list *where to click* and *what a bad state looks like*.

---

<a id="first-10"></a>
## 0. First 10 Minutes (any S1 / S2)

| # | Action | Why |
|---|--------|-----|
| 1 | Note **case no., start time (with TZ), reporter, impacted service/CI, business impact** | Timeline is the first thing everyone asks for |
| 2 | Define **blast radius**: one server / one app / one rack / one enclosure / one site / everything behind one FW or switch | Tells you which layer to start at (see Section 14) |
| 3 | Ask **"What changed?"** - change records last 24-72h, patching, firmware, FW rule push, zoning change, storage expansion, DNS / cert / password expiry | Most S1s are change-related |
| 4 | Check **monitoring** (alerts, graphs) for the *first* alert, not the loudest one | First alert usually = root cause layer |
| 5 | Can you **reach it**? ping, SSH, console (iLO / HMC vterm / OLVM console) `[CAUTION]` for console: may take over someone else's session | Separates "host down" vs "network down" vs "app down" |
| 6 | **Capture evidence before fixing** (logs, screenshots of console / PSOD / panic, `errpt`, `dmesg`) | Reboot destroys evidence; RCA will need it |
| 7 | Open **vendor case early** if hardware/firmware suspected (have serial no. / machine type-model ready) | Vendor SLA clock starts when you open it |
| 8 | Send first **status update** within agreed SLA (template in Section 16) | |

**Golden don'ts during S1:**

- Don't reboot / failover / restart services before capturing logs, unless the IM approves it to restore service.
- Don't clear counters (`portstatsclear`, `clear counters`, `errclear`) before recording them.
- Don't change zoning, LUN masking, routing, or FW rules without a second pair of eyes.
- Don't run `fsck` on mounted filesystems; don't `varyoffvg` / `vgchange -an` shared VGs on a live cluster node.

---

<a id="rhel"></a>
## 1. RHEL / Oracle Linux

<a id="rhel-uptime"></a>
### 1.1 Uptime, reboot and crash history

```bash
uptime                                   # load avg vs CPU count (nproc); recent reboot?
who -b                                   # last boot time
last -x | head -20                       # reboot/shutdown/runlevel history - unexpected reboot?
journalctl --list-boots | tail -5        # boot IDs (needs persistent journal)
journalctl -b -1 -n 100 --no-pager       # last 100 lines of PREVIOUS boot - why did it go down?
ls -lrt /var/crash/                      # kdump vmcore present = kernel panic
kdumpctl status                          # is kdump operational (for next time)?
cat /proc/cmdline                        # crashkernel= set?
```

<a id="rhel-cpu"></a>
### 1.2 CPU / Memory / Load

```bash
nproc; lscpu | egrep 'Model name|^CPU\(s\)|NUMA'
top -b -n 1 | head -30                   # top consumers, %wa (IO wait), %st (steal on VM)
vmstat 1 5                               # r > CPUs = CPU saturation; b > 0 = blocked on IO; si/so > 0 = swapping
mpstat -P ALL 1 3                        # single CPU pinned at 100%?
sar -q ; sar -u ; sar -r                 # historical (sysstat) - when did it start?
sar -f /var/log/sa/sa<DD> -u             # specific day
free -h                                  # 'available' is the real free; swap used?
ps aux --sort=-%mem | head -15           # memory hogs
ps aux --sort=-%cpu | head -15           # CPU hogs
ps -eo pid,stat,wchan:30,cmd | awk '$2 ~ /D/'   # D-state procs = stuck on IO (storage/NFS)
ps -eo stat | grep -c Z                  # zombie count
grep -iE 'out of memory|killed process|oom' /var/log/messages | tail   # OOM killer
cat /proc/pressure/{cpu,memory,io} 2>/dev/null  # PSI (RHEL 8+) - which resource is starved
```

<a id="rhel-logs"></a>
### 1.3 Kernel / system logs

```bash
dmesg -T | tail -100                     # HW errors, SCSI resets, link down, call traces
dmesg -T | egrep -i 'error|fail|warn|reset|abort|timeout|offline|hung|call trace|mce|edac' | tail -50
journalctl -p err -b --no-pager | tail -50       # errors this boot
journalctl --since "1 hour ago" --no-pager | tail -200
journalctl -u <service> --since "-2h" --no-pager # specific service
grep -i "blocked for more than" /var/log/messages # hung_task = IO stall
grep -i "soft lockup\|hard lockup\|rcu_sched" /var/log/messages
tail -200 /var/log/messages
```

<a id="rhel-fs"></a>
### 1.4 Filesystem / disk / LVM

```bash
df -hT                                   # 100% FS? (/, /var, /tmp, /var/log, app FS)
df -i                                    # inode exhaustion (df shows space but writes fail)
awk '$4 ~ /(^|,)ro(,|$)/' /proc/mounts   # FS remounted read-only = underlying IO error
findmnt -D                               # mount tree / missing mounts vs fstab
timeout 60 lsof -nP +L1 2>/dev/null | head   # [LOAD] deleted files still holding space (can block on hung NFS)
timeout 120 du -xhd1 /var 2>/dev/null | sort -h   # [LOAD] who filled it (metadata walk; heavy on huge dirs)
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,STATE
pvs; vgs; lvs -a -o +devices             # missing PV ("unknown device"), partial VG
iostat -xz 1 3                           # %util ~100, high await/r_await/w_await = slow storage (3 samples, light)
cat /proc/mdstat                         # SW RAID degraded?
```

<a id="rhel-san"></a>
### 1.5 SAN / multipath (FC)

```bash
# [LOAD] multipath / lsscsi can hang while paths are failing - run in a separate session, keep 'timeout'
timeout 60 multipath -ll                 # every LUN should have expected path count, all 'active ready running'
timeout 60 multipath -ll | grep -iE 'failed|faulty|offline|shaky'   # bad paths
multipathd show paths                    # path states summary
multipathd show maps status
lsscsi -t 2>/dev/null                    # transport / target view
cat /sys/class/fc_host/host*/port_state  # Online / Linkdown
cat /sys/class/fc_host/host*/port_name   # HBA WWPNs (give to SAN team)
cat /sys/class/fc_host/host*/speed
grep . /sys/class/fc_host/host*/statistics/{link_failure_count,loss_of_sync_count,loss_of_signal_count,invalid_crc_count,error_frames} 2>/dev/null
                                         # increasing counters = bad cable/SFP/switch port
dmesg -T | egrep -i 'qla2xxx|lpfc|rport|fc_remote|abort|reset' | tail -30
```

<a id="rhel-net"></a>
### 1.6 Network

```bash
ip -br a                                 # interfaces UP / IPs present
ip -br link                              # LOWER_UP missing = no carrier
ip r; ip -6 r                            # default gateway present?
ip -s link show <ifname>                 # RX/TX errors, drops, overruns
ethtool <ifname>                         # Link detected, speed/duplex (half duplex = problem)
ethtool -S <ifname> | egrep -i 'err|drop|crc|miss' | grep -v ': 0'
cat /proc/net/bonding/bond0              # active slave, MII status, link failure count per slave
nmcli -t dev status; nmcli con show --active
teamdctl <team0> state 2>/dev/null       # if teaming instead of bonding
ping -c 3 <gateway>; arping -c 3 -I <ifname> <gateway>   # [PROBE]
ip neigh show | grep -i -E 'FAILED|INCOMPLETE'    # ARP failures
traceroute -n <dest>                     # [PROBE] (or: tracepath <dest>)
ss -tulpn                                # app listening on expected port?
ss -s                                    # socket counts; huge TIME_WAIT / CLOSE_WAIT?
ss -tan state close-wait | wc -l         # app not closing connections
nc -zv -w 3 <host> <port>                # [PROBE] port open? (or: timeout 3 bash -c '</dev/tcp/<host>/<port>' && echo open)
cat /etc/resolv.conf; dig <name> +short; dig -x <ip> +short   # [PROBE] DNS
getent hosts <name>                      # what the OS actually resolves (incl. /etc/hosts)
```

<a id="rhel-auth"></a>
### 1.7 Time, services, security, auth

```bash
timedatectl                              # NTP synchronized: yes?
chronyc tracking; chronyc sources -v     # offset, reachability (Kerberos/AD/cluster break on skew)
systemctl --failed                       # failed units
systemctl status <svc> -l --no-pager
systemctl list-jobs                      # stuck start/stop jobs
getenforce; ausearch -m avc -ts recent 2>/dev/null | tail   # SELinux denials after change
firewall-cmd --state; firewall-cmd --list-all               # local firewall blocking?
systemctl status sssd; id <user>; journalctl -u sssd --since -1h   # AD/LDAP login issues
chage -l <user>                          # password/account expired?
faillock --user <user>                   # locked account (RHEL 8+). [CAUTION] '--reset' unlocks - not part of the check
timeout 10 openssl s_client -connect <host>:443 </dev/null 2>/dev/null | openssl x509 -noout -dates   # [PROBE] cert expiry
crontab -l; ls /etc/cron.d               # something scheduled at incident time?
```

<a id="rhel-nfs"></a>
### 1.8 NFS / CIFS clients

```bash
mount -t nfs,nfs4                        # NFS mounts present
timeout 5 stat <nfs_mountpoint> || echo "HUNG/STALE"   # [LOAD] use a spare session: a hard-mounted hung NFS can leave even this stuck in D-state
nfsstat -c                               # retrans high = network/server issue
timeout 10 showmount -e <nfs_server>     # [PROBE]
grep -i 'not responding\|stale' /var/log/messages | tail
```

<a id="rhel-hw"></a>
### 1.9 Hardware view from OS

```bash
dmidecode -t system | egrep 'Manufacturer|Product|Serial'   # serial for vendor case
ipmitool sel elist | tail -20 2>/dev/null                   # BMC/iLO event log from OS
ras-mc-ctl --errors 2>/dev/null; ras-mc-ctl --summary       # memory/CPU corrected errors (rasdaemon)
grep -i 'mce\|machine check\|edac' /var/log/messages | tail
ssacli ctrl all show config 2>/dev/null                     # HPE Smart Array: failed/degraded drive
ssacli ctrl all show status 2>/dev/null                     # controller, cache, battery
sensors 2>/dev/null                                         # temperatures
```

<a id="rhel-pcs"></a>
### 1.10 Pacemaker cluster (RHEL HA)

```bash
pcs status --full                        # node online/offline/standby, failed actions, resource locations
crm_mon -1 -Arf                          # one-shot with fail counts
pcs stonith status; pcs stonith history show   # was a node fenced? ([CAUTION] 'history cleanup' deletes it)
corosync-cfgtool -s                      # ring/link status
corosync-quorumtool -s                   # quorate? votes
pcs constraint --full                    # leftover location constraints (from 'pcs resource move')
journalctl -u pacemaker -u corosync --since "-2h" --no-pager | tail -100
pcs resource failcount show
# [CAUTION] pcs resource cleanup <res>   - retries failed resource, may move it
# [CAUTION] pcs resource move / ban      - leaves a constraint behind; remove with 'pcs resource clear'
```

<a id="rhel-evidence"></a>
### 1.11 Evidence

```bash
df -h /var/tmp                           # check free space first
sos report --batch --tmp-dir /var/tmp    # [EVIDENCE] (RHEL 8+, 'sosreport' on 7). Needs ~1-2 GB free, CPU/IO for minutes, contains sensitive data
```

---

<a id="aix"></a>
## 2. AIX

<a id="aix-uptime"></a>
### 2.1 Uptime, level, crash

```bash
uptime; who -b
oslevel -s                               # TL/SP
prtconf | head -30                       # model, serial, firmware, memory, CPU
sysdumpdev -l                            # dump device config
sysdumpdev -L                            # LAST dump info (date, status) = was there a crash?
alog -o -t boot | tail -50               # boot log
alog -o -t console | tail -50            # console log
```

<a id="aix-errpt"></a>
### 2.2 Error log (most important AIX check)

```bash
errpt | head -40                         # newest first; look at IDENTIFIER / TYPE (P=perm, T=temp) / CLASS (H=hw, S=sw)
errpt -d H -T PERM                       # permanent hardware errors only
errpt -s <mmddhhmmyy>                    # since incident start
errpt -a -j <IDENTIFIER> | more          # full detail incl. location code & FRU
errpt -a -N <resource> | more            # by resource, e.g. hdisk5, fcs0, ent0
# Typical bad ones: SC_DISK_ERR*, FCP_ERR*, FSCSI_ERR*, PATH_*, DISK_ERR*, LVM_SA_STALEPP, J2_FS_FULL,
#                   ENT_LINK_DOWN / ECH_*, CORE_DUMP, DUMP_STATS, REBOOT_ID, SYSPLANAR, SCAN_ERROR_CHRP
# [CAUTION] errclear - never during an incident (evidence)
```

<a id="aix-cpu"></a>
### 2.3 CPU / Memory / Paging

```bash
lparstat -i | egrep 'Type|Mode|Entitled|Online Virtual|Online Memory|Shared Pool'
lparstat 1 5                             # physc vs entitlement; %entc >100 = using uncapped; app pool exhausted?
vmstat 1 5                               # r (run queue), b (blocked), pi/po (paging) - po > 0 sustained = memory short
vmstat -v | egrep 'blocked|pending'      # pbuf/fsbuf blocked I/Os = LVM/JFS2 tuning or slow disk
svmon -G                                 # memory in use / pinned / virtual
lsps -a                                  # paging space %used (> 70-80% = danger; fork failures)
ps aux | sort -rn -k 3 | head -15        # top CPU
ps aux | sort -rn -k 4 | head -15        # top MEM
ps -ef | grep -c defunct                 # zombies
topas                                    # [LOAD] interactive, exit with q   (or: nmon, exit with q)
```

<a id="aix-disk"></a>
### 2.4 Disk / VG / FS

```bash
df -g                                    # %Used and %Iused (inodes) - /, /var, /tmp, /opt, /home, app FS
lsvg -o                                  # online VGs - expected ones varied on?
lsvg <vg>                                # STALE PVs / STALE PPs > 0 = mirror broken
lsvg -l <vg>                             # LV STATE: 'open/stale' bad; 'closed/syncd' = FS not mounted
lsvg -p <vg>                             # PV STATE: 'missing' / 'removed' bad
lspv                                     # all PVs with VG; 'None' disks
lsdev -Cc disk | grep -v Available       # Defined disks = lost
mount                                    # compare with /etc/filesystems (mount=true)
iostat -D 1 3                            # per-disk avg serv / sqfull - slow LUN?
iostat -aT 1 3                           # per adapter
fileplace -v <file>                      # deep dive: physical placement of one file
# [CAUTION] filemon - starts the AIX trace facility (CPU overhead) until 'trcstop'; only with approval, e.g.
#           filemon -o /tmp/fmon.out -O all ; sleep 30 ; trcstop
```

<a id="aix-san"></a>
### 2.5 SAN / MPIO

```bash
lsdev -Cc adapter | grep fcs             # all fcs Available?
lspath | grep -v Enabled                 # Failed / Missing / Defined paths
lspath -l hdiskX -F "status parent connection"
lsmpio -q                                # (AIX 7.1 TL3+) LUN view, size, vendor
lsmpio -ar                               # paths per remote port / adapter
lsmpio -Sd                               # path statistics / errors
pcmpath query adapter; pcmpath query device   # only if legacy SDDPCM installed
fcstat fcs0 | egrep -i 'Port Speed|Attention|Link Failure|Loss of Sync|Loss of Signal|Invalid CRC|No DMA|No Adapter Elements|No Command'
lscfg -vpl fcs0 | grep 'Network Address' # WWPN (for SAN team)
lsattr -El fscsi0 | egrep 'dyntrk|fc_err_recov'   # should be yes / fast_fail for most SAN setups
lsattr -El hdiskX | egrep 'reserve_policy|algorithm|queue_depth|hcheck'
```

<a id="aix-net"></a>
### 2.6 Network

```bash
ifconfig -a                              # IPs present, interface UP
netstat -in                              # Ierrs / Oerrs / Coll
netstat -rn                              # default route
entstat -d ent0 | egrep -i 'Link Status|Media Speed|errors|CRC|No Resource|Hypervisor'
                                         # 'No Resource Errors' rising = buffer tuning; Link Status Down = physical
lsattr -El ent<X>                        # EtherChannel: mode, adapter_names, backup_adapter
entstat -d ent<etherchannel> | egrep -i 'active channel|backup|link status'
netstat -an | grep LISTEN | grep <port>
netstat -an | grep -c CLOSE_WAIT
ping -c 3 <gateway>; traceroute <dest>   # [PROBE]
cat /etc/resolv.conf; nslookup <name>; grep hosts /etc/netsvc.conf  # [PROBE] nslookup; netsvc.conf = resolution order
```

<a id="aix-svc"></a>
### 2.7 Services, time, users

```bash
lssrc -a | grep -v active                # inoperative subsystems (expected vs unexpected)
lssrc -g tcpip ; lssrc -g nfs
lssrc -s xntpd ; ntpq -p                 # time sync (chrony on AIX 7.3: lssrc -s chronyd)
lsuser -a account_locked unsuccessful_login_count <user>
pwdadm -q <user>                         # password flags
cat /etc/security/lastlog | grep -p <user>
crontab -l                               # jobs at incident time
lsmcode -A                               # firmware levels of system/adapters
```

<a id="aix-gpfs"></a>
### 2.8 GPFS / Spectrum Scale (if used)

```bash
/usr/lpp/mmfs/bin/mmgetstate -a          # all nodes 'active'?
/usr/lpp/mmfs/bin/mmhealth node show     # component health
/usr/lpp/mmfs/bin/mmhealth cluster show
/usr/lpp/mmfs/bin/mmlsdisk <fs> -e       # disks not up/ready
/usr/lpp/mmfs/bin/mmlsmount all -L       # where is FS mounted
tail -200 /var/adm/ras/mmfs.log.latest   # expels, quorum loss, disk down
```

<a id="aix-evidence"></a>
### 2.9 Evidence

```bash
df -g /tmp                               # check free space first
snap -ac                                 # [EVIDENCE] /tmp/ibmsupt/snap.pax.Z - needs free space in /tmp (often 1 GB+), CPU/IO for minutes
# for dumps: snap -ac + sysdumpdev -L output, vmcore from dump device copied to /var/adm/ras
```

**AIX LED / boot codes seen on HMC console (Reference Code column):**

| Code | Meaning (common) |
|------|------------------|
| `0c9` / `0c0` | Dump in progress / dump completed - wait, don't power off during 0c9 |
| `888` | System crash (followed by codes) |
| `0518` | Mount of /usr or /var failed during boot |
| `0551` / `0552` / `0554` / `0556` | rootvg / boot device / ODM / JFS issue during boot |
| `0557` | Root FS could not be mounted |
| `0581` / `0607` | TCP/IP config / NIM-related hang |
| `B2xxxxxx` / `B7xxxxxx` / `B1xxxxxx` | Firmware / partition boot SRC - look up exact SRC in IBM docs |

---

<a id="vios"></a>
## 3. VIOS (login as `padmin`; `oem_setup_env` = root shell)

```bash
ioslevel                                 # VIOS level
errlog | head -30                        # same as errpt (oem_setup_env: errpt)
lsdev -type adapter | grep -v Available  # failed physical/virtual adapters
lsmap -all                               # vSCSI mapping vhost -> backing device; 'Status Available'?
lsmap -all -npiv                         # NPIV: Status LOGGED_IN vs NOT_LOGGED_IN, Flags, FC name, client LPAR
lsnports                                 # NPIV-capable ports; fabric=1 means switch supports NPIV
lsmap -all -net                          # SEA -> physical / virtual adapter mapping
entstat -all ent<SEA> | egrep -i 'State|Priority|Active|Link Status|High Availability'
                                         # SEA failover: PRIMARY / BACKUP; both 'PRIMARY' = loop risk; both BACKUP = outage
lsdev -dev ent<SEA> -attr                # ha_mode, ctl_chan
lspath | grep -v Enabled                 # (oem_setup_env) backend SAN paths
fcstat fcsX                              # (oem_setup_env) link errors
viosbr -view -list                       # config backups exist?
```

Remark: if **one VIOS** is down, clients should survive on the other (dual-VIOS). Check each client LPAR with
`lspath` (AIX) / `multipath -ll` (Linux on Power) that it lost only half its paths, not all.

---

<a id="powerha"></a>
## 4. PowerHA SystemMirror (AIX cluster)

```bash
/usr/es/sbin/cluster/utilities/clRGinfo -v        # RG state per node: ONLINE / OFFLINE / ERROR / UNMANAGED
lssrc -ls clstrmgrES | grep -i state              # ST_STABLE good; ST_RP_FAILED / ST_UNSTABLE bad
/usr/es/sbin/cluster/clstat -o                    # one-shot cluster status (needs clinfoES)
clmgr query cluster                               # cluster summary
clmgr view report status
lscluster -m                                      # CAA node membership
lscluster -d                                      # repository disk state
tail -300 /var/hacmp/log/hacmp.out                # event processing - EVENT FAILED lines
grep -i "EVENT FAILED\|config_too_long" /var/hacmp/log/hacmp.out | tail
tail -100 /var/hacmp/adm/cluster.log
# [CAUTION] clmgr move rg / clmgr online rg / clmgr offline node - only with approval
```

---

<a id="olvm"></a>
## 5. OLVM (Oracle Linux Virtualization Manager / oVirt)

<a id="olvm-gui"></a>
### 5.1 GUI - Administration Portal (`https://<engine-fqdn>/ovirt-engine`)

| Where                                                     | What to check                               | Bad state                                                                                                                 |
| --------------------------------------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Dashboard**                                             | Overall hosts / storage / VMs, alerts       | Red counters                                                                                                              |
| **Events** (bottom pane / Events tab)                     | Filter by Error / Warning, sort by time     | "Storage domain ... experienced a high latency", "Host ... is non responsive", "VM ... paused due to storage I/O problem" |
| **Compute > Hosts**                                       | Status, SPM role, Load                      | `NonResponsive`, `NonOperational`, `Connecting`, `InstallFailed`; SPM `Contending` for long                               |
| **Compute > Hosts > > Network Interfaces**                | Logical networks attached, bond status      | Out-of-sync network (red/orange icon)                                                                                     |
| **Storage > Domains**                                     | Status, free space, master domain           | `Inactive`, `Locked`, `Maintenance`, < 10 % free (VMs pause when thin disks can't extend)                                 |
| **Storage > Domains > > Data Center**                     | Attached / Active                           | Not Active                                                                                                                |
| **Compute > Virtual Machines**                            | Status                                      | `Paused` (usually storage I/O or no space), `Not Responding`, `Unknown`                                                   |
| **Compute > Data Centers**                                | Status                                      | `Non Responsive` / `Problematic` (SPM issue)                                                                              |
| **Compute > Clusters**                                    | CPU type, scheduling policy, fencing policy |                                                                                                                           |
| **Hosted Engine** (if self-hosted)                        | HA score on hosts (crown icon)              | Score 0 / engine VM not up                                                                                                |
| **Administration > Certificates** (OLVM 4.4+ engine cert) | Expiry                                      | Expired engine/host certs = hosts NonResponsive                                                                           |

<a id="olvm-engine"></a>
### 5.2 Engine VM / server

```bash
systemctl status ovirt-engine ovirt-engine-dwhd ovirt-imageio postgresql   # all active?
tail -300 /var/log/ovirt-engine/engine.log | egrep -i 'ERROR|WARN|exception'
tail -100 /var/log/ovirt-engine/server.log
df -h /var /var/log /var/lib/pgsql      # engine DB / logs full = GUI dies
hosted-engine --vm-status                # (from any HE host) engine VM state, HA score, maintenance mode
```

<a id="olvm-host"></a>
### 5.3 KVM hosts

```bash
systemctl status vdsmd supervdsmd libvirtd sanlock momd   # vdsm down = host NonResponsive
tail -300 /var/log/vdsm/vdsm.log | egrep -i 'ERROR|WARN|Traceback|timeout'
tail -100 /var/log/vdsm/supervdsm.log
sanlock client status                    # lockspaces held for each storage domain
sanlock client log_dump | tail -50       # renewal failures = storage latency
vdsm-client Host getStats | egrep -i 'cpuLoad|memAvailable|storageDomains' -A3
virsh -r list --all                      # read-only libvirt view of VMs on this host
multipath -ll                            # FC/iSCSI storage domains - paths per LUN
iscsiadm -m session -P 1 2>/dev/null     # iSCSI sessions
ip -br a; cat /proc/net/bonding/bond*    # ovirtmgmt bridge & bonds
journalctl -u vdsmd --since "-2h" --no-pager | tail -100
# + all RHEL checks from Section 1
```

**Common OLVM root causes:** storage latency / lost paths -> sanlock lease renewal fails -> host fenced or VMs paused;
engine certificate expiry; ovirtmgmt network down; storage domain full; SPM host lost.

Evidence `[EVIDENCE]`: `ovirt-log-collector` on engine (connects to and collects from engine + hosts; check engine free space, limit scope with `--hosts=` if needed), `sos report` on hosts.

---

<a id="san"></a>
## 6. SAN Fabric Switches

<a id="brocade"></a>
### 6.1 Brocade (FOS) - SSH as admin/user

```bash
version ; uptime                         # FOS version, last reboot
switchshow                               # switchState Online; each port: Online F-Port/E-Port, No_Light, No_Sync, Disabled, Laser_Flt
switchstatusshow                         # overall HEALTHY / MARGINAL / DOWN with reason
fabricshow                               # all switches in fabric present (missing one = ISL / switch down)
islshow ; trunkshow                      # ISLs up, trunk members, bandwidth
porterrshow                              # columns: crc_err, enc_out, disc_c3, link_fail, loss_sync, loss_sig - rising = bad SFP/cable/HBA
porterrshow <port>                       # re-run after 1-2 min and compare (rate matters, not absolute)
portshow <port>                          # portState, portPhys, WWNs logged in, portFlags
portstatsshow <port>                     # detailed counters (er_bad_os, er_crc, tim_txcrd_z = credit starvation / slow drain)
sfpshow <port> -f                        # Rx/Tx power, temp, current - Rx power low (e.g. < -10 dBm on SW SFP) = bad optic/cable
sfpshow -all                             # all optics
nsshow                                   # local name server - is host / array WWPN logged in?
nscamshow                                # remote switch NS entries
cfgactvshow                              # effective zoning
zoneshow <zone_or_alias>                 # check host-to-array zone exists
alishow <alias>
errdump | tail -100                      # error log (errshow = interactive)
fabriclog -s | tail -50                  # fabric events (rebuilds, segmentation)
mapsdb --show                            # MAPS dashboard: rule violations last 24h
mapsdb --show all
fanshow ; psshow ; tempshow ; chassisshow   # hardware health
historyshow                              # FRU insert/remove history
fcping <src_wwn> <dst_wwn>               # [PROBE] FC ELS echo connectivity test
# [CAUTION] portdisable/portenable, statsclear, portstatsclear, cfgenable, cfgsave
# [EVIDENCE] supportsave (collects on switch, uploads to FTP/SCP server) - collect from BOTH fabrics if dual-fabric
```

<a id="mds"></a>
### 6.2 Cisco MDS (NX-OS)

```bash
show version ; show system uptime ; show system reset-reason
show module ; show environment           # modules ok, fans, PSU, temp
show interface brief                     # fcX/Y status: up / down / notConnected / errDisabled / sfpAbsent
show interface fc<X/Y>                   # errors, discards, link failures, credit loss
show interface fc<X/Y> transceiver details   # Rx/Tx power alarms
show interface counters | i "fc|CRC|discard|error"
show port-channel summary                # ISL port-channels
show flogi database                      # host/array WWPN logged in on which port / VSAN
show fcns database vsan <N>              # name server
show zoneset active vsan <N> | i <wwpn>  # in active zone?
show zone status vsan <N>                # zone locks / mode
show vsan membership
show logging log | last 100
show processes cpu sort ; show system resources
# [EVIDENCE] show tech-support details > bootflash:tech.txt  (writes to flash - check 'dir bootflash:' space; then copy off)
```

<a id="san-notes"></a>
### 6.3 SAN-specific remarks

- Dual-fabric: compare **Fabric A vs Fabric B**. If only one fabric is affected, hosts should still run on the other - check host path counts.
- **Slow-drain device** symptom: many hosts slow, not down. Look at `tim_txcrd_z` (Brocade) / credit-loss & `TxWait` (MDS) on the F-port of one misbehaving HBA.
- New WWPN not seeing LUN: flogi/ns login -> zoning (active config) -> array host mapping/masking -> host rescan.
- Port flapping: `porterrshow` link_fail / loss_sync + `sfpshow` power + `errdump`.

---

<a id="storage"></a>
## 7. Storage Arrays

<a id="storage-any"></a>
### 7.1 What to check on ANY array (GUI or CLI)

| Area | What to check | Bad state |
|------|---------------|-----------|
| Alerts / event log | Critical / Major since incident start | Controller/node failover, cache disabled, drive failure, path loss |
| Controllers / nodes / canisters | All online, not in service mode | One node offline = degraded + write cache may go write-through (=> big latency) |
| Drives / RAID | Failed, rebuilding, spare count | Rebuild running = degraded performance; 2nd failure risk |
| Cache / battery / BBU / power | Write cache enabled, battery OK | Write-through mode |
| Pools / capacity | Physical pool used %, thin over-commit, snapshot reserve | Pool full => volumes go offline / read-only / host write errors |
| Volumes / LUNs | Online, mapped to correct host | Offline, unmapped |
| Host connectivity | Host initiators logged in on all expected ports | Host with partial or zero paths |
| Front-end ports | Link up, speed, errors | Port down / errors |
| Performance | Latency (ms), IOPS, MB/s, per volume & per host, queue | Latency > baseline (e.g. > 5-10 ms for flash) |
| Replication | Sync/async state, lag (RPO) | Suspended / split / lag growing |
| Firmware / recent change | Any NDU / upgrade in progress | Upgrade stalled |
| Call-home | Is vendor already notified? | |

<a id="svc"></a>
### 7.2 IBM FlashSystem / Storwize / SVC (Spectrum Virtualize) - SSH

```bash
lssystem                                 # code level, capacity, statistics
lseventlog -order severity -fixed no     # unfixed events, highest severity first ([CAUTION] running the DMP/fix procedure in GUI performs actions)
lsnodecanister  (or lsnode on SVC)       # status online, config node
lsenclosure ; lsenclosurecanister ; lsenclosurepsu ; lsenclosurebattery
lsdrive -filtervalue status=offline ; lsdrive -filtervalue status=degraded   # failed / degraded drives
lsarray                                  # array status, rebuilding
lsmdisk                                  # mdisk status online / degraded / offline
lsmdiskgrp                               # pool capacity / overallocation
lsvdisk -filtervalue status=offline      # offline volumes
lsvdisk -filtervalue status=degraded
lshost                                   # host status: online / degraded / offline
lshost <host>                            # per-WWPN state & node_logged_in_count
lsportfc                                 # FC port status
lsfabric -host <host>                    # logins between host and nodes
lsrcrelationship ; lsrcconsistgrp        # replication state
lspartnership
lsiogrp                                  # I/O group / write cache status
```

GUI: Dashboard (health, performance, capacity) -> Monitoring > Events (view Recommended Actions; `[CAUTION]` "Run Fix" / DMP executes recovery steps - only with approval or IBM guidance) -> Monitoring > Performance (latency per node / volume) -> Hosts (state) -> Pools.

<a id="netapp"></a>
### 7.3 NetApp ONTAP - SSH to cluster mgmt LIF

```bash
system health status show ; system health alert show
cluster show                             # nodes healthy / eligible
storage failover show                    # takeover possible? / in takeover / giveback pending
event log show -severity ERROR -time ><MM/DD/YYYY HH:MM:SS>
storage aggregate show -fields state,percent-used,raidstatus
volume show -state !online               # offline / restricted volumes
volume show -percent-used >90            # full volumes
storage disk show -broken ; storage disk show -container-type spare
storage shelf show -errors
network port show -health-status !healthy
network interface show -is-home false    # LIFs migrated off home port (after failover/port down)
network interface show -status-oper down
vserver show ; vserver nfs show ; vserver cifs show
lun show -state offline ; lun mapped show
igroup show                              # FC/iSCSI initiators logged in?
snapmirror show -fields state,status,lag-time,healthy
qos statistics volume latency show -iterations 3   # [LOAD] per-volume latency (bounded sampling)
statistics show-periodic -iterations 5   # [LOAD] cluster ops / latency (bounded sampling)
```

<a id="3par"></a>
### 7.4 HPE 3PAR / Primera / Alletra 9000 - SSH

```bash
showsys ; showversion
checkhealth -detail                      # [LOAD] best single health command (takes a while; avoid repeating on an overloaded array)
showalert -n                             # new alerts
shownode ; shownode -ps                  # node state, PSU
showbattery
showpd -failed -degraded                 # failed/degraded physical disks
showcage
showport                                 # target ports ready / loss_sync / offline
showhost -d                              # host WWPNs & which ports they are seen on
showvv -showcols Name,State,Comp_Usr_MB  # VV state
showcpg                                  # pool space
showrcopy                                # remote copy groups state
statvlun -ni -rw -iter 1                 # [LOAD] per-VLUN latency (svt ms), one sample
statport -host -iter 1                   # [LOAD] one sample
```

<a id="pure"></a>
### 7.5 Pure Storage FlashArray - SSH

```bash
purearray list ; purearray list --space  # capacity / data reduction
purealert list --filter "state='open'"   # open alerts (syntax may vary by Purity version; plain 'purealert list' works)
purehw list                              # controllers, drives, fans, PSU - status 'ok'
purehost list --all                      # hosts, WWPNs, volumes
pureport list --initiator                # which initiators are seen on which array port
purevol list --space
purearray monitor --interval 1 --repeat 5   # [LOAD] latency / IOPS live (5 samples)
purepod list ; purepod replica-link list    # ActiveCluster / replication
```

<a id="dell"></a>
### 7.6 Dell (PowerMax / Unity / PowerStore) and other arrays - mostly GUI

| Array | Where | What to check |
|-------|-------|---------------|
| PowerMax / VMAX | Unisphere for PowerMax: System > Alerts; Hardware; Storage Groups > performance; SRDF groups | Directors offline, disk failures, SRP capacity, SG response time, SRDF state (Synchronized / Consistent vs Suspended / Partitioned) |
| Unity | Unisphere: Dashboard health, Events/Alerts, System > Service > Health, Storage pools, Hosts > Initiators | SP offline/service mode, pool full, initiator not logged in, replication sessions |
| PowerStore | PowerStore Manager: Monitoring > Alerts, Hardware (appliance/nodes), Storage > Volumes performance, Hosts & Host Groups | Node fault, drive failure, capacity, host path count |
| Hitachi VSP | Storage Navigator / Ops Center: Alerts (SIM), Ports, Pools, LDEV status | SIM codes, pool depletion, port down |
| Generic | Vendor support portal / call-home | Has vendor already opened a proactive case? |

PowerMax CLI (if Solutions Enabler host available): `symcfg list`, `symcfg -sid <SID> list -dir all`, `symevent -sid <SID> list`,
`symdev -sid <SID> list -notready`, `symrdf -sid <SID> list`.

---

<a id="switch"></a>
## 8. Network Switches (Cisco IOS / IOS-XE / NX-OS; similar for Arista EOS)

```bash
show version                             # uptime, LAST RELOAD REASON, image
show logging | last 100   (NX-OS)  /  show logging | include %   (IOS)
show interface status | ex connected     # notconnect / err-disabled / disabled ports
show interface status err-disabled ; show errdisable recovery
show interface <if>                      # input errors, CRC, runts, giants, output drops, resets, last flap
show interface counters errors           # all ports at once - non-zero & increasing?
show interface <if> transceiver details  # optic power / alarms
show cdp neighbors ; show lldp neighbors # cabling / neighbor as expected
show mac address-table address <mac>     # where is the host? flapping between ports = loop / LACP issue
show ip arp <ip>  (NX-OS: show ip arp <ip> vrf all)
show port-channel summary  (IOS: show etherchannel summary)   # members (P)=bundled, (s)=suspended, (D)=down
show lacp neighbor
show vpc ; show vpc consistency-parameters global ; show vpc peer-keepalive   # NX-OS vPC: peer-link up, consistency ok
show spanning-tree summary
show spanning-tree detail | i ieee|occur|from|exec   # topology changes: how many, when, from which port
show spanning-tree blockedports
show vlan brief                          # VLAN exists & active on trunk
show interface trunk                     # allowed / forwarding VLANs
show ip route <dest> [vrf <name>]
show ip ospf neighbor ; show bgp summary  (or show ip bgp summary)   # adjacencies up / flapping
show standby brief ; show vrrp brief     # gateway HA state - active/standby correct?
show processes cpu sorted | ex 0.0       # IOS: CPU high (+ show processes cpu history). NX-OS: show processes cpu sort
show system resources (NX-OS) ; show memory statistics
show environment ; show module ; show inventory   # fans, PSU, temp, modules
show storm-control
show policy-map interface <if>           # QoS drops
ping <ip> source <vlan/if> repeat 5 size 1500 df-bit   # [PROBE] MTU issues (IOS syntax; NX-OS: ping <ip> source <if> packet-size 1472 df-bit count 5)
traceroute <ip>                          # [PROBE]
# [CAUTION] clear counters (record first!), shut/no shut, clear ip bgp, spanning-tree changes
# [EVIDENCE] show tech-support | redirect bootflash:tech.txt  (large, CPU on control plane, writes to flash - check 'dir bootflash:')
```

Remarks:

- Many hosts in one VLAN lose connectivity at once -> STP topology change / loop / gateway (HSRP/VRRP) / vPC peer-link.
- One host slow -> duplex mismatch, CRC errors, optic, port-channel member down, MTU mismatch.
- After change -> compare `show run` with last backup (config archive / NMS).

---

<a id="fw"></a>
## 9. Firewalls

<a id="pan"></a>
### 9.1 Palo Alto (PAN-OS)

```bash
show system info                         # version, uptime, mgmt IP
show high-availability state             # active/passive; 'state synchronization'
show high-availability all               # link/path monitoring, last failover reason
show system resources                    # MP CPU / memory
show running resource-monitor second last 30   # DATAPLANE CPU - high = drops
show session info                        # session table usage vs max
show session all filter source <ip> destination <ip>   # is the flow there? which rule/NAT?
show session id <id>
test security-policy-match from <zone> to <zone> source <ip> destination <ip> protocol 6 destination-port <port>
test nat-policy-match from <zone> to <zone> source <ip> destination <ip> protocol 6 destination-port <port>
show counter global filter delta yes severity drop     # why packets dropped (run twice)
show interface all ; show interface <ethX/Y>           # link state, errors
show routing route destination <ip>     # (or 'show routing fib')
show routing protocol bgp summary
show arp all | match <ip>
show log traffic direction equal backward query equal "( addr.src in <ip> )"   # newest first (or GUI Monitor > Traffic)
show jobs all                            # recent commits / content updates (change at incident time?)
show system disk-space
show vpn ike-sa ; show vpn ipsec-sa      # site-to-site tunnels
```

GUI: Dashboard (HA widget, System resources) -> Monitor > Traffic / Threat / System logs (filter by IP & time) ->
Monitor > Session Browser -> Device > High Availability -> Monitor > Logs > Configuration (who committed what) ->
Monitor > Packet Capture ([CAUTION] load).

<a id="forti"></a>
### 9.2 Fortinet FortiGate (FortiOS)

```bash
get system status                        # version, uptime, HA mode
get system performance status            # CPU, memory, sessions, conserve mode?
diagnose sys top 1 20                    # [LOAD] interactive top processes (press q to exit)
get system ha status                     # primary/secondary, sync status
diagnose sys ha checksum cluster         # config in sync
get router info routing-table all
get router info routing-table details <ip>
get system arp
get hardware nic <port>  (or: diagnose hardware deviceinfo nic <port>)   # link, errors
# Session filter below only changes the display filter of YOUR CLI session ('filter clear' resets the filter, not traffic).
# [CAUTION] NEVER type 'diagnose sys session clear' - that deletes live sessions (drops traffic).
diagnose sys session filter clear
diagnose sys session filter src <ip>
diagnose sys session filter dst <ip>
diagnose sys session filter              # verify filter is set BEFORE listing
diagnose sys session list                # [LOAD] matching sessions (unfiltered = huge output on busy box)
diagnose sniffer packet any 'host <ip> and port <port>' 4 20 l   # [CAUTION] packet capture (CPU, traffic data) - keep filter + 20-packet limit
# [CAUTION] debug flow (CPU heavy on busy box) - always set a count and disable after:
#   diagnose debug flow filter addr <ip> ; diagnose debug flow trace start 20 ; diagnose debug enable
#   ... then: diagnose debug disable ; diagnose debug reset
diagnose vpn tunnel list ; get vpn ipsec tunnel summary
execute log filter category 0 ; execute log display   # [LOAD] per-CLI-session display filter; output can be long (or GUI Log & Report)
```

<a id="checkpoint"></a>
### 9.3 Check Point (Gaia, expert mode where noted)

```bash
cphaprob state                           # ClusterXL: Active / Standby / Down / Ready
cphaprob -a if                           # cluster interfaces up
cphaprob list                            # critical devices (pnotes) failing
cphaprob show_failover                   # last failover reasons (R80.20+)
fw stat ; cpstat fw                      # policy installed? name / date
fw ctl pstat                             # memory, connections
fw tab -t connections -s                 # connection table #VALS vs #PEAK vs limit
cpview                                   # [LOAD] interactive overview (CPU per core, throughput, drops), exit with q
fw ctl multik stat                       # CoreXL instances load
fwaccel stat ; fwaccel stats -s          # SecureXL state
cpwd_admin list                          # daemons running
fw ctl zdebug drop | grep <ip>           # [CAUTION] enables kernel debug while running - busy GW: run briefly, Ctrl+C
fw monitor -e "accept host(<ip>);"       # [CAUTION] inserts capture into the kernel chain (load) - run briefly, Ctrl+C
tcpdump -p -nni <if> host <ip> -c 50     # [CAUTION] packet capture (CPU, traffic data); -p = don't switch NIC to promiscuous
df -h ; top                              # top: [LOAD] interactive, exit with q
```

GUI: SmartConsole > Logs & Monitor (filter src/dst, time) ; Gateways & Servers (status icons) ; Audit log (who installed policy).

<a id="asa"></a>
### 9.4 Cisco ASA / FTD (LINA)

```bash
show version                             # uptime
show failover                            # this unit Active/Standby, interface monitoring, last failover
show failover history
show cpu usage ; show memory
show conn count ; show xlate count
show conn address <ip>
show interface ip brief ; show interface <if>    # overruns / no buffer = overload
show route <ip>
show asp drop                            # accelerated path drop reasons (run twice, compare)
packet-tracer input <in_if> tcp <src_ip> 12345 <dst_ip> <port> detailed   # simulated rule / NAT / route decision (never add 'transmit')
show nat detail | i <ip>
show logging | i <ip>
show vpn-sessiondb summary ; show crypto ikev2 sa ; show crypto ipsec sa peer <ip>
# [CAUTION] capture creates a capture object + buffer (config/state change). Full lifecycle, then verify cleanup:
#   capture CAP interface <if> match ip host <a> host <b> ; show capture CAP ; no capture CAP ; show capture
```

<a id="fw-notes"></a>
### 9.5 Firewall remarks

- "Application can't connect" -> first confirm the flow even **reaches** the firewall (session table / capture). If no session: routing / switching / source host issue.
- Check **HA state** first; split-brain (both active) or recent failover explains a lot.
- Check **commit / policy install / content-update / cert** history near incident start.
- Session table full or dataplane CPU high -> DDoS, scan, or backup traffic burst.
- Asymmetric routing -> drops with "TCP out of state / non-SYN" reasons.

---

<a id="hpe"></a>
## 10. HPE ProLiant DL and BladeSystem BL (mostly GUI)

<a id="ilo"></a>
### 10.1 iLO (DL and BL) - `https://<ilo-ip>`

| Where (iLO 4 / 5 / 6) | What to check | Bad state / remark |
|-----------------------|---------------|--------------------|
| **Information > Overview** (iLO 5/6: **Information > Overview / Health Summary**) | System health, server power, iLO health, last POST | Health "Critical" / "Degraded" |
| **Integrated Management Log (IML)** | Hardware events with timestamp (memory, CPU, PSU, fan, storage, NMI, ASR) | "Uncorrectable Memory Error", "Processor IERR", "Power Supply Failure", "ASR Detected", "System Revision Mismatch" |
| **iLO Event Log** | Logins, power on/off/reset, iLO reboots | Who / what reset the server and when |
| **System Information > Summary / Processors / Memory** | Failed / degraded DIMMs, CPU status | DIMM "Degraded" or mapped-out |
| **System Information > Fans / Temperatures** | Redundancy, sensor readings | Fan failed, over-temp (check room/rack) |
| **System Information > Power** (+ Power & Thermal > Power Meter) | PSU status, redundancy | PSU failed / not redundant / input lost (PDU side) |
| **System Information > Network** | NIC port link status | Link down on expected port |
| **System Information > Device Inventory** | NIC/HBA firmware & status | Device failed |
| **System Information > Storage** (Smart Array / SR / NS controllers) | Controller, cache, battery, logical drives, physical drives | LD "Failed" / "Interim Recovery"; drive predictive failure; cache disabled (battery) |
| **Remote Console (HTML5 / .NET / Java)** `[CAUTION]` | What is on the screen right now (opening may take over another user's console; use shared mode if offered; don't type unless needed) | Kernel panic, PSOD, POST error, "Red Screen of Death", grub prompt, emergency mode -> **screenshot it** |
| **Virtual Media** | Media still mounted? (view only; `[CAUTION]` Eject / Mount) | Server tries to boot from ISO |
| **Power Management** | Power state, power regulator, power cap (view only; `[CAUTION]` any power button / cap change) | Power capped too low = performance issue |
| **Active Health System Log** `[EVIDENCE]` | Download for vendor (choose a short date range - generation loads iLO) | HPE support always asks for AHS. `[CAUTION]` never click "Clear Log" |
| **Firmware & OS Software / Firmware Verification** | ROM / iLO / NIC / controller versions | Mismatched after partial update |
| **Security > Security Dashboard** | Risk items | |

iLO CLI over SSH (for speed / scripting, read-only):

```text
show /system1                            # server power state, health
show /system1/log1                       # IML entries (show /system1/log1/record<N> for detail)
show /map1/log1                          # iLO event log
show /system1/fan*  ;  show /system1/sensor*  ;  show /system1/powersupply*
textcons                                 # [CAUTION] takes the text console (exit with ESC + ( )
# [CAUTION] power reset / power off hard / reset /map1 (iLO reset is safe for the host but drops sessions)
```

From an admin host `[CAUTION]` (creates an iLO session - always log out, iLO has a small session limit):
`ilorest login <ilo> -u <user>` -> `ilorest serverlogs --selectlog=IML` / `ilorest list --select ComputerSystem.` -> `ilorest logout`.

<a id="oa"></a>
### 10.2 BladeSystem c7000 Onboard Administrator (OA) - `https://<oa-ip>`

| Where                                              | What to check                                    | Bad state                                                    |
| -------------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------ |
| **Rack Overview / Enclosure Information > Status** | Enclosure health, active vs standby OA           | Degraded / Failed; standby OA missing                        |
| **Device Bays >**                                  | Blade health, power, iLO link                    | Blade "Failed", "No Power", "Insufficient Power", "Mismatch" |
| **Interconnect Bays**                              | Virtual Connect / SAN switch / pass-thru modules | Module "Degraded", powered off, management IP lost           |
| **Power and Thermal > Power Subsystem**            | PSU status, redundancy mode, input power         | PSU failed; redundancy lost (N+N broken)                     |
| **Power and Thermal > Thermal Subsystem / Fans**   | Fan status, ambient temp                         | Fan failed / missing; high ambient                           |
| **Enclosure Settings > System Log / OA syslog**    | Events with time                                 | Blade removed/inserted, power events, IPMI alerts            |
| **Active OA / Standby OA**                         | Redundancy, firmware match                       | Firmware mismatch, standby not present                       |

OA CLI over SSH:

```text
show enclosure status                    # overall + subsystem health
show server list                         # all bays: power, health, iLO IP
show server status <bay>                 # detail for one blade
show interconnect list ; show interconnect status <bay>
show enclosure power_summary ; show enclosure fan all ; show enclosure temp
show oa status all
show syslog oa                           # OA log
show syslog server <bay>                 # blade iLO log via OA
```

<a id="vc"></a>
### 10.3 Virtual Connect (VCM) - `https://<vc-ip>` (or via OneView)

| Where | What to check |
|-------|---------------|
| Domain Status / System Log | Domain health, stacking link status, recent events |
| Server Profiles | Profile assigned & status OK for the blade; profile not "Failed" |
| Ethernet Networks / Shared Uplink Sets | Uplink port linked/active, LACP, network "OK" (not "Failed" / "Degraded") |
| SAN Fabrics | Uplinks "Logged In"; fabric "OK"; server WWPN logged in |
| Interconnect Bays | VC module status, firmware match between modules |

VC CLI: `show domain`, `show status`, `show profile`, `show uplinkport`, `show stackinglink`, `show fabric`, `show network`, `show systemlog`.

<a id="oneview"></a>
### 10.4 HPE OneView / Synergy (if used)

Activity (filter Critical, last 24h) -> Server Hardware (health, profile, iLO status) -> Server Profiles (compliance / "Inconsistent") ->
Logical Interconnects (uplink sets, port status, firmware) -> Enclosures / Frames -> Firmware Bundles (compliance) -> Alerts -> Remote Support (case already raised?).

<a id="hpe-notes"></a>
### 10.5 HPE remarks

- **Server rebooted by itself** -> IML (ASR / NMI / hardware error) + iLO Event Log (who pressed power / was it iLO) + OS `last -x` / `errpt`.
- **Whole enclosure down** -> OA power subsystem + PDU / rack power + datacenter.
- **Multiple blades lost network/SAN** -> Virtual Connect / interconnect bay module, not the blades.
- Serial number and product number for HPE case: iLO Overview, or `dmidecode -t system`.

---

<a id="power"></a>
## 11. IBM Power Servers (HMC / ASMI / FSP / BMC)

<a id="hmc-gui"></a>
### 11.1 HMC GUI - `https://<hmc-ip>`

| Where (Enhanced UI, HMC V9/V10)                                              | What to check                                | Bad state                                                                                                                                                    |
| ---------------------------------------------------------------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **All Systems** - State column                                               | Managed system state                         | `Error`, `No Connection`, `Incomplete`, `Recovery`, `Failed Authentication`, `Power Off` (unexpected), `Error - Dump in progress`                            |
| **All Systems > > Partitions** - State / Reference Code / RMC                | Each LPAR state, current SRC, RMC connection | `Not Activated` (unexpected), `Error`, `Open Firmware`, `Starting` stuck, SRC stuck (e.g. `0c9`, `888`, `B2xxxxxx`), RMC `inactive` (DLPAR / LPM won't work) |
| **Serviceable Events Manager** (Serviceability > Serviceable Events Manager) | Open events, last 24-72h, by system          | Any open hardware SRC with FRU callout, "Call Home: Failed"                                                                                                  |
| **System > Attention LED**                                                   | LED status                                   | Attention LED on = hardware event pending                                                                                                                    |
| **System > Hardware Information / Adapters**                                 | Physical adapters & slots                    | Adapter missing / failed                                                                                                                                     |
| **System > Properties > Processors / Memory**                                | Installed vs configurable vs deconfigured    | Deconfigured CPU / memory (garded hardware)                                                                                                                  |
| **Partition > Console Window > Open Terminal**                               | Live console of LPAR / VIOS                  | Panic, LED code, hung boot, login prompt? **[CAUTION] only one vterm session; closing others' console**                                                      |
| **Partition > Reference Code history**                                       | Boot progress SRC sequence                   | Where it stopped                                                                                                                                             |
| **Performance (HMC V9 R1+)**                                                 | Pool utilisation, LPAR CPU vs entitlement    | Shared pool exhausted                                                                                                                                        |
| **HMC Management > Console Events / Audit**                                  | Who did what (shutdown, DLPAR, LPM)          | Unexpected human / scheduled action                                                                                                                          |
| **Virtual Networks / Virtual Storage (VIOS)**                                | SEA status, vSCSI / NPIV mappings per LPAR   | Missing mapping, VIOS down                                                                                                                                   |
| **Call Home / Remote Support**                                               | Events transmitted to IBM?                   | Not configured / failed                                                                                                                                      |

<a id="hmc-cli"></a>
### 11.2 HMC CLI (SSH as hscroot / your HMC user) - fast, read-only

```bash
lshmc -V                                 # HMC version
lssyscfg -r sys -F name,type_model,serial_num,state            # all managed systems + state
lssyscfg -r lpar -m <sys> -F name,lpar_id,lpar_env,state,rmc_state,os_version
lsrefcode -r sys -m <sys>                # system SRC
lsrefcode -r lpar -m <sys> -F lpar_name,lpar_id,time_stamp,refcode   # current SRC per LPAR
lsrefcode -r lpar -m <sys> --filter lpar_names=<lpar> -n 20          # last 20 SRCs (boot history)
lssvcevents -t hardware --filter "status=open"                       # open hardware serviceable events
lssvcevents -t hardware -d 3                                         # last 3 days
lssvcevents -t console -d 1                                          # HMC console events (who did what)
lsled -r sa -m <sys> -t phys                                         # system attention LED
lshwres -r proc -m <sys> --level sys                                 # configurable vs installed procs
lshwres -r mem -m <sys> --level sys
lshwres -r proc -m <sys> --level pool                                # shared pool usage
lslic -t sys -m <sys>                                                # firmware level
monhmc -r disk -n 0 ; monhmc -r mem -n 0                             # HMC itself healthy (disk full = HMC issues)
# [CAUTION] mkvterm -m <sys> -p <lpar> ; rmvterm -m <sys> -p <lpar>   (console take-over, one session only)
# [CAUTION] chsysstate (power on/off/restart LPAR or system), chhwres (DLPAR), migrlpar (LPM)
```

<a id="asmi"></a>
### 11.3 ASMI (Advanced System Management Interface) - `https://<fsp-or-ebmc-ip>`

Use when HMC shows `No Connection` / `Incomplete`, or for deep hardware detail.

| Where | What to check |
|-------|---------------|
| System Service Aids > **Error / Event Logs** | Platform error logs with SRC, FRU callouts, timestamps |
| System Configuration > **Hardware Deconfiguration** (Processor / Memory) | Guarded / deconfigured CPU cores, DIMMs |
| System Information > **Vital Product Data** | Serial, part numbers (for IBM case) |
| **Power / Restart Control** | Power state, last IPL type, auto restart setting (read only - don't change) |
| Environmental Services > **Temperature / Fan / Power Supply** status | Thermal / PSU problems |
| Network Services > Network Configuration | FSP/eBMC IP (when HMC lost connection) |
| Power10 eBMC: **Overview / Logs > Event logs / Hardware status / Inventory and LEDs** | Same as above in newer UI |

<a id="power-notes"></a>
### 11.4 IBM Power remarks

- HMC `No Connection` to a system does **not** mean LPARs are down; check LPARs directly (ping/SSH) before panicking.
- LPAR stuck in `Starting` with SRC `B2xxxxxx` -> firmware/partition config (memory/CPU not available, adapter missing, boot device not found).
- LPAR `Running` but unreachable -> open console (vterm, `[CAUTION]` single session), check AIX LED code / Linux panic.
- Many LPARs slow on the same frame -> shared processor pool exhausted, VIOS CPU, or VIOS SAN/network path.
- RMC `inactive` -> DLPAR / LPM / OS shutdown from HMC won't work; check `lssrc -s ctrmc` on LPAR and HMC-LPAR network.
- IBM case needs: machine type-model + serial (`lssyscfg -r sys -F type_model,serial_num`), SRC, FRU callout, `snap -ac` from AIX, `pedbg -c -q 4` from HMC if HMC issue (`[EVIDENCE]` large, only when IBM asks).

---

<a id="shared"></a>
## 12. Other common shared services (often the hidden root cause)

| Service | Quick check | Remark |
|---------|-------------|--------|
| DNS `[PROBE]` | `dig <name> @<dns1>` / `@<dns2>`; `nslookup` on AIX | One dead DNS server = random slowness (resolver timeout 5 s) |
| NTP | `chronyc sources -v` / `ntpq -p` | Skew breaks Kerberos/AD logins, clusters, certificates |
| AD / LDAP | `id <user>`, `sssctl domain-status <domain>`; `[CAUTION]` `kinit` writes a ticket cache - use a throw-away one: `KRB5CCNAME=/tmp/krb5cc_test kinit <user>` then `kdestroy -c /tmp/krb5cc_test` | Mass login failures |
| Certificates `[PROBE]` | `openssl s_client ... \| openssl x509 -noout -dates` | Expiry often lands on weekends / midnight |
| Load balancer (F5 / NetScaler) | Pool member status, VIP status, health monitor logs | Members marked down by monitor |
| Backup | Backup window vs incident time | Backup I/O / network saturation at night |
| Monitoring / jump host | Is it the *monitoring* that's broken, not the server? | False S1 |
| Power / cooling / DC | DC ops / BMS alarms, PDU status | Multiple racks affected simultaneously |

---

<a id="oneliners"></a>
## 13. Quick "is it this layer?" one-liners

```bash
# From an affected Linux host - a 30-second snapshot
uptime; df -hT | awk 'NR==1 || $6+0>=90'; free -h; systemctl --failed --no-legend
timeout 60 multipath -ll 2>/dev/null | grep -ciE 'failed|faulty'; ip -br a; ip r | grep default
dmesg -T | tail -20; chronyc tracking | grep -E 'System time|Leap'

# From an affected AIX host
uptime; df -g | awk 'NR==1 || $4+0>=90'; lsps -s; errpt | head -10; lspath | grep -v Enabled; lsvg -o; netstat -rn | grep default
```

---

<a id="matrix"></a>
## 14. Symptom -> Likely Layer Matrix

| Symptom | Check first | Then |
|---------|-------------|------|
| Single server unreachable (ping fails) | Console (iLO / HMC vterm / OLVM console) | Switch port / VLAN / bond; HW (IML / SRC) |
| Many servers in one VLAN / subnet unreachable | Network switch (STP, gateway HSRP/VRRP, vPC) / firewall | Recent network change |
| Many servers across VLANs, same site | Core switch / firewall HA / DC power | DNS / NTP / AD |
| All blades in one enclosure | OA, Virtual Connect / interconnect, enclosure power | Upstream switch of VC uplinks |
| All LPARs on one Power frame | HMC system state, VIOS pair, shared pool, frame SRC | SAN / network uplinks of VIOS |
| Server slow, high %wa / D-state / IO timeouts | Storage latency (array perf), multipath path loss | SAN port errors / slow drain, array rebuild/cache |
| Filesystem read-only / VMs paused | SAN / storage (paths lost, pool full) | Array events, fabric logs |
| Many hosts slow on same array | Array performance, controller failover, rebuild, replication | Fabric slow-drain |
| Application can't connect, ping works | Port listening (`ss`/`netstat`), local firewall, network FW policy/session | App logs, cert, DNS |
| Logins failing for many users | AD/LDAP/SSSD, time skew, DNS | Account lock / password expiry |
| Server rebooted unexpectedly | `last -x` / `sysdumpdev -L`, vmcore, IML / ASR, iLO / HMC event log | Cluster fencing (`pcs stonith history`, `hacmp.out`) |
| Cluster failover happened | Cluster logs (pacemaker / hacmp.out), heartbeat network, storage quorum disk | Network / SAN at that timestamp |
| OLVM hosts NonResponsive | vdsmd, engine-host network, certificates | Storage latency -> sanlock |
| Intermittent / random slowness | DNS (one dead resolver), NTP, packet loss (CRC), MTU | Firewall CPU / session table |

---

<a id="evidence"></a>
## 15. Evidence Collection Cheat-Sheet (collect BEFORE restore if IM allows)

The Tag column says what each item does. `[EVIDENCE]` rows generate files (check free space first), add CPU / IO /
management-plane load for minutes, and contain sensitive data (configs, IPs, users). `[LOAD]` rows only print long output to
your terminal (capture it with your SSH client's session logging). Rows marked **SENDS TO VENDOR** transmit data externally
the moment you run them - only with IM approval / vendor case open. Prefer the least heavy option first.

| Technology | Collect | Command / Location | Tag / side effect |
|------------|---------|--------------------|-------------------|
| RHEL | sosreport, vmcore | `sos report --batch`; `/var/crash/*` | `[EVIDENCE]` archive in /var/tmp (1-2 GB) |
| AIX | snap, dump | `snap -ac` -> `/tmp/ibmsupt/snap.pax.Z`; `sysdumpdev -L` (query only) | `[EVIDENCE]` archive in /tmp (1 GB+) |
| VIOS | snap | `snap` (padmin) | `[EVIDENCE]` archive on VIOS |
| PowerHA | cluster logs | `snap -e` (collects from all cluster nodes); `/var/hacmp/log/hacmp.out` | `[EVIDENCE]` archive, load on all nodes |
| Pacemaker | cluster report | `crm_report -f "YYYY-MM-DD HH:MM" /tmp/crm_report` | `[EVIDENCE]` archive, SSH to all nodes |
| OLVM | log collector | `ovirt-log-collector` (engine); `sos report` (hosts) | `[EVIDENCE]` archive, connects to every host |
| Brocade | supportsave | `supportsave` (both fabrics) | `[EVIDENCE]` uploads to your FTP/SCP server |
| Cisco MDS / NX-OS / IOS | show tech | `show tech-support details` (to terminal) | `[LOAD]` long output, control-plane CPU |
| IBM FlashSystem / SVC | support package | GUI: Settings > Support > Support Package | `[EVIDENCE]` package on config node. `[CAUTION]` "with statesave" only when IBM asks |
| NetApp | AutoSupport | `system node autosupport invoke -node * -type all -message "Case <no>"` | `[EVIDENCE]` **SENDS TO VENDOR** |
| 3PAR / Primera | checkhealth / InSplore | `checkhealth -detail`; Service Processor InSplore | checkhealth `[LOAD]`; InSplore `[EVIDENCE]` can upload to HPE |
| Pure | phonehome logs | `purearray phonehome --send-today` (or support portal) | `[EVIDENCE]` **SENDS TO VENDOR** |
| Palo Alto | tech support file | GUI: Device > Support > Generate Tech Support File | `[EVIDENCE]` file on MP, MP CPU load |
| FortiGate | debug report | `execute tac report` (to terminal) | `[LOAD]` very long output, CPU load |
| Check Point | cpinfo | `cpinfo -z -o /var/log/cpinfo_<case>.info` | `[EVIDENCE]` archive in /var/log (check `df -h`) |
| ASA | show tech | `show tech-support` (to terminal) | `[LOAD]` long output |
| HPE iLO | AHS log + IML screenshot | iLO > Active Health System Log > Download (short date range) | `[EVIDENCE]` file generated on iLO |
| HPE OA / VC | full dump | OA CLI `show all` ; VC `show all *` (to terminal) | `[LOAD]` very long output - try targeted `show` commands first |
| IBM HMC | serviceable events + pedbg | `lssvcevents` (query only); `pedbg -c -q 4` | pedbg `[EVIDENCE]` large, HMC load - only when IBM asks |
| Any | **Screenshots** of console / GUI error with clock visible | | None |

---

<a id="status"></a>
## 16. Status Update Template

```text
[S1/S2] <Case no.> - <Service / CI> - Update #<n> - <HH:MM TZ>

Impact      : <who/what is affected, since when>
Current status : <Investigating / Mitigated / Restored / Monitoring>
Findings    : <what we checked and what we found - layer by layer>
Actions taken : <what was done, by whom, at what time>
Next steps  : <next checks / vendor case / approvals needed>
Vendor case : <vendor, case no., severity>
Next update : <HH:MM TZ>
```

---

<a id="closure"></a>
## 17. Closure Checklist

- [ ] Service restored and confirmed by app owner / user (not only "server is up")
- [ ] Monitoring green; alerts acknowledged / closed
- [ ] Temporary changes recorded (e.g. pcs constraints, disabled ports, bypass rules, static routes) and a plan to revert
- [ ] Cluster back to preferred node / redundancy restored (both VIOS, both fabrics, both PSUs, HA pair synced)
- [ ] Counters cleared **after** evidence saved, so new errors are visible
- [ ] Evidence (logs, snaps, screenshots) attached to the case
- [ ] Vendor case updated / closed, RMA tracked
- [ ] Timeline written (first alert, detection, escalation, mitigation, restore)
- [ ] Problem record raised for RCA if needed
