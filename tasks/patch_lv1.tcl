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
# Description: PATCH: LV1 - Miscellaneous

# Option --patch-lv1-mmap: [3.xx/4.xx]  -->  Allow mapping of any memory area (Needed for LV2 Poke)
# Option --patch-lv1-htab-write: [3.xx/4.xx]  -->  Allow mapping of HTAB with write protection
# Option --patch-lv1-mfc-sr1-mask: [3.xx/4.xx]  -->  Allow to set all bits of SPE register MFC_SR1 with lv1_set_spe_privilege_state_area_1_register
# Option --patch-lv1-dabr-priv-mask: [3.xx/4.xx]  -->  Allow setting data access breakpoints in hypervisor state with lv1_set_dabr
# Option --patch-lv1-encdec-ioctl-0x85: [3.xx/4.xx]  -->  Allow ENCDEC IOCTL command 0x85
# Option --patch-lv1-gpu-4kb-iopage: [3.xx/4.xx]  -->  Allow 4kb IO page size for GPU GART memory
# Option --patch-lv1-dispmgr-access: [3.xx/4.xx]  -->  Allow access to all SS services (Needed for ps3dm-utils)
# Option --patch-lv1-iimgr-access: [3.xx/4.xx]  -->  Allow access to all services of Indi Info Manager
# Option --patch-lv1-um-extract-pkg: [3.xx/4.xx]  -->  Allow extracting for all package types
# Option --patch-lv1-um-write-eprom-product-mode: [3.xx/4.xx]  -->  Allow enabling product mode by using Update Manager Write EPROM
# Option --patch-lv1-sm-del-encdec-key: [3.xx/4.xx]  -->  Allow deleting of all ENCDEC keys
# Option --patch-lv1-repo-node-lpar: [3.xx/4.xx]  -->  Allow creating/modifying/deleting of repository nodes in any LPAR
# Option --patch-lv1-storage-skip-acl-check: [3.xx/4.xx]  -->  Skip ACL checks for all storage devices (OtherOS++/downgrader)
# Option --patch-lv1-gameos-sysmgr-ability:  [3.xx]  -->  Allow access to all System Manager services of GameOS
# Option --patch-lv1-gameos-gos-mode-one:  [3.xx]  -->  Enable GuestOS mode 1 for GameOS
# Option --patch-lv1-otheros-plus-plus-cold-boot-fix:  [3.xx]  -->  OtherOS++ cold boot fix
# Option --patch-lv1-revokelist-hash-check:  [3.55]  -->  Patch Revoke list Hash check. Product mode always on (downgrader)
# Option --patch-lv1-patch-productmode-erase:  [3.55]  -->  Patch In product mode erase standby bank skipped (downgrader)
# Option --patch-lv1-otheros-plus-plus:  [3.55]  -->  OtherOS++ support

# Type --patch-lv1-mmap: boolean
# Type --patch-lv1-htab-write: boolean
# Type --patch-lv1-mfc-sr1-mask: boolean
# Type --patch-lv1-dabr-priv-mask: boolean
# Type --patch-lv1-encdec-ioctl-0x85: boolean
# Type --patch-lv1-gpu-4kb-iopage: boolean
# Type --patch-lv1-dispmgr-access: boolean
# Type --patch-lv1-iimgr-access: boolean
# Type --patch-lv1-um-extract-pkg: boolean
# Type --patch-lv1-um-write-eprom-product-mode: boolean
# Type --patch-lv1-sm-del-encdec-key: boolean
# Type --patch-lv1-repo-node-lpar: boolean
# Type --patch-lv1-storage-skip-acl-check: boolean
# Type --patch-lv1-gameos-sysmgr-ability: boolean
# Type --patch-lv1-gameos-gos-mode-one: boolean
# Type --patch-lv1-otheros-plus-plus-cold-boot-fix: boolean
# Type --patch-lv1-revokelist-hash-check: boolean
# Type --patch-lv1-patch-productmode-erase: boolean
# Type --patch-lv1-otheros-plus-plus: boolean

namespace eval ::patch_lv1 {
	
    array set ::patch_lv1::options {		
        --patch-lv1-mmap false                
        --patch-lv1-htab-write false
        --patch-lv1-mfc-sr1-mask false
        --patch-lv1-dabr-priv-mask false
        --patch-lv1-encdec-ioctl-0x85 false
        --patch-lv1-gpu-4kb-iopage false
        --patch-lv1-dispmgr-access false
        --patch-lv1-iimgr-access false
        --patch-lv1-um-extract-pkg false
        --patch-lv1-um-write-eprom-product-mode false
        --patch-lv1-sm-del-encdec-key false
        --patch-lv1-repo-node-lpar false
        --patch-lv1-storage-skip-acl-check false		
        --patch-lv1-gameos-sysmgr-ability false
        --patch-lv1-gameos-gos-mode-one false
        --patch-lv1-otheros-plus-plus-cold-boot-fix false
		--patch-lv1-revokelist-hash-check false
        --patch-lv1-patch-productmode-erase false
		--patch-lv1-otheros-plus-plus false
    }

    proc main { } {
	
		# begin by calling the main function to go through
		# all the patches		
		::patch_lv1::Do_LV1_Patches $::CUSTOM_COSUNPKG_DIR		
    }

	# setup the filename with path, and call the base "modify_self_file"
	# routine to unself the lv1.self, and dispatch back to here,
	# to apply the patches, then re-sign the elf.
    proc Do_LV1_Patches {path} {
	
		set self "lv1.self"
		set file [file join $path $self]		
		# base function to decrypt the "self" to "elf" for patching
        ::modify_self_file $file ::patch_lv1::patch_lv1_elf
    }

	### main proc to do the LV1 patches, all in one shot ####
	##
    proc patch_lv1_elf {elf} {	
		
		# if "--patch-lv1-mmap" enabled, patch it
        if {$::patch_lv1::options(--patch-lv1-mmap)} {
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #			
			#
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55: 0x60C90 (0x240C90)
			# OFW 3.60: 0x60CB4 (0x240CB4)
			# OFW 4.46: 0x61ECC (0x241ECC)
			# OFW 4.55: 0x61ECC (0x241ECC)	
            log "Patching LV1 hypervisor to allow mapping of any memory area (1006151)"				  
		   #set search    "\x41\x9E\xFF\xF0\x4B\xFF\xFD\x00\x38\x60\x00\x00\x4B\xFF\xFC\x58"  --- OLD MATCH PATTERN --- 
            set search    "\x39\x2B\x00\x6C\x7D\x6B\x03\x78\x7D\x29\x03\x78\x91\x49\x00\x00\x48\x00\x00\x08\x43\x40\x00\x18"
			append search "\x80\x0B\x00\x00\x54\x00\x06\x30\x2F\x80\x00\x00\x41\x9E\xFF\xF0\x4B\xFF\xFD\x00"
            set replace   "\x4B\xFF\xFD\x01"											  ;# ^^ patch starts here
			set offset 40
			set mask 0				
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
        }                        
        # if "--patch-lv1-htab-write" enabled, patch it
        if {$::patch_lv1::options(--patch-lv1-htab-write)} {
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #			
			# (patch seems fine, NO mask req'd)
			#
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0xF5EB0 (0x2D5EB0)
			# OFW 3.60 == 0xF7698 (0x2D7698)  
			# OFW 4.46 == 0xFD284 (0x2DD284)
			# OFW 4.55 == 0xFD70C (0x2DD70C)
            log "Patching LV1 hypervisor to allow mapping of HTAB with write protection (1007280)"
            set search    "\x2f\x1d\x00\x00\x61\x4a\x97\xd2\x7f\x80\xf0\x00\x79\x4a\x07\xc6"
	        append search "\x65\x4a\xb5\x8e\x41\xdc\x00\x54\x3d\x40\x99\x79\x41\xda\x00\x54"
            set replace   "\x60\x00\x00\x00"
			set offset 28
			set mask 0			
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
	    }
		# if "--patch-lv1-mfc-sr1-mask" enabled, patch it
        if {$::patch_lv1::options(--patch-lv1-mfc-sr1-mask)} {
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #			
			# (patch seems fine, NO mask req'd)
			#
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0x112678 (0x2F2678)
			# OFW 3.60 == 0x113E44 (0x2F3E44)  
			# OFW 4.46 == 0x119A30 (0x2F9A30)
			# OFW 4.55 == 0x119EB8 (0x2F9EB8)
            log "Patching LV1 hypervisor to allow setting all bits of SPE register MFC_SR1 with lv1_set_spe_privilege_state_area_1_register (1123960)"         
            set search    "\xe8\x03\x00\x10\x39\x20\x00\x09\xe9\x43\x00\x00\x39\x00\x00\x00"
	        append search "\x78\x00\xef\xa6\x7c\xab\x48\x38\x78\x00\x1f\xa4\x7d\x6b\x03\x78"
            set replace   "\x39\x20\xff\xff"
			set offset 4
			set mask 0          
		    # PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
	    }
		# if "--patch-lv1-dabr-priv-mask" enabled, patch it
        if {$::patch_lv1::options(--patch-lv1-dabr-priv-mask)} {
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #			
			# (patch seems fine, NO mask req'd)
			#
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0x103CF4 (0x2E3CF4)
			# OFW 3.60 == 0x1054DC (0x2E54DC)  
			# OFW 4.46 == 0x10B0C8 (0x2EB0C8)
			# OFW 4.55 == 0x10B550 (0x2EB550)
            log "Patching LV1 hypervisor to allow setting data access breakpoints in hypervisor state with lv1_set_dabr (1064180)"           
            set search  "\x60\x00\x00\x00\x38\x00\x00\x0b\x7f\xe9\x00\x38\x7f\xa9\xf8\x00"
            set replace "\x38\x00\x00\x0F"
			set offset 4
			set mask 0         
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
	    }
		# if "--patch-lv1-encdec-ioctl-0x85" enabled, patch it
        if {$::patch_lv1::options(--patch-lv1-encdec-ioctl-0x85)} {
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #			
			# (patch seems fine, NO mask req'd)
			#
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0x93490 (0x273490)
			# OFW 3.60 == 0x934B4 (0x2734B4)  
			# OFW 4.46 == 0xCF IOCTLs allowed!!			
			# OFW 4.55 == 0x1CF IOCTLs allowed! (0x94FEC)
            log "Patching LV1 hypervisor to allow ENCDEC IOCTL command 0x85 (603284)"  
			if {${::NEWMFW_VER} < "3.70"} {
				set search  "\x38\x00\x00\x01\x39\x20\x00\x4f\x7c\x00\xf8\x36\x7c\x00\x48\x38"
				set replace "\x39\x20\x00\x5f"
				set offset 4
				set mask 0				
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
				
			} else {
				log "SKIPPING \"ENCDEC IOCTL command 0x85 patch\", as it's unneeded in this firmware version!"
			}         			
	    }
		# if "--patch-lv1-gpu-4kb-iopage" enabled, patch it
        if {$::patch_lv1::options(--patch-lv1-gpu-4kb-iopage)} {
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #			
			# (patch seems fine, NO mask req'd)
			#
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0x34990 (0x214990)
			# OFW 3.60 == 0x34990 (0x214990)
			# OFW 4.46 == 0x34F1C (0x214F1C)
			# OFW 4.55 == 0x34F1C (0x214F1C)
            log "Patching LV1 hypervisor to allow 4kb IO page size for GPU GART memory (215440)"         
           #set search  "\x6d\x00\x55\x55\x2f\xa9\x00\x00\x68\x00\x55\x55\x39\x20\x00\x00" -- old value -- (patch offset=84)
		    set search  "\xF9\x23\x01\x98\xF9\x23\x01\xA0\xF9\x23\x01\xA8\x41\x9E\x00\x0C\x3C\x00\x00\x01"
            set replace "\x38\x00\x10\x00"
			set offset 16
			set mask 0         
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
	    }
		# if "--patch-lv1-dispmgr-access" enabled, patch it		
        if {$::patch_lv1::options(--patch-lv1-dispmgr-access)} {	
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #			
			# (patch seems fine, NO mask req'd)
			#
            # patch SS services part 1/3       
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0x38EF28 (0x5BEF28)
			# OFW 3.60 == 0x38F698 (0x5BF698)
			# OFW 4.46 == 0x3AD9FC (0x5BD9FC)
			# OFW 4.55 == 0x3ADA74 (0x5BDA74)
            log "Patching Dispatcher Manager to allow access to all SS services 1/3 (3731240)"
            set search  "\xe8\x17\x00\x08\x7f\xc4\xf3\x78\x7f\x83\xe3\x78\xf8\x01\x00\x98"
            set replace "\x60\x00\x00\x00"
			set offset 12
			set mask 0           
		    # PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
         
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #			
			# (patch seems fine, NO mask req'd)
			#
			# patch SS services part 2/3 
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0x38EF4C (0x5BEF4C)
			# OFW 3.60 == 0x38F6BC (0x5BF6BC)
			# OFW 4.46 == 0x3ADA20 (0x5BDA20)
			# OFW 4.55 == 0x3ADA98 (0x5BDA98)
            log "Patching Dispatcher Manager to allow access to all SS services 2/3 (3731276)"
            set search  "\x7f\xa4\xeb\x78\x7f\x85\xe3\x78\x4b\xff\xf0\xe5\x54\x63\x06\x3e"
            set replace "\x38\x60\x00\x01"
			set offset 8
			set mask 0           
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
         
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #			
			# (patch seems fine, NO mask req'd)
			#
			# patch SS services part 3/3 
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0x38EFC4 (0x5BEFC4)
			# OFW 3.60 == 0x38F734 (0x5BF734)
			# OFW 4.46 == 0x3ADA98 (0x5BDA98)
			# OFW 4.55 == 0x3ADB10 (0x5BDB10)
            log "Patching Dispatcher Manager to allow access to all SS services 3/3 (3731396)"		   
		    set search  "\x7F\xC3\xF3\x78\x7f\x84\xe3\x78\x38\xa1\x00\x70\x9b\xe1\x00\x70\x48\x00"
            set replace "\x3b\xe0\x00\x01\x9b\xe1\x00\x70\x38\x60\x00\x00"
			set offset 8
			set mask 0         
		    # PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
        }
		# if "--patch-lv1-iimgr-access" enabled, patch it
        if {$::patch_lv1::options(--patch-lv1-iimgr-access)} {
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #			
			# (patch seems fine, NO mask req'd)
			#
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0x3407A0 (0x5707A0)
			# OFW 3.60 == 0x340B90 (0x570B90)
			# OFW 4.46 == 0x35E84C (0x56E84C)
			# OFW 4.55 == 0x35E8C4 (0x56E8C4)
            log "Patching Indi Info Manager to allow access to all its services (3409824)"          
            set search  "\x38\x60\x00\x0d\x38\x00\x00\x0d\x7c\x63\x00\x38\x4e\x80\x00\x20"
            set replace "\x38\x60\x00\x00"
			set offset 8
			set mask 0         
		    # PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
        }
        # if "--patch-lv1-um-extract-pkg" enabled, patch it
        if {$::patch_lv1::options(--patch-lv1-um-extract-pkg)} {
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #					
			#
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0x2C5040 (0x4F5040)
			# OFW 3.60 == 0x2C4DE0 (0x4F4DE0)
			# OFW 4.46 == 0x2E2684 (0x4F2684)
			# OFW 4.55 == 0x2E26A4 (0x4F26A4)
            log "Patching Update Manager to enable extracting for all package types (2904128)"         
            set search  "\x38\x1f\xff\xf9\x2f\x1d\x00\x01\x2b\x80\x00\x01\x38\x00\x00\x00\xf8\x1b\x00\x00\x41\x9d\x00\xa8\x7b\xfd\x00\x20\x7f\x44\xd3\x78"
			set mask	"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x00\x00\x00\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
            set replace "\x60\x00\x00\x00"																;# ^^ patch starts here
			set offset 20			 
		    # PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
        }
		# if "--patch-lv1-um-write-eprom-product-mode" enabled, patch it
        if {$::patch_lv1::options(--patch-lv1-um-write-eprom-product-mode)} {
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #					
			#
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0x2C7A28 (0x4F7A28)
			# OFW 3.60 == 0x2C7954 (0x4F7954)
			# OFW 4.46 == 0x2E540C (0x4F540C)
			# OFW 4.55 == 0x2E5454 (0x4F5454)
            log "Patching Update Manager to enable setting product mode by using Update Manager Write EPROM (2914856)"                  
			set search  "\x38\x80\x00\x01\xE8\xA2\x8C\x10\x7F\xC3\xF3\x78\x48\x02\xD4\x0D\xE8\x18\x00\x08\x2F\xA0\x00\x00\x40\x9E\x00\x10\x7F\xC3\xF3\x78"
			set mask	"\xFF\xFF\xFF\xFF\xFF\xFF\x00\x00\xFF\xFF\xFF\xFF\xFF\x00\x00\x00\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x00\x00\xFF\xFF\xFF\xFF"
            set replace "\x38\x00\x00\x00"												;# ^^ patch starts here
			set offset 16			 
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
        }
		# if "--patch-lv1-sm-del-encdec-key" enabled, patch it
        if {$::patch_lv1::options(--patch-lv1-sm-del-encdec-key)} {
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #			
			# (patch seems fine, NO mask req'd)
			#
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0x2DC420 (0x50C420)
			# OFW 3.60 == 0x2DCAF8 (0x50CAF8)
			# OFW 4.46 == 0x2FB330 (0x50B330)
			# OFW 4.55 == 0x2FB5D0 (0x50B5D0)
            log "Patching Storage Manager to allow deleting of all ENCDEC keys (2999328)"         
            set search    "\x7d\x24\x4b\x78\x39\x29\xff\xf4\x7f\xa3\xeb\x78\x2b\xa9\x00\x03"
            append search "\x38\x00\x00\x09\x41\x9d"
            set replace   "\x60\x00\x00\x00"
			set offset 20
			set mask 0			
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
        }
		# if "--patch-lv1-repo-node-lpar" enabled, patch it
        if {$::patch_lv1::options(--patch-lv1-repo-node-lpar)} {
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #			
			# (patch seems fine, NO mask req'd)
			#
		    # verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0xFD850 (0x2DD850)
			# OFW 3.60 == 0xFF038 (0x2DF038)
			# OFW 4.46 == 0x104C24 (0x2E4C24)    			
			# OFW 4.55 == 0x1050AC (0x2E50AC)    
            log "Patching LV1 hypervisor to allow creating/modifying/deleting of repository nodes in any LPAR 1/3 (1038416)"
            set search     "\x39\x20\x00\x00\xe9\x69\x00\x00\x4b\xff\xff\x68\x3d\x2d\x00\x00\x7c\x08\x02\xa6"
	        append search  "\xf8\x21\xff\x11\x39\x29\x98\x18\xfb\xa1\x00\xd8"		   
            set replace    "\xe8\x1e\x00\x20\xe9\x3e\x00\x28\xe9\x5e\x00\x30\xe9\x1e\x00\x38\xe8\xfe\x00\x40"
	        append replace "\xe8\xde\x00\x48\xeb\xfe\x00\x18"
			set offset 64
			set mask 0			
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
			
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #			
			# (patch seems fine, NO mask req'd)
			#
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0xFDCF4 (0x2DDCF4)
			# OFW 3.60 == 0xFF4DC (0x2DF4DC)
			# OFW 4.46 == 0x1050C8 (0x2E50C8)    		    
			# OFW 4.55 == 0x105550 (0x2E5550)    	
            log "Patching LV1 hypervisor to allow creating/modifying/deleting of repository nodes in any LPAR 2/3 (1039604)"
            set search     "\x39\x20\x00\x00\xe9\x29\x00\x00\x4b\xff\xff\x9c\x3d\x2d\x00\x00\x7c\x08\x02\xa6"
	        append search  "\xf8\x21\xff\x11\x39\x29\x98\x18\xfb\xa1\x00\xd8"
            set replace    "\xe8\x1e\x00\x20\xe9\x3e\x00\x28\xe9\x5e\x00\x30\xe9\x1e\x00\x38\xe8\xfe\x00\x40"
	        append replace "\xe8\xde\x00\x48\xeb\xfe\x00\x18"
			set offset 64
			set mask 0			
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
         
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #			
			# (patch seems fine, NO mask req'd)
			#
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0xFD5CC  (0x2DD5CC)
			# OFW 3.60 == 0xFEDB4  (0x2DEDB4)
			# OFW 4.46 == 0x1049A0 (0x2E49A0)     
			# OFW 4.55 == 0x104E28 (0x2E4E28)    
            log "Patching LV1 hypervisor to allow creating/modifying/deleting of repository nodes in any LPAR 3/3 (1037772)"
            set search    "\x39\x20\x00\x00\xe9\x29\x00\x00\x4b\xff\xfe\x70\x3d\x2d\x00\x00\x7c\x08\x02\xa6"
	        append search "\xf8\x21\xff\x31\x39\x29\x98\x18\xfb\xa1\x00\xb8"
            set replace   "\xe8\x1e\x00\x20\xe9\x5e\x00\x28\xe9\x1e\x00\x30\xe8\xfe\x00\x38\xeb\xfe\x00\x18"
			set offset 60
			set mask 0			
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
        }				
		# if "--patch-lv1-storage-skip-acl-check" enabled, patch it
        if {$::patch_lv1::options(--patch-lv1-storage-skip-acl-check)} {
			# <><> --- OPTIMIZED FOR 'PATCHTOOL' --- <><> #			
			# (patch seems fine, NO mask req'd)
			#
			# verified OFW ver. 3.55 - 4.55+
			# OFW 3.55 == 0x7B340 (0x25B340)
			# OFW 3.60 == 0x7B364 (0x25B364)
			# OFW 4.46 == 0x7C504 (0x25C504) 
			# OFW 4.55 == 0x7C504 (0x25C504) 
            log "Patching LV1 to enable skipping of ACL checks for all storage devices (OtherOS++/downgrader) (504640)"         
            set search    "\x54\x63\x06\x3e\x2f\x83\x00\x00\x41\x9e\x00\x14\xe8\x01\x00\x70\x54\x00\x07\xfe"
	        append search "\x2f\x80\x00\x00\x40\x9e\x00\x18"
            set replace   "\x38\x60\x00\x01\x2f\x83\x00\x00\x41\x9e\x00\x14\x38\x00\x00\x01"
			set offset 0
			set mask 0         
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
        }
		
		##################### 		BEGIN BROKEN/3.XX ONLY PATCHES 		##########################################################
		# if "--patch-lv1-gameos-sysmgr-ability" enabled, patch it
        if {$::patch_lv1::options(--patch-lv1-gameos-sysmgr-ability)} {
			## *** NEEDS REFINING, CODE CHANGED IN 4.xx ***
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55 == 0x222258 (0x452258)
			# OFW 3.60 == 0x222274 (0x452274)
			# OFW 4.46 == ???
			die "CURRENTLY NOT SUPPORTED, NEEDS UPDATING!!"
			# -------------------------------------------- #			
			
            log "Patching System Manager ability mask of GameOS to allow access to all System Manager services (2237028)"         
            set search    "\xe8\x1f\x01\xc0\x39\x20\x00\x03\xf9\x5f\x00\x60\x64\x00\x00\x3b\xf9\x3f\x01\xc8"
            append search "\x60\x00\xf7\xee\xf8\x1f\x01\xc0\xe8\x01\x00\x90"
            set replace   "\x64\x00\xff\xff\xf9\x3f\x01\xc8\x60\x00\xff\xfe"
			set offset 12
			set mask 0
         
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
        }
        # if "--patch-lv1-gameos-gos-mode-one" enabled, patch it
        if {$::patch_lv1::options(--patch-lv1-gameos-gos-mode-one)} {
			# **** CANNOT FIND THIS PATCH!!! *****
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55 == 0x21D25C (0x44D25C)
			# OFW 3.60 == 0x21D278 (0x44D278)
			# OFW 4.46 == ???
			die "CURRENTLY NOT SUPPORTED, NEEDS UPDATING!!"
			## --------------------------------------------- ####
			
            log "Patching Initial GuestOS Loader to enable GuestOS mode 1 for GameOS (2216552)"         
            set search  "\xe9\x29\x00\x00\x2f\xa9\x00\x01\x40\x9e\x00\x18\x38\x60\x00\x00"
            set replace "\x38\x60\x00\x01"
			set offset 12
			set mask 0
         
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
        }
		# if "--patch-lv1-otheros-plus-plus-cold-boot-fix" enabed, patch it
        if {$::patch_lv1::options(--patch-lv1-otheros-plus-plus-cold-boot-fix)} {
			# verified OFW ver. 3.55 - 4.46+
			# OFW 3.55 == 0x21D25C (0x44D25C)
			# OFW 3.60 == 0x21D278 (0x44D278)
			# OFW 4.46 == ???
			die "CURRENTLY NOT SUPPORTED, NEEDS UPDATING!!"
			## --------------------------------------------- ####
			
            log "Patching Initial GuestOS Loader to fix cold boot problem for OtherOS++ (2216540)"           
            set search  "\xe9\x29\x00\x00\x2f\xa9\x00\x01\x40\x9e\x00\x18"
            set replace "\x39\x20\x00\x03"
			set offset 0
			set mask 0
         
			# PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
        }
		##################### 				END BROKEN/3.XX ONLY PATCHES 			   ##########################################################
		
		#### ----------------------------------------------------- BEGIN:  3.XX PATCHES AREA ----------------------------------------------- ####
		#
		# if "--patch-lv1-revokelist-hash-check" enabled, patch it
		#  **** PATCH ONLY VALID FOR FW 3.55 ********
        if {$::patch_lv1::options(--patch-lv1-revokelist-hash-check)} {
			
            log "Patch Revoke list Hash check. Product mode always on (downgrader) (2894836)"            			
			if {${::NEWMFW_VER} > "3.55"} {
				die "PATCH NOT SUPPORTED ABOVE 3.55!"
			} else {							
				set search "\x41\x9E\x00\x1C\x7F\xA3\xEB\x78\xE8\xA2\x85\x68\x38\x80\x00\x01"
				set replace "\x60\x00\x00\x00\x7F\xA3\xEB\x78\xE8\xA2\x85\x68\x38\x80\x00\x01"
				set offset 0
				set mask 0				
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
			}
        }
        # if "--patch-lv1-patch-productmode-erase" enabled, patch it
		#  **** PATCH ONLY VALID FOR FW 3.55 ********
        if {$::patch_lv1::options(--patch-lv1-patch-productmode-erase)} {
		
            log "Patch In product mode erase standby bank skipped (downgrader) (2911100)"			
			if {${::NEWMFW_VER} > "3.55"} {
				die "PATCH NOT SUPPORTED ABOVE 3.55!"
			} else {
				set search "\x41\x9E\x00\x0C\xE8\xA2\x8A\x38\x48\x00\x00\xCC\x7B\xFD\x00\x20"
				set replace "\x60\x00\x00\x00\xE8\xA2\x8A\x38\x48\x00\x00\xCC\x7B\xFD\x00\x20"
				set offset 0
				set mask 0
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
			}
        }
		# if "--patch-lv1-otheros-plus-plus" enabled, patch it
        if {$::patch_lv1::options(--patch-lv1-otheros-plus-plus)} {		
            # **** CANNOT FIND THIS PATCH!!! *****
			die "This patch is currently not supported!!!!"
			## --------------------------------------------- #### 
			
			
            log "Patching Secure LPAR Loader to add OtherOS++ support 1/5 (3639260)"
            set search "\x53\x43\x45\x00\x00\x00\x00\x02\x80\x00\x00\x01\x00\x00\x01\xe0\x00\x00\x00\x00"
            append search "\x00\x00\x04\x80\x00\x00\x00\x00\x00\x03\x8a\x50\x00\x00\x00\x00\x00\x00\x00\x03"
            append search "\x00\x00\x00\x00\x00\x00\x00\x70\x00\x00\x00\x00\x00\x00\x00\x90\x00\x00\x00\x00"
            append search "\x00\x00\x00\xd0\x00\x00\x00\x00\x00\x03\x8b\xd0\x00\x00\x00\x00\x00\x00\x01\x40"
            append search "\x00\x00\x00\x00\x00\x00\x01\x80\x00\x00\x00\x00\x00\x00\x01\x90\x00\x00\x00\x00"
            append search "\x00\x00\x00\x70\x00\x00\x00\x00\x00\x00\x00\x00\x10\x70\x00\x00\x34\x00\x00\x01"
            append search "\x07\x00\x00\x01\x00\x00\x00\x04"
            set replace "\x00\x00\x00\x00\x00\x01\xd0\x00\x00\x00\x00\x00\x00\x01\xd0\x00\x00\x00\x00\x00"
            append replace "\x00\x01\x00\x00\x00\x00\x00\x01\x00\x00\x00\x06\x00\x00\x00\x00\x00\x03\x00\x00"
            append replace "\x00\x00\x00\x00\xc0\x00\x00\x00\x00\x00\x00\x00\xc0\x00\x00\x00\x00\x00\x00\x00"
            append replace "\x00\x00\x77\x20\x00\x00\x00\x00\x00\x00\x81\x30\x00\x00\x00\x00\x00\x01\x00\x00"
            append replace "\x00\x00\x00\x00\x00\x01\x04\x80\x00\x00\x00\x00\x00\x01\xd0\x00"
			set offset 240
			set mask 0
         
            # PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
         
            log "Patching Secure LPAR Loader to add OtherOS++ support 2/5 (3640268)"
            set search  "\x63\x2f\xeb\x68\x7f\x45\x4c\x46\x02\x02\x01\x66\x00\x00\x00\x00\x00\x00\x00\x00"
            append search "\x00\x02\x00\x15\x00\x00\x00\x01\x00\x00\x00\x00\xc0\x00\x29\x78\x00\x00\x00\x00"
            append search "\x00\x00\x00\x40\x00\x00\x00\x00\x00\x03\x87\x50\x00\x00\x00\x00\x00\x40\x00\x38"
            append search "\x00\x02\x00\x40\x00\x0c\x00\x0b\x00\x00\x00\x01\x00\x00\x00\x07\x00\x00\x00\x00"
            append search "\x00\x01\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00"
            append search "\x00\x00\x00\x00\x00\x01\xc0\x80\x00\x00\x00\x00\x00\x01\xc0\x80"
            set replace  "\x00\x00\x00\x00\x00\x01\xd0\x00\x00\x00\x00\x00\x00\x01\xd0\x00"
			set offset 100
			set mask 0
         
            # PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
         
            log "Patching Secure LPAR Loader to add OtherOS++ support 3/5 (3871772)"
            set search  "\x00\x00\x00\x27\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x03\x00\x00\x00\x00"
	        append search "\x80\x01\xb3\x90\x00\x00\x00\x00\x00\x02\xb3\x90\x00\x00\x00\x00\x00\x00\x0c\xf0"
            set replace  "\x00\x00\x00\x00\x00\x00\x1c\x70"
			set offset 32
			set mask 0
         
            # PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
         
            log "Patching Secure LPAR Loader to add OtherOS++ support 4/5 (3820524)"
            set search  "\x00\x00\x00\x00\xc0\x00\x5c\xd8\x00\x00\x00\x00\xc0\x00\x5c\xc0\x00\x00\x00\x00"
            append search "\xc0\x00\x5c\xa8\x00\x00\x00\x00\xc0\x00\x5c\x90\x00\x00\x00\x00\xc0\x00\x5b\x88"
            append search "\x00\x00\x00\x00\xc0\x00\x5b\x70\x00\x00\x00\x00\xc0\x00\x5c\xf0\x00\x00\x00\x00"
            append search "\xc0\x00\x4d\x48\x00\x00\x00\x00\xc0\x00\x4d\x60\x00\x00\x00\x00\xc0\x00\x5a\xc8"
            append search "\x00\x00\x00\x00\xc0\x00\x4d\x78\x00\x00\x00\x00\xc0\x00\x4e\x38"
         
            set replace  "\xf8\x21\xff\x01\x7c\x08\x02\xa6\xf8\x01\x01\x10\xfb\x21\x00\xf8\xfb\x41\x00\xf0"
	        append replace "\xfb\x61\x00\xe8\xfb\x81\x00\xe0\xfb\xa1\x00\xd8\xfb\xc1\x00\xd0\xfb\xe1\x00\xc8"
	        append replace "\xf8\x61\x00\xc0\xf8\x81\x00\xb8\xf8\xa1\x00\xb0\x48\x00\x00\x05\x7f\xe8\x02\xa6"
    	    append replace "\x3b\xff\xff\xc8\xe8\x1f\x04\xb0\xf8\x01\x00\x88\xe8\x1f\x04\xb8\xf8\x01\x00\x90"
	        append replace "\xe8\x1f\x04\xc0\xf8\x01\x00\x98\xe8\x1f\x04\xc8\xf8\x01\x00\xa0\x38\x00\x00\x00"
	        append replace "\xf8\x01\x00\x78\xf8\x01\x00\x80\x38\x60\x00\x01\x38\x81\x00\x88\x38\xa1\x00\x78"
	        append replace "\x3b\xc0\x00\x00\x67\xde\x80\x01\x63\xde\x2f\xd0\x7f\xc9\x03\xa6\x4e\x80\x04\x21"
	        append replace "\x2f\xa3\x00\x00\x40\x9e\x00\x18\xe8\x01\x00\x78\x78\x00\x06\x20\x2f\x80\x00\xff"
	        append replace "\x3b\x60\x00\x0f\x40\x9e\x03\x6c\xe8\x1f\x04\xb0\xf8\x01\x00\x88\xe8\x1f\x04\xb8"
	        append replace "\xf8\x01\x00\x90\xe8\x1f\x04\xd0\xf8\x01\x00\x98\xe8\x1f\x04\xd8\xf8\x01\x00\xa0"
	        append replace "\x38\x00\x00\x00\xf8\x01\x00\x78\xf8\x01\x00\x80\x38\x60\x00\x01\x38\x81\x00\x88"
	        append replace "\x38\xa1\x00\x78\x3b\xc0\x00\x00\x67\xde\x80\x01\x63\xde\x2f\xd0\x7f\xc9\x03\xa6"
	        append replace "\x4e\x80\x04\x21\x2f\xa3\x00\x00\x40\x9e\x00\x18\xe8\x01\x00\x78\x78\x00\x06\x20"
	        append replace "\x2f\x80\x00\xff\x3b\x60\x00\x0f\x40\x9e\x03\x04\xe8\x1f\x04\xb0\xf8\x01\x00\x88"
    	    append replace "\xe8\x1f\x04\xb8\xf8\x01\x00\x90\xe8\x1f\x04\xe0\xf8\x01\x00\x98\xe8\x1f\x04\xd8"
	        append replace "\xf8\x01\x00\xa0\x38\x00\x00\x00\xf8\x01\x00\x78\xf8\x01\x00\x80\x38\x60\x00\x01"
	        append replace "\x38\x81\x00\x88\x38\xa1\x00\x78\x3b\xc0\x00\x00\x67\xde\x80\x01\x63\xde\x2f\xd0"
	        append replace "\x7f\xc9\x03\xa6\x4e\x80\x04\x21\x2f\xa3\x00\x00\x40\x9e\x00\x18\xe8\x01\x00\x78"
	        append replace "\x78\x00\x06\x20\x2f\x80\x00\xff\x3b\x60\x00\x0f\x40\x9e\x02\x9c\xe8\x1f\x04\xb0"
	        append replace "\xf8\x01\x00\x88\xe8\x1f\x04\xb8\xf8\x01\x00\x90\xe8\x1f\x04\xe8\xf8\x01\x00\x98"
	        append replace "\xe8\x1f\x04\xd8\xf8\x01\x00\xa0\x38\x00\x00\x00\xf8\x01\x00\x78\xf8\x01\x00\x80"
	        append replace "\x38\x60\x00\x01\x38\x81\x00\x88\x38\xa1\x00\x78\x3b\xc0\x00\x00\x67\xde\x80\x01"
	        append replace "\x63\xde\x2f\xd0\x7f\xc9\x03\xa6\x4e\x80\x04\x21\x2f\xa3\x00\x00\x40\x9e\x00\x18"
	        append replace "\xe8\x01\x00\x78\x78\x00\x06\x20\x2f\x80\x00\xff\x3b\x60\x00\x0f\x40\x9e\x02\x34"
    	    append replace "\xe8\x61\x00\xb0\x38\x80\x00\x00\xeb\x5f\x04\x70\xeb\x9f\x04\x90\x7c\xba\xe2\x14"
    	    append replace "\x38\xc1\x00\xa8\x3b\xc0\x00\x00\x67\xde\x80\x00\x63\xde\x26\xb4\x7f\xc9\x03\xa6"
	        append replace "\x4e\x80\x04\x21\x2f\x83\x00\x00\x7c\x7b\x1b\x78\x40\x9e\x01\xfc\xe8\x61\x00\xa8"
	        append replace "\x38\x80\x00\x00\x7f\x85\xe3\x78\x3b\xc0\x00\x00\x67\xde\x80\x00\x63\xde\x02\x78"
	        append replace "\x7f\xc9\x03\xa6\x4e\x80\x04\x21\x38\x7f\x04\x98\x38\x80\x00\x00\x3b\x60\x00\x10"
	        append replace "\x3b\xc0\x00\x00\x67\xde\x80\x01\x63\xde\x3d\x40\x7f\xc9\x03\xa6\x4e\x80\x04\x21"
	        append replace "\x2f\x83\x00\x00\x7c\x7d\x1b\x78\x41\x9c\x01\x94\x7f\xa3\x07\xb4\xe8\x81\x00\xa8"
	        append replace "\x3b\x20\x08\x00\x7f\x25\xcb\x78\x3b\x60\x00\x10\x3b\xc0\x00\x00\x67\xde\x80\x01"
	        append replace "\x63\xde\x3d\xb8\x7f\xc9\x03\xa6\x4e\x80\x04\x21\x7f\xa3\xc8\x00\x40\x9e\x01\x4c"
    	    append replace "\x3b\x60\x00\x14\x38\x7f\x04\x78\xe8\x81\x00\xa8\x38\xa0\x00\x10\x3b\xc0\x00\x00"
    	    append replace "\x67\xde\x80\x01\x63\xde\x39\xe0\x7f\xc9\x03\xa6\x4e\x80\x04\x21\x2f\xa3\x00\x00"
    	    append replace "\x40\x9e\x01\x20\xe8\xa1\x00\xa8\x83\x25\x00\x10\x2f\x99\x00\x01\x40\x9e\x01\x10"
	        append replace "\xe8\xa1\x00\xa8\x83\x25\x00\x20\x2f\x99\x00\x00\x40\x9e\x01\x00\xe8\xa1\x00\xa8"
	        append replace "\x83\x25\x02\x00\x2f\x99\x00\x00\x41\x9e\x00\xf0\xe8\xa1\x00\xa8\x83\x25\x00\x24"
	        append replace "\x7f\xb9\xe0\x00\x41\x9d\x00\xe0\x7f\xa3\x07\xb4\xe8\x81\x00\xa8\x7f\x25\xcb\x78"
	        append replace "\x3b\x60\x00\x10\x3b\xc0\x00\x00\x67\xde\x80\x01\x63\xde\x3d\xb8\x7f\xc9\x03\xa6"
	        append replace "\x4e\x80\x04\x21\x7f\xa3\xc8\x00\x40\x9e\x00\xb4\xe8\x1f\x04\xf0\xf8\x01\x00\x88"
	        append replace "\xe8\x1f\x04\xf8\xf8\x01\x00\x90\xe8\x1f\x05\x00\xf8\x01\x00\x98\xe8\x1f\x05\x08"
	        append replace "\xf8\x01\x00\xa0\x38\x00\x00\x00\xf8\x01\x00\x78\xf8\x01\x00\x80\x38\x60\x00\x01"
	        append replace "\x38\x81\x00\x88\x38\xa1\x00\x78\x3b\xc0\x00\x00\x67\xde\x80\x01\x63\xde\x2f\x88"
	        append replace "\x7f\xc9\x03\xa6\x4e\x80\x04\x21\x38\x60\x00\x29\x3b\xc0\x00\x00\x67\xde\x80\x00"
	        append replace "\x63\xde\x2c\xf0\x7f\xc9\x03\xa6\x4e\x80\x04\x21\x39\x20\x00\x00\x48\x00\x00\x14"
	        append replace "\xe8\x01\x00\xa8\x7c\x09\x02\x14\x7c\x00\x00\x6c\x39\x29\x00\x80\x7f\xa9\xe0\x00"
	        append replace "\x41\x9c\xff\xec\x7c\x00\x04\xac\x39\x20\x00\x00\x48\x00\x00\x14\xe8\x01\x00\xa8"
	        append replace "\x7c\x09\x02\x14\x7c\x00\x07\xac\x39\x29\x00\x80\x7f\xa9\xe0\x00\x41\x9c\xff\xec"
	        append replace "\x4c\x00\x01\x2c\x3b\x60\x00\x00\x7f\xa3\x07\xb4\x3b\xc0\x00\x00\x67\xde\x80\x01"
	        append replace "\x63\xde\x3d\x7c\x7f\xc9\x03\xa6\x4e\x80\x04\x21\xe8\x61\x00\xa8\x7c\x9a\xe2\x14"
	        append replace "\x3b\xc0\x00\x00\x67\xde\x80\x01\x63\xde\x3e\xb8\x7f\xc9\x03\xa6\x4e\x80\x04\x21"
	        append replace "\x7b\x63\x00\x20\xe8\x01\x01\x10\xeb\x21\x00\xf8\xeb\x41\x00\xf0\xeb\x61\x00\xe8"
	        append replace "\xeb\x81\x00\xe0\xeb\xa1\x00\xd8\xeb\xc1\x00\xd0\xeb\xe1\x00\xc8\x2f\x83\x00\x00"
	        append replace "\x41\x9e\x00\x2c\xe8\x61\x00\xc0\xe8\x81\x00\xb8\xe8\xa1\x00\xb0\x38\x21\x01\x00"
	        append replace "\x7c\x08\x03\xa6\x38\xc0\x00\x00\x64\xc6\x80\x00\x60\xc6\x0e\x44\x7c\xc9\x03\xa6"
	        append replace "\x4e\x80\x04\x20\x38\x21\x01\x00\x7c\x08\x03\xa6\x4e\x80\x00\x20\x00\x00\x00\x00"
	        append replace "\x00\x00\x00\x00\x63\x65\x6c\x6c\x5f\x65\x78\x74\x5f\x6f\x73\x5f\x61\x72\x65\x61"
	        append replace "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x80\x00\x00\x2f\x64\x65\x76"
	        append replace "\x2f\x72\x66\x6c\x61\x73\x68\x5f\x6c\x78\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
	        append replace "\x00\x00\x00\x00\x73\x73\x00\x00\x70\x61\x72\x61\x6d\x00\x00\x00\x75\x70\x64\x61"
	        append replace "\x74\x65\x00\x00\x73\x74\x61\x74\x75\x73\x00\x00\x70\x72\x6f\x64\x75\x63\x74\x00"
	        append replace "\x6d\x6f\x64\x65\x00\x00\x00\x00\x72\x65\x63\x6f\x76\x65\x72\x00\x68\x64\x64\x63"
	        append replace "\x6f\x70\x79\x00\x00\x00\x00\x00\x69\x6f\x73\x00\x61\x74\x61\x00\x00\x00\x00\x00"
	        append replace "\x72\x65\x67\x69\x6f\x6e\x30\x00\x61\x63\x63\x65\x73\x73\x00\x00"
			set offset 96
			set mask 0
         
            # PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
         
            log "Patching Secure LPAR Loader to add OtherOS++ support 5/5 (3708368)"
            set search  "\x88\x04\x00\x00\x2f\x80\x00\x00\x41\x9e\x01\x20\x2b\xa6\x00\x01\x40\x9d\x01\x18"
            append search "\x7c\xa4\x2b\x78\x7c\xc5\x33\x78\x48\x00\x03\xe1"
            set replace  "\x48\x01\xb6\x1d"
			set offset 28
			set mask 0
         
            # PATCH THE ELF BINARY
			catch_die {::patch_elf $elf $search $offset $replace $mask} "Unable to patch self [file tail $elf]" 
        }
		##
		##
		#### ----------------------------------------------------- END:  3.XX PATCHES AREA ----------------------------------------------- ####
    }
}
