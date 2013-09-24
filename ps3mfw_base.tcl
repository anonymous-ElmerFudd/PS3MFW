#!/usr/bin/tclsh
#
# ps3mfw -- PS3 MFW creator
#
# Copyright (C) Anonymous Developers (Code Monkeys)
#
# This software is distributed under the terms of the GNU General Public
# License ("GPL") version 3, as published by the Free Software Foundation.
#
#



# PRINT USAGE
proc usage {{msg ""}} {
    global options

    ego

    if {$msg != ""} {
        puts $msg
    }
    puts "Usage: ${::argv0} \[options\] <Original> <Modified> \[task\] \[task options\]"
    puts "eg. ${::argv0} PS3UPDAT.PUP PS3UPDAT.MFW.PUP"
    puts ""
    puts "Available options are : "
    foreach option [get_sorted_options [file normalize [info script]] [array names options]] {
        puts "  $option \"$options($option)\"\n    [get_option_description [file normalize [info script]] $option]"
    }
    puts "\nAvailable tasks are : "
    foreach task [get_sorted_task_files] {
        puts "\nTask:\n--[string map {_ -} [file rootname [file tail $task]]] : [string map {\n \n\t\t\t\t} [get_task_description $task]]"
        set taskname [file rootname [file tail $task]]
        if { [llength [array names ::${taskname}::options]] } {
            puts "  Task options:"
            foreach option [get_sorted_options $task [array names ::${taskname}::options]] {
                puts "  $option \"[set ::${taskname}::options($option)]\"\n    [get_option_description $task $option]"
            }
        }
    }
    puts ""
    exit -1
}

# new routine for extracting LV0 for 3.60+ OFW (using lv0tool.exe)
# default:  crypt/decrypt "lv1ldr", unless we are under
# FW version 3.65
proc extract_lv0 {path file} {   

	log "Extracting 3.60+ LV0 and loaders...."
	set fullpath [file join $path $file]
	set lv1ldr_crypt no
	
	# if firmware is >= 3.65, LV1LDR is crypted, otherwise it's
	# not crypted.  Also, check if we "override" this setting
	# by the flag in the "patch_coreos" task
	set FWVer [format "%.1d%.2d" $::OFW_MAJOR_VER $::OFW_MINOR_VER]	
	if {$FWVer >= "365"} {
		set lv1ldr_crypt yes
		if {$::FLAG_NO_LV1LDR_CRYPT != 0} {	
			set lv1ldr_crypt no
		}
	}	
	# decrypt LV0 to "LV0.elf", and
	# delete the original "lv0"
	decrypt_self $fullpath ${fullpath}.elf
	file delete ${fullpath}
	
	# export LV0 contents.....
	append fullpath ".elf"	
	shell ${::LV0TOOL} -option export -lv1crypt $lv1ldr_crypt -filename ${file}.elf -filepath $path	
}

# new routine for re-packing LV0 for 3.60+ OFW (using lv0tool.exe)
# default:  crypt/decrypt "lv1ldr", unless we are under
# FW version 3.65
proc import_lv0 {path file} {   

	log "Importing 3.60+ loaders into LV0...."	
	set fullpath [file join $path $file]
	set lv1ldr_crypt no
	
	# if firmware is >= 3.65, LV1LDR is crypted, otherwise it's
	# not crypted.  Also, check if we "override" this setting
	# by the flag in the "patch_coreos" task
	set FWVer [format "%.1d%.2d" $::OFW_MAJOR_VER $::OFW_MINOR_VER]	
	if {$FWVer >= "365"} {
		set lv1ldr_crypt yes
		if {$::FLAG_NO_LV1LDR_CRYPT != 0} {	
			set lv1ldr_crypt no
		}
	}	
	
	# execute the "lv0tool" to re-import the loaders
	shell ${::LV0TOOL} -option import -lv1crypt $lv1ldr_crypt -cleanup yes -filename ${file}.elf -filepath $path	
	
	# resign "lv0.elf" "lv0.self"
	sign_elf ${fullpath}.elf ${fullpath}.self
	
	file delete ${fullpath}.elf
	file rename -force ${fullpath}.self $fullpath		
}

proc get_log_fd {} {
    global log_fd LOG_FILE

    if {![info exists log_fd]} {
        set log_fd [open $LOG_FILE w]
        fconfigure $log_fd -buffering none
    }
    return $log_fd
}

proc log {msg {force 0}} {
    global options

    if {!$options(--silent) || $force} {
        set fd [get_log_fd]
        puts $fd $msg
        if {$force} {
            puts stderr $msg
        } else {
            puts $msg
        }
    }
}

proc debug {msg} {
    if {$::options(--debug)} {
        log $msg 1
    }
}

proc grep {re args} {
    set result [list]
    set files [eval glob -types f $args]
    foreach file $files {
        set fp [open $file]
        set l 0
        while {[gets $fp line] >= 0} {
            if [regexp -- $re $line] {
                lappend result [list $file $line $l]
            }
            incr l
        } 
		close $fp
    }
    set result
}

proc _get_comment_from_file {filename re} {
    set results [grep $re $filename]
    set comment ""
    foreach match $results {
        foreach {file match line} $match break
        append comment "[string trim [regsub $re $match {}]]\n"
    }
    string trim $comment
}

proc get_task_description {filename} {
    return [_get_comment_from_file $filename {^# Description:}]
}

proc get_option_description {filename option} {
    return [_get_comment_from_file $filename "^# Option ${option}:"]
}

proc get_sorted_options {filename options} {
    return [lsort -command [list sort_options $filename] $options]
}

proc sort_options {file opt1 opt2 } {
    set re1 "^# Option ${opt1}:"
    set re2 "^# Option ${opt2}:"
    set results1 [grep $re1 $file]
    set results2 [grep $re2 $file]

    if {$results1 == {} && $results2 == {}} {
        return [string compare $opt1 $opt2]
    } elseif {$results1 == {}} {
        return 1
    } elseif {$results2 == {}} {
        return -1
    } else {
        foreach {file match line1} [lindex $results1 0] break
        foreach {file match line2} [lindex $results2 0] break
        return [expr {$line1 - $line2}]
    }
}

proc get_option_type {filename option} {
    return [_get_comment_from_file $filename "^# Type ${option}:"]
}

proc task_to_file {task} {
    return [file join ${::TASKS_DIR} ${task}.tcl]
}

proc file_to_task {file} {
    return [file rootname [file tail $file]]
}

proc compare_tasks {task1 task2} {
    return [compare_task_files [task_to_file $task1] [task_to_file $task2]]
}

proc compare_task_files {file1 file2} {
    set prio1 [_get_comment_from_file $file1 {^# Priority:}]
    set prio2 [_get_comment_from_file $file2 {^# Priority:}]

    if {$prio1 == {} && $prio2 == {}} {
        return [string compare $file1 $file2]
    } elseif {$prio1 == {}} {
        return 1
    } elseif {$prio2 == {}} {
        return -1
    } else {
        return [expr {$prio1 - $prio2}]
    }
}

proc sort_tasks {tasks} {
    return [lsort -command compare_tasks $tasks]
}

proc sort_task_files {files} {
    return [lsort -command compare_task_files $files]
}

proc get_sorted_tasks { {tasks {}} } {
    set files [glob -nocomplain [file join ${::TASKS_DIR} *.tcl]]
    set tasks [list]
    foreach file $files {
        lappend tasks [file_to_task $file]
    }
    return [sort_tasks $tasks]
}

proc get_sorted_task_files { } {
    set files [glob -nocomplain [file join ${::TASKS_DIR} *.tcl]]
    return [sort_task_files $files]
}

proc get_selected_tasks { } {
    return ${::selected_tasks}
}

# failure function
proc die {message} {
    global LOG_FILE

    log "FATAL ERROR: $message" 1
    puts stderr "See ${LOG_FILE} for more info"
    puts stderr "Last lines of log : "
    puts stderr "*****************"
    catch {puts stderr "[tail $LOG_FILE]"}
    puts stderr "*****************"
    exit -2
}

proc catch_die {command message} {
    set catch {
        if {[catch {@command@} res] } {
            die "@message@ : $res"
        }
        return $res
    }
    debug "Executing command $command"
    set catch [string map [list "@command@" "$command" "@message@" "$message"] $catch]
    uplevel 1 $catch
}

proc shell {args} {
    set fd [get_log_fd]
    debug "Executing shell $args"
    eval exec $args >&@ $fd
}

proc hexify { str } {
    set out ""
    for {set i 0} { $i < [string length $str] } { incr i} {
        set c [string range $str $i $i]
        binary scan $c H* h
        append out "\[$h\]"
    }
    return $out
}

proc tail {filename {n 10}} {
    set fd [open $filename r]
    set lines [list]
    while {![eof $fd]} {
        lappend lines [gets $fd]
        if {[llength $lines] > $n} {
            set lines [lrange $lines end-$n end]
        }
    }
    close $fd
    return [join $lines "\n"]
}

proc create_mfw_dir {args} {   
    catch_die {file mkdir $args} "Could not create dir $args"
}


proc copy_file {args} {
    catch_die {file copy {*}$args} "Unable to copy $args"
}

proc sha1_check {file} {
    shell ${::fciv} -add [file nativename $file] -wp -sha1 -xml db.xml
}

proc sha1_verify {file} {
    shell ${::fciv} [file nativename $file] -v -sha1 -xml db.xml
}

proc delete_file {args} {
    catch_die {file delete {*}$args} "Unable to delete $args"
}

proc rename_file {src dst} {
    catch_die {file rename {*}$src $dst} "Unable to rename and/or move $src $dst"
}

proc delete_promo { } {
    delete_file -force ${::CUSTOM_PROMO_FLAGS_TXT}
}

proc copy_spkg { } {
    debug "searching for spkg"
    set spkg [glob -directory ${::CUSTOM_UPDATE_DIR} *.1]
	debug "spkg found in $spkg"
	debug "copy new spkg into spkg dir"
    copy_file -force $spkg ${::CUSTOM_SPKG_DIR}
	if {[file exists [file join $spkg]]} {
	debug "removing spkg from working dir"
	delete_file -force $spkg
	}
} 

proc copy_mfw_imgs { } {
    create_mfw_dir ${::CUSTOM_MFW_DIR}
    copy_file -force ${::CUSTOM_IMG_DIR} ${::CUSTOM_MFW_DIR}
}

# routine to copy standalone '*Install Package Files' app into MFW
proc copy_ps3_game {arg} {
    variable option
	set arg0 0
	set arg1 0
	set arg2 0
	set arg3 0
	set arg4 1
	
	if {[info exists ::patch_xmb::options(--add-install-pkg)]} {
		set arg0 $::patch_xmb::options(--add-install-pkg) }
	if {[info exists ::patch_xmb::options(--add-pkg-mgr)]} {
		set arg1 $::patch_xmb::options(--add-pkg-mgr) }
	if {[info exists ::patch_xmb::options(--add-hb-seg)]} {
		set arg2 $::patch_xmb::options(--add-hb-seg) }
	if {[info exists ::patch_xmb::options(--add-emu-seg)]} {
		set arg3 $::patch_xmb::options(--add-emu-seg) }
	if {[info exists ::customize_firmware::options(--customize-embedded-app)]} {
		set arg4 [file exists $::customize_firmware::options(--customize-embedded-app) == 0] }
    
    if { $arg0 || $arg1 || $arg2 || $arg3  && !$arg4 } {
        rename_file -force $arg ${::CUSTOM_EMBEDDED_APP}
    } elseif { $arg0 || $arg1 || $arg2 || $arg3  && $arg4 } {
        copy_file -force $arg ${::CUSTOM_MFW_DIR}
    } elseif { !$arg0 && !$arg1 && !$arg2 && !$arg3 && !$arg4 } {
        create_mfw_dir ${::CUSTOM_MFW_DIR}
        rename_file -force $arg ${::CUSTOM_EMBEDDED_APP}
    } elseif { !$arg0 && !$arg1 && !$arg2 && !$arg3 && $arg4 } {
        create_mfw_dir ${::CUSTOM_MFW_DIR}
        copy_file -force $arg ${::CUSTOM_MFW_DIR}
    }
	unset arg0, arg1, arg2, arg3, arg4
}

proc copy_ps3_game_standart { } {
    set ttf "SCE-PS3-RD-R-LATIN.TTF"
	debug "using font file .ttf as argument to search for"
	debug "cause we need a tar with a bit space in it"
    modify_devflash_file [file join dev_flash data font $ttf] callback_ps3_game_standart
}

proc callback_ps3_game_standart { file } {
    log "Creating custom directory in dev_flash"
	create_mfw_dir ${::CUSTOM_MFW_DIR}
	if {${::CFW} == "AC1D"} {
	    log "Installing standalone 'Custom FirmWare' app"
	    copy_file -force ${::CUSTOM_PS3_GAME2} ${::CUSTOM_MFW_DIR}
		log "Copy custom imgs into dev_flash"
	    copy_file -force ${::CUSTOM_IMG_DIR} ${::CUSTOM_MFW_DIR}
	} else {
	    log "Installing standalone '*Install Package Files' app"
	    copy_file -force ${::CUSTOM_PS3_GAME} ${::CUSTOM_MFW_DIR}
	}
}

proc pup_extract {pup dest} {
#    shell ${::PUP} x $pup $dest
    shell ${::PUPUNPACK} [file nativename $pup] [file nativename $dest]
}

proc pup_create {dir pup build} {
#    shell ${::PUP} c $dir $pup $build
    shell ${::PUPPACK} $pup [file nativename $dir] [file nativename $build]
}

proc pup_get_build {pup} {
    set fd [open $pup r]
    fconfigure $fd -translation binary
    seek $fd 16
    set build [read $fd 8]
    close $fd

    if {[binary scan $build W build_ver] != 1} {
        error "Cannot read 64 bit big endian from [hexify $build]"
    }
	
    return $build_ver
}

proc extract_tar {tar dest} {

    file mkdir $dest
    debug "Extracting tar file [file tail $tar] into [file tail $dest]"
    catch_die {::tar::untar $tar -dir $dest} "Could not untar file $tar"
}

proc create_tar {tar directory files} {
    set debug [file tail $tar]
    if {$debug == "content" } {
        set debug [file tail [file dirname $tar]]
    }
    debug "Creating tar file $debug"
    set pwd [pwd]
    cd $directory
    catch_die {::tar::create $tar $files} "Could not create tar file $tar"
    cd $pwd
}

proc find_devflash_archive {dir find} {

    foreach file [glob -nocomplain [file join $dir * content]] {
        if {[catch {::tar::stat $file $find}] == 0} {
            return $file
        }
    }
    return ""
}

proc spkg {pkg} {
    shell ${::SPKG} [file nativename $pkg]
}

proc new_pkg {pkg dest} {
    shell ${::NEWPKG} retail [file nativename $pkg] [file nativename $dest]
}

proc unpkg {pkg dest} {
    shell ${::UNPKG} [file nativename $pkg] [file nativename $dest]
}

proc pkg {pkg dest} {
    shell ${::PKG} retail [file nativename $pkg] [file nativename $dest]
}

proc unpkg_archive {pkg dest} {
    debug "unpkg-ing file [file tail $pkg]"
    catch_die {unpkg $pkg $dest} "Could not unpkg file [file tail $pkg]"
}

proc pkg_archive {dir pkg} {
    debug "pkg-ing file [file tail $pkg]"
    catch_die {pkg $dir $pkg} "Could not pkg file [file tail $pkg]"
}

proc new_pkg_archive {dir pkg} {
    debug "pkg-ing / spkg-ing file [file tail $pkg]"
    catch_die {new_pkg $dir $pkg} "Could not pkg / spkg file [file tail $pkg]"
}

proc spkg_archive {pkg} {
    debug "spkg-ing file [file tail $pkg]"
    catch_die {spkg $pkg} "Could not spkg file [file tail $pkg]"
}

proc unpkg_devflash_all {dir} {
    file mkdir $dir
    foreach file [lsort [glob -nocomplain [file join ${::CUSTOM_UPDATE_DIR} dev_flash_*]]] {
        unpkg_archive $file [file join $dir [file tail $file]]
    }
}

proc cosunpkg { pkg dest } {
    shell ${::COSUNPKG} [file nativename $pkg] [file nativename $dest]
}

proc cospkg { dir pkg } {
    shell ${::COSPKG} [file nativename $pkg] [file nativename $dir]
}

proc cosunpkg_package { pkg dest } {
    debug "cosunpkg-ing file [file tail $pkg]"
    catch_die { cosunpkg $pkg $dest } "Could not cosunpkg file [file tail $pkg]"
}

proc cospkg_package { dir pkg } {
    debug "cospkg-ing file [file tail $dir]"
    catch_die { cospkg $dir $pkg } "Could not cospkg file [file tail $pkg]"
}

proc modify_coreos_file { file callback args } {
	## core os files are now automaticallly unpacked/repacked
	## at the start/end of the MFW build script
	die "THIS ROUTINE IS NO LONGER SUPPORTED!!!"
	
    log "Modifying CORE_OS file [file tail $file]"   
    set pkg [file join ${::CUSTOM_UPDATE_DIR} CORE_OS_PACKAGE.pkg]
    set unpkgdir [file join ${::CUSTOM_UPDATE_DIR} CORE_OS_PACKAGE.unpkg]
    set cosunpkgdir [file join ${::CUSTOM_UPDATE_DIR} CORE_OS_PACKAGE]
    
    ::unpkg_archive $pkg $unpkgdir
    ::cosunpkg_package [file join $unpkgdir content] $cosunpkgdir

    if {[file writable [file join $cosunpkgdir $file]]} {
	    set ::SELF $file
        eval $callback [file join $cosunpkgdir $file] $args
    } elseif { ![file exists [file join $cosunpkgdir $file]] } {
        die "Could not find $file in CORE_OS_PACKAGE"
    } else {
        die "File $file is not writable in CORE_OS_PACKAGE"
    }

    ::cospkg_package $cosunpkgdir [file join $unpkgdir content]
    
    if {[::get_pup_version] >= ${::NEWCFW}} {
       ::new_pkg_archive $unpkgdir $pkg
        ::copy_spkg
    } else {
        ::pkg_archive $unpkgdir $pkg
    }
}

proc modify_coreos_files { files callback args } {
	## core os files are now automaticallly unpacked/repacked
	## at the start/end of the MFW build script
	die "THIS ROUTINE IS NO LONGER SUPPORTED!!!"
	
    log "Modifying CORE_OS files [file tail $files]" 
    set pkg [file join ${::CUSTOM_UPDATE_DIR} CORE_OS_PACKAGE.pkg]
    set unpkgdir [file join ${::CUSTOM_UPDATE_DIR} CORE_OS_PACKAGE.unpkg]
    set cosunpkgdir [file join ${::CUSTOM_UPDATE_DIR} CORE_OS_PACKAGE]
    
    ::unpkg_archive $pkg $unpkgdir
    ::cosunpkg_package [file join $unpkgdir content] $cosunpkgdir
    
	foreach file $files {
        if {[file writable [file join $cosunpkgdir $file]]} {
		    log "Using file $file now"
			set ::SELF $file
            eval $callback [file join $cosunpkgdir $file] $args
        } elseif { ![file exists [file join $cosunpkgdir $file]] } {
            die "Could not find $file in CORE_OS_PACKAGE"
        } else {
            die "File $file is not writable in CORE_OS_PACKAGE"
        }
	}

    ::cospkg_package $cosunpkgdir [file join $unpkgdir content]
    
    if {[::get_pup_version] >= ${::NEWCFW}} {
        ::new_pkg_archive $unpkgdir $pkg	
        ::copy_spkg
    } else {
        ::pkg_archive $unpkgdir $pkg
    }
}

# proc for "unpackaging" the "CORE_OS" files
proc unpack_coreos_files { args } {
	#::CUSTOM_PKG_DIR == $pkg
	#::CUSTOM_UNPKG_DIR == $unpkg
	#::CUSTOM_COSUNPKG_DIR == $cosunpkg
    log "UN-PACKAGING CORE_OS files..."   
   
    ::unpkg_archive $::CUSTOM_PKG_DIR $::CUSTOM_UNPKG_DIR
    ::cosunpkg_package [file join $::CUSTOM_UNPKG_DIR content] $::CUSTOM_COSUNPKG_DIR	
	
	# if firmware is >= 3.60, we need to extract LV0 contents
	set FWVer [format "%.1d%.2d" $::OFW_MAJOR_VER $::OFW_MINOR_VER]	
	if {$FWVer >= "360"} {
		catch_die {extract_lv0 $::CUSTOM_COSUNPKG_DIR "lv0"} "ERROR: Could not extract LV0"
	}
	
	# set the global flag that "CORE_OS" is unpacked
	set ::FLAG_COREOS_UNPACKED 1
	log "CORE_OS UNPACKED..." 	
}

# proc for "packaging" up the "CORE_OS" files
proc repack_coreos_files { args } {
	#::CUSTOM_PKG_DIR == $pkg
	#::CUSTOM_UNPKG_DIR == $unpkg
	#::CUSTOM_COSUNPKG_DIR == $cosunpkg
    log "RE-PACKAGING CORE_OS files..." 

	# if firmware is >= 3.60, we need to import LV0 contents
	set FWVer [format "%.1d%.2d" $::OFW_MAJOR_VER $::OFW_MINOR_VER]
	if {$FWVer >= "360"} {
		catch_die {import_lv0 $::CUSTOM_COSUNPKG_DIR "lv0"} "ERROR: Could not import LV0"
	}	
    
	# re-package up the files
    ::cospkg_package $::CUSTOM_COSUNPKG_DIR [file join $::CUSTOM_UNPKG_DIR content]   
   	::pkg_archive $::CUSTOM_UNPKG_DIR $::CUSTOM_PKG_DIR		
	
	# set the global flag that "CORE_OS" is packed
	set ::FLAG_COREOS_UNPACKED 0
	log "CORE_OS REPACKED..." 	
}

proc get_pup_build {} {
    debug "Getting PUP build from [file tail ${::IN_FILE}]"
    catch_die {pup_get_build ${::IN_FILE}} "Could not get the PUP build information"
    return [pup_get_build ${::IN_FILE}]
}

proc set_pup_build {build} {
    debug "PUP build: $build"
    set ::PUP_BUILD $build
}

proc get_pup_version {} {
    debug "Getting PUP version from [file tail ${::CUSTOM_VERSION_TXT}]"
    set fd [open [file join ${::CUSTOM_VERSION_TXT}] r]
    set version [string trim [read $fd]]
    close $fd
    return $version
}

proc set_pup_version {version} {
    debug "Setting PUP version in [file tail ${::CUSTOM_VERSION_TXT}]"
    set fd [open [file join ${::CUSTOM_VERSION_TXT}] w]
    puts $fd "${version}"
    close $fd
}

proc modify_pup_version_file {prefix suffix {clear 0}} {
    if {$clear} {
      set version ""
    } else {
      set version [::get_pup_version]
    }
    debug "PUP version: ${prefix}${version}${suffix}"
    set_pup_version "${prefix}${version}${suffix}"
}

proc sed_in_place {file search replace} {
    set fd [open $file r]
    set data [read $fd]
    close $fd

    set data [string map [list $search $replace] $data]

    set fd [open $file w]
    puts -nonewline $fd $data
    close $fd
}

proc unself {in out} {
    set FIN [file nativename $in]
	set FOUT [file nativename $out]

    shell ${::SCETOOL} -d $FIN $FOUT
}

#
# new makeself routine using scetool
#
#
proc makeself {in out} {
   variable options
   set fwversiVar ""
   set versionVar ""
   set keyRev "00"
   set authID ""
   set vendID "ff000000"
   set selfType ""
   set compress FALSE
   

    # Reading the pup suffix var and set up fw/self version var 	
	# example: "0004004100000000"
	set versionVar [format "000%d00%d00000000" $::OFW_MAJOR_VER $::OFW_MINOR_VER]
	set fwversiVar $versionVar	
	set ::SELF [file tail $in]	
	#debug "VERSION: $versionVar"	
	
    # Read the loaded self and set authentication/vendor ID, self type and key revision 
	#
    if { ${::SELF} == "lv0" || ${::SELF} == "lv0.elf" } {
		set compress FALSE
		set authID "1ff0000001000001"
		set selfType "LV0"		
    } elseif { ${::SELF} == "lv1ldr.self" || ${::SELF} == "lv1ldr.self.elf" } {
		set compress FALSE
		set authID "1FF0000008000001"
		set selfType "LDR"		
    } elseif { ${::SELF} == "lv2ldr.self" || ${::SELF} == "lv2ldr.self.elf"} {
		set compress FALSE
		set authID "1FF0000009000001"
		set selfType "LDR"		
    } elseif { ${::SELF} == "isoldr.self" || ${::SELF} == "isoldr.self.elf" } {
		set compress FALSE
	    set authID "1FF000000A000001"
		set selfType "LDR"
	} elseif { ${::SELF} == "appldr.self" || ${::SELF} == "appldr.self.elf"} {
		set compress FALSE
	    set authID "1ff000000c000001"
		set selfType "LDR"
	} elseif { ${::SELF} == "lv1.self" || ${::SELF} == "lv1.self.elf" } {
		set compress TRUE
		set authID "1ff0000002000001"
		set selfType "LV1"
    } elseif { ${::SELF} == "lv2_kernel.self" || ${::SELF} == "lv2_kernel.self.elf" } {
		set compress TRUE
		set authID "1050000003000001"
		set vendID "05000002"
		set selfType "LV2"		
    } elseif { ${::SELF} == "spu_pkg_rvk_verifier.self" || ${::SELF} == "spu_pkg_rvk_verifier.self.elf" } {
		set compress FALSE
		set authID "1070000022000001"
		set vendID "07000001"
		set selfType "ISO"
		set keyRev "01"
    } elseif { ${::SELF} == "retail game/update" } {
		set compress FALSE
		set authID "1010000001000003"		
		set selfType "APP"
		set keyRev "01"    
	} elseif { ${::SELF} == "ps2emu" } {
		set compress FALSE
		set authID "1020000401000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "onicore_child" } {
		set compress FALSE
		set authID "1070000001000002"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "mcore" } {
		set compress FALSE
		set authID "1070000002000002"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "mgvideo" } {
		set compress FALSE
		set authID "1070000003000002"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "swagner" } {
		set compress FALSE
		set authID "1070000004000002"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "swreset" } {
		set compress FALSE
		set authID "1070000004000002"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "ss_init" } {
		set compress FALSE
		set authID "1070000017000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "ss_sc_init_pu" } {
		set compress FALSE
		set authID "107000001A000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "updater_frontend" } {
		set compress FALSE
		set authID "107000001C000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "sysmgr_ss" } {
		set compress FALSE
		set authID "107000001D000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "sb_iso_spu_module.self" || ${::SELF} == "sb_iso_spu_module.self.elf" } {
		set compress FALSE
		set authID "107000001F000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "sc_iso.self" || ${::SELF} == "sc_iso.self.elf" } {
		set compress FALSE
		set authID "1070000020000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "sc_iso_factory.self" || ${::SELF} == "sc_iso_factory.self.elf" } {
		set compress FALSE
		set authID "1070000020000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "spp_verifier.self" || ${::SELF} == "spp_verifier.self.elf" } {
		set compress FALSE
		set authID "1070000021000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "spu_pkg_rvk_verifier.self" || ${::SELF} == "spu_pkg_rvk_verifier.self.elf" } {
		set compress FALSE
		set authID "1070000022000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "spu_token_processor.self" || ${::SELF} == "spu_token_processor.self.elf" } {
		set compress FALSE
		set authID "1070000023000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "sv_iso_spu_module.self" || ${::SELF} == "sv_iso_spu_module.self.elf" } {
		set compress FALSE
		set authID "1070000024000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "aim_spu_module.self" || ${::SELF} == "aim_spu_module.self.elf" } {
		set compress FALSE
		set authID "1070000025000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "ss_sc_init" } {
		set compress FALSE
		set authID "1070000026000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "factory_data_mngr_server" } {
		set compress FALSE
		set authID "1070000028000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "fdm_spu_module" } {
		set compress FALSE
		set authID "1070000029000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "ss_server1" } {
		set compress FALSE
		set authID "1070000032000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "ss_server2" } {
		set compress FALSE
		set authID "1070000033000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "ss_server3" } {
		set compress FALSE
		set authID "1070000034000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "mc_iso_spu_module.self" || ${::SELF} == "mc_iso_spu_module.self.elf" } {
		set compress FALSE
		set authID "1070000037000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "bdp_bdmv" } {
		set compress FALSE
		set authID "1070000039000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "bdj" } {
		set compress FALSE
		set authID "107000003A000001"		
		set selfType "APP"
		set keyRev "01"
    }  elseif { ${::SELF} == "ps1emu" } {
		set compress FALSE
		set authID "1070000041000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "me_iso_spu_module.self" || ${::SELF} == "me_iso_spu_module.self.elf"} {
		set compress FALSE
		set authID "1070000043000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "spu_mode_auth" } {
		set compress FALSE
		set authID "1070000046000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "spu_utoken_processor.self" || ${::SELF} == "spu_utoken_processor.self.elf" } {
		set compress FALSE
		set authID "107000004C000001"		
		set selfType "APP"
		set keyRev "01"
    }  elseif { ${::SELF} == "manu_info_spu_module.self" || ${::SELF} == "manu_info_spu_module.self.elf" } {
		set compress FALSE
		set authID "1070000055000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "me_iso_for_ps2emu.self" || ${::SELF} == "me_iso_for_ps2emu.self.elf" } {
		set compress FALSE
		set authID "1070000058000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "sv_iso_for_ps2emu.self" || ${::SELF} == "sv_iso_for_ps2emu.self.elf" } {
		set compress FALSE
		set authID "1070000059000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "Lv2diag BD Remarry" } {
		set authID "1070000300000001"		
		set selfType "APP"
		set keyRev "01"
    } elseif { ${::SELF} == "emer_init.self" || ${::SELF} == "emer_init.self.elf" } {
		set compress TRUE
	    set authID "10700003FC000001"
		set selfType "APP"
	} elseif { ${::SELF} == "ps3swu" } {
		set compress FALSE
	    set authID "10700003FD000001"
		set selfType "APP"
	} elseif { ${::SELF} == "Lv2diag FW Stuff" } {
		set compress FALSE
	    set authID "10700003FF000001"
		set selfType "APP"
	} elseif { ${::SELF} == "pspemu" } {
		set compress FALSE
	    set authID "1070000409000001"
		set selfType "APP"
	} elseif { ${::SELF} == "psp_translator" } {
		set compress FALSE
	    set authID "107000040A000001"
		set selfType "APP"
	} elseif { ${::SELF} == "pspemu modules" } {
		set compress FALSE
	    set authID "107000040B000001"
		set selfType "APP"
	} elseif { ${::SELF} == "pspemu drm" } {
		set compress FALSE
	    set authID "107000040C000001"
		set selfType "APP"
	} elseif { ${::SELF} == "cellftp" } {
		set compress FALSE
	    set authID "1070000500000001"
		set selfType "APP"
	} elseif { ${::SELF} == "hdd_copy" } {
		set compress FALSE
	    set authID "1070000501000001"
		set selfType "APP"
	} elseif { ${::SELF} == "sys_audio" } {
		set compress FALSE
	    set authID "10700005FC000001"
		set selfType "APP"
	} elseif { ${::SELF} == "sys_init_osd" } {
		set compress FALSE
	    set authID "10700005FD000001"
		set selfType "APP"
	} elseif { ${::SELF} == "sys_init_osd" } {
		set compress FALSE
	    set authID "10700005FD000001"
		set selfType "APP"
	} elseif { ${::SELF} == "vsh.self" || ${::SELF} == "vsh.self.elf" } {
		set compress TRUE
	    set authID "10700005ff000001"
		set vendID "01000002"
		set selfType "APP"
		set keyRev "1C"
	## ------------- ALL "DEV_FLASH/xxxx" module checks are below ----------------
	} elseif { ([string first "dev_flash/sys/external/" $in 0] != -1) } {
		set compress TRUE
		set authID "1070000040000001"
		set vendID "01000002"		
		set selfType "APP"
		set keyRev "1C"	
    } elseif { ([string first "dev_flash/sys/internal/" $in 0] != -1) || ([string first "dev_flash/vsh/module/" $in 0] != -1) } {  
		set compress TRUE
		set authID "1070000052000001"
		set vendID "01000002"			
		set selfType "APP"
		set keyRev "1C"
    }
	## ------------- DONE "DEV_FLASH/xxxx" module checks  ----------------
	#
	#
	################ END OF AUTH_IDs TABLE ####################
	
	# ----- IF WE COULD NOT FIND THE "SELF" MATCH ABOVE, THEN CHECK HERE -----
	#
	# Load the pre-defined application var into a loop and compare it against the loaded self,
	# search for the "::SELF" filename within the "patchself" string, as it's a full
	# "dev_flash/xxxx" path
	if { $authID == "" } {
		log "AUTHID was not found in lookup list, trying failsafe list..."
		foreach patchSelf ${::APPSELF} {
			set tempfile ${patchSelf}.elf
			if { ([string first ${::SELF} $tempfile 0] != -1) } {
				# if we found our "dev_flash/xxx" file in the list				
				set authID "1070000052000001"				
				set compress TRUE
				set vendID "01000002"
				set selfType "APP"					
				if { ${::SUF} == ${::c} || ${::SUF} == ${::d} } {
					set keyRev "1C"
				} elseif { ${::SUF} == ${::a} } {
					set keyRev "04"
				} elseif { ${::SUF} == ${::b} } {
					set keyRev "0A"
				}
			}
		}
	}
	## make sure we have a valid authID, if it's blank, 
	## then we have an unhandled SELF type that needs to be added!!
	if { $authID == "" } {
		#### CURRENTLY UNHANDLED TYPE - if dies here, fix the script to add  #####		
		die "Unhandled SELF TYPE:\"${::SELF}\", fix script to support it!"
	}		
	# run the scetool to resign the elf file
    shell ${::SCETOOL} -0 SELF -1 $compress -2 $keyRev -3 $authID -4 $vendID -5 $selfType -A $versionVar -6 $fwversiVar -e $in $out
}

proc decrypt_self {in out} {
    debug "Decrypting self file [file tail $in]"
    catch_die {unself $in $out} "Could not decrypt file [file tail $in]"
}

proc sign_elf {in out} {
    debug "Rebuilding self file [file tail $out]"
    catch_die {makeself $in $out} "Could not rebuild file [file tail $out]"
}

proc modify_self_file {file callback args} {
    log "Modifying self/sprx file [file tail $file]"
    decrypt_self $file ${file}.elf
    eval $callback ${file}.elf $args
    sign_elf ${file}.elf ${file}.self
	#file copy -force ${file}.self ${::BUILD_DIR}    # used for debugging to copy the patched elf and new re-signed self to MFW build dir without the need to unpup the whole fw or even a single file
    file rename -force ${file}.self $file
	#file copy -force ${file}.elf ${::BUILD_DIR}     # same as above
    file delete ${file}.elf
	debug "Self successfully rebuilt"
	log "Self successfully rebuilt"
}

proc patch_self {file search replace_offset replace {ignore_bytes {}}} {
    modify_self_file $file patch_elf $search $replace_offset $replace $ignore_bytes
}
# proc for patching files matching the pattern with replace bytes,
# added the global "flag" check for multi-pattern replace, verus
# usual "single" pattern match
proc patch_elf {file search replace_offset replace {ignore_bytes {}}} {
	if { $::FLAG_PATCH_FILE_MULTI != 0 } {
		patch_file_multi $file $search $replace_offset $replace $ignore_bytes
		set ::FLAG_PATCH_FILE_MULTI 0
	} else {
		patch_file $file $search $replace_offset $replace $ignore_bytes
	}
}

proc patch_file {file search replace_offset replace {ignore_bytes {}}} {
    foreach bytes $ignore_bytes {
        if {[llength $bytes] == 1} {
            set search [string replace $search $bytes $bytes "?"]
        } elseif {[llength $bytes] == 2} {
            set idx1 [lindex $bytes 0]
            set idx2 [lindex $bytes 1]
            set len [expr {$idx2 - $idx1 + 1}]
            if {$len < 0} {
                set len 0
            }
            set search [string replace $search $idx1 $idx2 [string repeat "?" $len]]
        }
    }
    set fd [open $file r+]
    fconfigure $fd -translation binary
    set offset -1
    set buffer ""
    while {![eof $fd]} {
        append buffer [read $fd 1]
        if {[string length $buffer] > [string length $search]} {
            set buffer [string range $buffer 1 end]
        }
        set tmp $buffer
        foreach bytes $ignore_bytes {
            if {[llength $bytes] == 1} {
                set tmp [string replace $tmp $bytes $bytes "?"]
            } elseif {[llength $bytes] == 2} {
                set idx1 [lindex $bytes 0]
                set idx2 [lindex $bytes 1]
                set len [expr {$idx2 - $idx1 + 1}]
                if {$len < 0} {
                    set len 0
                }
                set tmp [string replace $tmp $idx1 $idx2 [string repeat "?" $len]]
            }
        }
        if {$tmp == $search} {
            if {$offset != -1} {
                error "Pattern found multiple times"
            }
            set offset [tell $fd]
            incr offset -[string length $search]
            incr offset $replace_offset
        }
    }
    if {$offset == -1} {
        error "Could not find pattern to patch"
    }
	set offsetInHex [format %x $offset]
    #debug "offset: $offset"
	debug "patched offset: 0x$offsetInHex"	
    seek $fd $offset
    puts -nonewline $fd $replace
    close $fd
}

proc patch_file_multi {file search replace_offset replace {ignore_bytes {}}} {
    foreach bytes $ignore_bytes {
        if {[llength $bytes] == 0} {
            set search [string replace $search $bytes $bytes "?"]
        } else {
            set search [string replace $search [lindex $bytes 0] [lindex $bytes 1] "?"]
        }
    }
    set fd [open $file r+]
    fconfigure $fd -translation binary
    set offset -1
    set counter 0
    set buffer ""
    while {![eof $fd]} {
        append buffer [read $fd 1]
        if {[string length $buffer] > [string length $search]} {
            set buffer [string range $buffer 1 end]
        }
        set tmp $buffer
        foreach bytes $ignore_bytes {
            if {[llength $bytes] == 0} {
                set tmp [string replace $tmp $bytes $bytes "?"]
            } else {
                set tmp [string replace $tmp [lindex $bytes 0] [lindex $bytes 1] "?"]
            }
        }
        if {$tmp == $search} {
            incr counter 1
            set offset [tell $fd]
            incr offset -[string length $search]
            incr offset $replace_offset
			set offsetInHex [format %x $offset]
            #debug "offset: $offset"
			debug "patched offset: 0x$offsetInHex"
            seek $fd $offset
            puts -nonewline $fd $replace
            seek $fd $offset
            set offset -1
        }
    }
    if {$counter == 0} {
        error "Could not find pattern to patch"
    } else {
        debug "Replaced $counter occurences of search pattern"
    }
    close $fd
}

proc modify_devflash_file {file callback args} {

    log "Modifying dev_flash file [file tail $file]"
	
    set tar_file [find_devflash_archive ${::CUSTOM_DEVFLASH_DIR} $file]
    if {$tar_file == ""} {
        die "Could not find [file tail $file] in devflash file"
    }

    set pkg_file [file tail [file dirname $tar_file]]
    debug "Found [file tail $file] in $pkg_file"

    file delete -force [file join ${::CUSTOM_DEVFLASH_DIR} dev_flash]			
	# extract the original flash file
    extract_tar $tar_file ${::CUSTOM_DEVFLASH_DIR}	

    if {[file writable [file join ${::CUSTOM_DEVFLASH_DIR} $file]] } {		
        eval $callback [file join ${::CUSTOM_DEVFLASH_DIR} $file] $args
    } elseif { ![file exists [file join ${::CUSTOM_DEVFLASH_DIR} $file]] } {
        die "Could not find $file in ${::CUSTOM_DEVFLASH_DIR}"
    } else {
        die "File $file is not writable in ${::CUSTOM_DEVFLASH_DIR}"
    }

    file delete -force $tar_file
    create_tar $tar_file ${::CUSTOM_DEVFLASH_DIR} dev_flash	
    
    set pkg [file join ${::CUSTOM_UPDATE_DIR} $pkg_file]
    set unpkgdir [file join ${::CUSTOM_DEVFLASH_DIR} $pkg_file]
	::pkg_archive $unpkgdir $pkg
	
	# commenting out, as we should not need
	# to do this?
    #if {[::get_pup_version] >= ${::NEWCFW}} {
    #    ::new_pkg_archive $unpkgdir $pkg
    #    ::copy_spkg
    #} else {
    #    ::pkg_archive $unpkgdir $pkg
    #}
}

proc modify_devflash_files {path files callback args} {

    foreach file $files {
        set file [file join $path $file]
        log "Modifying dev_flash file [file tail $file] in devflash file"
        
        set tar_file [find_devflash_archive ${::CUSTOM_DEVFLASH_DIR} $file]        
        if {$tar_file == ""} {
            debug "Skipping [file tail $file] not found"
            continue
        }
        
        set pkg_file [file tail [file dirname $tar_file]]
        debug "Found [file tail $file] in $pkg_file"
       
        file delete -force [file join ${::CUSTOM_DEVFLASH_DIR} dev_flash]		
        extract_tar $tar_file ${::CUSTOM_DEVFLASH_DIR}
	 
        if {[file writable [file join ${::CUSTOM_DEVFLASH_DIR} $file]] } {
		    set ::SELF $file
			log "Using file $file now"
            eval $callback [file join ${::CUSTOM_DEVFLASH_DIR} $file] $args
        } elseif { ![file exists [file join ${::CUSTOM_DEVFLASH_DIR} $file]] } {
            debug "Could not find $file in ${::CUSTOM_DEVFLASH_DIR}"
        } else {
            die "File $file is not writable in ${::CUSTOM_DEVFLASH_DIR}"
        }
        
        file delete -force $tar_file        
        create_tar $tar_file ${::CUSTOM_DEVFLASH_DIR} dev_flash		
        
        set pkg [file join ${::CUSTOM_UPDATE_DIR} $pkg_file]
        set unpkgdir [file join ${::CUSTOM_DEVFLASH_DIR} $pkg_file]
		::pkg_archive $unpkgdir $pkg
		
		# commenting out, as we should not need
		# to do this?
        #if {[::get_pup_version] >= ${::NEWCFW}} {
        #    ::new_pkg_archive $unpkgdir $pkg
        #    ::copy_spkg
        #} else {
        #    ::pkg_archive $unpkgdir $pkg
        #}
    }
	
}

proc modify_upl_file {callback args} {
    log "Modifying UPL.xml file"
    set file "content"
    
    set pkg [file join ${::CUSTOM_UPDATE_DIR} UPL.xml.pkg]
    set unpkgdir [file join ${::CUSTOM_UPDATE_DIR} UPL.xml.unpkg]

    ::unpkg_archive $pkg $unpkgdir

    if {[file writable [file join $unpkgdir $file]] } {
        eval $callback [file join $unpkgdir $file] $args
    } elseif { ![file exists [file join $unpkgdir $file]] } {
        die "Could not find $file in $unpkgdir"
    } else {
        die "File $file is not writable in $unpkgdir"
    }

    if {[::get_pup_version] >= ${::NEWCFW}} {
        ::new_pkg_archive $unpkgdir $pkg
        ::copy_spkg
    } else {
        ::pkg_archive $unpkgdir $pkg
    }
}

proc remove_node_from_xmb_xml { xml key message} {
    log "Removing \"$message\" from XML"

    while { [::xml::GetNodeByAttribute $xml "XMBML:View:Attributes:Table" key $key] != "" } {
        set xml [::xml::RemoveNode $xml [::xml::GetNodeIndicesByAttribute $xml "XMBML:View:Attributes:Table" key $key]]
    }
    while { [::xml::GetNodeByAttribute $xml "XMBML:View:Items:Query" key $key] != "" } {
        set xml [::xml::RemoveNode $xml [::xml::GetNodeIndicesByAttribute $xml "XMBML:View:Items:Query" key $key]]
    }

    return $xml
}

proc change_build_upl_xml { xml key message } {
    log "Not implemented yet"
}

proc remove_pkg_from_upl_xml { xml key message } {
    log "Removing \"$message\" package from UPL.xml" 1

    set i 0
    while { 1 } {
        set index [::xml::GetNodeIndices $xml "UpdatePackageList:Package" $i]
        if {$index == "" } break
        set node [::xml::GetNodeByIndex $xml $index]
        set data [::xml::GetData $node "Package:Type"]
        #debug "index: $index :: node: $node :: data: $data"
        if {[string equal $data $key] == 1 } {
            #debug "data: $data :: key: $key"
            set xml [::xml::RemoveNode $xml $index]
            break
        }
        incr i 1
    }
    return $xml
}

proc remove_pkgs_from_upl_xml { xml key message } {
    log "Removing \"$message\" packages from UPL.xml" 1

    set i 0
    while { 1 } {
        set index [::xml::GetNodeIndices $xml "UpdatePackageList:Package" $i]
        if {$index == "" } break
        set node [::xml::GetNodeByIndex $xml $index]
        set data [::xml::GetData $node "Package:Type"]
        #debug "index: $index :: node: $node :: data: $data"
        if {[string equal $data $key] == 1 } {
            #debug "data: $data :: key: $key"
            set xml [::xml::RemoveNode $xml $index]
            incr i -1
        }
        incr i 1
    }
    return $xml
}

# .rco files handling routines
proc rco_dump {rco rco_xml rco_dir} {
    shell ${::RCOMAGE} dump [file nativename $rco] [file nativename $rco_xml] --resdir [file nativename $rco_dir]
}

proc rco_compile {rco_xml rco_new} {
    set RCOMAGE_OPTS "--pack-hdr zlib --zlib-method default --zlib-level 9"
    shell ${::RCOMAGE} compile [file nativename $rco_xml] [file nativename $rco_new] {*}$RCOMAGE_OPTS
}

proc unpack_rco_file {rco rco_xml rco_dir} {
    log "unpacking rco file [file tail $rco]"
    catch_die {rco_dump $rco $rco_xml $rco_dir} "Could not unpack rco file [file tail $rco]"
}

proc pack_rco_file {rco_xml rco_new} {
    log "packing rco file [file tail $rco_new]"
    catch_die {rco_compile $rco_xml $rco_new} "Could not pack rco file [file tail $rco_new]"
}

proc callback_modify_rco {rco_file callback callback_args} {
    set RCO_XML ${rco_file}.xml
    set RCO_DIR ${rco_file}_dir
    set RCO_NEW ${rco_file}.new

    catch_die {file mkdir $RCO_DIR} "Could not create dir $RCO_DIR"
    unpack_rco_file $rco_file $RCO_XML $RCO_DIR

    eval $callback $RCO_DIR $callback_args

    pack_rco_file $RCO_XML $RCO_NEW
    catch_die {
        file rename -force $RCO_NEW $rco_file
        file delete -force $RCO_XML
        file delete -force $RCO_DIR
    } "Could not cleanup files after modifying [file tail $rco_file]"
}

proc modify_rco_file {rco_file callback args} {
    modify_devflash_file $rco_file callback_modify_rco $callback $args
}

# RCO callback for multiple files
proc modify_rco_files {path rco_files callback args} {
    modify_devflash_files $path $rco_files callback_modify_rco $callback $args
}

proc get_header_key_upl_xml { file key message } {
    debug "Getting \"$message\" information from UPL.xml"

    set xml [::xml::LoadFile $file]
    set data [::xml::GetData $xml "UpdatePackageList:Header:$key"]
    if {$data != ""} {
        debug "$key: $data"
        return $data
    }
    return ""
}

proc set_header_key_upl_xml { file key replace message } {
    log "Setting \"$message\" information in UPL.xml" 1

    set xml [::xml::LoadFile $file]

    set search [::xml::GetData $xml "UpdatePackageList:Header:$key"]
    if {$search != "" } {
        debug "$key: $search -> $replace"
        set fd [open $file r]
        set xml [read $fd]
        close $fd
     
        set xml [string map [list $search $replace] $xml]
     
        set fd [open $file w]
        puts -nonewline $fd $xml
        close $fd
        return $search
    }
    return ""
}

proc unspp {in out} {
    shell ${::UNSPP} [file nativename $in] [file nativename $out]
}

proc spp {in out} {
    shell ${::SPP} 355 [file nativename $in] [file nativename $out]
}

proc decrypt_spp {in out} {
    debug "Decrypting spp file [file tail $in]"
    catch_die {unspp $in $out} "Could not decrypt file [file tail $in]"
}

proc patch_pp {file search replace_offset replace {ignore_bytes {}}} {
    patch_file $file $search $replace_offset $replace $ignore_bytes
}

proc sign_pp {in out} {
    debug "Rebuilding spp file [file tail $out]"
    catch_die {spp $in $out} "Could not rebuild file [file tail $out]"
}

proc modify_spp_file {file callback args} {
    log "Modifying spp file [file tail $file]"
    decrypt_spp $file ${file}.pp
    eval $callback ${file}.pp $args
    sign_pp ${file}.pp $file
    file delete ${file}.pp
}
