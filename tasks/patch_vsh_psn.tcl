#!/usr/bin/tclsh
#
# ps3mfw -- PS3 MFW creator
#
# Copyright (C) Anonymous Developers (Code Monkeys)
#
# This software is distributed under the terms of the GNU General Public
# License ("GPL") version 3, as published by the Free Software Foundation.
#

# Created By RazorX

# Priority: 111
# Description: PATCH: Patch VSH for Offline PSN Activator

# Option --allow-activating-psn-retail1: Patch to allow activating psn content offline for 3.55 retail
# Option --allow-activating-psn-debug1: Patch to allow activating psn content offline for 3.55 debug
# Option --allow-activating-psn-retail2: Patch to allow activating psn content offline for 3.41 retail
# Option --allow-activating-psn-debug2: Patch to allow activating psn content offline for 3.41 debug

# Type --allow-activating-psn-retail1: boolean
# Type --allow-activating-psn-debug1: boolean
# Type --allow-activating-psn-retail2: boolean
# Type --allow-activating-psn-debug2: boolean

namespace eval ::patch_vsh_psn {

    array set ::patch_vsh_psn::options {
        --allow-activating-psn-retail1 true
		--allow-activating-psn-debug1 false
        --allow-activating-psn-retail2 false
		--allow-activating-psn-debug2 false
    }

    proc main { } {
        set self [file join dev_flash vsh module vsh.self]

        ::modify_devflash_file $self ::patch_vsh_psn::patch_self
    }

    proc patch_self {self} {
        if {!$::patch_vsh_psn::options(--allow-activating-psn-retail1)} {
            log "WARNING: Enabled task has no enabled option" 1
        } else {
            ::modify_self_file $self ::patch_vsh_psn::patch_elf
        }
    }

    proc patch_elf {elf} {
        if {$::patch_vsh_psn::options(--allow-activating-psn-retail1)} {
            log "Patching [file tail $elf] to allow activating psn content offline"

			set offset "0x30b230"
            set search "\x4b\xcf\x5b\x45"
            set replace "\x38\x60\x00\x00"

            catch_die {::patch_elf $elf $search 0 $replace} "Unable to patch self [file tail $elf]"

			set offset "0x30ac90"
            set search "\x48\x31\xb4\x65"
            set replace "\x38\x60\x00\x00"

            catch_die {::patch_elf $elf $search 20 $replace} "Unable to patch self [file tail $elf]"
			
			log "WARNING: activating psn content offline requires reActPSN application" 1
        }
    }
			
    proc patch_self {self} {
        if {!$::patch_vsh_psn::options(--allow-activating-psn-debug1)} {
            log "WARNING: Enabled task has no enabled option" 1
        } else {
            ::modify_self_file $self ::patch_vsh_psn::patch_elf
        }
    }

    proc patch_elf {elf} {
        if {$::patch_vsh_psn::options(--allow-activating-psn-debug1)} {
            log "Patching [file tail $elf] to allow activating psn content offline"

			set offset "0x312308"
            set search "\x4b\xce\xea\x6d"
            set replace "\x38\x60\x00\x00"

            catch_die {::patch_elf $elf $search 0 $replace} "Unable to patch self [file tail $elf]"

			set offset "0x311d68"
            set search "\x48\x31\xb7\xd5"
            set replace "\x38\x60\x00\x00"

            catch_die {::patch_elf $elf $search 20 $replace} "Unable to patch self [file tail $elf]"

            log "WARNING: activating psn content offline requires reActPSN application" 1
        }
    }
	
	    proc patch_self {self} {
        if {!$::patch_vsh_psn::options(--allow-activating-psn-retail2)} {
            log "WARNING: Enabled task has no enabled option" 1
        } else {
            ::modify_self_file $self ::patch_vsh_psn::patch_elf
        }
    }

    proc patch_elf {elf} {
        if {$::patch_vsh_psn::options(--allow-activating-psn-retail2)} {
            log "Patching [file tail $elf] to allow activating psn content offline"

			set offset "0x305dc4"
            set search "\x4b\xcf\xaf\xb1"
            set replace "\x38\x60\x00\x00"

            catch_die {::patch_elf $elf $search 0 $replace} "Unable to patch self [file tail $elf]"

			set offset "0x305824"
            set search "\x48\x31\x43\xad"
            set replace "\x38\x60\x00\x00"

            catch_die {::patch_elf $elf $search 20 $replace} "Unable to patch self [file tail $elf]"
			
			log "WARNING: activating psn content offline requires reActPSN application" 1
        }
    }
	
		    proc patch_self {self} {
        if {!$::patch_vsh_psn::options(--allow-activating-psn-debug2)} {
            log "WARNING: Enabled task has no enabled option" 1
        } else {
            ::modify_self_file $self ::patch_vsh_psn::patch_elf
        }
    }

    proc patch_elf {elf} {
        if {$::patch_vsh_psn::options(--allow-activating-psn-debug2)} {
            log "Patching [file tail $elf] to allow activating psn content offline"

			set offset "0x30cedc"
            set search "\x4b\xcf\x3e\x99"
            set replace "\x38\x60\x00\x00"

            catch_die {::patch_elf $elf $search 0 $replace} "Unable to patch self [file tail $elf]"

			set offset "0x30c93c"
            set search "\x48\x31\x47\x1d"
            set replace "\x38\x60\x00\x00"

            catch_die {::patch_elf $elf $search 20 $replace} "Unable to patch self [file tail $elf]"
			
			log "WARNING: activating psn content offline requires reActPSN application" 1
        }
    }
}
