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
# Description: PATCH CORE-OS

# Option --patch-lv0-nodescramble-lv1ldr: [3.xx/4.xx]  LV0: --> Patch to disable LV0 descrambling of LV1LDR (3.xx/4.xx)
# Option --patch-lv0-ldrs-ecdsa-checks: [3.xx/4.xx]  LV0: --> Patch to disable ECDSA checks in ALL LV0-loaders (3.xx/4.xx)
# Option --patch-lv1-peek-poke: [3.xx/4.xx]  LV1: --> Patch for peek/poke support (unused lv1 calls 182 and 183) (3.xx/4.xx)
# Option --patch-lv1-remove-lv2-protection: [3.xx/4.xx]  LV1: --> Patch to remove LV2 protection (3.xx/4.xx)
# Option --patch-lv2-peek-poke-4x: [3.xx/4.xx]  LV2: --> Patch LV2 to add Peek&Poke system calls (3.xx/4.xx)
# Option --patch-lv2-lv1-peek-poke-4x: [3.xx/4.xx]  LV2: --> Patch LV2 to add LV1 Peek&Poke system calls (LV1 peek/poke patch necessary) (3.xx/4.xx)
# Option --patch-lv2-npdrm-ecdsa-check: [3.xx/4.xx]  LV2: --> Patch LV2 to disable NPDRM ECDSA check  (Jailbait) (3.xx/4.xx)
# Option --patch-lv2-payload-hermes-4x: [3.xx/4.xx]  LV2: --> Patch LV2 to implement hermes payload SC8 /app_home/ redirection & embedded app mount (3.xx/4.xx)
# Option --patch-lv2-SC36-4x: [3.xx/4.xx]  LV2: --> Patch LV2 to implement SysCall36 (3.xx/4.xx)
# Option --patch-spkg-ecdsa-check: [3.xx/4.xx]  ALT: --> Patch FW PKG Verifier to disable ECDSA check for spkg files (spu_pkg_rvk_verifier.self) (3.xx/4.xx)
# Option --patch-RSOD-bypass: [3.xx/4.xx]  ALT: --> Patch to bypass RSOD errors (basic_plugins.sprx) (3.xx/4.xx)
# Option --patch-lv2-peek-poke-355: [3.55]  LV2: --> Patch LV2 to add Peek&Poke system calls 3.55
# Option --patch-lv2-lv1-peek-poke-355: [3.55]  LV2: --> Patch LV2 to add LV1 Peek&Poke system calls 3.55 (LV1 peek/poke patch necessary)
# Option --patch-lv2-lv1-call-355: [3.55]  LV2: --> Patch LV2 to add LV1 Call system call 3.55
# Option --patch-lv2-payload-hermes-355: [3.55]  LV2: --> Patch LV2 to implement hermes payload with SC8 and /app_home/ redirection 3.55
# Option --patch-lv2-SC36-355: [3.55]  LV2: --> Patch LV2 to implement SysCall36 3.55

# Type --patch-lv0-nodescramble-lv1ldr: boolean
# Type --patch-lv0-ldrs-ecdsa-checks: boolean
# Type --patch-lv2-peek-poke-4x: boolean
# Type --patch-lv2-lv1-peek-poke-4x: boolean
# Type --patch-lv2-npdrm-ecdsa-check: boolean
# Type --patch-lv2-payload-hermes-4x: boolean
# Type --patch-lv2-SC36-4x: boolean
# Type --patch-spkg-ecdsa-check: boolean
# Type --patch-RSOD-bypass: boolean
# Type --patch-lv1-peek-poke: boolean
# Type --patch-lv1-remove-lv2-protection: boolean
# Type --patch-lv2-peek-poke-355: boolean
# Type --patch-lv2-lv1-peek-poke-355: boolean
# Type --patch-lv2-lv1-call-355: boolean
# Type --patch-lv2-payload-hermes-355: boolean
# Type --patch-lv2-SC36-355: boolean

namespace eval ::patch_cos {
	
	# just create empty globals for the binary search/replace/offset strings
	set ::patch_cos::search ""
	set ::patch_cos::replace ""
	set ::patch_cos::offset 0
	
    array set ::patch_cos::options {	
		--patch-lv0-nodescramble-lv1ldr false
		--patch-lv0-ldrs-ecdsa-checks true
		--patch-lv1-peek-poke true
		--patch-lv1-remove-lv2-protection true
		--patch-lv2-peek-poke-4x true
        --patch-lv2-lv1-peek-poke-4x true
        --patch-lv2-npdrm-ecdsa-check true
        --patch-lv2-payload-hermes-4x true
		--patch-lv2-SC36-4x true
		--patch-spkg-ecdsa-check true
		--patch-RSOD-bypass true        
        --patch-lv2-peek-poke-355 false
        --patch-lv2-lv1-peek-poke-355 false
        --patch-lv2-lv1-call-355 false
        --patch-lv2-payload-hermes-355 false
        --patch-lv2-SC36-355 false
    }

    proc main { } {
	
		set embd [file join dev_flash vsh etc layout_factor_table_272.txt]		
		
		## ---------------------- SET 'EXTERNALS' HERE ------------------
		## first see if "customize_firmware" task is even selected, if so,
		## set the "embed" param to the embedded app		
		set hermes_enabled false
		set embedded_app ""
		set installpkg_enabled false
		set addpkgmgr_enabled false
		set addhbseg_enabled false
		set addemuseg_enabled false
		set patchpkgfiles_enabled false
		set patchapphome_enabled false		
		
		if {[info exists ::patch_cos::options(--patch-lv2-payload-hermes-4x)]} {
			set hermes_enabled $::patch_cos::options(--patch-lv2-payload-hermes-4x) }
		if {[info exists ::customize_firmware::options(--customize-embedded-app)]} {
			set embedded_app ${::customize_firmware::options(--customize-embedded-app)} }				
		if {[info exists ::patch_xmb::options(--add-install-pkg)]} {
			set installpkg_enabled $::patch_xmb::options(--add-install-pkg) }	
		if {[info exists ::patch_xmb::options(--add-pkg-mgr)]} {
			set addpkgmgr_enabled $::patch_xmb::options(--add-pkg-mgr) }
		if {[info exists ::patch_xmb::options(--add-hb-seg)]} {
			set addhbseg_enabled $::patch_xmb::options(--add-hb-seg) }
		if {[info exists ::patch_xmb::options(--add-emu-seg)]} {
			set addemuseg_enabled $::patch_xmb::options(--add-emu-seg) }
		if {[info exists ::patch_xmb::options(--patch-package-files)]} {
			set patchpkgfiles_enabled $::patch_xmb::options(--patch-package-files) }
		if {[info exists ::patch_xmb::options(--patch-app-home)]} {
			set patchapphome_enabled $::patch_xmb::options(--patch-app-home) }			
		##  ----------------     END EXTERNALS -------------------------		
        
        
		# begin by calling the main function to go through
		# all the patches
		::patch_cos::Do_CoreOS_Patches $::CUSTOM_COSUNPKG_DIR        
		
		# if no options were selected to add the "*Install Pkg Files" elsewhere, 
		# install this package into dev_flash		
		if { $hermes_enabled } {
			if { ([expr {"$embedded_app" eq ""}]) && (!$installpkg_enabled) && (!$addpkgmgr_enabled) && (!$addhbseg_enabled)
			&& (!$addemuseg_enabled) && (!$patchpkgfiles_enabled) && (!$patchapphome_enabled) } {
				log "Copy standalone '*Install Package Files' app into dev_flash"
				#::modify_devflash_file $embd ::copy_ps3_game ${::CUSTOM_PS3_GAME}
				#::modify_devflash_file $embd ::patch_cos::install_pkg
				tk_messageBox -default ok -message "WARNING: Install PKG was not selected!" -icon warning
			}		
		}
    }		
	
	# --------------------------Do_CoreOS_Patches-------------------------------------------
	# this proc is for applying any patches to CORE_OS files, it is
	# expected that the "::patch_coreos_files" routine was already
	# called to extract all CORE_OS files, and return the "path"
	# of the unpackaged files
    proc Do_CoreOS_Patches {path} {
	
		# call the function to do any LV0 selected patches
		::patch_cos::Do_LV0_Patches $path
		
		# call the function to do any LV1 selected patches				
		set self "lv1.self"
		set file [file join $path $self]		
		::modify_self_file $file ::patch_cos::Do_LV1_Patches		
		
		# call the function to do any LV2 selected patches
		set self "lv2_kernel.self"
		set file [file join $path $self]		
		::modify_self_file $file ::patch_cos::Do_LV2_Patches
	
		# call the function to do any other OS-file selected patches
		::patch_cos::Do_Misc_OS_Patches $path
					
	}
	### ------------------------------------- END:    Do_CoreOS_Patches{} --------------------------------------------- ###	
	

	# --------------------------  BEGIN:  Do_LV0_Patches   ------------------------------------------------------------ ### 
	#
	# This proc is for applying any patches to LV0
	#
	#
	proc Do_LV0_Patches {path} {
		
		log "Applying LV0 patches...."
		
		#if "--patch-lv0-ldrs-ecdsa-checks" enabled, patch it
		# enable the "FLAG_PATCH_FILE_MULTI" true, so we patch
		# ALL occurances of ECDSA checks in each ldr
		if {$::patch_cos::options(--patch-lv0-ldrs-ecdsa-checks)} {		
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55 == 0x81A8 (0x1ACA8)			
			# OFW 3.70 == 0x6E48 (0x19948)  
			# OFW 4.00 == 0x6E50 (0x19950) 
			# OFW 4.46 == 0x6EC4 (0x199C4)
			log "Patching 4.xx LV1LDR ECDSA CHECKS......"            
			set self "lv1ldr.self"
			set file [file join $path $self]			
			set ::FLAG_PATCH_FILE_MULTI 1
			
            set ::patch_cos::search  "\x0C\x00\x01\x85\x34\x01\x40\x80\x1C\x10\x00\x81\x3F\xE0\x02\x83"
            set ::patch_cos::replace "\x40\x80\x00\x03"
            set ::patch_cos::offset 12		
			# base function to decrypt the "self" to "elf" for patching
			::modify_self_file $file ::patch_cos::patch_elf

			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55 == 0x43C0 (0x16EC0)			
			# OFW 3.70 == 0x4458 (0x16F58)  
			# OFW 4.00 == 0x47F0 (0x172F0) 
			# OFW 4.46 == 0x47E8 (0x172E8)
			log "Patching 4.xx LV2LDR ECDSA CHECKS......"
			set self "lv2ldr.self"
			set file [file join $path $self]			
			set ::FLAG_PATCH_FILE_MULTI 1
            
            set ::patch_cos::search  "\x0C\x00\x01\x85\x34\x01\x40\x80\x1C\x10\x00\x81\x3F\xE0\x02\x83"
            set ::patch_cos::replace "\x40\x80\x00\x03"
            set ::patch_cos::offset 12		
			# base function to decrypt the "self" to "elf" for patching
			::modify_self_file $file ::patch_cos::patch_elf
		
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55 == 0x49F0 (0x2A170)			
			# OFW 3.70 == 0x2750 (0x27ED0)  
			# OFW 4.00 == 0x2750 (0x27ED0) 
			# OFW 4.46 == 0x2898 (0x28018)
			log "Patching 4.xx ISOLDR ECDSA CHECKS......"       
			set self "isoldr.self"
			set file [file join $path $self]
			set ::FLAG_PATCH_FILE_MULTI 1			
            
            set ::patch_cos::search  "\x0C\x00\x01\x85\x34\x01\x40\x80\x1C\x10\x00\x81\x3F\xE0\x02\x83"
            set ::patch_cos::replace "\x40\x80\x00\x03"
            set ::patch_cos::offset 12		
			# base function to decrypt the "self" to "elf" for patching
			::modify_self_file $file ::patch_cos::patch_elf
			
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55 == 0x9F60 (0x1CA60)			
			# OFW 3.70 == 0x56B0 (0x181B0)  
			# OFW 4.00 == 0x5778 (0x18278) 
			# OFW 4.46 == 0x5740 (0x18240)
			log "Patching 4.xx APPLDR ECDSA CHECKS......"
			set self "appldr.self"
			set file [file join $path $self]			
			set ::FLAG_PATCH_FILE_MULTI 1
			
            set ::patch_cos::search  "\x0C\x00\x01\x85\x34\x01\x40\x80\x1C\x10\x00\x81\x3F\xE0\x02\x83"
            set ::patch_cos::replace "\x40\x80\x00\x03"
            set ::patch_cos::offset 12		
			# base function to decrypt the "self" to "elf" for patching
			::modify_self_file $file ::patch_cos::patch_elf            						
		}					
		# if "lv0-LV1LDR descramble" patch is enabled, patch in "lv0.elf"
		# ** LV0 IS ONLY SCRAMBLED IN OFW VERSIONS 3.65+ **
        if {$::patch_cos::options(--patch-lv0-nodescramble-lv1ldr)} {
			# verified OFW ver. 3.56 - 4.46+
			# OFW 3.65 == 0x279A8 (0x80079A8)			
			# OFW 3.70 == 0x27A58 (0x8007A58)  
			# OFW 4.00 == 0x27A58 (0x8007A58) 
			# OFW 4.46 == 0x27AD0 (0x8007AD0)
			if {${::NEWMFW_VER} >= "3.65"} {
			
				log "Patching Lv0 to disable LV1LDR descramble"
				set self "lv0"
				set file [file join $path $self]			
				set ::FLAG_NO_LV1LDR_CRYPT 1			
			
				set ::patch_cos::search    "\x64\x84\xB0\x00\x48\x00\x00\xFC\xE8\x61\x00\x70\x80\x81\x00\x7C"
				append ::patch_cos::search "\x48\x00"
				set ::patch_cos::replace   "\x60\x00\x00\x00"
				set ::patch_cos::offset 16						
				# base function to decrypt the "self" to "elf" for patching
				::modify_self_file $file ::patch_cos::patch_elf	
				
			} else {	
				log "SKIPPING LV0-DESCRAMBLE PATCH, LV0 is NOT scrambled in FW below 3.65...."				
			}
        }			
		
		log "Done LV0 patches...."
	}
	### ------------------------------------- END:    Do_LV0_Patches{} --------------------------------------------- ### 
	
	
	
	# --------------------------  BEGIN:  Do_LV1_Patches   --------------------------------------------------------- ### 
	#
	# This proc is for applying any patches to LV1
	#
	#	
	proc Do_LV1_Patches {elf} {		
		
		log "Applying LV1 patches...."		
		
		# if "lv1-peek-poke" enabled, patch it
		if {$::patch_cos::options(--patch-lv1-peek-poke)} {
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55: 0x1225E8 (0x3025E8)
			# OFW 3.60: 0x123DB4 (0x303DB4			
			# OFW 4.30: 0x1299C0 (0x3099C0)
			# OFW 4.46: 0x1299C0 (0x3099C0)		
            log "Patching LV1 hypervisor - peek/poke support(1189356) part 1/2"         
            set search    "\x38\x00\x00\x00\x64\x00\xFF\xFF\x60\x00\xFF\xEC\xF8\x03\x00\xC0"
	        append search "\x4E\x80\x00\x20\x38\x00\x00\x00"
            set replace   "\xE8\x83\x00\x18\xE8\x84\x00\x00\xF8\x83\x00\xC8"         
			set offset 4				
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"                
			
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55: 0x1225F8 (0x3025F8)
			# OFW 3.60: 0x123DC4 (0x303DC4			
			# OFW 4.30: 0x1299D0 (0x3099D0)
			# OFW 4.46: 0x1299D0 (0x3099D0)	
			log "Patching LV1 hypervisor - peek/poke support(1189356) part 2/2" 
            set search    "\x4E\x80\x00\x20\x38\x00\x00\x00\x64\x00\xFF\xFF\x60\x00\xFF\xEC"
	        append search "\xF8\x03\x00\xC0\x4E\x80\x00\x20\xE9\x22"
            set replace   "\xE8\xA3\x00\x20\xE8\x83\x00\x18\xF8\xA4\x00\x00"         
			set offset 8				
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"                    
        }
		#if "lv1-remove-lv2-protection" enabled, patch it
		if {$::patch_cos::options(--patch-lv1-remove-lv2-protection)} {
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55: 0x21D0B8 (0x44D0B8)
			# OFW 3.60: 0x21D0D4 (0x44D0D4)			
			# OFW 4.30: 0x23A998 (0x44A998)
			# OFW 4.46: 0x23A998 (0x44A998)	
            log "Patching LV1 hypervisior to remove LV2 protection"            
            set search  "\x2F\x83\x00\x00\x38\x60\x00\x01\x41\x9E\x00\x20\xE8\x62"
            set replace "\x48\x00"
            set offset 8				
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"                         
        }
		log "Done LV1 patches...."	
	}
	### ------------------------------------- END:    Do_LV1_Patches{} --------------------------------------------- ###   
	
	
	
	# --------------------------  BEGIN:  Do_LV2_Patches   --------------------------------------------------------- ### 
	#
	# This proc is for applying any patches to the "LV2" self file
	#
	#
	proc Do_LV2_Patches {elf} {
	
		log "Applying LV2 patches...."									
		
		#### ---------------------------------------------------- BEGIN: 4.XX PATCHES AREA ----------------------------------------------- ####
		####
		#				
		##  set the filename here, and prepend the "path"		
		
		set pop_warning 0	
		# check for any erroneous settings, and throw up message boxes if so
		if {$::patch_cos::options(--patch-lv2-peek-poke-355) || $::patch_cos::options(--patch-lv2-peek-poke-4x) } {
			if {![info exists ::patch_lv1::options(--patch-lv1-mmap)]} {
				if {!$::patch_cos::options(--patch-lv1-remove-lv2-protection)} {					
					set pop_warning 1
				}
			} elseif {!$::patch_lv1::options(--patch-lv1-mmap)} {
				if {!$::patch_cos::options(--patch-lv1-remove-lv2-protection)} {					
					set pop_warning 1
				}
            }
			if {$pop_warning == 1} {
					log "WARNING: You enabled Peek&Poke without enabling LV1 mmap or LV2 protection patching." 1
					log "WARNING: Patching LV1 mmap or deactivated LV2 protection is necessary for Poke to function." 1
					tk_messageBox -default ok -message "WARNING: You enabled Peek&Poke without enabling LV1 mmap or LV2 protection patching, \
					Patching LV1 mmap or deactivated LV2 protection is necessary for Poke to function." -icon warning			
			}
		}
		# if "--patch-lv2-peek-poke-4x" enabled, do patch
		if {$::patch_cos::options(--patch-lv2-peek-poke-4x)} {
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55: 0x65F64 (0x55F64)
			# OFW 3.60: 0x6692C (0x5692C)			
			# OFW 4.30: 0x67234 (0x57234)
			# OFW 4.46: 0x66184 (0x56184)	
			log "Patching LV2 peek&poke for 4.xx CFW - part 1/2"				 
			set search   "\x3F\xE0\x80\x01\x63\xFF\x00\x3E\x4B\xFF\xFF\x0C\x83\xBC\x00\x78"
			set replace  "\x3B\xE0\x00\x00"
			set offset 4
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"    		 					
			
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55: 0x65E98 (0x55E98)
			# OFW 3.60: 0x66860 (0x56860)			
			# OFW 4.30: 0x67168 (0x57168)
			# OFW 4.46: 0x660B8 (0x560B8)	
			log "Patching LV2 peek&poke for 4.xx CFW - part 2/2"	
			set search    "\x3F\xE0\x80\x01\x2F\x84\x00\x02\x63\xFF\x00\x3D\x41\x9E\xFF\xD4"
			append search "\x38\xDE\x00\x07"
			set replace   "\x60\x00\x00\x00"
			set offset 12
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"    			 
		}
		# if "--patch-lv2-lv1-peek-poke-4x" enabled, do patch
		if {$::patch_cos::options(--patch-lv2-lv1-peek-poke-4x)} {
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55: 0x10F00 (0xF00) ** PATCH @0x1170C **
			# OFW 3.60: 0x10F00 (0xF00) ** PATCH @0x1170C **		
			# OFW 4.30: 0x10F00 (0xF00) ** PATCH @0x1170C **
			# OFW 4.46: 0x10F00 (0xF00)	** PATCH @0x1170C **
			log "Patching LV1 peek&poke call permission for LV2 into LV2 - part 1/2"
			# 7C 71 43 A6 7C 92 43 A6 48 00 00 00 00 00 00 00
			# 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
			# 7C 71 43 A6 7C 92 43 A6 7C B3 43 A6 7C 7A 02 A6......
			set search     "\x7C\x71\x43\xA6\x7C\x92\x43\xA6\x48\x00\x00\x00\x00\x00\x00\x00"
			append search  "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
			append search  "\x7C\x71\x43\xA6\x7C\x92\x43\xA6\x7C\xB3\x43\xA6\x7C\x7A\x02\xA6"
			set replace    "\xE8\x63\x00\x00\x4E\x80\x00\x20\xF8\x83\x00\x00\x4E\x80\x00\x20"
			append replace "\x7C\x08\x02\xA6\xF8\x01\x00\x10\x39\x60\x00\xB6\x44\x00\x00\x22"
			append replace "\x7C\x83\x23\x78\xE8\x01\x00\x10\x7C\x08\x03\xA6\x4E\x80\x00\x20"
			append replace "\x7C\x08\x02\xA6\xF8\x01\x00\x10\x39\x60\x00\xB7\x44\x00\x00\x22"
			append replace "\x38\x60\x00\x00\xE8\x01\x00\x10\x7C\x08\x03\xA6\x4E\x80\x00\x20"
			append replace "\x7C\x08\x02\xA6\xF8\x01\x00\x10\x7D\x4B\x53\x78\x44\x00\x00\x22"
			append replace "\xE8\x01\x00\x10\x7C\x08\x03\xA6\x4E\x80\x00\x20\x80\x00\x00\x00"
			append replace "\x00\x00\x17\x0C\x80\x00\x00\x00\x00\x00\x17\x14\x80\x00\x00\x00"
			append replace "\x00\x00\x17\x1C\x80\x00\x00\x00\x00\x00\x17\x3C\x80\x00\x00\x00"
			append replace "\x00\x00\x17\x5C"
			set offset 2060
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"    			 					
			
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55: 0x355DE5 (0x345DE5) ** PATCH @0x3565A0 **
			# OFW 3.60: 0x35D05D (0x34D05D) ** PATCH @0x35D818 **		
			# OFW 4.30: 0x36D425 (0x35D425) ** PATCH @0x36DC10 **
			# OFW 4.46: 0x36E0A5 (0x35E0A5)	** PATCH @0x36E890 **
			# OFW 4.50: 0x36E915 (0x35E915)	** PATCH @0x36F100 **
			log "Patching LV1 peek&poke call permission for LV2 into LV2 - part 2/2"
			# old patch, saving for reference, but not universal enough for all FWs
			# set search   "\x80\x00\x00\x00\x00\x2F\xEA\x40"
			
			# code pattern at start of 'vector table', same across all FWs
			# for >= 3.70 FW, offset is 0x7EB (2027)
			# for < 3.70 FW, offset is 0x7BB (1979)			
			set search     "\x83\x86\x5C\xCB\x37\x6F\x5D\x5C\x43\x93\xA4\xBA\x53\x35\x90\x03"			
			set replace    "\x80\x00\x00\x00\x00\x00\x17\x78\x80\x00\x00\x00\x00\x00\x17\x80"
			append replace "\x80\x00\x00\x00\x00\x00\x17\x88\x80\x00\x00\x00\x00\x00\x17\x90"
			append replace "\x80\x00\x00\x00\x00\x00\x17\x98"
			if {${::NEWMFW_VER} >= "3.70"} {
				set offset 2027
			} else {
				set offset 1979
			}
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"    			   
		}
		# if "-patch-lv2-npdrm-ecdsa-check" enabled, do patch
		if {$::patch_cos::options(--patch-lv2-npdrm-ecdsa-check)} {
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55: 0x8AEE8???? (0x)  ** unsure of this patch **
			# OFW 3.60: 0x69CAC (0x59CAC)
			# OFW 4.30: 0x6A6B8 (0x5A6B8)
			# OFW 4.46: 0x69608 (0x59608)
			
			## since patch is unsure for OFW <= 3.55, only patch if > 3.55
			if {${::NEWMFW_VER} > "3.55"} {
				log "Patching NPDRM ECDSA check disabled"				
				# saving old patch for reference
				#set search    "\x41\x9E\xFD\x68\x4B\xFF\xFD\x68\xE9\x22\x99\x90\x7C\x08\x02\xA6"
				set search     "\x3C\x60\x80\x01\x60\x63\x00\x17\x41\x9E\xFD\x68\x4B\xFF\xFD\x68"
				append search  "\xE9\x22"
				set replace    "\x38\x60\x00\x00\x4E\x80\x00\x20"
				set offset 16
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"  
				
			} else {
				log "NPDRM ECDSA Patch not supported for OFW <= 3.55!!"
				die "NPDRM ECDSA Patch not supported for OFW <= 3.55!!"
			}
		}
		# if "--patch-lv2-SC36-4x" enabled, do patch
		if {$::patch_cos::options(--patch-lv2-SC36-4x)} {
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55: 0x65F10 (0x55F10)
			# OFW 3.60: 0x668D8 (0x568D8)
			# OFW 4.30: 0x671E0 (0x571E0)
			# OFW 4.46: 0x66130 (0x56130)
			log "Patching LV2 with SysCall36 4.xx CFW part 1/3"			
			set search     "\x41\x9E\x00\xD8\x41\x9D\x00\xC0\x2F\x84\x00\x04\x40\x9C\x00\x48"			
			set replace    "\x60\x00\x00\x00\x2F\x84\x00\x04\x48\x00\x00\x98"
			set offset 4
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"    			
			
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55: 0x8AF60 (0x7AF60)
			# OFW 3.60: 0x6A194 (0x5A194)
			# OFW 4.30: 0x6ABA0 (0x5ABA0)
			# OFW 4.46: 0x69AF0 (0x59AF0)
			log "Patching LV2 with SysCall36 4.xx CFW part 2/3"	
			if {${::NEWMFW_VER} <= "3.55"} {
				# pattern for <= 3.55 OFW
				set search "\x54\x63\x06\x3E\x2F\x83\x00\x00\x41\x9E\x00\x20\xE8\x61"
			} else {
				# pattern for > 3.55 OFW
				set search "\x54\x63\x06\x3E\x2F\x83\x00\x00\x41\x9E\x00\x70\xE8\x61"
			}			
			set replace    "\x60\x00\x00\x00"
			set offset 8
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"    		 					

			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55: 0x8AF74 (0x7AF74)
			# OFW 3.60: 0x6A1A8 (0x5A1A8)
			# OFW 4.30: 0x6ABB4 (0x5ABB4)
			# OFW 4.46: 0x69B04 (0x59B04)
			log "Patching LV2 with SysCall36 4.xx CFW part 3/3"
			if {${::NEWMFW_VER} <= "3.55"} {
				# pattern for <= 3.55 OFW							
			   #set search "\x4B\xFF\xF3\x31\x54\x63\x06\x3E\x2F\x83\x00\x00\x41\x9E\x00\x70"	# OLD PATCH		
				set search "\x54\x63\x06\x3E\x2F\x83\x00\x00\x41\x9E\x00\x20\x80\x61\x00\x7C"
			} else {
				# pattern for > 3.55 OFW
				set search "\x54\x63\x06\x3E\x2F\x83\x00\x00\x41\x9E\x00\x70\x38\x61\x00\x70"
			}
			set replace    "\x60\x00\x00\x00"
			set offset 8
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"    			 
		}
		# if "--patch-lv2-payload-hermes-4x" enabled, then patch
		if {$::patch_cos::options(--patch-lv2-payload-hermes-4x)} {
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55: 0x2E8460 (0x2D8460)
			# OFW 3.60: 0x2EB940 (0x2DB940)
			# OFW 4.30: 0x2F9F98 (0x2E9F98)
			# OFW 4.46: 0x2FAA48 (0x2EAA48)
			log "Patching Hermes payload 4.xx into LV2"				
			set search     	"\x52\x52\x30\x20\x3A\x20\x30\x78"			
			set replace    	"\xF8\x21\xFF\x61\x7C\x08\x02\xA6\xFB\x81\x00\x80\xFB\xA1\x00\x88"
			append replace  "\xFB\xE1\x00\x98\xFB\x41\x00\x70\xFB\x61\x00\x78\xF8\x01\x00\xB0" 
			append replace  "\x7C\x9C\x23\x78\x7C\x7D\x1B\x78\x3B\xE0\x00\x01\x7B\xFF\xF8\x06"
			append replace  "\x67\xE4\x00\x2E\x60\x84\xAA\xBC\x38\xA0\x00\x02\x4B\xD6\x2C\x11"
			append replace  "\x28\x23\x00\x00\x40\x82\x00\x28\x67\xFF\x00\x2E\x63\xFF\xAA\xCC"
			append replace  "\xE8\x7F\x00\x00\x28\x23\x00\x00\x41\x82\x00\x14\xE8\x7F\x00\x08"
			append replace  "\x38\x9D\x00\x09\x4B\xD6\x2B\x95\xEB\xBF\x00\x00\x7F\xA3\xEB\x78"
			append replace  "\x4B\xFD\x9D\x1C\x2F\x61\x70\x70\x5F\x68\x6F\x6D\x65\x00\x00\x00"
			append replace  "\x00\x00\x00\x00\x80\x00\x00\x00\x00\x2E\xAA\xDC\x80\x00\x00\x00"
			append replace  "\x00\x2E\xAA\xEA\x2F\x64\x65\x76\x5F\x66\x6C\x61\x73\x68\x2F\x70"
			append replace  "\x6B\x67\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"	
			set offset 0
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"    				
		}		
		##
		#### ------------------------------------------------------  END:  4.XX PATCHES AREA ----------------------------------------------- ####		
		
		
		#### ----------------------------------------------------- BEGIN:  3.XX PATCHES AREA ----------------------------------------------- ####
		# if "lv2-peek-poke" enabled for LV2 3.55
		if {$::patch_cos::options(--patch-lv2-peek-poke-355)} {
		
			log "Patching LV2 to allow Peek and Poke support"										
			set search    "\xEB\xA1\x00\x88\x38\x60\x00\x00\xEB\xC1\x00\x90\xEB\xE1\x00\x98"
			append search "\x7C\x08\x03\xA6\x7C\x63\x07\xB4\x38\x21\x00\xA0\x4E\x80\x00\x20"
			append search "\x3C\x60\x80\x01\x60\x63\x00\x03\x4E\x80\x00\x20\x3C\x60\x80\x01"
			append search "\x60\x63\x00\x03\x4E\x80\x00\x20"
			set replace   "\xE8\x63\x00\x00\x60\x00\x00\x00\x4E\x80\x00\x20\xF8\x83\x00\x00\x60\x00\x00\x00"				 
			set offset 32
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"	
		}
		# if "patch-lv2-lv1-peek-poke" for LV2 3.55
		if {$::patch_cos::options(--patch-lv2-lv1-peek-poke-355)} {
		
			log "Patching LV2 to allow LV1 Peek and Poke support (3.55)"					
			set search     "\x7C\x71\x43\xA6\x7C\x92\x43\xA6\x7C\xB3\x43\xA6\x48"
			set replace    "\x7C\x08\x02\xA6\xF8\x01\x00\x10\x39\x60\x00\xB6\x44\x00\x00\x22"
			append replace "\x7C\x83\x23\x78\xE8\x01\x00\x10\x7C\x08\x03\xA6\x4E\x80\x00\x20"
			append replace "\x7C\x08\x02\xA6\xF8\x01\x00\x10\x39\x60\x00\xB7\x44\x00\x00\x22"
			append replace "\x38\x60\x00\x00\xE8\x01\x00\x10\x7C\x08\x03\xA6\x4E\x80\x00\x20"				 
			set offset 5644
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"					
		 
			set search     "\xEB\xA1\x00\x88\x38\x60\x00\x00\xEB\xC1\x00\x90\xEB\xE1\x00\x98"
			append search  "\x7C\x08\x03\xA6\x7C\x63\x07\xB4\x38\x21\x00\xA0\x4E\x80\x00\x20"
			set replace    "\x4B\xFE\x83\xB8\x60\x00\x00\x00\x60\x00\x00\x00\x4B\xFE\x83\xCC"
			append replace "\x60\x00\x00\x00\x60\x00\x00\x00"
			set offset 56
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"				   
		}
		# if "--patch-lv2-lv1-call-355" enabled, do patch
		if {$::patch_cos::options(--patch-lv2-lv1-call-355)} {
		
			log "Patching LV2 to allow LV1 Call support (3.55)"				 
			set search     "\x7C\x71\x43\xA6\x7C\x92\x43\xA6\x7C\xB3\x43\xA6\x48"
			set replace    "\x7C\x08\x02\xA6\xF8\x01\x00\x10\x7D\x4B\x53\x78\x44\x00\x00\x22"
			append replace "\xE8\x01\x00\x10\x7C\x08\x03\xA6\x4E\x80\x00\x20"				  
			set offset 5708
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"							
		 
			set search     "\xEB\xA1\x00\x88\x38\x60\x00\x00\xEB\xC1\x00\x90\xEB\xE1\x00\x98"
			append search  "\x7C\x08\x03\xA6\x7C\x63\x07\xB4\x38\x21\x00\xA0\x4E\x80\x00\x20"
			set replace    "\x4B\xFE\x83\xE0\x60\x00\x00\x00\x60\x00\x00\x00"				 
			set offset 80
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"								
		}
		# if "--patch-lv2-payload-hermes-355" enabled, do patch
		if {$::patch_cos::options(--patch-lv2-payload-hermes-355)} {
		
			log "Patching Hermes payload 3.55 into LV2"				 
			set search     "\x4B\xFF\xFD\x04\xE8\x01\x00\x90\x60\x63\x00\x02\xEB\xC1\x00\x70"
			set replace    "\x25\x64\x25\x73\x25\x30\x31\x36\x6C\x78\x25\x30\x31\x36\x6C\x6C"
			append replace "\x78\x25\x30\x31\x36\x6C\x6C\x78\x25\x73\x25\x73\x25\x30\x38\x78"
			append replace "\x25\x64\x25\x31\x64\x25\x31\x64\x25\x31\x64\x41\x41\x41\x0A\x00"
			append replace "\xF8\x21\xFF\x31\x7C\x08\x02\xA6\xF8\x01\x00\xE0\xFB\xE1\x00\xC8"
			append replace "\x38\x81\x00\x70\x4B\xEC\xF7\x85\x3B\xE0\x00\x01\x7B\xFF\xF8\x06"
			append replace "\x67\xFF\x00\x2B\x63\xFF\xE5\x5C\xE8\x7F\x00\x00\x2C\x23\x00\x00"
			append replace "\x41\x82\x00\x0C\x38\x80\x00\x27\x4B\xDA\x2A\xAD\x38\x80\x00\x27"
			append replace "\x38\x60\x08\x00\x4B\xDA\x26\x65\xF8\x7F\x00\x00\xE8\x81\x00\x70"
			append replace "\x4B\xD9\x01\x65\xE8\x61\x00\x70\x38\x80\x00\x27\x4B\xDA\x2A\x89"
			append replace "\xE8\x7F\x00\x00\x4B\xD9\x01\x79\xE8\x9F\x00\x00\x7C\x64\x1A\x14"
			append replace "\xF8\x7F\x00\x08\x38\x60\x00\x00\xEB\xE1\x00\xC8\xE8\x01\x00\xE0"
			append replace "\x38\x21\x00\xD0\x7C\x08\x03\xA6\x4E\x80\x00\x20\x00\x00\x00\x00"
			append replace "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
			append replace "\x80\x00\x00\x00\x00\x2B\xE4\xD0\x00\x00\x00\x00\x00\x00\x00\x00"
			append replace "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
			append replace "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
			append replace "\xF8\x21\xFF\x61\x7C\x08\x02\xA6\xFB\x81\x00\x80\xFB\xA1\x00\x88"
			append replace "\xFB\xE1\x00\x98\xFB\x41\x00\x70\xFB\x61\x00\x78\xF8\x01\x00\xB0"
			append replace "\x7C\x9C\x23\x78\x7C\x7D\x1B\x78\x3B\xE0\x00\x01\x7B\xFF\xF8\x06"
			append replace "\x67\xE4\x00\x2B\x60\x84\xE6\x64\x38\xA0\x00\x09\x4B\xD9\x00\xFD"
			append replace "\x28\x23\x00\x00\x40\x82\x00\x30\x67\xFF\x00\x2B\x63\xFF\xE5\x5C"
			append replace "\xE8\x7F\x00\x00\x28\x23\x00\x00\x41\x82\x00\x14\xE8\x7F\x00\x08"
			append replace "\x38\x9D\x00\x09\x4B\xD9\x00\x81\xEB\xBF\x00\x00\x7F\xA3\xEB\x78"
			append replace "\x4B\xFF\x4C\x8C\x7F\xA3\xEB\x78\x3B\xE0\x00\x01\x7B\xFF\xF8\x06"
			append replace "\x67\xE4\x00\x2B\x60\x84\xE6\x6E\x38\xA0\x00\x09\x4B\xD9\x00\xAD"
			append replace "\x28\x23\x00\x00\x40\x82\x00\x28\x67\xFF\x00\x2B\x63\xFF\xE5\x5C"
			append replace "\xE8\x7F\x00\x00\x28\x23\x00\x00\x41\x82\x00\x14\xE8\x7F\x00\x08"
			append replace "\x38\x9D\x00\x09\x4B\xD9\x00\x31\xEB\xBF\x00\x00\x7F\xA3\xEB\x78"
			append replace "\x4B\xFF\x4C\x3C\x2F\x64\x65\x76\x5F\x62\x64\x76\x64\x00\x2F\x61"
			append replace "\x70\x70\x5F\x68\x6F\x6D\x65\x00"					
			set offset 0
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"								
			
			log "Patching Hermes payload pointer Syscall_Map_Open_Desc"    
			set search     "\x"
			set replace    "\x80\x00\x00\x00\x00\x2B\xE5\x70"
			set offset 0
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"							
		}
		# if "--patch-lv2-SC36-355" enabled, do patch
		if {$::patch_cos::options(--patch-lv2-SC36-355)} {
		
			log "Patching LV2 SysCall36 3.55 CFW"				 
			set search     "\x7C\x7F\x1B\x78\x41\xC2\x00\x58\x80\x1F\x00\x48\x2F\x80\x00\x02"
			set replace    "\x60\x00\x00\x00\x80\x1F\x00\x48\x48\x00\x00\x98"
			set offset 4
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"					
		   
			set search     "\x7C\xF9\x3B\x78\x90\x1D\x00\x80\x90\x1D\x00\x84\xF9\x3D\x00\x90"
			append search  "\x91\x3D\x00\x98\xF8\xDD\x00\xA0"
			set replace    "\x60\x00\x00\x00\x90\x1D\x00\x80\x90\x1D\x00\x84\xF9\x3D\x00\x90"
			append replace "\x91\x3D\x00\x98\x60\x00\x00\x00"
			set offset 0
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"							
		}
		##
		#### ----------------------------------------------------- END:  3.XX PATCHES AREA ----------------------------------------------- ####						
		
		log "Done LV2 patches...."
	}
	### ------------------------------------- END:    Do_LV2_Patches{} --------------------------------------------- ###   
	
	
	# --------------------------  BEGIN:  Do_Misc_OS_Patches   --------------------------------------------------------- ### 
	#
	# This proc is for applying any patches any other OS specific files
	#
	#
	proc Do_Misc_OS_Patches {path} {	
			
		log "Applying OS Misc File patches...."						
		# if "--patch-spkg-ecdsa-check" is enabled, patch in "spu_pkg_rvk_verifier.self"
		if {$::patch_cos::options(--patch-spkg-ecdsa-check)} {
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55: 0x3150 (0x38D0)
			# OFW 3.60: 0x3150 (0x38D0)
			# OFW 4.30: 0x3150 (0x38D0)
			# OFW 4.46: 0x3150 (0x38D0)
            log "Patching SPKG ECDSA verifier to disable ECDSA check"  
			set self "spu_pkg_rvk_verifier.self"
			set file [file join $path $self]			
          
		    set ::patch_cos::search  "\x04\x00\x2A\x03\x33\x7F\xD0\x80\x04\x00\x01\x82\x32\x00\x01\x00"
            set ::patch_cos::replace "\x40\x80\x00\x03"
			set ::patch_cos::offset 4			
			# base function to decrypt the "self" to "elf" for patching
			::modify_self_file $file ::patch_cos::patch_elf	
        }
		# if "--patch-RSOD-bypass" is enabled, patch in "dev_flash\vsh\module\basic_plugins.sprx"
		if {$::patch_cos::options(--patch-RSOD-bypass)} {
		
            log "Patching BASIC_PLUGINS.sprx to patch RSOD bypass"  
			set BASIC_PLUGINS [file join dev_flash vsh module basic_plugins.sprx]
			::modify_devflash_file $BASIC_PLUGINS ::patch_cos::patch_devflash_self			
        }	
	}
	### ------------------------------------- END:    Do_Misc_OS_Patches{} --------------------------------------------- ###   
	
	
	# stub proc for calling the ::copy_ps3_game routine
	proc install_pkg {arg} {		
		::copy_ps3_game ${::CUSTOM_PS3_GAME}
	}		
	# this is the proc for calling the ps3mfw_base::patch_elf{} routine
	proc patch_elf {elf} {               
        catch_die {::patch_elf $elf $::patch_cos::search $::patch_cos::offset $::patch_cos::replace} \
        "Unable to patch self [file tail $elf]"
    }
	proc patch_devflash_self {self} {		
        log "Patching [file tail $self]"
        ::modify_self_file $self ::patch_cos::patch_devflash_file
    }
	
	# this proc is for patching dev_flash files
	proc patch_devflash_file {elf} {   
		# verified OFW ver. 4.00 - 4.46+
		# OFW 3.55: NOT FOUND
		# OFW 3.60: NOT FOUND
		# OFW 4.00: 0xFEEC (0xFDFC)
		# OFW 4.30: 0xFF00 (0xFE10)
		# OFW 4.46: 0xFF00 (0xFE10)		
		if {${::NEWMFW_VER} < "4.00"} {
				log "RSOD BYPASS PATCH NOT SUPPORTED BELOW 4.00!"
				die "RSOD BYPASS PATCH NOT SUPPORTED BELOW 4.00!"
		} else {
			# if "--patch-RSOD-bypass" is enabled, patch in "dev_flash\vsh\module\basic_plugins.sprx"
			if {$::patch_cos::options(--patch-RSOD-bypass)} {
				set search     "\x41\x9E\x00\x10\x2F\x9F\x00\x02\x40\x9E\x00\x20\x48\x00\x00\x10"     
				set replace    "\x48\x00"
				set offset 8	
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"
			}
		}
    }
	# --------------------------------------------------------------------------------------		
}