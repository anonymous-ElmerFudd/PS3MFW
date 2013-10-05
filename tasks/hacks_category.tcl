#!/usr/bin/tclsh
#
# ps3mfw -- PS3 MFW creator
#
# Copyright (C) Anonymous Developers (Code Monkeys)
#
# This software is distributed under the terms of the GNU General Public
# License ("GPL") version 3, as published by the Free Software Foundation.
#

# Priority: 400
# Description: MISC: Add "Hacks" category to the XMB

# Option --hacks-cat: Category to replace
    
# Type --hacks-cat: combobox {{Users} {Photo} {Music} {Video} {TV} {Game} {Network} {PlayStation® Network} {Friends}}


namespace eval ::hacks_category {

    array set ::hacks_category::options {
        --hacks-cat "Category"
    }

    proc main {} {
	    set CATEGORY_TV_XML [file join dev_flash vsh resource explore xmb category_tv.xml]
		set CATEGORY_GAME_TOOL2_XML [file join dev_flash vsh resource explore xmb category_game_tool2.xml]
		set EXPLORE_PLUGIN_FULL_RCO [file join dev_flash vsh resource explore_plugin_full.rco]
		set XMB_INGAME_RCO [file join dev_flash vsh resource xmb_ingame.rco]
		
		if {$::hacks_category::options(--hacks-cat) == "Users"} {
			set CATEGORY_XML [file join dev_flash vsh resource explore xmb category_user.xml]
		}
		
		if {$::hacks_category::options(--hacks-cat) == "Photo"} {
			set CATEGORY_XML [file join dev_flash vsh resource explore xmb category_photo.xml]
		}

		if {$::hacks_category::options(--hacks-cat) == "Music"} {
			set CATEGORY_XML [file join dev_flash vsh resource explore xmb category_music.xml]
		}
		
		if {$::hacks_category::options(--hacks-cat) == "Video"} {
			set CATEGORY_XML [file join dev_flash vsh resource explore xmb category_video.xml]
		}
		
		if {$::hacks_category::options(--hacks-cat) == "TV"} {
			set CATEGORY_XML [file join dev_flash vsh resource explore xmb category_tv.xml]
			set XMB_PLUGIN [file join dev_flash vsh module xmb_plugin.sprx]
			modify_devflash_file $XMB_PLUGIN ::hacks_category::patch_self
		}
		
		if {$::hacks_category::options(--hacks-cat) == "Game"} {
			set CATEGORY_XML [file join dev_flash vsh resource explore xmb category_game.xml]
		}
		
		if {$::hacks_category::options(--hacks-cat) == "Network"} {
			set CATEGORY_XML [file join dev_flash vsh resource explore xmb category_network.xml]
		}
		
		if {$::hacks_category::options(--hacks-cat) == "PlayStation® Network"} {
			set CATEGORY_XML [file join dev_flash vsh resource explore xmb category_psn.xml]
		}
		
		if {$::hacks_category::options(--hacks-cat) == "Friends"} {
			set CATEGORY_XML [file join dev_flash vsh resource explore xmb category_friend.xml]
		}
		
		modify_devflash_file $CATEGORY_TV_XML ::hacks_category::find_nodes
        modify_devflash_file $CATEGORY_GAME_TOOL2_XML ::hacks_category::find_nodes_2
        modify_devflash_file $CATEGORY_XML ::hacks_category::inject_nodes
		modify_rco_file $EXPLORE_PLUGIN_FULL_RCO ::hacks_category::callback_hacks
		modify_rco_file $XMB_INGAME_RCO ::hacks_category::callback_hacks
	}
	
    proc patch_self {self} {
        log "Patching [file tail $self]"
        ::modify_self_file $self ::hacks_category::patch_elf
    }

    proc patch_elf {elf} {
	
		log "Patching [file tail $elf] to add tv category"
		set search  "\x64\x65\x76\x5f\x68\x64\x64\x30\x2f\x67\x61\x6d\x65\x2f\x42\x43\x45\x53\x30\x30\x32\x37\x35"
		set replace "\x64\x65\x76\x5f\x66\x6c\x61\x73\x68\x2f\x64\x61\x74\x61\x2f\x63\x65\x72\x74\x00\x00\x00\x00"

		catch_die {::patch_elf $elf $search 0 $replace} \
			"Unable to patch self [file tail $elf]"
    }
	
	proc find_nodes { file } {
        log "Parsing XML: [file tail $file]"
        set xml [::xml::LoadFile $file]
		set ::XMBML [::xml::GetNodeByAttribute $xml "XMBML" version "1.0"]    
		if {$::XMBML == ""} {
			die "Could not parse $file"
		}
    }
	
	proc find_nodes_2 { file } {
        log "Parsing XML: [file tail $file]"
        set xml [::xml::LoadFile $file]
		set ::query_package_files [::xml::GetNodeByAttribute $xml "XMBML:View:Items:Query" key "seg_package_files"]
		set ::view_package_files [::xml::GetNodeByAttribute $xml "XMBML:View" id "seg_package_files"]
		set ::view_packages [::xml::GetNodeByAttribute $xml "XMBML:View" id "seg_packages"]

		if {$::query_package_files == "" || $::view_package_files == "" || $::view_packages == "" } {
			die "Could not parse $file"
		}

		set ::query_gamedebug [::xml::GetNodeByAttribute $xml "XMBML:View:Items:Query" key "seg_gamedebug"]
		set ::view_gamedebug [::xml::GetNodeByAttribute $xml "XMBML:View" id "seg_gamedebug"]

		if {$::query_gamedebug == "" || $::view_gamedebug== "" } {
			die "Could not parse $file"
		}
    }
    
    proc inject_nodes { file } {
        log "Modifying XML: [file tail $file]"
        set xml [::xml::LoadFile $file]		
		set xml [::xml::ReplaceNode $xml [::xml::GetNodeIndicesByAttribute $xml "XMBML" version "1.0"] $::XMBML]
		set xml [::xml::InsertNode $xml [::xml::GetNodeIndicesByAttribute $xml "XMBML:View:Items:Query" key "seg_gameexit"] $::query_package_files]
		set xml [::xml::InsertNode $xml {2 end 0} $::view_package_files]
		set xml [::xml::InsertNode $xml {2 end 0} $::view_packages]
		set xml [::xml::InsertNode $xml [::xml::GetNodeIndicesByAttribute $xml "XMBML:View:Items:Query" key "seg_gameexit"] $::query_gamedebug]
		set xml [::xml::InsertNode $xml {2 end 0} $::view_gamedebug]

		unset ::query_package_files
		unset ::view_package_files
		unset ::view_packages
		unset ::query_gamedebug
		unset ::view_gamedebug
        ::xml::SaveToFile $xml $file
    }	
	proc callback_hacks {path args} {		
		log "Patching English.xml into [file tail $path]"
		sed_in_place [file join $path English.xml] $::hacks_category::options(--hacks-cat) hacks	
	}
}