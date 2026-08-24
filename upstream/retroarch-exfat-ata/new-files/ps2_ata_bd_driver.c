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

#include <stdint.h>
#include <stddef.h>
#include <ps2_ata_bd_driver.h>
#include <ps2_dev9_driver.h>
#include <ps2_bdm_driver.h>
#include <irx_common_macros.h>

#include <sifrpc.h>
#include <loadfile.h>

EXTERN_IRX(ata_bd_irx);

#ifdef F_internals_ps2_ata_bd_driver
enum ATA_BD_INIT_STATUS __ata_bd_init_status = ATA_BD_INIT_STATUS_UNKNOWN;
DECL_IRX_VARS(ata_bd);
#else
extern enum ATA_BD_INIT_STATUS __ata_bd_init_status;
EXTERN_IRX_VARS(ata_bd);
#endif

#ifdef F_init_ps2_ata_bd_driver
static enum ATA_BD_INIT_STATUS loadIRXs(void) {
    /* Already resident from an earlier call */
    if (__ata_bd_init_status == ATA_BD_INIT_STATUS_OK)
        return ATA_BD_INIT_STATUS_OK;

    /* ATA_BD.IRX */
    if (CHECK_IRX_LOAD(ata_bd)) {
        __ata_bd_id = SifExecModuleBuffer(&ata_bd_irx, size_ata_bd_irx, 0, NULL, &__ata_bd_ret);
        if (CHECK_IRX_ERR(ata_bd))
            return ATA_BD_INIT_STATUS_IRX_ERROR;

        return ATA_BD_INIT_STATUS_OK;
    }

    /* CHECK_IRX_LOAD is false while the status is not OK: an earlier attempt
     * left the module in a failed state. Report it instead of silently
     * claiming success -- ps2hdd.irx and ps2fs.irx import the "atad" library
     * this module registers, and would fail in turn. */
    return ATA_BD_INIT_STATUS_IRX_ERROR;
}

enum ATA_BD_INIT_STATUS init_ata_bd_driver(bool init_dependencies) {
    /* Requires DEV9, which drives the expansion bay the ATA port lives on */
    if (init_dependencies && init_dev9_driver() != DEV9_INIT_STATUS_OK) {
        __ata_bd_init_status = ATA_BD_INIT_STATUS_DEPENDENCY_DEV9_ERROR;
        return __ata_bd_init_status;
    }

    /* Requires BDM, which the driver hands the drive over to */
    if (init_dependencies && init_bdm_driver() != BDM_INIT_STATUS_OK) {
        __ata_bd_init_status = ATA_BD_INIT_STATUS_DEPENDENCY_BDM_ERROR;
        return __ata_bd_init_status;
    }

    __ata_bd_init_status = loadIRXs();
    return __ata_bd_init_status;
}
#endif

#ifdef F_deinit_ps2_ata_bd_driver
static void unloadIRXs(void) {
    /* ATA_BD.IRX */
    if (CHECK_IRX_UNLOAD(ata_bd)) {
        SifUnloadModule(__ata_bd_id);
        RESET_IRX_VARS(ata_bd);
        /* Must be reset alongside the IRX vars, otherwise the early-out in
         * loadIRXs() would skip a legitimate reload. */
        __ata_bd_init_status = ATA_BD_INIT_STATUS_UNKNOWN;
    }
}

void deinit_ata_bd_driver(bool deinit_dependencies) {
    unloadIRXs();

    if (deinit_dependencies) {
        deinit_bdm_driver();
        deinit_dev9_driver();
    }
}
#endif
