#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PS2CHDtoOPLPS2.py

Brings a Batocera PS2 library (.chd) onto an OPL / RETROLauncher drive, converted
to plain .iso, named the way OPL wants, and sorted into CD/ and DVD/.

    D:\\batocera\\roms\\ps2\\Air Blade.chd
        -> E:\\DVD\\SCES_502.46.Air Blade.iso

WHAT IT DOES NOT DO: it never writes to the source folder, and it never deletes
anything on the destination that it did not put there itself.

--------------------------------------------------------------------------------
HOW IT KNOWS WHAT IS ALREADY THERE
--------------------------------------------------------------------------------
By SIZE, and that is the whole trick.

Matching by title does not work here. The Batocera names and the OPL names are
both hand-made and they disagree: "Grand Theft Auto 3.chd" is "GTA3.iso" on the
drive, "Alone in the Dark - The New Nightmare.chd" is "AOLD - The New Nightmare",
"Castlevania - a Lament of Innocence" is "Cast - a Lament of Inn". Tested on the
real library: title matching called 50 games missing, of which several were
already there under a shortened name. Converting those would have cost hours and
tens of gigabytes for nothing.

A CHD header carries the exact uncompressed size, so no decompression is needed
to know what a file will weigh:

    offset  8  header length
    offset 12  version (5 expected)
    offset 32  logicalbytes, big-endian     <- the whole disc, in CHD units
    offset 56  hunkbytes
    offset 60  unitbytes                    <- 2448 here

unitbytes is 2448 and not 2048 because these CHDs describe the disc as CD sectors:
2352 bytes of sector plus 96 of subchannel. An .iso holds only the 2048 user bytes
of each one, so:

    iso_size = logicalbytes / 2448 * 2048

Verified on four games known to be on both sides - the ratio is exactly 1.195312
every time. On the real library that identifies 159 of 192 games with no
decompression at all.

That figure is an estimate, good to a sector or two: the BIN that comes out of
extractcd holds one to three sectors fewer than the header implies, which is the
lead-out. Close enough to compare against the drive, not close enough to validate
a conversion against - the real size is taken from the file once it exists.

A size does NOT identify a game on its own, and that is not theoretical. On the
real library seven games share exactly 4 698 767 360 bytes - Devil May Cry I and
II, GTA3, Resident Evil Outbreak, Street Fighter Alpha Anthology, Manhunt - which
is simply a DVD-5 image padded to capacity. Three more sizes are shared by two
games each.

So the size narrows it down to a small group, and the title decides inside that
group. If no title in the group resembles the source filename, the game is
reported as AMBIGUOUS and left alone rather than assumed present - skipping a game
that is actually missing is the one mistake that is invisible afterwards.

The title comparison is deliberately loose and acronym-aware, because
"Grand Theft Auto 3" has to match "GTA3".

The list of what is on the drive comes from OPL Manager's own cache,
"cache_normal.dat", an XML with <ID>, <Title>, <File>, <Media> and <Size> per
game. If it is missing, the destination folders are scanned directly.

--------------------------------------------------------------------------------
THE NAME
--------------------------------------------------------------------------------
    <ID>.<Title>.iso        SCES_502.46.Air Blade.iso

The ID is read from SYSTEM.CNF inside the produced ISO - the real one the console
uses, not a guess from the filename. The title is the Batocera filename with the
region and language tags stripped, which is what you asked for: no dependency on
an external title database.

--------------------------------------------------------------------------------
CD OR DVD
--------------------------------------------------------------------------------
By size, 700 MB. Confirmed against the existing library: the largest CD is 641 MB
and the smallest DVD is 707 MB, so the two groups do not overlap. The threshold is
CD_MAX_BYTES below if you ever need to move it.

--------------------------------------------------------------------------------
USAGE
--------------------------------------------------------------------------------
    python PS2CHDtoOPLPS2.py                 dry run - says what it would do
    python PS2CHDtoOPLPS2.py --go            actually convert and copy
    python PS2CHDtoOPLPS2.py --go --limit 3  the first three only, to try it out
    python PS2CHDtoOPLPS2.py --go --replace  also overwrite different dumps

A game can be on the drive already and still not match by size: the Batocera CHD
is simply a different dump of the same disc. That happened to God Of War I, 7 Sins
and Half-Life on the real library. The copy on the drive is the one that has been
tested on the console, so by default such a game is converted and LEFT in the
scratch folder rather than overwriting a working file. --replace overrides that.

Everything is converted into WORK_DIR first (a fast local disk), checked, and only
then copied to the destination. Nothing half-written ever reaches the PS2 drive.

--------------------------------------------------------------------------------
VERIFIED ON HARDWARE
--------------------------------------------------------------------------------
Both sector layouts, booted on a real PS2:

    Pink Pong          2352, Mode 2 Form 1, from the scratch folder  boots
    Zombie Hunters 2   2352, Mode 2 Form 1, larger               boots
    Killer 7           2048, straight from the drive             boots
    Jak 3              2048, straight from the drive             boots

The first two are the ones that were broken while the offset was 16.
"""

import os
import re
import shutil
import struct
import subprocess
import sys
import unicodedata
import xml.etree.ElementTree as ET

# ------------------------------------------------------------------ configuration

SOURCE_DIR = r"D:\batocera\roms\ps2"
DEST_DIR = r"E:\ "[:-1]                     # E:\  -> DVD\ and CD\ live here
CHDMAN_DIR = r"D:\DOCS\Documents\a-Emulation\Batocera\Windows Tools\CHDMAN (RetroPie User-Friendly)"
OPL_MANAGER_DIR = r"D:\DOCS\Documents\a-Emulation\EmuWindows\Sony-PS2\OPL Manager"

# Known-good conversions. Anything here wins over what is on the destination:
# if the drive holds a different file for the same game, it gets replaced.
REFERENCE_DIR = r"D:\Temp\Mathieu"

# Scratch space. Conversion happens here - keep it on the SSD, it is much faster
# than writing a 4 GB ISO straight to the PS2 drive. Files that do not fit on the
# destination stay here, under Converted\CD and Converted\DVD.
WORK_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Converted")

CD_MAX_BYTES = 700 * 1024 * 1024

# Leave this much free on the destination rather than filling it to the last byte.
KEEP_FREE_BYTES = 1 * 1024 * 1024 * 1024

CHD_UNIT = 2448          # bytes per sector in the CHD (Mode 1 + subchannel)
ISO_UNIT = 2048          # bytes per sector in an .iso (user data only)


# ------------------------------------------------------------------ CHD header

def chd_iso_size(path):
    """Uncompressed .iso size of a CHD, read from its header alone.

    Returns None if the file is not a CHD v5 or the geometry is not what we
    expect - better to say "I do not know" than to return a wrong number that
    would make the script skip a game it should have converted.
    """
    try:
        with open(path, "rb") as f:
            head = f.read(64)
    except OSError:
        return None
    if len(head) < 64 or head[:8] != b"MComprHD":
        return None
    if struct.unpack(">I", head[12:16])[0] != 5:
        return None
    logical = struct.unpack(">Q", head[32:40])[0]
    unit = struct.unpack(">I", head[60:64])[0]
    if unit not in (ISO_UNIT, CHD_UNIT) or logical % unit:
        return None
    return logical // unit * ISO_UNIT


# ------------------------------------------------------------------ SYSTEM.CNF

def read_game_id(iso_path):
    """The PS2 game ID, read from SYSTEM.CNF inside the ISO.

    SYSTEM.CNF sits in the root directory and holds a line such as

        BOOT2 = cdrom0:\\SLES_503.30;1

    Rather than walk ISO9660 properly, the first 64 MB are scanned for that
    pattern - the root directory of a PS2 disc is always well inside that, and it
    keeps this function to a dozen lines with nothing to get wrong.
    """
    pattern = re.compile(rb"([A-Z]{4})_?(\d{3})\.?(\d{2})\s*;1")
    try:
        with open(iso_path, "rb") as f:
            for _ in range(64):
                chunk = f.read(1024 * 1024)
                if not chunk:
                    break
                m = pattern.search(chunk)
                if m:
                    return "%s_%s.%s" % (m.group(1).decode(), m.group(2).decode(),
                                         m.group(3).decode())
    except OSError:
        pass
    return None


# ------------------------------------------------------------------ names

_TAGS = re.compile(
    r"\((?:europe|usa|japan|france|germany|spain|italy|world|eu|us|jp|fr|de|es|it|au)"
    r"[^)]*\)|\((?:en|fr|de|es|it|nl|pt|sv|no|da|fi|ja)[,\s][^)]*\)|\[[^\]]*\]",
    re.I)


def clean_title(filename):
    """Batocera filename -> title for the OPL name.

    Region and language tags go, the rest is kept as it is: "Burnout 2 - Point Of
    Impact" is already how you name things, and second-guessing it would only
    produce a name you did not choose.
    """
    name = os.path.splitext(os.path.basename(filename))[0]
    name = _TAGS.sub(" ", name)
    name = name.replace("_", " ")
    name = re.sub(r"\s{2,}", " ", name).strip(" -.")
    # Windows will not take these, and OPL reads the name off the filesystem.
    name = re.sub(r'[<>:"/\\|?*]', "-", name)
    # OPL truncates the displayed name; keep it sane.
    return name[:60].strip()


# ------------------------------------------------------------------ OPL naming
#
# OPL refuses a title longer than 32 characters, and only accepts
# A-Z a-z 0-9 space - _ ( ) [ ]. It says so in its "Invalid files" tab, after the
# fact, once the file is already on the drive - so the check belongs here instead.
OPL_TITLE_MAX = 32
OPL_TITLE_ALLOWED = re.compile(r"^[A-Za-z0-9 _()\[\]-]+$")

# Decisions already made, so the same question is not asked twice.
TITLES_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                           "PS2CHDtoOPLPS2-titles.json")


def opl_title_problem(title):
    """None if OPL will take this title, otherwise what is wrong with it."""
    if not title:
        return "empty"
    if len(title) > OPL_TITLE_MAX:
        return "%d characters, OPL allows %d" % (len(title), OPL_TITLE_MAX)
    if not OPL_TITLE_ALLOWED.match(title):
        bad = sorted(set(c for c in title if not OPL_TITLE_ALLOWED.match(c)))
        return "forbidden character(s): %s" % " ".join(repr(c) for c in bad)
    return None


def propose_title(title):
    """A title OPL will accept, as close to the original as possible.

    Only a proposal - it is shown for editing, never applied silently. Renaming a
    game without asking is how a library stops being recognisable.
    """
    t = title.replace("&", " and ")
    # "Tour de France, Le" is the catalogue form; the article belongs in front.
    m = re.match(r"^(.*), (Le|La|Les|The|A|An|Der|Die|Das|El|Los|Il)$", t)
    if m:
        t = "%s %s" % (m.group(2), m.group(1))
    t = re.sub(r"[^A-Za-z0-9 _()\[\]-]", " ", t)
    t = re.sub(r"\s{2,}", " ", t).strip(" -")

    if len(t) <= OPL_TITLE_MAX:
        return t

    # Too long. Abbreviate what comes before a " - " to its initials, which is the
    # convention already used on the drive: "DBZ - Budokai 3", "TR - 2 Legend".
    if " - " in t:
        head, tail = t.split(" - ", 1)
        short = "".join(w[0].upper() for w in re.split(r"[^A-Za-z0-9]+", head) if w)
        candidate = ("%s - %s" % (short, tail)).strip()
        if 0 < len(candidate) <= OPL_TITLE_MAX:
            return candidate

    # Still too long: drop whole words from the end rather than cut mid-word.
    words = t.split()
    while words and len(" ".join(words)) > OPL_TITLE_MAX:
        words.pop()
    return " ".join(words) or t[:OPL_TITLE_MAX]


def load_titles():
    try:
        import json
        with open(TITLES_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_titles(mapping):
    try:
        import json
        with open(TITLES_FILE, "w", encoding="utf-8") as f:
            json.dump(mapping, f, indent=2, ensure_ascii=False, sort_keys=True)
    except OSError:
        pass


def ascii_key(text):
    """Letters and digits only, lowercase, tags removed."""
    text = unicodedata.normalize("NFKD", text or "").encode("ascii", "ignore").decode()
    text = re.sub(r"\([^)]*\)|\[[^\]]*\]", " ", text)
    return re.sub(r"[^a-z0-9]+", "", text.lower())


def initials(text):
    """"Grand Theft Auto 3" -> "gta3". Digits are kept as they are."""
    text = unicodedata.normalize("NFKD", text or "").encode("ascii", "ignore").decode()
    text = re.sub(r"\([^)]*\)|\[[^\]]*\]", " ", text).lower()
    out = []
    for word in re.split(r"[^a-z0-9]+", text):
        if not word:
            continue
        out.append(word if word[0].isdigit() else word[0])
    return "".join(out)


def same_game(source_name, drive_title):
    """Do these two names plausibly designate the same game?

    Only ever used to pick inside a group of same-sized candidates, never to
    declare a match on its own. Being generous here is safe; being strict would
    turn a correct match into a needless four-gigabyte conversion.
    """
    a, b = ascii_key(source_name), ascii_key(drive_title)
    if not a or not b:
        return False
    if a == b or a.startswith(b) or b.startswith(a):
        return True
    if len(b) >= 4 and b in a:
        return True
    if len(a) >= 4 and a in b:
        return True
    # "Grand Theft Auto 3" vs "GTA3", "Alone in the Dark ..." vs "AOLD - ..."
    return initials(source_name) == b or initials(drive_title) == a


# ------------------------------------------------------------------ destination

def load_opl_cache():
    """What OPL Manager thinks is on the drive: size -> list of (id, title, media).

    Sizes are the key. Several games can share one size in theory, so the value is
    a list and a collision is reported rather than resolved silently.
    """
    path = os.path.join(OPL_MANAGER_DIR, "cache_normal.dat")
    by_size = {}
    if not os.path.isfile(path):
        return by_size
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as exc:
        print("  ! cache_normal.dat unreadable (%s), scanning the drive instead" % exc)
        return by_size
    for game in root.findall("Game"):
        try:
            size = int(game.findtext("Size") or 0)
        except ValueError:
            continue
        if size:
            by_size.setdefault(size, []).append((
                game.findtext("ID"), game.findtext("Title"),
                game.findtext("Media"), game.findtext("File")))
    return by_size


def scan_folder_sizes(folder):
    """Fallback, and also a cross-check: the real sizes on disk right now."""
    found = {}
    for sub in ("CD", "DVD"):
        d = os.path.join(folder, sub)
        if not os.path.isdir(d):
            continue
        for name in os.listdir(d):
            if name.lower().endswith(".iso"):
                full = os.path.join(d, name)
                try:
                    found.setdefault(os.path.getsize(full), []).append(
                        (None, os.path.splitext(name)[0], sub, full))
                except OSError:
                    pass
    return found


# The CHD-derived size is short by one to three sectors of lead-out, so an exact
# lookup misses games that ARE on the drive: God Of War, Oni, Tekken Tag and
# Theme Park World were all converted again for a difference of six kilobytes.
# Sixteen sectors of slack is far below the gap between two real dumps, which is
# tens of megabytes.
SIZE_SLACK = 16 * ISO_UNIT


def lookup_size(by_size, sorted_sizes, size):
    """Entries whose size is within SIZE_SLACK of the one asked for."""
    exact = by_size.get(size)
    if exact:
        return exact
    out = []
    import bisect
    lo = bisect.bisect_left(sorted_sizes, size - SIZE_SLACK)
    hi = bisect.bisect_right(sorted_sizes, size + SIZE_SLACK)
    for candidate in sorted_sizes[lo:hi]:
        out.extend(by_size[candidate])
    return out


def free_space(path):
    try:
        return shutil.disk_usage(path).free
    except OSError:
        return 0


# ------------------------------------------------------------------ conversion

def find_chdman():
    """Any executable whose name contains "chdman".

    Not just "chdman.exe": the RetroPie User-Friendly pack ships it as
    "a-chdman.exe", so an exact-name search found nothing at all.
    """
    for base in (CHDMAN_DIR, os.path.dirname(os.path.abspath(__file__))):
        if not os.path.isdir(base):
            continue
        for root, _dirs, files in os.walk(base):
            for f in sorted(files):
                low = f.lower()
                if "chdman" in low and low.endswith((".exe", "")) and not low.endswith(".bat"):
                    full = os.path.join(root, f)
                    if os.path.isfile(full):
                        return full
    return shutil.which("chdman") or shutil.which("chdman.exe")


def chd_to_iso(chdman, chd_path, iso_path, expected_size):
    """CHD -> .iso, going through the .bin/.cue that extractcd produces.

    These CHDs are CD-type (compressors cdlz/cdzl/cdfl, 2448-byte units), so
    extractcd is the right command even for a DVD game. It gives a BIN whose
    sectors still carry their sync, header and error correction; the ISO is the
    2048 user bytes of each one.
    """
    stem = os.path.splitext(iso_path)[0]
    cue, binf = stem + ".cue", stem + ".bin"
    for leftover in (cue, binf, iso_path):
        if os.path.exists(leftover):
            os.remove(leftover)

    cmd = [chdman, "extractcd", "-i", chd_path, "-o", cue, "-ob", binf, "-f"]
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if proc.returncode != 0 or not os.path.isfile(binf):
        return None, (proc.stdout or b"").decode("utf-8", "replace").strip()[-300:]

    # The sector size is read from the BIN, NOT deduced from the expected count.
    #
    # Two things vary and the first version of this got both wrong. The sector
    # size is 2048 on some discs and 2352 on others, depending on how the CHD was
    # made - God Of War I and Oni come out at 2048, 7 Sins and Mister Mosquito at
    # 2352. And the BIN holds one to three sectors FEWER than the CHD header
    # implies, which is the lead-out. Deriving the sector size from the expected
    # count therefore failed on seven games out of thirty-three, all of them
    # perfectly convertible.
    bin_size = os.path.getsize(binf)
    raw = None
    for candidate in (ISO_UNIT, 2352, CHD_UNIT, 2336):
        if bin_size % candidate == 0:
            raw = candidate
            break
    if raw is None:
        os.remove(binf)
        if os.path.exists(cue):
            os.remove(cue)
        return None, "no known sector size divides the BIN (%d bytes)" % bin_size

    sectors = bin_size // raw
    drift = expected_size // ISO_UNIT - sectors
    if abs(drift) > 16:
        os.remove(binf)
        if os.path.exists(cue):
            os.remove(cue)
        return None, ("BIN has %d sectors of %d, header implied %d - too far apart"
                      % (sectors, raw, expected_size // ISO_UNIT))

    if raw == ISO_UNIT:
        os.replace(binf, iso_path)
    else:
        # WHERE the user data starts inside a raw sector depends on the mode, and
        # getting this wrong produces an ISO that looks plausible and does not
        # boot - the console says "not a PlayStation 2 disc".
        #
        #   Mode 1        12 sync + 4 header +                2048 data + 288 EDC/ECC
        #   Mode 2 Form 1 12 sync + 4 header + 8 subheader +  2048 data + 280 EDC
        #
        # PS2 CD games are Mode 2 Form 1, like PS1 ones. Taking offset 16 on those
        # copies the 8 subheader bytes and loses the last 8 data bytes of every
        # sector, so the whole filesystem is shifted by eight. That is exactly what
        # happened to 7 Sins while Half-Life, whose BIN was already 2048, was fine.
        #
        # Byte 15 of the sector carries the mode, right after the 12 sync bytes and
        # the 3 minute/second/frame bytes.
        with open(binf, "rb") as src:
            first = src.read(raw)
        if first[:12] != b"\x00" + b"\xff" * 10 + b"\x00":
            os.remove(binf)
            if os.path.exists(cue):
                os.remove(cue)
            return None, "raw sector without a sync pattern - unexpected layout"
        mode = first[15]
        if mode == 2:
            offset = 24
        elif mode == 1:
            offset = 16
        else:
            os.remove(binf)
            if os.path.exists(cue):
                os.remove(cue)
            return None, "unknown sector mode %d" % mode

        with open(binf, "rb") as src, open(iso_path, "wb") as dst:
            while True:
                sector = src.read(raw)
                if len(sector) < raw:
                    break
                dst.write(sector[offset:offset + ISO_UNIT])
        os.remove(binf)
    if os.path.exists(cue):
        os.remove(cue)

    got = os.path.getsize(iso_path)
    if got != sectors * ISO_UNIT:
        return None, "short write: %d bytes for %d sectors" % (got, sectors)
    return iso_path, ("%d sector(s) of lead-out trimmed" % drift) if drift else None


# ------------------------------------------------------------------ main

def human(n):
    return "%.2f GB" % (n / (1024.0 ** 3))


def main():
    go = "--go" in sys.argv
    replace = "--replace" in sys.argv
    limit = None
    if "--limit" in sys.argv:
        try:
            limit = int(sys.argv[sys.argv.index("--limit") + 1])
        except (IndexError, ValueError):
            pass

    print("=" * 74)
    print("PS2 CHD -> OPL ISO" + ("" if go else "        DRY RUN - nothing will be written"))
    print("=" * 74)
    print("  source      : %s" % SOURCE_DIR)
    print("  destination : %s" % DEST_DIR)
    print("  scratch     : %s" % WORK_DIR)

    if not os.path.isdir(SOURCE_DIR):
        print("\n  ! source folder not found"); return 1

    chdman = find_chdman()
    print("  chdman      : %s" % (chdman or "NOT FOUND"))
    if go and not chdman:
        print("\n  ! chdman.exe is required to convert. Check CHDMAN_DIR."); return 1

    # ---- what is already on the drive -------------------------------------
    # BOTH sources, merged. The cache carries the game IDs, which a directory
    # listing cannot give; the listing carries whatever has been added since OPL
    # Manager last ran - including everything a previous run of THIS script
    # copied. On the cache alone, a second run would convert those all over again.
    on_drive = load_opl_cache()
    from_cache = sum(len(v) for v in on_drive.values())
    seen = set()
    for entries in on_drive.values():
        for _gid, _t, _m, f in entries:
            if f:
                seen.add(os.path.normcase(os.path.basename(f)))
    added = 0
    for size, entries in scan_folder_sizes(DEST_DIR).items():
        for entry in entries:
            if os.path.normcase(os.path.basename(entry[3])) not in seen:
                on_drive.setdefault(size, []).append(entry)
                added += 1
    print("  known there : %d games (OPL cache %d + %d found on the drive)"
          % (from_cache + added, from_cache, added))

    reference = scan_folder_sizes(REFERENCE_DIR) if os.path.isdir(REFERENCE_DIR) else {}
    if reference:
        print("  reference   : %d known-good ISOs in %s" % (
            sum(len(v) for v in reference.values()), REFERENCE_DIR))

    # ---- the delta ---------------------------------------------------------
    sizes_sorted = sorted(on_drive)
    todo, present, unreadable, ambiguous = [], [], [], []
    for name in sorted(os.listdir(SOURCE_DIR)):
        if not name.lower().endswith(".chd"):
            continue
        full = os.path.join(SOURCE_DIR, name)
        size = chd_iso_size(full)
        if size is None:
            unreadable.append(name)
            continue
        group = lookup_size(on_drive, sizes_sorted, size)
        if not group:
            todo.append((name, size))
        elif len(group) == 1:
            present.append((name, size, group[0]))
        else:
            # Several games share this size. The title decides.
            stem = os.path.splitext(name)[0]
            picked = [g for g in group if same_game(stem, g[1])]
            if picked:
                present.append((name, size, picked[0]))
            else:
                ambiguous.append((name, size, group))

    print()
    print("  %-28s %4d" % ("CHD in the source", len(todo) + len(present) + len(unreadable)))
    print("  %-28s %4d" % ("already on the drive", len(present)))
    print("  %-28s %4d   %s once extracted" % ("to convert", len(todo), human(sum(s for _, s in todo))))
    if unreadable:
        print("  %-28s %4d" % ("header unreadable", len(unreadable)))
        for n in unreadable[:5]:
            print("        %s" % n)
    if ambiguous:
        print("\n  ! %d ambiguous - the size matches a group but no title does." % len(ambiguous))
        print("    NOT converted and NOT counted as present. Decide by hand:")
        for n, s, m in ambiguous:
            print("        %s  (%s)" % (n, human(s)))
            print("            drive has at this size: %s" % ", ".join(str(x[1]) for x in m))

    if not todo:
        print("\n  Nothing to do - the drive already has every game in the source.")
        return 0

    # ---- room -------------------------------------------------------------
    room = free_space(DEST_DIR) - KEEP_FREE_BYTES
    need = sum(s for _, s in todo)
    print("\n  free on destination : %s   needed : %s" % (human(free_space(DEST_DIR)), human(need)))
    if need > room:
        print("  -> will not all fit. What does not fit stays in %s" % WORK_DIR)

    if limit:
        todo = todo[:limit]
        print("  -> limited to the first %d" % len(todo))

    # ---- titles, settled before anything is converted ----------------------
    # OPL rejects a title over 32 characters or carrying anything outside
    # A-Z a-z 0-9 space - _ ( ) [ ], and it only says so afterwards, in its
    # "Invalid files" tab, once the file is already on the drive. Asking here
    # costs a few seconds and saves a four-gigabyte round trip.
    remembered = load_titles()
    titles, asked = {}, False
    for name, _size in todo:
        raw_title = clean_title(name)
        if name in remembered:
            titles[name] = remembered[name]
            continue
        problem = opl_title_problem(raw_title)
        if not problem:
            titles[name] = raw_title
            continue
        suggestion = propose_title(raw_title)
        if not go:
            print("\n  ! OPL will refuse \"%s\"" % raw_title)
            print("      %s" % problem)
            print("      suggestion: %s" % suggestion)
            titles[name] = suggestion
            continue
        asked = True
        print("\n  OPL will refuse this title:")
        print("      %s" % raw_title)
        print("      %s" % problem)
        try:
            answer = input("  name it [%s] : " % suggestion).strip()
        except (EOFError, KeyboardInterrupt):
            answer = ""
            print()
        chosen = answer or suggestion
        while opl_title_problem(chosen):
            print("      still refused: %s" % opl_title_problem(chosen))
            try:
                answer = input("  name it [%s] : " % suggestion).strip()
            except (EOFError, KeyboardInterrupt):
                chosen = suggestion
                print()
                break
            chosen = answer or suggestion
        titles[name] = chosen
        remembered[name] = chosen
    if asked:
        save_titles(remembered)
        print("\n  Choices saved to %s - they will not be asked again."
              % os.path.basename(TITLES_FILE))

    if not go:
        print("\n  Would convert:")
        for name, size in todo:
            media = "CD" if size <= CD_MAX_BYTES else "DVD"
            print("    [%s] %8s  %s" % (media, human(size), titles[name]))
        print("\n  Re-run with --go to do it.")
        return 0

    # ---- work -------------------------------------------------------------
    # ID -> (size, file) for everything already on the drive, to spot a game that
    # is present under a different dump.
    by_id = {}
    for size_key, entries in on_drive.items():
        for gid, title, _media, fpath in entries:
            # A file found by scanning has no ID field, but the OPL naming puts it
            # at the front of the filename, so it can be read straight off.
            if not gid and fpath:
                head = os.path.basename(fpath).split(".")
                if len(head) >= 3 and re.match(r"^[A-Z]{4}_\d{3}$", head[0]):
                    gid = "%s.%s" % (head[0], head[1])
            if gid:
                by_id.setdefault(gid, (size_key, fpath or title))

    ok, failed, overflow, different, skipped, raw_on_drive = 0, [], 0, 0, 0, 0
    for index, (name, size) in enumerate(todo, 1):
        media = "CD" if size <= CD_MAX_BYTES else "DVD"
        title = titles[name]
        work_sub = os.path.join(WORK_DIR, media)
        os.makedirs(work_sub, exist_ok=True)
        tmp_iso = os.path.join(work_sub, "~converting.iso")

        print("\n[%d/%d] %s   (%s, %s)" % (index, len(todo), title, media, human(size)))

        if free_space(WORK_DIR) < size + KEEP_FREE_BYTES:
            print("      ! not enough scratch space, stopping here")
            break

        iso, err = chd_to_iso(chdman, os.path.join(SOURCE_DIR, name), tmp_iso, size)
        if not iso:
            print("      ! conversion failed: %s" % err)
            failed.append((name, err))
            if os.path.exists(tmp_iso):
                os.remove(tmp_iso)
            continue
        if err:
            print("      %s" % err)
        size = os.path.getsize(iso)      # the truth, now that it exists

    # Nothing was written to the drive yet, so a missing ID is not fatal.
        game_id = read_game_id(iso)
        if not game_id:
            print("      ! no game ID in SYSTEM.CNF - keeping it, but named without an ID")
        final_name = ("%s.%s.iso" % (game_id, title)) if game_id else ("%s.iso" % title)

        # A reference conversion, if we have one, wins over what we just made.
        ref = reference.get(size)
        if ref and os.path.isfile(ref[0][3]):
            print("      using the reference copy from %s" % REFERENCE_DIR)
            os.remove(iso)
            iso = ref[0][3]

        dest_sub = os.path.join(DEST_DIR, media)
        target = os.path.join(dest_sub, final_name)

        # Same game, different dump. The drive holds a copy that has been played
        # on the console; this one has not. Keep the tested one unless told.
        rival = by_id.get(game_id) if game_id else None

        # Same disc, but the copy on the drive is a RAW image renamed .iso.
        #
        # A CD sector is 2352 bytes; an .iso keeps only the 2048 user bytes. When
        # the file on the drive is exactly 2352/2048 larger and both divide into
        # the same sector count, it is not another dump - it is the same disc with
        # the sync, header and error-correction bytes still in it. Eight games out
        # of nine were in that state, and calling them "different dumps" said
        # nothing useful.
        if rival and rival[0] % 2352 == 0 and size % ISO_UNIT == 0 \
           and rival[0] // 2352 == size // ISO_UNIT:
            print("      the drive holds a RAW 2352-byte-per-sector image of this")
            print("        drive %d bytes = %d sectors x 2352 (sync + header + ECC kept)"
                  % (rival[0], rival[0] // 2352))
            print("        this  %d bytes = %d sectors x 2048 (a real .iso)"
                  % (size, size // ISO_UNIT))
            if not replace:
                keep = os.path.join(work_sub, final_name)
                print("      kept here: %s   (--replace to swap it in)" % keep)
                if iso.startswith(WORK_DIR):
                    os.replace(iso, keep)
                else:
                    shutil.copy2(iso, keep)
                raw_on_drive += 1
                continue
            print("      replacing the raw image")

        elif rival and abs(rival[0] - size) <= SIZE_SLACK:
            # Same disc after all: the gap is only the lead-out. Nothing to do.
            print("      already on the drive (same dump, %+d bytes)" % (size - rival[0]))
            if iso.startswith(WORK_DIR) and os.path.exists(iso):
                os.remove(iso)
            skipped += 1
            continue
        if rival and not replace:
            keep = os.path.join(work_sub, final_name)
            print("      already on the drive as a DIFFERENT dump:")
            print("        drive   %s  (%d bytes)" % (os.path.basename(rival[1] or "?"), rival[0]))
            print("        this    %s  (%d bytes, %+d)" % (final_name, size, size - rival[0]))
            print("      kept here instead: %s   (--replace to overwrite)" % keep)
            os.replace(iso, keep) if iso.startswith(WORK_DIR) else shutil.copy2(iso, keep)
            different += 1
            continue

        fits = os.path.isdir(dest_sub) and free_space(DEST_DIR) >= size + KEEP_FREE_BYTES

        if fits:
            # Replace a wrong file for the same game rather than leave two.
            for existing in os.listdir(dest_sub):
                if game_id and existing.startswith(game_id) and existing != final_name:
                    print("      replacing %s" % existing)
                    os.remove(os.path.join(dest_sub, existing))
            print("      -> %s" % target)
            shutil.move(iso, target) if iso.startswith(WORK_DIR) else shutil.copy2(iso, target)
        else:
            keep = os.path.join(work_sub, final_name)
            print("      no room on the destination -> %s" % keep)
            if iso.startswith(WORK_DIR):
                os.replace(iso, keep)
            else:
                shutil.copy2(iso, keep)
            overflow += 1
        ok += 1

    print("\n" + "=" * 74)
    print("  converted   : %d" % ok)
    if overflow:
        print("  left in %s : %d (no room on the destination)" % (WORK_DIR, overflow))
    if skipped:
        print("  already there : %d (same dump, nothing written)" % skipped)
    if raw_on_drive:
        print("  raw images on the drive : %d - same discs, kept in %s" % (raw_on_drive, WORK_DIR))
        print("      --replace swaps them for the proper .iso (smaller, and tested)")
    if different:
        print("  different dumps : %d kept in %s, drive untouched" % (different, WORK_DIR))
    if failed:
        print("  failed      : %d" % len(failed))
        for n, e in failed:
            print("      %s  -  %s" % (n, e))
    print("  Run OPL Manager once afterwards so its cache picks up the new games.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
