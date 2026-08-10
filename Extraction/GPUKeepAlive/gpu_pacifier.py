#!/usr/bin/env python
r"""GPU keep-alive "pacifier" for the RTX 5070 idle bus-drop.

WHY THIS EXISTS
  The offline extraction pipeline runs the GPU in short per-trigger bursts, each
  in its own subprocess that EXITS when done:
      extractRAW_NPXLS.m
        -> runKilosort4.py        (GPU subprocess, exits)
        -> extractRAW_rtSort.m -> runRTSort.py   (GPU subprocess, exits)
        -> LFP filter / sync / save / zip / cloud copy   (CPU+disk, GPU IDLE)
  Between those bursts the GPU has no work AND no resident context, so the
  hardware descends to P8 / PCIe L1 / Gen1 and (on this chipset slot) can fall
  off the bus -> TDR / hard hang.

  This process runs ALONGSIDE the batch and keeps the GPU awake with:
    - continuous small matmuls          -> holds the CORE off P8, and
    - a periodic host<->device transfer -> holds the LINK in L0 (out of L1/Gen1);
      link power management responds to bus TRANSACTIONS, not GPU compute, so the
      matmul alone is not enough (proven: matmul-only left it at P8/Gen1).
  It is a WORKAROUND for a hardware fragility, not a fix for a code defect.

LIFECYCLE / IDEMPOTENCY
  On start it writes its PID to --pidfile and refuses to start a second copy if a
  live one is already recorded there (so calling start twice is safe). On exit it
  removes the pidfile. `--stop` reads the pidfile and kills the running instance.
  extractRAW_NPXLS.m starts it before the session loop and stops it via onCleanup
  (fires on any exit, including error), so it tracks the extraction run exactly.

USAGE  (nexus env)
  start:  python gpu_pacifier.py
  stop :  python gpu_pacifier.py --stop
"""
import argparse
import ctypes
import os
import signal
import subprocess
import sys
import time

# Runtime artifacts (pid + logs) live with the other TDR diagnostics, NOT in the
# repo, so the working tree stays clean. Change here if that folder moves.
DEFAULT_PIDFILE = r"C:\Users\Primus\gpu-tdr-diag\pacifier.pid"
_STILL_ACTIVE = 259


def _pid_alive(pid):
    """Windows-safe liveness check without external deps."""
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
    pid = _read_pid(pidfile)
    if pid and _pid_alive(pid):
        subprocess.run(["taskkill", "/PID", str(pid), "/F"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(f"[pacifier] stopped PID {pid}", flush=True)
    else:
        print("[pacifier] no live instance to stop", flush=True)
    try:
        os.remove(pidfile)
    except OSError:
        pass


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--stop", action="store_true", help="stop the running pacifier and exit")
    ap.add_argument("--pidfile", default=DEFAULT_PIDFILE)
    ap.add_argument("--interval", type=float, default=0.05, help="seconds between pulses")
    ap.add_argument("--size", type=int, default=2048, help="square matmul dimension")
    ap.add_argument("--iters", type=int, default=10, help="matmuls per pulse")
    ap.add_argument("--transfer-mb", type=float, default=8.0,
                    help="host<->device round-trip per pulse (MB) to keep the PCIe LINK out of L1/Gen1")
    ap.add_argument("--heartbeat", type=float, default=60.0, help="seconds between status prints")
    args = ap.parse_args()

    if args.stop:
        _stop(args.pidfile)
        return

    # idempotency guard: don't stack duplicate pacifiers
    existing = _read_pid(args.pidfile)
    if existing and _pid_alive(existing):
        print(f"[pacifier] already running (PID {existing}); not starting another.", flush=True)
        return

    import torch
    if not torch.cuda.is_available():
        print("[pacifier] FATAL: CUDA not available; nothing to keep awake.", flush=True)
        sys.exit(1)

    with open(args.pidfile, "w") as fh:
        fh.write(str(os.getpid()))

    dev = torch.device("cuda:0")
    name = torch.cuda.get_device_name(0)
    a = torch.randn(args.size, args.size, device=dev)
    b = torch.randn(args.size, args.size, device=dev)
    n_elems = max(1, int(args.transfer_mb * 1024 * 1024) // 4)
    host = torch.empty(n_elems, dtype=torch.float32, pin_memory=True)
    print(f"[pacifier] holding {name} awake: {args.iters} x {args.size}^2 matmul + "
          f"{args.transfer_mb:g}MB H2D/D2H every {args.interval}s (PID {os.getpid()}, "
          f"torch {torch.__version__})", flush=True)

    stop = {"now": False}
    def _sig(*_):
        stop["now"] = True
    signal.signal(signal.SIGINT, _sig)
    try:
        signal.signal(signal.SIGTERM, _sig)
    except Exception:
        pass

    pulses = 0
    t_last = time.time()
    try:
        while not stop["now"]:
            # tanh keeps values bounded in [-1, 1] so the running product never
            # overflows over long runs; the kernels still exercise the GPU.
            for _ in range(args.iters):
                b = torch.tanh(a @ b)
            # round-trip the pinned buffer for real PCIe traffic (link -> L0).
            _ = host.to(dev, non_blocking=True).add_(1.0).cpu()
            torch.cuda.synchronize()      # force the kernels to actually execute
            pulses += 1
            now = time.time()
            if now - t_last >= args.heartbeat:
                mib = torch.cuda.memory_allocated(0) // (1024 * 1024)
                print(f"[pacifier] alive: {pulses} pulses, mem={mib}MiB @ "
                      f"{time.strftime('%H:%M:%S')}", flush=True)
                t_last = now
            time.sleep(args.interval)
    finally:
        # only remove the pidfile if it's still ours
        if _read_pid(args.pidfile) == os.getpid():
            try:
                os.remove(args.pidfile)
            except OSError:
                pass
        print(f"[pacifier] stopping after {pulses} pulses; released GPU.", flush=True)


if __name__ == "__main__":
    main()
