#!/usr/bin/tclsh
#
# ps3mfw -- PS3 MFW creator
#
# Copyright (C) Anonymous Developers (Code Monkeys)
#
# This software is distributed under the terms of the GNU General Public
# License ("GPL") version 3, as published by the Free Software Foundation.
#

# Notes: use only official REBUG files (3.55.2.PUP/Update0.X.PKG)

# Priority: 119
# Description: PATCH: Patch REBUG All-In-One Task

# Option --vsh-self: vsh.self EDAT file
# Option --vsh-cexsp: vsh.self.cexsp EDAT file
# Option --vsh-swp: vsh.self.swp EDAT file
# Option --index-dat: index.dat.swp file
# Option --version-txt: version.txt.swp file
# Option --rebug-sel: Rebug_Selector_1.6.1 file
# Option --bd-emu: BDEMU2.pkg file
# Option --patch-lv1-checks: Disable SYSCON-Checks for safe Hardware Downgrade   (aka Rogero v2 "NO_CHECK.PUP")
# Option --patch-playstation-com: Patch communication to playstation.com
# Option --patch-playstation-net: Patch communication to playstation.net		LEAVE IT for some PSN Games!!!)
# Option --patch-playstation-org: Patch communication to playstation.org
# Option --patch-sony: Patch communication to sony.[com|co.jp]
# Option --patch-bitwallet: Patch communication to bitwallet.co.jp
# Option --patch-qriocity: Patch communication to qriocity.com
# Option --patch-trendmicro: Patch communication to trendmicro.com
# Option --patch-allmusic: Patch communication to allmusic.com
# Option --patch-intertrust: Patch communication to intertrust.com
# Option --patch-marlin-drm: Patch communication to marlin-drm.com
# Option --patch-marlin-tmo: Patch communication to marlin-tmo.com
# Option --patch-oasis-open: Patch communication to oasis-open.org
# Option --patch-octopus-drm: Patch communication to octopus-drm.com
# Option --allow-offline-activation: reActPSN 2.0 Patch to allow Offline PSN-Content Activation

# Type --vsh-self: file open {"SELF EDAT" {self}}
# Type --vsh-cexsp: file open {"SELF EDAT" {cexsp}}
# Type --vsh-swp: file open {"SELF EDAT" {self.swp}}
# Type --index-dat: file open {"index dat" {dat.swp}}
# Type --version-txt: file open {"version txt" {txt.swp}}
# Type --rebug-sel: file open {"pkg file" {pkg}}
# Type --bd-emu: file open {"pkg file" {pkg}}
# Type --patch-lv1-checks: boolean
# Type --patch-playstation-com: boolean
# Type --patch-playstation-net: boolean
# Type --patch-playstation-org: boolean
# Type --patch-sony: boolean
# Type --patch-bitwallet: boolean
# Type --patch-qriocity: boolean
# Type --patch-trendmicro: boolean
# Type --patch-allmusic: boolean
# Type --patch-intertrust: boolean
# Type --patch-marlin-drm: boolean
# Type --patch-marlin-tmo: boolean
# Type --patch-oasis-open: boolean
# Type --patch-octopus-drm: boolean
# Type --allow-offline-activation: combobox {{REBUG 3.41} {REBUG 3.55}}

namespace eval ::rebug_update_pkg {

    array set ::rebug_update_pkg::options {
        --vsh-self "path/to/replacement"
        --vsh-cexsp "path/to/replacement"
        --vsh-swp "path/to/replacement"
        --index-dat "path/to/replacement"
        --version-txt "path/to/replacement"
        --rebug-sel "path/to/replacement"
        --bd-emu "path/to/replacement"
		--patch-lv1-checks true
        --patch-allmusic true
        --patch-bitwallet true
        --patch-intertrust true
        --patch-marlin-drm true
        --patch-marlin-tmo true
        --patch-oasis-open true
        --patch-octopus-drm true
        --patch-playstation-net false
        --patch-playstation-com true
        --patch-playstation-org true
        --patch-qriocity true
        --patch-sony true
        --patch-trendmicro true
        --allow-offline-activation "Select Firmware"
    }
    proc main {} {
        variable options
        set self [file join dev_flash vsh module vsh.self]
        set cexsp [file join dev_flash vsh module vsh.self.cexsp]
        set swp [file join dev_flash vsh module vsh.self.swp]
        set dat [file join dev_flash vsh etc index.dat.swp]
        set txt [file join dev_flash vsh etc version.txt.swp]
        set rbgpkg [file join dev_flash rebug packages Rebug_Selector_1.6.pkg]
        set bdemu [file join dev_flash rebug packages BDEMU.pkg]
        if {[file exists $options(--vsh-self)] == 0 } {
            log "Skipping vsh, $options(--vsh-self) does not exist"
        } else {
            ::modify_devflash_file ${self} ::rebug_update_pkg::copy_devflash_file $::rebug_update_pkg::options(--vsh-self)
        }
        if {[file exists $options(--vsh-cexsp)] == 0 } {
            log "Skipping cexsp, $options(--vsh-cexsp) does not exist"
        } else {
            ::modify_devflash_file ${cexsp} ::rebug_update_pkg::copy_devflash_file $::rebug_update_pkg::options(--vsh-cexsp)
        }
        if {[file exists $options(--vsh-swp)] == 0 } {
            log "Skipping swp, $options(--vsh-swp) does not exist"
        } else {
            ::modify_devflash_file ${swp} ::rebug_update_pkg::copy_devflash_file $::rebug_update_pkg::options(--vsh-swp)
        }
        if {[file exists $options(--index-dat)] == 0 } {
            log "Skipping dat, $options(--index-dat) does not exist"
        } else {
            ::modify_devflash_file ${dat} ::rebug_update_pkg::copy_devflash_file $::rebug_update_pkg::options(--index-dat)
        }
        if {[file exists $options(--version-txt)] == 0 } {
            log "Skipping txt, $options(--version-txt) does not exist"
        } else {
            ::modify_devflash_file ${txt} ::rebug_update_pkg::copy_devflash_file $::rebug_update_pkg::options(--version-txt)
        }
        if {[file exists $options(--rebug-sel)] == 0 } {
            log "Skipping rbgpkg, $options(--rebug-sel) does not exist"
        } else {
            ::modify_devflash_file ${rbgpkg} ::rebug_update_pkg::copy_devflash_file $::rebug_update_pkg::options(--rebug-sel)
        }
        if {[file exists $options(--bd-emu)] == 0 } {
            log "Skipping bdemu, $options(--bd-emu) does not exist"
        } else {
            ::modify_devflash_file ${bdemu} ::rebug_update_pkg::copy_devflash_file $::rebug_update_pkg::options(--bd-emu)
        }
        if {$::rebug_update_pkg::options(--patch-lv1-checks)} {
            set self "lv1.self"
			set path $::CUSTOM_COSUNPKG_DIR
			set file [file join $path $self]			
			## go do the lv1.self patches
            ::rebug_update_pkg::patch_lv1_self $file
        }
        if {$::rebug_update_pkg::options(--patch-allmusic)} {
            set selfs {x3_amgsdk.sprx}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_allmusic_com_self
        }
        if {$::rebug_update_pkg::options(--patch-bitwallet)} {
            set selfs {edy_plugin.sprx}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_bitwallet_co_jp_self
        }
        if {$::rebug_update_pkg::options(--patch-intertrust)} {
            set selfs {mcore.self msmw2.sprx}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_intertrust_com_self
        }
        if {$::rebug_update_pkg::options(--patch-marlin-drm)} {
            set selfs {mcore.self}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_marlin-drm_com_self
        }
        if {$::rebug_update_pkg::options(--patch-marlin-tmo)} {
            set selfs {mcore.self msmw2.sprx}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_marlin-tmo_com_self
        }
        if {$::rebug_update_pkg::options(--patch-oasis-open)} {
            set selfs {mcore.self msmw2.sprx}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_oasis-open_org_self
        }
        if {$::rebug_update_pkg::options(--patch-octopus-drm)} {
            set selfs {mcore.self msmw2.sprx}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_octopus-drm_com_self
        }
        if {$::rebug_update_pkg::options(--patch-playstation-com)} {
            set selfs {netconf_plugin.sprx sysconf_plugin.sprx sysconf_plugin.sprx.dex}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_playstation_com_self
        }
        if {$::rebug_update_pkg::options(--patch-playstation-net)} {
        set selfs {libad_core.sprx libmedi.sprx libsysutil_np_clans.sprx libsysutil_np_commerce2.sprx libsysutil_np_util.sprx}
            ::modify_devflash_files [file join dev_flash sys external] $selfs ::rebug_update_pkg::patch_playstation_net_self

        set selfs {autodownload_plugin.sprx download_plugin.sprx esehttp.sprx eula_cddb_plugin.sprx eula_hcopy_plugin.sprx eula_net_plugin.sprx explore_category_friend.sprx explore_category_game.sprx explore_category_music.sprx explore_category_network.sprx explore_category_photo.sprx explore_category_psn.sprx explore_category_sysconf.sprx explore_category_tv.sprx explore_category_user.sprx explore_category_video.sprx explore_plugin.sprx explore_plugin_ft.sprx explore_plugin_np.sprx friendtrophy_plugin.sprx game_ext_plugin.sprx hknw_plugin.sprx nas_plugin.sprx newstore_plugin.sprx np_eula_plugin.sprx np_trophy_plugin.sprx np_trophy_util.sprx photo_network_sharing_plugin.sprx profile_plugin.sprx regcam_plugin.sprx sysconf_plugin.sprx sysconf_plugin.sprx.dex videoeditor_plugin.sprx videoplayer_plugin.sprx videoplayer_util.sprx vsh.self vsh.self.swp vsh.self.cexsp x3_mdimp11.sprx x3_mdimp7.sprx}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_playstation_net_self
        }
        if {$::rebug_update_pkg::options(--patch-playstation-org)} {
            set selfs {netconf_plugin.sprx sysconf_plugin.sprx sysconf_plugin.sprx.dex}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_playstation_org_self
        }
        if {$::rebug_update_pkg::options(--patch-qriocity)} {
            set selfs {regcam_plugin.sprx}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_qriocity_com_self
        }
        if {$::rebug_update_pkg::options(--patch-sony)} {
            set selfs {eula_net_plugin.sprx mintx_client.sprx}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_sony_com_self
        }
        if {$::rebug_update_pkg::options(--patch-sony)} {
            set selfs {videodownloader_plugin.sprx}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_sony_co_jp_self
        }
        if {$::rebug_update_pkg::options(--patch-trendmicro)} {
            set selfs {silk.sprx silk_nas.sprx}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_trendmicro_com_self
        }
		if {$::rebug_update_pkg::options(--allow-offline-activation) == "REBUG 3.41"} {
            set self {vsh.self.cexsp}
            ::modify_devflash_files [file join dev_flash vsh module] $self ::rebug_update_pkg::patch_341retail_self
            set selfs {vsh.self vsh.self.swp}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_341debug_selfs
		}
		if {$::rebug_update_pkg::options(--allow-offline-activation) == "REBUG 3.55"} {
            set self {vsh.self.cexsp}
            ::modify_devflash_files [file join dev_flash vsh module] $self ::rebug_update_pkg::patch_355retail_self
            set selfs {vsh.self vsh.self.swp}
            ::modify_devflash_files [file join dev_flash vsh module] $selfs ::rebug_update_pkg::patch_355debug_selfs
		}
    }
    proc copy_devflash_file { dst src } {
        if {[file exists $src] == 0} {
            die "$src does not exist"
        } else {
            if {[file exists $dst] == 0} {
                die "$dst does not exist"
            } else {
                log "Replacing default devflash file [file tail $dst] with updated [file tail $src]"
                copy_file -force $src $dst
            }
        }
    }
    proc patch_lv1_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_lv1_elf
    }
    proc patch_allmusic_com_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_allmusic_com_elf
    }
    proc patch_bitwallet_co_jp_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_bitwallet_co_jp_elf
    }
    proc patch_intertrust_com_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_intertrust_com_elf
    }
    proc patch_marlin-drm_com_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_marlin-drm_com_elf
    }
    proc patch_marlin-tmo_com_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_marlin-tmo_com_elf
    }
    proc patch_oasis-open_org_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_oasis-open_org_elf
    }
    proc patch_octopus-drm_com_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_octopus-drm_com_elf
    }
    proc patch_playstation_com_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_playstation_com_elf
    }
    proc patch_playstation_net_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_playstation_net_elf
    }
    proc patch_playstation_org_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_playstation_org_elf
    }
    proc patch_qriocity_com_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_qriocity_com_elf
    }
    proc patch_sony_com_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_sony_com_elf
    }
    proc patch_sony_co_jp_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_sony_co_jp_elf
    }
    proc patch_trendmicro_com_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_trendmicro_com_elf
    }
    proc patch_341retail_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_341retail_elf
    }
    proc patch_341debug_selfs {selfs} {
        ::modify_self_file $selfs ::rebug_update_pkg::patch_341debug_elfs
    }
    proc patch_355retail_self {self} {
        ::modify_self_file $self ::rebug_update_pkg::patch_355retail_elf
    }
    proc patch_355debug_selfs {selfs} {
        ::modify_self_file $selfs ::rebug_update_pkg::patch_355debug_elfs
    }
    proc patch_lv1_elf {elf} {
        if {$::rebug_update_pkg::options(--patch-lv1-checks)} {
            log "Patching LV1 Checks"
            # ss_server1
            # Patch core OS Hash check // product mode always on
            log "--------------- Patching  ss_server1.fself ----------------------------"
            log "Patch core OS Hash check // product mode always on"
            set search "\x41\x9E\x00\x1C\x7F\x63\xDB\x78\xE8\xA2\x85\x68\x38\x80\x00\x01"
            set replace "\x60\x00\x00\x00\x7F\x63\xDB\x78\xE8\xA2\x85\x68\x38\x80\x00\x01"
            catch_die {::patch_elf $elf $search 0 $replace} "Unable to patch self [file tail $elf]"
            # Patch check_revoke_list_hash check // product mode always on
            log "Patch check_revoke_list_hash check // product mode always on"
            set search "\x41\x9E\x00\x1C\x7F\xA3\xEB\x78\xE8\xA2\x85\x68\x38\x80\x00\x01"
            set replace "\x60\x00\x00\x00\x7F\xA3\xEB\x78\xE8\xA2\x85\x68\x38\x80\x00\x01"
            catch_die {::patch_elf $elf $search 0 $replace} "Unable to patch self [file tail $elf]"
            # In product mode erase standby bank skipped
            log "Patch In product mode erase standby bank skipped" 
            set search "\x41\x9E\x00\x0C\xE8\xA2\x8A\x38\x48\x00\x00\xCC\x7B\xFD\x00\x20"
            set replace "\x60\x00\x00\x00\xE8\xA2\x8A\x38\x48\x00\x00\xCC\x7B\xFD\x00\x20"
            catch_die {::patch_elf $elf $search 0 $replace} "Unable to patch self [file tail $elf]"  
            # Patching System Manager to disable integrity check
            log "Patching System Manager to disable integrity check"
            set search  "\x38\x60\x00\x01\xf8\x01\x00\x90\x88\x1f\x00\x00\x2f\x80\x00\x00"
            set replace "\x38\x60\x00\x00"
            catch_die {::patch_elf $elf $search 0 $replace} "Unable to patch self [file tail $elf]"  
            # Patching LV1 to enable skipping of ACL checks for all storage devices
            log "Patching LV1 to enable skipping of ACL checks for all storage devices"
            set search  "\x54\x63\x06\x3e\x2f\x83\x00\x00\x41\x9e\x00\x14\xe8\x01\x00\x70\x54\x00\x07\xfe"
            append search "\x2f\x80\x00\x00\x40\x9e\x00\x18"
            set replace "\x38\x60\x00\x01\x2f\x83\x00\x00\x41\x9e\x00\x14\x38\x00\x00\x01"
            catch_die {::patch_elf $elf $search 0 $replace} "Unable to patch self [file tail $elf]" 
            # LV1 0021D0B4@355 patch (?Patch sys_mgr integrity lv1 and lv0 integrity check?)
            log "Patch sys_mgr integrity lv1 and lv0 integrity check" 
            set search "\x48\x00\xD7\x15\x2F\x83\x00\x00\x38\x60\x00\x01"
            set replace "\x38\x60\x00\x00\x2F\x83\x00\x00\x38\x60\x00\x01"
            catch_die {::patch_elf $elf $search 0 $replace} "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_playstation_com_elf {elf} {
        if {$::rebug_update_pkg::options(--patch-playstation-com)} {
            log "Patching [file tail $elf] to disable communication with playstation.com"
#           playstation.com
            set search  "\x70\x6c\x61\x79\x73\x74\x61\x74\x69\x6f\x6e\x2e\x63\x6f\x6d"
#           aaaaaaaaaaa.com
            set replace "\x61\x61\x61\x61\x61\x61\x61\x61\x61\x61\x61\x2e\x63\x6f\x6d"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_playstation_net_elf {elf} {
        if {$::rebug_update_pkg::options(--patch-playstation-net)} {
            log "Patching [file tail $elf] to disable communication with playstation.net"
#           playstation.net
            set search  "\x70\x6c\x61\x79\x73\x74\x61\x74\x69\x6f\x6e\x2e\x6e\x65\x74"
#           aaaaaaaaaaa.net
            set replace "\x61\x61\x61\x61\x61\x61\x61\x61\x61\x61\x61\x2e\x6e\x65\x74"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
#           playstation.net
            set search  "\x70\x00\x6c\x00\x61\x00\x79\x00\x73\x00\x74\x00\x61\x00\x74\x00\x69\x00\x6f\x00\x6e\x00\x2e\x00\x6e\x00\x65\x00\x74"
#           aaaaaaaaaaa.net
            set replace "\x61\x00\x61\x00\x61\x00\x61\x00\x61\x00\x61\x00\x61\x00\x61\x00\x61\x00\x61\x00\x61\x00\x2e\x00\x6e\x00\x65\x00\x74"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_playstation_org_elf {elf} {
        if {$::rebug_update_pkg::options(--patch-playstation-org)} {
            log "Patching [file tail $elf] to disable communication with playstation.org"
#           playstation.org
            set search  "\x70\x6c\x61\x79\x73\x74\x61\x74\x69\x6f\x6e\x2e\x6f\x72\x67"
#           aaaaaaaaaaa.org
            set replace "\x61\x61\x61\x61\x61\x61\x61\x61\x61\x61\x61\x2e\x6f\x72\x67"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_sony_com_elf {elf} {
        if {$::rebug_update_pkg::options(--patch-sony)} {
            log "Patching [file tail $elf] to disable communication with sony.com"
#           sony.com
            set search  "\x73\x6f\x6e\x79\x2e\x63\x6f\x6d"
#           aaaa.com
            set replace "\x61\x61\x61\x61\x2e\x63\x6f\x6d"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_sony_co_jp_elf {elf} {
        if {$::rebug_update_pkg::options(--patch-sony)} {
            log "Patching [file tail $elf] to disable communication with sony.co.jp"
#           sony.co.jp
            set search  "\x73\x6f\x6e\x79\x2e\x63\x6f\x2e\x6a\x70"
#           aaaa.co.jp
            set replace "\x61\x61\x61\x61\x2e\x63\x6f\x2e\x6a\x70"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_bitwallet_co_jp_elf {elf} {
        if {$::rebug_update_pkg::options(--patch-bitwallet)} {
            log "Patching [file tail $elf] to disable communication with bitwallet.co.jp"
#           bitwallet.co.jp
            set search  "\x62\x69\x74\x77\x61\x6c\x6c\x65\x74\x2e\x63\x6f\x2e\x6a\x70"
#           aaaaaaaaa.co.jp
            set replace "\x61\x61\x61\x61\x61\x61\x61\x61\x61\x2e\x63\x6f\x2e\x6a\x70"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_qriocity_com_elf {elf} {
        if {$::rebug_update_pkg::options(--patch-qriocity)} {
            log "Patching [file tail $elf] to disable communication with qriocity.com"
#           qriocity.com
            set search  "\x71\x72\x69\x6f\x63\x69\x74\x79\x2e\x63\x6f\x6d"
#           aaaaaaaa.com
            set replace "\x61\x61\x61\x61\x61\x61\x61\x61\x2e\x63\x6f\x6d"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_trendmicro_com_elf {elf} {
        if {$::rebug_update_pkg::options(--patch-trendmicro)} {
            log "Patching [file tail $elf] to disable communication with trendmicro.com"
#           trendmicro.com
            set search  "\x74\x72\x65\x6e\x64\x6d\x69\x63\x72\x6f\x2e\x63\x6f\x6d"
#           aaaaaaaaaa.com
            set replace "\x61\x61\x61\x61\x61\x61\x61\x61\x61\x61\x2e\x63\x6f\x6d"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_allmusic_com_elf {elf} {
        if {$::rebug_update_pkg::options(--patch-allmusic)} {
            log "Patching [file tail $elf] to disable communication with allmusic.com"
#           allmusic.com
            set search  "\x61\x6c\x6c\x6d\x75\x73\x69\x63\x2e\x63\x6f\x6d"
#           aaaaaaaa.com
            set replace "\x61\x61\x61\x61\x61\x61\x61\x61\x2e\x63\x6f\x6d"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_intertrust_com_elf {elf} {
        if {$::rebug_update_pkg::options(--patch-intertrust)} {
            log "Patching [file tail $elf] to disable communication with intertrust.com"
#           intertrust.com
            set search  "\x69\x6e\x74\x65\x72\x74\x72\x75\x73\x74\x2e\x63\x6f\x6d"
#           aaaaaaaaaa.com
            set replace "\x61\x61\x61\x61\x61\x61\x61\x61\x61\x61\x2e\x63\x6f\x6d"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_marlin-tmo_com_elf {elf} {
        if {$::rebug_update_pkg::options(--patch-marlin-tmo)} {
            log "Patching [file tail $elf] to disable communication with marlin-tmo.com"
#           marlin-tmo.com
            set search  "\x6d\x61\x72\x6c\x69\x6e\x2d\x74\x6d\x6f\x2e\x63\x6f\x6d"
#           aaaaaaaaaa.com
            set replace "\x61\x61\x61\x61\x61\x61\x61\x61\x61\x61\x2e\x63\x6f\x6d"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_marlin-drm_com_elf {elf} {
        if {$::rebug_update_pkg::options(--patch-marlin-drm)} {
            log "Patching [file tail $elf] to disable communication with marlin-drm.com"
#           marlin-drm.com
            set search  "\x6d\x61\x72\x6c\x69\x6e\x2d\x64\x72\x6d\x2e\x63\x6f\x6d"
#           aaaaaaaaaa.com
            set replace "\x61\x61\x61\x61\x61\x61\x61\x61\x61\x61\x2e\x63\x6f\x6d"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_oasis-open_org_elf {elf} {
        if {$::rebug_update_pkg::options(--patch-oasis-open)} {
            log "Patching [file tail $elf] to disable communication with oasis-open.org"
#           oasis-open.org
            set search  "\x6f\x61\x73\x69\x73\x2d\x6f\x70\x65\x6e\x2e\x6f\x72\x67"
#           aaaaaaaaaa.org
            set replace "\x61\x61\x61\x61\x61\x61\x61\x61\x61\x61\x2e\x6f\x72\x67"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_octopus-drm_com_elf {elf} {
        if {$::rebug_update_pkg::options(--patch-octopus-drm)} {
            log "Patching [file tail $elf] to disable communication with octopus-drm.com"
#           octopus-drm.com
            set search  "\x6f\x63\x74\x6f\x70\x75\x73\x2d\x64\x72\x6d\x2e\x63\x6f\x6d"
#           aaaaaaaaaaa.com
            set replace "\x61\x61\x61\x61\x61\x61\x61\x61\x61\x61\x61\x2e\x63\x6f\x6d"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_341retail_elf {elf} {
		if {$::rebug_update_pkg::options(--allow-offline-activation) == "REBUG 3.41"} {
            log "Patching REBUG 3.41 [file tail $elf] to allow Offline PSN-Activation"
#           allow unsigned act.dat
            set search "\x4B\xCF\xAF\xB1"
            set replace "\x38\x60\x00\x00"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
#           disable deletion of act.dat
            set search "\x48\x31\x43\xAD"
            set replace "\x38\x60\x00\x00"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_341debug_elfs {elfs} {
		if {$::rebug_update_pkg::options(--allow-offline-activation) == "REBUG 3.41"} {
            log "Patching REBUG 3.41 [file tail $elfs] to allow Offline PSN-Activation"
#           allow unsigned act.dat
            set search  "\x4B\xCF\x3E\x99"
            set replace "\x38\x60\x00\x00"
            catch_die {::patch_file_multi $elfs $search 0 $replace} \
                "Unable to patch self [file tail $elfs]"
#           disable deletion of act.dat
            set search  "\x48\x31\x47\x1D"
            set replace "\x38\x60\x00\x00"
            catch_die {::patch_file_multi $elfs $search 0 $replace} \
                "Unable to patch self [file tail $elfs]"
        }
    }
    proc patch_355retail_elf {elf} {
		if {$::rebug_update_pkg::options(--allow-offline-activation) == "REBUG 3.55"} {
            log "Patching REBUG 3.55 [file tail $elf] to allow Offline PSN-Activation"
#           allow unsigned act.dat
            set search  "\x4B\xCF\x5B\x45"
            set replace "\x38\x60\x00\x00"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
#           disable deletion of act.dat
            set search  "\x48\x31\xB4\x65"
            set replace "\x38\x60\x00\x00"
            catch_die {::patch_file_multi $elf $search 0 $replace} \
                "Unable to patch self [file tail $elf]"
        }
    }
    proc patch_355debug_elfs {elfs} {
		if {$::rebug_update_pkg::options(--allow-offline-activation) == "REBUG 3.55"} {
            log "Patching REBUG 3.55 [file tail $elfs] to allow Offline PSN-Activation"
#           allow unsigned act.dat
            set search  "\x4B\xCE\xEA\x6D"
            set replace "\x38\x60\x00\x00"
            catch_die {::patch_file_multi $elfs $search 0 $replace} \
                "Unable to patch self [file tail $elfs]"
#           disable deletion of act.dat
            set search  "\x48\x31\xB7\xD5"
            set replace "\x38\x60\x00\x00"
            catch_die {::patch_file_multi $elfs $search 0 $replace} \
                "Unable to patch self [file tail $elfs]"
        }
    }
}