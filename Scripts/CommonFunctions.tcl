#* 
#* ------------------------------------------------------------------
#* CommonFunctions.tcl - Common Functions
#* Created by Robert Heller on Sat May 27 15:52:38 2006
#* ------------------------------------------------------------------
#* Modification History: $Log$
#* Modification History: Revision 1.3  2007/07/12 16:54:46  heller
#* Modification History: Lockdown: 1.0.4
#* Modification History:
#* Modification History: Revision 1.2  2006/06/03 19:39:20  heller
#* Modification History: Final 06032006-1
#* Modification History:
#* Modification History: Revision 1.1  2006/06/02 02:39:48  heller
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

package require Tk
package require tile
package require snit
package require Dialog
package require ScrollWindow
package require MainFrame
package require ButtonBox

snit::type MessageList {
    pragma -hastypedestroy no
    pragma -hasinstances no
    pragma -hastypeinfo no
    
    typemethod CountMessages {list} {
        set count 0
        foreach m $list {
            if {[file isdirectory "$m"]} {continue}
            set m [file tail $m]
            if {[catch [list expr int($m)] i]} {continue}
            if {[string compare "$i" "$m"] == 0} {incr count}
        }
        return $count
    }
    typemethod Lowestnumber {list} {
        set result 0
        foreach i $list {
            if {[file isdirectory "$i"]} {continue}
            set i [file tail $i]
            if {[catch [list expr int($i)] j]} {continue}
            if {[string compare "$i" "$j"] == 0} {
                if {$result == 0} {
                    set result $i
                } elseif {$i < $result} {
                    set result $i
                }
            }
        }
        return $result
    }
    typemethod Highestnumber {list} {
        set result 0
        foreach i $list {
            if {[file isdirectory "$i"]} {continue}
            set i [file tail $i]
            if {[catch [list expr int($i)] j]} {continue}
            if {[string compare "$i" "$j"] == 0} {
                if {$result == 0} {
                    set result $i
                } elseif {$i > $result} {
                    set result $i
                }
            }
        }
        return $result
    }
}

snit::type GroupName {
    pragma -hastypedestroy no
    pragma -hasinstances no
    pragma -hastypeinfo no
    
    typemethod WindowName {group} {
        regsub -all -- {\.} $group {_} result
        return "[string tolower $result]"
    }
    

    typemethod Path { group} {
        regsub -all -- {\.} $group {/} result
        return $result
    }
}

snit::type RFC822 {
    pragma -hastypedestroy no 
    pragma -hasinstances no
    pragma -hastypeinfo no


    # Procedure: GetRFC822Name
    typemethod Name { RFC822Address} {
        if {[regsub {<.+>} $RFC822Address {} result]} {
            return [string trim $result]
        }
        if {[regsub {(.*\()(.+)(\).*)} $RFC822Address {\2} result]} {
            return [string trim $result]
        }
        return [string trim $RFC822Address]
    }
    # Procedure GetRFC822EMail
    typemethod EMail { RFC822Address} {
        regsub {\([^)]+\)} "$RFC822Address" {} RFC822Address
        if {[regexp {<([^>]+)>} "$RFC822Address" -> result] > 0} {
            return "$result"
        }
        return [string trim $RFC822Address]
    }
    typemethod validate {emailaddress} {
        return [regexp {^[[:space:][:alnum:]_.-]+\@[[:alnum:]_.-]+$} "$emailaddress"]
    }
    # Procedure SmartSplit
    typemethod SmartSplit {string char} {
        set result {}
        set remainder "$string"
        set start 0
        while {[string length "$remainder"] > 0} {
            set quote1Pos [string first {"} "$remainder" $start]
            if {$quote1Pos >= $start} {
                set quote2Pos [string first {"} "$remainder" [expr {$quote1Pos + 1}]]
            } else {
                set quote2Pos $quote1Pos
            }
            set charPos   [string first "$char" "$remainder" $start]
            if {$charPos < 0} {
                lappend result "$remainder"
                break
            }
            if {$charPos < $quote1Pos || $quote1Pos < 0} {
                lappend result [string range "$remainder" 0 [expr {$charPos - 1}]]
                set remainder [string range "$remainder" [expr {$charPos + 1}] end]
                set start 0
            } else {
                set start [expr {$quote2Pos + 1}]
            }
        }
        return $result    
    }
}

snit::widgetadaptor SearchPatternDialog {
    typevariable dialogsByParent -array {}
    option -pattern -default "" -configuremethod _configurePattern \
          -cgetmethod _cgetPattern
    method _configurePattern {option value} {
        if {[info exists pattern] && [winfo exists $pattern]} {
            $pattern delete 0 end
            $pattern insert end $value
        }
    }
    method _cgetPattern {option} {
        if {[info exists pattern] && [winfo exists $pattern]} {
            return [$pattern get]
        }
    }
    option -parent -readonly yes -default .
    delegate option -title to hull
    component labelframe
    component pattern
    constructor {args} {
        #      puts stderr "*** ${type}::constructor ($self) $args"
        set options(-parent) [from args -parent]
        installhull using Dialog \
              -class SearchPatternDialog -bitmap questhead \
              -default ok -cancel cancel -modal local -transient yes \
              -parent $options(-parent) -side bottom 
        #      puts stderr "*** ${type}::constructor ($self): win = $win, parent = $parent"
        #      puts stderr "*** ${type}::constructor ($self): wm transient $win = [wm transient $win]"
        #      puts stderr "*** ${type}::constructor ($self): winfo toplevel [winfo parent $win] = [winfo toplevel [winfo parent $win]]"
        $hull add ok -text OK -command [mymethod _OK]
        $hull add cancel -text Cancel -command [mymethod _Cancel]
        $hull add help -text Help -command [list BWHelp::HelpTopic SearchPatternDialog]
        wm protocol $win WM_DELETE_WINDOW [mymethod _Cancel]
        set frame [$hull getframe]
        install labelframe using ttk::labelframe $frame.labelframe \
              -text "Search Pattern:" -labelanchor w
        pack $labelframe -fill x
        install pattern using ttk::entry $labelframe.pattern
        pack $pattern -fill x -side left -expand yes
        $self configurelist $args
        set dialogsByParent($options(-parent)) $self
    }
    destructor {
        catch {unset dialogsByParent($options(-parent))}
    }
    method _OK {} {
        $hull withdraw
        return [$hull enddialog ok]
    }
    method _Cancel {} {
        $hull withdraw
        return [$hull enddialog cancel]
    }
    method _Draw {args} {
        $self configurelist $args
        switch -exact [$hull draw] {
            ok {return "[$pattern get]"}
            cancel {return {}}
        }
    }
    typemethod draw {args} {
        #      puts stderr "*** ${type}::draw $args"
        set parent [from args -parent {.}]
        #      puts stderr "*** ${type}::draw: parent = $parent"
        if {[catch "set dialogsByParent($parent)" dialog]} {
            if {[string equal [string index $parent end] {.}]} {
                set dialog ${parent}searchPatternDialog%AUTO%
            } else {
                set dialog ${parent}.searchPatternDialog%AUTO%
            }
            set dialog [eval [list $type \
                              create ${dialog} -parent $parent] \
                              $args]
        }
        #      puts stderr "*** ${type}::draw: dialog = $dialog"
        return "[eval [list $dialog _Draw] $args]"
    }
}

snit::widgetadaptor ServerMessageDialog {
      
    typemethod Message {parent title message} {
        $type draw -message "$message" -parent $parent -title $title    
    }
    typeconstructor {
        ttk::style ServerMessageDialog \
              -aspect 1500 \
              -justify left \
              -anchor w \
              -messagerelief flat \
              -messageborderwidth 0 \
              ;
    }
    option -style -default ServerMessageDialog
    delegate option -title to hull
    delegate option -parent to hull
    delegate option -geometry to hull
    delegate option -message to message as -text
    delegate method * to hull
    component message
    constructor {args} {
        installhull using Dialog \
              -class ServerMessageDialog -bitmap info \
              -default ok -cancel ok -modal none -transient yes \
              -side bottom
        $hull add ok -text OK -command [mymethod _OK]
        wm protocol $win WM_DELETE_WINDOW [mymethod _OK]
        set frame [$hull getframe]
        install message using message $frame.message
        pack $message -fill x
        $self configurelist $args
        catch {wm transient $win [$self cget -parent]}
        #      update idle
        #      set w [expr [winfo reqwidth $message] + 30]
        #      set h [expr [winfo reqheight $message] + 60]
        bind $message <<ThemeChanged>> [mymethod _ThemeChanged]
        $self _ThemeChanged
        $hull draw
    }
    method _ThemeChanged {} {
        $message configure -aspect [ttk::style lookup $options(-style) -aspect]
        $message configure -justify [ttk::style lookup $options(-style) -justify]
        $message configure -anchor [ttk::style lookup $options(-style) -anchor]
        $message configure -relief [ttk::style lookup $options(-style) -messagerelief]
        $message configure -borderwidth [ttk::style lookup $options(-style) -messageborderwidth]
    }
    method _OK {} {
        destroy $self
        return ok
    }
    typemethod draw {args} {
        set dialog [eval [list $type create .serverMessageDialog%AUTO%] $args]
        #      update
    }
}



snit::widget BackgroundShellProcessWindow {
    hulltype tk::toplevel
    widgetclass BackgroundShellProcessWindow

    component mainFrame
    component logScroll
    component logText
    component dismis
    
    variable status
    variable progress
    
    option -title -default {Backgroud Shell Process} -configuremethod _SetTitle
    method _SetTitle {option value} {
        wm title $win "$value"
        set options($option) "$value"
    }
    option -parent -default . -configuremethod _SetTransient
    method _SetTransient {option value} {
        wm transient $win $value
        set options($option) $value
    }
    option {-abortfunction abortFunction AbortFunction} -default {} \
          -configuremethod _SetAbort
    method _SetAbort {option value} {
        set options($option) $value
        if {[string equal "$value" {}]} {
            catch {$dismis configure -text "Dismis" -state disabled \
                      -command [mymethod _Close]}
        } else {
            catch {$dismis configure -text "Abort" -state normal \
                      -command [mymethod _Abort]}
        }
    }
    delegate option -progressmax to mainFrame
    delegate option -menu to hull
    delegate option -width to logText
    delegate option -height to logText
    constructor {args} {
        #      puts stderr "*** $type create $self $args"
        wm maxsize $win 1024 768
        wm minsize $win 10 10
        wm protocol $win WM_DELETE_WINDOW [mymethod _Close]
        install mainFrame using MainFrame $win.mainFrame\
              -progressvar [myvar progress] \
              -textvariable [myvar status]
        #      puts stderr "*** $self constructor: mainFrame = $mainFrame"
        pack $mainFrame -expand yes -fill both
        
        install logScroll using ScrolledWindow [$mainFrame getframe].logScroll \
              -scrollbar both -auto both
        #      puts stderr "*** $self constructor: logScroll = $logScroll"
        pack $logScroll -expand yes -fill both
        install dismis using ttk::button [$mainFrame getframe].dismis \
              -text "Dismis" -state disabled \
              -command [mymethod _Close]
        #      puts stderr "*** $self constructor: dismis = $dismis"
        pack $dismis -fill x
        install logText using ROText [$logScroll getframe].text -wrap none
        #      puts stderr "*** $self constructor: logText = $logText"
        $logScroll setwidget $logText
        $self configurelist $args
    }
    method setStatus {text} {set status "$text"}
    method setProgress {value} {set progress $value}
    method setProcessDone {} {$dismis configure -state normal}
    method addTextToLog {text} {
        $logText insert end "$text\n"
        $logText see end
    }
    method _Close {} {destroy $self}
    method _Abort {} {
	if {[tk_messageBox -type yesno -icon question -parent $win \
              -message "Are you sure you want to abort this process?"] \
                  eq no} {return}
        catch {uplevel #0 "$options(-abortfunction)"}
        $dismis configure -text "Dismis" -state disabled \
              -command [mymethod _Close]
    }
}

snit::type WaitExternalProgramASync {
    option -commandline -readonly yes
    variable pipe
    variable processflag
    constructor {args} {
        $self configurelist $args
        if {![info exists options(-commandline)] || 
            [string length "$options(-commandline)"] == 0} {
            error "-commandline is a required option!"
        }
        set pipe [open "|$options(-commandline)" r]
        set processflag 1
        fileevent $pipe readable [mymethod _ReadPipe]
    }
    destructor {
        if {[info exists processflag]} {
            if {$processflag > 0} {vwait [myvar processflag]}
        }
    }
    method _ReadPipe {} {
        if {[gets $pipe line] < 0} {
            catch {close $pipe}
            incr processflag -1
        }
    }
    method wait {} {
        if {$processflag > 0} {vwait [myvar processflag]}
    }
}



package provide CommonFunctions 1.0
