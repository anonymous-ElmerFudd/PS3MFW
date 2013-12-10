#!/usr/bin/tclsh
#
# ps3mfw -- PS3 MFW creator
#
# Copyright (C) Anonymous Developers (Code Monkeys)
#
# This software is distributed under the terms of the GNU General Public
# License ("GPL") version 3, as published by the Free Software Foundation.
#

# Priority: 0002
# Description: PATCH: LV2 - Miscellaneous

# Option --patch-misc-rogero-patches: [3.xx/4.xx]  -->  Patch LV2 with misc ROGERO patches

# Type --patch-misc-rogero-patches: boolean

namespace eval ::patch_lv2 {

    array set ::patch_lv2::options {
		--patch-misc-rogero-patches true
    }
		
    proc main { } {
	
        # call the function to do any LV2_KERNEL selected patches				
		set self "lv2_kernel.self"
		set path $::CUSTOM_COSUNPKG_DIR
		set file [file join $path $self]		
		::modify_self_file $file ::patch_lv2::Do_LV2_Patches	    
    }   
	
	##################			 proc for applying any  "MISCELLANEOUS"  LV2_KERNEL patches    	##############################################################
	#
	#
	# ----- As of OFW version 4.50, still UNSURE as to what exactly these patches are,
	# ----- currently suspect they are QA flag related, but not sure...
	#
	proc Do_LV2_Patches {elf} {
		
		log "Applying MISC LV2 patches (QA Flag patches???)...."	
		if {$::patch_lv2::options(--patch-misc-rogero-patches)} {		    
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55 == 0x29A3EC (0x28A3EC)
			# OFW 3.60 == 0x29AC54 (0x28AC54)
			# OFW 3.70 == 0x2A0188 (0x290188)  
			# OFW 4.46 == 0x2A72FC (0x2972FC)
			# OFW 4.50 == 0x27F608 (0x26F608)
			log "Patching LV2_KERNEL with Rogero QA Flag patch??"						 
			set search    "\x7C\x09\xFE\x76\x7D\x23\x02\x78\x7C\x69\x18\x50\x38\x63\xFF\xFF"
			append search "\x78\x63\x0F\xE0\x4E\x80\x00\x20\x80\x03\x02\x6C"
			set replace   "\x38\x60\x00\x00\x7C\x63\x07\xB4\x4E\x80\x00\x20"
			set offset 24       				
			# PATCH THE ELF BINARY
            catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"  		
		}
    }
	##
	################################################################################################################################################
}
	