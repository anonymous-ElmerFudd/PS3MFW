#!/usr/bin/tclsh
#
# ps3mfw -- PS3 MFW creator
#
# Copyright (C) Anonymous Developers (Code Monkeys)
#
# This software is distributed under the terms of the GNU General Public
# License ("GPL") version 3, as published by the Free Software Foundation.
#

# Priority: 103
# Description: PATCH: Patch VSH for unsigned PKG's (4.xx)

# Option --allow-unsigned-app-4xx: Patch to allow running of unsigned applications

# Type --allow-unsigned-app-4xx: boolean

namespace eval ::patch_uns {

    array set ::patch_uns::options {
        --allow-unsigned-app-4xx true
    }

    proc main { } {
        set path [file join dev_flash data cert]
            set self [file join dev_flash vsh module vsh.self]
			
            ::modify_devflash_file $self ::patch_uns::patch_self
    }

    proc patch_self {self} {    
        ::modify_self_file $self ::patch_uns::patch_elf
    }

    proc patch_elf {elf} {
        if {$::patch_uns::options(--allow-unsigned-app-4xx)} {
            log "Patching [file tail $elf] to allow running of unsigned applications"
			log "Proved Legit by RedDot-3ND7355"
			log "Part 1"
         
            set search "\xF8\x21\xFF\x81\x7C\x08\x02\xA6\x38\x61\x00\x70\xF8\x01\x00\x90\x4B\xFF\xFF\xE1\x38\x00\x00\x00"
            set replace "\x38\x60\x00\x01\x4E\x80\x00\x20"
         
            catch_die {::patch_elf $elf $search 0 $replace} "Unable to patch self [file tail $elf]"
         
			log "Proved Legit by RedDot-3ND7355"
			log "Part 2"

            set search "\xA0\x7F\x00\x04\x39\x60\x00\x01\x38\x03\xFF\x7F\x2B\xA0\x00\x01\x40\x9D\x00\x08\x39\x60\x00\x00"
            set replace "\x60\x00\x00\x00"
         
            catch_die {::patch_elf $elf $search 20 $replace} "Unable to patch self [file tail $elf]"
        }
	}
}
