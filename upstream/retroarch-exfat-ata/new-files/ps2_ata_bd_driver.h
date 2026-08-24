/*
# _____     ___ ____     ___ ____
#  ____|   |    ____|   |        | |____|
# |     ___|   |____ ___|    ____| |    \    PS2DEV Open Source Project.
#-----------------------------------------------------------------------
# Copyright 2005, ps2dev - http://www.ps2dev.org
# Licenced under GNU Library General Public License version 2
# Review ps2sdk README & LICENSE files for further details.
#
# PS2_ATA_BD_DRIVER
*/

#ifndef PS2_ATA_BD_DRIVER
#define PS2_ATA_BD_DRIVER

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

enum ATA_BD_INIT_STATUS {
    ATA_BD_INIT_STATUS_DEPENDENCY_BDM_ERROR = -4,
    ATA_BD_INIT_STATUS_DEPENDENCY_DEV9_ERROR = -3,
    ATA_BD_INIT_STATUS_IRX_ERROR = -2,
    ATA_BD_INIT_STATUS_UNKNOWN = -1,
    ATA_BD_INIT_STATUS_OK = 0,
};

/* ATA_BD DRIVER REQUIRES DEV9 AND BDM DRIVERS AS DEPENDENCIES.
 *
 * ata_bd.irx is the very same driver as ps2atad.irx, built with
 * ATA_ENABLE_BDM=1. On top of the "atad" library exported by ps2atad, it
 * calls bdm_connect_bd() for every drive it finds, which publishes the
 * internal ATA disk as a BDM block device. Combined with bdmfs_fatfs.irx,
 * that makes a FAT32/exFAT formatted internal drive visible as massN:,
 * exactly like a USB stick or an MX4SIO card.
 *
 * Because ata_bd exports the same "atad" library as ps2atad, the two are
 * mutually exclusive: loading both fails. The APA stack (ps2hdd/ps2fs, i.e.
 * hdd0:) works on top of ata_bd just as well, so ps2_hdd_driver depends on
 * this driver instead of embedding ps2atad.irx of its own.
 */
/* With init_dependencies = false, dev9 and bdm must already be resident:
 * ata_bd.irx imports bdm_connect_bd()/bdm_disconnect_bd() unconditionally and
 * will fail to link otherwise. */
enum ATA_BD_INIT_STATUS init_ata_bd_driver(bool init_dependencies);
void deinit_ata_bd_driver(bool deinit_dependencies);

#ifdef __cplusplus
}
#endif

#endif /* PS2_ATA_BD_DRIVER */
