# Extraction — Work In Progress

Running backlog of identified-but-deferred architecture work — ideas that came
up mid-conversation, got designed enough to be worth keeping, but were
explicitly held off rather than implemented immediately. Each entry should
carry enough context to pick up cold, without needing to re-derive the design.

Entry format: **Status**, **Context** (what prompted it), **Design**, **Touches**
(files/functions affected), **Depends on** (prerequisites that should land first).

---

## 1. Extraction-log writes are not atomic — header-clipping corruption

**Status:** Fixed for `write2Extrctn.m` (opt-in) and the two call sites that
were actually observed corrupting a log (`extractEXT.m`, `extractDTS.m`).
12 other files still write extraction logs the old, unsafe way — see
"Remaining exposure" below.

**Context:** Recurring bug — after multiple sessions of `extractEXT`/
`extractDTS`, an extraction log's CSV header would come back clipped/missing
entirely (`Unrecognized table variable name 'SessionName'`), breaking every
downstream consumer of that log. Traced to a read-modify-write pattern
repeated across the extraction codebase:
```matlab
extractionLog = readtable(logPath);
extractionLog(contains(extractionLog.SessionName, session), :).Extracted = 1;
writetable(extractionLog, logPath);
```
`writetable` truncates the destination file immediately and writes
progressively — it is not atomic. Anything that interrupts the write partway
(a crash, a timeout, a parallel pool tearing down mid-run, Ctrl+C) leaves the
file exactly as truncated/corrupted as observed. `extractEXT.m`/`extractDTS.m`
both call this once per successfully-extracted session inside a loop, so a
single run has many opportunities for an interruption to land mid-write.
`extractDTS.m` already had a defensive "header missing?" check that skips the
update when this has already happened — a band-aid for the symptom, not a fix
for the cause.

**Design — implemented:**
- `Extraction/Logging/writetableAtomic.m` (new): writes to a temp file in the
  *same directory* as the target, then `movefile`s it onto the real path. A
  same-filesystem `movefile`/rename is atomic at the OS level, so any reader
  always sees either the complete old file or the complete new one, never a
  partial write. The temp file must stay in the same directory — a system-temp
  round trip would cross filesystems (e.g. onto a network/cloud-mounted
  drive) and degrade to copy+delete, losing the atomicity guarantee.
- `Extraction/Logging/write2Extrctn.m`: new optional 5th arg `atomicWrite`
  (default `false`). Every existing caller is unaffected; nothing currently
  passes `true`.
- `extractEXT.m` / `extractDTS.m`: both have their own inline
  read-modify-write (neither goes through `write2Extrctn.m` — different
  target file, different value shape), so each was switched directly to call
  `writetableAtomic` instead of `writetable`.

**Remaining exposure:** the same unsafe `writetable(...)`-on-an-extraction-log
pattern is still present, unchanged, in 12 other files:
`Extraction/Logging/rewriteExtractionLogs.m`,
`Extraction/Extraction-Modules/PHOTON/extractRAW_PHOTON.m`,
`Extraction/Extraction-Modules/extractRAW.m`,
`Extraction/Modalities/Behavior/extractJOLT_legacy.m`,
`Extraction/Extraction-Modules/LEGACY/extractDTS_legacy.m`,
`Extraction/Extraction-Modules/JOLT/extractJOLT.m`,
`Extraction/Extraction-Modules/PHOTOM/extractRAW_PHOTOM.m`,
`Extraction/Modalities/Neuropixels/AP/extractAP.m`,
`Extraction/Modalities/Features/extractFeature_JOLT.m`,
`Extraction/Extraction-Modules/NPXLS/extractRAW_NPXLS.m`,
`Extraction/Modalities/Neuropixels/LFP/extractLFP.m`,
`Extraction/Modalities/Behavior/extractJOLT.m`.
Deliberately left untouched for now — scope was intentionally limited to the
two call sites in the actual error trace, to confirm the fix works before
sweeping the rest. Also unresolved: even with atomic writes everywhere, two
genuinely concurrent writers to the same log would still silently have the
later one win (lost update, not corruption) — the atomic-rename fix prevents
a torn/corrupted file but not a lost row-update from a true race. Whether
that's actually happening (vs. one writer simply getting interrupted) hasn't
been confirmed either way.

**Touches (if swept further):** the 12 files above — same mechanical swap,
`writetable(...)` → `writetableAtomic(...)`, at each one's own log-write call
site(s).

**Depends on:** Nothing architecturally. Gated on confirming the two-file fix
actually stops the clipping in practice before extending it.

---
