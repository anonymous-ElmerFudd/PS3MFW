#!/usr/bin/tclsh
#
# ps3mfw -- PS3 MFW creator
#
# Copyright (C) Anonymous Developers (Code Monkeys)
#
# This software is distributed under the terms of the GNU General Public
# License ("GPL") version 3, as published by the Free Software Foundation.
#

# Priority: 0005
# Description: PATCH: Patch VSH - Miscellaneous

# Option --enable-spoof-build: [3.xx/4.xx]  -->  Enable setting PUP build version (FW Spoofing)
# Option --spoof-build-number:	[3.xx/4.xx] ---->  PUP build version to set
# Option --patch-rogero-vsh-patches: [3.xx/4.xx]  -->  Patch VSH with ROGERO patches
# Option --allow-unsigned-app: [3.xx/4.xx]  -->  Patch to allow running of unsigned applications (3.xx/4.xx)
# Option --patch-vsh-react-psn-v2-4x: [3.xx/4.xx]  -->  Jailbait - Patch to implement ReactPSN v2.0 into VSH (3.xx/4.xx)
# Option --patch-vsh-no-delete-actdat: [3.xx/4.xx]  -->  Jailbait - Patch to implement NO deleting of unsigned act/dat (3.xx/4.xx)
# Option --disable-cinavia-protection-4x: [3.xx/4.xx]  -->  Disable Cinavia Protection (4.xx)
# Option --allow-retail-pkg-dex: [3.xx/4.xx]  -->  Patch to allow installation of retail packages on DEX (3.xx/4.xx)
# Option --allow-pseudoretail-pkg: [3.xx/4.xx]  -->  Patch to allow installation of pseudo-retail packages on REX/DEX (3.xx/4.xx)
# Option --allow-debug-pkg: [3.xx/4.xx]  -->  Patch to allow installation of debug packages (3.xx/4.xx)
# Option --customize-fw-ssl-cer: [3.xx/4.xx]  -->  Change SSL - New SSL CA certificate (source)
# Option --customize-fw-change-cer: [3.xx/4.xx]  -->  Change SSL - SSL CA public certificate (destination)

# Type --enable-spoof-build: boolean
# Type --spoof-build-custom: combobox { }
# Type --patch-rogero-vsh-patches: boolean
# Type --allow-unsigned-app: boolean
# Type --patch-vsh-react-psn-v2-4x: boolean
# Type --patch-vsh-no-delete-actdat: boolean
# Type --disable-cinavia-protection-4x: boolean
# Type --allow-retail-pkg-dex: boolean
# Type --allow-pseudoretail-pkg: boolean
# Type --allow-debug-pkg: boolean
# Type --customize-fw-ssl-cer: file open {"SSL Certificate" {cer}}
# Type --customize-fw-change-cer: combobox {{DNAS} {Proxy} {ALL} {CA01.cer} {CA02.cer} {CA03.cer} {CA04.cer} {CA05.cer} {CA23.cer} {CA06.cer} {CA07.cer} {CA08.cer} {CA09.cer} {CA10.cer} {CA11.cer} {CA12.cer} {CA13.cer} {CA14.cer} {CA15.cer} {CA16.cer} {CA17.cer} {CA18.cer} {CA19.cer} {CA20.cer} {CA21.cer} {CA22.cer} {CA24.cer} {CA25.cer} {CA26.cer} {CA27.cer} {CA28.cer} {CA29.cer} {CA30.cer} {CA31.cer} {CA32.cer} {CA33.cer} {CA34.cer} {CA35.cer} {CA36.cer}}

namespace eval ::patch_vsh {

    array set ::patch_vsh::options {
		--enable-spoof-build true
		--spoof-build-number "99999"
		--patch-rogero-vsh-patches true
		--allow-unsigned-app true
		--patch-vsh-react-psn-v2-4x true
		--patch-vsh-no-delete-actdat false	
		--disable-cinavia-protection-4x false		
        --allow-retail-pkg-dex false
        --allow-pseudoretail-pkg false		
        --allow-debug-pkg false		
        --customize-fw-ssl-cer ""
        --customize-fw-change-cer ""		   
    }

    proc main { } {
        variable options
        set src $::patch_vsh::options(--customize-fw-ssl-cer)
        set dst $::patch_vsh::options(--customize-fw-change-cer)
        set path [file join dev_flash data cert]
		
		
		# setup vars based on the spoof string
        if {$::patch_vsh::options(--enable-spoof-build)} {
			set org_build ""
			set new_build ""
			log "Changing PUP build version, patching UPL.xml........"
			            
			set org_build ${::PUP_BUILD}
			set new_build $::patch_vsh::options(--spoof-build-number)	
			
			# go patch the UPL.xml file
            ::modify_upl_file ::patch_vsh::set_upl_xml_build $new_build			
		}
     
		# if "retail/debug pkg" options, then patch "nas_plugin.sprx"
        if {$::patch_vsh::options(--allow-pseudoretail-pkg) || $::patch_vsh::options(--allow-debug-pkg) || $::patch_vsh::options(--allow-retail-pkg-dex)} {
            set self [file join dev_flash vsh module nas_plugin.sprx]
            ::modify_devflash_file $self ::patch_vsh::patch_self
        }
        # if "unsigned/psn" patches enabled, patch "vsh.self"
        if {$::patch_vsh::options(--allow-unsigned-app) || $::patch_vsh::options(--patch-vsh-react-psn-v2-4x) || $::patch_vsh::options(--patch-rogero-vsh-patches) ||
			$::patch_vsh::options(--patch-vsh-no-delete-actdat)} {
            set self [file join dev_flash vsh module vsh.self]
            ::modify_devflash_file $self ::patch_vsh::patch_self
        }		
		
        # if "--customize-fw-ssl-cer" is defined, patch it
        if {$::patch_vsh::options(--customize-fw-ssl-cer) != ""} {
            if {[file exists $src] == 0 } {
                die "Source SSL CA public certificate file $src does not exist"
            } elseif {[string equal $dst "DNAS"] == 1} {
                log "Changing DNAS SSL CA public certificates to [file tail $dst]" 1
                set dst "CA01.cer CA02.cer CA03.cer CA04.cer CA05.cer"
                ::modify_devflash_files $path $dst ::patch_vsh::copy_customized_file $src
            } elseif {[string equal $dst "Proxy"] == 1} {
                log "Changing SSL CA public certificates to [file tail $src]" 1
                set dst "CA06.cer CA07.cer CA08.cer CA09.cer CA10.cer CA11.cer CA12.cer CA13.cer CA14.cer CA15.cer CA16.cer CA17.cer CA18.cer CA19.cer CA20.cer CA21.cer CA22.cer CA23.cer CA24.cer CA25.cer CA26.cer CA27.cer CA28.cer CA29.cer CA30.cer CA31.cer CA32.cer CA33.cer CA34.cer CA35.cer CA36.cer"
                ::modify_devflash_files $path $dst ::patch_vsh::copy_customized_file $src
            } elseif {[string equal $dst "ALL"] == 1} {
                log "Changing ALL SSL CA public certificates to [file tail $dst]" 1
                set dst "CA01.cer CA02.cer CA03.cer CA04.cer CA05.cer CA06.cer CA07.cer CA08.cer CA09.cer CA10.cer CA11.cer CA12.cer CA13.cer CA14.cer CA15.cer CA16.cer CA17.cer CA18.cer CA19.cer CA20.cer CA21.cer CA22.cer CA23.cer CA24.cer CA25.cer CA26.cer CA27.cer CA28.cer CA29.cer CA30.cer CA31.cer CA32.cer CA33.cer CA34.cer CA35.cer CA36.cer"
                ::modify_devflash_files $path $dst ::patch_vsh::copy_customized_file $src
            } else {
                log "Changing SSL CA public certificate $dst to [file tail $src]" 1
                set dst [file join $path [lindex $dst 0]]
                ::modify_devflash_file $dst ::patch_vsh::copy_customized_file $src
            }
        }
		# if "--disable-cinavia-protection-4x" enabled, patch it
		if {$::patch_vsh::options(--disable-cinavia-protection-4x)} {
		    log "Swapping videoplayer_plugin.sprx from Debug FW to Retail one..."
			log "...to disable cinavia protection"
			::patch_vsh::swappCinavia
		}
    }
	
	# ------------------------------------------------- #
	# func. to replace the "UPL.xml.pkg" "buildnum" in
	# the '<BUILD>buildnum, buildate</BUILD>' tag
	proc set_upl_xml_build {filename buildnum} {
	        
		# retrieve the '<BUILD>.....</BUILD>' xml tag
        set data [::get_header_key_upl_xml $filename Build Build]	
		if { [regexp {(^[0-9]{5,5}),.*} $data none orgbuild] == 0} {
			die "Failed to locate build number in UPL file!\n"
		}			
		# substitute in the new build number
		if {[regsub ($orgbuild) $data $buildnum data] == 0} {
			die "Failed updating build number in UPL file\n"
		}				
		# update the <BUILD>....</BUILD> data
		set xml [::set_header_key_upl_xml $filename Build "${data}" Build]
		if { $xml == "" } {
			die "Updating build number in UPL.xml failed...."
		} 
		set ::PUP_BUILD $buildnum
    }
	# ------------------------------------------------- #
	
	# proc for dispatching to the appropriate func to path the
	# desired "self" file
    proc patch_self {self} { 		
		::modify_self_file $self ::patch_vsh::patch_elf		
    }

	# proc for patching "nas_plugin.sprx" file
    proc patch_elf {elf} {
	
		###########			PATCHES FOR "NAS_PLUGIN.SPRX"   #############################
		##
		if { [string first "nas_plugin.sprx" $elf 0] != -1 } {		
		
			# if "--allow-pseudoretail-pkg" enabled, patch it
			if {$::patch_vsh::options(--allow-pseudoretail-pkg) } {
				# verified OFW ver. 3.55 - 4.46+
				# OFW 3.55 == 0x325C (0x316C)			
				# OFW 3.70 == 0x3264 (0x3174) 
				# OFW 4.00 == 0x3264 (0x3174)
				# OFW 4.46 == 0x3264 (0x3174)
				log "Patching [file tail $elf] to allow pseudo-retail pkg installs"         
				set search  "\x7C\x60\x1B\x78\xF8\x1F\x01\x80\xE8\x7F\x01\x80"
				set replace "\x38\x00\x00\x00"
				set offset 0
			 
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"   
			}			
			# if "--allow-retail-pkg-dex" enabled, patch it
			if {$::patch_vsh::options(--allow-retail-pkg-dex) } {
				# verified OFW ver. 3.55 - 4.46+
				# OFW 3.55 == 0x371E4 (0x370F4)			
				# OFW 3.70 == 0x3BDB4 (0x3BCC4)  
				# OFW 4.46 == 0x2E988 (0x2E898)
				# OFW 4.46 == 0x (0x)
				log "Patching [file tail $elf] to allow retail pkg installs on dex"         
				set search  "\x55\x60\x06\x3E\x2F\x80\x00\x00\x41\x9E\x01\xB0\x3B\xA1\x00\x80"
				set replace "\x60\x00\x00\x00"
				set offset 8
			 
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"        
			}			
			# if "--allow-debug-pkg" enabled, patch it
			if {$::patch_vsh::options(--allow-debug-pkg) } {
				# verified OFW ver. 3.55 - 4.46+
				# OFW 3.55 == 0x3734C (0x3725C)			
				# OFW 3.70 == 0x3BF1C (0x3BE2C)
				# OFW 4.30 == 0x2E930 (0x2E840)
				# OFW 4.46 == 0x2EAF0 (0x2EA00)
				log "Patching [file tail $elf] to allow debug pkg installs"         				
				set search  "\x2F\x89\x00\x00\x41\x9E\x00\x4C\x38\x00\x00\x00\x81\x22"
				set replace "\x60\x00\x00\x00"
				set offset 4
			 
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"        
			}			
		} 
		##
		####           END OF PATCHES FOR "NAS_PLUGIN.SPRX"  ########################
		
		
		##########		PATCHES FOR "VSH.SELF"   		#############################
		##
		if { [string first "vsh.self" $elf 0] != -1 } {

			# patch VSH.self for ROGERO patches
			# there are TWO of these patches, easier to
			# just use the "MULTI" patch to hit them both in one shot
			if {$::patch_vsh::options(--patch-rogero-vsh-patches)} {			
				# verified OFW ver. 3.60 - 4.50+
				# OFW 3.60 == 0x (0x)
				# OFW 4.00 == 0x17E2EC,0x17FF18 (0x18E2EC,0x18FF18)  
				# OFW 4.46 == 0x18406C,0x185CA4 (0x19406C,0x195CA4)
				# OFW 4.50 == 0x184274,0x185EAC (0x194274,0x195EAC)
				log "Patching VSH.self with Rogero patch 1&2/4"
				set ::FLAG_PATCH_FILE_MULTI 1				
				
				set search  "\x39\x29\x00\x04\x7C\x00\x48\x28"
				set replace "\x38\x00\x00\x01"
				set offset 4         				
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"      
				
				log "Patching VSH.self with (downgrader patch) Rogero patch 3/4"	
				# verified OFW ver. 3.60 - 4.50+
				# OFW 3.60 == 0x (0x)
				# OFW 4.00 == 0x2320A8 (0x2420A8)  
				# OFW 4.46 == 0x23CFC0 (0x24CFC0)
				# OFW 4.50 == 0x23E718 (0x24E718)				
				set search    "\x6C\x60\x80\x01\x2F\x80\x00\x06\x40\x9E\x02\xD0\x48\x00\x02\xB8"
				append search "\x38\x61\x02\x90\x48\x00"
				set replace   "\x60\x00\x00\x00"
				set offset 20   				
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"														
				
				log "Patching VSH.self with Rogero patch 4/4"	
				# verified OFW ver. 3.60 - 4.50+
				# OFW 3.60 == 0x (0x)
				# OFW 3.70 == 0x (0x)  
				# OFW 4.00 == 0x697A30 (0x6B7A30)  
				# OFW 4.46 == 0x6AA330 (0x6BA330)
				# OFW 4.50 == 0x6A9CB0 (0x6B9D0D)	
				set search     "\x61\x64\x5F\x72\x65\x63\x65\x69\x76\x65\x5F\x65\x76\x65\x6E\x74"
				append search  "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
				append search  "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
				append search  "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
				append search  "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
				append search  "\x00\x00\x00\x24\x13\xBC\xC5\xF6\x00\x33\x00\x00\x00"
				set replace    "\x34"
				set offset 93    				
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"											
			}			
			# if "--allow-unsigned-app" enabled, patch it
			if {$::patch_vsh::options(--allow-unsigned-app)} {
				# verified OFW ver. 3.55 - 4.50+
				# OFW 3.55 == 0x5FFEE8 (0x60FEE8)			
				# OFW 3.70 == 0x61A3C4 (0x62A3C4)
				# OFW 4.00 == 0x5DB8B8 (0x5FB8B8)  				
				# OFW 4.46 == 0x5EA584 (0x5FA584)
				# OFW 4.50 == 0x5E98F0 (0x5F98F0)
				log "Patching [file tail $elf] to allow running of unsigned applications 1/2"         
				set search  "\xF8\x21\xFF\x81\x7C\x08\x02\xA6\x38\x61\x00\x70\xF8\x01\x00\x90\x4B\xFF\xFF\xE1\x38\x00\x00\x00"
				set replace "\x38\x60\x00\x01\x4E\x80\x00\x20"
				set offset 0
			 
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"        
			 
				# verified OFW ver. 3.55 - 4.50+
				# OFW 3.55 == 0x30A7C0 (0x31A7C0)			
				# OFW 3.70 == 0x31B55C (0x32B55C) 
				# OFW 4.00 == 0x2376B8 (0x2476B8) 
				# OFW 4.46 == 0x241C2C (0x251C2C)
				# OFW 4.50 == 0x243388 (0x253388)
				log "Patching [file tail $elf] to allow running of unsigned applications 2/2"
				set search  "\xA0\x7F\x00\x04\x39\x60\x00\x01\x38\x03\xFF\x7F\x2B\xA0\x00\x01\x40\x9D\x00\x08\x39\x60\x00\x00"
				set replace "\x60\x00\x00\x00"
				set offset 20
			 
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"        
			}
			# if "--patch-vsh-react-psn-v2-4x" enabled, patch it
			if {$::patch_vsh::options(--patch-vsh-react-psn-v2-4x)} {
				# verified OFW ver. 3.55 - 4.50+
				# OFW 3.55 == 0x30B1D4 (0x31B1D4)			
				# OFW 3.70 == 0x31BF70 (0x250970)				
				# OFW 4.30 == 0x240974 (0x250974)
				# OFW 4.46 == 0x2425EC (0x2525EC)
				# OFW 4.50 == 0x243D48 (0x253D48)
				log "Patching [file tail $elf] to allow unsigned act.dat & .rif files"          
			   #set search    "\x4B\xDC\x03\xA9" --- old value ---
			    set search    "\x4E\x80\x00\x20\x7C\x80\x23\x78\x78\x63\x00\x20\x2F\x80\x00\x00"
				append search "\x78\x84\x00\x20\x41\x9E\x00\x08\x4B\xFF\xFF"
				set replace   "\x38\x60\x00\x00"
				set offset 92
			 
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"        
			}
			# if "--patch-vsh-no-delete-actdat" enabled, patch it
			if {$::patch_vsh::options(--patch-vsh-no-delete-actdat)} {
				# verified OFW ver. 3.55 - 4.50+
				# OFW 3.55 == 0x30AC64 (0x31AC64)			
				# OFW 3.70 == 0x31BA00 (0x32BA00)  
				# OFW 4.30 == 0x240400 (0x250400)
				# OFW 4.46 == 0x24207C (0x25207C)
				# OFW 4.50 == 0x2437D8 (0x2537D8)
				log "Patching [file tail $elf] to disable deleting of unsigned act.dat & .rif files"
			   #set search    "\x48\x3D\x55\x6D"   ---- old value ----
			    set search    "\x7C\x08\x03\xA6\xEB\x61\x00\xA8\xEB\x81\x00\xB0\xEB\xA1\x00\xB8"
				append search "\xEB\xC1\x00\xC0\xEB\xE1\x00\xC8\x38\x21\x00\xD0\x4E\x80\x00\x20"
				append search "\xF8\x21\xFF\x91\x7C\x08\x02\xA6\xF8\x01\x00\x80\x48"
				set replace   "\x38\x60\x00\x00"
				set offset 44
			 
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]" 				
			}									
		}
		#
		###########   END OF PATCHES TO "NAS_PLUGIN.SPRX" ###################################################
    }

    proc get_fw_release {filename} {
        set results [grep "^release:" $filename]
        set release [string trim [regsub "^release:" $results {}] ":"]
        return [string trim $release]
    }

    proc get_fw_build {filename} {
        set results [grep "^build:" $filename]
        set build [string trim [regsub "^build:" $results {}] ":"]
        return [string trim $build]
    }

    proc get_fw_target {filename} {
        set results [grep "^target:" $filename]
        set target [regsub "^target:" $results {}]
        return [string trim $target]
    }

    proc get_fw_security {filename} {
        set results [grep "^security:" $filename]
        set security [string trim [regsub "^security:" $results {}] ":"]
        return [string trim $security]
    }

    proc get_fw_system {filename} {
        set results [grep "^system:" $filename]
        set system [string trim [regsub "^system:" $results {}] ":"]
        return [string trim $system]
    }

    proc get_fw_x3 {filename} {
        set results [grep "^x3:" $filename]
        set x3 [string trim [regsub "^x3:" $results {}] ":"]
        return [string trim $x3]
    }

    proc get_fw_paf {filename} {
        set results [grep "^paf:" $filename]
        set paf [string trim [regsub "^paf:" $results {}] ":"]
        return [string trim $paf]
    }

    proc get_fw_vsh {filename} {
        set results [grep "^vsh:" $filename]
        set vsh [string trim [regsub "^vsh:" $results {}] ":"]
        return [string trim $vsh]
    }

    proc get_fw_sys_jp {filename} {
        set results [grep "^sys_jp:" $filename]
        set sys_jp [string trim [regsub "^sys_jp:" $results {}] ":"]
        return [string trim $sys_jp]
    }

    proc get_fw_ps1emu {filename} {
        set results [grep "^ps1emu:" $filename]
        set ps1emu [string trim [regsub "^ps1emu:" $results {}] ":"]
        return [string trim $ps1emu]
    }

    proc get_fw_ps1netemu {filename} {
        set results [grep "^ps1netemu:" $filename]
        set ps1netemu [string trim [regsub "^ps1netemu:" $results {}] ":"]
        return [string trim $ps1netemu]
    }

    proc get_fw_ps1newemu {filename} {
        set results [grep "^ps1newemu:" $filename]
        set ps1newemu [string trim [regsub "^ps1newemu:" $results {}] ":"]
        return [string trim $ps1newemu]
    }

    proc get_fw_ps2emu {filename} {
        set results [grep "^ps2emu:" $filename]
        set ps2emu [string trim [regsub "^ps2emu:" $results {}] ":"]
        return [string trim $ps2emu]
    }

    proc get_fw_ps2gxemu {filename} {
        set results [grep "^ps2gxemu:" $filename]
        set ps2gxemu [string trim [regsub "^ps2gxemu:" $results {}] ":"]
        return [string trim $ps2gxemu]
    }

    proc get_fw_ps2softemu {filename} {
        set results [grep "^ps2softemu:" $filename]
        set ps2softemu [string trim [regsub "^ps2softemu:" $results {}] ":"]
        return [string trim $ps2softemu]
    }

    proc get_fw_pspemu {filename} {
        set results [grep "^pspemu:" $filename]
        set pspemu [string trim [regsub "^pspemu:" $results {}] ":"]
        return [string trim $pspemu]
    }

    proc get_fw_emerald {filename} {
        set results [grep "^emerald:" $filename]
        set emerald [string trim [regsub "^emerald:" $results {}] ":"]
        return [string trim $emerald]
    }

    proc get_fw_bdp {filename} {
        set results [grep "^bdp:" $filename]
        set bdp [string trim [regsub "^bdp:" $results {}] ":"]
        return [string trim $bdp]
    }

    proc get_fw_auth {filename} {
        set results [grep "^auth:" $filename]
        set auth [string trim [regsub "^auth:" $results {}] ":"]
        return [string trim $auth]
    }	
	
    # func to copy specific file over
    proc copy_customized_file { dst src } {
        if {[file exists $src] == 0} {
            die "$src does not exist"
        } else {
            if {[file exists $dst] == 0} {
                die "$dst does not exist"
            } else {
                log "Replacing default firmware file [file tail $dst] with [file tail $src]"
                copy_file -force $src $dst
            }
        }
    }
	# proc for "swapping" debug versus retail
	# 'Cinavia' files
	proc swappCinavia {} {
        set copyCinavia [file copy -force ${::DCINAVIA} ${::RCINAVIA}]
	    set catch [catch $copyCinavia]
	    set batch [::modify_devflash_file ${::RCINAVIA} $catch]
        if {$batch == 0} {
	        log "Successfull swapped sprx and disabled cinavia protection"
	    } else {
	        log "Error!! Something went very wrong"
	    }
    }
}
#
# ############  END OF PATCH_VSH.TCL ######################################