"""
zipLongPath.py  --  archive files from a manifest, handling Windows long paths.
Paths are read from a manifest file (one per line) to avoid command-line length limits.

Usage:
    python zipLongPath.py <manifest.txt> <output> [<7z.exe>]

With 7z.exe: calls 7-zip via @listfile (zstd, multithreaded) — 7-zip reads paths
  from the file directly, bypassing the Windows cmd-line 260-char limit entirely.
Without:     falls back to Python zipfile (ZIP_DEFLATED) with \\?\ long-path prefix.

Source files are deleted after successful archive creation.
"""

import sys
import os
import tempfile
import time
import zipfile
import subprocess


def _find_free_drive():
    for c in reversed('ZYXWVUTSRQPONM'):
        if not os.path.exists(c + ':\\'):
            return c + ':'
    raise RuntimeError('[zipLongPath] No free drive letter available for subst')


def _subst_create(drive, target):
    """Map drive letter to target via DefineDosDevice.
    Unlike subst.exe, passes the path as a Unicode string directly to the Win32 API
    so there is no 260-char limit on the target path.
    """
    import ctypes
    nt_target = '\\??' + '\\' + target.rstrip('\\')
    DDD_RAW_TARGET_PATH = 0x1
    if not ctypes.windll.kernel32.DefineDosDeviceW(DDD_RAW_TARGET_PATH, drive, nt_target):
        raise OSError(f'DefineDosDevice({drive!r}) failed — error {ctypes.GetLastError()}')


def _subst_remove(drive, target):
    """Remove a mapping created by _subst_create."""
    import ctypes
    nt_target = '\\??' + '\\' + target.rstrip('\\')
    flags = 0x1 | 0x2 | 0x4  # RAW_TARGET_PATH | REMOVE_DEFINITION | EXACT_MATCH_ON_REMOVE
    ctypes.windll.kernel32.DefineDosDeviceW(flags, drive, nt_target)


def main():
    if len(sys.argv) < 3:
        print(f'Usage: {sys.argv[0]} <manifest.txt> <output> [<7z.exe>]')
        sys.exit(1)

    manifest_path = sys.argv[1]
    archive_path  = sys.argv[2]
    seven_zip     = sys.argv[3] if len(sys.argv) >= 4 else None

    with open(manifest_path, 'r', encoding='utf-8') as f:
        items = [line.strip() for line in f if line.strip()]

    if not items:
        print('zipLongPath: manifest is empty')
        sys.exit(1)

    print(f'[zipLongPath] archiving {len(items)} file(s) -> {archive_path}', flush=True)

    use_python_zip = False

    if seven_zip and os.path.isfile(seven_zip):
        # Output archive path may also exceed MAX_PATH — write to a short temp path
        # on the same drive, then rename to the final long path via \\?\ prefix.
        tmp_archive = os.path.join(tempfile.gettempdir(), '_tmp_' + os.path.basename(archive_path))
        print(f'[zipLongPath] 7-zip staging to {tmp_archive}', flush=True)

        # All path-aliasing approaches (\\?\, subst, DefineDosDevice) fail because
        # 7-zip resolves virtual paths back to the real long path before opening files.
        # Solution: NTFS hard links — instant (no data copy), give 7-zip genuinely
        # short paths pointing to the same inodes as the originals.
        link_dir = os.path.join(tempfile.gettempdir(), '_7ztmp_npxls')
        os.makedirs(link_dir, exist_ok=True)
        short_items = []
        for src in items:
            lp_src = src if src.startswith('\\\\?\\') else '\\\\?\\' + src
            short  = os.path.join(link_dir, os.path.basename(src))
            if os.path.exists(short):
                os.remove(short)
            os.link(lp_src, short)  # instant — no data copied
            short_items.append(short)
            print(f'[zipLongPath] linked: {os.path.basename(src)}', flush=True)

        short_manifest = manifest_path + '.short.txt'
        with open(short_manifest, 'w', encoding='utf-8') as f:
            for s in short_items:
                f.write(s + '\n')

        total_bytes = sum(os.path.getsize(s) for s in short_items)
        print(f'[zipLongPath] compressing {total_bytes/1e9:.2f} GB — started {time.strftime("%H:%M:%S")}', flush=True)
        t0 = time.time()

        try:
            # No -sdel: 7-zip would delete the hard links, not the originals.
            # We delete originals manually below via \\?\ after success.
            # -bb3: verbose per-file operation log so errors name the failing file.
            result = subprocess.run(
                [seven_zip, 'a', '-mx=1', '-mmt=on', '-bb3',
                 tmp_archive, f'@{short_manifest}'])
        finally:
            for short in short_items:
                if os.path.exists(short):
                    os.remove(short)
            try:
                os.rmdir(link_dir)
            except Exception:
                pass
            if os.path.exists(short_manifest):
                os.remove(short_manifest)

        if result.returncode != 0:
            if os.path.exists(tmp_archive):
                os.remove(tmp_archive)
            print('[zipLongPath] WARNING: 7-zip hard-link approach failed — falling back to Python zipfile (ZIP)', flush=True)
            use_python_zip = True
        else:
            elapsed  = time.time() - t0
            arc_size = os.path.getsize(tmp_archive)
            ratio    = arc_size / total_bytes * 100 if total_bytes else 0
            print(f'[zipLongPath] compressed {total_bytes/1e9:.2f} GB -> {arc_size/1e9:.2f} GB '
                  f'({ratio:.1f}%) in {elapsed/60:.1f} min', flush=True)
            # Delete originals via \\?\ (7-zip couldn't do it — no -sdel above)
            for src in items:
                lp_src = src if src.startswith('\\\\?\\') else '\\\\?\\' + src
                os.remove(lp_src)
            long_final = archive_path if archive_path.startswith('\\\\?\\') else '\\\\?\\' + archive_path
            os.rename(tmp_archive, long_final)
            print('[zipLongPath] moved to final path', flush=True)
    else:
        print('[zipLongPath] 7z.exe not found — falling back to Python zipfile (ZIP)', flush=True)
        use_python_zip = True

    if use_python_zip:
        # Pure-Python fallback: standard ZIP with \\?\ prefix for long paths.
        # Changes extension to .zip since zipfile can't write .7z.
        p, _ = os.path.splitext(archive_path)
        archive_path = p + '.zip'
        print(f'[zipLongPath] writing {archive_path}', flush=True)
        with zipfile.ZipFile(archive_path, 'w', compression=zipfile.ZIP_DEFLATED,
                             compresslevel=3) as zf:
            for src in items:
                long_src = src if src.startswith('\\\\?\\') else ('\\\\?\\' + src)
                arcname  = os.path.basename(src)
                zf.write(long_src, arcname)
                print(f'  added: {arcname}', flush=True)
        for src in items:
            long_src = src if src.startswith('\\\\?\\') else ('\\\\?\\' + src)
            os.remove(long_src)
            print(f'  deleted: {os.path.basename(src)}', flush=True)

    print('[zipLongPath] done.', flush=True)


if __name__ == '__main__':
    main()
