"""
unzipLongPath.py  --  extract a .7z archive handling Windows long paths.
Uses NTFS hard links so 7-zip sees short paths; extracted files are moved
to the final long-path destination via the \\?\ kernel prefix.

Usage:
    python unzipLongPath.py <archive> <dest_dir> [<7z.exe>]

archive:  full path to the .7z file (may be a long path)
dest_dir: directory to extract files into (may be a long path)
Source archive is NOT deleted after extraction.
"""

import sys
import os
import tempfile
import time
import subprocess


def main():
    if len(sys.argv) < 3:
        print(f'Usage: {sys.argv[0]} <archive> <dest_dir> [<7z.exe>]')
        sys.exit(1)

    archive_path = sys.argv[1]
    dest_dir     = sys.argv[2]
    seven_zip    = sys.argv[3] if len(sys.argv) >= 4 else r'C:\Program Files\7-Zip\7z.exe'

    if not os.path.isfile(seven_zip):
        print(f'[unzipLongPath] ERROR: 7z.exe not found at {seven_zip}', flush=True)
        sys.exit(1)

    arc_size = os.path.getsize('\\\\?\\' + archive_path if not archive_path.startswith('\\\\?\\') else archive_path)
    print(f'[unzipLongPath] extracting {arc_size/1e9:.2f} GB archive -> {dest_dir}', flush=True)
    print(f'[unzipLongPath] started {time.strftime("%H:%M:%S")}', flush=True)
    t0 = time.time()

    tmp_dir = tempfile.gettempdir()

    # Hard-link the archive to a short path so 7-zip can open it
    short_archive = os.path.join(tmp_dir, '_tmp_extract_' + os.path.basename(archive_path))
    lp_archive    = archive_path if archive_path.startswith('\\\\?\\') else '\\\\?\\' + archive_path
    if os.path.exists(short_archive):
        os.remove(short_archive)
    os.link(lp_archive, short_archive)
    print(f'[unzipLongPath] linked archive to {short_archive}', flush=True)

    # Extract to a short temp output dir
    short_out = os.path.join(tmp_dir, '_tmp_extract_out')
    os.makedirs(short_out, exist_ok=True)

    try:
        result = subprocess.run(
            [seven_zip, 'e', '-bb3', '-y', f'-o{short_out}', short_archive])

        if result.returncode != 0:
            print('[unzipLongPath] ERROR: 7-zip extraction failed', flush=True)
            sys.exit(result.returncode)

        # Move extracted files to final long-path destination
        lp_dest = dest_dir if dest_dir.startswith('\\\\?\\') else '\\\\?\\' + dest_dir
        os.makedirs(lp_dest, exist_ok=True)

        extracted = os.listdir(short_out)
        print(f'[unzipLongPath] moving {len(extracted)} file(s) to destination', flush=True)
        for fname in extracted:
            src  = os.path.join(short_out, fname)
            dst  = os.path.join(lp_dest, fname)
            os.replace(src, dst)
            print(f'  restored: {fname}', flush=True)

    finally:
        if os.path.exists(short_archive):
            os.remove(short_archive)
        # Clean up any leftover temp files
        for f in os.listdir(short_out):
            try:
                os.remove(os.path.join(short_out, f))
            except Exception:
                pass
        try:
            os.rmdir(short_out)
        except Exception:
            pass

    elapsed = time.time() - t0
    print(f'[unzipLongPath] done in {elapsed/60:.1f} min', flush=True)


if __name__ == '__main__':
    main()
