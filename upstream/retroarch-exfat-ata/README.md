# Making RetroArch PS2 see an internal exFAT disk

RetroArch runs fine on a PS2 with a network adapter and a SATA drive, but any
ROM stored on that drive is invisible to it. Cores only ever see `mc0:`,
`mass:` (USB), `mx4sio:` and `cdfs:`.

This directory contains a working proposal to fix that upstream: two small
patches, one new driver file, and a CI workflow that builds the result without
installing anything locally.

---

## 1. Why it cannot be fixed from a launcher

Every RetroArch core on PS2 is a **separate, statically linked ELF** — there is
no host process loading cores as plugins. And each one calls `reset_IOP()`
before doing anything else:

```c
static void reset_IOP()
{
   SifInitRpc(0);
#if !defined(DEBUG) || defined(BUILD_FOR_PCSX2)
   while(!SifIopReset(NULL, 0)){};
#endif
   ...
}
```

`SifIopReset` wipes the I/O processor. Any driver a launcher pre-loaded is
gone before the core's own `init_drivers()` runs. There is nothing a launcher
can hand over.

Binary-patching the ELF is not a realistic alternative either: the IOP modules
are compiled in as byte arrays and the load sequence is fixed machine code, so
adding a module means injecting both ~10 KB of data and a call site — in every
core ELF, and again after every RetroArch release.

The fix has to be in the core's own startup path.

---

## 2. What is actually missing

`frontend/drivers/platform_ps2.c`, `init_drivers()`:

```c
init_fileXio_driver();
init_memcard_driver(true);
init_usb_driver(true);      /* usbd + bdm + bdmfs_fatfs + usbmass_bd */
init_mx4sio_driver(true);
init_cdfs_driver();
/* ... only_if_booted_from_hdd / DEBUG handling / init_poweroff_driver() ... */
init_dev9_driver();
hddStatus = init_hdd_driver(false, only_if_booted_from_hdd);
```

The core already loads:

* the **whole BDM stack** — including `bdmfs_fatfs.irx`, which is what
  understands FAT32 and exFAT and publishes `massN:`;
* **`dev9`**, the expansion-bay layer the internal ATA port sits behind.

The only missing piece is the module that hands an ATA drive to BDM.

That module already exists in ps2sdk and is built and installed by default —
`ps2sdk/iop/dev9/ata_bd/Makefile`:

```make
IOP_SRC_DIR = $(PS2SDKSRC)/iop/dev9/atad/src/
IOP_INC_DIR = $(PS2SDKSRC)/iop/dev9/atad/include/
ATA_ENABLE_BDM ?= 1
IOP_BIN ?= ata_bd.irx
include $(PS2SDKSRC)/iop/dev9/atad/Makefile
```

`ata_bd.irx` **is** `ps2atad.irx`, compiled with `ATA_ENABLE_BDM=1`. That flag
enables one block in `ps2atad.c`:

```c
#ifdef ATA_ENABLE_BDM
    g_ata_bd[i].sectorCount = devinfo[i].total_sectors_lba48;
    bdm_connect_bd(&g_ata_bd[i]);
#endif
```

`ps2_drivers` embeds `ps2atad.irx` — the build **without** BDM — and only from
`init_hdd_driver()`, which targets the native APA/PFS stack (`hdd0:`) and which
RetroArch calls with `only_if_booted_from_hdd = true`. So nothing in the chain
ever loads `ata_bd.irx`, the drive is never a BDM block device, and
`bdmfs_fatfs` never looks at it.

No ps2sdk change is required. `ata_bd` is already in `iop/dev9/Makefile`'s
`SUBDIRS` and its Makefile defaults to `ATA_ENABLE_BDM ?= 1`, so a current
ps2sdk installs `$PS2SDK/iop/irx/ata_bd.irx` on its own. How far back that goes
has not been established here, which is why the CI workflow checks for the file
and fails with an explicit message rather than building something subtly
broken.

---

## 3. The proposed change

### `ps2_drivers` — `patches/ps2_drivers-ata_bd.patch`

* New `src/ps2_ata_bd_driver.c` + `include/ps2_ata_bd_driver.h`, embedding
  `ata_bd.irx` and following the exact shape of the existing `mx4sio` driver
  (`F_internals` / `F_init` / `F_deinit` split, `CHECK_IRX_*` macros,
  `init_dependencies` flag). Dependencies: `dev9` and `bdm`.
* `ps2_hdd_driver.c` **stops embedding `ps2atad.irx`** and depends on the new
  driver instead.

  This part matters. `ata_bd` exports the same `atad` library `ps2atad` does,
  so the two are mutually exclusive — loading both fails at
  `RegisterLibraryEntries` and would have broken APA HDD support. Since
  `ps2hdd.irx` and `ps2fs.irx` sit on that library unchanged, routing the HDD
  driver through `ata_bd` leaves `hdd0:` working exactly as before and gets BDM
  for free. One ATA module in the system, not two.
* `ps2_filesystem_driver.c` loads it from `init_ps2_filesystem_driver()` and
  from the `BOOT_DEVICE_HDD` branch of `init_only_boot_...`, with matching
  deinit calls.

  Both pass `init_dependencies = true`. That is not cosmetic on the second
  path: `init_only_boot_...` never calls `init_usb_driver()`, so `bdm.irx` is
  not resident there, and `ata_bd.irx` imports `bdm_connect_bd()` /
  `bdm_disconnect_bd()` unconditionally (`iop/dev9/atad/src/imports.lst`) — it
  would fail to link. `init_ata_bd_driver()` also reports a stale failure
  rather than returning OK on a second call, because `ps2hdd.irx` and
  `ps2fs.irx` import the `atad` library it registers and would fail in turn.
* Teardown follows ownership: `deinit_hdd_driver()` releases `ata_bd` only in
  its `deinit_dependencies` branch, alongside `bdm` and `dev9`. A caller that
  shuts the HDD driver down while keeping the filesystem driver up therefore
  keeps the internal disk's `massN:` mapping.
* `CMakeLists.txt`: `add_irx_source(ata_bd …)` replaces `ps2atad`, plus the
  driver objects.

### RetroArch — `patches/RetroArch-platform_ps2-ata_bd.patch`

Two lines of substance:

```c
   init_dev9_driver();
+  init_ata_bd_driver(true);
   hddStatus = init_hdd_driver(false, only_if_booted_from_hdd);
```

```c
   deinit_hdd_driver(false);
+  deinit_ata_bd_driver(false);
   deinit_dev9_driver();
```

`platform_ps2.c` includes `<ps2_all_drivers.h>` → `ps2_filesystem_driver.h`,
which now pulls in the new header, so no include change is needed there.

The intent is that an internal FAT32/exFAT drive then appears as `massN:` and
every core reads it with no further work — this has not been run on hardware
yet, see section 9. It is orthogonal to APA/PFS support (`hdd0:`): it covers
exFAT-formatted internal drives, which is how OPL, NHDDL and Neutrino already
handle them.

---

## 4. Open questions to settle before proposing this upstream

### 4.1 `mass` numbering

`bdmfs_fatfs` numbers mass devices in the order block devices connect. Adding a
second source of block devices can therefore shift a USB stick from `mass0:` to
`mass1:`, and RetroArch derives its working directory from the path it was
launched with.

`init_ata_bd_driver()` is called **after** `init_usb_driver()` and
`init_mx4sio_driver()` so those get first claim, but USB enumeration is
asynchronous and slow while ATA connects almost immediately, so ordering the
calls is not a guarantee.

This is the one thing to verify on hardware before proposing the change
upstream, in this order:

1. USB stick only, no internal drive → still `mass0:`, nothing changed.
2. Internal drive only → shows up, cores can read from it.
3. Both → note which is `mass0:`, and whether booting RetroArch from each of
   them still finds its config and assets.

If case 3 turns out to renumber, the honest upstream shape is a build-time or
config option rather than unconditional loading — worth saying so in the PR
rather than being asked.

Note also that `bdmfs_fatfs` is built with `FF_VOLUMES 10`, so there is a cap
on how many `mass` volumes can coexist.

### 4.2 Unconditional ATA probing at boot

Under `ATA_ENABLE_BDM`, the module's `_start` calls `sceAtaInit(0)` and
`sceAtaInit(1)` — a full ATA bus reset plus IDENTIFY on both devices — at load
time. Until now RetroArch's `only_if_booted_from_hdd = true` meant the ATA
driver was never loaded on a USB or memory-card boot; with this change it is
loaded on every boot.

That is a new fixed cost at startup for users who have no internal drive at
all, and it exercises a code path that ps2sdk itself flags as delicate on
PSX/DVR units (see the `ata_dvrp_workaround` handling in `ps2atad.c`). Worth
measuring the added boot time on a console without a network adapter, and
worth mentioning in the PR unprompted.

---

## 5. Building it without installing anything

`workflow/PS2-ata-bd.yml` goes into `.github/workflows/` of a RetroArch fork.
It runs in `reallibretroretroarch/libretro-build-ps2`, the same container the
official PS2 CI uses, rebuilds `ps2_drivers` with the patch, installs it into
the container's PS2SDK, then builds RetroArch. Artifacts are downloadable from
the run page.

Two jobs:

* **build** — Salamander + RetroArch with the static dummy core. This alone is
  enough to test the fix: boot `retroarchps2.elf` and open the file browser; the
  internal disk should be listed as `massN:`.
* **core** — a matrix building three real cores (fceumm, Genesis Plus GX,
  snes9x2005) end to end, for a playable build.

The workflow fails early with an explicit message if the container's ps2sdk
predates `ata_bd.irx`, and again if the `ps2_drivers` fork it clones does not
actually contain the new driver — a silent build without the fix would be worse
than no build.

`PS2_DRIVERS_REPO` / `PS2_DRIVERS_REF` at the top of the file point at the
`ps2_drivers` fork to build against.

---

## 6. Order of work

1. Fork `fjtrujy/ps2_drivers`, apply `patches/ps2_drivers-ata_bd.patch`, push.
2. Fork `libretro/RetroArch`, apply
   `patches/RetroArch-platform_ps2-ata_bd.patch`, add the workflow, push.
3. Run the workflow, download the dummy-core artifact, test on hardware
   following the three cases in section 4.
4. If it holds up: PR to `ps2_drivers` first (RetroArch's change depends on it),
   then to RetroArch, linking the existing issues below.

## 7. Existing upstream issues

* [libretro/RetroArch#14346](https://github.com/libretro/RetroArch/issues/14346)
  — [PS2] No Internal HDD Support
* [libretro/RetroArch#16010](https://github.com/libretro/RetroArch/issues/16010)
  — PS2 HDD Support

Both describe this gap and are still open.

---

## 8. What RETROLauncher does meanwhile

The launcher copies a ROM that lives on the internal disk to a device the core
can read — USB stick first, memory card otherwise — immediately before
launching, and passes that path instead. The copy is cached, so relaunching the
same game is free. It works for NES, SNES, Mega Drive and Game Boy, but the
memory card's 8 MB is a hard ceiling when no USB stick is present, and a GBA
ROM will not fit.

## 9. Hardware result

Tested on a PS2 FAT with a network adapter and a SATA drive formatted exFAT,
using the dummy-core build produced by the CI workflow in section 5.

**The drive mounts.** With no USB stick connected, the browser lists it and
reads it — a device that simply did not exist for any core before this patch.

The second observation was more interesting. With a USB stick *also* connected,
the browser showed only the stick. Not because the drive failed to mount, but
because `frontend_ps2_parse_drive_list` only ever offered `mass:` — BDM volume
zero. The stick takes volume zero, the internal drive lands on volume one, and
nothing in the menu could reach it.

Which name the drive ends up with depends on the ps2sdk the core was built
against:

* A **current** ps2sdk: `ps2atad.c:357-358` sets `g_ata_bd[i].name = "ata"` and
  `.path = "ata"`, and `bdmfs_fatfs/src/fs_driver.c:195-236` registers one
  iomanX device per distinct `bd->path`, `"mass"` handled separately.
  `usbmass_bd` never sets `.path`, so USB keeps `mass` and the drive becomes
  `ata0:`.
* An **older** ps2sdk folds every block device into `"mass"`, and the drive is
  simply the next `massN:`.

The patch therefore lists `mass0:`, `mass1:` and `ata0:` alongside the existing
`mass:`, so one binary behaves correctly either way.

On the container's ps2sdk it is the second case: the drive answers to `mass1:`
and reads correctly, while `ata0:` exists but enumerates empty. Worth knowing
why that is possible — `connect_bd` registers the iomanX device *before*
attempting `f_mount` and leaves it registered if the mount fails, so a device
appearing in the list is not proof that anything mounted. `ata0:` is left in the
list anyway: it costs one entry, and it is the name a newer bdmfs_fatfs gives
the same drive.

Note that listing `mass1:` is a fix in its own right, independent of ATA: a
second USB stick was equally unreachable before, for exactly the same reason.

The important consequence: **nothing is renumbered**. A USB stick keeps volume
zero and keeps `mass:`; every path a user already configured still resolves. The
"should this be an option rather than unconditional" question raised in section
4.1 is answered — it can be unconditional.

The only remaining cost is the one in section 4.2 — `sceAtaInit` runs at boot on
machines with no internal drive.

### The drive list needed the same treatment

Mounting the drive is not enough to make it reachable. `frontend_ps2_parse_drive_list`
(`platform_ps2.c:461`) builds the browser's device list from a fixed set of
`BOOT_DEVICE_*` constants — mc0, mc1, cdfs, mass, host, plus the APA mount point
when one exists. `ata0:` was mounted and usable by absolute path, and RetroArch
was even deriving its own directories from it when launched off the drive, but
the file browser never offered it.

So the patch also adds `BOOT_DEVICE_ATA0` / `ATA1` to `ps2_filesystem_driver`
(appended at the end of the enum, so existing values keep their numbers) with
their entries in `rootDevicePath()` and `getBootDeviceID()`, and appends them to
the drive list — guarded by `path_is_directory`, so a console with no expansion
bay sees exactly the list it saw before.

### What this means for a launcher

The device name differs between Enceladus and a core, for the same disk:

    Enceladus (its own BDM stack)   mass0:
    a RetroArch core                ata0:

Different ps2sdk vintages: the older `bdmfs_fatfs` folds every block device into
`mass`, the current one honours `bd->path`. A launcher that hands a core an
absolute path to a file on the internal drive has to translate `mass0:` to
`ata0:`, and must not translate a memory-card path at all.

## 10. Verification status of the code here

What has been done:

* The new driver compiles clean under `-Wall -Wextra -Werror` and links
  correctly across all three `F_*` translation units the CMake build splits it
  into, using host GCC against stub headers.
* The patch was reviewed against the real ps2sdk, ps2_drivers and RetroArch
  sources. That review caught two genuine defects, both fixed here: a missing
  BDM dependency on the HDD-boot path that would have broken `hdd0:` outright,
  and an `init` that reported success after a failed module load.

What has **not** been done: the patch has never been cross-compiled for PS2,
and never run on hardware. That is what the CI workflow in section 5 is for,
and it is step 3 of section 6. Nothing here should be sent upstream before
that step passes.
