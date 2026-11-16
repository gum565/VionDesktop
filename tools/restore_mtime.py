#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/restore_mtime.py - Restore file modification times from Git commit history.
Ensures Ninja incremental builds can detect which files are actually newer than prebuilt .obj files.
"""

import os
import subprocess
import sys
import time


def main():
    start_time = time.time()
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.abspath(os.path.join(script_dir, ".."))

    # 1. Get all tracked files
    try:
        res = subprocess.run(
            ["git", "ls-files"],
            cwd=root_dir,
            capture_output=True,
            text=True,
            check=True
        )
        tracked_files = set(
            os.path.normpath(line.strip())
            for line in res.stdout.splitlines()
            if line.strip()
        )
    except Exception as e:
        print(f"[restore_mtime] Warning: could not list tracked files: {e}")
        return

    if not tracked_files:
        print("[restore_mtime] No tracked files found.")
        return

    # 2. Fast single-pass log parse: git log --name-only --format="TIME:%ct"
    try:
        proc = subprocess.Popen(
            ["git", "log", "--name-only", "--format=TIME:%ct"],
            cwd=root_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            errors="ignore"
        )
    except Exception as e:
        print(f"[restore_mtime] Warning: git log failed: {e}")
        return

    file_mtimes = {}
    current_time = None
    remaining_count = len(tracked_files)

    for line in proc.stdout:
        line = line.strip()
        if not line:
            continue
        if line.startswith("TIME:"):
            try:
                current_time = int(line[5:])
            except ValueError:
                current_time = None
        elif current_time is not None:
            norm_path = os.path.normpath(line)
            if norm_path in tracked_files and norm_path not in file_mtimes:
                file_mtimes[norm_path] = current_time
                remaining_count -= 1
                if remaining_count == 0:
                    break

    proc.stdout.close()
    proc.terminate()

    # 3. Apply mtimes to files on disk
    updated_count = 0
    for rel_path, mtime in file_mtimes.items():
        full_path = os.path.join(root_dir, rel_path)
        if os.path.isfile(full_path):
            try:
                os.utime(full_path, (mtime, mtime))
                updated_count += 1
            except Exception:
                pass

    elapsed = time.time() - start_time
    print(f"[restore_mtime] Successfully restored mtime for {updated_count}/{len(tracked_files)} files in {elapsed:.2f}s")


if __name__ == "__main__":
    main()
