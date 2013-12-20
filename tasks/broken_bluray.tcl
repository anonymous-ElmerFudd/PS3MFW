#!/usr/bin/tclsh
#
# ps3mfw -- PS3 MFW creator
#
# Copyright (C) Anonymous Developers (Code Monkeys)
#
# This software is distributed under the terms of the GNU General Public
# License ("GPL") version 3, as published by the Free Software Foundation.
#
    
# Priority: 0000
# Description: ---- Allow firmware update of console with broken blu-ray drive
    
# Option --remove-bd-revoke: remove BdpRevoke (ENABLING THIS WILL REMOVE BLU-RAY DRIVE FIRMWARE)
# Option --remove-bd-firmware: remove BD firmware (ENABLING THIS WILL REMOVE BLU-RAY DRIVE FIRMWARE)

# Type --remove-bd-revoke: boolean
# Type --remove-bd-firmware: boolean

namespace eval ::broken_bluray {

    array set ::broken_bluray::options {
        --remove-bd-revoke true
        --remove-bd-firmware true
    }
    
    proc main {} {
        ::modify_upl_file ::broken_bluray::callback
    }
    
    proc callback { file } {
	
        log "Modifying XML file [file tail ${file}]"       
        set xml [::xml::LoadFile $file]
        if {$::broken_bluray::options(--remove-bd-revoke)} {
		  log "Removing BdpRevoke package...."
          set xml [::remove_pkg_from_upl_xml $xml "BdpRevoke" "blu-ray drive revoke"]
        }

        if {$::broken_bluray::options(--remove-bd-firmware)} {
		  log "Removing Blu-ray firmware packages...."
          set xml [::remove_pkgs_from_upl_xml $xml "BD" "blu-ray drive firmware"]
        }
		# save the file as is, then re-read it
		# in, and fixup the CR/LFs, etc
        ::xml::SaveToFile $xml $file
		
		set finaldata ""		
		set xml ""
		set fd [open $file r]
		fconfigure $fd -translation binary 
        set xml [read $fd]
        close $fd     		
		
		# iterate through the 'xml' data
		# since the "xml.tcl" removes the original xml header, we
		# need to add it back!!
		append finaldata "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\x0A"		
		set lines [split $xml "\x0D"]
		foreach line $lines {			
			append finaldata $line
		}
        # write out final data
        set fd [open $file w]
		fconfigure $fd -translation binary
        puts -nonewline $fd $finaldata
        close $fd        		
    }
}
