# Performance, Capacity and Disk Checks

Why it is slow, or what filled the disk. Is it up, and which layer: [Oncall_S1_S2_Runbook.md](Oncall_S1_S2_Runbook.md).

Linux `sar` is not AIX `sar`. AIX has no `sar -n`. On AIX, `sar -r` is paging, not free memory. RHEL 8+ often has no `netstat`; use `ss`.

## Map

| Need | Open |
| --- | --- |
| 30 seconds on the host | [Linux and AIX snapshot](#snapshot) |
| Every Linux sar flag | [sar](#linux-sar) |
| Every AIX sar flag | [sar](#aix-sar) |
| Which process, vmstat, iostat | [CPU, memory, disk](#cpu-mem-disk) |
| netstat, ss, TCP state | [Linux](#linux-netstat) · [AIX](#aix-netstat) |
| What is this port | [Port list](#ports) |
| 100% full, or "no space" with room left | [Inodes](#inodes) · [Find the files](#large-files) |
| Delete without making it worse | [How](#delete) · [Do not run](#delete-never) |

| Flag | Linux | AIX | Means |
| --- | --- | --- | --- |
| CPU | `sar -u` | `sar -u` | `%iowait` / `%wio` high = storage, not CPU |
| Run queue | `sar -q` | `sar -q` | above the CPU count = need more CPU |
| Memory | `sar -r` | `vmstat` column `fre` | AIX `sar -r` is paging. Use `lsps -s` for paging space |
| Swapping now | `sar -W` | `vmstat` `pi` `po` | non-zero = memory is short |
| Disk latency | `sar -d -p` | `sar -d` | high `await` / `avserv` = slow LUN or path |
| NIC rate | `sar -n DEV` | `netstat -I en0 1 5` | `%ifutil` near 100 = link full |
| Retransmits | `sar -n ETCP` | `netstat -p tcp` | rising retransmits = packet loss |
| Sockets | `sar -n SOCK` / `ss -s` | `netstat -an` | `CLOSE-WAIT` pile = the app is not closing |

Click a link in the preview or on GitHub. In the editor, Ctrl+Shift+O jumps by heading.

## How to read a command

- No tag: query-only.
- `[LOAD]`: query-only, but heavy, interactive, or can hang on a bad filesystem. Short counts only (`1 5` = every 1 second, 5 times). Use a spare SSH session.
- `[PROBE]`: sends test traffic.
- `[CAUTION]`: changes or **deletes** something. Section 11 is the only section that removes data.

Rules that prevent a bad paste:

- **Linux `sar` and AIX `sar` are different commands.** `sar -n DEV` and `sar -S` exist only on Linux. On AIX, network is `netstat` / `entstat`, and `sar -r` means paging, not memory.
- **RHEL 8+ often has no `netstat`** (`net-tools` not installed). Use `ss`. AIX has `netstat` and does not have `ss`.
- On Linux, the **first line** of `sar -u 1 5` is often the average **since boot**. Read the later lines for "right now". The final `Average` line is the average of the samples, not the current second.
- `du` / `find` / `lsof` on a **hung NFS mount block the shell**. Stay on one filesystem (`-x` on AIX, `-xdev` on Linux) and avoid the NFS mount.

Thresholds below are starting points, not your SLO. Compare with the same hour last week (`sar -f`) before calling it bad.

---

<a id="snapshot"></a>
## 1. Thirty-second snapshot

### Linux

```bash
nproc; uptime
vmstat 1 5                               # r, b, us, sy, id, wa, st, si, so, free, cache
mpstat -P ALL 1 3                        # one CPU pinned at 100%?
free -h                                  # trust 'available', not 'free'
df -hT; df -i                            # space AND inodes
iostat -xz 1 3                           # %util, await, aqu-sz  (needs sysstat)
sar -n DEV 1 3                           # interface throughput, %ifutil
sar -n ETCP 1 3                          # retrans/s
ss -s                                    # socket totals, TCP states
```

### AIX

```bash
uptime; lparstat 1 5                     # physc vs entitlement, %idle, %entc
vmstat 1 5                               # r, b, fre, pi, po
lsps -s                                  # paging space % used
df -g                                     # space. Inodes, if this AIX has the flag: df -i <fs>
iostat -D 1 3                            # avg serv, sqfull
netstat -I en0 1 3                       # per-interface packets and errors (change en0)
netstat -p tcp | egrep -i 'retrans|packet sent|packet received' | head
sar -u 1 5                               # %usr %sys %wio %idle  (ignore if 'sar' not installed)
```

How to read `vmstat` (both OS, column names differ slightly):

| Column | Bad when | Means |
|--------|----------|--------|
| `r` (run queue) | stays above CPU count | CPU starvation |
| `b` (blocked) | stays above 0 | threads stuck on I/O |
| `wa` / `%wio` / `wa` | high while CPU idle | waiting on disk or SAN, not on CPU |
| `st` (Linux steal) | above a few % | hypervisor took the CPU away (VM too small, or host busy) |
| `si` `so` / AIX `pi` `po` | sustained non-zero | swapping / paging. Memory is short |
| `fre` (AIX) | stuck near minfree and `po` > 0 | real memory pressure, not just filesystem cache |
| `in` `cs` | very high with high `%sys` | interrupt or context-switch storm (network, many small I/Os) |

---

<a id="linux-sar"></a>
## 2. Linux `sar` (sysstat)

Binary: `sar`. History files: `/var/log/sa/saDD` or `/var/log/sysstat/saDD` (`DD` = day of month). `ls -ld /var/log/sa /var/log/sysstat`.

```bash
sar -<flag> 1 5                          # live: every 1s, 5 times. Ignore line 1 if it is "since boot"
sar -<flag> -s 09:00:00 -e 10:00:00      # today, from the history file
sar -<flag> -f /var/log/sa/sa30 -s 09:00:00 -e 10:00:00    # a past day
sar -A -s 09:00:00 -e 09:10:00           # [LOAD] everything for a short window
sadf -d /var/log/sa/sa30 -- -u           # [LOAD] CSV, for a spreadsheet. Same flags after --
```

`sar -o /tmp/sa.bin 1 5` **writes a file**. Do not use `-o` for a check.

If `sar` is missing, `vmstat`, `iostat`, `mpstat` and `pidstat` answer the same questions. `iostat`, `mpstat`, `pidstat` and `sar` all come from the `sysstat` package.

| Command | What it reports | Read this |
|---------|-----------------|-----------|
| `sar -u 1 5` | CPU: `%user %nice %system %iowait %steal %idle` | `%iowait` high = storage. `%steal` high = hypervisor. `%system` high = kernel (interrupts, fs, network). All of user+system near 100 and iowait ~0 = CPU bound |
| `sar -u ALL 1 5` | same, plus guest, gnice, irq, soft | `%soft` high = network softirq (pps too high for the CPU) |
| `sar -P ALL 1 5` | per-CPU `-u` | one CPU at 100% and others idle = single-threaded app or IRQ pinned to one CPU |
| `sar -q 1 5` | `runq-sz`, task list size, `ldavg-1/5/15`, `blocked` | `runq-sz` above `nproc` = CPU saturated. `blocked` > 0 = I/O wait queue. Load average includes D-state threads, so high load + idle CPU = I/O, not CPU |
| `sar -w 1 5` | `proc/s` (forks), `cswch/s` (context switches) | `cswch/s` very high with high `%system` = too many threads or a spin |
| `sar -I SUM 1 5` | interrupts per second | sudden jump = NIC, HBA, or a noisy device |
| `sar -r 1 5` | memory: free, **available**, used, buffers, cache, commit | **`kbavail` / `%commit`**. Low available and `%commit` over 100 = will swap or OOM. Cache being large is normal |
| `sar -S 1 5` | swap used and `%swpused` | any growing swap during the incident |
| `sar -W 1 5` | `pswpin/s` `pswpout/s` | non-zero = actively swapping. This is the bad one |
| `sar -B 1 5` | paging: `pgpgin/s` `pgpgout/s` `fault/s` `majflt/s` | `majflt/s` high = reading from disk because memory was reclaimed |
| `sar -H 1 5` | hugepages free / reserved | DB (Oracle, etc.) failing to start or shrinking if free hugepages hit 0 |
| `sar -b 1 5` | total I/O: `tps` `rtps` `wtps` `bread/s` `bwrtn/s` | system-wide transfer rate. Does not say which disk |
| `sar -d 1 5` | per block device: `tps`, `rkB/s`, `wkB/s`, `areq-sz`, `aqu-sz`, `await`, `%util` | `%util` near 100 **and** `await` high = that device is saturated. `await` high and `%util` low = waiting on the SAN/array, not on the local HBA queue. Names look like `dev8-0` |
| `sar -d -p 1 5` | same, pretty names (`sda`, `dm-0`, `nvme0n1`) | use this so you can match `lsblk` |
| `sar -F 1 5` | filesystem space from sar (sysstat 11+) | older sysstat has no `-F`. `df` is the check that always works |
| `sar -v 1 5` | kernel tables: dentries, `file-nr`, inodes | `file-nr` near `/proc/sys/fs/file-max` = system-wide open-file exhaustion ("too many open files" everywhere) |
| `sar -n DEV 1 5` | per NIC: `rxpck/s` `txpck/s` `rxkB/s` `txkB/s` `%ifutil` | `%ifutil` near 100 = link full. High pps and low kB/s = small packets, CPU will suffer before the link does |
| `sar -n EDEV 1 5` | NIC errors: `rxerr/s` `txerr/s` `rxdrop/s` `txdrop/s` `rxfifo/s` `txfifo/s` | any rising rate = bad cable/SFP, duplex, or ring buffer too small |
| `sar -n IP 1 5` | IP packets in/out, forwards | forwards climbing on a host that should not route = ip_forward left on |
| `sar -n EIP 1 5` | IP errors, reassembly failures | `frag/s` and reassembly failures = MTU problem |
| `sar -n TCP 1 5` | TCP segments, active/passive opens | connection rate. A spike in `active/s` = this host is connecting out a lot |
| `sar -n ETCP 1 5` | `atmptf/s` `estres/s` **`retrans/s`** `isegerr/s` `orsts/s` | **`retrans/s` rising = packet loss** on the path. `estres/s` = resets. `atmptf/s` = failed connect attempts |
| `sar -n UDP 1 5` | UDP datagrams | `idgmerr/s` in the EDEV/UDP error view = nothing listening, or buffer overrun |
| `sar -n SOCK 1 5` | sockets in use, `tcp-tw` (TIME_WAIT), raw | `tcp-tw` in the tens of thousands = connection churn. `totsck` climbing and not falling = leak |
| `sar -n NFS 1 5` | NFS **client**: calls, retrans, read/write | `retrans` climbing = NFS server or the network to it |
| `sar -n NFSD 1 5` | NFS **server** (only if this host exports) | thread bottleneck: packets dropped while nfsd is busy |
| `sar -m CPU 1 5` | CPU frequency (if the kernel exports it) | MHz far below nominal = power saving or thermal throttle |
| `sar -m TEMP 1 5` | temperatures, when sensors are wired into sysstat | often empty on VMs. Use `sensors` or iLO for hardware |
| `sar -y 1 5` | TTY activity | only useful for a serial-console flood |
| `sar -A` | all of the above | `[LOAD]` on a busy multi-NIC, multi-disk host. Narrow with `-s` and `-e` |

Match a `sar -d` device to a disk:

```bash
lsblk -o NAME,KNAME,SIZE,TYPE,MOUNTPOINT,MODEL
# dev8-16 means major 8 minor 16; ls -l /dev | awk '$5=="8," && $6=="16"'
```

---

<a id="aix-sar"></a>
## 3. AIX `sar`

Not the same binary. Installed with the accounting/perf filesets. If `sar` is not found, use `vmstat`, `iostat` and `lparstat` (Section 4). AIX has **no** `sar -n`, `sar -S`, `sar -W`, `sar -B`.

History, **only if** `sa1`/`sa2` cron is already enabled: binary `/var/adm/sa/saDD`, text report `/var/adm/sa/sarDD`.

```bash
sar -u 1 5
sar -u -s 09:00:00 -e 10:00:00 -f /var/adm/sa/sa30
sar -A -s 09:00:00 -e 09:05:00           # [LOAD] short window only
```

`sar -o /tmp/sa.bin 1 5` writes a file. Do not use it for a check. Do not enable system accounting in the middle of an incident.

| Command | What it reports | Read this |
|---------|-----------------|-----------|
| `sar -u 1 5` | `%usr %sys %wio %idle` (newer AIX also `%steal`) | `%wio` = I/O wait. `%steal` on a micropartition = the shared pool is busy. `%idle` 0 = CPU cap |
| `sar -P ALL 1 5` | per logical CPU | one CPU at 100% = single thread. Also compare with `lparstat` entitlement |
| `sar -q 1 5` | `runq-sz` `%runocc` `swpq-sz` `%swpocc` | `runq-sz` > number of logical CPUs = need more CPU. **`swpq-sz` > 0 = threads waiting on paging. Bad** |
| `sar -r 1 5` | **paging**, not free memory: `slots`, `cycle/s`, `fault/s`, `odio/s` | non-zero `cycle/s` together with `lsps` filling = memory shortage. For free memory use `vmstat` column `fre` |
| `sar -d 1 5` | per hdisk: `%busy` `avque` `r+w/s` `Kbs/s` `avwait` `avserv` | `%busy` near 100 and `avwait` high = queueing on that hdisk. **`avserv` high (tens of ms on flash) = the array or path is slow** |
| `sar -b 1 5` | buffer cache: bread, lread, `%rcache`, bwrit, `%wcache` | `%rcache` very low with high bread = poor read cache, lots of real disk reads |
| `sar -c 1 5` | syscalls: `scall/s` `sread/s` `swrit/s` `fork/s` `exec/s` | `fork/s` high = a script spawning processes in a loop (often a health-check script) |
| `sar -w 1 5` | context switches `cswch/s`, plus pswch | same meaning as Linux `sar -w` |
| `sar -v 1 5` | kernel tables `proc-sz` `inod-sz` `file-sz` `thrd-sz` as used/max | **`file-sz` or `proc-sz` near the max** = "too many open files" / "cannot fork". The max is a tunable (`lsattr -El sys0`) |
| `sar -y 1 5` | TTY characters in/out | a console flood |
| `sar -a 1 5` | file-name lookups: `iget/s` `namei/s` `dirbk/s` | `dirbk/s` high = directories with a huge number of files (find/backup/mail queue) |
| `sar -m 1 5` | IPC: `msg/s` `sema/s` | only when an app is stuck on semaphores or message queues |
| `sar -k 1 5` | kernel process creation | rarely the first place to look |
| `sar -A` | all of the above | `[LOAD]` |

Paging space and memory (sar will not show these):

```bash
lsps -a                                  # %Used per paging space. Over ~80% is dangerous
lsps -s                                  # total
vmstat -s | egrep 'page|scan|steal'      # lifetime counters, not a rate
svmon -G -O unit=GB                      # [LOAD] in-use / pin / virtual / pg space
```

---

<a id="cpu-mem-disk"></a>
## 4. CPU, memory and disk (when sar is not enough)

### Linux — which process

```bash
ps aux --sort=-%cpu | head -15
ps aux --sort=-%mem | head -15
ps -eo pid,stat,wchan:25,cmd | awk '$2 ~ /D/'     # D state = stuck in I/O
pidstat -u 1 5                           # per-process CPU
pidstat -r 1 5                           # per-process RSS and faults
pidstat -d 1 5                           # per-process disk kB/s
pidstat -w 1 5                           # per-process context switches
pidstat -p <pid> -u -r -d 1 5
iostat -xz 1 5                           # r_await / w_await split. aqu-sz high = deep queue
nfsiostat 1 3 2>/dev/null                # NFS mount latency, if nfs-utils is installed
cat /proc/pressure/{cpu,memory,io}       # PSI, RHEL 8+. 'some' avg10 over a few % = that resource is stalling
```

`iotop -oP -n 3` is `[LOAD]` and often not installed. `pidstat -d` covers the same need.

### AIX — which process, which hdisk

```bash
ps aux | sort -rn -k 3 | head -15        # %CPU
ps aux | sort -rn -k 4 | head -15        # %MEM
ps avx | head -20                        # PGIN column: page-ins per process
svmon -P -t 10 -O unit=MB                # [LOAD] top 10 memory consumers
iostat -D hdiskX 1 5                     # one suspect disk: avg serv, sqfull
iostat -aT 1 3                           # per adapter (fcs, vscsi)
lparstat -i | egrep 'Type|Mode|Entitled|Online Virtual|Online Memory|Desired'
filemon                                  # [CAUTION] turns trace ON until trcstop. Not a casual check
```

`sqfull` counting up on an hdisk means the AIX queue filled (`queue_depth` too low, or the array is not accepting I/O).

### Fibre path performance (both OS)

A full path is "up" and still slow. Health of the paths is in the other runbook (`multipath -ll`, `lspath`, `fcstat`). For **speed**:

- Linux: `iostat -x` on the `dm-` device and on the underlying `sd` devices. One `sd` much slower than its siblings = a bad path.
- AIX: `iostat -D` per hdisk, plus `fcstat fcsX` for rising `No DMA Resource` / `No Command Resource` (HBA queue exhausted).

---

<a id="linux-netstat"></a>
## 5. Linux `netstat` and `ss`

`netstat` is the `net-tools` package. On RHEL 8/9 it is often absent. Every line below has the `ss` / `ip` equivalent, which is what you should run.

`netstat` itself is query-only. It does not clear counters.

| netstat | ss / ip equivalent | What it tells you |
|---------|--------------------|-------------------|
| `netstat -s` | `nstat -as` | protocol totals since boot: retransmits, listen drops, buffer errors. See the note under the table |
| `netstat -st` | `nstat -as \| grep -i tcp` | TCP only: `segments retransmitted`, `resets sent`, `listen queue overflows` |
| `netstat -su` | `nstat -as \| grep -i udp` | UDP: `receive buffer errors` = the app is not reading fast enough |
| `netstat -i` | `ip -s link` | per-interface RX/TX bytes and errors |
| `netstat -ie` | `ip -s link ; ethtool <if>` | same, plus MTU and flags |
| `netstat -rn` | `ip r` | routing table. Default route present? |
| `netstat -r` | `ip r` | routes with names (slow if DNS is broken — prefer `-n`) |
| `netstat -an` | `ss -ant` | every socket, numeric. Look at state counts |
| `netstat -ant` | `ss -ant` | TCP only |
| `netstat -anu` | `ss -anu` | UDP only |
| `netstat -lntup` | `ss -lntup` | **listening** sockets and the process. "Is the port open on this host?" |
| `netstat -antp` | `ss -antp` | established connections with process. Needs root to see other users' process names |
| `netstat -tp` | `ss -tp` | established TCP only |
| `netstat -M` | `conntrack -S` (if conntrack-tools) | NAT table. Usually empty on an app server; relevant on a Linux firewall |
| `netstat -c` | `ss -s` in a loop | repaints every second. `[LOAD]` if you leave it running. Ctrl+C |

```bash
ss -s                                    # totals: TCP estab, closed, timewait, orphan
ss -ant | awk '{print $1}' | sort | uniq -c | sort -nr     # count by state
ss -lntup                                # listeners with pid
ss -antp dst = <ip>                      # connections to one destination
ss -ti dst = <ip>                        # [LOAD if many] RTT, retrans, cwnd per connection
ss -ltnp sport = :443                    # who owns 443
```

State names that matter:

| State | Means |
|-------|--------|
| `LISTEN` | service is up |
| `ESTAB` | working connection |
| `TIME-WAIT` / `TIME_WAIT` | local side closed; normal in volume after many short connections. Tens of thousands = churn, can exhaust ephemeral ports |
| `CLOSE-WAIT` | **the local app received a close and did not call close()**. App bug. Count grows = leak |
| `SYN-SENT` | we are calling out and nobody answers (wrong IP, firewall drop, remote down) |
| `SYN-RECV` | we are being called and the handshake is not finishing (SYN flood, or our reply is dropped) |
| `FIN-WAIT-1` / `FIN-WAIT-2` | waiting for the peer to finish closing. A pile of FIN-WAIT-2 = the other end is gone |
| `LAST-ACK` | we closed, waiting for the last ACK |

`nstat` note: `nstat -as` prints absolute counters and does not reset kernel counters. Plain `nstat` also **writes a history file** so the next run shows a delta. Do not use `nstat -r` during an incident (it resets that history). Kernel counters are not cleared by this.

Listen-queue overflows (service too slow to accept):

```bash
nstat -as | egrep -i 'ListenDrops|ListenOverflows|TCPRetransSegs|TCPAbort|TCPRcvQDrop'
```

Retransmits climbing between two samples, taken a minute apart, mean loss **right now**. A large lifetime total only means "it happened sometime since boot".

---

<a id="aix-netstat"></a>
## 6. AIX `netstat`

Query-only, except **`netstat -Z`, which zeroes the protocol statistics**. Never run `-Z` during an incident.

| Command | What it tells you |
|---------|-------------------|
| `netstat -in` | all interfaces: MTU, packets, **Ierrs Oerrs Coll**. Errors climbing = physical or driver |
| `netstat -i` | same, names resolved. Avoid if DNS is sick |
| `netstat -I en0` | one interface since boot |
| `netstat -I en0 1 5` | one interface, per-second rate. This is the AIX replacement for `sar -n DEV` |
| `netstat -rn` | routing table, numeric. `default` via the gateway you expect. Watch for two defaults |
| `netstat -r` | routes with names. Hangs if DNS is down |
| `netstat -an` | all sockets, numeric |
| `netstat -an \| grep LISTEN` | listeners. Match against Section 7 |
| `netstat -an \| grep ESTABLISHED \| wc -l` | how many live TCP sessions |
| `netstat -an \| awk '{print $6}' \| sort \| uniq -c \| sort -nr` | count by TCP state. Same meanings as the Linux table |
| `netstat -s` | protocol statistics since boot |
| `netstat -p tcp` | TCP detail. Look for `packets retransmitted`, `connections established`, `dropped` |
| `netstat -p udp` | UDP drops: `socket buffer overflows` |
| `netstat -p ip` | IP forwarding, fragments |
| `netstat -p icmp` | unreachables, time exceeded |
| `netstat -D` | data-link counters per protocol since boot (dropped at each layer) |
| `netstat -m` | **mbuf / network memory**. `failed` column must be 0. Non-zero = packets dropped because the network memory pool was exhausted |
| `netstat -v en0` | `[LOAD]` full adapter statistics. Long. Prefer `entstat -d ent0` for errors and link speed |
| `netstat -f inet` | IPv4 sockets only |
| `netstat -f inet6` | IPv6 sockets only |
| `netstat -na -A` | includes the PCB address, for `kdb`/`crash` work. Not needed for a normal check |

```bash
entstat -d ent0 | egrep -i 'Link Status|Media Speed|Packets:|Errors:|CRC|No Resource|Hypervisor'
# "No Resource Errors" climbing = the adapter queue is too small for the traffic
# Link Status Down, or Media Speed at Half Duplex = physical problem
```

Sample twice, a minute apart, before blaming a counter. Lifetimes since boot are not a rate.

```bash
netstat -p tcp | egrep -i 'retransmitted|reset|dropped|initiated|established'
```

---

<a id="ports"></a>
## 7. Major ports

Use this to answer "should anything be listening?" and "what did we just lose?". Ports are TCP unless noted. Many of these are **management** ports: if they are closed, the host can still be serving the application.

Check locally (no packets sent):

```bash
# Linux
ss -lntup | grep -E ':22 |:443 |:54321 '

# AIX
netstat -an | grep LISTEN | grep -E '\.22 |\.443 '
```

Check from outside `[PROBE]`:

```bash
nc -zv -w 3 <host> <port>                # Linux
telnet <host> <port>                     # AIX. Ctrl+] then quit. A refused vs a hang tells you firewall vs host down
```

<a id="ports-os"></a>
### Operating system and identity

| Port | Proto | What | Failure looks like |
|------|-------|------|--------------------|
| 22 | TCP | SSH | no login, no scp, no HMC vterm fallback, no OLVM host deploy |
| 23 | TCP | Telnet | legacy on switches and old iLO. Should normally be **disabled** |
| 53 | TCP+UDP | DNS | slow logins, "host not found", 5 s hangs. Always test both DNS servers |
| 88 | TCP+UDP | Kerberos | AD password logins fail, NFS with sec=krb5 fails |
| 123 | UDP | NTP | time drift, then Kerberos, clusters and certificates fail |
| 389 | TCP | LDAP | AD/LDAP lookups fail |
| 636 | TCP | LDAPS | same, over TLS |
| 445 | TCP | SMB / CIFS | Windows shares, NetApp CIFS |
| 464 | TCP+UDP | Kerberos password change | password updates fail, logins still work |
| 636 / 3269 | TCP | LDAPS / Global Catalog SSL | cross-domain AD lookups |
| 3268 | TCP | AD Global Catalog | cross-domain group membership |
| 514 | UDP, or TCP 514/6514 | syslog / syslog-tls | logs stop arriving. The app is still up |
| 161 | UDP | SNMP poll | monitoring shows the device down when it is not |
| 162 | UDP | SNMP traps | alerts never leave the device |
| 25 / 587 | TCP | SMTP | app mail and root's cron output queue up and can fill `/var` |

<a id="ports-storage"></a>
### Storage, filesystems, clusters

| Port | Proto | What | Failure looks like |
|------|-------|------|--------------------|
| 111 | TCP+UDP | rpcbind | NFS mount hangs or "program not registered" |
| 2049 | TCP+UDP | NFS | mounts stale, `df` and `ls` hang on the mount |
| 20048 | TCP+UDP | NFS mountd (common; it is configurable) | new mounts fail, existing ones stay up |
| 3260 | TCP | iSCSI | paths to an iSCSI array drop |
| 2224 | TCP | pcsd (RHEL HA) | `pcs status` from another node fails |
| 5405 | UDP | corosync | cluster nodes see each other as offline, fencing risk |
| 21064 | TCP | DLM | clvmd / GFS2 locks stall |
| 16191 | TCP+UDP | PowerHA CAA `clcomd` | cluster commands fail between nodes |
| 6181 | TCP | CAA config daemon | CAA membership / config sync fails |
| 4098 | UDP | CAA multicast heartbeat | nodes declare each other down on a multicast cluster |
| 42112 | TCP | CAA cluster socket | CAA traffic blocked, split-brain risk |

<a id="ports-olvm"></a>
### OLVM / KVM

Oracle's firewall table. Defaults; your `engine-setup` may have moved a few.

| Port | Proto | Where | What |
|------|-------|-------|------|
| 80, 443 | TCP | Engine | Admin Portal, VM Portal, API. 80 only redirects |
| 2222 | TCP | Engine | VM serial console |
| 5432 | TCP | Engine | PostgreSQL for engine and DWH. Usually local only. **Do not expose it** |
| 6100 | TCP | Engine | noVNC / HTML5 console websocket |
| 54323 | TCP | Engine | image upload (ovirt-imageio proxy) |
| 7410 | UDP | Engine | fence_kdump listener |
| 54321 | TCP | KVM host | VDSM. Engine marks the host NonResponsive if this is blocked |
| 54322 | TCP | KVM host | image I/O on the host |
| 16514 | TCP | KVM host | libvirt migration |
| 49152–49216 | TCP | KVM host | VDSM migration and fencing |
| 5900–6923 | TCP | KVM host | SPICE / VNC guest consoles |
| 2223 | TCP | KVM host | host side of VM serial console |
| 9090 | TCP | KVM host | Cockpit, if you installed it |
| 6081 | UDP | KVM host | OVN tunnel, if OVN is enabled |

<a id="ports-hw"></a>
### Hardware management and fabric

| Port | Proto | What |
|------|-------|------|
| 443 | TCP | iLO, OA, Virtual Connect, OneView, HMC, ASMI, array GUIs, switch GUIs, firewall GUIs |
| 22 | TCP | SSH on iLO, OA, HMC, Brocade, MDS, arrays, VIOS |
| 80 | TCP | usually a redirect to 443. If 443 is down and 80 answers, you only get the redirect page |
| 623 | UDP | IPMI. `ipmitool` from the OS, and some fencing |
| 17988 | TCP | iLO virtual media and remote console |
| 161 | UDP | SNMP on OA, switches, arrays |

Array and switch **data** ports are Fibre Channel, not TCP. A closed TCP 22 on a Brocade switch does not mean the fabric is down. Check `switchshow` / host `multipath` for that.

<a id="ports-fw"></a>
### Firewalls (management, not the traffic they pass)

| Port | Proto | What |
|------|-------|------|
| 443, 22 | TCP | PAN-OS, FortiGate, ASA/FTD management |
| 257 | TCP | Check Point log export |
| 18191 | TCP | Check Point CPD |
| 18210 | TCP | Check Point SIC (management to gateway) |
| 19009 | TCP | Check Point management API / SmartConsole |

Application ports (your DB, app server, load balancer VIP) are site-specific. The listening check in Section 5 is how you confirm the one in the ticket.

---

<a id="inodes"></a>
## 8. Is the disk full, or out of inodes?

These look the same from an application ("no space left") and they are fixed differently.

```bash
# Linux
df -hT                                   # Size / Used / Avail / Use% / Mounted on
df -i                                    # IUse% at 100% = too many files, even if df -h shows free space
# AIX
df -g                                    # GB. Look at %Used
df -k                                    # 1 KB blocks, if you need to be precise
```

A filesystem at 100% that is **full of tiny files** needs inode cleanup or more inodes, not deletion of one big file. A filesystem at 100% with low inode use needs the big-file hunt below.

On AIX, `df -i <fs>` prints used and free inodes where the flag exists. JFS2 allocates inodes dynamically, so "no space" with GB still free is often **fragmentation** (it cannot find a contiguous 16 KB extent), not a full inode table. Do not run `defragfs` during an S1.

Also check files that were deleted but are still held open (Section 10). `df` does not get the space back until the process closes them.

---

<a id="large-files"></a>
## 9. Find the large directories, then the large files

Drill down. Do not start with `find /`. Start at the filesystem `df` says is full, and do not cross onto other filesystems.

### Linux

```bash
du -xh -d 1 /var 2>/dev/null | sort -h            # [LOAD] biggest directories directly under /var
du -xh -d 1 /var/log 2>/dev/null | sort -h        # then the winner, and so on
du -xh -d 1 / 2>/dev/null | sort -h               # only if you do not yet know which filesystem

# files larger than 500 MB on this filesystem, biggest last
find /var -xdev -type f -size +500M -printf '%s\t%p\n' 2>/dev/null | sort -n | tail -30 \
  | awk '{printf "%8.1f GB  %s\n", $1/1024/1024/1024, $2}'

# a directory with millions of small files (inode problem)
du -x --inodes -d 1 /var 2>/dev/null | sort -n | tail
find /var/spool -xdev -type f 2>/dev/null | wc -l
```

`-x` / `-xdev` means "do not wander into other mounts". Without it, `du /` also walks every NFS share and can hang.

### AIX

`du` defaults to **512-byte blocks**. Always pass `-m` or `-g`. `find -size` is also **512-byte blocks**, and AIX `find` has no `-printf`.

```bash
du -smx /var/* 2>/dev/null | sort -n | tail -20    # [LOAD] MB, this filesystem only, biggest last
du -smx /var/log/* 2>/dev/null | sort -n | tail -20
du -gx /var                                     # one number, GB, for the whole tree

# bigger than 512 MB: 512 MB / 512 bytes = 1048576 blocks
find /var -xdev -type f -size +1048576 -ls 2>/dev/null | sort -n -k7 | tail -30
# bigger than 1 GB: use -size +2097152
```

The size in `find -ls` output is the 7th field. If the sort looks wrong, read the size off the line yourself.

<a id="usual-fillers"></a>
### What you usually find

| Path | What it is | Delete? |
|------|------------|---------|
| `/var/log/*.gz`, `/var/log/*-YYYYMMDD` | rotated logs | old ones, yes, after you keep what the case needs |
| `/var/log/messages`, `secure`, `cron`, `maillog` (the file with **no** date) | the **live** log | do not `rm` it. Truncate. Section 11 |
| `/var/log/journal` | systemd journal | `journalctl --vacuum-*`, not `rm -rf` |
| `/var/log/audit/audit.log` | audit trail | only with security agreement. Often a compliance file |
| `/var/crash`, `/var/log/dump` | kernel crash dumps | only after the dump has been copied off for the case |
| `/var/lib/systemd/coredump`, `core.*` under app dirs | process cores | yes if the case does not need the core |
| `/var/tmp`, `/tmp` | scratch | only files you can identify, and not files from today |
| `/var/spool/clientmqueue`, `/var/spool/mqueue` | stuck mail | yes if cron has been mailing a giant error for weeks |
| `/var/log/ovirt-engine` | OLVM engine logs | old rotated files. Do not touch `/var/lib/pgsql` |
| `/var/log/vdsm`, `/var/log/sanlock` | host logs | old rotated files |
| `/var/cache/dnf`, `/var/cache/yum` | package cache | `dnf clean all` is safe to free space. It only removes caches |
| AIX `/var/adm/wtmp`, `sulog`, `failedlogin` | login records | truncate only after you accept the history is gone |
| AIX `/tmp/ibmsupt` | leftover `snap` | yes, once the snap has been copied off |
| AIX `/var/adm/ras/trcfile` | a trace left running | stop the trace first (`trcstop`), then the file stops growing |
| `/var/lib/pgsql`, `pg_wal`, `/var/lib/mysql`, any `datavg` | database data | **never delete files here to free space** |
| `/boot` | kernels | do not hand-delete. Old kernels go through the package tool, later, not during an S1 |
| `/` itself when only one filesystem is 100% | a file in an app directory | find the file. Do not wipe a directory |

---

<a id="deleted-open"></a>
## 10. Space held by deleted files

`rm` unlinks the name. The bytes stay until every process that has the file open exits. `df` does not move until then.

### Linux

```bash
lsof -nP +L1 2>/dev/null | head -50      # [LOAD] files with a link count of 0 (deleted) still held open
```

The `PID` column is who to restart **after** you decide a restart is acceptable. Restarting a database or a cluster service to free a log is a `[CAUTION]` action, not a disk cleanup.

### AIX

```bash
fuser -dV /var 2>/dev/null               # deleted files still open on this filesystem, with pid
```

---

<a id="delete"></a>
## 11. How to delete — without making the incident worse

`[CAUTION]` every command in this section removes data. There is no undo.

Order:

1. Confirm the filesystem from `df`, and that the file is on it (`df /full/path/file`).
2. Copy evidence off the box **before** you truncate a live log. Copy the tail, not the whole multi-GB file, and not onto the filesystem that is already full.

```bash
tail -n 20000 /var/log/messages > /tmp/messages.tail     # only if /tmp is a DIFFERENT filesystem with room
# or, from your laptop, so nothing extra lands on the full box:
# scp <host>:/var/log/messages ./messages.partial   is wrong for a 50 GB file.
# Instead, on the host: tail -n 20000 /var/log/messages
# and save the SSH session scrollback, or:
tail -n 20000 /var/log/messages | ssh <your-admin-host> 'cat > /safe/path/messages.tail'
```

3. See whether it is open.

```bash
# Linux
lsof -nP /var/log/messages
fuser -v /var/log/messages
# AIX
fuser -u /var/adm/wtmp
```

4. Delete in one of these two ways. Nothing else.

**Live file a daemon has open** (current log, wtmp). Truncate. The process keeps writing to the same inode and `df` drops immediately.

```bash
# Linux
truncate -s 0 /var/log/messages
# or, if truncate is missing:
: > /var/log/messages

# AIX has no truncate command
cat /dev/null > /var/adm/wtmp
```

**Old rotated file nobody has open** (`messages-20240101.gz`, `core.1234`, a file in `/tmp` from last month). Remove that file only.

```bash
ls -lh /var/log/messages-20240101.gz
rm -i /var/log/messages-20240101.gz      # -i asks before each file. Keep it
```

5. `df` the same filesystem again. If the number did not move, the file is still held open (Section 10).

<a id="delete-journal"></a>
### Journal, package cache, old tmp

```bash
journalctl --disk-usage
journalctl --vacuum-size=500M            # [CAUTION] deletes archived journals until total is about 500 MB
journalctl --vacuum-time=7d              # [CAUTION] deletes journals older than 7 days

dnf clean all                            # [CAUTION] only package caches. Safe for space. RHEL 7: yum clean all

# preview, then delete. Read the list before the rm.
find /var/tmp -xdev -type f -mtime +14 -ls
find /var/tmp -xdev -type f -mtime +14 -exec rm -f {} +     # [CAUTION] AIX and Linux both accept -exec. Do not use find -delete
```

Do not run `logrotate -f /etc/logrotate.conf` during an S1. Post-rotate scripts in that file restart services.

<a id="delete-never"></a>
### Do not run these

- `rm -rf /var/log`, `rm -rf /tmp/*`, `rm -rf /var/tmp/*`
- `rm` of a variable or a glob you have not printed first (`rm -rf $DIR/*` when `DIR` is empty becomes `rm -rf /*`)
- `find / -delete` or any `find` that starts at `/` and deletes
- Deleting files under a database directory, `/boot`, `/usr`, `/opt/<product>/data`, cluster repository disks
- `errclear`, `netstat -Z`, clearing audit logs, or removing `/var/crash` before the case has a copy
- `fsck` on a filesystem that is still mounted

<a id="delete-aix"></a>
### AIX extras

```bash
# wtmp can grow for years and is not rotated on many systems
ls -lh /var/adm/wtmp /var/adm/sulog /var/adm/ras/errlog
cat /dev/null > /var/adm/wtmp            # [CAUTION] login history gone

# errlog is a circular file of fixed size. Do not rm it.
# A dump device (sysdumpdev -l) is not a file. Do not rm the LV under it.
# Snap leftovers, after the pax has been copied off:
du -smx /tmp/ibmsupt
rm -rf /tmp/ibmsupt                      # [CAUTION] only this directory, only after the copy
```

### Afterward

- `df` shows space returned.
- The application that was failing writes again (touch a test file as the app user if you can).
- If a process still holds a deleted file and you cannot restart it, say so in the case. The space comes back at the next planned restart.
- Put the log rotation gap on the problem record: a filesystem filled because `logrotate` was not covering that file. Fixing rotation is the permanent action, done after the incident, not by deleting more.
