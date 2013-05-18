#* 
#* ------------------------------------------------------------------
#* QWKFunctions.tcl - QWK Functions
#* Created by Robert Heller on Sat May 27 16:01:09 2006
#* ------------------------------------------------------------------
#* Modification History: $Log$
#* Modification History: Revision 1.4  2007/07/12 16:54:47  heller
#* Modification History: Lockdown: 1.0.4
#* Modification History:
#* Modification History: Revision 1.3  2006/06/03 19:58:59  heller
#* Modification History: Final 06032006-1
#* Modification History:
#* Modification History: Revision 1.1  2006/06/02 02:39:49  heller
#* Modification History: Mostly Done!
#* Modification History:
#* Modification History: Revision 1.1  2002/07/28 14:03:50  heller
#* Modification History: Add it copyright notice headers
#* Modification History:
#* ------------------------------------------------------------------
#* Contents:
#* ------------------------------------------------------------------
#*  
#*     TkNews II -- News/Mail reader, version 2
#* 
#*     Copyright (C) 2006  Robert Heller D/B/A Deepwoods Software
#* 			51 Locke Hill Road
#* 			Wendell, MA 01379-9728
#* 
#*     This program is free software; you can redistribute it and/or modify
#*     it under the terms of the GNU General Public License as published by
#*     the Free Software Foundation; either version 2 of the License, or
#*     (at your option) any later version.
#* 
#*     This program is distributed in the hope that it will be useful,
#*     but WITHOUT ANY WARRANTY; without even the implied warranty of
#*     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#*     GNU General Public License for more details.
#* 
#*     You should have received a copy of the GNU General Public License
#*     along with this program; if not, write to the Free Software
#*     Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#* 
#*  
#* 

namespace eval QWK {
  snit::type QWKFileProcess {
    typevariable busyFlag no
    typemethod isBusyP {} {return $busyFlag}
    component progressWindow
    variable stdoutPipeFp
    variable processRunning
    variable processErrorP
    variable done
    variable status
    option -nocomplain -readonly yes -default no -validatemethod _CheckBoolean
    option -doreply    -readonly yes -default no -validatemethod _CheckBoolean
    method _CheckBoolean {option value} {
      if {[string is boolean -strict "$value"]} {
        return $value"
      } else {
        error "Expected a boolean value for $option, got $value"
      }
    }
    option -spool -readonly yes
    option -recycleprocesswindow -readonly yes
    option -parent -readonly yes -default .

    constructor {args} {
      set myprog yes
      set options(-nocomplain) [from args -nocomplain]
      if {$busyFlag} {
	set status "Already fatching a QWK file -- try again later!"
	if {!$options(-nocomplain)} {
	  error "Already fatching a QWK file -- try again later!"
	}
	return
      }
      set busyFlag yes
      set done 0
      set processRunning 0
      set status {}
      set options(-spool) [from args -spool]
      if {![info exists options(-spool)] || 
	  [string length $options(-spool)] == 0} {
	set busyFlag no
	error "-spool is a required option!"
      }
      set spoolWindow [Spool::SpoolWindow getSpoolByName $options(-spool)]
      if {[string length "$spoolWindow"] == 0} {
	set toplevel .[string tolower $options(-spool)]
	toplevel $toplevel -class SpoolWindow
	set command [option get $toplevel qwkGetMailCommand QwkGetMailCommand]
	destroy $toplevel
      } else {
	set command [option get $spoolWindow qwkGetMailCommand QwkGetMailCommand]
      }
#      puts stderr "*** $self constructor: command = $command"
      if {[string length "$command"] == 0} {
	set busyFlag no
	set status "$options(-spool) is not a QWK Spool!"
	if {!$options(-nocomplain)} {
	  error "$options(-spool) is not a QWK Spool!"
	}
	return
      }
      set spoolWindow [Spool::SpoolWindow getOrMakeSpoolByName $options(-spool)]
#      puts stderr "*** $self constructor: spoolWindow = $spoolWindow"
      set options(-recycleprocesswindow) [from args -recycleprocesswindow {}]
#      puts stderr "*** $self constructor: options(-recycleprocesswindow) = $options(-recycleprocesswindow)"
      if {[string length $options(-recycleprocesswindow)] > 0 &&
	  [winfo exists  $options(-recycleprocesswindow)]} {
	incr done
	set progressWindow $options(-recycleprocesswindow)
	set myprog no
      } else {
	set options(-parent) [from args -parent $spoolWindow]
#	puts stderr "*** $self constructor: options(-parent) = $options(-parent)"
	install progressWindow using \
	   Common::BackgroundShellProcessWindow $spoolWindow.getQWKFile%AUTO% \
		-title "Getting QWK file for spool $options(-spool)" \
		-parent $options(-parent)
      }
#      puts stderr "*** $self: progressWindow = $progressWindow"
      if {![string equal [wm state $spoolWindow] normal]} {
	wm deiconify $spoolWindow
	wm deiconify $progressWindow
      }
      regsub {^[0-9x]*} [wm geometry $progressWindow] 725x400 geo
      regsub {^[0-9x]*} [wm geometry [winfo toplevel [winfo parent $progressWindow]]] {} parentGeo
      regsub {\+0\+0} "$geo" $parentGeo geo
      wm geometry $progressWindow $geo
      raise $progressWindow
#      puts stderr "*** $self constructor: progressWindow = $progressWindow"
      $self configurelist $args
      if {$options(-doreply)} {
	catch {QWK::MakeQWKReply $options(-spool) -replace no -quiet yes \
					-recycleprocesswindow $progressWindow}
      }
      if {[catch [list open "|$command" r] stdoutPipeFp]} {
	set status "Could not fork $command: $stdoutPipeFp"
	set busyFlag no
	error "Could not fork $command: $stdoutPipeFp"
      }
      $progressWindow setStatus "Running: $command"
      $progressWindow setProgress -1
      $progressWindow configure -abortfunction [mymethod _AbortProcess]
      incr processRunning
      fileevent $stdoutPipeFp readable [mymethod _PipeToLog]
      if {$processRunning > 0} {tkwait variable [myvar processRunning]}
      $progressWindow configure -abortfunction {}
      incr done
      if {$processErrorP} {
	set busyFlag no
        $progressWindow setProcessDone
	return
      }
      catch {QWK::RescanQWKSpool}
      global QWKInSpool
      set qwkFile [file join $QWKInSpool "$options(-spool).qwk"]
      if {[file exists "$qwkFile"]} {
	if {[catch [list $spoolWindow reload -fromQWK "$qwkFile" \
			    -recycleprocesswindow $progressWindow] error]} {
	  global errorInfo errorCode
	  set ei "$errorInfo"
	  set ec "$errorCode"
	  catch {
	    $progressWindow setStatus "$error"
	    $progressWindow setProgress -1
	    if {$myprog} {$progressWindow setProcessDone}
	    set busyFlag no
 	  }
	  error "$error" "$ei" "$ec"
	  return
	}
      }
      $progressWindow setStatus "Done"
      $progressWindow setProgress -1
      if {$myprog} {$progressWindow setProcessDone}
      set busyFlag no
    }
    destructor {
      catch {if {!$done} {destroy $progressWindow}}
    }
    method _PipeToLog {} {
#      puts stderr "*** ${self}::_PipeToLog: captureUsernameP = $captureUsernameP, stdoutPipeFp = $stdoutPipeFp"
      if {[gets $stdoutPipeFp line] >= 0} {
	$progressWindow addTextToLog "$line"
      } else {
	set processErrorP [catch "close $stdoutPipeFp"]
	incr processRunning -1
      }
      update idle
    }
    method _AbortProcess {} {
      set pid [pid $stdoutPipeFp]
      if {![string equal "$pid" {}]} {
        catch "exec /usr/bin/kill $pid"
      }
      catch "close $stdoutPipeFp"
      set processErrorP yes
      incr processRunning -1
    }
    method getStatus {} {
      return "$status"
    }
  }
  snit::type LoadQWKFile {
    component progressWindow
    variable stdoutPipeFp
    variable processRunning
    variable done
    variable username
    option -file -readonly yes
    option -activefile -readonly yes
    option -spooldirectory -readonly yes
    option -newsrc -readonly yes
    option -recycleprocesswindow -readonly yes
    option -parent -readonly yes -default .
    option -killfile -readonly yes -default {}

    constructor {args} {
      set myprog yes
      set done 0
      set processRunning 0
      global env
      set username "$env(USER)"
      set options(-file) [from args -file]
      if {![info exists options(-file)]} {
	error "-file is a required option!"
      }
      if {![file readable "$options(-file)"]} {
	error "-file is not a readable file!"
      }
      set options(-activefile) [from args -activefile]
      if {![info exists options(-activefile)]} {
	error "-activefile is a required option!"
      }
      if {![file writable "$options(-activefile)"]} {
	error "-activefile is not a writable file!"
      }
      set options(-spooldirectory) [from args -spooldirectory]
      if {![info exists options(-spooldirectory)]} {
	error "-spooldirectory is a required option!"
      }
      if {![file writable "$options(-spooldirectory)"] ||
	  ![file isdirectory "$options(-spooldirectory)"]} {
	error "-spooldirectory is not a writable directory!"
      }
      set options(-newsrc) [from args -newsrc]
      if {![info exists options(-newsrc)]} {
	error "-newsrc is a required option!"
      }
      if {![file writable "$options(-newsrc)"]} {
	error "-newsrc is not a writable file!"
      }
      set options(-recycleprocesswindow) [from args -recycleprocesswindow {}]
      if {[string length $options(-recycleprocesswindow)] > 0 &&
	  [winfo exists  $options(-recycleprocesswindow)]} {
	incr done
	set progressWindow $options(-recycleprocesswindow)
	set myprog no
      } else {
        set options(-parent) [from args -parent]
        if {[string equal "$options(-parent)" {.}]} {
	  set window .qwkProcess%AUTO%
	} else {
	  set window $options(-parent).qwkProcess%AUTO%
	}
        install progressWindow using \
		Common::BackgroundShellProcessWindow $window \
      			-title "Loading QWK file $options(-file)" \
			-parent $options(-parent)
      }
      if {![string equal [wm state $progressWindow] normal]} {
	wm deiconify $progressWindow
      }
      regsub {^[0-9x]*} [wm geometry $progressWindow] 725x400 geo
      regsub {^[0-9x]*} [wm geometry [winfo toplevel [winfo parent $progressWindow]]] {} parentGeo
      regsub {\+0\+0} "$geo" $parentGeo geo
      wm geometry $progressWindow $geo
      $self configurelist $args
      global QWKWorkDir QWKUnarchiver
      if {![file exists $QWKWorkDir]} {
	if {[catch "file mkdir $QWKWorkDir" err]} {
	  error "Cannot create work directory $QWKWorkDir: $err"
	  return
	}
      } elseif {![file isdirectory $QWKWorkDir]} {
	error "$QWKWorkDir exists and is not a directory!"
	return
      }
      catch [concat file delete -force [glob -nocomplain $QWKWorkDir/*]]
      set here [pwd]
      if {[catch {
	cd $QWKWorkDir
	set stdoutPipeFp [open "|$QWKUnarchiver $options(-file)" r]
	$progressWindow setStatus "Running: $QWKUnarchiver $options(-file)"
        $progressWindow setProgress -1
	incr processRunning
#	puts stderr "*** ${self}::constructor: processRunning = $processRunning"
	fileevent $stdoutPipeFp readable "[mymethod _PipeToLog] no"
#	puts stderr "*** ${self}::constructor: processRunning = $processRunning"
	if {$processRunning > 0} {tkwait variable [myvar processRunning]}
#	puts stderr "*** ${self}::constructor: processRunning = $processRunning"
      } error]} {
	cd $here
 	$progressWindow setStatus "$error"
	$progressWindow setProgress -1
	if {$myprog} {$progressWindow setProcessDone}
	error $error
	return
      }
      cd $here
      global QWKToSpoolProg
      if {[file exists $QWKWorkDir/control.dat]} {
	set control [file join $QWKWorkDir/control.dat]
      } elseif {[file exists $QWKWorkDir/CONTROL.DAT]} {
	set control [file exists $QWKWorkDir/CONTROL.DAT]
      } else {
 	$progressWindow setStatus "Control file missing!"
	$progressWindow setProgress -1
	if {$myprog} {$progressWindow setProcessDone}
	error "Control file missing!"
      }
      if {[file exists $QWKWorkDir/messages.dat]} {
	set messages [file join $QWKWorkDir/messages.dat]
      } elseif {[file exists $QWKWorkDir/MESSAGES.DAT]} {
	set messages [file exists $QWKWorkDir/MESSAGES.DAT]
      } else {
	$progressWindow setStatus "Messages file missing!"
	$progressWindow setProgress -1
	if {$myprog} {$progressWindow setProcessDone}
	error "Messages file missing!"
      }
      set command [list $QWKToSpoolProg $control $messages \
		$options(-activefile) $options(-spooldirectory) \
		$options(-newsrc) "$options(-killfile)"]
#      puts stderr "*** ${self}::constructor: about to start $command"
      global env
      if {[catch [list open "|$command" r] stdoutPipeFp]} {
        error "Error: open \"|$command\" r: $stdoutPipeFp"
        return
      }
#      puts stderr "*** ${self}::constructor: stdoutPipeFp = $stdoutPipeFp"
#      puts stderr "*** ${self}::constructor: fconfigure $stdoutPipeFp = [fconfigure $stdoutPipeFp]"
      $progressWindow setStatus "Running: $QWKToSpoolProg ..."
      $progressWindow setProgress 0
      incr processRunning 
#      puts stderr "*** ${self}::constructor: processRunning = $processRunning"
      fileevent $stdoutPipeFp readable "[mymethod _PipeToLog] yes"
#      puts stderr "*** ${self}::constructor: processRunning = $processRunning"
      if {$processRunning > 0} {tkwait variable [myvar processRunning]}
#      puts stderr "*** ${self}::constructor: processRunning = $processRunning"
      if {[string length "$options(-recycleprocesswindow)"] == 0} {incr done}
      $progressWindow setStatus "Done"
      $progressWindow setProgress -1
      if {$myprog} {$progressWindow setProcessDone}
    }
    destructor {
      global QWKWorkDir
      catch {if {!$done} {destroy $progressWindow}}
      catch [concat file delete -force [glob -nocomplain $QWKWorkDir/*]]
    }
    method getUserName {} {return $username}
    method _PipeToLog {captureUsernameP} {
#      puts stderr "*** ${self}::_PipeToLog: captureUsernameP = $captureUsernameP, stdoutPipeFp = $stdoutPipeFp"
      if {[gets $stdoutPipeFp line] >= 0} {
	if {[regexp {^###([0-9.]*)$} $line -> progress] > 0} {
	  $progressWindow setProgress [expr int($progress * 100)]
	} else {
	  if {$captureUsernameP} {regexp {^Username: (.*)$} "$line" -> username}
	  $progressWindow addTextToLog "$line"
	}
      } else {
	catch "close $stdoutPipeFp"
	incr processRunning -1
      }
      update idle
    }
  }
  snit::type QWKReplyProcess {
    component progressWindow
    variable stdoutPipeFp
    variable processRunning
    variable done
    variable status
    variable numPacked
    option -replace -readonly yes -default no -validatemethod _CheckBoolean
    option -quiet -readonly yes -default no -validatemethod _CheckBoolean
    method _CheckBoolean {option value} {
      if {[string is boolean -strict "$value"]} {
        return $value"
      } else {
        error "Expected a boolean value for $option, got $value"
      }
    }
    option -spool -readonly yes
    option -recycleprocesswindow -readonly yes
    option -parent -readonly yes -default .
    constructor {args} {
      set myprog yes
      global QWKOutSpool QWKWorkDir
      set done 0
      set processRunning 0
      set status {}
      set options(-spool) [from args -spool]
      if {![info exists options(-spool)] || 
	  [string length $options(-spool)] == 0} {
	error "-spool is a required option!"
      }
      set options(-replace) [from args -replace]
      set options(-quiet) [from args -quiet]
      set archive [file join $QWKOutSpool "$options(-spool).rep"]
      if {[file exists $archive]} {
	if {!$options(-replace)} {
	  if {!$options(-quiet)} {
	    if {[tk_messageBox -type yesno -icon question \
		-message "$archive exists, remove it?"]} {
	      catch "file delete -force $archive"
	    } else {
	      return
	    }
	  } else {
	    return
	  }
	} else {
	  catch "file delete -force $archive"
	}
      }
      if {![file exists $QWKWorkDir]} {
	if {[catch "file mkdir $QWKWorkDir" err]} {
	  error "Cannot create work directory $QWKWorkDir: $err"
	  return
	}
      } elseif {![file isdirectory $QWKWorkDir]} {
	error "$QWKWorkDir exists and is not a directory!"
	return
      }
      catch [concat file delete -force [glob -nocomplain $QWKWorkDir/*]]
      set msgFile [file join $QWKWorkDir "$options(-spool).msg"]
      set spoolWindow [Spool::SpoolWindow getOrMakeSpoolByName $options(-spool)]
      set options(-recycleprocesswindow) [from args -recycleprocesswindow {}]
      if {[string length $options(-recycleprocesswindow)] > 0 &&
	  [winfo exists  $options(-recycleprocesswindow)]} {
	incr done
	set progressWindow $options(-recycleprocesswindow)
        set myprog no
      } else {
	set options(-parent) [from args -parent $spoolWindow]
	install progressWindow using \
	   Common::BackgroundShellProcessWindow $spoolWindow.makeQWKReply%AUTO% \
		-title "Getting QWK file for spool $options(-spool)" \
		-parent $options(-parent)
      }
      if {![string equal [wm state $spoolWindow] normal]} {
	wm deiconify $spoolWindow
	wm deiconify $progressWindow
      }
      regsub {^[0-9x]*} [wm geometry $progressWindow] 725x400 geo
      regsub {^[0-9x]*} [wm geometry [winfo toplevel [winfo parent $progressWindow]]] {} parentGeo
      regsub {\+0\+0} "$geo" $parentGeo geo
      wm geometry $progressWindow $geo
      $self configurelist $args
      set activeFile "[$spoolWindow cget -activefile]"
      set spoolDirectory "[$spoolWindow cget -spooldirectory]"
      set name "[$spoolWindow user]"
      global SpoolToReplyProg
      set command [list $SpoolToReplyProg "$activeFile" "$spoolDirectory" "$options(-spool)" "$name" "$msgFile"]
      if {[catch [list open "|$command" r] stdoutPipeFp]} {
	set status "Could not fork $command: $stdoutPipeFp"
	error "Could not fork $command: $stdoutPipeFp"
      }
      $progressWindow setStatus "Running: $command"
      $progressWindow setProgress -1
      set numPacked 0
      incr processRunning
      fileevent $stdoutPipeFp readable "[mymethod _PipeToLog] yes"
      if {$processRunning > 0} {tkwait variable [myvar processRunning]}
      if {$numPacked == 0} {
	$progressWindow setStatus "Done"
	if {$myprog} {$progressWindow setProcessDone}
	incr done
	return
      }
      global QWKArchiver
      set command "$QWKArchiver $archive $msgFile"
      if {[catch [list open "|$command" r] stdoutPipeFp]} {
	set status "Could not fork $command: $stdoutPipeFp"
	error "Could not fork $command: $stdoutPipeFp"
      }
      $progressWindow setStatus "Running: $command"
      $progressWindow setProgress -1
      incr processRunning
      fileevent $stdoutPipeFp readable "[mymethod _PipeToLog] no"
      if {$processRunning > 0} {tkwait variable [myvar processRunning]}
      $progressWindow setStatus "Done"
      if {$myprog} {$progressWindow setProcessDone}
      incr done
    }
    destructor {
      catch {if {!$done} {destroy $progressWindow}}
    }
    method getStatus {} {return "$status"}
    method _PipeToLog {getNumPacked} {
#      puts stderr "*** ${self}::_PipeToLog: captureUsernameP = $captureUsernameP, stdoutPipeFp = $stdoutPipeFp"
      if {[gets $stdoutPipeFp line] >= 0} {
	$progressWindow addTextToLog "$line"
	if {$getNumPacked} {
#	  puts stderr "*** $self _PipeToLog: line = $line"
	  regexp {^NumPacked:[[:space:]]*([0-9]*)$} "$line" -> numPacked
#	  puts stderr "*** $self _PipeToLog: numPacked = $numPacked"
	}
      } else {
	catch "close $stdoutPipeFp"
	incr processRunning -1
      }
      update idle
    }
  }
}

# Procedure: RescanQWKSpool
proc QWK::RescanQWKSpool {} {
  global QWKInSpool QWKList

  if {[catch "glob $QWKInSpool/*.qw?" qwkFiles]} {
    set qwkFiles {}
  }

  $QWKList delete [$QWKList items]
  foreach qwk [lsort -command QWK::fnsort $qwkFiles] {
    set tail [file tail $qwk]
    set size [file size $qwk]
    set date [clock format [file mtime $qwk] -format {%D@%T}]
    set line [format {%-12s %6d %s %s} $tail $size $date $qwk]
    $QWKList insert end $tail -text "$line" -data "$qwk"
  }
#  raise .
  focus $QWKList
}

# Procedure: fnsort
proc QWK::fnsort {A B} {
  set ATime [file mtime "$A"]
  set BTime [file mtime "$B"]
  return [expr $BTime - $ATime]
}

proc QWK::GetQWKFile {{spool {}} args} {
  if {[QWKFileProcess isBusyP]} {
    tk_messageBox -type ok -icon warning \
		  -message "Busy fetching a spool.  Try again later"
    return
  }
  if {[string length "$spool"] == 0} {set spool [Spool::GetSpoolName local no]}
  if {[string length "$spool"] == 0} {return}
  set process [eval [list QWKFileProcess $spool%AUTO% \
				-spool $spool -doreply yes] $args]
  set result [$process getStatus]
  $process destroy
  return $result
}

proc QWK::GetAllQWKFiles {{spoolList {}}} {
  if {[QWKFileProcess isBusyP]} {
    tk_messageBox -type ok -icon warning \
		  -message "Busy fetching a spool.  Try again later"
    return
  }
  if {[llength "$spoolList"] == 0} {
    set spoolList [option get . spoolList SpoolList]
  }
  foreach spool $spoolList {
    GetQWKFile $spool -nocomplain yes
  }
}

proc QWK::MakeQWKReply {{spool {}} args} {
  if {[string length "$spool"] == 0} {set spool [Spool::GetSpoolName local no]}
  if {[string length "$spool"] == 0} {return}
  set process [eval [list QWKReplyProcess $spool%AUTO% \
			-spool $spool] $args]
  set result [$process getStatus]
  $process destroy
  return $result
}

SplashWorkMessage "Loaded QWK Functions" [expr 5 * 16.66]

package provide QWKFunctions 1.0
