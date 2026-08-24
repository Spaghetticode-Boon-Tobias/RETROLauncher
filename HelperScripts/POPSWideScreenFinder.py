#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
POPSWideScreenFinder.py

Hunts the PS1 widescreen address through RALibretro's process memory, using
memory snapshots of several camera VIEWS that you switch by hand.

How it works:
  1. Export any result list from RALibretro's Memory Inspector (addresses and
     values). It is only used as an anchor to locate the PS1 RAM inside the
     emulator process - the hunt itself reads the whole 2 MiB directly.
  2. The tool asks for a number of views (3 is good). For each one: set the
     camera in the game, come back to this console, press Enter. Each view is
     photographed several times, two megabytes at a time.
  3. Cross analysis:
       - WIDESCREEN candidates: 16-bit words equal to 0x1000 in every dump of
         every view. The projection factor is a constant - that is the whole
         point of the classic tutorial's "move the camera then refilter".
       - CAMERA values: stable within a view, different across views. Listed
         for information, and testable afterwards.
  4. Write test, in batches: each candidate gets 0x0C00 written continuously
     (like a real GameShark code - many addresses are recomputed every frame,
     a single write never survives to the render). The game image is compared
     against its own 75%-squished version: an image that starts looking like
     the squished reference is the signature of a width hack, immune to plain
     animation. Reactive batches are replayed one address at a time, and every
     hit is confirmed twice.

Keys during the write test:  y = mark current address (your eye wins),
q = stop and print the report. Codes come out ready for POPStarter's
CHEATS.TXT:  80XXXXXX 0C00

Needs: Windows, Python 3, Pillow (pip install pillow). Run as administrator
if attaching fails. Keep the emulator visible and on a live 3D scene.
"""

import ctypes
import ctypes.wintypes as wt
import re
import struct
import sys
import time
from pathlib import Path

try:
    from PIL import ImageGrab, ImageChops
except ImportError:
    print("Pillow is required:  pip install pillow")
    sys.exit(1)

k32 = ctypes.windll.kernel32
u32 = ctypes.windll.user32

PROCESS_ALL = 0x0010 | 0x0020 | 0x0008 | 0x0400
MEM_COMMIT = 0x1000
PS1_RAM = 2 * 1024 * 1024
BASE_VALUE = 0x1000
WIDE_VALUE = 0x0C00
RATIO = WIDE_VALUE / BASE_VALUE      # 0.75, same for every pair of the table

# The full table from the pcsx2 forums tutorial: initial 4:3 value -> 16:9 value.
# The projection factor of a given game is ONE of these constants.
WIDE_TABLE = {0x1000: 0x0C00, 0x1004: 0x0C03, 0x1999: 0x1333, 0x199A: 0x1334,
              0x1200: 0x0D80, 0x12AA: 0x0E00, 0x111A: 0x0CD3, 0x1400: 0x0F00,
              0x1164: 0x0D0B, 0x0B98: 0x08B2}
TABLE_ORDER = [0x1000, 0x1999, 0x199A, 0x12AA, 0x111A, 0x1400,
               0x1004, 0x1200, 0x1164, 0x0B98]
CROP = (32, 24, 128, 96)             # central 60% of the 160x120 thumbnails


class MBI(ctypes.Structure):
    _fields_ = [("BaseAddress", ctypes.c_void_p),
                ("AllocationBase", ctypes.c_void_p),
                ("AllocationProtect", wt.DWORD),
                ("PartitionId", wt.WORD),
                ("RegionSize", ctypes.c_size_t),
                ("State", wt.DWORD),
                ("Protect", wt.DWORD),
                ("Type", wt.DWORD)]


def find_pid(name_part):
    TH32CS_SNAPPROCESS = 0x2

    class PE32(ctypes.Structure):
        _fields_ = [("dwSize", wt.DWORD), ("cntUsage", wt.DWORD),
                    ("th32ProcessID", wt.DWORD),
                    ("th32DefaultHeapID", ctypes.POINTER(ctypes.c_ulong)),
                    ("th32ModuleID", wt.DWORD), ("cntThreads", wt.DWORD),
                    ("th32ParentProcessID", wt.DWORD),
                    ("pcPriClassBase", ctypes.c_long), ("dwFlags", wt.DWORD),
                    ("szExeFile", ctypes.c_char * 260)]

    snap = k32.CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
    pe = PE32()
    pe.dwSize = ctypes.sizeof(PE32)
    pid = None
    if k32.Process32First(snap, ctypes.byref(pe)):
        while True:
            if name_part.lower() in pe.szExeFile.decode(errors="ignore").lower():
                pid = pe.th32ProcessID
                break
            if not k32.Process32Next(snap, ctypes.byref(pe)):
                break
    k32.CloseHandle(snap)
    return pid


def read_mem(h, addr, size):
    buf = ctypes.create_string_buffer(size)
    got = ctypes.c_size_t()
    if k32.ReadProcessMemory(h, ctypes.c_void_p(addr), buf, size, ctypes.byref(got)):
        return buf.raw[:got.value]
    return None


def write_u16(h, addr, value):
    buf = struct.pack("<H", value)
    done = ctypes.c_size_t()
    return bool(k32.WriteProcessMemory(h, ctypes.c_void_p(addr),
                                       buf, 2, ctypes.byref(done)))


def regions(h):
    addr, out = 0, []
    while addr < 0x7FFFFFFFFFFF:
        mbi = MBI()
        if not k32.VirtualQueryEx(h, ctypes.c_void_p(addr),
                                  ctypes.byref(mbi), ctypes.sizeof(mbi)):
            break
        base = mbi.BaseAddress or 0
        size = mbi.RegionSize or 0
        if mbi.State == MEM_COMMIT and (mbi.Protect & 0xFF) in (0x04, 0x40) \
           and size >= PS1_RAM:
            out.append((base, size))
        addr = base + size
        if size == 0:
            break
    return out


def parse_pairs(path):
    """(address, value) pairs from a RALibretro export. Lines look like
    '0x0006ea  0x1000  Kernel RAM' but any two hex fields will do."""
    pairs = []
    for line in Path(path).read_text(encoding="utf-8", errors="replace").splitlines():
        nums = re.findall(r'(?:0x)?([0-9a-fA-F]{3,8})', line)
        if len(nums) < 2:
            continue
        a, v = int(nums[0], 16), int(nums[1], 16)
        if a < PS1_RAM and a % 2 == 0 and v <= 0xFFFF:
            pairs.append((a, v))
    seen, out = set(), []
    for a, v in pairs:
        if a not in seen:
            seen.add(a)
            out.append((a, v))
    return out


def locate_ram(h, pairs):
    """Host address of PS1 RAM: the offset where the exported pairs match.
    Values may have drifted since the export, so 60% agreement is enough."""
    probe = pairs[:60]
    best = None
    for base, size in regions(h):
        block = read_mem(h, base, min(size, 256 * 1024 * 1024))
        if not block:
            continue
        limit = len(block) - PS1_RAM
        off = 0
        while off <= limit:
            hits = 0
            for a, v in probe:
                if block[off + a: off + a + 2] == struct.pack("<H", v):
                    hits += 1
            if hits >= max(8, int(len(probe) * 0.6)):
                return base + off, hits, len(probe)
            if best is None or hits > best[0]:
                best = (hits, len(probe))
            off += 0x1000
    return None, (best[0] if best else 0), (best[1] if best else len(probe))


def pick_point(label):
    input(f"  Put the mouse on the {label} of the GAME area and press Enter... ")
    pt = wt.POINT()
    u32.GetCursorPos(ctypes.byref(pt))
    print(f"    ({pt.x}, {pt.y})")
    return pt.x, pt.y


def grab(box):
    return ImageGrab.grab(bbox=box).convert("L").resize((160, 120))


def squish(img):
    w = int(160 * RATIO)
    s = img.resize((w, 120))
    out = img.copy()
    out.paste(s, ((160 - w) // 2, 0))
    return out


def dcrop(a, b):
    hist = ImageChops.difference(a.crop(CROP), b.crop(CROP)).histogram()
    n = (CROP[2] - CROP[0]) * (CROP[3] - CROP[1])
    return sum(i * c for i, c in enumerate(hist)) / n


def main():
    print(__doc__.strip())
    print("\n" + "=" * 70)

    pid = find_pid("RALibretro")
    if not pid:
        print("\nRALibretro is not running.")
        return 1
    h = k32.OpenProcess(PROCESS_ALL, False, pid)
    if not h:
        print("\nCould not open the process (run this as administrator).")
        return 1
    print(f"\nAttached to RALibretro, PID {pid}")

    p = input("Path of any exported result list (RAM anchor): ").strip().strip('"')
    pairs = parse_pairs(p)
    if len(pairs) < 5:
        print("Fewer than 5 address/value pairs parsed - wrong file?")
        return 1
    ram, hits, probes = locate_ram(h, pairs)
    if ram is None:
        print(f"\nPS1 RAM not located (best {hits}/{probes}). Export a fresh")
        print("list without touching the game, then rerun immediately.")
        return 1
    print(f"PS1 RAM found at host address 0x{ram:X}  ({hits}/{probes} probes)")

    # Suspect archive: screenshot + full RAM during the effect + RAM after
    # restore + your note, for offline analysis.
    suspects_dir = Path(p).with_name("wsf_suspects")

    def archive_suspect(targets, note):
        import gzip
        suspects_dir.mkdir(exist_ok=True)
        n = sum(1 for _x in suspects_dir.glob("*")) + 1
        tag = "-".join(f"{va:06X}" for va, _vv, _o, _b in targets)[:48]
        d = suspects_dir / f"{n:03d}_{tag}"
        d.mkdir(exist_ok=True)
        try:
            ImageGrab.grab().save(d / "held_screen.png")
        except OSError:
            pass
        blk = read_mem(h, ram, PS1_RAM)
        if blk:
            with gzip.open(d / "ram_held.bin.gz", "wb") as f_:
                f_.write(blk)
        with open(d / "info.txt", "w", encoding="utf-8") as f_:
            for va, vv, _o, bv in targets:
                f_.write(f"addr 0x{va:06X}  wrote {vv:04X}  was "
                         f"{bv if isinstance(bv, str) else format(bv, '04X')}\n")
            f_.write(f"note: {note}\n")
        print(f"    suspect archived -> {d.name}")
        return d

    def archive_restored(d):
        import gzip
        blk = read_mem(h, ram, PS1_RAM)
        if blk and d is not None:
            with gzip.open(d / "ram_restored.bin.gz", "wb") as f_:
                f_.write(blk)

    # ---- Verify mode: hold one code by hand and just watch -------------------
    # Type an address (and optionally a value) to keep it written while you
    # look at the game; Enter with nothing starts the normal hunt.
    print("\nVerify mode. Commands:")
    print("  6B0C8                 hold one address (16:9 value from the table)")
    print("  6B0C8:0B00            hold with an explicit value")
    print("  6B0C8+6B1F8+7024C     hold SEVERAL together (sibling copies often")
    print("                        rewrite each other - only the set works)")
    print("  n 6B0C8               map the memory around an address: projection")
    print("                        factors live in structures, X next to Y")
    print("  Enter                 continue to the hunt")
    raw = input("> ").strip()
    while raw:
        try:
            if raw.lower().startswith("n "):
                va = int(raw[2:].strip(), 16)
                start = max(0, va - 0x100) & ~0xF
                blk = read_mem(h, ram + start, 0x200)
                if blk:
                    print(f"  16-bit words around 0x{va:06X} "
                          f"(* = plausible factor 0800-2000):")
                    for row in range(0, 0x200, 0x10):
                        cells = []
                        for c in range(0, 0x10, 2):
                            w = struct.unpack("<H", blk[row + c:row + c + 2])[0]
                            mark = "*" if 0x0800 <= w <= 0x2000 else " "
                            cur = ">" if start + row + c == va else " "
                            cells.append(f"{cur}{w:04X}{mark}")
                        print(f"    0x{start + row:06X}  " + " ".join(cells))
            else:
                targets = []
                for part in raw.split("+"):
                    part = part.strip()
                    if ":" in part:
                        x, y = part.split(":", 1)
                        va, vv = int(x, 16), int(y, 16)
                    else:
                        va, vv = int(part, 16), None
                    orig = read_mem(h, ram + va, 2)
                    base_v = struct.unpack("<H", orig)[0] if orig else None
                    if vv is None:
                        if base_v in WIDE_TABLE:
                            vv = WIDE_TABLE[base_v]
                        elif base_v is not None:
                            vv = max(1, (base_v * 3) // 4)   # generic 16:9 = x0.75
                        else:
                            vv = 0x0C00
                    targets.append((va, vv, orig, base_v))
                desc = "  ".join(f"80{va:06X} {vv:04X}(was {bv:04X})"
                                for va, vv, _o, bv in targets)
                print(f"  holding {desc}")
                print("  Enter = restore,  s [note] = mark SUSPECT "
                      "(RAM+screenshot archived)")
                import threading
                stop_evt = threading.Event()
                def holder():
                    while not stop_evt.is_set():
                        for va, vv, _o, _b in targets:
                            write_u16(h, ram + va, vv)
                        time.sleep(0.05)
                t = threading.Thread(target=holder, daemon=True)
                t.start()
                ans = input()
                d_arch = None
                if ans.strip().lower().startswith("s"):
                    d_arch = archive_suspect(targets, ans.strip()[1:].strip())
                stop_evt.set()
                t.join(timeout=1)
                for va, _vv, orig, _b in targets:
                    if orig:
                        for _r in range(3):
                            k32.WriteProcessMemory(h, ctypes.c_void_p(ram + va),
                                                   orig, 2,
                                                   ctypes.byref(ctypes.c_size_t()))
                            time.sleep(0.03)
                if d_arch is not None:
                    time.sleep(0.3)
                    archive_restored(d_arch)
                print("  restored.")
        except (ValueError, struct.error):
            print("  could not parse that.")
        raw = input("> ").strip()

    # ---- Phase 1: memory snapshots of each camera view -----------------------
    raw = input("\nHow many camera views will you show me? [5]: ").strip()
    n_views = int(raw) if raw.isdigit() and int(raw) >= 2 else 5
    DUMPS = 3
    views = []
    same_as = []      # same_as[i] = index of the view sharing the SAME camera
    for v in range(n_views):
        input(f"\nSet the game to VIEW {v+1}/{n_views}, then press Enter here... ")
        lab = ""
        if v > 0:
            lab = input(f"  Same CAMERA as an earlier view? (view number, "
                        f"Enter = new camera): ").strip()
        same_as.append(int(lab) - 1 if lab.isdigit() and 1 <= int(lab) <= v else None)
        dumps = []
        for d in range(DUMPS):
            blk = read_mem(h, ram, PS1_RAM)
            if blk is None:
                print("RAM read failed - did the game stop?")
                return 1
            dumps.append(blk)
            time.sleep(0.35)
        views.append(dumps)
        tag = f" (camera of view {same_as[v]+1})" if same_as[v] is not None else ""
        print(f"  view {v+1}: {DUMPS} dumps of 2 MiB taken{tag}")

    # ---- Phase 2: cross analysis --------------------------------------------
    print("\nCross-analysing...")
    wanted = {struct.pack("<H", v): v for v in WIDE_TABLE}
    wide_candidates = []      # (addr, base_value)
    camera_values = []
    view_params = []          # equal across same-camera views, differ otherwise
    for a in range(0, PS1_RAM, 2):
        stable = True
        per_view = []
        for dumps in views:
            v0 = dumps[0][a:a + 2]
            for d in dumps[1:]:
                if d[a:a + 2] != v0:
                    stable = False
                    break
            if not stable:
                break
            per_view.append(v0)
        if not stable:
            continue
        if per_view[0] in wanted and all(pv == per_view[0] for pv in per_view):
            wide_candidates.append((a, wanted[per_view[0]]))
        elif len(set(per_view)) > 1:
            camera_values.append((a, [struct.unpack("<H", pv)[0] for pv in per_view]))
            # VIEW-PARAM: equal whenever the camera is the same, different
            # between cameras -> a per-view setting, where a per-camera FOV
            # would live. Requires at least one repeated-camera pair.
            if any(s is not None for s in same_as):
                rep_ok = all(per_view[i] == per_view[s]
                             for i, s in enumerate(same_as) if s is not None)
                if rep_ok:
                    cams = {}
                    for i, s in enumerate(same_as):
                        root = s if s is not None else i
                        cams.setdefault(root, per_view[i])
                    if len(set(cams.values())) > 1:
                        view_params.append(
                            (a, [struct.unpack("<H", pv)[0] for pv in per_view]))

    kernel = [c for c in wide_candidates if c[0] < 0x10000]
    wide_candidates = [c for c in wide_candidates if c[0] >= 0x10000]
    wide_candidates.sort(key=lambda c: (TABLE_ORDER.index(c[1]), c[0]))
    counts = {}
    for _a, v in wide_candidates:
        counts[v] = counts.get(v, 0) + 1
    print(f"  {len(wide_candidates)} WIDESCREEN candidate(s), constant across "
          f"all views:")
    for v in TABLE_ORDER:
        if v in counts:
            print(f"    {v:04X} -> {WIDE_TABLE[v]:04X} : {counts[v]}")
    if kernel:
        print(f"  {len(kernel)} kernel address(es) (< 0x10000) excluded: writing")
        print(f"  there freezes the PS1 virtual machine, and no game keeps its")
        print(f"  projection factor in the kernel.")
    print(f"  {len(camera_values)} address(es) are stable per view but differ "
          f"between views (camera values)")
    if view_params:
        # plausible projection factors first
        view_params.sort(key=lambda cv: (not any(0x0400 <= x <= 0x4000
                                                 for x in cv[1]), cv[0]))
        outp = Path(p).with_name("view_params.txt")
        with open(outp, "w", encoding="utf-8") as f_:
            f_.write("addr      value per view (* = plausible factor range)\n")
            for a2, vals in view_params:
                star = "*" if any(0x0400 <= x <= 0x4000 for x in vals) else " "
                f_.write(f"{star}0x{a2:06X}  "
                         + "  ".join(f"{x:04X}" for x in vals) + "\n")
        stars = sum(1 for _a, vals in view_params
                    if any(0x0400 <= x <= 0x4000 for x in vals))
        print(f"  {len(view_params)} VIEW-PARAM address(es) - equal for a same")
        print(f"  camera, different between cameras - written to {outp.name},")
        print(f"  {stars} in a plausible factor range (marked *). Test them in")
        print(f"  verify mode with 'addr' (value*0.75 is applied by default).")
    if camera_values:
        out = Path(p).with_name("camera_values.txt")
        with open(out, "w", encoding="utf-8") as f:
            for a, vals in camera_values:
                f.write(f"0x{a:06X}  " + "  ".join(f"{v:04X}" for v in vals) + "\n")
        print(f"  camera values written to {out}")
    if not wide_candidates:
        print("\nNothing constant at 0x1000 across the views - unusual. Make")
        print("sure every view showed a live 3D scene of the same game mode.")
        return 1

    # ---- Phase 3: write test ------------------------------------------------
    done_file = Path(p).with_name("wsf_done.txt")
    crash_file = Path(p).with_name("wsf_crashers.txt")
    already = set()
    for f_ in (done_file, crash_file):
        if f_.is_file():
            for line in f_.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if not line:
                    continue
                if ":" in line:
                    x, y = line.split(":", 1)
                    already.add((int(x, 16), int(y, 16)))
                else:
                    already.add((int(line, 16), 0x1000))
    if already:
        before = len(wide_candidates)
        wide_candidates = [c for c in wide_candidates if c not in already]
        print(f"\nResuming: {before - len(wide_candidates)} address(es) already"
              f" tested or known to crash, {len(wide_candidates)} left.")
        print(f"(delete {done_file.name} to start over)")

    print("\nFrame the game image (the 3D view only, avoid overlays):")
    x1, y1 = pick_point("TOP-LEFT corner")
    x2, y2 = pick_point("BOTTOM-RIGHT corner")
    box = (min(x1, x2), min(y1, y2), max(x1, x2), max(y1, y2))

    mode = input("\nMode:  [1] automatic (measured)   [2] fast eye-sweep "
                 "(you watch, ~0.2s per code) [1]: ").strip()

    if mode == "2":
        try:
            import msvcrt
        except ImportError:
            print("Fast mode needs Windows (msvcrt). Falling back to automatic.")
            mode = "1"

    if mode == "2":
        raw = input("Seconds per code [0.25]: ").strip()
        try:
            fast_hold = max(0.1, float(raw)) if raw else 0.25
        except ValueError:
            fast_hold = 0.25

        def held(a, v, seconds):
            end = time.time() + seconds
            while time.time() < end:
                write_u16(h, ram + a, v)
                time.sleep(0.04)

        def full_diff2(x, y):
            hist = ImageChops.difference(x, y).histogram()
            return sum(i * c for i, c in enumerate(hist)) / (160 * 120)

        def alive2():
            x = grab(box)
            time.sleep(0.35)
            return full_diff2(x, grab(box)) > 0.02

        def replay(window):
            print("\n  Replaying the last addresses slowly. For each one:")
            print("  y = that is it,  s [note] = suspect (RAM+shot archived),")
            print("  Enter = next\n")
            hits = []
            for a, v in window:
                wv = WIDE_TABLE[v]
                print(f"    holding 80{a:06X} {wv:04X} ...", end="", flush=True)
                import threading
                stop_evt = threading.Event()
                def holder():
                    while not stop_evt.is_set():
                        write_u16(h, ram + a, wv)
                        time.sleep(0.05)
                t = threading.Thread(target=holder, daemon=True)
                t.start()
                ans = input("  seen? ").strip().lower()
                d_arch = None
                if ans.startswith("s"):
                    d_arch = archive_suspect([(a, wv, None, v)], ans[1:].strip())
                stop_evt.set()
                t.join(timeout=1)
                for _r in range(3):
                    write_u16(h, ram + a, v)
                    time.sleep(0.04)
                if d_arch is not None:
                    time.sleep(0.3)
                    archive_restored(d_arch)
                if ans == "y":
                    print(f"    >>> HIT 0x{a:06X}  ->  code: 80{a:06X} {wv:04X}")
                    hits.append((a, v))
            return hits

        print("\nSweeping. Keys: SPACE or y = I saw something (replays the")
        print("last 12 slowly), q = stop. Watch the game, not the console.\n")
        found = []
        recent = []
        i = 0
        stop = False
        while i < len(wide_candidates) and not stop:
            c = wide_candidates[i]
            a, v = c
            held(a, WIDE_TABLE[v], fast_hold)
            for _r in range(2):
                write_u16(h, ram + a, v)
                time.sleep(0.02)
            recent.append(c)
            recent = recent[-12:]
            print(f"\r  0x{a:06X}  ({v:04X})  [{i+1}/{len(wide_candidates)}]   ",
                  end="", flush=True)
            while msvcrt.kbhit():
                ch = msvcrt.getwch().lower()
                if ch in (" ", "y"):
                    found += replay(list(recent))
                    print("\n  ...sweeping again\n")
                elif ch == "q":
                    stop = True
            if i % 24 == 23 and not alive2():
                print(f"\n\nGAME FROZEN. Recent suspects: "
                      + ", ".join(f"0x{x:06X}" for x, _ in recent[-4:]))
                with open(crash_file, "a", encoding="utf-8") as f_:
                    for x, y_ in recent[-4:]:
                        f_.write(f"{x:06X}:{y_:04X}\n")
                input("Reload your save state, then press Enter... ")
                while not alive2():
                    input("Still frozen. Reload and press Enter again... ")
            else:
                with open(done_file, "a", encoding="utf-8") as f_:
                    f_.write(f"{a:06X}:{v:04X}\n")
            i += 1

        print("\n" + "=" * 70)
        if found:
            print(f"{len(found)} hit(s):")
            for a, v in found:
                print(f"  80{a:06X} {WIDE_TABLE[v]:04X}")
        else:
            print("Nothing marked. The events of automatic runs stay in")
            print("wsf_events.txt / wsf_shots if you want to cross-check.")
        return 0

    raw = input("\nSeconds to hold each write [1.5]: ").strip()
    try:
        hold = max(0.5, float(raw)) if raw else 1.5
    except ValueError:
        hold = 1.5
    raw = input("Batch size [8] (1 = safest, slower): ").strip()
    batch = max(1, int(raw)) if raw.isdigit() else 8

    def test_group(group):
        """Held write on the whole group of (addr, base_value) pairs.
        Returns (raw_diff, squish_score, ref_image, most_reactive_image)."""
        ref = grab(box)
        ref_s = squish(ref)
        end = time.time() + hold
        best_raw, best_sq, best_img = 0.0, -999.0, None
        while time.time() < end:
            for a, base_v in group:
                write_u16(h, ram + a, WIDE_TABLE[base_v])
            time.sleep(0.10)
            img = grab(box)
            r = dcrop(img, ref)
            s = dcrop(img, ref) - dcrop(img, ref_s)
            best_raw = max(best_raw, r)
            if s > best_sq:
                best_sq, best_img = s, img
        for _r in range(3):
            for a, base_v in group:
                write_u16(h, ram + a, base_v)
            time.sleep(0.06)
        return best_raw, best_sq, ref, best_img

    def full_diff(x, y):
        hist = ImageChops.difference(x, y).histogram()
        return sum(i * c for i, c in enumerate(hist)) / (160 * 120)

    print("\nCalibrating on the live image...")
    base_sq, live_min = 0.0, 999.0
    refc = grab(box)
    for _i in range(6):
        time.sleep(0.3)
        img = grab(box)
        base_sq = max(base_sq, dcrop(img, refc) - dcrop(img, squish(refc)))
        live_min = min(live_min, full_diff(img, refc))
        refc = img
    sq_thr = base_sq * 3 + 0.4
    freeze_thr = max(live_min * 0.15, 0.02)
    print(f"squish threshold = {sq_thr:.2f}   liveliness = {live_min:.2f}")

    # Visual journal: anything that stirs beyond the soft thresholds gets a
    # before/during snapshot, hit or not - so nothing seen is ever lost.
    shots_dir = Path(p).with_name("wsf_shots")
    shots_dir.mkdir(exist_ok=True)
    events_file = Path(p).with_name("wsf_events.txt")
    raw_soft = live_min * 2 + 1.5
    sq_soft = max(sq_thr * 0.5, 0.2)
    ev_count = [0]

    def record_event(tag, group, raw_d, sq, ref, img):
        ev_count[0] += 1
        name = f"{ev_count[0]:04d}_{tag}_" + "-".join(
            f"{a:06X}.{v:04X}" for a, v in group[:4]) + f"_sq{sq:+.1f}.png"
        try:
            if ref is not None and img is not None:
                from PIL import Image
                combo = Image.new("L", (322, 120), 255)
                combo.paste(ref, (0, 0))
                combo.paste(img, (162, 0))
                combo.save(shots_dir / name)
        except OSError:
            pass
        with open(events_file, "a", encoding="utf-8") as f_:
            f_.write(f"{tag}  raw={raw_d:7.2f}  sq={sq:+7.2f}  "
                     + " ".join(f"{a:06X}:{v:04X}" for a, v in group) + "\n")
    if live_min < 0.05:
        print("WARNING: the framed image barely moves. Include the race timer")
        print("in the frame, or freezes cannot be told apart from normal play.")

    def is_alive():
        x = grab(box)
        time.sleep(0.35)
        y = grab(box)
        if full_diff(x, y) > freeze_thr:
            return True
        time.sleep(0.5)
        z = grab(box)
        return full_diff(x, z) > freeze_thr
    print("\nKeys any time in this console: y = mark current, q = stop.\n")

    try:
        import msvcrt
    except ImportError:
        msvcrt = None

    found = []
    stop = False
    t0 = time.time()
    done = 0
    i = 0
    while i < len(wide_candidates) and not stop:
        group = wide_candidates[i:i + batch]
        i += len(group)
        raw_d, sq, g_ref, g_img = test_group(group)
        if sq > sq_soft or raw_d > raw_soft:
            record_event("stir", group, raw_d, sq, g_ref, g_img)
        suspects = group if sq > sq_thr else []
        for c in suspects:
            if len(group) > 1:
                _r1, s1, r_ref, r_img = test_group([c])
                if s1 <= sq_thr:
                    if s1 > sq_soft:
                        record_event("solo", [c], _r1, s1, r_ref, r_img)
                    continue
            ok = 0
            for _x in range(2):
                r2, s2, c_ref, c_img = test_group([c])
                if s2 > sq_thr:
                    ok += 1
                    record_event("confirm", [c], r2, s2, c_ref, c_img)
            if ok == 2:
                a, v = c
                print(f"\n  >>> HIT 0x{a:06X}  ({v:04X} -> {WIDE_TABLE[v]:04X})"
                      f"  ->  code: 80{a:06X} {WIDE_TABLE[v]:04X}\n")
                found.append(c)
        # The scene must still be alive: the timer keeps the image moving.
        # A frozen game means one of the last writes killed the PS1 VM.
        if not is_alive():
            print(f"\n\nGAME FROZEN. Suspect address(es): "
                  + ", ".join(f"0x{a:06X}" for a, _v in group))
            with open(crash_file, "a", encoding="utf-8") as f_:
                for a, v in group:
                    f_.write(f"{a:06X}:{v:04X}\n")
            record_event("FREEZE", group, raw_d, sq, g_ref, g_img)
            print("They are recorded in wsf_crashers.txt and will be skipped")
            print("from now on, including after a restart.")
            input("Reload your save state in RALibretro, then press Enter... ")
            while not is_alive():
                input("Still frozen. Reload the state and press Enter again... ")
        else:
            with open(done_file, "a", encoding="utf-8") as f_:
                for a, v in group:
                    f_.write(f"{a:06X}:{v:04X}\n")
        done += len(group)
        rate = done / max(time.time() - t0, 1)
        left = (len(wide_candidates) - done) / max(rate * 60, 0.01)
        print(f"\r  {done}/{len(wide_candidates)}  sq={sq:6.2f}  "
              f"~{left:4.0f} min left   ", end="", flush=True)
        if msvcrt:
            while msvcrt.kbhit():
                ch = msvcrt.getwch().lower()
                if ch == "y" and group:
                    a, v = group[-1]
                    record_event("manual", [group[-1]], raw_d, sq, g_ref, g_img)
                    print(f"\n  >>> MANUAL HIT 0x{a:06X}"
                          f"  ->  code: 80{a:06X} {WIDE_TABLE[v]:04X}\n")
                    found.append(group[-1])
                elif ch == "q":
                    stop = True

    print("\n" + "=" * 70)
    if not found:
        print("No candidate squeezed the image. Options: hold longer, hunt the")
        print("other start values from the tutorial (1999, 199A, 12AA, 111A,")
        print("1400), or explore camera_values.txt - per-view projection games")
        print("keep their factor there instead of in a constant.")
    else:
        print(f"{len(found)} candidate(s). GameShark / CHEATS.TXT lines:")
        for a, v in found:
            print(f"  80{a:06X} {WIDE_TABLE[v]:04X}")
        print("\nTest each alone in RALibretro: the right one widens the")
        print("picture without breaking the HUD.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\nInterrupted - every write was restored after its test.")
        sys.exit(130)
