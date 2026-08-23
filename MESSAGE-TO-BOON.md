# RETROLauncher on an internal exFAT drive — what we found, and what we changed

Hi Boon,

I forked RETROLauncher to run it from a PS2's **internal exFAT drive** instead of a
USB stick. That turned out to be a much bigger rabbit hole than expected, and along
the way we found a hard limitation that isn't yours, plus a handful of real bugs in
the existing code. Everything below is working on real hardware.

Take whatever is useful. Ignore the rest.

---

## 1. The finding that explains everything

**A RetroArch libretro core cannot read the internal drive. At all. Ever.**

Not a configuration problem, not something a path can fix. Every PS2 core calls
`SifIopReset()` before anything else. The core's ELF is already in RAM so it keeps
running, but the IOP is wiped and the core reloads *its own* driver list:

```
usbd, bdm, bdmfs_fatfs, usbmass_bd, mx4sio, cdfs, dev9
```

`ata_bd` is not in that list, and nothing loaded beforehand survives the reset. The
moment a core starts, the internal drive stops existing for it.

So if `cores/`, `info/` and `retroarch/` sit on that drive, RetroArch has nothing
left to read and dies before drawing a frame. Even `raboot.elf` fails — it can't
find `cores/` and exits immediately.

This is not specific to RETROLauncher. The author of PSBBN describes the same thing
and gives the same workaround in issue #448 of his project: the ELF wherever you
like, **everything else on USB**.

## 2. The workaround, with no recompiling

The launcher itself runs fine from the internal drive — Enceladus loads `ata_bd`
and reads it happily. Only the *cores* are blind to it. So:

```
RetroArch install      USB stick     once, by hand
the ROM being launched USB stick     every launch, automatic
its saves              USB stick     every launch, automatic
saves coming back      internal      next launcher start
```

Before handing control to a core, the launcher copies the ROM and that game's saves
to the stick, points RetroArch's config at them, and launches. On the next start it
collects whatever the core wrote and puts it back on the internal drive, then clears
the stick. The internal drive stays the home of the ROMs and the saves; the stick is
a corridor. ROMs are small, so the copy is imperceptible — and it's one ROM at a
time, so the stick never fills up.

The USB layout mirrors the internal one exactly, which makes both halves readable:

```
<USB>/RETROLauncher/
    LibretroPS2Files/     config + the one core in use + raboot.elf
    Bios/  Roms/<console>/  Saves/<console>/  SaveStates/<console>/
```

PS2 ISOs and PS1 games are not concerned — Neutrino and POPStarter load their own
`ata_bd` and read the internal drive directly. Which is convenient, since those are
the big files.

**If there is no USB stick**, the twelve libretro systems are switched off before
the lists are even built. A console that is absent is more honest than one that
opens and says "Games or RetroArch not found" on every game.

## 3. Bugs we hit in the existing code

These are independent of exFAT — they'd bite anyone.

**`existe()` gated launches on one hardcoded core per system.** If that exact ELF
wasn't found, the game was refused with "Games or RetroArch not found", even with
sixty other cores present that declare the right extension in their `.info`. It now
asks whether *any* core serving that system exists.

**`elegir_core()` ended with `if #rutas <= 1 then return ruta_defecto end`.** "The
only one there is" and "the one that was the default" are not the same thing:
`ruta_defecto` is a bare filename when the path couldn't be resolved, so a system
with exactly one usable core was handed an ELF path that doesn't exist.

**`System.cfg` is 49 numbers re-read by position, and one of the slots holds a file
path.** The reader extracts numbers with `%d+`. If that path contains one digit more
or less than expected, everything after it is read shifted. That's why the
"show index in list" toggle never stuck — its slot was being read from the wrong
offset. We moved that one switch to its own file.

**The APPS list scanned the root of every drive**, descending one level into every
folder found there. On a drive that also serves OPL that means listing `ART`, `THM`,
`CHT`, `$RECYCLE.BIN` and `System Volume Information` — thousands of files each.
Boot died there. Also, the list of places to search has holes punched in it (entries
set to `nil` when a device is absent) and was walked with `#`, whose result on a
table with holes is undefined in Lua — it can stop at the first gap and silently
skip everything after.

**The per-core override files caused silent data loss.** An active override makes
RetroArch refuse to save anything — `[Overrides] Not saving. Overrides active.` —
and `config/Gambatte/gbc.cfg` was turning off save-state sorting, so states landed
loose instead of in their console folder. We ship none now; one `retroarch.cfg`
configured on the console is the whole configuration.

**`Font.ftLoad` on a missing file, `Graphics.loadImage` on a bad PNG** — both can
freeze the console with no message at all. There's now a journal line written
*before* each risky operation, so the last line names the culprit.

## 4. Other things that changed

**Twenty-four `retroarch.cfg` files became one.** Twelve consoles × NTSC/PAL, each
carrying about twenty absolute paths like
`mass:/RETROLauncher/System/RetroarchPS2/Sega Megadrive/retroarch/assets`. Keeping
them correct required `relocation.lua` — 2989 lines that rewrote all twenty-four
every time the launcher changed drive. RetroArch works out every folder from its own
location, so none of those paths were needed. The script is gone, and moving the
launcher between a stick, a memory card and the internal drive now needs no
rewriting at all.

**The folder tree was flattened.** Everything used to sit under
`System/RetroarchPS2/<Console name>/`, three levels deep, with a full copy of
RetroArch repeated per console — the same ten core files thirteen times, 36 MB. The
name was misleading too: POPStarter, Neutrino, OPL, uLaunchELF and the rest all
lived in a folder called "RetroarchPS2". One folder per module at the root now, each
updatable on its own.

**Drop a nightly in and it works.** `raboot.elf`, `cores/`, `info/` unzipped into
`LibretroPS2Files/` — nothing to rename, nothing to move. A nightly doesn't ship
`retroarch/`, so the launcher creates the folders RetroArch expects. That matters
more than it sounds: **RetroArch opens files but does not create directories.**
Without `temp/` (its `cache_directory`) it cannot extract a zipped ROM, and you get
a black screen with no log — because it couldn't create the log directory either.

**One journal.** There were five separate log files; the thing you actually need is
the *order* events happened in, and split across five files that's gone. It's one
file now with a category per line, and the loading screen shows the same steps live,
so a boot that doesn't reach the menu says where it stopped.

**Per-game VMCs for PS2 ISOs.** One shared 64 MB card is what corrupts saves — many
games reject or damage cards over 8 MB, and a single card lets one game overwrite
another's data. The launcher now copies a blank formatted 8 MB template to
`VMC/<ID>.bin` on first launch and passes `-mc0=` to Neutrino.

## 5. The recompile route — offered, but I don't recommend it

There *is* a proper fix: add `ata_bd` to the driver list a core loads after
`SifIopReset`. `ata_bd.irx` is `ps2atad` built with `ATA_ENABLE_BDM=1`; it already
exists in ps2sdk and calls `bdm_connect_bd()`. Two changes:

- **`fjtrujy/ps2_drivers`** — a new `ps2_ata_bd_driver.c` following the mx4sio
  template exactly, so `init_ata_bd_driver()` sits alongside the others.
- **`libretro/RetroArch`**, `frontend/drivers/platform_ps2.c` — call it after
  `init_dev9_driver()`, and add `mass1:` and `ata0:` to
  `frontend_ps2_parse_drive_list()`, which only ever offered `mass:` (volume 0). A
  second USB stick was equally unreachable, so that part is a fix in its own right.

Everything is in `upstream/retroarch-exfat-ata/` — both patches, the new source
files, and a GitHub Actions workflow that builds the cores.

**But I'd leave it there.** I built cores with it and they're half broken — one
reports a refresh rate of 1,000,000 Hz and the frontend forks out at zero seconds.
And even if it worked, every core has to be re-patched and rebuilt at every nightly,
which nobody is going to do. The USB workaround needs no recompiling and works with
official cores today. The patch files are in the repo for anyone who wants to play
with it — that's all they're for.

Two things worth noting for anyone who does try:

- `ata_bd` and `ps2atad` both export the `atad` library, so they're mutually
  exclusive — loading both fails at `RegisterLibraryEntries`.
- `bdmfs_fatfs/src/fs_driver.c`: `connect_bd()` calls `fs_ensure_typed_driver()`
  *before* `f_mount`, and leaves the device registered if the mount fails.
- Binary-patching the shipped ELFs is not an option: they're compressed by
  `ps2-packer` — one PT_LOAD segment, entry `0x01d0001c`, zero readable strings.

## 6. Two details that cost us days

**The internal drive changes name across a core launch.** Enceladus always calls it
`mass0:`. A core renumbers everything, because it resets the IOP and mounts its own
stack in the order set by `init_drivers()`: usbmass_bd first, then mx4sio, then
ata_bd. BDM volumes are numbered as they connect, so the internal drive's index is
exactly the number of USB devices ahead of it. Verified on hardware: `mass1:` with
one stick, `mass0:` with none.

**`video_threaded` does nothing on PS2.** `Makefile.ps2` builds with
`HAVE_THREADS = 0`, so `video_thread_wrapper` isn't even compiled in. The setting is
read, stored, and ignored.

---

That's the lot. Diff is roughly 476 files, ~90,000 lines removed — most of it the
twenty-four config files, the thirteen RetroArch copies and `relocation.lua`.

Thanks for RETROLauncher — none of this would exist without it.
