#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
VMCManager.py

Tames PlayStation 2 virtual memory cards for RETROLauncher.

The problem it solves: one big shared card (a 64 MB VMC, for instance) is
exactly what corrupts saves - many games reject or damage cards larger than
8 MB, and a single card shared by everything means one game can clobber
another's data. The clean setup is one small 8 MB card PER GAME, which is what
Neutrino wants anyway (it takes a VMC per game through -mc0=).

What this tool does, from the console-side "VMC" folder of the launcher:

  inspect   read any card (.bin .vmc .ps2), show its size, whether it carries
            ECC, and every save on it (product code, title, size).
  split     take a shared card and write one fresh 8 MB card per game into the
            VMC folder, named after the game's product code, each holding only
            that game's save. This is the "extraire propre" you asked for.
  extract   back every save up to a portable .psu file (openable by mymc, OPL,
            wLaunchELF, PCSX2...).
  import    drop a .psu / .psv / .max save into a card - for the games that
            need a specific save file provided.
  blank     make a new empty, formatted 8 MB card.

Naming: a save folder is called e.g. "BESLES-51044folder"; the product code
"SLES-51044" is pulled out and the per-game card is "SLES-51044.bin". The
launcher normalises an ISO id "SLES_510.44" to the same "SLES-51044" and picks
"VMC/SLES-51044.bin" at launch.

Needs mymcplus for the PS2 card format (pip install mymcplus). It is imported,
not bundled - like Pillow for the other scripts.

--- A word on the PS1 (POPStarter) cards, since you could not find them -------
POPStarter does NOT use these .bin cards. For every PS1 game it makes a folder
at  <drive>/POPS/<game name>/  containing SLOT0.VMC and SLOT1.VMC, two 128 KB
PS1 cards, one per virtual slot. They are created the first time the game runs.
So "Gran Turismo [SCES_009.84].VCD" saves into
  <drive>/POPS/Gran Turismo [SCES_009.84]/SLOT0.VMC
This tool leaves those alone; it only reports them (see the "pops" command).
"""

import struct
import sys
from pathlib import Path

MC_STANDARD_PAGES = 16384            # 16384 * 512 = 8 MiB of data
MC_PAGE = 512
PS1_VMC_SIZE = 128 * 1024            # a PS1 memory card image


def need_mymcplus():
    try:
        from mymcplus import ps2mc
        from mymcplus.save import ps2save
        return ps2mc, ps2save
    except ImportError:
        print("\nThis needs mymcplus (the PS2 card format library).")
        print("Install it with:   pip install mymcplus")
        sys.exit(1)


def ask(q, default=""):
    if default:
        print(f"  default: {default}")
    r = input(f"{q}: ").strip().strip('"').strip("'")
    return r or default


def yes_no(q, default):
    d = "Y/n" if default else "y/N"
    r = input(f"{q} [{d}]: ").strip().lower()
    return default if not r else r in ("y", "yes", "o", "oui")


def open_card(ps2mc, path, writable=False):
    f = open(path, "r+b" if writable else "rb")
    try:
        mc = ps2mc.ps2mc(f)
    except Exception as e:
        f.close()
        raise e
    return mc, f


def product_code(dirname):
    """'BESLES-51044SAVE' -> 'SLES-51044'. Falls back to the raw name."""
    import re
    m = re.search(r'(SL|SC|SL|BA|BE|BI|BK)?([A-Z]{2}[A-Z]{2})[-_]?(\d{3})[._]?(\d{2})',
                  dirname)
    m2 = re.search(r'([A-Z]{4})[-_ ]?(\d{5})', dirname)
    if m2:
        return f"{m2.group(1)}-{m2.group(2)}"
    return dirname


def list_saves(mc):
    """[(dirname, title, size_bytes)] for each real save on the card."""
    out = []
    for ent in mc.dir_open("/"):
        name = ent[8].decode("ascii", "replace") if isinstance(ent[8], bytes) else ent[8]
        if name in (".", ".."):
            continue
        if not (ent[0] & 0x0020):     # DF_DIRECTORY bit
            pass
        title = ""
        try:
            icon = mc.get_icon_sys("/" + name)
            if icon is not None:
                title = decode_title(icon)
        except Exception:
            pass
        size = 0
        try:
            size = mc.dir_size("/" + name)
        except Exception:
            pass
        out.append((name, title, size))
    return out


def decode_title(icon_data):
    """Title from raw icon.sys bytes - the same title uLaunchELF shows when its
    'filename/title' toggle is on. Two Shift-JIS lines, joined with a space,
    full-width characters folded back to plain ASCII."""
    import unicodedata
    try:
        from mymcplus.ps2iconsys import IconSys
        t1, t2 = IconSys(icon_data).get_title("utf-8")
        title = " ".join(x.strip() for x in (t1, t2) if x and x.strip())
    except Exception:
        return ""
    title = unicodedata.normalize("NFKC", title)
    return " ".join(title.split())


REGIONS = {"ES": "Europe", "CE": "Europe", "US": "USA", "CU": "USA",
           "PS": "Japan", "PM": "Japan", "CP": "Japan", "AJ": "Asia",
           "KA": "Korea"}


def region_of(code):
    """'SLES-51044' -> 'Europe', from the last two letters of the prefix."""
    return REGIONS.get(code[2:4].upper(), "") if len(code) >= 4 else ""


def safe_name(s, limit=48):
    """FAT32-safe: strip forbidden characters, non-ASCII, cap the length."""
    s = "".join(c for c in s if 32 <= ord(c) < 127 and c not in '\\/:*?"<>|')
    return " ".join(s.split())[:limit].strip()


def card_filename(code, title):
    """'SLES-55242', 'BURNOUT Dominator' -> 'SLES-55242 BURNOUT Dominator (Europe).bin'
    The product code stays FIRST: it is the key the launcher matches on."""
    reg = region_of(code)
    parts = [code]
    t = safe_name(title)
    if t:
        parts.append(t)
    if reg:
        parts.append(f"({reg})")
    return " ".join(parts) + ".bin"


# ---------------------------------------------------------------------------

def cmd_inspect(ps2mc, ps2save, path):
    size = Path(path).stat().st_size
    has_ecc = abs(size - MC_STANDARD_PAGES * (MC_PAGE + 16)) < MC_PAGE
    kind = "with ECC (physical dump)" if has_ecc else "raw, no ECC (OPL/Neutrino VMC)"
    print(f"\n{path}")
    print(f"  {size:,} bytes  ({size / (1 << 20):.1f} MiB)  {kind}")
    if size > 8 * (1 << 20) + 1024:
        print("  NOTE: larger than 8 MB. Many games corrupt cards over 8 MB -")
        print("  this is very likely the source of your trouble. 'split' fixes it.")
    mc, f = open_card(ps2mc, path)
    try:
        saves = list_saves(mc)
        free = mc.get_free_space()
        print(f"  {len(saves)} save(s), {free / 1024:.0f} KB free:")
        for name, title, sz in saves:
            code = product_code(name)
            t = f"  \"{title}\"" if title else ""
            print(f"    {code:16} {sz/1024:6.0f} KB   {name}{t}")
    finally:
        mc.close()
        f.close()


def cmd_split(ps2mc, ps2save, path, vmc_dir, overwrite):
    vmc_dir = Path(vmc_dir)
    vmc_dir.mkdir(parents=True, exist_ok=True)
    mc, f = open_card(ps2mc, path)
    n_done = 0
    try:
        saves = list_saves(mc)
        if not saves:
            print("No save on this card.")
            return
        print(f"\n{len(saves)} save(s) -> one 8 MB card each in {vmc_dir}")
        for name, title, sz in saves:
            code = product_code(name)
            dest = vmc_dir / card_filename(code, title)
            already = list(vmc_dir.glob(code + "*.bin"))
            if already and not overwrite:
                print(f"  {already[0].name} exists, skipped")
                continue
            for old in already:          # replace any older name for this code
                old.unlink()
            # portable copy of the save straight from the shared card
            sf = mc.export_save_file("/" + name)
            # a fresh, empty, no-ECC 8 MB card
            make_blank(ps2mc, dest)
            dmc, df = open_card(ps2mc, dest, writable=True)
            try:
                dmc.import_save_file(sf, True)
            finally:
                dmc.close()
                df.close()
            n_done += 1
            print(f"  {dest.name}  <- {name}  ({sz/1024:.0f} KB)")
    finally:
        mc.close()
        f.close()
    print(f"\n{n_done} per-game card(s) written.")
    print("At launch the launcher will pick VMC/<game id>.bin automatically.")


def cmd_extract(ps2mc, ps2save, path, out_dir):
    from mymcplus.save import format_ems
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    mc, f = open_card(ps2mc, path)
    try:
        saves = list_saves(mc)
        for name, title, sz in saves:
            code = product_code(name)
            sf = mc.export_save_file("/" + name)
            dest = out_dir / f"{code}.psu"
            with open(dest, "wb") as o:
                format_ems.save(sf, o)
            print(f"  {dest.name}  ({sz/1024:.0f} KB)")
    finally:
        mc.close()
        f.close()
    print(f"\nSaves written to {out_dir}")


def cmd_import(ps2mc, ps2save, card, save_file):
    from mymcplus.save.ps2save import PS2SaveFile, poll_format
    if not Path(card).is_file():
        make_blank(ps2mc, card)
        print(f"  created a blank card: {card}")
    with open(save_file, "rb") as sfin:
        fmt = poll_format(sfin)
        if fmt is None:
            print("  save file format not recognised (.psu .psv .max ...)")
            return
        sfin.seek(0)              # poll_format consumed the header, rewind
        sf = PS2SaveFile()
        fmt.load(sf, sfin)
    mc, f = open_card(ps2mc, card, writable=True)
    try:
        mc.import_save_file(sf, True)
    finally:
        mc.close()
        f.close()
    print(f"  imported {Path(save_file).name} into {Path(card).name}")


def make_blank(ps2mc, path):
    """A fresh, formatted 8 MB card in the RAW layout Neutrino/OPL expect:
    exactly 8,388,608 bytes, 512-byte pages, no ECC spare.

    mymcplus always formats with ECC spare (528-byte pages), so we format into
    a temporary buffer and strip the 16 spare bytes of each page. mymcplus then
    reads this raw image back perfectly (it recomputes ECC on the fly), and -
    verified - preserves the raw size on further writes."""
    import io
    buf = io.BytesIO()
    ps2mc.ps2mc(buf, True, (True, MC_PAGE, 16, MC_STANDARD_PAGES)).close()
    ecc = buf.getvalue()
    raw = bytearray()
    for p in range(0, len(ecc), MC_PAGE + 16):
        raw += ecc[p:p + MC_PAGE]
    raw = bytes(raw[:8 * 1024 * 1024]).ljust(8 * 1024 * 1024, b"\x00")
    with open(path, "wb") as f:
        f.write(raw)


def cmd_convert_folders(ps2mc, vmc_dir):
    """Turn plain FOLDERS sitting in the VMC folder into proper per-game cards.

    A save extracted by hand, pulled off another card or downloaded arrives as a
    directory like 'BESLES-55242SAVE' full of files. The console cannot use that:
    Neutrino wants a card image. This builds a fresh 8 MB card, copies the folder
    into it as a save, and names the card '<CODE> <Title> (<Region>).bin' using
    the title in the folder's own icon.sys - so it lands exactly where the
    launcher expects it, under the right name."""
    import re
    vmc_dir = Path(vmc_dir)
    folders = [d for d in sorted(vmc_dir.iterdir()) if d.is_dir()]
    if not folders:
        print(f"\nNo folder to convert in {vmc_dir}")
        print("(this converts save FOLDERS into .bin cards; .psu files go")
        print(" through option 4)")
        return
    print(f"\n{len(folders)} folder(s) found:")
    for d in folders:
        n = sum(1 for _f in d.rglob("*") if _f.is_file())
        print(f"  {d.name}   ({n} file(s))")
    if not yes_no("\nConvert them into per-game cards?", True):
        return

    done = 0
    for d in folders:
        files = [f for f in sorted(d.iterdir()) if f.is_file()]
        if not files:
            print(f"  {d.name}: empty, skipped")
            continue
        m = re.search(r'([A-Z]{4})[-_ ]?(\d{5})', d.name.upper())
        if m is None:
            print(f"  {d.name}: no product code in the name, skipped")
            continue
        code = f"{m.group(1)}-{m.group(2)}"

        # Title from the folder's own icon.sys, exactly like uLaunchELF reads it.
        title = ""
        for f in files:
            if f.name.lower() == "icon.sys":
                try:
                    title = decode_title(f.read_bytes())
                except Exception:
                    title = ""
                break

        existing = list(vmc_dir.glob(code + "*.bin"))
        if existing:
            print(f"  {d.name}: {existing[0].name} already exists, skipped")
            continue
        dest = vmc_dir / card_filename(code, title)

        make_blank(ps2mc, dest)
        mc, fh = open_card(ps2mc, dest, writable=True)
        try:
            mc.mkdir("/" + d.name)
            for f in files:
                data = f.read_bytes()
                out = mc.open("/" + d.name + "/" + f.name, "wb")
                out.write(data)
                out.close()
            mc.close()
            fh.close()
        except Exception as e:
            try:
                mc.close()
                fh.close()
            except Exception:
                pass
            if dest.exists():
                dest.unlink()
            print(f"  {d.name}: FAILED ({type(e).__name__}: {e})")
            continue
        done += 1
        total = sum(f.stat().st_size for f in files)
        print(f"  {d.name}  ->  {dest.name}   ({total/1024:.0f} KB)")

    print(f"\n{done} card(s) created. The original folders were left untouched;")
    print("delete them yourself once you have checked the cards.")


def cmd_rename(ps2mc, vmc_dir):
    """Rename existing per-game cards to '<CODE> <Title> (<Region>).bin' using
    the title stored in each card's own save (its icon.sys) - the very title
    uLaunchELF displays. The product code stays first, so the launcher's
    prefix match keeps working."""
    import re
    vmc_dir = Path(vmc_dir)
    cards = sorted(vmc_dir.glob("*.bin"))
    if not cards:
        print(f"No .bin card in {vmc_dir}")
        return
    n = 0
    for card in cards:
        m = re.match(r'^([A-Z]{4}-\d{5})', card.stem)
        if not m:
            print(f"  {card.name}: no product code in front, left alone")
            continue
        code = m.group(1)
        try:
            mc, f = open_card(ps2mc, card)
            try:
                saves = list_saves(mc)
            finally:
                mc.close()
                f.close()
        except Exception as e:
            print(f"  {card.name}: unreadable ({type(e).__name__}), left alone")
            continue
        title = ""
        for _name, t, _sz in saves:
            if t:
                title = t
                break
        new_name = card_filename(code, title)
        if new_name == card.name:
            continue
        dest = card.with_name(new_name)
        if dest.exists():
            print(f"  {card.name}: target exists, left alone")
            continue
        card.rename(dest)
        n += 1
        print(f"  {card.name}  ->  {new_name}")
    print(f"\n{n} card(s) renamed.")


def cmd_pops(root):
    """Report the PS1 POPStarter cards, which are NOT .bin files."""
    root = Path(root)
    found = list(root.glob("*/SLOT0.VMC")) + list(root.glob("*/SLOT0.vmc"))
    if not found:
        print(f"\nNo POPS card under {root}. They appear once a game has run.")
        print("Expected: <POPS>/<game name>/SLOT0.VMC and SLOT1.VMC (128 KB each).")
        return
    print(f"\nPS1 memory cards under {root}:")
    for slot0 in sorted(found):
        game = slot0.parent.name
        s0 = slot0.stat().st_size
        slot1 = slot0.with_name("SLOT1.VMC")
        s1 = slot1.stat().st_size if slot1.is_file() else 0
        print(f"  {game}")
        print(f"    SLOT0.VMC {s0/1024:.0f} KB   SLOT1.VMC {s1/1024:.0f} KB")
    print("\nThese are per-game already. To back one up, just copy its folder.")


# ---------------------------------------------------------------------------

def main():
    print(__doc__.strip())
    print("\n" + "=" * 70)
    ps2mc, ps2save = need_mymcplus()

    print("\nWhat do you want to do?")
    print("  1. inspect a card (list its saves)")
    print("  2. split a shared card into one 8 MB card per game")
    print("  3. extract every save to portable .psu files")
    print("  4. import a .psu/.psv/.max save into a card")
    print("  5. make a blank 8 MB card")
    print("  6. show my PS1 (POPStarter) cards")
    print("  7. rename existing per-game cards with their save titles")
    print("  8. convert save FOLDERS in the VMC folder into .bin cards")
    choice = input("\nNumber: ").strip()

    if choice == "8":
        cmd_convert_folders(ps2mc, ask("VMC folder (e.g. E:\\VMC)"))
        return 0

    if choice == "7":
        cmd_rename(ps2mc, ask("VMC folder (e.g. F:\\RETROLauncher\\VMC)"))
        return 0

    if choice == "6":
        cmd_pops(ask("POPS folder (e.g. F:\\POPS)"))
        return 0

    if choice == "5":
        dest = ask("New card path (e.g. F:\\RETROLauncher\\VMC\\SLES-51044.bin)")
        make_blank(ps2mc, dest)
        print(f"  blank 8 MB card written: {dest}")
        return 0

    if choice == "4":
        card = ask("Target card (.bin), created if absent")
        sfile = ask("Save file to import (.psu/.psv/.max)")
        if not Path(sfile).is_file():
            print("  save file not found.")
            return 1
        cmd_import(ps2mc, ps2save, card, sfile)
        return 0

    card = ask("Card image (.bin/.vmc/.ps2)")
    if not Path(card).is_file():
        print("  not found.")
        return 1
    try:
        if choice == "1":
            cmd_inspect(ps2mc, ps2save, card)
        elif choice == "2":
            vmc = ask("VMC output folder",
                      str(Path(card).resolve().parent))
            ow = yes_no("Overwrite existing per-game cards?", False)
            cmd_split(ps2mc, ps2save, card, vmc, ow)
        elif choice == "3":
            out = ask("Folder for the .psu backups",
                      str(Path(card).resolve().parent / "psu"))
            cmd_extract(ps2mc, ps2save, card, out)
        else:
            print("  unknown choice.")
            return 1
    except Exception as e:
        print(f"\n  error: {type(e).__name__}: {e}")
        return 1
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\nInterrupted.")
        sys.exit(130)
