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

namespace eval Common {#dummy}

catch {
# Standard Motif bindings:

bind ROText <1> {
    tk::TextButton1 %W %x %y
    %W tag remove sel 0.0 end
}
bind ROText <B1-Motion> {
    set tk::Priv(x) %x
    set tk::Priv(y) %y
    tk::TextSelectTo %W %x %y
}
bind ROText <Double-1> {
    set tk::Priv(selectMode) word
    tk::TextSelectTo %W %x %y
    catch {%W mark set insert sel.last}
    catch {%W mark set anchor sel.first}
}
bind ROText <Triple-1> {
    set tk::Priv(selectMode) line
    tk::TextSelectTo %W %x %y
    catch {%W mark set insert sel.last}
    catch {%W mark set anchor sel.first}
}
bind ROText <Shift-1> {
    tk::TextResetAnchor %W @%x,%y
    set tk::Priv(selectMode) char
    tk::TextSelectTo %W %x %y
}
bind ROText <Double-Shift-1>	{
    set tk::Priv(selectMode) word
    tk::TextSelectTo %W %x %y 1
}
bind ROText <Triple-Shift-1>	{
    set tk::Priv(selectMode) line
    tk::TextSelectTo %W %x %y
}
bind ROText <B1-Leave> {
    set tk::Priv(x) %x
    set tk::Priv(y) %y
    tk::TextAutoScan %W
}
bind ROText <B1-Enter> {
    tk::CancelRepeat
}
bind ROText <ButtonRelease-1> {
    tk::CancelRepeat
}
bind ROText <Control-1> {
    %W mark set insert @%x,%y
}
bind ROText <Left> {
    tk::TextSetCursor %W insert-1c
}
bind ROText <Right> {
    tk::TextSetCursor %W insert+1c
}
bind ROText <Up> {
    tk::TextSetCursor %W [tk::TextUpDownLine %W -1]
}
bind ROText <Down> {
    tk::TextSetCursor %W [tk::TextUpDownLine %W 1]
}
bind ROText <Shift-Left> {
    tk::TextKeySelect %W [%W index {insert - 1c}]
}
bind ROText <Shift-Right> {
    tk::TextKeySelect %W [%W index {insert + 1c}]
}
bind ROText <Shift-Up> {
    tk::TextKeySelect %W [tk::TextUpDownLine %W -1]
}
bind ROText <Shift-Down> {
    tk::TextKeySelect %W [tk::TextUpDownLine %W 1]
}
bind ROText <Control-Left> {
    tk::TextSetCursor %W [tk::TextPrevPos %W insert tcl_startOfPreviousWord]
}
bind ROText <Control-Right> {
    tk::TextSetCursor %W [tk::TextNextWord %W insert]
}
bind ROText <Control-Up> {
    tk::TextSetCursor %W [tk::TextPrevPara %W insert]
}
bind ROText <Control-Down> {
    tk::TextSetCursor %W [tk::TextNextPara %W insert]
}
bind ROText <Shift-Control-Left> {
    tk::TextKeySelect %W [tk::TextPrevPos %W insert tcl_startOfPreviousWord]
}
bind ROText <Shift-Control-Right> {
    tk::TextKeySelect %W [tk::TextNextWord %W insert]
}
bind ROText <Shift-Control-Up> {
    tk::TextKeySelect %W [tk::TextPrevPara %W insert]
}
bind ROText <Shift-Control-Down> {
    tk::TextKeySelect %W [tk::TextNextPara %W insert]
}
bind ROText <Prior> {
    tk::TextSetCursor %W [tk::TextScrollPages %W -1]
}
bind ROText <Shift-Prior> {
    tk::TextKeySelect %W [tk::TextScrollPages %W -1]
}
bind ROText <Next> {
    tk::TextSetCursor %W [tk::TextScrollPages %W 1]
}
bind ROText <Shift-Next> {
    tk::TextKeySelect %W [tk::TextScrollPages %W 1]
}
bind ROText <Control-Prior> {
    %W xview scroll -1 page
}
bind ROText <Control-Next> {
    %W xview scroll 1 page
}

bind ROText <Home> {
    tk::TextSetCursor %W {insert linestart}
}
bind ROText <Shift-Home> {
    tk::TextKeySelect %W {insert linestart}
}
bind ROText <End> {
    tk::TextSetCursor %W {insert lineend}
}
bind ROText <Shift-End> {
    tk::TextKeySelect %W {insert lineend}
}
bind ROText <Control-Home> {
    tk::TextSetCursor %W 1.0
}
bind ROText <Control-Shift-Home> {
    tk::TextKeySelect %W 1.0
}
bind ROText <Control-End> {
    tk::TextSetCursor %W {end - 1 char}
}
bind ROText <Control-Shift-End> {
    tk::TextKeySelect %W {end - 1 char}
}

bind ROText <Control-Tab> {
    focus [tk_focusNext %W]
}
bind ROText <Control-Shift-Tab> {
    focus [tk_focusPrev %W]
}
bind ROText <Select> {
    %W mark set anchor insert
}
bind ROText <<Copy>> {
    tk_textCopy %W
}
# Additional emacs-like bindings:

bind ROText <Control-a> {
    if {!$tk_strictMotif} {
	tk::TextSetCursor %W {insert linestart}
    }
}
bind ROText <Control-b> {
    if {!$tk_strictMotif} {
	tk::TextSetCursor %W insert-1c
    }
}
bind ROText <Control-e> {
    if {!$tk_strictMotif} {
	tk::TextSetCursor %W {insert lineend}
    }
}
bind ROText <Control-f> {
    if {!$tk_strictMotif} {
	tk::TextSetCursor %W insert+1c
    }
}
bind ROText <Control-n> {
    if {!$tk_strictMotif} {
	tk::TextSetCursor %W [tk::TextUpDownLine %W 1]
    }
}
bind ROText <Control-p> {
    if {!$tk_strictMotif} {
	tk::TextSetCursor %W [tk::TextUpDownLine %W -1]
    }
}
if {[string compare $tcl_platform(platform) "windows"]} {
bind ROText <Control-v> {
    if {!$tk_strictMotif} {
	tk::TextScrollPages %W 1
    }
}
}

bind ROText <Meta-b> {
    if {!$tk_strictMotif} {
	tk::TextSetCursor %W [tk::TextPrevPos %W insert tcl_startOfPreviousWord]
    }
}
bind ROText <Meta-f> {
    if {!$tk_strictMotif} {
	tk::TextSetCursor %W [tk::TextNextWord %W insert]
    }
}
bind ROText <Meta-less> {
    if {!$tk_strictMotif} {
	tk::TextSetCursor %W 1.0
    }
}
bind ROText <Meta-greater> {
    if {!$tk_strictMotif} {
	tk::TextSetCursor %W end-1c
    }
}
# Macintosh only bindings:

# if text black & highlight black -> text white, other text the same
if {[string equal $tcl_platform(platform) "macintosh"]} {
bind ROText <FocusIn> {
    %W tag configure sel -borderwidth 0
    %W configure -selectbackground systemHighlight -selectforeground systemHighlightText
}
bind ROText <FocusOut> {
    %W tag configure sel -borderwidth 1
    %W configure -selectbackground white -selectforeground black
}
bind ROText <Option-Left> {
    tk::TextSetCursor %W [tk::TextPrevPos %W insert tcl_startOfPreviousWord]
}
bind ROText <Option-Right> {
    tk::TextSetCursor %W [tk::TextNextWord %W insert]
}
bind ROText <Option-Up> {
    tk::TextSetCursor %W [tk::TextPrevPara %W insert]
}
bind ROText <Option-Down> {
    tk::TextSetCursor %W [tk::TextNextPara %W insert]
}
bind ROText <Shift-Option-Left> {
    tk::TextKeySelect %W [tk::TextPrevPos %W insert tcl_startOfPreviousWord]
}
bind ROText <Shift-Option-Right> {
    tk::TextKeySelect %W [tk::TextNextWord %W insert]
}
bind ROText <Shift-Option-Up> {
    tk::TextKeySelect %W [tk::TextPrevPara %W insert]
}
bind ROText <Shift-Option-Down> {
    tk::TextKeySelect %W [tk::TextNextPara %W insert]
}

# End of Mac only bindings
}

}

proc Common::CarefulExit {{dontask no}} {
  set loadedSpools [Spool::SpoolWindow loadedSpools]
  if {[llength $loadedSpools] > 0} {
    set ans yes
    if {!$dontask} {
      set ans "[tk_messageBox \
			-icon question \
			-type yesno \
			-message {There are loaded spools -- Close them and exit?}]"
    }
    if {[string equal "$ans" "yes"]} {
      foreach spoolname $loadedSpools {
	set spool [Spool::SpoolWindow getSpoolByName $spoolname]
	destroy $spool
      }
      set dontask yes
    }
  }
  if {$dontask} {
    set ans yes
  } else {
    set ans "[tk_messageBox -icon question -type yesno -message {Really Exit }]"
  }
  switch -exact "$ans" {
    no {return}
    yes {
        exit
    }
  }
}

proc Common::Capitialize { word} {
  set first [string toupper [string index $word 0]]
  set rest  [string tolower [string range $word 1 end]]
  return "$first$rest"
}

proc Common::GroupToWindowName {group} {
  regsub -all -- {\.} $group {_} result
  return "[string tolower $result]"
}

namespace eval Common {
  snit::widgetadaptor SearchPatternDialog {

    typevariable dialogsByParent -array {}
    delegate option -pattern to patternLE as -text
    option -parent -readonly yes -default .
    delegate option -title to hull
    component patternLE
    constructor {args} {
#      puts stderr "*** ${type}::constructor ($self) $args"
      set options(-parent) [from args -parent]
      installhull using Dialog::create \
			-class SearchPatternDialog -bitmap questhead \
			-default 0 -cancel 1 -modal local -transient yes \
			-parent $options(-parent) -side bottom 
#      puts stderr "*** ${type}::constructor ($self): win = $win, parent = $parent"
#      puts stderr "*** ${type}::constructor ($self): wm transient $win = [wm transient $win]"
#      puts stderr "*** ${type}::constructor ($self): winfo toplevel [winfo parent $win] = [winfo toplevel [winfo parent $win]]"
      Dialog::add $win -name ok -text OK -command [mymethod _OK]
      Dialog::add $win -name cancel -text Cancel -command [mymethod _Cancel]
      Dialog::add $win -name help -text Help -command [list BWHelp::HelpTopic SearchPatternDialog]
      wm protocol $win WM_DELETE_WINDOW [mymethod _Cancel]
      set frame [Dialog::getframe $win]
      install patternLE using LabelEntry $frame.patternLE -side left \
					-label "Search Pattern:"
      pack $patternLE -fill x
      $self configurelist $args
      set dialogsByParent($options(-parent)) $self
    }
    destructor {
      catch {unset dialogsByParent($options(-parent))}
    }
    method _OK {} {
      Dialog::withdraw $win
      return [Dialog::enddialog $win ok]
    }
    method _Cancel {} {
      Dialog::withdraw $win
      return [Dialog::enddialog $win cancel]
    }
    method _Draw {args} {
      $self configurelist $args
      switch -exact [Dialog::draw $win] {
        ok {return "[$patternLE cget -text]"}
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

    delegate option -title to hull
    delegate option -parent to hull
    delegate option -geometry to hull
    delegate option -message to message as -text
    delegate method * to hull
    component message
    constructor {args} {
      installhull using Dialog \
			-class ServerMessageDialog -bitmap info \
			-default 0 -cancel 0 -modal none -transient yes \
			-side bottom
      Dialog::add $win -name ok -text OK -command [mymethod _OK]
      set frame [Dialog::getframe $win]
      install message using message $frame.message \
		-aspect 1500 -justify left -anchor w
      pack $message -fill x
      $self configurelist $args
      catch {wm transient $win [$self cget -parent]}
#      update idle
#      set w [expr [winfo reqwidth $message] + 30]
#      set h [expr [winfo reqheight $message] + 60]
      Dialog::draw $win
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
}


proc Common::GroupToPath { group} {
  regsub -all -- {\.} $group {/} result
  return $result
}

proc Common::CountMessages {list} {
  set count 0
  foreach m $list {
    if {[file isdirectory "$m"]} {continue}
    set m [file tail $m]
    if {[catch [list expr int($m)] i]} {continue}
    if {[string compare "$i" "$m"] == 0} {incr count}
  }
  return $count
}

proc Common::ServerMessage {parent title message} {
  ServerMessageDialog draw -message "$message" -parent $parent -title $title
}

proc Common::Lowestnumber {list} {
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

proc Common::Highestnumber {list} {
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

# Procedure: GetRFC822Name
proc Common::GetRFC822Name { RFC822Address} {
  if {[regsub -- {<.+>} $RFC822Address {} result]} {
    return [string trim $result]
  }
  if {[regsub -- {(.*\()(.+)(\).*)} $RFC822Address {\2} result]} {
    return [string trim $result]
  }
  return [string trim $RFC822Address]
}

# Procedure GetRFC822EMail
proc Common::GetRFC822EMail { RFC822Address} {
  regsub -- {\([^)]+\)} "$RFC822Address" {} RFC822Address
  if {[regexp {<([^>]+)>} "$RFC822Address" -> result] > 0} {return "$result"}
  return [string trim $RFC822Address]
}

# Procedure ValidEMailAddress
proc Common::ValidEMailAddress {emailaddress} {
  return [regexp {^[[:space:][:alnum:]_.-]+\@[[:alnum:]_.-]+$} "$emailaddress"]
}

# Procedure Common::SmartSplit
proc Common::SmartSplit {string char} {
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

namespace eval Common {
  snit::widget BackgroundShellProcessWindow {
    hulltype toplevel
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
      install dismis using Button [$mainFrame getframe].dismis \
			-text "Dismis" -state disabled \
			-command [mymethod _Close]
#      puts stderr "*** $self constructor: dismis = $dismis"
      pack $dismis -fill x
      install logText using text [$logScroll getframe].text -wrap none
#      puts stderr "*** $self constructor: logText = $logText"
      bindtags $logText [list $logText ROText . all]
      pack $logText -expand yes -fill both
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
	if {[string equal \
		[tk_messageBox -type yesno -icon question -parent $win \
		     -message "Are you sure you want to abort this process?"] \
		no]} {return}
	uplevel #0 "$options(-abortfunction)"
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
}

proc Common::PostMenuOnPointer {menu w} {
  set X [winfo pointerx $w]
  set Y [winfo pointery $w]

  $menu activate none
  $menu post $X $Y
  upvar #0 $menu data
  set data(oldfocus) [focus]
  focus $menu
}

proc Common::UnPostMenu {menu} {
  catch {
    upvar #0 $menu data
    $menu unpost
    focus $data(oldfocus)
  }
}

SplashWorkMessage "Loaded Common Functions" 16.66

package provide CommonFunctions 1.0
