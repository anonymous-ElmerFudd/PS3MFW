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

# Option --allow-unsigned-app: [3.xx/4.xx]  -->  Patch to allow running of unsigned applications (3.xx/4.xx)
# Option --patch-vsh-react-psn-v2-4x: [3.xx/4.xx]  -->  Jailbait - Patch to implement ReactPSN v2.0 into VSH (3.xx/4.xx)
# Option --disable-cinavia-protection-4x: [3.xx/4.xx]  -->  Disable Cinavia Protection (4.xx)
# Option --allow-retail-pkg-dex: [3.xx/4.xx]  -->  Patch to allow installation of retail packages on DEX (3.xx/4.xx)
# Option --allow-pseudoretail-pkg: [3.xx/4.xx]  -->  Patch to allow installation of pseudo-retail packages on REX/DEX (3.xx/4.xx)
# Option --allow-debug-pkg: [3.xx/4.xx]  -->  Patch to allow installation of debug packages (3.xx/4.xx)
# Option --spoof-psn-passphrase: [3.xx/4.xx]  -->  Jailbait - Patch PSN Passphrase (Not needed to time)
# Option --spoof-new: [3.xx/4.xx]  -->  Jailbait - Patch SEN/PSN Access (New FW Spoofing)
# Option --customize-fw-ssl-cer: [3.xx/4.xx]  -->  Change SSL - New SSL CA certificate (source)
# Option --customize-fw-change-cer: [3.xx/4.xx]  -->  Change SSL - SSL CA public certificate (destination)

# Type --allow-unsigned-app: boolean
# Type --disable-cinavia-protection-4x: boolean
# Type --allow-retail-pkg-dex: boolean
# Type --allow-pseudoretail-pkg: boolean
# Type --allow-debug-pkg: boolean
# Type --patch-vsh-react-psn-v2-4x: boolean
# Type --spoof-psn-passphrase: boolean
# Type --spoof-new: combobox { {4.31 59249 20121027 0001:CEX-ww 4906@security/sdk_branches/release_431/trunk 49507@sys/sdk_branches/release_431/trunk 16072@x3/branches/target43x 6218@paf/branches/target43x 91288@vsh/branches/target43x 85@sys_jp/branches/target43x 9073@emu/branches/target101/ps1 9080@emu/branches/target430/ps1_net 9039@emu/branches/target202/ps1_new 9040@emu/branches/target400/ps2 16771@branches/target400/gx 16770@branches/soft190/soft 9097@emu/branches/target430/psp 3924@emerald/target42x 19089@bdp/prof5/branches/target42x} {4.30 59178 20121018 0001:CEX-ww 4878@security/sdk_branches/release_430/trunk 49489@sys/sdk_branches/release_430/trunk 16072@x3/branches/target43x 6218@paf/branches/target43x 91242@vsh/branches/target43x 85@sys_jp/branches/target43x 9073@emu/branches/target101/ps1 9080@emu/branches/target430/ps1_net 9039@emu/branches/target202/ps1_new 9040@emu/branches/target400/ps2 16771@branches/target400/gx 16770@branches/soft190/soft 9076@emu/branches/target430/psp 3924@emerald/target42x 19089@bdp/prof5/branches/target42x} {4.25 58730 20120907 0001:CEX-ww 4859@security/sdk_branches/release_425/trunk 49405@sys/sdk_branches/release_425/trunk 16046@x3/branches/target42x 6203@paf/branches/target42x 90897@vsh/branches/target42x 81@sys_jp/branches/target42x 8891@emu/branches/target101/ps1 8948@emu/branches/target420/ps1_net 8890@emu/branches/target202/ps1_new 9029@emu/branches/target400/ps2 16578@branches/target400/gx 15529@branches/soft190/soft 9020@emu/branches/target42x/psp 3924@emerald/target42x 19089@bdp/prof5/branches/target42x} {4.21 58071 20120630 0001:CEX-ww 4824@security/sdk_branches/release_421/trunk 49276@sys/sdk_branches/release_421/trunk 16040@x3/branches/target421 6205@paf/branches/target421 90261@vsh/branches/target421 83@sys_jp/branches/target421 8891@emu/branches/target101/ps1 8948@emu/branches/target420/ps1_net 8890@emu/branches/target202/ps1_new 8960@emu/branches/target400/ps2 16578@branches/target400/gx 15529@branches/soft190/soft 8962@emu/branches/target420/psp 3924@emerald/target42x 19089@bdp/prof5/branches/target42x} }
# Type --customize-fw-ssl-cer: file open {"SSL Certificate" {cer}}
# Type --customize-fw-change-cer: combobox {{DNAS} {Proxy} {ALL} {CA01.cer} {CA02.cer} {CA03.cer} {CA04.cer} {CA05.cer} {CA23.cer} {CA06.cer} {CA07.cer} {CA08.cer} {CA09.cer} {CA10.cer} {CA11.cer} {CA12.cer} {CA13.cer} {CA14.cer} {CA15.cer} {CA16.cer} {CA17.cer} {CA18.cer} {CA19.cer} {CA20.cer} {CA21.cer} {CA22.cer} {CA24.cer} {CA25.cer} {CA26.cer} {CA27.cer} {CA28.cer} {CA29.cer} {CA30.cer} {CA31.cer} {CA32.cer} {CA33.cer} {CA34.cer} {CA35.cer} {CA36.cer}}

namespace eval ::patch_vsh {

    array set ::patch_vsh::options {
		--allow-unsigned-app true
		--disable-cinavia-protection-4x false		
        --allow-retail-pkg-dex false
        --allow-pseudoretail-pkg false		
        --allow-debug-pkg false
		--patch-vsh-react-psn-v2-4x true        
        --spoof-psn-passphrase false
        --spoof-new ""
        --customize-fw-ssl-cer ""
        --customize-fw-change-cer ""		   
    }

    proc main { } {
        variable options
        set src $::patch_vsh::options(--customize-fw-ssl-cer)
        set dst $::patch_vsh::options(--customize-fw-change-cer)
        set path [file join dev_flash data cert]
     
		# if "retail/debug pkg" options, then patch "nas_plugin.sprx"
        if {$::patch_vsh::options(--allow-pseudoretail-pkg) || $::patch_vsh::options(--allow-debug-pkg) || $::patch_vsh::options(--allow-retail-pkg-dex)} {
            set self [file join dev_flash vsh module nas_plugin.sprx]
            ::modify_devflash_file $self ::patch_vsh::patch_self
        }
        # if "unsigned/psn" patches enabled, patch "vsh.self"
        if {$::patch_vsh::options(--allow-unsigned-app)  || $::patch_vsh::options(--patch-vsh-react-psn-v2-4x) || {$::patch_vsh::options(--spoof-new) != 0} ||
		$::patch_vsh::options(--spoof-psn-passphrase)} {
            set self [file join dev_flash vsh module vsh.self]
            ::modify_devflash_file $self ::patch_vsh::patch_self
        }
		# setup vars based on the spoof string
        if {$::patch_vsh::options(--spoof-new) != "" } {
			variable options
			set release [lindex $options(--spoof-old) 0]
			set build [lindex $options(--spoof-old) 1]
			set bdate [lindex $options(--spoof) 2]
			set target [lindex $options(--spoof) 3]
			set security [lindex $options(--spoof) 4]
			set system [lindex $options(--spoof) 5]
			set x3 [lindex $options(--spoof) 6]
			set paf [lindex $options(--spoof) 7]
			set vsh [lindex $options(--spoof) 8]
			set sys_jp [lindex $options(--spoof) 9]
			set ps1emu [lindex $options(--spoof) 10]
			set ps1netemu [lindex $options(--spoof) 11]
			set ps1newemu [lindex $options(--spoof) 12]
			set ps2emu [lindex $options(--spoof) 13]
			set ps2gxemu [lindex $options(--spoof) 14]
			set ps2softemu [lindex $options(--spoof) 15]
			set pspemu [lindex $options(--spoof) 16]
			set emerald [lindex $options(--spoof) 17]
			set bdp [lindex $options(--spoof) 18]
			set auth [lindex $options(--spoof) 1]
         
            log "Changing firmware version.txt & index.dat file"
            ::modify_devflash_file [file join dev_flash vsh etc version.txt] ::patch_vsh::version_txt
         
            log "Patching UPL.xml"
            ::modify_upl_file ::patch_vsh::upl_xml
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
			
			# if "--allow-unsigned-app" enabled, patch it
			if {$::patch_vsh::options(--allow-unsigned-app)} {
				# verified OFW ver. 3.55 - 4.46+
				# OFW 3.55 == 0x5FFEE8 (0x60FEE8)			
				# OFW 3.70 == 0x61A3C4 (0x62A3C4)  
				# OFW 4.46 == 0x5EA584 (0x5FA584)
				log "Patching [file tail $elf] to allow running of unsigned applications 1/2"         
				set search  "\xF8\x21\xFF\x81\x7C\x08\x02\xA6\x38\x61\x00\x70\xF8\x01\x00\x90\x4B\xFF\xFF\xE1\x38\x00\x00\x00"
				set replace "\x38\x60\x00\x01\x4E\x80\x00\x20"
				set offset 0
			 
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"        
			 
				# verified OFW ver. 3.55 - 4.46+
				# OFW 3.55 == 0x30A7C0 (0x31A7C0)			
				# OFW 3.70 == 0x31B55C (0x32B55C)  
				# OFW 4.46 == 0x241C2C (0x251C2C)
				log "Patching [file tail $elf] to allow running of unsigned applications 2/2"
				set search  "\xA0\x7F\x00\x04\x39\x60\x00\x01\x38\x03\xFF\x7F\x2B\xA0\x00\x01\x40\x9D\x00\x08\x39\x60\x00\x00"
				set replace "\x60\x00\x00\x00"
				set offset 20
			 
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"        
			}
			# if "--patch-vsh-react-psn-v2-4x" enabled, patch it
			if {$::patch_vsh::options(--patch-vsh-react-psn-v2-4x)} {
				# verified OFW ver. 3.55 - 4.46+
				# OFW 3.55 == 0x30B1D4 (0x31B1D4)			
				# OFW 3.70 == 0x31BF70 (0x250970)  
				# OFW 4.30 == 0x240974 (0x250974)
				# OFW 4.46 == 0x2425F0 (0x2525F0)
				log "Patching [file tail $elf] to allow unsigned act.dat & .rif files"          
			   #set search    "\x4B\xDC\x03\xA9" --- old value ---
			    set search    "\x4E\x80\x00\x20\x7C\x80\x23\x78\x78\x63\x00\x20\x2F\x80\x00\x00"
				append search "\x78\x84\x00\x20\x41\x9E\x00\x08\x4B\xFF\xFF"
				set replace   "\x38\x60\x00\x00"
				set offset 92
			 
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"        
			 
				# verified OFW ver. 3.55 - 4.46+
				# OFW 3.55 == 0x30AC64 (0x31AC64)			
				# OFW 3.70 == 0x31BA00 (0x32BA00)  
				# OFW 4.30 == 0x240400 (0x250400)
				# OFW 4.46 == 0x24207C (0x25207C)
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
			# if "--spoof-psn-passphrase" enabled, patch it
			if {$::patch_vsh::options(--spoof-psn-passphrase)} {
			
				log "Patching [file tail $elf] new passphrase for PSN access"            
				set search     "\x"
				append search  "\x"
				append search  "\x"
				set replace    "\x"
				append replace "\x"
				append replace "\x"
				set offset 0
				
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"        
			}
			# if "--spoof-new" enabled, patch it
			if {$::patch_vsh::options(--spoof-new) != ""} {
				variable options
				set release [lindex $::patch_vsh::options(--spoof-new) 0]
				set build [lindex $::patch_vsh::options(--spoof-new) 1]
			  
				log "Patching [file tail $elf] with new build/version number for PSN access"         
				debug "Patching build number"
				set search "[format %0.5d [::get_pup_build]]"
				set replace "[format %0.5d $build]"
				set offset 0
				
				# PATCH THE ELF BINARY
				catch_die {::patch_elf $elf $search $offset $replace} "Unable to patch self [file tail $elf]"
				
				debug "Patching version number"
				set search "99.99"
				set major [lindex [split $release "."] 0]
				set minor [lindex [split $release "."] 1]
				set replace "[format %0.2d ${major}].[format %0.2d ${minor}]\x00\x00\0x00\0x00"
				set offset 8
				
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

    proc version_txt {filename} {
        variable options
     
        set release [lindex $options(--spoof) 0]
        set build [lindex $options(--spoof) 1]
        set bdate [lindex $options(--spoof) 2]
        set target [lindex $options(--spoof) 3]
        set security [lindex $options(--spoof) 4]
        set system [lindex $options(--spoof) 5]
        set x3 [lindex $options(--spoof) 6]
        set paf [lindex $options(--spoof) 7]
        set vsh [lindex $options(--spoof) 8]
        set sys_jp [lindex $options(--spoof) 9]
        set ps1emu [lindex $options(--spoof) 10]
        set ps1netemu [lindex $options(--spoof) 11]
        set ps1newemu [lindex $options(--spoof) 12]
        set ps2emu [lindex $options(--spoof) 13]
        set ps2gxemu [lindex $options(--spoof) 14]
        set ps2softemu [lindex $options(--spoof) 15]
        set pspemu [lindex $options(--spoof) 16]
        set emerald [lindex $options(--spoof) 17]
        set bdp [lindex $options(--spoof) 18]
        set auth [lindex $options(--spoof) 1]
     
        set fd [open $filename r]
        set data [read $fd]
        close $fd
       
        if {$release != [get_fw_release $filename]} {
            set major [lindex [split $release "."] 0]
            set minor [lindex [split $release "."] 1]
            set nano "0"
            debug "Setting release to release:[format %0.2d ${major}].[format %0.2d ${minor}][format %0.2d ${nano}]:"
            set data [regsub {release:[0-9]+\.[0-9]+:} $data "release:[format %0.2d ${major}].[format %0.2d ${minor}][format %0.2d ${nano}]:"]
        }
     
        if {$build != [get_fw_build $filename]} {
            set build_num $build
            set build_date $bdate
            debug "Setting build to build:${build_num},${build_date}:"
           set data [regsub {build:[0-9]+,[0-9]+:} $data "build:${build_num},${build_date}:"]
        }
     
        if {$target != [get_fw_target $filename]} {
            set target_num [lindex [split $target ":"] 0]
            set target_string [lindex [split $target ":"] 1]
            debug "Setting target to target:${target_num}:${target_string}"
            set data [regsub {target:[0-9]+:[A-Z]+-ww} $data "target:${target_num}:${target_string}"]
        }
     
        if {$security != [get_fw_security $filename]} {
            set security_string [lindex [split $security ":"] 0]
            debug "Setting security to security:${security_string}:"
            set data [regsub {security:(.*?):} $data "security:${security_string}:"]
        }
     
        if {$system != [get_fw_system $filename]} {
            set system_string [lindex [split $system ":"] 0]
            debug "Setting system to system:${system_string}:"
            set data [regsub {system:(.*?):} $data "system:${system_string}:"]
        }
     
        if {$x3 != [get_fw_x3 $filename]} {
            set x3_string [lindex [split $x3 ":"] 0]
            debug "Setting x3 to x3:${x3_string}:"
            set data [regsub {x3:(.*?):} $data "x3:${x3_string}:"]
        }
     
        if {$paf != [get_fw_paf $filename]} {
            set paf_string [lindex [split $paf ":"] 0]
            debug "Setting paf to paf:${paf_string}:"
            set data [regsub {paf:(.*?):} $data "paf:${paf_string}:"]
        }
     
        if {$vsh != [get_fw_vsh $filename]} {
            set vsh_string [lindex [split $vsh ":"] 0]
            debug "Setting vsh to vsh:${vsh_string}:"
            set data [regsub {vsh:(.*?):} $data "vsh:${vsh_string}:"]
        }
     
        if {$sys_jp != [get_fw_sys_jp $filename]} {
            set sys_jp_string [lindex [split $sys_jp ":"] 0]
            debug "Setting sys_jp to sys_jp:${sys_jp_string}:"
            set data [regsub {sys_jp:(.*?):} $data "sys_jp:${sys_jp_string}:"]
        }
     
        if {$ps1emu != [get_fw_ps1emu $filename]} {
            set ps1emu_string [lindex [split $ps1emu ":"] 0]
            debug "Setting ps1emu to ps1emu:${ps1emu_string}:"
            set data [regsub {ps1emu:(.*?):} $data "ps1emu:${ps1emu_string}:"]
        }
     
        if {$ps1netemu != [get_fw_ps1netemu $filename]} {
            set ps1netemu_string [lindex [split $ps1netemu ":"] 0]
            debug "Setting ps1netemu to ps1netemu:${ps1netemu_string}:"
            set data [regsub {ps1netemu:(.*?):} $data "ps1netemu:${ps1netemu_string}:"]
        }
     
        if {$ps1newemu != [get_fw_ps1newemu $filename]} {
            set ps1newemu_string [lindex [split $ps1newemu ":"] 0]
            debug "Setting ps1newemu to ps1newemu:${ps1newemu_string}:"
            set data [regsub {ps1newemu:(.*?):} $data "ps1newemu:${ps1newemu_string}:"]
        }
     
        if {$ps2emu != [get_fw_ps2emu $filename]} {
            set ps2emu_string [lindex [split $ps2emu ":"] 0]
            debug "Setting ps2emu to ps2emu:${ps2emu_string}:"
            set data [regsub {ps2emu:(.*?):} $data "ps2emu:${ps2emu_string}:"]
        }
     
        if {$ps2gxemu != [get_fw_ps2gxemu $filename]} {
            set ps2gxemu_string [lindex [split $ps2gxemu ":"] 0]
            debug "Setting ps2gxemu to ps2gxemu:${ps2gxemu_string}:"
            set data [regsub {ps2gxemu:(.*?):} $data "ps2gxemu:${ps2gxemu_string}:"]
        }
     
        if {$ps2softemu != [get_fw_ps2softemu $filename]} {
            set ps2softemu_string [lindex [split $ps2softemu ":"] 0]
            debug "Setting ps2softemu to ps2softemu:${ps2softemu_string}:"
            set data [regsub {ps2softemu:(.*?):} $data "ps2softemu:${ps2softemu_string}:"]
        }
     
        if {$pspemu != [get_fw_pspemu $filename]} {
            set pspemu_string [lindex [split $pspemu ":"] 0]
            debug "Setting pspemu to pspemu:${pspemu_string}:"
            set data [regsub {pspemu:(.*?):} $data "pspemu:${pspemu_string}:"]
        }
     
        if {$emerald != [get_fw_emerald $filename]} {
            set emerald_string [lindex [split $emerald ":"] 0]
            debug "Setting emeral to emerald:${emerald_string}:"
            set data [regsub {emerald:(.*?):} $data "emerald:${emerald_string}:"]
        }
     
        if {$bdp != [get_fw_bdp $filename]} {
            set bdp_string [lindex [split $bdp ":"] 0]
            debug "Setting bdp to bdp:${bdp_string}:"
            set data [regsub {bdp:(.*?):} $data "bdp:${bdp_string}:"]
        }
     
        if {$auth != [get_fw_auth $filename]} {
            debug "Setting auth to auth:$auth:"
            set data [regsub {auth:[0-9]+:} $data "auth:$auth:"]
        }
     
        set fd [open $filename w]
        puts -nonewline $fd $data
        close $fd
     
        set index_dat [file join [file dirname $filename] index.dat]
        shell "dat" [file nativename $filename] [file nativename $index_dat]
    }

    proc upl_xml {filename} {
        variable options
     
        set release [lindex $options(--spoof) 0]
        set build [lindex $options(--spoof) 1]
        set bdate [lindex $options(--spoof) 2]
        set major [lindex [split $release "."] 0]
        set minor [lindex [split $release "."] 1]
        set nano "0"
     
        debug "Setting UPL.xml.pkg :: release to ${release} :: build to ${build},${bdate}"
     
        set search [::get_header_key_upl_xml $filename Version Version]
        set replace "[format %0.2d ${major}].[format %0.2d ${minor}][format %0.2d ${nano}]:"
        if { $search != "" && $search != $replace } {
            set xml [::set_header_key_upl_xml $filename Version "${replace}" Version]
            if { $xml == "" } {
                die "spoof failed:: search: $search :: replace: $replace"
            }
        }
     
        set search [::get_header_key_upl_xml $filename Build Build]
        set replace "${build},${bdate}"
        if { $search != "" && $search != $replace } {
            set xml [::set_header_key_upl_xml $filename Build "${replace}" Build]
            if { $xml == "" } {
                die "spoof failed:: search: $search :: replace: $replace"
            }
        }
     
        if {$::patch_pup::options(--pup-build) == ""} {
            ::set_pup_build [incr build]
        }
    }
   
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