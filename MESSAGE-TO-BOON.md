# 👋 Hi Boon!

## 🎮 RETROLauncher on an internal exFAT drive — everything we found and changed

> Huge changes. I also rearranged the directories into modules so everything can be
> updated independently, and dropped a pile of duplicated files on the way.

I forked RETROLauncher to run it from a PS2's **internal exFAT drive** instead of a
USB stick. That turned out to be a much bigger rabbit hole than expected: it answers
**issue #1**, open since 2024, and along the way we found a hard limitation that
isn't yours plus a good number of real bugs in the existing code.

**Everything below runs on real hardware.** Take whatever is useful, ignore the rest. 🙂

---

## ⚡ How to boot it from the internal disk

A few small files go on the memory card first, so the driver is loaded before
anything else and the launcher can then boot from the disk.

Put this in `mc0:/RETROBOOT/`:

```
ata_bd.irx
dev9_ns.irx
boot.lua
```

…and launch with the argument:

```
mc0:/RETROBOOT/boot.lua
```

I use **SysMenu**, configured with R3 Configurator. I fixed a few things there too
while I was at it → https://github.com/saildot4k/R3CONFIGURATOR/releases

**None of this is needed for a plain USB setup.**

---

# 1️⃣ The internal exFAT HDD now works

## 🧨 The blocker nobody had found

`System/IRX/` exists upstream so users can load extra IOP drivers, but the folder
ships empty and the feature had never been exercised. **It does not work:**

> **`Sif.loadModule(path)` freezes the console on every call.** Not "fails" —
> freezes, before video init, with no message.

Verified with:

- `dev9_ns.irx` and `poweroff.irx` (valid IRX modules)
- **a plain text file renamed to `.irx`** (not a module at all)
- both the 1-argument and 3-argument call forms
- both the bundled 2024 Enceladus build and the current 2025 one

An invalid file should return a negative ID immediately and never reach the IOP. It
freezes anyway, so this is not a driver problem.

**Cause:** `SifLoadModule` makes the *IOP* resolve the path, through its `LOADFILE`
module, which uses the old `ioman`. But `mass:` is provided by `bdmfs_fatfs`, which
registers with `iomanX`. The IOP cannot open the path and the RPC never returns.

**Fix:** read the `.irx` on the EE side and hand over the bytes with
`IOP.loadModuleBuffer(data, size)`. No IOP-side path resolution, no freeze.

📣 Worth reporting upstream to Enceladus too — any homebrew loading IRX files from a
BDM device in Lua will hit this.

## 🔌 What was added

- `dev9_ns.irx` and `ata_bd.irx` (already shipped with Neutrino) are loaded at
  startup, **in that order** — `ata_bd` imports the `dev9` library, and
  `System.listDirectory` guarantees no ordering.
- A **blocklist** skips modules Enceladus already loads. Loading a second BDM stack
  registers twice (`BDM: ERROR: Already registered!`) and hangs the console.
- The internal disk then appears as **`massN:`**, never as `hdd0:`. `hdd0:` is the
  native ATAD/PFS stack, a different world.
- Drives appearing *after* the drivers load are tagged as ATA, which distinguishes a
  mounted internal disk from a second USB stick. Upstream's "device on the second USB
  port" guard used to fire on the internal disk and **block startup in an infinite
  loop**.
- A single `IRX/` folder at the root, instead of one buried in `System/`.

## 🔎 Cumulative game search

Games are searched in **both** the boot device and the internal disk, in a folder
named after the launcher:

```
mass:/RETROLauncher       (USB, boot)
mass1:/RETROLauncher      (internal exFAT)
```

Applies to RetroArch systems, PS1 `.cue` for Ember, and PS2 ISOs — plus `DVD/` and
`CD/` at the root of ATA drives. Duplicates are de-duplicated by name, USB wins. Each
entry remembers where it came from, so launching resolves against the right root.

EmulationStation / Batocera folder names are accepted as well (`roms/snes`,
`roms/nes`…), both inside the launcher folder and at the root of each drive.

## 💿 PS2 ISOs and PS1

**PS2 ISOs on the internal disk launch and run.** RETROLauncher already passed
`-bsd=ata` to Neutrino for the `.hdd` extension; this fork detects an ATA origin and
forces it automatically, rewriting the device prefix to `mass:` — with `-bsd=ata`
Neutrino loads only `ata_bd`, so the internal disk is its only block device. A plain
`.iso` is enough, no renaming.

**PS1 works too**, through Ember, from the internal disk. Ember resolves its `.cue`
relative to its own directory, so `ember.elf` and `bios.bin` are deployed next to the
cues from `Bios/`, once per folder.

## 🎯 POPS

`POPS` was hardcoded to the boot device across **47 references**. It is now resolved
at startup: an ATA drive whose `POPS/` contains `POPS_IOX.PAK` is preferred, then any
existing `POPS/`, then the boot device.

The USB access delay POPStarter needs is patched automatically
(`POPS_USB_DELAY`) — that was the real culprit behind
*"Opening mass:/POPS/… FAILED / No POPS directory?"*, not the IOP state.

The guide is also explicit that in USB mode the emulator is **one single file**,
`POPS_IOX.PAK`. Requiring `IOPRP252.IMG` — which belongs to HDD mode — was rejecting
perfectly valid USB setups.

---

# 2️⃣ RetroArch, and the limitation that shapes everything

> **A RetroArch libretro core cannot read the internal drive. At all. Ever.**

Not a configuration problem, not something a path can fix. Every PS2 core calls
`SifIopReset()` before anything else. The core's ELF is already in RAM so it keeps
running, but the IOP is wiped and the core reloads *its own* driver list:

```
usbd, bdm, bdmfs_fatfs, usbmass_bd, mx4sio, cdfs, dev9
```

`ata_bd` is **not** in that list, and nothing loaded beforehand survives the reset.

So if `cores/`, `info/` and `retroarch/` sit on that drive, RetroArch has nothing to
read and dies before drawing a frame. Even `raboot.elf` fails — it can't find
`cores/` and exits immediately.

📌 Not specific to RETROLauncher. The author of **PSBBN** describes the same thing and
gives the same workaround in issue **#448**: the ELF wherever you like, everything
else on USB.

## 🔁 The shuttle, with no recompiling

The launcher itself runs fine from the internal drive — Enceladus loads `ata_bd` and
reads it happily. Only the *cores* are blind to it.

| What | Where | When |
|---|---|---|
| RetroArch install | 🔌 USB stick | once, by hand |
| the ROM being launched | 🔌 USB stick | every launch, automatic |
| its saves and states | 🔌 USB stick | every launch, automatic |
| saves coming back | 💽 internal | next launcher start |

The internal drive stays the home of the ROMs and the saves; **the stick is a
corridor**. ROMs are small, so the copy is imperceptible — and it's one ROM at a
time, so the stick never fills up.

The USB layout mirrors the internal one exactly:

```
<USB>/RETROLauncher/
    LibretroPS2Files/      config + the one core in use + raboot.elf
    Bios/
    Roms/<console>/
    Saves/<console>/
    SaveStates/<console>/
```

`raboot.elf` is copied too, once — the launcher never uses it, but RetroArch stays
openable from uLaunchELF without going through RETROLauncher, which is how you check
an installation when something is wrong.

## 💾 The save bridge, both ways

```
before launching   this game's saves go from the drive to the stick
the core plays     it writes on the stick, knowing nothing of a drive
coming back        the launcher collects everything and puts it on the drive
```

The outbound leg matters as much as the return: without it a game would start blank
and overwrite what was on the drive at its first save.

A file found loose at the root of `SaveStates/` — which happens when an override
turns off content-folder sorting — is matched against the ROMs in each
`Roms/<console>/` and filed where it belongs, instead of coming back loose.

**If a core crashes, nothing written is lost.** The bridge runs at every launcher
start, before anything else can fail.

## ⚙️ Two installations, and telling them apart

This was the subtlest bug in the whole fork:

| | Where | Answers |
|---|---|---|
| **master** | next to the launcher, all cores | *what can be played* |
| **shuttle** | on the stick, one core | *what runs it* |

Anything asking "what is available" must ask the **master**. Three places asked the
wrong one, and that is why Lynx, GBA, GB, GBC and NES all said *"Games or RetroArch
not found"* with sixty cores sitting on the disk.

⚠️ **If there is no USB stick**, the twelve libretro systems are switched off before
the lists are even built. A console that is absent is more honest than one that opens
and refuses every game.

---

# 3️⃣ Configuration, simplified

### 📄 Twenty-four `retroarch.cfg` files became one

Twelve consoles × NTSC/PAL, each carrying about twenty absolute paths like
`mass:/RETROLauncher/System/RetroarchPS2/Sega Megadrive/retroarch/assets`. Keeping
them correct required `relocation.lua` — **2989 lines** that rewrote all twenty-four
every time the launcher changed drive.

RetroArch derives every folder from its own location, so none of those paths were
needed. **The script is gone**, and moving the launcher between a stick, a memory card
and the internal drive needs no rewriting at all.

### 🧾 What the launcher forces before each game

RetroArch saves its config on exit and the user can change things from its menu, so
these are re-applied every time rather than set once: the seventeen directory keys,
plus save sorting and the aspect ratio. Everything else is left alone.

Saves land in `Saves/<console>/` and `SaveStates/<console>/`, mirroring
`Roms/<console>/`, grouped by **content folder** rather than by core — otherwise
PicoDrive merges four Sega consoles into one.

`Bios/` is the single copy and is handed over as `system_directory`, so there is no
second copy to keep in sync.

### 🚫 Per-core overrides dropped

An active override makes RetroArch **refuse to save anything** —
`[Overrides] Not saving. Overrides active.` — and `config/Gambatte/gbc.cfg` was
quietly turning off save-state sorting, so states landed loose. One `retroarch.cfg`
configured on the console is now the whole configuration.

### 📦 Drop a nightly in and it works

`raboot.elf`, `cores/`, `info/` unzipped into `LibretroPS2Files/` — nothing to rename,
nothing to move. A nightly doesn't ship `retroarch/`, so the launcher creates the
folders RetroArch expects.

> 💡 **RetroArch opens files but does not create directories.** Without `temp/` (its
> `cache_directory`) it cannot extract a zipped ROM, and you get a black screen with
> no log — because it couldn't create the log directory either. That one cost us an
> evening.

---

# 4️⃣ Folder reorganisation — modular, updatable one by one

Everything used to sit under `System/RetroarchPS2/<Console name>/`, three levels deep,
with a full copy of RetroArch repeated per console — the same ten core files thirteen
times, **36 MB**. The name was misleading too: POPStarter, Neutrino, OPL, uLaunchELF,
TempGBA and SNESticle all lived in a folder called "RetroarchPS2".

Now, one folder per module at the root. **Replace the folder, keep the name, done:**

```
RETROLauncher.elf
System/            code, media, settings
LibretroPS2Files/  RetroArch      ← unzip a nightly here
Neutrino/          PS2 ISO loader
OPL/               PS2 ISO loader, alternative
POPStarter/        PS1 (.VCD)
uLaunchELF/        file manager
IRX/               IOP drivers
Bios/              BIOS files + the blank VMC template
Roms/              games and artwork
Saves/ SaveStates/ one folder per console, matching Roms/
```

- **uLaunchELF** ships under a different filename in every release — `WLE.ELF`,
  `WLE-R3Z.ELF`, `WLE-R3Z-DS34.ELF` — so the launcher no longer looks for a name: it
  takes the first `.elf` in the folder. Drop the new one in, delete the old, done.
- **Media can live next to the ROMs** (`Roms/<system>/media/covers/…`), so games on
  the exFAT drive carry their own artwork. The historical location still works.
- **TempGBA removed** — built for the PSP, it runs a GBA game at 45–55 FPS on PS2
  while gpSP does full speed with its dynarec, and it carried a fourth copy of
  `gba_bios.bin`.
- **SNESticle removed** to keep one kind of core. Restoring it is documented.

---

# 5️⃣ Interface

### 🎛️ Quick system selection

`L1 + R1` together opens a **grid of system logos** — only systems enabled in
`SISTEMAS.*_ON`, cursor on the current one, Cross to confirm, Triangle to cancel.
Each trigger alone still cycles as before. The combination was chosen because SELECT,
L3, R3, START, L2 and R2 are all taken in the main menu. An on-screen hint sits
top-left.

### 🧩 Core selector

When more than one core serves a system, a picker appears at launch with the expected
core already selected — filtered by crossing the system's real extensions with what
each core declares in its `.info`. **Cores already on the stick are shown in green**
(nothing to copy), the others in white. An arrow marks the cursor, since colour alone
no longer says where you are.

### 🏷️ Tags in the game list

Entries are prefixed with their origin and extension: `[ATA].iso God Of War`,
`.zip Sonic The Hedgehog`. Names are still displayed without their extension, so the
tag is the only way to tell a `.zip` from a loose ROM. Shown while CIRCLE is held, so
the title scroll keeps working.

**Games already on the stick are drawn in green** — green means launching copies
nothing. On USB 1.1 that's worth knowing in advance.

### ⏳ The loading screen says what it is doing

Instead of a fixed *"Loading lists and settings"*, a panel rolls the boot steps as
they happen, with the source of each scan:

```
  USB scan gb
  gb  12 found  (5/15)
> ATA scan gbc
```

A boot that never reaches the menu now says where it stopped, on screen and in the
journal.

### 🚀 The launch sequence is announced

```
> Checking cores for Nintendo Game Boy
> Core: gambatte_libretro_ps2.elf   (green if already on USB)
> Writing retroarch.cfg
> Copying ROM  4096 / 16384 KB
> Launching Tetris
```

Copies above 256 KB report progress in KB — `System.copyFile` says nothing while it
works, and on USB 1.1 a GBA ROM is fifteen seconds of a still screen, indistinguishable
from a freeze.

### 🧰 Smaller things

- **The OPL ELF picker** (Options → *PlayStation 2* → SELECT) lists ATA drives, so a
  custom `OPNPS2LD` on the internal disk can be selected. Device selector banners grow
  with the number of entries instead of overflowing.
- **PS1 errors say what is missing and where** — the absent files and the directory
  they were expected in, instead of a generic message. Same for libretro systems:
  *"No core for Atari Lynx"* rather than *"Games or RetroArch"*.
- **Typo:** `POSP` → `POPS` in the PS1 error string, in all three languages.
- **Media folder indexing.** The manual warns that checking a folder of 500 entries
  isn't the same as one of 1000+. Each selection change was asking for up to six paths,
  one filesystem call each — and this fork multiplied the roots. Folders are listed
  once and lookups become table hits.

---

# 6️⃣ Bugs fixed

Independent of exFAT — these would bite anyone.

<details>
<summary><b>existe() gated launches on one hardcoded core per system</b></summary>

If that exact ELF wasn't found the game was refused, even with sixty other cores
declaring the right extension in their `.info`. It now asks whether **any** core
serving that system exists.
</details>

<details>
<summary><b>elegir_core() returned a filename that doesn't exist</b></summary>

`if #rutas <= 1 then return ruta_defecto end`. *"The only one there is"* and *"the one
that was the default"* are not the same thing: `ruta_defecto` is a bare filename when
the path couldn't be resolved, so a system with exactly **one** usable core was handed
an ELF path that doesn't exist.
</details>

<details>
<summary><b>The Ember .cue scan was nested inside the POPS check</b></summary>

With no `POPS` folder on the boot device, PS1 games were never listed even when
correctly placed. The scan is independent now.
</details>

<details>
<summary><b>System.cfg is read by position, and one slot holds a file path</b></summary>

49 numbers on one line, re-read by position, extracted with `%d+`. If that path
contains one digit more or less than expected, **everything after it is read
shifted**. That's why the *"show index in list"* toggle never stuck. That switch now
lives in its own file.
</details>

<details>
<summary><b>The APPS list scanned the root of every drive</b></summary>

…descending one level into every folder there. On a drive that also serves OPL that
means listing `ART`, `THM`, `CHT`, `$RECYCLE.BIN`, `System Volume Information` —
thousands of files each. **Boot died there.**
</details>

<details>
<summary><b>Lists with nil holes walked with #</b></summary>

The tables of places to search have entries set to `nil` when a device is absent, and
were iterated with `#` — whose result on a table with holes is **undefined in Lua**.
It can stop at the first gap and silently skip everything after.
</details>

<details>
<summary><b>The second-USB-port guard fired on the internal disk</b></summary>

…and blocked startup in an infinite loop, because a mounted internal drive looks like
a second device.
</details>

<details>
<summary><b>The theme editor freezes if you turn every element off</b></summary>

`estado()` in the style editor looks for the next **active** element:

```lua
local buscar = true
while buscar do
    ...
    if estado_elementos_new[selector_elementos] == true then buscar = false end
end
```

There is no other way out of that loop. Turn all fourteen elements off from
"active elements" and it spins forever - no redraw, no pad read, console frozen,
power button. Three button presses from the main menu.

It now gives up after one full pass and keeps the current element.
</details>

<details>
<summary><b>Silent freezes with no message at all</b></summary>

`Font.ftLoad` on a missing file and `Graphics.loadImage` on a bad PNG can both hang
the console without a word. A journal line is written **before** each risky operation,
so the last line names the culprit.
</details>

---

# 7️⃣ Diagnostics

**One journal**, `RETROLauncher.log`, replacing five separate files. What you actually
need is the **order** events happened in, and split across five files that's gone. One
category per line:

```
PRE   BOOT   CARGA   CONF   SAVES   LANZA   ART   LLAVE
```

- Flushed line by line during the critical phase, so a freeze is pinpointed.
- The last 8 KB of previous sessions is kept in front — a failed launch hands control
  back to uLaunchELF, and without history the next attempt would erase the only trace
  of the previous one.
- Written before every `System.loadELF`: resolved paths with an existence check on
  each.
- `LLAVE` lists what is actually on the stick at every start — cores present,
  `retroarch.cfg`, the cached ROM, and whether RetroArch's working folders exist.
- `INVENTARIO_ON` adds a full listing of what the launcher finds in each root. Off by
  default.

Every mechanism has a switch at the top of `system.lua`: `SAVES_PUENTE_ON`,
`ROM_SHUTTLE_ON`, `LIBRETRO_AUTO_USB`, `RETROARCH_FORZAR_ON`, `CORES_ATA_ON`,
`VMC_AUTO_ON`, `APPS_RAIZ_ON`, `MOSTRAR_ORIGEN`, `BOOT_LOG_ON`… Turn one off, reboot,
see what changes.

---

# 8️⃣ Compatibility layer

`system.lua` fills in globals removed between the 2024 and 2025 Enceladus builds:
`FREAD` / `FWRITE` / `FRDWR` / `FCREATE`, `SET` / `CUR` / `END`, `Sif` → `IOP`,
`System.rename` → `System.moveFile`. The block is inert on the original build, so
**the fork runs on both interpreters**. IRX loading only activates when the `IOP`
global is present.

Note that the bundled `RETROLauncher.elf` hasn't been rebuilt since 2024-10-20, while
`irx_load()` was added on 2026-01-17 — which is why the folder had never been
exercised.

---

# 9️⃣ Small tools

In `HelperScripts/`. Plain Python. Costs nothing to ship them, so here they are:

| Tool | What it does |
|---|---|
| 🗂️ **VMCManager.py** | Reads, lists, extracts and creates PS2 virtual memory cards. Builds the one-8 MB-card-per-game setup and names each card after its game ID. |
| 🖼️ **MediaCopier.py** | Pulls box art, screenshots and real game titles out of a Batocera / Recalbox / EmulationStation install and lays them out the way RETROLauncher expects. |
| 🔎 **PopsCheck.py** | Checks a POPStarter setup against the official quick-start guide and names which of the three usual culprits is at fault when a game boots straight back to the launcher. |
| 📺 **POPSWideScreenFinder.py** | Hunts the PS1 widescreen address through RALibretro's process memory, using snapshots of several camera views. |

**Per-game VMCs** are wired into the launcher itself: one shared 64 MB card is exactly
what corrupts saves — many games reject or damage cards over 8 MB, and a single card
lets one game clobber another's data. The launcher copies a blank formatted 8 MB
template to `VMC/<ID>.bin` on first launch and passes `-mc0=<path>` to Neutrino. Cards
are found by ID prefix, so VMCManager can rename them to something readable on the PC.

---

# 🔧 The recompile route — offered, but I don't recommend it

There **is** a proper fix: add `ata_bd` to the driver list a core loads after
`SifIopReset`. `ata_bd.irx` is `ps2atad` built with `ATA_ENABLE_BDM=1`; it already
exists in ps2sdk and calls `bdm_connect_bd()`. Two changes:

- **`fjtrujy/ps2_drivers`** — a new `ps2_ata_bd_driver.c` following the mx4sio
  template exactly, so `init_ata_bd_driver()` sits alongside the others.
- **`libretro/RetroArch`**, `frontend/drivers/platform_ps2.c` — call it after
  `init_dev9_driver()`, and add `mass1:` and `ata0:` to
  `frontend_ps2_parse_drive_list()`, which only ever offered `mass:` (volume 0). A
  second USB stick was equally unreachable, so **that part is a fix in its own right**.

Everything is in `upstream/retroarch-exfat-ata/` — both patches, the new source files,
and a GitHub Actions workflow that builds the cores.

I left my own build workflow public, for anyone curious about the recompilation side:
👉 https://github.com/soaresden/RetroArch/actions/workflows/PS2-ata-bd.yml

> ❌ **But I'd leave it there.** I built cores with it and they're half broken — one
> reports a refresh rate of **1,000,000 Hz** and the frontend forks out at zero
> seconds. And even if it worked, every core has to be re-patched and rebuilt at every
> nightly, which nobody is going to do. The USB workaround needs no recompiling and
> works with official cores today.
>
> The patch files are in the repo for anyone who wants to play with it. That's all
> they're for. 🙂

Three things worth knowing if you do try:

- `ata_bd` and `ps2atad` both export the `atad` library, so they're **mutually
  exclusive** — loading both fails at `RegisterLibraryEntries`.
- `bdmfs_fatfs/src/fs_driver.c`: `connect_bd()` calls `fs_ensure_typed_driver()`
  *before* `f_mount`, and leaves the device registered if the mount fails.
- Binary-patching the shipped ELFs is **not** an option: they're compressed by
  `ps2-packer` — one PT_LOAD segment, entry `0x01d0001c`, zero readable strings.

---

# ⏱️ Two details that cost us days

**The internal drive changes name across a core launch.** Enceladus always calls it
`mass0:`. A core renumbers everything, because it resets the IOP and mounts its own
stack in the order set by `init_drivers()`: usbmass_bd first, then mx4sio, then
ata_bd. BDM volumes are numbered as they connect, so the internal drive's index is
exactly the number of USB devices ahead of it. Verified on hardware: **`mass1:` with
one stick, `mass0:` with none.**

**`video_threaded` does nothing on PS2.** `Makefile.ps2` builds with
`HAVE_THREADS = 0`, so `video_thread_wrapper` isn't even compiled in. The setting is
read, stored, and ignored.

---

That's the lot. Diff is roughly **727 files, ~90,000 lines removed** — most of it the
twenty-four config files, the thirteen RetroArch copies and `relocation.lua`.

**Thanks for RETROLauncher — none of this would exist without it.** 🙏
