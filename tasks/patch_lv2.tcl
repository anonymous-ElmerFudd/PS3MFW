#!/usr/bin/tclsh
#
# ps3mfw -- PS3 MFW creator
#
# Copyright (C) Anonymous Developers (Code Monkeys)
#
# This software is distributed under the terms of the GNU General Public
# License ("GPL") version 3, as published by the Free Software Foundation.
#

# Priority: 0006
# Description: PATCH: LV2 - Miscellaneous


namespace eval ::patch_lv2 {

    array set ::patch_lv2::options {
		
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
		# apply any MISC lv2 patches here....
		
    }
	##
	################################################################################################################################################
}
	