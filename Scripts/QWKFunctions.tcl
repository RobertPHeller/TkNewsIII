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

package require Tk;#                 GUI Toolkit
package require tile;#               Themed Widgets
package require snit;#               OO Framework
package require SpoolFunctions
package require CommonFunctions

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
        set spoolWindow [SpoolWindow getSpoolByName $options(-spool)]
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
        set spoolWindow [SpoolWindow getOrMakeSpoolByName $options(-spool)]
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
                  BackgroundShellProcessWindow $spoolWindow.getQWKFile%AUTO% \
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
            catch {QWKReplyProcess MakeQWKReply $options(-spool) -replace no -quiet yes \
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
        catch {.main RescanQWKSpool}
        set qwkFile [QWKList QWKFile "$options(-spool)"]
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
    typemethod GetQWKFile {{spool {}} args} {
        if {$busyFlag} {
            tk_messageBox -type ok -icon warning \
                  -message "Busy fetching a spool.  Try again later"
            return
        }
        if {[string length "$spool"] == 0} {set spool [SpoolWindow GetSpoolName local no]}
        if {[string length "$spool"] == 0} {return}
        set process [eval [list $type $spool%AUTO% \
                           -spool $spool -doreply yes] $args]
        set result [$process getStatus]
        $process destroy
        return $result
    }
    typemethod GetAllQWKFiles {{spoolList {}}} {
        if {$busyFlag} {
            tk_messageBox -type ok -icon warning \
                  -message "Busy fetching a spool.  Try again later"
            return
        }
        if {[llength "$spoolList"] == 0} {
            set spoolList [option get . spoolList SpoolList]
        }
        foreach spool $spoolList {
            $type GetQWKFile $spool -nocomplain yes
        }
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
                  BackgroundShellProcessWindow $window \
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
        
        if {![QWKList MakeWorkDir]} {return}
        QWKList CleanWorkDir
        set here [pwd]
        if {[catch {$self _unarchiverprocess} error]} {
            cd $here
            $progressWindow setStatus "$error"
            $progressWindow setProgress -1
            if {$myprog} {$progressWindow setProcessDone}
            error $error
            return
        }
        cd $here
        set control [QWKList ControlFile]
        if {$control eq {}} {
            $progressWindow setStatus "Control file missing!"
            $progressWindow setProgress -1
            if {$myprog} {$progressWindow setProcessDone}
            error "Control file missing!"
        }
        set messages [QWKList MessagesFile]
        if {$messages eq {}} {
            $progressWindow setStatus "Messages file missing!"
            $progressWindow setProgress -1
            if {$myprog} {$progressWindow setProcessDone}
            error "Messages file missing!"
        }
        set command [QWKList QWKToSpoolCommand $control $messages \
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
    method _unarchiverprocess {} {
        QWKList CdWorkDir
        set unarchiver [QWKList Unarchiver $options(-file)]
        set stdoutPipeFp [open "|$unarchiver" r]
        $progressWindow setStatus "Running: $unarchiver"
        $progressWindow setProgress -1
        incr processRunning
        #	puts stderr "*** ${self}::constructor: processRunning = $processRunning"
        fileevent $stdoutPipeFp readable "[mymethod _PipeToLog] no"
        #	puts stderr "*** ${self}::constructor: processRunning = $processRunning"
        if {$processRunning > 0} {tkwait variable [myvar processRunning]}
        #	puts stderr "*** ${self}::constructor: processRunning = $processRunning"
    }
    destructor {
        catch {if {!$done} {destroy $progressWindow}}
        QWKList CleanWorkDir
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
        set archive [QWKList QWKReply "$options(-spool)"]
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
        if {![QWKList MakeWorkDir]} {return}
        QWKList CleanWorkDir
        set msgFile [QWKList MessageFile "$options(-spool)"]
        set spoolWindow [SpoolWindow getOrMakeSpoolByName $options(-spool)]
        set options(-recycleprocesswindow) [from args -recycleprocesswindow {}]
        if {[string length $options(-recycleprocesswindow)] > 0 &&
            [winfo exists  $options(-recycleprocesswindow)]} {
            incr done
            set progressWindow $options(-recycleprocesswindow)
            set myprog no
        } else {
            set options(-parent) [from args -parent $spoolWindow]
            install progressWindow using \
                  BackgroundShellProcessWindow $spoolWindow.makeQWKReply%AUTO% \
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
        set command [QWKList SpoolToReplyCommand "$activeFile" \
                     "$spoolDirectory" "$options(-spool)" "$name" \
                     "$msgFile"]
        if {[catch {open "|$command" r} stdoutPipeFp]} {
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
        set command [QWKList Archiver $archive $msgFile]
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
    typemethod MakeQWKReply {{spool {}} args} {
        if {[string length "$spool"] == 0} {set spool [SpoolWindow GetSpoolName local no]}
        if {[string length "$spool"] == 0} {return}
        set process [eval [list $type $spool%AUTO% \
                           -spool $spool] $args]
        set result [$process getStatus]
        $process destroy
        return $result
    }
}
snit::widgetadaptor QWKList {
    typevariable columnheadings -array {
        name,stretch yes
        name,text Name
        name,anchor w
        name,width 80
        size,stretch no
        size,text Size
        size,anchor e
        size,width 50
        timestamp,stretch no
        timestamp,text {Time Stamp}
        timestamp,anchor w
        timestamp,width 150
        fullname,stretch yes
        fullname,text {File Name}
        fullname,anchor w
    }
    typevariable columns {name size timestamp fullname}
    typevariable QWKToSpoolProg 
    typemethod QWKToSpoolCommand {control messages activefile 
        spooldirectory newsrc killfile} {
        return [list $QWKToSpoolProg $control $messages $activefile \
                $spooldirectory $newsrc $killfile]
    }
    typevariable SpoolToReplyProg
    typemethod SpoolToReplyCommand {activeFile spoolDirectory spool name 
        msgFile} {
        return [list $SpoolToReplyProg $activeFile $spoolDirectory $spool \
                $name $msgFile]
    }
    typevariable QWKInSpool 
    typemethod   QWKFile {spool} {
        return [file join $QWKInSpool "${spool}.qwk"]
    }
    typevariable QWKOutSpool
    typemethod   QWKReply {spool} {
        return [file join $QWKOutSpool "${spool}.rep"]
    }
    typevariable QWKWorkDir
    typemethod MakeWorkDir {} {
        if {![file exists $QWKWorkDir]} {
            if {[catch "file mkdir $QWKWorkDir" err]} {
                error "Cannot create work directory $QWKWorkDir: $err"
                return false
            }
        } elseif {![file isdirectory $QWKWorkDir]} {
            error "$QWKWorkDir exists and is not a directory!"
            return false
        }
        return true
    }
    typemethod MessageFile {spool} {
        return [file join $QWKWorkDir "${spool}.msg"]
    }
    typemethod CdWorkDir {} {
        cd $QWKWorkDir
    }
    typemethod ControlFile {} {
        set controlfile1 [file join $QWKWorkDir control.dat]
        set controlfile2 [file join $QWKWorkDir CONTROL.DAT]
        if {[file exists $controlfile1]} {
            return $controlfile1
        } elseif {[file exists $controlfile2]} {
            return $controlfile2
        } else {
            return {}
        }
    }
    typemethod MessagesFile {} {
        set messagesfile1 [file join $QWKWorkDir messaes.dat]
        set messagesfile2 [file join $QWKWorkDir MESSAGES.DAT]
        if {[file exists $messagesfile1]} {
            return $messagesfile1
        } elseif {[file exists $messagesfile2]} {
            return $messagesfile2
        } else {
            return {}
        }
    }
    typevariable QWKArchiver
    typemethod   Archiver {archive msgFile} {
        return "$QWKArchiver $archive $msgFile"
    }
    typevariable QWKUnarchiver
    typemethod   Unarchiver {archive} {
        return "$QWKUnarchiver $archive"
    }
    typeconstructor {
        global execbindir
        set QWKToSpoolProg [auto_execok [file join $execbindir QWKToSpool]]
        set SpoolToReplyProg [auto_execok [file join $execbindir SpoolToReplyProg]]
        set QWKInSpool [file normalize [option get . qwkInSpool QWKInSpool]]
        set QWKOutSpool [file normalize [option get . qwkOutSpool QWKOutSpool]]
        set QWKWorkDir [file normalize [option get . qwkWorkDir QWKWorkDir]]
        set QWKArchiver "[option get . qwkArchiver QWKArchiver]"
        set QWKUnarchiver "[option get . qwkUnarchiver QWKUnarchiver]"
        bind $type <Motion>                [mytypemethod _Motion %W %x %y]
        bind $type <B1-Leave>              { #nothing }
        bind $type <Leave>                 [mytypemethod _ActivateHeading {} {}]
        bind $type <ButtonPress-1>         [mytypemethod _Press %W %x %y]
        bind $type <Double-ButtonPress-1>  [mytypemethod _DoubleClick %W %x %y]
        bind $type <ButtonRelease-1>       [mytypemethod _Release %W %x %y]
        bind $type <B1-Motion>             [mytypemethod _Drag %W %x %y]
        bind $type <KeyPress-Up>           [mytypemethod _Keynav %W up]
        bind $type <KeyPress-Down>         [mytypemethod _Keynav %W down]
        bind $type <KeyPress-Right>        [mytypemethod _Keynav %W right]
        bind $type <KeyPress-Left>         [mytypemethod _Keynav %W left]
        bind $type <KeyPress-Prior>        { %W yview scroll -1 pages }
        bind $type <KeyPress-Next>         { %W yview scroll  1 pages }
        bind $type <KeyPress-Return>       [mytypemethod _ToggleFocus %W]
        bind $type <KeyPress-space>        [mytypemethod _ToggleFocus %W]
        bind $type <Shift-ButtonPress-1>   [mytypemethod _Select %W %x %y extend]
        bind $type <Control-ButtonPress-1> [mytypemethod _Select %W %x %y toggle]
        ttk::copyBindings TtkScrollable $type
        ttk::style layout $type [ttk::style layout Treeview]
    }
    typevariable _hulls -array {}
    typemethod _Keynav {w dir} {
        ttk::treeview::Keynav $_hulls($w) dir
    }
    typemethod _Motion {w x y} {
        ttk::treeview::Motion $_hulls($w) $x $y
    }
    typemethod _ActivateHeading {w heading} {
        if {$w ne {}} {set w $_hulls($w)}
        ttk::treeview::ActivateHeading $w $heading
    }
    typemethod _Select {w x y op} {
        ttk::treeview::Select $_hulls($w) $x $y $op
    }
    typemethod _DoubleClick {w x y} {
        $w _invoke $x $y
    }
    typemethod _Press {w x y} {
        lassign [$_hulls($w) identify $x $y] what where detail
        focus $w	;# or: ClickToFocus?
        
        switch -- $what {
            nothing { }
            heading { ttk::treeview::heading.press $_hulls($w) $where }
            separator { ttk::treeview::resize.press $_hulls($w) $x $where }
            cell -
            row  -
            item { ttk::treeview::SelectOp $_hulls($w) $where choose }
        }
        if {$what eq "item" && [string match *indicator $detail]} {
            ttk::treeview::Toggle $_hulls($w) $where
        }
    }
    typemethod _Drag {w x y} {
        ttk::treeview::Drag $_hulls($w) $x $y
    }
    typemethod _Release {w x y} {
        ttk::treeview::Release $_hulls($w) $x $y
    }
    typemethod _ToggleFocus {w} {
        ttk::treeview::ToggleFocus $_hulls($w)
    }    
    delegate option -height to hull
    delegate option -xscrollcommand to hull
    delegate option -yscrollcommand to hull
    delegate method xview to hull
    delegate method yview to hull
    delegate method selection to hull
    method filename {item} {
        return [lindex [$hull item $item -values] 3]
    }
    option -command -default ""
    method _invoke {x y} {
        #puts stderr "*** $self _invoke $x $y"
        #puts stderr "*** $self _invoke: items are [$hull children {}]"
        #puts stderr "*** $self _invoke: selection is [$hull selection]"
        #puts stderr "*** $self _invoke: identify is [$hull identify $x $y]"
        lassign [$hull identify $x $y] what where detail
        if {$options(-command) ne ""} {
            uplevel #0 "$options(-command) $where"
        }
    }
    constructor {args} {
        installhull using ttk::treeview -columns $columns \
              -displaycolumns $columns -show {headings} \
              -style $type -class $type
        set _hulls($self) $hull
        $self configurelist $args
        #parray columnheadings
        foreach c $columns {
            #puts stderr "*** $type create $self: c = $c"
            set copts [list]
            if {[info exists columnheadings($c,stretch)]} {
                lappend copts -stretch $columnheadings($c,stretch)
            }
            if {[info exists columnheadings($c,width)]} {
                lappend copts -width $columnheadings($c,width)
            }
            if {[info exists columnheadings($c,anchor)]} {
                lappend copts -anchor $columnheadings($c,anchor)
            }
            #puts stderr "*** $type create $self: copts = $copts"
            if {[llength $copts] > 0} {
                eval [list $hull column $c] $copts
            }
            set hopts [list]
            if {[info exists columnheadings($c,text)]} {
                lappend hopts -text $columnheadings($c,text)
            }
            if {[info exists columnheadings($c,image)]} {
                lappend hopts -image $columnheadings($c,image)
            }
            if {[info exists columnheadings($c,anchor)]} {
                lappend hopts -anchor $columnheadings($c,anchor)
            }
            #puts stderr "*** $type create $self: hopts = $hopts"
            if {[llength $hopts] > 0} {
                eval [list $hull heading $c] $hopts
            }
        }
        $self RescanQWKSpool
    }
    method RescanQWKSpool {} {
        set qwkFiles [glob -nocomplain [file join $QWKInSpool *.qw?]]
        $hull delete [$hull children {}]
        foreach qwk [lsort -command [myproc fnsort] $qwkFiles] {
            set tail [file tail $qwk]
            set size [file size $qwk]
            set date [clock format [file mtime $qwk] -format {%D@%T}]
            $hull insert {} end -text {} \
                  -values [list $tail $size $date $qwk]
            focus $win
        }
    }
    proc fnsort {A B} {
        set ATime [file mtime "$A"]
        set BTime [file mtime "$B"]
        return [expr {$BTime - $ATime}]
    }
    typemethod CleanWorkDir {} {
        set files [glob -nocomplain $QWKWorkDir/*]
        catch {eval [list file delete -force] $files}
    }
}

package provide QWKFunctions 1.0
