#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PopsCheck.py

Checks a POPStarter setup the way the official quick start guide describes it,
and tells you which of the three usual culprits is at fault when a game boots
straight back to the launcher.

The guide (ShaolinAssassin / krHACKen) asks for exactly this on a USB device:

    <drive>:/POPS/POPS_IOX.PAK      the emulator, one single file
    <drive>:/POPS/GAME.VCD          the game, converted with CUE2POPS
    <drive>:/POPS/XX.GAME.ELF       POPSTARTER.ELF renamed after the VCD

IOPRP252.IMG, POPS.ELF and POPS.PAK belong to the HDD setup. They do no harm
on USB, but they are not what makes it work, and their presence is often
mistaken for a complete install.

Nothing is modified. This only reads and reports.
"""

import hashlib
import struct
import sys
from pathlib import Path

# Reference hashes published with the POPS binaries (AnimMouse/POPS-binaries).
# A different hash means a different dump, and POPStarter exits without a word.
# POPS_IOX.PAK is the only one USB mode needs; the other three are HDD mode.
POPS_MD5 = {
    "POPS_IOX.PAK": "a625d0b3036823cdbf04a3c0e1648901",
    "POPS.ELF":     "355a892a8ce4e4a105469d4ef6f39a42",
    "POPS.PAK":     "e684f69cd92ccc1a75291f9a0eaa853f",
    "IOPRP252.IMG": "1db9c6020a2cd445a7bb176a1a3dd418",
}
POPS_IOX_MD5 = POPS_MD5["POPS_IOX.PAK"]

RAW_SECTOR = 2352      # the image itself is raw sectors
ISO_SECTOR = 2048
VCD_HEADER = 1 << 20   # 1 MiB of table of contents in front of the image

def md5(path, chunk=1 << 20):
    h = hashlib.md5()
    with open(path, "rb") as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def inspect(path):
    """Describe the layout of a .VCD.

    A VCD is not a bare disc image: it opens with a 1 MiB table of contents
    (the Q-subchannel points A0/A1/A2 in BCD, hence the 0x41 0x00 0xA0... at
    offset zero), and the raw 2352-byte sectors follow. So the ISO9660
    descriptor of sector 16 sits at 1 MiB + 16*2352 + 24, not at 32768.
    Looking in the wrong place makes a perfectly good image look broken.

    Returns a dict describing what was found."""
    out = {"header": None, "sector": None, "volume": None, "aligned": None}
    size = path.stat().st_size
    try:
        with open(path, "rb") as f:
            for header in (VCD_HEADER, 0):
                for sector, offset in ((RAW_SECTOR, 24), (RAW_SECTOR, 16),
                                       (ISO_SECTOR, 0)):
                    pos = header + 16 * sector + offset
                    if pos + 46 > size:
                        continue
                    f.seek(pos)
                    block = f.read(46)
                    if block[1:6] != b"CD001":
                        continue
                    out["header"] = header
                    out["sector"] = sector
                    out["volume"] = block[8:40].decode("latin1").strip()
                    body = size - header
                    out["aligned"] = (body % sector == 0)
                    return out
    except OSError:
        pass
    return out


def report(pops):
    print(f"\nPOPS folder: {pops}")
    print("=" * 70)

    iox = pops / "POPS_IOX.PAK"
    if not iox.is_file():
        print("MISSING  POPS_IOX.PAK - the emulator itself. Nothing can boot.")
    else:
        got = md5(iox)
        if got == POPS_IOX_MD5:
            print("ok       POPS_IOX.PAK, hash matches the reference")
        else:
            print("WRONG    POPS_IOX.PAK does not match the reference dump")
            print(f"         found    {got}")
            print(f"         expected {POPS_IOX_MD5}")
            print("         This alone makes every game exit instantly.")

    ref = pops / "POPSTARTER.ELF"
    if ref.is_file():
        # Rev 13 Beta, 2019/06/05, is the build the quick start pack ships and
        # the one RETROLauncher bundles. 167700 bytes.
        size = ref.stat().st_size
        mark = "ok      " if size == 167700 else "note    "
        print(f"{mark} POPSTARTER.ELF  {size:,} bytes  md5 {md5(ref)}")
        if size != 167700:
            print("         Rev 13 Beta (2019/06/05) is 167,700 bytes.")
    else:
        print("note     POPSTARTER.ELF not in this folder (only the XX. copies"
              " matter)")

    for name in ("POPS.ELF", "POPS.PAK", "IOPRP252.IMG"):
        f = pops / name
        if not f.is_file():
            continue
        if md5(f) == POPS_MD5[name]:
            print(f"ok       {name}, hash matches (HDD-mode file, unused here)")
        else:
            print(f"WRONG    {name} does not match the reference dump")

    vcds = sorted(p for p in pops.glob("*") if p.suffix.lower() == ".vcd")
    if not vcds:
        print("\nNo .VCD in this folder.")
        return
    print(f"\n{len(vcds)} game(s):")
    print("-" * 70)

    for v in vcds:
        print(f"\n{v.name}")
        size = v.stat().st_size
        print(f"  size      {size:,} bytes  ({size / (1 << 20):.0f} MiB)")

        info = inspect(v)
        if info["sector"] is None:
            print("  FORMAT    no ISO9660 descriptor found, in any layout.")
            print("            This is not something POPS can mount. Re-convert")
            print("            the .cue.")
        elif info["header"] == VCD_HEADER and info["sector"] == RAW_SECTOR:
            print("  ok        1 MiB table of contents + raw 2352-byte sectors,")
            print(f"            which is the VCD layout. Volume: {info['volume']}")
            if not info["aligned"]:
                print("  note      the image part is not a whole number of sectors")
        elif info["header"] == 0:
            print("  FORMAT    the disc image starts at offset 0, with no table")
            print("            of contents in front of it. This is a .bin or .iso")
            print(f"            renamed to .VCD ({info['sector']}-byte sectors).")
            print("            It has to go through a real converter.")
        else:
            print(f"  note      unusual layout: header {info['header']}, "
                  f"sectors {info['sector']}")

        if info["volume"] and info["volume"] != "PLAYSTATION":
            print(f"  note      volume identifier is '{info['volume']}',"
                  " expected PLAYSTATION")

        elf = pops / f"XX.{v.stem}.ELF"
        if elf.is_file():
            ref = pops / "POPSTARTER.ELF"
            if ref.is_file() and md5(elf) != md5(ref):
                print(f"  SUSPECT   XX.{v.stem}.ELF differs from POPSTARTER.ELF")
                print(f"            {elf.stat().st_size:,} bytes against "
                      f"{ref.stat().st_size:,}. The shortcut is only meant to be")
                print("            a byte-for-byte copy under another name.")
            else:
                print(f"  ok        shortcut XX.{v.stem}.ELF")
        else:
            near = [p.name for p in pops.glob("XX.*")
                    if p.stem.lower().lstrip("xx.") == v.stem.lower()]
            print(f"  MISSING   XX.{v.stem}.ELF")
            if near:
                print(f"            closest match: {near[0]}")
            print("            The name after 'XX.' must match the VCD exactly,")
            print("            case included.")


def main():
    print(__doc__.strip())
    r = input("\nPOPS folder (e.g. F:\\POPS): ").strip().strip('"').strip("'")
    pops = Path(r)
    if not pops.is_dir():
        print(f"\nNot a folder: {pops}")
        return 1
    report(pops)
    print("\n" + "=" * 70)
    print("If everything above is clean and the game still exits, convert the")
    print(".cue again with CUE2POPS and try a single-track game first: discs")
    print("with CDDA audio are the ones conversions usually get wrong.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\nInterrupted.")
        sys.exit(130)
