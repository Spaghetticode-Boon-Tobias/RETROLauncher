#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MediaCopier.py

Pulls box art, screenshots and real game titles from a Batocera / Recalbox /
EmulationStation install, and lays them out the way RETROLauncher expects.

Artwork is named after the ROM file without its extension:

    Roms/<system>/media/covers/<rom without extension>.png
    Roms/<system>/media/screenshots/<rom without extension>.png

Everything is written to the USB stick, because the launcher checks the boot
device first. Games on the internal exFAT disk are found either through
"exfatdb.json", the inventory the console writes next to its ELF, or by reading
the disk directly if it happens to be mounted on this PC.

Titles go to a "titles.txt" next to the artwork, one "file|title" pair per line.
File names are never modified.
"""

import json
import shutil
import sys
import unicodedata
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

# --- Systems ------------------------------------------------------------------
# long    : name reported by the console in exfatdb.json ("sistema")
# es      : folder names on the Batocera / Recalbox side
# folders : folder names accepted under Roms/, old and new
# dir     : canonical folder for this fork, where artwork is written
SYSTEMS = [
    {"long": "Sega Megadrive", "dir": "megadrive",
     "es": ["megadrive", "genesis"],
     "folders": ["megadrive", "genesis", "md", "Roms Sega Megadrive"]},
    {"long": "Sega Master System", "dir": "mastersystem",
     "es": ["mastersystem"],
     "folders": ["mastersystem", "sms", "Roms Sega Master System"]},
    {"long": "Sega Game Gear", "dir": "gamegear",
     "es": ["gamegear"],
     "folders": ["gamegear", "gg", "Roms Sega Game Gear"]},
    {"long": "Sega SG-1000", "dir": "sg1000",
     "es": ["sg1000", "sg-1000", "sega-sg1000"],
     "folders": ["sg1000", "sg-1000", "Roms Sega SG-1000"]},
    {"long": "Nintendo Famicom", "dir": "nes",
     "es": ["nes", "famicom", "fds"],
     "folders": ["nes", "famicom", "fds", "Roms Nintendo Famicom"]},
    {"long": "Nintendo Super Famicom", "dir": "snes",
     "es": ["snes", "sfc", "supernintendo"],
     "folders": ["snes", "sfc", "supernintendo", "Roms Nintendo Super Famicom"]},
    {"long": "Nintendo Game Boy", "dir": "gb",
     "es": ["gb", "gameboy"],
     "folders": ["gb", "gameboy", "Roms Nintendo Game Boy"]},
    {"long": "Nintendo Game Boy Color", "dir": "gbc",
     "es": ["gbc", "gameboycolor"],
     "folders": ["gbc", "gameboycolor", "Roms Nintendo Game Boy Color"]},
    {"long": "Nintendo Game Boy Advance", "dir": "gba",
     "es": ["gba", "gameboyadvance"],
     "folders": ["gba", "gameboyadvance", "Roms Nintendo Game Boy Advance"]},
    {"long": "Atari 2600", "dir": "atari2600",
     "es": ["atari2600"],
     "folders": ["atari2600", "Roms Atari 2600"]},
    {"long": "Atari Lynx", "dir": "lynx",
     "es": ["lynx", "atarilynx"],
     "folders": ["lynx", "atarilynx", "Roms Atari Lynx"]},
    {"long": "Neo Geo Pocket", "dir": "ngp",
     "es": ["ngp", "ngpc", "neogeopocket"],
     "folders": ["ngp", "ngpc", "neogeopocket", "Roms Neo Geo Pocket"]},
    {"long": "PlayStation", "dir": "psx-ember(bin and cue)",
     "es": ["psx"],
     "folders": ["psx-ember(bin and cue)", "psx", "CUEs PlayStation 1"]},
    # Same games, other container: POPStarter takes .vcd, Ember takes .cue+.bin.
    # The Batocera gamelist is indexed on the stem, so both resolve against "psx".
    {"long": "PlayStation POPS", "dir": "psx-pops(vcd)",
     "es": ["psx"],
     "folders": ["psx-pops(vcd)", "psx-pops", "VCDs PlayStation 1"]},
    {"long": "PlayStation 2", "dir": "ps2-isos",
     "es": ["ps2"],
     "folders": ["ps2-isos", "ps2", "ISOs PlayStation 2"]},
]

TAGS = ["boxart", "image", "thumbnail", "screenshot", "cartridge",
        "mix", "wheel", "marquee"]

SKIP_EXT = {".png", ".txt", ".xml", ".cfg", ".sav", ".srm"}


def ask(question, default=""):
    if default:
        print(f"  default: {default}")
    r = input(f"{question}: ").strip().strip('"').strip("'")
    return r or default


def yes_no(question, default):
    d = "Y/n" if default else "y/N"
    r = input(f"{question} [{d}]: ").strip().lower()
    return default if not r else r in ("y", "yes", "o", "oui")


def pick_tag(role, default):
    print(f"\nGamelist tag for {role}:")
    print("  " + "  ".join(f"{i}.{t}" for i, t in enumerate(TAGS, 1)))
    r = input(f"Number, or Enter for '{default}': ").strip()
    if not r:
        return default
    try:
        n = int(r)
        if 1 <= n <= len(TAGS):
            return TAGS[n - 1]
    except ValueError:
        pass
    return default


def find_system(name):
    """Match a system by its long name (exfatdb) or by a folder name."""
    if not name:
        return None
    low = name.lower()
    for s in SYSTEMS:
        if low == s["long"].lower():
            return s
        if any(low == f.lower() for f in s["folders"]):
            return s
    # Last resort: keyword match, so "Roms Nintendo Game Boy Advance" still
    # resolves even if the exact spelling drifts.
    for s in SYSTEMS:
        if s["long"].lower() in low:
            return s
    return None


def load_gamelist(es_root, syst):
    for name in syst["es"]:
        path = es_root / "roms" / name / "gamelist.xml"
        if path.is_file():
            try:
                root = ET.parse(path).getroot()
            except (ET.ParseError, OSError) as e:
                print(f"    unreadable gamelist ({e})")
                return None, None
            # Indexed twice: by full file name, and by name without extension.
            # A Batocera gamelist often lists ".chd" where the console has the
            # same game as ".cue"/".bin" or ".vcd" - same stem, other container.
            index = {}
            for game in root.findall("game"):
                p = game.findtext("path")
                if not p:
                    continue
                f = Path(p.replace("\\", "/")).name
                index[f.lower()] = game
                index.setdefault(Path(f).stem.lower(), game)
            return index, path.parent
    return None, None


def extract_gba(rom):
    """gpSP cannot read archives, so a .zip has to become a .gba. Returns
    (path, extracted_now) - the second value is False when a previous run
    already did the work, so nothing is redone and nothing is recounted.

    The archive is deleted once the .gba is in place: keeping both makes the
    game appear twice in the launcher and wastes room on the stick."""
    target = rom.with_suffix(".gba")

    def drop_archive():
        # Only ever after checking the extracted file is really there and holds
        # something - never delete the only copy on the strength of a 0-byte file.
        try:
            if target.is_file() and target.stat().st_size > 0 and rom.is_file():
                rom.unlink()
                return True
        except OSError as e:
            print(f"    archive kept ({e}): {rom.name}")
        return False

    if target.exists():
        drop_archive()
        return target, False

    try:
        with zipfile.ZipFile(rom) as z:
            members = [m for m in z.infolist()
                       if not m.is_dir()
                       and Path(m.filename).suffix.lower() in (".gba", ".bin")]
            if not members:
                return None, False
            members.sort(key=lambda m: m.file_size, reverse=True)
            with z.open(members[0]) as src, open(target, "wb") as out:
                shutil.copyfileobj(src, out, 1 << 20)
    except (zipfile.BadZipFile, OSError) as e:
        print(f"    not extracted ({e}): {rom.name}")
        return None, False

    drop_archive()
    return target, True


def opl_id(name):
    """"SCES_502.40.Extermination.iso" -> "SCES_502.40". OPL names its artwork
    after that ID: <ID>_COV.png, <ID>_SCR.png, <ID>_LGO.png..."""
    stem = Path(name).stem
    if len(stem) >= 12 and stem[4] == "_" and stem[11] == ".":
        return stem[:11]
    return None


# Two hard rules from the RETROLauncher manual, page 31:
#
#   "The image must have a transparency mask, otherwise it will not be displayed."
#   "It is recommended to use resolutions lower than 320x240."
#
# The first one is not a suggestion. A PNG without an alpha channel is loaded and
# silently ignored, which is exactly what artwork scraped from Batocera and OPL
# looks like: 8-bit palette, no alpha. Everything is re-encoded to RGBA and fitted
# in the box below. The console has 4 MB of video memory for the whole interface.
MAX_W, MAX_H = 320, 240
_pillow_warned = False


def copy_file(source, target, overwrite):
    global _pillow_warned
    if not source.is_file():
        return False
    if target.exists() and not overwrite:
        return False
    target.parent.mkdir(parents=True, exist_ok=True)
    try:
        from PIL import Image
    except ImportError:
        if not _pillow_warned:
            _pillow_warned = True
            print("  WARNING: Pillow is missing, images are copied unchanged.")
            print("           Without an alpha channel the PS2 will not show them.")
            print("           Install it with:  pip install pillow")
        shutil.copy2(source, target)
        return True
    try:
        with Image.open(source) as im:
            im = im.convert("RGBA")
            if im.width > MAX_W or im.height > MAX_H:
                im.thumbnail((MAX_W, MAX_H), Image.LANCZOS)
            im.save(target, "PNG", optimize=True)
        return True
    except (OSError, ValueError) as e:
        print(f"    unconverted ({e}): {source.name}")
        shutil.copy2(source, target)
        return True


def clean_orphans(usb_root, known):
    """Drop artwork and title lines whose ROM is no longer there. The manual is
    explicit about it, page 31: idle images with no game attached cause long
    pauses, because the launcher still has to walk the folder to look for one.
    Only systems that were actually scanned are touched."""
    orphans, stale = [], []
    for dirname, stems in sorted(known.items()):
        base = usb_root / "Roms" / dirname
        for kind in ("covers", "screenshots"):
            d = base / "media" / kind
            if d.is_dir():
                orphans += [p for p in sorted(d.glob("*.png"))
                            if p.stem.lower() not in stems]
        f = base / "titles.txt"
        if f.is_file():
            try:
                lines = [l for l in f.read_text(encoding="utf-8",
                                                errors="replace").splitlines()
                         if "|" in l]
            except OSError:
                continue
            keep = [l for l in lines
                    if Path(l.split("|", 1)[0]).stem.lower() in stems]
            if len(keep) != len(lines):
                stale.append((f, keep, len(lines) - len(keep)))

    if not orphans and not stale:
        return
    n_titles = sum(s[2] for s in stale)
    print(f"\n{len(orphans)} image(s) and {n_titles} title(s) belong to games "
          f"that are gone.")
    if orphans:
        print(f"  e.g. {orphans[0]}")
    if not yes_no("Delete them?", True):
        return
    n = 0
    for p in orphans:
        try:
            p.unlink()
            n += 1
        except OSError as e:
            print(f"  kept, {e}")
    for f, keep, _c in stale:
        try:
            f.write_text("\n".join(sorted(keep)) + "\n", encoding="utf-8")
        except OSError as e:
            print(f"  {f} unchanged, {e}")
    print(f"  {n} image(s) and {n_titles} title(s) removed.")


def plain_text(s):
    """The manual, page 46: a title holding a special character is displayed wrong
    or not at all. A French or Spanish gamelist is full of them, so accents are
    folded to their base letter and anything left outside ASCII is dropped."""
    s = unicodedata.normalize("NFKD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = (s.replace("Œ", "OE").replace("œ", "oe")
          .replace("Æ", "AE").replace("æ", "ae")
          .replace("Ø", "O").replace("ø", "o")
          .replace("ß", "ss").replace("Ł", "L").replace("ł", "l"))
    for a, b in (("’", "'"), ("‘", "'"), ("“", '"'),
                 ("”", '"'), ("–", "-"), ("—", "-"),
                 ("…", "...")):
        s = s.replace(a, b)
    return "".join(c for c in s if 32 <= ord(c) < 127).strip()


def fix_alpha_in_place(folder):
    """Give every PNG in a folder an alpha channel, without moving or copying it.
    Used on OPL's "ART": the launcher reads that folder directly, so the files
    only have to become loadable, not to be duplicated somewhere else."""
    try:
        from PIL import Image
    except ImportError:
        print(f"  {folder}: Pillow missing, transparency mask not added")
        return
    files = sorted(folder.glob("*.png")) + sorted(folder.glob("*.PNG"))
    if not files:
        return
    todo = []
    for p in files:
        try:
            with Image.open(p) as im:
                if im.mode not in ("RGBA", "LA") and "transparency" not in im.info:
                    todo.append(p)
        except (OSError, ValueError):
            continue
    if not todo:
        print(f"  {folder}: {len(files)} image(s), transparency mask already there")
        return
    print(f"\n  {folder}: {len(todo)} of {len(files)} image(s) have no transparency")
    print("  mask, so RETROLauncher cannot display them. OPL is not affected by")
    print("  the change, and nothing is copied: the files are rewritten in place.")
    if not yes_no("  Add it?", True):
        return
    n = 0
    for p in todo:
        try:
            with Image.open(p) as im:
                im.convert("RGBA").save(p, "PNG", optimize=True)
            n += 1
        except (OSError, ValueError) as e:
            print(f"    skipped ({e}): {p.name}")
    print(f"  {n} image(s) converted.")


def handle_games(names, syst, es_root, usb_root, tag_cover, tag_screen,
                 overwrite, rom_folder=None):
    """Process a list of ROM file names for one system.
    "rom_folder" is set only for local folders, where GBA archives can be
    extracted; it is None for entries coming from exfatdb.json."""
    index, es_folder = load_gamelist(es_root, syst)
    if index is None:
        return None

    base_dir = usb_root / "Roms" / syst["dir"]
    d_cover = base_dir / "media" / "covers"
    d_screen = base_dir / "media" / "screenshots"

    n_cov, n_scr, n_gba, n_miss = 0, 0, 0, 0
    titles = []

    for name in sorted(names):
        if Path(name).suffix.lower() in SKIP_EXT:
            continue

        # PlayStation 2 artwork is NOT copied. OPL already keeps it in "ART" at the
        # root of the drive, named after the game ID, and RETROLauncher reads that
        # folder directly on every drive. Duplicating it would just waste space.
        gid = opl_id(name) if syst["dir"] == "ps2-isos" else None

        # Explicit None test: an XML Element has no meaningful truth value,
        # and 'or' on one raises a DeprecationWarning.
        game = index.get(name.lower())
        if game is None:
            game = index.get(Path(name).stem.lower())
        if game is None:
            # "SCES_502.40.Extermination.iso" already carries its title after
            # the OPL ID. Good enough, and better than showing the raw ID.
            if gid is not None:
                rest = Path(name).stem[len(gid):].strip(". ")
                if rest:
                    titles.append(f"{name}|{plain_text(rest.replace('.', ' '))}")
            else:
                n_miss += 1
            continue

        base = Path(name).stem

        if rom_folder is not None and syst["dir"] == "gba" \
                and name.lower().endswith(".zip"):
            extracted, is_new = extract_gba(rom_folder / name)
            if extracted is not None:
                if is_new:
                    n_gba += 1
                base = extracted.stem

        title = plain_text((game.findtext("name") or ""))
        if title:
            titles.append(f"{name}|{title}")
            if base != Path(name).stem:
                titles.append(f"{base}.gba|{title}")

        rel = game.findtext(tag_cover)
        if rel and copy_file((es_folder / rel.replace("\\", "/")).resolve(),
                             d_cover / f"{base}.png", overwrite):
            n_cov += 1

        rel = game.findtext(tag_screen)
        if rel and copy_file((es_folder / rel.replace("\\", "/")).resolve(),
                             d_screen / f"{base}.png", overwrite):
            n_scr += 1

    if titles:
        base_dir.mkdir(parents=True, exist_ok=True)
        try:
            existing = []
            f = base_dir / "titles.txt"
            if f.is_file():
                existing = [l for l in f.read_text(encoding="utf-8",
                                                   errors="replace").splitlines()
                            if l.strip()]
            merged = {l.split("|", 1)[0]: l for l in existing if "|" in l}
            for l in titles:
                merged[l.split("|", 1)[0]] = l
            f.write_text("\n".join(sorted(merged.values())) + "\n",
                         encoding="utf-8")
        except OSError as e:
            print(f"    titles.txt not written ({e})")

    return n_cov, n_scr, len(titles), n_gba, n_miss


def local_folders(root):
    """(folder, system) pairs under Roms/, de-duplicated. Windows is
    case-insensitive, so "Roms" and "roms" would otherwise be listed twice."""
    found, seen = [], set()
    for container in ("Roms", "Games", "roms"):
        base = root / container
        if not base.is_dir():
            continue
        for d in sorted(base.iterdir()):
            if not d.is_dir():
                continue
            key = str(d.resolve()).lower()
            if key in seen:
                continue
            s = find_system(d.name)
            if s is not None:
                seen.add(key)
                found.append((d, s))
    return found


def exfat_games(db):
    """{system: set(file names)} for what the console saw on the internal disk.
    The file is grouped by support: {"ATA": {"juegos": {"roms/nes": [...]}}}."""
    out = {}
    if not db:
        return out
    for folder, names in (db.get("ATA") or {}).get("juegos", {}).items():
        syst = find_system(folder.split("/")[-1])
        if syst is not None and names:
            out.setdefault(syst["long"], set()).update(names)
    return out


def main():
    print(__doc__.strip())
    print("\n" + "=" * 70 + "\n")

    es_root = Path(ask("Batocera / Recalbox root (e.g. D:\\batocera)"))
    if not (es_root / "roms").is_dir():
        print(f"\nNo 'roms' folder inside {es_root}")
        return 1

    # This script lives in <RETROLauncher>/HelperScripts/, so the launcher root
    # is simply one level up. Nothing to ask.
    usb_root = Path(__file__).resolve().parent.parent
    if not (usb_root / "Roms").is_dir():
        print(f"\nNo 'Roms' folder next to this script (looked in {usb_root}).")
        print("Put MediaCopier.py back in <RETROLauncher>/HelperScripts/.")
        return 1

    # The console reads the USB stick, not the git checkout this script may be
    # sitting in. Enter accepts the folder above; otherwise point at the stick.
    print(f"\nLauncher folder: {usb_root}")
    r = input("Enter to use it, or another RETROLauncher folder "
              "(e.g. F:\\RETROLauncher): ").strip().strip('"').strip("'")
    if r:
        alt = Path(r)
        if (alt / "Roms").is_dir():
            usb_root = alt
            print(f"  Writing to {usb_root}")
        else:
            print(f"  No 'Roms' folder in {alt}, keeping {usb_root}")

    # exfatdb.json: written by the console next to its ELF, so at the root of
    # the launcher folder. Also accepted next to this script.
    print("\nHow should games on the internal exFAT disk be found?")
    print("  1. From exfatdb.json, the inventory written by the console")
    print("  2. By reading the disk directly (it must be mounted on this PC)")
    mode = input("\nNumber [1]: ").strip()

    ata, ata_root = {}, None

    if mode == "2":
        r = ask("\nexFAT disk drive or path (e.g. G:\\)", "")
        if r:
            ata_root = Path(r)
            if not ata_root.is_dir():
                print(f"  Not found: {ata_root}")
                ata_root = None
        if ata_root is not None:
            # PS2 ISOs live in DVD/ and CD/ at the root, not under RETROLauncher.
            ps2 = find_system("PlayStation 2")
            names = set()
            for sub in ("DVD", "CD"):
                folder = ata_root / sub
                if folder.is_dir():
                    names |= {f.name for f in folder.iterdir()
                              if f.is_file()
                              and f.suffix.lower() in (".iso", ".hdd", ".mx4",
                                                       ".mmc", ".udp")}
            if names:
                ata[ps2["long"]] = names
                print(f"  {len(names)} PS2 image(s) in DVD/ and CD/")
            # OPL's own artwork folder. Nothing is copied out of it - the launcher
            # reads it where it is - but OPL writes PNGs without an alpha channel
            # and the PS2 refuses to display those. Adding the mask in place costs
            # no extra space and OPL keeps reading them just as well.
            for cand in (ata_root / "ART", ata_root / "art"):
                if cand.is_dir():
                    fix_alpha_in_place(cand)
                    break

            # POPStarter games live in "POPS/" at the root of the drive, next to
            # its binaries; the launcher lists them together with the library.
            pops = ata_root / "POPS"
            if pops.is_dir():
                vcd = {f.name for f in pops.iterdir()
                       if f.is_file() and f.suffix.lower() == ".vcd"}
                if vcd:
                    ata[find_system("psx-pops(vcd)")["long"]] = vcd
                    print(f"  {len(vcd)} POPStarter .vcd in POPS/")
            # One library, not two. Artwork and titles belong on the USB stick,
            # which the launcher reads first; anything left on the disk by an
            # older run is dead weight that can only conflict.
            strays = []
            for folder, _s in local_folders(ata_root / "RETROLauncher"):
                if (folder / "titles.txt").is_file():
                    strays.append(folder / "titles.txt")
                if (folder / "media").is_dir():
                    strays.append(folder / "media")
            if strays:
                print(f"\n  {len(strays)} artwork/title item(s) found on the disk "
                      f"itself, e.g. {strays[0]}")
                if yes_no("  Remove them, so only the USB copy remains?", True):
                    for p in strays:
                        try:
                            shutil.rmtree(p) if p.is_dir() else p.unlink()
                        except OSError as e:
                            print(f"    kept, {e}")
    else:
        db = None
        for candidate in (usb_root / "exfatdb.json",
                          Path(__file__).resolve().parent / "exfatdb.json"):
            if candidate.is_file():
                try:
                    db = json.loads(candidate.read_text(encoding="utf-8",
                                                        errors="replace"))
                    print(f"\nReading {candidate}")
                except (json.JSONDecodeError, OSError) as e:
                    print(f"\nUnreadable {candidate}: {e}")
                break

        ata = exfat_games(db)
        if ata:
            total = sum(len(v) for v in ata.values())
            print(f"  {total} game(s) on the internal exFAT disk, "
                  f"across {len(ata)} system(s)")
            print("  Only systems browsed on the console since its last boot")
            print("  appear here. Walk the L1+R1 grid to complete it.")
        elif db is not None:
            print("  No exFAT game recorded yet.")
        else:
            print("\nNo exfatdb.json found: only USB games will be processed.")

    # POPStarter binaries: deploy Bios/POPS to <drive>/POPS only if it is not
    # already there. An existing POPS folder is never touched.
    src_pops = usb_root / "Bios" / "POPS"
    dst_pops = usb_root.parent / "POPS"
    if src_pops.is_dir():
        # An existing POPS folder is never overwritten, but it is completed: a set
        # missing POPS.ELF, the PS1 emulator itself, looks fine and boots nothing.
        missing = [f for f in sorted(src_pops.iterdir())
                   if f.is_file() and not (dst_pops / f.name).exists()]
        if not dst_pops.is_dir():
            if yes_no(f"\nDeploy POPStarter binaries to {dst_pops}?", True):
                dst_pops.mkdir(parents=True, exist_ok=True)
                for f in missing:
                    shutil.copy2(f, dst_pops / f.name)
                print(f"  {len(missing)} file(s) copied.")
        elif missing:
            print(f"\n{dst_pops} exists but {len(missing)} file(s) from Bios/POPS "
                  f"are not in it:")
            print("  " + ", ".join(f.name for f in missing))
            if yes_no("Add them? Existing files are never touched.", True):
                for f in missing:
                    shutil.copy2(f, dst_pops / f.name)
                print(f"  {len(missing)} file(s) copied.")
        else:
            print(f"\nPOPS complete at {dst_pops}.")

    tag_cover = pick_tag("COVERS", "cartridge")
    tag_screen = pick_tag("SCREENSHOTS", "screenshot")
    print("\nGBA archives are extracted to .gba and the archive removed,")
    print("since gpSP cannot read them and both would show up twice.")
    print("\nImages already present are left alone, so a second run is quick.")
    overwrite = yes_no("Redo them anyway (needed after changing the tag above)?",
                       False)

    # A game present on both supports is processed once, from the USB copy:
    # that is the one the launcher reads first. Hence the order below.
    # "known" keeps every name seen for a system, whatever its source: it is what
    # tells apart an image whose ROM is gone from one belonging to the other
    # support, and it must therefore be filled before the duplicate filter.
    jobs, queued, known = [], {}, {}

    def add_job(syst, names, folder, origin):
        stems = known.setdefault(syst["dir"], set())
        for n in names:
            stems.add(Path(n).stem.lower())
        done = queued.setdefault(syst["dir"], set())
        fresh = sorted(n for n in names if n.lower() not in done)
        if not fresh:
            return
        done.update(n.lower() for n in fresh)
        jobs.append((syst, fresh, folder, origin))

    for folder, syst in local_folders(usb_root):
        add_job(syst, [f.name for f in folder.iterdir() if f.is_file()],
                folder, "USB  ")

    if ata_root is not None:
        for folder, syst in local_folders(ata_root / "RETROLauncher"):
            add_job(syst, [f.name for f in folder.iterdir() if f.is_file()],
                    folder, "exFAT")

    for long_name, names in ata.items():
        syst = find_system(long_name)
        if syst is not None:
            add_job(syst, names, None, "exFAT")

    if not jobs:
        print("\nNothing to process.")
        return 0

    print(f"\nCovers: {tag_cover}    Screenshots: {tag_screen}")
    print(f"{len(jobs)} source(s)\n" + "-" * 70)

    total = [0, 0, 0, 0, 0]
    for syst, names, folder, origin in jobs:
        res = handle_games(names, syst, es_root, usb_root,
                           tag_cover, tag_screen, overwrite, folder)
        label = f"{origin} {syst['dir']}"
        if res is None:
            print(f"{label:36} no gamelist ({', '.join(syst['es'])})")
            continue
        for i in range(5):
            total[i] += res[i]
        line = f"{res[0]:4} cover(s), {res[1]:4} screenshot(s), {res[2]:4} title(s)"
        if res[3]:
            line += f", {res[3]} gba extracted"
        if res[4]:
            line += f", {res[4]} not in gamelist"
        print(f"{label:36} {line}")

    print("-" * 70)
    clean_orphans(usb_root, known)
    print(f"Covers: {total[0]}   Screenshots: {total[1]}   Titles: {total[2]}")
    if total[3]:
        print(f"GBA ROMs extracted from archives: {total[3]}")
    if total[4]:
        print(f"ROMs missing from the gamelist: {total[4]}")
    print(f"\nEverything written under {usb_root / 'Roms'}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\nInterrupted.")
        sys.exit(130)
