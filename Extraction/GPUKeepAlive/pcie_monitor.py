#!/usr/bin/env python
r"""PCIe / DMI bandwidth monitor with optional competing-process intervention.

WHY THIS EXISTS
  The RTX 5070 sits in a chipset PCIe 3.0 x4 slot. ALL chipset devices—NVMe
  drives, the GPU, and the NIC—share the same DMI 3.0 x8 (~8 GB/s) link to
  the CPU. Under combined load (Kilosort VRAM loads + NVMe copy + NIC) that
  link can saturate and the GPU falls off the bus.

  This daemon samples GPU PCIe Rx/Tx (pynvml), per-drive disk I/O (win32pdh),
  and NIC throughput (psutil) every --interval seconds, logging to CSV and
  printing WARN/CRIT lines when estimated DMI load or GPU PCIe Rx exceed
  thresholds.

  With --intervene it runs a hysteresis threshold controller that suspends
  competing processes (default: robocopy) the moment gpu_pcie_rx crosses
  --suspend-threshold-mbs, and resumes them only after --calm-secs of sustained
  quiet below --calm-mbs.

USAGE  (nexus env)
  monitor only:
    python pcie_monitor.py [--drives E: X:]
  with intervention (overnight safe defaults):
    python pcie_monitor.py --intervene
                           [--suspend-threshold-mbs 700]
                           [--calm-mbs 300  --calm-secs 10]
                           [--suspend-names robocopy]
                           [--guard-pidfiles C:\...\pacifier.pid]
  stop:
    python pcie_monitor.py --stop

THRESHOLD RATIONALE (no calibration data required)
  pacifier baseline gpu_rx : ~200-600 MB/s  (H2D round-trips every 50 ms)
  Kilosort minimum gpu_rx  : ~1100 MB/s     (5.5 GB VRAM load in <5 s)
  --suspend-threshold-mbs  : 700            (margin above noise, below any GPU load)
  --calm-mbs               : 300            (above pacifier floor so CLEAR is reachable)
  --calm-secs              : 10             (Kilosort stays hot for >10 s; avoids flap)

  CONTROLLER STATES:
    CLEAR   → ACTIVE  : gpu_rx ≥ suspend_threshold (single sample, instant)
    ACTIVE  → CLEAR   : gpu_rx < calm_mbs for calm_secs consecutive samples

  Suspending robocopy mid-transfer is safe: Windows freezes the process threads;
  on resume the I/O continues from where it left off. robocopy's /R:2 /W:5 flags
  cover any retry needed if a file times out while frozen.

  Protected PIDs (--guard-pidfiles) are never touched. The monitor and pacifier
  PIDs are always auto-protected.

Logs: C:\Users\Primus\gpu-tdr-diag\pcie_log_YYYYMMDD_HHMMSS.csv
"""
import argparse
import ctypes
import os
import signal
import sys
import time
import warnings
from datetime import datetime

DEFAULT_PIDFILE        = r"C:\Users\Primus\gpu-tdr-diag\pcie_monitor.pid"
DEFAULT_LOGDIR         = r"C:\Users\Primus\gpu-tdr-diag"
DEFAULT_DRIVES         = ["E:", "X:"]
DEFAULT_INTERVAL       = 1.0
DEFAULT_WARN_DMI       = 4000    # MB/s
DEFAULT_CRIT_DMI       = 6000    # MB/s
DEFAULT_WARN_GPU_RX    = 2000    # MB/s
DEFAULT_SUSPEND_NAMES      = ["robocopy"]
DEFAULT_GUARD_PIDFILES     = [r"C:\Users\Primus\gpu-tdr-diag\pacifier.pid"]
DEFAULT_SUSPEND_THRESHOLD  = 900    # MB/s — pacifier max observed ~708; Kilosort min ~1100
DEFAULT_TRIGGER_SECS       = 2      # consecutive seconds above threshold before suspending
DEFAULT_CALM_MBS           = 650    # MB/s — above pacifier average so resume can complete
DEFAULT_CALM_SECS          = 10     # seconds below calm_mbs before resuming
_STILL_ACTIVE          = 259
PCIE_X4_GEN3_MBS       = 3500    # practical PCIe 3.0 x4 ceiling


# ── Windows process helpers ───────────────────────────────────────────────────

def _pid_alive(pid):
    PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
    h = ctypes.windll.kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pid)
    if not h:
        return False
    try:
        code = ctypes.c_ulong()
        ctypes.windll.kernel32.GetExitCodeProcess(h, ctypes.byref(code))
        return code.value == _STILL_ACTIVE
    finally:
        ctypes.windll.kernel32.CloseHandle(h)


def _read_pid(pidfile):
    try:
        with open(pidfile) as fh:
            return int(fh.read().strip())
    except (OSError, ValueError):
        return None


def _stop(pidfile):
    import subprocess
    pid = _read_pid(pidfile)
    if pid and _pid_alive(pid):
        subprocess.run(["taskkill", "/PID", str(pid), "/F"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(f"[pcie_monitor] stopped PID {pid}", flush=True)
    else:
        print("[pcie_monitor] no live instance found", flush=True)
    try:
        os.remove(pidfile)
    except OSError:
        pass


# ── Process suspension via ntdll ──────────────────────────────────────────────

class ProcessGuard:
    """Suspends/resumes competing processes by name when GPU Rx spikes.

    Uses NtSuspendProcess / NtResumeProcess (ntdll) — works for same-user
    processes without elevation. STATUS_SUCCESS = 0x00000000.
    """

    PROCESS_SUSPEND_RESUME = 0x0800

    def __init__(self, suspend_names, guard_pids, dry_run=False):
        self._names    = [n.lower() for n in suspend_names]
        self._guard    = set(guard_pids) | {os.getpid()}
        self._dry_run  = dry_run
        self._ntdll    = ctypes.windll.ntdll
        self._k32      = ctypes.windll.kernel32
        self._suspended = {}    # pid → name

    def _open(self, pid):
        h = self._k32.OpenProcess(self.PROCESS_SUSPEND_RESUME, False, pid)
        return h or None

    def _targets(self):
        import psutil
        out = []
        for p in psutil.process_iter(["pid", "name"]):
            pid  = p.info["pid"]
            name = (p.info["name"] or "").lower()
            if pid in self._guard or pid in self._suspended:
                continue
            if any(s in name for s in self._names):
                out.append((pid, p.info["name"]))
        return out

    def suspend(self):
        """Suspend all matching processes not already suspended or guarded."""
        for pid, name in self._targets():
            tag = "DRY-RUN suspend" if self._dry_run else "suspend"
            if not self._dry_run:
                h = self._open(pid)
                if h:
                    ok = self._ntdll.NtSuspendProcess(h) == 0
                    self._k32.CloseHandle(h)
                    if ok:
                        self._suspended[pid] = name
                    else:
                        print(f"[pcie_monitor] WARN: could not suspend PID {pid} ({name})",
                              flush=True)
                        continue
            else:
                self._suspended[pid] = name
            print(f"[pcie_monitor] {tag} PID {pid} ({name})", flush=True)

    def resume(self):
        """Resume all suspended processes."""
        for pid, name in list(self._suspended.items()):
            tag = "DRY-RUN resume" if self._dry_run else "resume"
            if not self._dry_run:
                h = self._open(pid)
                if h:
                    self._ntdll.NtResumeProcess(h)
                    self._k32.CloseHandle(h)
            print(f"[pcie_monitor] {tag} PID {pid} ({name})", flush=True)
            del self._suspended[pid]

    def resume_all_on_exit(self):
        """Safety net: always resume on exit so nothing stays frozen."""
        if self._suspended:
            print("[pcie_monitor] exit: resuming suspended processes...", flush=True)
            self.resume()

    @property
    def suspended_count(self):
        return len(self._suspended)


# ── Hysteresis threshold controller ──────────────────────────────────────────

class ThresholdController:
    """Two-state hysteresis controller for process suspension.

    CLEAR  → ACTIVE : gpu_rx ≥ suspend_threshold for trigger_secs consecutive samples
    ACTIVE → CLEAR  : gpu_rx < calm_mbs for calm_secs consecutive samples

    trigger_secs > 1 filters single-sample pacifier bursts (which are real but
    momentary) from sustained Kilosort loads (which hold for many seconds).
    calm_mbs should be set above the pacifier's typical oscillation floor so
    the ACTIVE→CLEAR transition can actually complete between Kilosort runs.
    """

    CLEAR  = "CLEAR"
    ACTIVE = "ACTIVE"

    def __init__(self, suspend_threshold, trigger_secs, calm_mbs, calm_secs, interval):
        self._threshold      = suspend_threshold
        self._trigger_needed = max(1, int(trigger_secs / interval))
        self._calm_mbs       = calm_mbs
        self._calm_needed    = max(1, int(calm_secs / interval))
        self._trigger_count  = 0
        self._calm_count     = 0
        self.state           = self.CLEAR

    def update(self, rx_mbs):
        """Returns (state, event) where event is 'suspend', 'resume', or None."""
        event = None
        if self.state == self.CLEAR:
            if rx_mbs >= self._threshold:
                self._trigger_count += 1
                if self._trigger_count >= self._trigger_needed:
                    self.state          = self.ACTIVE
                    self._trigger_count = 0
                    self._calm_count    = 0
                    event               = "suspend"
            else:
                self._trigger_count = 0   # burst didn't sustain — reset
        else:  # ACTIVE
            if rx_mbs < self._calm_mbs:
                self._calm_count += 1
                if self._calm_count >= self._calm_needed:
                    self.state       = self.CLEAR
                    self._calm_count = 0
                    event            = "resume"
            else:
                self._calm_count = 0
        return self.state, event


# ── Disk I/O via win32pdh (logical-disk counters by drive letter) ─────────────

class DiskCounters:
    def __init__(self, drives):
        import win32pdh
        self._pdh    = win32pdh
        self._query  = win32pdh.OpenQuery()
        self._ctrs   = {}
        self.active  = []
        for drv in drives:
            letter = drv.rstrip("\\:").upper()
            added  = False
            for rw in ("Read", "Write"):
                path = f"\\LogicalDisk({letter}:)\\Disk {rw} Bytes/sec"
                try:
                    h = win32pdh.AddCounter(self._query, path)
                    self._ctrs[f"{letter}_{rw.lower()}"] = h
                    added = True
                except Exception:
                    pass
            if added:
                self.active.append(letter)
        win32pdh.CollectQueryData(self._query)   # prime

    def sample(self):
        self._pdh.CollectQueryData(self._query)
        out = {}
        for key, h in self._ctrs.items():
            try:
                _, v = self._pdh.GetFormattedCounterValue(h, self._pdh.PDH_FMT_DOUBLE)
                out[key] = v / (1024 * 1024)
            except Exception:
                out[key] = 0.0
        return out


# ── NIC throughput via psutil ─────────────────────────────────────────────────

class NetCounters:
    def __init__(self):
        import psutil
        self._ps = psutil
        s = psutil.net_io_counters()
        self._rx, self._tx, self._t = s.bytes_recv, s.bytes_sent, time.monotonic()

    def sample(self):
        s  = self._ps.net_io_counters()
        t  = time.monotonic()
        dt = max(t - self._t, 1e-6)
        rx = max((s.bytes_recv - self._rx) / dt / (1024 * 1024), 0.0)
        tx = max((s.bytes_sent - self._tx) / dt / (1024 * 1024), 0.0)
        self._rx, self._tx, self._t = s.bytes_recv, s.bytes_sent, t
        return rx, tx


# ── GPU PCIe + power via pynvml ───────────────────────────────────────────────

class GPUCounters:
    def __init__(self):
        warnings.filterwarnings("ignore", category=FutureWarning)
        import pynvml
        pynvml.nvmlInit()
        self._n = pynvml
        self._h = pynvml.nvmlDeviceGetHandleByIndex(0)
        self.name = pynvml.nvmlDeviceGetName(self._h)
        self.vram_total_mib = pynvml.nvmlDeviceGetMemoryInfo(self._h).total // (1024 * 1024)

    def sample(self):
        """Returns (tx_mbs, rx_mbs, power_w, temp_c, vram_used_mib)."""
        n, h = self._n, self._h
        tx = n.nvmlDeviceGetPcieThroughput(h, n.NVML_PCIE_UTIL_TX_BYTES) / 1024
        rx = n.nvmlDeviceGetPcieThroughput(h, n.NVML_PCIE_UTIL_RX_BYTES) / 1024
        try:    pwr = n.nvmlDeviceGetPowerUsage(h) / 1000.0
        except: pwr = float("nan")
        try:    tmp = float(n.nvmlDeviceGetTemperature(h, 0))
        except: tmp = float("nan")
        vram = n.nvmlDeviceGetMemoryInfo(h).used // (1024 * 1024)
        return tx, rx, pwr, tmp, vram


# ── Main monitor loop ─────────────────────────────────────────────────────────

def run_monitor(args):
    os.makedirs(args.logdir, exist_ok=True)
    logpath = os.path.join(args.logdir, f"pcie_log_{datetime.now():%Y%m%d_%H%M%S}.csv")

    gpu  = GPUCounters()
    disk = DiskCounters(args.drives)
    net  = NetCounters()

    # Build guard pid set from pidfiles
    guard_pids = set()
    for pf in (args.guard_pidfiles or []):
        pid = _read_pid(pf)
        if pid:
            guard_pids.add(pid)

    guard      = (ProcessGuard(args.suspend_names, guard_pids, dry_run=args.dry_run)
                  if args.intervene else None)
    controller = (ThresholdController(args.suspend_threshold_mbs, args.trigger_secs,
                                      args.calm_mbs, args.calm_secs, args.interval)
                  if args.intervene else None)

    skipped = [d.rstrip("\\:").upper() for d in args.drives
               if d.rstrip("\\:").upper() not in disk.active]
    disk_col_names = [f"{drv}_{rw}_mbs"
                      for drv in disk.active for rw in ("read", "write")]

    header = ("timestamp,gpu_pcie_tx_mbs,gpu_pcie_rx_mbs,gpu_pcie_rx_pct,"
              "gpu_power_w,gpu_temp_c,gpu_vram_used_mib,gpu_vram_total_mib,"
              + ",".join(disk_col_names)
              + ",net_rx_mbs,net_tx_mbs,dmi_est_mbs,ctrl_state,level")

    with open(logpath, "w", buffering=1) as fh:
        fh.write(header + "\n")

        print(f"[pcie_monitor] {gpu.name}  vram={gpu.vram_total_mib} MiB", flush=True)
        print(f"[pcie_monitor] disk tracked={disk.active}  skipped={skipped}", flush=True)
        if args.intervene:
            mode = "DRY-RUN" if args.dry_run else "LIVE"
            print(f"[pcie_monitor] intervention {mode}: will suspend {args.suspend_names}  "
                  f"guard_pids={sorted(guard_pids)}  "
                  f"suspend if gpu_rx >= {args.suspend_threshold_mbs} MB/s "
                  f"for {args.trigger_secs}s  "
                  f"resume if < {args.calm_mbs} MB/s for {args.calm_secs}s", flush=True)
        print(f"[pcie_monitor] warn_gpu_rx>{args.warn_gpu_rx_mbs}  "
              f"warn_dmi>{args.warn_dmi_mbs}  crit_dmi>{args.crit_dmi_mbs}  "
              f"interval={args.interval}s", flush=True)
        print(f"[pcie_monitor] logging → {logpath}", flush=True)

        stop = {"now": False}
        def _sig(*_):
            stop["now"] = True
        signal.signal(signal.SIGINT, _sig)
        try:
            signal.signal(signal.SIGTERM, _sig)
        except Exception:
            pass

        n = 0
        try:
            while not stop["now"]:
                t0 = time.monotonic()

                gpu_tx, gpu_rx, pwr, tmp, vram = gpu.sample()
                disk_data = disk.sample()
                net_rx, net_tx = net.sample()

                dmi = gpu_tx + gpu_rx + net_rx + net_tx
                for drv in disk.active:
                    dmi += disk_data.get(f"{drv}_read", 0.0) + disk_data.get(f"{drv}_write", 0.0)

                rx_pct = gpu_rx / PCIE_X4_GEN3_MBS * 100

                ctrl_state = "OFF"
                if controller is not None:
                    ctrl_state, event = controller.update(gpu_rx)
                    if event == "suspend":
                        print(f"[pcie_monitor] SUSPEND — gpu_rx={gpu_rx:.0f} MB/s "
                              f">= {args.suspend_threshold_mbs} MB/s threshold  "
                              f"suspending: {args.suspend_names}", flush=True)
                        guard.suspend()
                    elif event == "resume":
                        print(f"[pcie_monitor] RESUME — gpu_rx={gpu_rx:.0f} MB/s  "
                              f"calm for {args.calm_secs}s  resuming processes", flush=True)
                        guard.resume()

                if dmi >= args.crit_dmi_mbs:
                    level = "CRIT"
                elif dmi >= args.warn_dmi_mbs or gpu_rx >= args.warn_gpu_rx_mbs:
                    level = "WARN"
                else:
                    level = ""

                ts = datetime.now().isoformat(timespec="seconds")
                disk_vals = ",".join(
                    f"{disk_data.get(f'{drv}_{rw}', 0.0):.1f}"
                    for drv in disk.active for rw in ("read", "write")
                )
                row = (f"{ts},{gpu_tx:.1f},{gpu_rx:.1f},{rx_pct:.1f},"
                       f"{pwr:.1f},{tmp:.0f},{vram},{gpu.vram_total_mib},"
                       f"{disk_vals},{net_rx:.1f},{net_tx:.1f},{dmi:.1f},{ctrl_state},{level}")
                fh.write(row + "\n")

                susp = f"  suspended={guard.suspended_count}" if guard else ""
                if level:
                    print(f"[pcie_monitor] {level} {ts}  "
                          f"gpu_rx={gpu_rx:.0f}({rx_pct:.0f}%)  "
                          f"dmi={dmi:.0f}MB/s  pwr={pwr:.0f}W  vram={vram}MiB{susp}",
                          flush=True)
                elif n % 60 == 0:
                    print(f"[pcie_monitor] {ts}  "
                          f"gpu_rx={gpu_rx:.0f}({rx_pct:.0f}%) gpu_tx={gpu_tx:.0f}  "
                          f"pwr={pwr:.0f}W  dmi={dmi:.0f}MB/s  vram={vram}MiB  "
                          f"ctrl={ctrl_state}{susp}",
                          flush=True)

                n += 1
                elapsed = time.monotonic() - t0
                rem = args.interval - elapsed
                if rem > 0:
                    time.sleep(rem)

        finally:
            if guard:
                guard.resume_all_on_exit()


def main():
    ap = argparse.ArgumentParser(description="PCIe/DMI bandwidth monitor")
    ap.add_argument("--stop",      action="store_true")
    ap.add_argument("--pidfile",   default=DEFAULT_PIDFILE)
    ap.add_argument("--logdir",    default=DEFAULT_LOGDIR)
    ap.add_argument("--drives",    nargs="+", default=DEFAULT_DRIVES)
    ap.add_argument("--interval",  type=float, default=DEFAULT_INTERVAL)
    ap.add_argument("--warn-dmi-mbs",    type=float, default=DEFAULT_WARN_DMI)
    ap.add_argument("--crit-dmi-mbs",    type=float, default=DEFAULT_CRIT_DMI)
    ap.add_argument("--warn-gpu-rx-mbs", type=float, default=DEFAULT_WARN_GPU_RX)
    # intervention
    ap.add_argument("--intervene",   action="store_true",
                    help="enable process suspension when GPU Rx crosses threshold")
    ap.add_argument("--dry-run",     action="store_true",
                    help="log what would be suspended/resumed without actually doing it")
    ap.add_argument("--suspend-names", nargs="+", default=DEFAULT_SUSPEND_NAMES,
                    help="process name substrings to suspend (case-insensitive)")
    ap.add_argument("--guard-pidfiles", nargs="+", default=DEFAULT_GUARD_PIDFILES,
                    help="pidfiles whose PIDs are protected from suspension")
    ap.add_argument("--suspend-threshold-mbs", type=float, default=DEFAULT_SUSPEND_THRESHOLD,
                    help="gpu_rx MB/s level that starts the suspend countdown "
                         "(default 900: above pacifier burst max ~708, below Kilosort min ~1100)")
    ap.add_argument("--trigger-secs", type=float, default=DEFAULT_TRIGGER_SECS,
                    help="consecutive seconds above threshold before actually suspending "
                         "(default 2: filters single-sample pacifier bursts)")
    ap.add_argument("--calm-mbs",  type=float, default=DEFAULT_CALM_MBS,
                    help="gpu_rx must fall below this to start the resume countdown "
                         "(default 650: above pacifier oscillation average so resume can complete)")
    ap.add_argument("--calm-secs", type=float, default=DEFAULT_CALM_SECS,
                    help="seconds below calm-mbs before suspended processes are resumed")
    ap.add_argument("--logfile",   default=None)
    args = ap.parse_args()

    if args.stop:
        _stop(args.pidfile)
        return

    if args.logfile:
        _log = open(args.logfile, "w", buffering=1)
        sys.stdout = _log
        sys.stderr = _log

    existing = _read_pid(args.pidfile)
    if existing and _pid_alive(existing):
        print(f"[pcie_monitor] already running (PID {existing}); not starting another.", flush=True)
        return

    with open(args.pidfile, "w") as fh:
        fh.write(str(os.getpid()))

    try:
        run_monitor(args)
    finally:
        if _read_pid(args.pidfile) == os.getpid():
            try:
                os.remove(args.pidfile)
            except OSError:
                pass
        print("[pcie_monitor] stopped.", flush=True)


if __name__ == "__main__":
    main()
