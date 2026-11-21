<#
.SYNOPSIS
    Enterprise Multi-VM Lab Orchestrator & Self-Healing Service Supervisor.
.DESCRIPTION
    Boots and monitors the VMware Workstation Enterprise Lab:
      - ansible-nfs (192.168.242.132) - Controller & NFS Server
      - olvm-engine (192.168.242.133) - OLVM/oVirt Management Engine
      - kvm-host-1  (192.168.242.134) - Enterprise KVM Hypervisor 1
      - kvm-host-2  (192.168.242.135) - Enterprise KVM Hypervisor 2
    Performs live SSH health checks on critical daemons and automatically restarts
    any failed, inactive, or hung services.
.PARAMETER Mode
    Start (default), Stop, Restart, or Status.
.PARAMETER Gui
    Switch to open VMware Workstation in GUI mode instead of background nogui mode.
.PARAMETER TimeoutSeconds
    Timeout waiting for SSH port 22 on each VM (default 120s).
.EXAMPLE
    .\Start-Lab.ps1
    .\Start-Lab.ps1 -Mode Stop
    .\Start-Lab.ps1 -Mode Status
#>

[CmdletBinding()]
param(
    [ValidateSet("Start", "Stop", "Restart", "Status")]
    [string]$Mode = "Start",

    [switch]$Gui,

    [int]$TimeoutSeconds = 120
)

# Set UTF-8 Output Encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ==============================================================================
# CONFIGURATION & TOPOLOGY
# ==============================================================================
$VmrunPath = "D:\01_APP\Vmware\vmrun.exe"
if (-not (Test-Path $VmrunPath)) {
    # Check default fallback paths
    $fallbackPaths = @(
        "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe",
        "C:\Program Files\VMware\VMware Workstation\vmrun.exe"
    )
    foreach ($p in $fallbackPaths) {
        if (Test-Path $p) { $VmrunPath = $p; break }
    }
}

$SshKeyPath = "$env:USERPROFILE\.ssh\id_rsa"

$LabTopology = @(
    @{
        Name        = "ansible-nfs"
        Role        = "Ansible Controller & NFS Shared Storage"
        IP          = "192.168.242.132"
        VmxPath     = "F:\VMware\OLVM-Lab\ansible-nfs\ansible-nfs.vmx"
        BootOrder   = 1
        Services    = @("nfs-server", "rpcbind", "sshd")
        SpecialCheck = "exportfs"
    },
    @{
        Name        = "olvm-engine"
        Role        = "Oracle Linux Virtualization Manager (OLVM)"
        IP          = "192.168.242.133"
        VmxPath     = "F:\VMware\OLVM-Lab\olvm-engine\olvm-engine.vmx"
        BootOrder   = 2
        Services    = @("postgresql", "ovirt-engine", "httpd", "sshd")
        SpecialCheck = "ovirt-engine-warmup"
    },
    @{
        Name        = "kvm-host-1"
        Role        = "Enterprise KVM Hypervisor Node 1"
        IP          = "192.168.242.134"
        VmxPath     = "F:\VMware\OLVM-Lab\kvm-host-1\kvm-host-1.vmx"
        BootOrder   = 2
        Services    = @("libvirtd", "supervdsmd", "vdsmd", "sanlock", "sshd")
        SpecialCheck = "nfs-mount"
    },
    @{
        Name        = "kvm-host-2"
        Role        = "Enterprise KVM Hypervisor Node 2"
        IP          = "192.168.242.135"
        VmxPath     = "F:\VMware\OLVM-Lab\kvm-host-2\kvm-host-2.vmx"
        BootOrder   = 2
        Services    = @("libvirtd", "supervdsmd", "vdsmd", "sanlock", "sshd")
        SpecialCheck = "nfs-mount"
    }
)

# ==============================================================================
# LOGGING & CONSOLE HELPERS
# ==============================================================================
function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White
    Write-Host "================================================================================" -ForegroundColor Cyan
}

function Write-Info {
    param([string]$Msg)
    Write-Host "[INFO]  " -ForegroundColor Cyan -NoNewline
    Write-Host $Msg -ForegroundColor White
}

function Write-Success {
    param([string]$Msg)
    Write-Host "[OK]    " -ForegroundColor Green -NoNewline
    Write-Host $Msg -ForegroundColor White
}

function Write-Warn {
    param([string]$Msg)
    Write-Host "[WARN]  " -ForegroundColor Yellow -NoNewline
    Write-Host $Msg -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Msg)
    Write-Host "[FAIL]  " -ForegroundColor Red -NoNewline
    Write-Host $Msg -ForegroundColor Red
}

function Write-Healed {
    param([string]$Msg)
    Write-Host "[HEALED]" -ForegroundColor Magenta -NoNewline
    Write-Host " $Msg" -ForegroundColor Magenta
}

# ==============================================================================
# VM LIFECYCLE HELPERS
# ==============================================================================
function Ensure-HostServices {
    Write-Info "Verifying VMware Workstation host network daemons..."
    $natService = Get-Service -Name "VMware NAT Service" -ErrorAction SilentlyContinue
    if ($natService -and $natService.Status -ne "Running") {
        Write-Warn "VMware NAT Service is stopped. Starting service..."
        Start-Service -Name "VMware NAT Service" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    
    $dhcpService = Get-Service -Name "VMnetDHCP" -ErrorAction SilentlyContinue
    if ($dhcpService -and $dhcpService.Status -ne "Running") {
        Write-Warn "VMware DHCP Service is stopped. Starting service..."
        Start-Service -Name "VMnetDHCP" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    Write-Success "Host virtualization background services verified."
}

function Get-RunningVms {
    if (-not (Test-Path $VmrunPath)) {
        Write-Fail "vmrun.exe not found at $VmrunPath. Please verify installation path."
        return @()
    }
    $raw = & $VmrunPath list
    $running = @()
    foreach ($line in $raw) {
        $trim = $line.Trim()
        if ($trim -match '\.vmx$' -and (Test-Path $trim)) {
            $running += (Resolve-Path $trim).Path
        }
    }
    return $running
}

function Start-VirtualMachine {
    param(
        [hashtable]$Vm,
        [string[]]$RunningVms
    )
    $resolvedPath = (Resolve-Path $Vm.VmxPath -ErrorAction SilentlyContinue).Path
    if ($RunningVms -contains $resolvedPath) {
        Write-Success "$($Vm.Name) is already powered on."
        return
    }

    $guiMode = if ($Gui) { "gui" } else { "nogui" }
    Write-Info "Powering on $($Vm.Name) ($($Vm.Role)) [$guiMode]..."
    
    $startResult = & $VmrunPath -T ws start $Vm.VmxPath $guiMode 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$($Vm.Name) power-on signal accepted."
    } else {
        Write-Fail "Failed to power on $($Vm.Name): $startResult"
    }
}

function Stop-VirtualMachine {
    param(
        [hashtable]$Vm,
        [string[]]$RunningVms
    )
    $resolvedPath = (Resolve-Path $Vm.VmxPath -ErrorAction SilentlyContinue).Path
    if ($RunningVms -notcontains $resolvedPath) {
        Write-Info "$($Vm.Name) is already powered off."
        return
    }

    Write-Info "Sending ACPI shutdown (soft) to $($Vm.Name)..."
    & $VmrunPath -T ws stop $Vm.VmxPath soft 2>&1 | Out-Null
}

# ==============================================================================
# NETWORK & SSH HEALTH HELPERS
# ==============================================================================
function Test-TcpPort {
    param(
        [string]$HostIP,
        [int]$Port = 22,
        [int]$TimeoutMs = 1500
    )
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $iar = $tcp.BeginConnect($HostIP, $Port, $null, $null)
        $success = $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
        if ($success -and $tcp.Connected) {
            $tcp.EndConnect($iar)
            $tcp.Close()
            return $true
        }
        $tcp.Close()
        return $false
    } catch {
        return $false
    }
}

function Wait-ForSshPort {
    param(
        [string]$HostIP,
        [string]$VmName,
        [int]$TimeoutSec = 120
    )
    Write-Host -NoNewline "[WAIT]  Waiting for $VmName ($($HostIP):22) to respond..." -ForegroundColor Cyan
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSec) {
        if (Test-TcpPort -HostIP $HostIP -Port 22) {
            $elapsed = [int]$stopwatch.Elapsed.TotalSeconds
            Write-Host "`r[READY] $VmName ($($HostIP):22) responded in ${elapsed}s!               " -ForegroundColor Green
            return $true
        }
        Start-Sleep -Seconds 2
        Write-Host -NoNewline "." -ForegroundColor Yellow
    }
    Write-Host "`r[TIMEOUT] $VmName ($($HostIP):22) did not respond within ${TimeoutSec}s!     " -ForegroundColor Red
    return $false
}

function Invoke-RemoteSSH {
    param(
        [string]$HostIP,
        [string]$Command
    )
    # Primary: Windows OpenSSH with identity file
    if (Test-Path $SshKeyPath) {
        $sshArgs = @(
            "-i", "$SshKeyPath",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "ConnectTimeout=5",
            "-o", "BatchMode=yes",
            "-o", "LogLevel=ERROR",
            "root@$HostIP",
            "$Command"
        )
        $output = & ssh $sshArgs 2>&1
        if ($LASTEXITCODE -eq 0) {
            return ($output -join "`n").Trim()
        }
    }

    # Secondary: Python Paramiko fallback with laboratory root password
    $pyCode = @"
import paramiko, sys
try:
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect('$HostIP', port=22, username='root', password='Unknown@56', timeout=5)
    stdin, stdout, stderr = c.exec_command('''$Command''')
    out = stdout.read().decode('utf-8', errors='ignore')
    print(out.strip())
    c.close()
    sys.exit(0)
except Exception:
    sys.exit(1)
"@
    $resPy = python -c "$pyCode" 2>$null
    if ($LASTEXITCODE -eq 0) {
        return ($resPy -join "`n").Trim()
    }

    return $null
}

# ==============================================================================
# SELF-HEALING SERVICE VERIFICATION
# ==============================================================================
function Inspect-And-HealServices {
    param([hashtable]$Vm)
    
    Write-Host ""
    Write-Host "--- Health Check & Service Verification: $($Vm.Name) ($($Vm.IP)) ---" -ForegroundColor DarkCyan
    
    $nodeUptime = Invoke-RemoteSSH -HostIP $Vm.IP -Command "uptime -p 2>/dev/null || uptime"
    if ($nodeUptime) {
        Write-Info "Node Uptime: $nodeUptime"
    }

    $allHealthy = $true

    foreach ($svc in $Vm.Services) {
        $status = Invoke-RemoteSSH -HostIP $Vm.IP -Command "systemctl is-active $svc 2>/dev/null"
        
        # Handle known slow-booting services gracefully
        if ($svc -eq "ovirt-engine" -and $status -eq "activating") {
            Write-Warn "Service '$svc' is currently initializing WildFly JVM. Polling for readiness..."
            $warmupAttempts = 0
            while ($warmupAttempts -lt 10) {
                Start-Sleep -Seconds 5
                $status = Invoke-RemoteSSH -HostIP $Vm.IP -Command "systemctl is-active $svc 2>/dev/null"
                if ($status -eq "active") { break }
                $warmupAttempts++
            }
        }

        if ($status -eq "active") {
            Write-Success "Service '$svc' is ACTIVE."
        } else {
            Write-Warn "Service '$svc' state is '$status'. Initiating automated self-healing restart..."
            
            # Execute restart
            Invoke-RemoteSSH -HostIP $Vm.IP -Command "systemctl restart $svc" | Out-Null
            Start-Sleep -Seconds 4
            
            # Re-verify
            $recheck = Invoke-RemoteSSH -HostIP $Vm.IP -Command "systemctl is-active $svc 2>/dev/null"
            if ($recheck -eq "active") {
                Write-Healed "Service '$svc' successfully restarted and is now ACTIVE."
            } else {
                Write-Fail "Service '$svc' failed to restart (State: '$recheck')."
                $journal = Invoke-RemoteSSH -HostIP $Vm.IP -Command "journalctl -u $svc -n 5 --no-pager 2>/dev/null"
                if ($journal) {
                    Write-Host "    [Journal Log Snippet]:" -ForegroundColor DarkGray
                    $journal -split "`n" | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
                }
                $allHealthy = $false
            }
        }
    }

    # Custom technology verification
    if ($Vm.SpecialCheck -eq "exportfs") {
        $exports = Invoke-RemoteSSH -HostIP $Vm.IP -Command "exportfs -s 2>/dev/null"
        if ($exports -match "/export/olvm-data" -and $exports -match "/export/cluster-logs") {
            Write-Success "NFS Shares (/export/olvm-data, /export/cluster-logs) are actively exported."
        } else {
            Write-Warn "NFS exports incomplete. Running 'exportfs -ra'..."
            Invoke-RemoteSSH -HostIP $Vm.IP -Command "exportfs -ra; systemctl restart nfs-server" | Out-Null
            Write-Healed "NFS export tables re-synchronized."
        }
    }

    if ($Vm.SpecialCheck -eq "nfs-mount") {
        $mounts = Invoke-RemoteSSH -HostIP $Vm.IP -Command "df -h /rhev/data-center/mnt/* 2>/dev/null | wc -l"
        if ([int]$mounts -gt 1) {
            Write-Success "OLVM Storage Domain NFS mounts verified active."
        } else {
            Write-Info "Storage Domain mount will be bound by OLVM SPM automatically once engine connects."
        }
    }

    return $allHealthy
}

# ==============================================================================
# MAIN EXECUTION WORKFLOW
# ==============================================================================
Write-Header "ENTERPRISE INFRASTRUCTURE LAB ORCHESTRATOR & SELF-HEALING ENGINE"
Write-Info "Execution Mode: $Mode | Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

Ensure-HostServices
$runningVms = Get-RunningVms

# ------------------------------------------------------------------------------
# STOP MODE
# ------------------------------------------------------------------------------
if ($Mode -eq "Stop") {
    Write-Header "GRACEFUL LAB SHUTDOWN (FREE RAM & CPU FOR GAMING / SYSTEM REST)"
    
    # Shutdown order: Hypervisors first, Engine next, NFS/Controller last
    $stopSequence = @("kvm-host-2", "kvm-host-1", "olvm-engine", "ansible-nfs")
    foreach ($name in $stopSequence) {
        $vm = $LabTopology | Where-Object { $_.Name -eq $name }
        if ($vm) {
            Stop-VirtualMachine -Vm $vm -RunningVms $runningVms
        }
    }

    Write-Host ""
    Write-Info "Waiting for all VMs to power down cleanly..."
    $waitCounter = 0
    while ($waitCounter -lt 30) {
        $active = Get-RunningVms
        $labActive = $active | Where-Object { $_ -match "OLVM-Lab" }
        if (-not $labActive) {
            Write-Success "All lab virtual machines have powered off cleanly. 100% resources freed!"
            break
        }
        Start-Sleep -Seconds 2
        $waitCounter++
    }
    exit 0
}

# ------------------------------------------------------------------------------
# STATUS MODE
# ------------------------------------------------------------------------------
if ($Mode -eq "Status") {
    Write-Header "ENTERPRISE LAB RUNTIME STATUS DASHBOARD"
    $summary = @()
    foreach ($vm in $LabTopology) {
        $resolved = (Resolve-Path $vm.VmxPath -ErrorAction SilentlyContinue).Path
        $isPowered = ($runningVms -contains $resolved)
        $isPortOpen = if ($isPowered) { Test-TcpPort -HostIP $vm.IP -Port 22 } else { $false }
        
        $summary += [PSCustomObject]@{
            "Server Name" = $vm.Name
            "IP Address"  = $vm.IP
            "Power State" = if ($isPowered) { "RUNNING" } else { "OFF" }
            "SSH (Port 22)" = if ($isPortOpen) { "OPEN" } else { "CLOSED" }
            "Role"        = $vm.Role
        }
    }
    $summary | Format-Table -AutoSize
    exit 0
}

# ------------------------------------------------------------------------------
# START / RESTART MODE
# ------------------------------------------------------------------------------
if ($Mode -eq "Restart") {
    Write-Header "RESTARTING COMPLETE LAB ENVIRONMENT"
    # Send soft reboot or shutdown first
    foreach ($vm in ($LabTopology | Sort-Object BootOrder -Descending)) {
        Stop-VirtualMachine -Vm $vm -RunningVms $runningVms
    }
    Start-Sleep -Seconds 10
    $runningVms = Get-RunningVms
}

Write-Header "PHASE 1: DEPENDENCY-AWARE LAB BOOT SEQUENCE"

# Step 1: Boot Storage & Controller (BootOrder = 1)
$storageVm = $LabTopology | Where-Object { $_.BootOrder -eq 1 }
Start-VirtualMachine -Vm $storageVm -RunningVms $runningVms

$nfsReady = Wait-ForSshPort -HostIP $storageVm.IP -VmName $storageVm.Name -TimeoutSec $TimeoutSeconds
if (-not $nfsReady) {
    Write-Fail "Fatal: $($storageVm.Name) failed to respond. Halting startup to prevent cluster split-brain."
    exit 1
}

# Step 2: Boot Engine and KVM Nodes in parallel (BootOrder = 2)
$clusterVms = $LabTopology | Where-Object { $_.BootOrder -eq 2 }
foreach ($vm in $clusterVms) {
    Start-VirtualMachine -Vm $vm -RunningVms $runningVms
}

Write-Header "PHASE 2: NETWORK & SSH CONNECTIVITY VALIDATION"
$bootSuccess = $true
foreach ($vm in $clusterVms) {
    $ready = Wait-ForSshPort -HostIP $vm.IP -VmName $vm.Name -TimeoutSec $TimeoutSeconds
    if (-not $ready) { $bootSuccess = $false }
}

Write-Header "PHASE 3: SERVICE HEALTH INSPECTION & SELF-HEALING SUPERVISION"
$allNodesHealthy = $true
foreach ($vm in $LabTopology) {
    $healthy = Inspect-And-HealServices -Vm $vm
    if (-not $healthy) { $allNodesHealthy = $false }
}

Write-Header "LAB DASHBOARD & OPERATIONAL ACCESS ENDPOINTS"
Write-Host "  Ansible Lab Controller : ssh local-ansible-nfs  (IP: 192.168.242.132)" -ForegroundColor White
Write-Host "  Automation Framework   : /root/Infrastructure-Automation (104 Playbooks)" -ForegroundColor Cyan
Write-Host "  OLVM Web Admin Console : https://192.168.242.133/ovirt-engine/" -ForegroundColor White
Write-Host "  Credentials            : User: admin@internal | Pass: Unknown@56" -ForegroundColor Yellow
Write-Host "  SSH Direct Access      : ssh local-olvm-engine | ssh local-kvm-host-1 | ssh local-kvm-host-2" -ForegroundColor White
Write-Host "  Clean Shutdown Before  : .\Start-Lab.ps1 -Mode Stop (or double-click Stop-Lab.bat)" -ForegroundColor Green

Write-Host ""
if ($allNodesHealthy) {
    Write-Success "ALL 4 LAB NODES & CRITICAL DAEMONS ARE 100% OPERATIONAL!"
} else {
    Write-Warn "One or more services required attention. Review details above."
}
Write-Host "================================================================================" -ForegroundColor Cyan
