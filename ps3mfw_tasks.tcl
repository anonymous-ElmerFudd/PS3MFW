#!/usr/bin/tclsh
#
# ps3mfw -- PS3 MFW creator
#
# Copyright (C) Anonymous Developers (Code Monkeys)
#
# This software is distributed under the terms of the GNU General Public
# License ("GPL") version 3, as published by the Free Software Foundation.
#

proc ego {} {
    puts "PS3MFW Creator v${::PS3MFW_VERSION}"
    puts "    Copyright (C) 2011 Project PS3MFW"
    puts "    This program comes with ABSOLUTELY NO WARRANTY;"
    puts "    This is free software, and you are welcome to redistribute it"
    puts "    under certain conditions; see COPYING for details."
    puts ""
    puts "    Developed By :"
    puts "    Anonymous Developers"
    puts ""
}

proc ego_gui {} {
    log "PS3MFW Creator v${::PS3MFW_VERSION}"
    log "    Copyright (C) 2011 Project PS3MFW"
    log "    This program comes with ABSOLUTELY NO WARRANTY;"
    log "    This is free software, and you are welcome to redistribute it"
    log "    under certain conditions; see COPYING for details."
    log ""
    log "    Developed By :"
    log "    Anonymous Developers"
    log ""
}

proc clean_up {} {
    log "Deleting output files"
    catch_die {file delete -force -- ${::CUSTOM_PUP_DIR} ${::ORIGINAL_PUP_DIR} ${::OUT_FILE}} \
        "Could not cleanup output files"
}

proc unpack_source_pup {pup dest} {
    log "Unpacking source PUP [file tail ${pup}]"
    catch_die {pup_extract ${pup} ${dest}} "Error extracting PUP file [file tail ${pup}]"

    # Check for license.txt for people using older version of ps3tools
    set license_txt [file join ${::CUSTOM_UPDATE_DIR} license.txt]
    if {![file exists ${::CUSTOM_LICENSE_XML}] && [file exists ${license_txt}]} {
        set ::CUSTOM_LICENSE_XML ${license_txt}
    }
}
# --------------------------------------------- #
# proc for packing the CFW pup
# Why was the original build num. incremented???
# (this is now fixed, the increment was removed)
proc pack_custom_pup {dir pup} {
    set build ${::PUP_BUILD}
    set obuild [get_pup_build]
	log "PUP original build:$obuild"
    if {${build} == "" || ![string is integer ${build}] || ${build} == ${obuild}} {
        set build ${obuild}        
    }
    # create pup
    log "Packing Modified PUP:\"[file tail ${pup}]\", BUILD:$build"
    catch_die {pup_create ${dir} ${pup} $build} "Error packing PUP file [file tail ${pup}]"
}
# -------------------------------------------- #

# ----------------------------------------------------------------------------------- #
# ----------------------------- MAIN CFW BUILD TASK --------------------------------- #
proc build_mfw {input output tasks} {
    global options	
	 # array for saving off SELF-SCE Hdr fields
	 # for "LV0" for use by unself/makeself routines
	array set LV0_SCE_HDRS {
		--KEYREV ""
		--AUTHID ""
		--VENDORID ""
		--SELFTYPE ""
		--APPVERSION ""
		--FWVERSION ""
		--CTRLFLAGS ""
		--CAPABFLAGS ""
		--COMPRESS ""
	}
	# setup the tasks list
    set ::selected_tasks [sort_tasks ${tasks}]

    # print out ego info
    ego_gui

    if {${input} == "" || ${output} == ""} {
        die "Must specify an input and output file"
    }
    if {![file exists ${input}]} {
        die "Input file does not exist"
    }

    log "Selected tasks : ${::selected_tasks}"

    if {[info exists ::env(HOME)]} {
        debug "HOME=$::env(HOME)"
    }
    if {[info exists ::env(USERPROFILE)]} {
        debug "USERPROFILE=$::env(USERPROFILE)"
    }
    if {[info exists ::env(PATH)]} {
        debug "PATH=$::env(PATH)"
    }
	# remove all previous files, etc
	set ::OUT_FILE [file join ${::OUT_DIR} ${::OUT_FILE}]	
    clean_up
	
	# Add the input OFW SHA1 to the DB
	if {${::SHADD} == "true"} {
	    debug "Adding the SHA1 of the Input PUP to the DB"
		sha1_check ${input}
	}

    # Check input OFW PUP SHA1
	if {${::SHCHK} == "true"} {
	    set catch [catch [sha1_verify ${input}]]
	    if {$catch == 1} {
		    log "Error!!"
			log "SHA1 of input PUP does not match any known SHA1"
			after 20000
			exit 0
		} elseif {$catch == 0} {
		    log "PUP SHA1 of input OFW matches known SHA1!"
		}
		unset catch
	}

	## ----------------------------------------------------------------------------------------- ##
	## --------------- UNPACK ALL FILES 'FIRST' IN THE 'ORIGINAL_PUP' DIR ---------------------- ##
	##
	#
    # PREPARE PS3UPDAT.PUP for modification
	# -- create the 'BUILD-DIR' path first, then
	# -- create the 'PS3MFW-OFW' dir
	log "Creating initial build directories....."	
	create_mfw_dir ${::BUILD_DIR}	
	create_mfw_dir ${::ORIGINAL_PUP_DIR}		
	
	## -- unpack the OFW PUP file.....
	log "Directory creation and PUP unpacking complete!\n"	
    unpack_source_pup ${input} ${::ORIGINAL_PUP_DIR}	
	
	# set the pup version into a variable so commands later can check it and do fw specific thingy's
	# save off the "OFW MAJOR.MINOR" into a global for usage throughout
	debug "checking pup version"
    set ::SUF [::get_pup_version ${::ORIGINAL_VERSION_TXT}]	
	if { [regexp "(^\[0-9]{1,2})\.(\[0-9]{1,2})(.*)" $::SUF all ::OFW_MAJOR_VER ::OFW_MINOR_VER SubVerInfo] } {		
		set ::NEWMFW_VER [format "%.1d.%.2d" $::OFW_MAJOR_VER $::OFW_MINOR_VER]	
		if { $SubVerInfo != "" } {
			log "Getting pup version OK! var = ${::NEWMFW_VER} (subversion:$SubVerInfo)"
		} else { 
			log "Getting pup version OK! var = ${::NEWMFW_VER}"
		}		
	} else {
		die "Getting pup version FAILED! Exiting!"
	}
	
	# extract "custom_update.tar
    extract_tar ${::ORIGINAL_UPDATE_TAR} ${::ORIGINAL_UPDATE_DIR}
	
	# if firmware is >= 3.56 we need to extract
	# spkg_hdr.tar	
	if { ${::NEWMFW_VER} >= ${::OFW_2NDGEN_BASE} } {
		extract_tar ${::ORIGINAL_SPKG_TAR} ${::ORIGINAL_SPKG_DIR} }	

	# unpack devflash files	
	# (do this before the copy, so we have the unpacked
	#  flash files in the PS3OFW directory)
    log "Unpacking all dev_flash files"
    unpkg_devflash_all ${::ORIGINAL_UPDATE_DIR} ${::ORIGINAL_DEVFLASH_DIR}	

	# unpack the CORE_OS files here, pass the 
	# SELF-SCE Headers array
	::unpack_coreos_files ${::ORIGINAL_PUP_DIR} LV0_SCE_HDRS			
	
	### DO THE COPY HERE, SO WE HAVE A MIRROR OF ALL REQ'D
	### files in the 'PS3MFW-OFW' directory.
	# copy original UNPACKED PUP/assoc. files to working dir
	log "Please WAIT.....copying unpacked OFW to MFW dirs....."	
    copy_dir ${::ORIGINAL_PUP_DIR} ${::CUSTOM_PUP_DIR}
	
	#
	### --------------------- END OF PRE-EXECUTION PREP-WORK ------------------- ###
	
	

	### ----------  !!! BEGIN EXECUTION OF MAIN TASKS !!!! --------------------- ###
	
    # Execute tasks
    foreach task ${::selected_tasks} {
        log "******** Running task: \"$task.tcl\" **********"
        eval [string map {- _} ${task}::main]
    }
    log "******** Completed tasks **********"
	
	### ----------  !!!! DONE EXEUCTION OF TASKS !!! --------------------------- ###
	
	#repack the CORE_OS files here, pass the 
	# SELF-SCE Headers array	
	::repack_coreos_files LV0_SCE_HDRS	

    # RECREATE PS3UPDAT.PUP
    file delete -force ${::CUSTOM_DEVFLASH_DIR}
	debug "custom dev_flash deleted"	
	
	# if firmware is >= 3.56, we need to repack spkg files	
	if { ${::NEWMFW_VER} >= ${::OFW_2NDGEN_BASE} } {		
		set filesSPKG [lsort [glob -nocomplain -tails -directory ${::CUSTOM_SPKG_DIR} *.1]]
		debug "spkg's added to list"
	}
    set files [lsort [glob -nocomplain -tails -directory ${::CUSTOM_UPDATE_DIR} *.pkg]]
	debug "pkg's added to list"
    eval lappend files [lsort [glob -nocomplain -tails -directory ${::CUSTOM_UPDATE_DIR} *.img]]
	debug "img's added to list"
    eval lappend files [lsort [glob -nocomplain -tails -directory ${::CUSTOM_UPDATE_DIR} dev_flash3_*]]
	debug "dev_flash 3 added to list"
    eval lappend files [lsort [glob -nocomplain -tails -directory ${::CUSTOM_UPDATE_DIR} dev_flash_*]]
	debug "dev_flash added to list"
		
	
	# create the tar with the 'nodirs' flag, to assure 'directories' are NOT
	# included in the tar
	# '-nodirs' = do NOT include directories in tar file
	# do NOT specify 'nofinalpad', as we want the final .tar padded!
    create_tar ${::CUSTOM_UPDATE_TAR} ${::CUSTOM_UPDATE_DIR} ${files} -nodirs
	debug "PKG TAR created"	
	
	# if firmware is >= 3.56, we need to repack spkg files	
	# do NOT specify 'nofinalpad', as we want the final .tar padded!
	if { ${::NEWMFW_VER} >= ${::OFW_2NDGEN_BASE} } {				
		# create the SPKG tar
		# '-nodirs' = do NOT include directories in tar file
		create_tar ${::CUSTOM_SPKG_TAR} ${::CUSTOM_SPKG_DIR} ${filesSPKG} -nodirs
		debug "SPKG TAR created"
	}
	# cleanup any previous output builds
	set final_output "${::OUT_FILE}_$::OFW_MAJOR_VER.$::OFW_MINOR_VER.pup"
	catch_die {file delete -force -- ${::OUT_FILE}} "Could not cleanup output files"
	
	# finalize the completed PUP
    pack_custom_pup ${::CUSTOM_PUP_DIR} ${final_output}
	log "CUSTOM FIMWARE VER:$::OFW_MAJOR_VER.$::OFW_MINOR_VER BUILD COMPLETE!!!"
}
#
# ---------------------------------------  END OF TASKS SCRIPT --------------------------------------------- #
