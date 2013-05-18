#* 
#* ------------------------------------------------------------------
#* SpoolFunction.tcl - Spool functions
#* Created by Robert Heller on Sat May 27 15:58:06 2006
#* ------------------------------------------------------------------
#* Modification History: $Log$
#* Modification History: Revision 1.7  2007/12/03 16:36:39  heller
#* Modification History: Prepare for conversion to subversion
#* Modification History:
#* Modification History: Revision 1.6  2007/07/28 22:54:52  heller
#* Modification History: File Attachment Lockdown
#* Modification History:
#* Modification History: Revision 1.5  2007/07/12 16:54:47  heller
#* Modification History: Lockdown: 1.0.4
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

package require uri
package require ncgi
namespace eval AddressBook {#dummy}

namespace eval Spool {
  variable spooltoplevelList {}

  snit::widget SpoolWindow {
    widgetclass SpoolWindow
    hulltype toplevel

    typevariable _LoadedSpools -array {}

    typemethod spoolIsLoadedP {spoolname} {
#      puts stderr "*** ${type}::spoolIsLoadedP $spoolname"
#      puts stderr "*** ${type}::spoolIsLoadedP: array names = _LoadedSpools [array names _LoadedSpools]"
      set loadedP [expr [lsearch -exact [array names _LoadedSpools] $spoolname] != -1]
#      puts stderr "*** ${type}::spoolIsLoadedP: loadedP = $loadedP"
      return $loadedP
    }
    typemethod loadedSpools {} {return [array names _LoadedSpools]}

    typemethod getSpoolByName {spoolname} {
      if {[$type spoolIsLoadedP $spoolname]} {
	return $_LoadedSpools($spoolname)
      } else {
	return {}
      }
    }

    typemethod getOrMakeSpoolByName {spoolname args} {
      set reload [from args -reload no]
      if {[$type spoolIsLoadedP $spoolname]} {
	set oldspool $_LoadedSpools($spoolname)
	if {$reload} {eval [list $oldspool reload] $args}
	return $oldspool
      } else {
	set toplevel .[string tolower $spoolname]
	return [eval [list $type $toplevel -spoolname $spoolname] $args]
      }
    }

    typeconstructor {
#      option add *SpoolWindow*PanedWindow*ButtonBox*font \
#	{-*-*-medium-r-semicondensed-*-10-*-*-*-*-*-*-*} widgetDefault
    }

    typemethod processURL {args} {
#      puts stderr "*** $type processURL $args"
      set spoolname [from args -spool {}]
      if {[string length "$spoolname"] == 0} {
	error "$type processURL: required option -spool missing!"
      }
      set spool [$type getOrMakeSpoolByName $spoolname]
#      puts stderr "*** $type processURL: llength \$args = [llength $args]"
      if {[llength $args] > 1} {
	$spool processURLinspool "$args"
      } else {
	$spool processURLinspool "[lindex $args 0]"
      }
    }

    component main
    component groupTree
    component groupNameLabel
    component artlistButtons
    component manageSavedArticlesMenu
    component articleListSW
    component articleList
    component articleButtons
    
    option -spoolname -readonly yes

    component grouplist
    component newslist

    component articleViewWindow

    variable serverchannel
    variable currentArticle {}
    variable currentGroup {}
    variable selectedGroup {}
    variable userName {}
    variable savedDirectories

    option {-activefile activeFile ActiveFile} -validatemethod _CheckFile -default {}
    option {-cleanfunction cleanFunction CleanFunction} -readonly yes -validatemethod _CheckBoolean -default no
    option {-newsrc newsRc NewsRc} -readonly yes -validatemethod _CheckFile -default {}
    option {-savednews savedNews SavedNews} -readonly yes -validatemethod _CheckDirectory -default {}
    option -drafts -readonly yes -validatemethod _CheckDirectory -default {}
    option {-servername serverName ServerName} -readonly yes -validatemethod _CheckHost -default localhost
    option {-spellchecker spellChecker SpellChecker} -readonly yes -default {}
    option {-externaleditor externalEditor ExternalEditor} -readonly yes -default {}
    option {-spooldirectory spoolDirectory SpoolDirectory} -readonly yes -validatemethod _CheckDirectory -default {}
    option {-useserver useServer UseServer} -readonly yes -validatemethod _CheckBoolean -default no
    option {-geometry spoolGeometry SpoolGeometry} -readonly yes -default {}
    option {-iconic iconic Iconic} -readonly yes -default 0 -validatemethod _CheckBoolean
    option {-killfile killFile KillFile} -readonly yes -default {} -validatemethod _CheckFile
    
    method _CheckFile {option value} {
      if {[file exists "$value"] && [file readable "$value"]} {
        return $value
      } else {
        error "Expected an existing, readable file for $option, got $value"
      }
    }
    method _CheckBoolean {option value} {
      if {[string is boolean -strict "$value"]} {
        return $value"
      } else {
        error "Expected a boolean value for $option, got $value"
      }
    }
    method _CheckDirectory {option value} {
      if {[file isdirectory "$value"]} {
        return $value
      } else {
        error "Expected an existing directory for $option, got $value"
      }
    }

    method _CheckHost {option value} {
      if {[catch {package require dns}]} {return "$value"}
      set token [dns::resolve "$value"]
      set status [dns::status $token]
      dns::cleanup $token
      switch -exact $status {
	ok {return $value}
	error {
	  error "Expected a hostname for $option, got $value"
        }
      }
    }
    delegate option * to hull
    delegate method {main *} to main
    constructor {args} {
      global IconBitmap IconBitmapMask
      wm iconbitmap $win $IconBitmap
      wm iconmask   $win $IconBitmapMask
#      puts stderr "*** ${type}::constructor: as passed: args = $args"
      set options(-spoolname) [from args -spoolname {}]
      if {[string equal "$options(-spoolname)" {}]} {
	error "$type: $self: -spoolname is a REQUIRED option!"
      }
      set options(-activefile) [from args -activefile [option get $win activeFile ActiveFile]]
      set options(-cleanfunction) [from args -cleanfunction [option get $win cleanFunction CleanFunction]]
      set options(-newsrc) [from args -newsrc [option get $win newsRc NewsRc]]
      set options(-savednews) [from args -savednews [option get $win savedNews SavedNews]]
      set options(-drafts) [from args -drafts [option get $win drafts Drafts]]
      set options(-servername) [from args -servername [option get $win serverName ServerName]]
      set options(-spellchecker) [from args -spellchecker [option get $win spellChecker SpellChecker]]
      set options(-externaleditor) [from args -spellchecker [option get $win externalEditor ExternalEditor]]
      set options(-spooldirectory) [from args -spooldirectory [option get $win spoolDirectory SpoolDirectory]]
      set options(-useserver) [from args -useserver [option get $win useServer UseServer]]
      set options(-geometry) [from args -geometry [option get $win spoolGeometry SpoolGeometry]]
      set options(-killfile) [from args -killfile [option get $win killFile KillFile]]

      wm maxsize $win 1024 768
      wm minsize $win 640 10
      wm title $win "TkNews: Spool of $options(-spoolname)"
      wm iconname $win "$options(-spoolname)"
      wm protocol $win WM_DELETE_WINDOW [mymethod _CloseSpool]
      set newGeo "$options(-geometry)"
#      puts stderr "*** $type create $self: winfo class $win = [winfo class $win]"
#      puts stderr "*** $type create $self: newGeo = $newGeo"
      if {[string length "$newGeo"] > 0} {
        wm geometry $win "$newGeo"
      }
      if {![string equal "$options(-savednews)" {}]} {
	if {![file exists $options(-savednews)]} {
	  file mkdir $options(-savednews)
	} elseif {![file isdirectory $options(-savednews)]} {
	  error "$options(-savednews) exists and it is not a directory!"
	}
      }
      if {![string equal "$options(-drafts)" {}]} {
	if {![file exists $options(-drafts)]} {
	  file mkdir $options(-drafts)
	} elseif {![file isdirectory $options(-drafts)]} {
	  error "$options(-drafts) exists and it is not a directory!"
	}
      }
      if {[package vcompare [package provide Tcl] 8.4] < 0} {
	if {![string equal "$options(-savednews)" {}]} {
	  set options(-savednews) [glob -nocomplain "$options(-savednews)"]
	}
	if {![string equal "$options(-drafts)" {}]} {
	  set options(-drafts) [glob -nocomplain "$options(-drafts)"]
	}
      } else {
	if {![string equal "$options(-savednews)" {}]} {
	  set options(-savednews) [file normalize "$options(-savednews)"]
	}
	if {![string equal "$options(-drafts)" {}]} {
	  set options(-drafts) [file normalize "$options(-drafts)"]
	}
      }
      if {$options(-useserver)} {
        $self _Srv_Connect
        Common::ServerMessageDialog draw -parent $win \
	   -title "$options(-spoolname): $options(-servername):  Connection Response" \
	   -message "[$self srv_recv]" -geometry 600x100
	set options(-spooldirectory) {}
	set options(-activefile) {}
      } else {
	if {[package vcompare [package provide Tcl] 8.4] < 0} {
	  set options(-spooldirectory) [glob -nocomplain "$options(-spooldirectory)"]
	  set options(-activefile) [glob -nocomplain "$options(-activefile)"]
	  set options(-newsrc) [glob -nocomplain "$options(-newsrc)"]
	} else {
	  set options(-spooldirectory) [file normalize "$options(-spooldirectory)"]
	  set options(-activefile) [file normalize "$options(-activefile)"]
	  set options(-newsrc) [file normalize "$options(-newsrc)"]
	}
	if {![file exists $options(-activefile)]} {
	  close [open $options(-activefile) w]
	}
	if {![file exists $options(-spooldirectory)]} {
	  file mkdir $options(-spooldirectory)
	} elseif {![file isdirectory $options(-spooldirectory)]} {
	  error "$options(-spooldirectory) exists and it is not a directory!"
	}
      }
      if {![file exists $options(-newsrc)]} {
	close [open $options(-newsrc) w]
      }

      set menu [list \
	"&File" {file:menu} {file} 0 [list \
	    [list command "&Fetch QWK File" {file:fetch} "Fetch QWK File" {Ctrl f} -command [mymethod _FetchMyQWKFile] -state disabled] \
	    [list command "&Read Group" {file:read} "Read Group" {Ctrl r} -command [mymethod _ReadAGroup] -state disabled] \
	    [list command "&Post"       {file:post} "Post To Group" {Ctrl p} -command [mymethod _PostToGroup] -state disabled] \
	    [list command "C&lean"      {file:clean} "Clean Group" {Ctrl l} -command [mymethod _CleanGroup] -state disabled] \
	    [list command "Clean All Groups" {file:cleanall} "Clean All Groups" {} -command [mymethod _CleanAllGroups] -state disabled] \
	    {separator} \
	    [list command "&Close"	   {file:close} "Close Spool" {Ctrl c} -command [mymethod _CloseSpool]] \
	 ] \
	 "&Edit" {edit:menu} {edit} 0 { 
		{command "&Undo" {edit:undo} "Undo last change" {Ctrl z} -state disabled} 
		{command "Cu&t" {edit:cut edit:havesel} "Cut selection to the paste buffer" {Ctrl x}  -state disabled} 
		{command "&Copy" {edit:copy edit:havesel} "Copy selection to the paste buffer" {Ctrl c}  -state disabled} 
		{command "&Paste" {edit:paste edit:havesel} "Paste in the paste buffer" {Ctrl v}  -state disabled}
		{command "C&lear" {edit:clear edit:havesel} "Clear selection" {}  -state disabled}
		{command "&Delete" {edit:delete edit:havesel} "Delete selection" {Ctrl d} -state disabled}
		{separator}
		{command "Select All" {edit:selectall} "Select everything" {} -state disabled}
		{command "De-select All" {edit:deselectall edit:havesel} "Select nothing" {} -state disabled}
	    } \
	    "&View" {view:menu} {view} 0 {
	        {command "&Address Book" {view:addrbook} "View / Edit Address book" {} -command AddressBook::ViewEdit} \
	    } \
	    "&Options" {options:menu} {options} 0 {
	    } \
	    "&Help" {help:menu} {help} 0 {
		{command "On &Context..." {help:context} "Help on context" {} -command BWHelp::HelpContext}
		{command "On &Help..." {help:help} "Help on help" {} -command "BWHelp::HelpTopic Help"}
		{command "On &Window..." {help:window} "Help on the current window" {} -command "BWHelp::HelpWindow"}
		{command "On &Keys..." {help:keys} "Help on keyboard accelerators" {} -command "BWHelp::HelpTopic Keys"}
		{command "&Index..." {help:index} "Help index" {} -command "BWHelp::HelpTopic Index"}
		{command "&Tutorial..." {help:tutorial} "Tutorial" {}  -command "BWHelp::HelpTopic Tutorial"}
		{command "On &Version" {help:version} "Version" {} -command "BWHelp::HelpTopic Version"}
		{command "Warranty" {help:warranty} "Warranty" {} -command "BWHelp::HelpTopic Warranty"}
		{command "Copying" {help:copying} "Copying" {} -command "BWHelp::HelpTopic Copying"}
	    } \
      ]

# Main window
      install main using mainwindow $win.main -menu $menu -dontwithdraw yes
      pack $main -expand yes -fill both
      $main wipmessage hide
# Group tree
      set sframe [$main scrollwindow getframe]
#      puts stderr "*** $type create $self: option get $win spoolNumGroups SpoolNumGroups = [option get $win spoolNumGroups SpoolNumGroups]"
      install groupTree using Tree $sframe.groupTree \
		-selectcommand "[mymethod _EnableGroupButtons] $groupTree" \
		-width 60 \
		-height [option get $win spoolNumGroups SpoolNumGroups] \
		-selectfill yes -takefocus 1
      $main scrollwindow setwidget $groupTree
      $groupTree bindText <Double-Button-1> "[mymethod _ReadGroup] $groupTree"
      $groupTree bindImage <Double-Button-1> "[mymethod _ReadGroup] $groupTree"
      $groupTree bindText <KeyPress-Return> "[mymethod _ReadGroup] $groupTree"
      $groupTree bindImage <KeyPress-Return> "[mymethod _ReadGroup] $groupTree"
      $groupTree bindText <KeyPress-R> "[mymethod _ReadGroup] $groupTree"
      $groupTree bindImage <KeyPress-R> "[mymethod _ReadGroup] $groupTree"
      $groupTree bindText <KeyPress-r> "[mymethod _ReadGroup] $groupTree"
      $groupTree bindImage <KeyPress-r> "[mymethod _ReadGroup] $groupTree"
# Spool buttons (main's button box)
      $main buttons add -name unread  \
			-text "Unread\nGroup"  \
			-state {disabled}  \
			-command [mymethod _UnreadGroup]
      $main buttons add -name read  \
			-text "Read\nGroup"  \
			-state {disabled}  \
			-command [mymethod _ReadAGroup]
      $main buttons add -name close  \
			-text "Close\nGroup"  \
			-state {disabled}  \
			-command [mymethod _CloseGroup]
      $main buttons add -name catchup  \
			-text "Catch Up\nGroup"  \
			-state {disabled}  \
			-command [mymethod _CatchUpGroup]
      $main buttons add -name unsubscribe  \
			-text "Unsubscribe\nGroup"  \
			-state {disabled}  \
			-command [mymethod _UnSubscribeGroup]
      $main buttons add -name groupdir  \
			-text "Directory of\nall groups"  \
			-command [mymethod _DirectoryOfGroups]
      $main buttons add -name refresh  \
			-text "Refresh\nGroup List"  \
			-command [mymethod _RefreshGroupList]
# Slideout for the article list
      set alsframe [$main slideout add articles]
      install groupNameLabel using Label $alsframe.groupNameLabel
      pack $groupNameLabel -fill x
      install artlistButtons using ButtonBox $alsframe.artlistButtons \
				-orient horizontal
      pack $artlistButtons -fill x
      $artlistButtons add -name post \
			  -text {Post}  \
			  -command "[mymethod _PostToGroup] no"
      $artlistButtons add -name list  \
			  -text "List/Search\nArticles"  \
			  -command [mymethod _ListSearchArticles]
      $artlistButtons add -name read  \
			  -text "Read\nArticle"  \
			  -command [mymethod _ReadSelectedArticle]
      $artlistButtons add -name refresh  \
			  -text "Refresh Article\nList"  \
			  -command [mymethod _RefereshArticles]
      $artlistButtons add -name manage \
			  -text "Manage Saved\nArticles" \
			  -state disabled
      install manageSavedArticlesMenu using menu $artlistButtons.manage_menu \
			  -title {Manage Saved Articles}
      $artlistButtons itemconfigure manage \
	  -command "Common::PostMenuOnPointer $manageSavedArticlesMenu $win"
      $manageSavedArticlesMenu add command \
		-label {Print All Articles} \
		-command [mymethod _PrintAllSavedArticles]
      $manageSavedArticlesMenu add command \
		-label {Delete All Articles} \
		-command [mymethod _DeleteAllSavedArticles]
      $manageSavedArticlesMenu add command \
		-label {Delete Selected Articles} \
		-command [mymethod _DeleteSelectedArticles]
      $manageSavedArticlesMenu add command \
		-label {Renumber Articles} \
		-command [mymethod _RenumberArticles]
      $manageSavedArticlesMenu add command \
		-label {Recode Article} \
		-command [mymethod _RecodeArticle]
      $manageSavedArticlesMenu add command \
		-label {Flatfile Articles} \
		-command [mymethod _FlatfileArticles]
      bind $manageSavedArticlesMenu <Escape> {Common::UnPostMenu %W;break}
# Article list
      install articleListSW using ScrolledWindow $alsframe.articleListSW \
			-scrollbar both -auto both
      pack $articleListSW -fill both -expand yes
#      puts stderr "*** $type create $self: option get $win spoolNumArticles SpoolNumArticles = [option get $win spoolNumArticles SpoolNumArticles]"
      install articleList using ListBox [$articleListSW getframe].articleList \
			  -selectmode single -selectfill yes -takefocus 1 \
			  -height [option get $win spoolNumArticles SpoolNumArticles]
      pack $articleList -fill both -expand yes
      $articleListSW setwidget $articleList
      $articleList bindText <Double-Button-1> "[mymethod _ReadArticle] $articleList"
      $articleList bindText <KeyPress-Return> "[mymethod _ReadArticle] $articleList"
      $articleList bindText <KeyPress-R> "[mymethod _ReadArticle] $articleList"
      $articleList bindText <KeyPress-r> "[mymethod _ReadArticle] $articleList"
      $articleList bindText <KeyPress-space> "$articleList selection set"
#      puts stderr "*** ${type}::constructor: winfo class $articleList = [winfo class $articleList]"
# Article buttons
      install articleButtons using ButtonBox $alsframe.articleButtons \
				-orient horizontal -homogeneous no
      pack $articleButtons -fill x
      $articleButtons add -name followup  \
			  -text {Followup} \
			  -command "[mymethod _FollowupArticle] no"
      $articleButtons add -name mailreply  \
			  -text {Mail Reply To Sender} \
			  -command [mymethod _MailReply]
      $articleButtons add -name forwardto \
			  -text {Forward To} \
			  -command [mymethod _ForwardTo]
      $articleButtons add -name save  \
			  -text {Save}  \
			  -command [mymethod _SaveArticle]
      $articleButtons add -name file  \
			  -text {File}  \
			  -command [mymethod _FileArticle]
      $articleButtons add -name print  \
			  -text {Print} \
			  -command [mymethod _PrintArticle]
      $articleButtons configure -state disabled
#      puts stderr "*** ${type}::constructor: before configurelist: args = $args"
      $self configurelist $args
      set _LoadedSpools($options(-spoolname)) $self
      set qfile [from args -fromQWK {}]
      if {[string length "$qfile"] > 0} {
	set loaded [QWK::LoadQWKFile %AUTO% \
			-file "$qfile" \
			-activefile "$options(-activefile)" \
			-spooldirectory "$options(-spooldirectory)" \
			-newsrc "$options(-newsrc)" \
			-killfile "$options(-killfile)" \
			-parent $win]
	set userName [$loaded getUserName]
	$loaded destroy
      } else {
	global env
	set userName $env(USER)
      }
      $self _LoadActiveList
      $self _LoadNewsRc
      $self _LoadGroupTree $groupTree {.} 0 Brief
      set currentGroup {}

      if {$options(-iconic)} {
	update idle
	wm iconify $win
      } else {
	raise $win
      }
      bind $win <Control-c> [mymethod _CloseSpool]
      set command [option get $win qwkGetMailCommand QwkGetMailCommand]
      if {[string length "$command"] > 0} {
	bind $win <Control-f> [mymethod _FetchMyQWKFile]
	$main mainframe setmenustate file:fetch normal
      }
      focus $groupTree
      if {$options(-cleanfunction)} {
	$main mainframe setmenustate file:cleanall normal
      }
    }
    destructor {
#      puts stderr "*** ${type}::destructor"
      catch {$self _WriteNewsRc} message
#      puts stderr "*** ${type}::destructor: $self _WriteNewsRc done: $message"
      catch {$grouplist destroy} message
#      puts stderr "*** ${type}::destructor: $grouplist destroy done: $message"
      catch {$newslist destroy}
#      puts stderr "*** ${type}::destructor: $newslist destroy done: $message"
      if {$options(-useserver)} {catch {$self _Srv_NetClose}}
      catch {unset _LoadedSpools($options(-spoolname))} message
#      puts stderr "*** ${type}::destructor: unset _LoadedSpools($options(-spoolname)) done: $message"
    }
    method _FetchMyQWKFile {args} {
      eval [list QWK::GetQWKFile "$options(-spoolname)"] $args
    }
    method reload {args} {
      set qfile [from args -fromQWK {}]
      set recycleprocesswindow [from args -recycleprocesswindow {}]
      if {[string length "$qfile"] > 0} {
#	puts stderr "*** $self reload: Loading '$qfile'"
	set loaded [QWK::LoadQWKFile %AUTO% \
			-file "$qfile" \
			-activefile "$options(-activefile)" \
			-spooldirectory "$options(-spooldirectory)" \
			-newsrc "$options(-newsrc)" \
			-parent $win \
			-killfile "$options(-killfile)" \
			-recycleprocesswindow "$recycleprocesswindow"]
	set userName [$loaded getUserName]
	$loaded destroy
      }
#      puts stderr "*** $self reload: $self _ReLoadActiveList"
      $self _ReLoadActiveList
#      puts stderr "*** $self reload: $self _LoadGroupTree $groupTree {.} 0 Brief"
      $self _LoadGroupTree $groupTree {.} 0 Brief
    }
    method user {} {return "$userName"}
    method _CloseSpool {} {
      set answer "[tk_messageBox -icon question \
				 -type yesno \
				 -message {Really close this spool?} \
				 -parent $win]"
      if {[string equal "$answer" no]} {return}
      destroy $self
    }
    typevariable _NNTPPort 119
    method _Srv_Connect {} {
      if {[catch [list socket $options(-servername) $_NNTPPort] socket]} {
	error "${self}::_Srv_Connect: [list socket $options(-servername) $_NNTPPort]: $socket"
        return 0
      }
      set serverchannel $socket
      return 1
    }
    method srv_recv {{BufV {}}} {
      if {[string length "$BufV"] > 0} {
	upvar $BufV Buf
      }
      set len [gets $serverchannel Buf]
      if {[string length "$BufV"] > 0} {
	return $len
      } else {
	return "$Buf"
      }
    }
    method srv_cmd {command {BufV {}}} {
      $self _Srv_CheckConnection
      if {[string length "$BufV"] > 0} {
	upvar $BufV Buf
      }

      if {[catch [list $self srv_send "$command"]]} {
	$self _Srv_CheckConnection
	$self srv_send "$command"
      }

      set len [gets $serverchannel Buf]

      if {[string length "$BufV"] > 0} {
	return $len
      } else {
	return "$Buf"
      }

    }

    method srv_send {buf} {
      puts $serverchannel "$buf"
      flush $serverchannel
    }
      
    method _Srv_NetClose {} {
      catch [list close $serverchannel]
      unset serverchannel
    }
    method _Srv_CheckConnection {} {
      if {![info exists serverchannel]} {
	$self _Srv_Connect
	$self srv_recv
	return
      }
      if {[catch "fconfigure $serverchannel"]} {
	$self _Srv_Connect
	$self srv_recv
	return
      }
      if {[catch "flush $serverchannel"]} {
	$self _Srv_Connect
	$self srv_recv
	return
      }
    }

    method srv_rdTxt {p bufferV} {
      if {$p} {
	upvar $bufferV buffer
	set buffer {}
      }

      while {1} {
	set len [$self srv_recv line]
	if {$len < 0} {return len}
	if {[string compare "$line" {.}] == 0} {break}
	if {[string compare "[string range $line 0 1]" {..}] == 0} {
	  set line "[string range $line 2 end]"
	}
	if {$p} {append buffer "$line\n"}
      }
      return 0
    }

    method srv_rdTxtFp {fp} {
      while {1} {
	set len [$self srv_recv line]
	if {$len < 0} {return len}
	if {[string compare "$line" {.}] == 0} {break}
	if {[string compare "[string range $line 0 1]" {..}] == 0} {
	  set line "[string range $line 2 end]"
	}
	puts $fp "$line"
      }
      return 0
    }

    method srv_rdTxtTextBox {text} {
      while {1} {
	set len [$self srv_recv line]
	if {$len < 0} {return len}
	if {[string compare "$line" {.}] == 0} {break}
	if {[string compare "[string range $line 0 1]" {..}] == 0} {
	  set line "[string range $line 2 end]"
	}
	$text insert end "$line\n"
      }
      return 0
    }
    method crv_copyTxt {pre bufferV} {
      set buffer {}

      while {1} {
	set len [$self srv_recv line]
	if {$len < 0} {return len}
	if {[string compare "$line" {.}] == 0} {break}
	if {[string compare "[string range $line 0 1]" {..}] == 0} {
	  set line "[string range $line 2 end]"
	}
	append buffer "$pre$line\n"
      }
      return 0
    }

    method _LoadActiveList {} {
      if {$options(-useserver)} {
	install grouplist using Groups::groupList \
					 "${options(-spoolname)}_groups" \
					 -spool $self -method NNTP
      } else {
	install grouplist using Groups::groupList  \
					 "${options(-spoolname)}_groups" \
					 -spool $self -method File
      }
    }
    method _ReLoadActiveList {} {
      $grouplist reloadActiveFile
    }
    method _LoadNewsRc {} {
      install newslist using Groups::newsList \
				     "${options(-spoolname)}_news" \
				     -file $options(-newsrc) \
				     -grouplist $grouplist
    }
    method _WriteNewsRc {} {
      $newslist write
    }
    method _LoadGroupTree {tree pattern unsubscribed format} {
      if {[string length "$options(-savednews)"] > 0} {
	set saved 1
      } else {
	set saved 0
      }
      $grouplist loadGroupTree $tree $pattern $unsubscribed $format $saved
    }
    method _ReadAGroup {} {
#      puts stderr "*** ${type}::_ReadAGroup: selectedGroup = $selectedGroup, currentGroup = $currentGroup"
      if {[string equal "$selectedGroup" {}]} {return}
      if {![string equal "$currentGroup" {}] && 
	  ![string equal "$currentGroup" "$selectedGroup"]} {
	$self _CloseGroup 0
      }
      $main mainframe setmenustate file:post normal
      bind $win <Control-p> [mymethod _PostToGroup]
      set notsaved [catch "set savedDirectories($selectedGroup)"]
#      puts stderr "*** ${type}::_ReadAGroup: notsaved = $notsaved"
#      puts stderr "*** ${type}::_ReadAGroup: options(-cleanfunction) = $options(-cleanfunction)"
      if {$notsaved && $options(-cleanfunction)} {
	$main mainframe setmenustate file:clean normal
	bind $win <Control-l> [mymethod _CleanGroup]
      } else {
	$main mainframe setmenustate file:clean disabled
	bind $win <Control-l> {}
      }
      $main buttons itemconfigure close -state normal
      if {$notsaved} {
	$main buttons itemconfigure unread -state normal
	$main buttons itemconfigure catchup -state normal
	$main buttons itemconfigure unsubscribe -state normal
	$artlistButtons itemconfigure manage -state disabled
      } else {
	$main buttons itemconfigure unread -state disabled
	$main buttons itemconfigure catchup -state disabled
	$main buttons itemconfigure unsubscribe -state disabled
	$artlistButtons itemconfigure manage -state normal
      }
      # ReadGroup1
      set currentGroup "$selectedGroup"
      set groupWindow $win.[Common::GroupToWindowName $currentGroup]
      set groupClass [Common::Capitialize [lindex [split $currentGroup {.}] 0]]
      catch {destroy $groupWindow}
      frame $groupWindow -class $groupClass
      set IsEmail [option get $groupWindow isEmail IsEmail]
      destroy $groupWindow
      if {$IsEmail} {
	$main menu entryconfigure file 1 -command "[mymethod _PostToGroup] yes"
	$artlistButtons itemconfigure post \
			-text {Compose} -command "[mymethod _PostToGroup] yes"
	$articleButtons itemconfigure followup \
			-text {Reply To All} \
			-command "[mymethod _FollowupArticle] yes"
      } else {
	$main menu entryconfigure file 1 -command "[mymethod _PostToGroup] no"
	$artlistButtons itemconfigure post \
			-text {Post} -command "[mymethod _PostToGroup] no"
	$articleButtons itemconfigure followup \
			-text {Followup} \
			-command "[mymethod _FollowupArticle] no"
      }
      $articleList delete [$articleList items]
      $grouplist insertArticleList $articleList $currentGroup
      $groupNameLabel configure -text "$currentGroup"
      $main slideout show articles
      focus $articleList
    }
    method _EnableGroupButtons {gt selection} {
      if {[string length "$selection"] == 0} {return}
#      puts stderr "*** ${type}::_EnableGroupButtons: gt = $gt, selection = $selection"
      set selectedGroup [$gt itemcget $selection -data]
#      puts stderr "*** ${type}::_EnableGroupButtons: selectedGroup = $selectedGroup"
#      puts stderr "*** ${type}::_EnableGroupButtons: currentGroup = $currentGroup"
      $main mainframe setmenustate file:read normal
      $main buttons itemconfigure read -state normal
      bind $win <Control-r> [mymethod _ReadAGroup]
    }
    method _ReadGroup {gt selection} {
#      puts stderr "*** ${type}::_ReadGroup: gt = $gt, selection = $selection"
      set selectedGroup [$gt itemcget $selection -data]
#      puts stderr "*** ${type}::_ReadGroup:  selectedGroup = $selectedGroup"
      $main mainframe setmenustate file:read normal
      $main buttons itemconfigure read -state normal
      bind $win <Control-r> [mymethod _ReadAGroup]
      $self _ReadAGroup
    }
    method _CloseGroup {{disableButtons 1}} {
      if {$disableButtons} {
	$main mainframe setmenustate file:read disabled
        bind $win <Control-r> {}
	$main mainframe setmenustate file:post disabled
	bind $win <Control-p> {}
	$main mainframe setmenustate file:clean disabled
	bind $win <Control-l> {}
	$main buttons itemconfigure unread -state disabled
	$main buttons itemconfigure catchup -state disabled
	$main buttons itemconfigure unsubscribe -state disabled
	$main buttons itemconfigure close -state disabled
      }
      if {[string equal "$currentGroup" {}]} {return}
      # Really close the group.
      $main slideout hide articles
      catch {$articleViewWindow close}
      catch {$self _WriteNewsRc}
      set currentGroup {}
    }
    method _ReadSelectedArticle {} {
      set selection [$articleList selection get]
      if {[llength $selection] < 1} {return}
      $self _ReadArticle $articleList [lindex $selection 0]
    }
    method _ReadArticle {al selection} {
      set artNumber [$al itemcget $selection -data]
      $self _ReadArticleN $artNumber
    }
    method _ReadArticleN {artNumber {unread 1}} {
      if {[catch "set savedDirectories($currentGroup)" mdir] == 0} {
	set filename [file join $mdir $artNumber]
	if {![file exists $filename]} {return}
	if {![file readable $filename]} {return}
	set currentArticle $artNumber
	set useFile yes
      } elseif {$options(-useserver)} {
	if {![$grouplist articleExists $currentGroup $artNumber]} {return}
	set currentArticle $artNumber
	set useFile no
      } else {
	set filename [file join "$options(-spooldirectory)" [Common::GroupToPath $currentGroup] $artNumber]
	if {![file exists $filename]} {return}
	if {![file readable $filename]} {return}
	set currentArticle $artNumber
	set useFile yes
      }
      set nextArticle [$grouplist findNextArticle $currentGroup $currentArticle $unread]
      set previousArticle [$grouplist findPreviousArticle $currentGroup $currentArticle $unread]
      if {[string equal $articleViewWindow {}]} {
	install articleViewWindow \
		using Articles::Viewer $win.articleViewWindow \
			-parent $win -spool $self
      }
      if {$nextArticle < 0} {
	$articleViewWindow buttons itemconfigure next -state disabled
      } else {
	$articleViewWindow buttons itemconfigure next \
		-state normal \
		-command "[mymethod _ReadArticleN] $nextArticle $unread"
      }
      if {$previousArticle < 0} {
	$articleViewWindow buttons itemconfigure previous -state disabled
      } else {
	$articleViewWindow buttons itemconfigure previous \
		-state normal \
		-command "[mymethod _ReadArticleN] $previousArticle $unread"
      }
      $articleViewWindow setNumber $currentArticle
      $articleViewWindow setGroup  $currentGroup
      if {!$useFile} {
	$articleViewWindow NNTP_GetArticleToText
      } else {
        $articleViewWindow readArticleFromFile $filename
      }
      $grouplist findRange $currentGroup $currentArticle yes
      $grouplist updateGroupLineInTree $groupTree $currentGroup
      $articleButtons configure -state normal
      $articleViewWindow draw      
      $newslist write
    }
    method closeArticle {} {
      $articleButtons configure -state disabled
    }
    method _UnreadGroup {} {
      $grouplist groupsetranges $currentGroup {}
      $articleList delete [$articleList items]
      $grouplist insertArticleList $articleList $currentGroup
      $newslist write
    }
    method _SaveArticle {} {
      $articleViewWindow buttons invoke save
    }
    method _FileArticle {} {
      $articleViewWindow buttons invoke file
    }
    method addSavedGroupLine {group newsaved} {
      $grouplist addSavedGroupLineInTree $groupTree $group $newsaved
    }
    method updateGroupTreeLine {name} {
      $grouplist updateGroupLineInTree $groupTree $name
    }
    method _PrintArticle {} {
      $articleViewWindow buttons invoke print
    }
    method _RefreshGroupList {} {
      $self _ReLoadActiveList
      $self _LoadGroupTree $groupTree {.} 0 Brief
    }
    method _RefereshArticles {} {
      $articleList delete [$articleList items]
      $grouplist insertArticleList $articleList $currentGroup
    }
    # Misc additional group functions
    method _CatchUpGroup {} {
      if {[catch "set savedDirectories($currentGroup)" mdir] == 0} {return}
      $grouplist catchUpGroup $groupTree $articleList $currentGroup
      $newslist write
    }
    method _CleanGroup {} {
      if {!$options(-cleanfunction)} {return}
      if {[catch "set savedDirectories($currentGroup)" mdir] == 0} {return}
      if {$options(-useserver)} {return}
      set answer "[tk_messageBox -icon question \
				 -type yesno \
				 -message "Really clean group $currentGroup?" \
				 -parent $win]"
      if {[string equal "$answer" no]} {return}
      $grouplist cleanGroup $groupTree $articleList $currentGroup
      $self _CloseGroup
    }
    method _CleanAllGroups {} {
      if {!$options(-cleanfunction)} {return}
      if {$options(-useserver)} {return}
      set answer "[tk_messageBox -icon question \
				 -type yesno \
				 -message "Really clean all groups?" \
				 -parent $win]"
      if {[string equal "$answer" no]} {return}
      $self _CloseGroup
      foreach group [$grouplist activeGroups] {
	if {[catch "set savedDirectories($group)" mdir] == 0} {continue}
	if {[string equal -nocase "$group" reply]} {continue}
	$grouplist cleanGroup $groupTree {} $group
      }
    }
    method _UnSubscribeGroup {} {
      if {[catch "set savedDirectories($currentGroup)" mdir]} {
	$grouplist unSubscribeGroup $groupTree $currentGroup
      }
      $self _CloseGroup
    }
    method _DirectoryOfGroups {} {
      Groups::DirectoryOfAllGroupsDialog draw \
				-parent $win \
				-grouplist $grouplist \
				-subscribecallback [mymethod _SubscribeToGroup]
    }
    method _SubscribeToGroup {newgroup} {
      if {[string length "$options(-savednews)"] > 0} {
	set saved 1
      } else {
	set saved 0
      }
      $grouplist subscribeGroup $groupTree $newgroup $saved
      $newslist write
    }
    method _ListSearchArticles {} {
      Articles::SearchArticlesDialog draw \
	-parent $win -grouplist $grouplist \
	-group $currentGroup -readarticle [mymethod _ReadArticleN]
    }
    # Saved articles management menu
    method _PrintAllSavedArticles {} {
      if {[catch "set savedDirectories($currentGroup)" mdir]} {return}
      set mlist [glob -nocomplain [file join "$mdir" *]]
      set numMessages [Common::CountMessages $mlist]
      if {$numMessages == 0} {return}
      set firstMessage [Common::Lowestnumber $mlist]
      set lastMessage  [Common::Highestnumber $mlist]
      global PrintCommand
      set printPipe "|$PrintCommand"
      if {[catch [list open "$printPipe" w] outfp]} {
	error "Cannot create pipeline: $printPipe: $outfp"
	return
      }
      for {set im $firstMessage} {$im <= $lastMessage} {incr im} {
	set mfile [file join $mdir $im]
	if {[file exists "$mfile"] && [file readable "$mfile"]} {
	  set ifp [open "$mfile" r]
	  fcopy $ifp $outfp
	  close $ifp
	}
      }
      catch "close $outfp" message
      if {[string length "$message"] > 0} {
	Common::ServerMessageDialog draw \
			-parent $win \
			-title "$PrintCommand messages" \
			-message "$message" \
			-geometry 600x200
      }

    }
    method _DeleteAllSavedArticles {} {
      if {[catch "set savedDirectories($currentGroup)" mdir]} {return}
      set mlist [glob -nocomplain [file join "$mdir" *]]
      set numMessages [Common::CountMessages $mlist]
      if {$numMessages == 0} {return}
      set answer "[tk_messageBox -icon question \
				 -type yesno \
				 -message "Really clean group $currentGroup?" \
				 -parent $win]"
      if {[string equal "$answer" no]} {return}
      set firstMessage [Common::Lowestnumber $mlist]
      set lastMessage  [Common::Highestnumber $mlist]
      for {set im $firstMessage} {$im <= $lastMessage} {incr im} {
	set mfile [file join $mdir $im]
	if {[file exists "$mfile"] && [file writable "$mfile"]} {
	  file delete $mfile
	}
      }
      $grouplist updateGroupLineInTree $groupTree $currentGroup
      $articleList delete [$articleList items]
      $grouplist insertArticleList $articleList $currentGroup
    }
    method _DeleteSelectedArticles {} {
      if {[catch "set savedDirectories($currentGroup)" mdir]} {return}
      # -- Delete selected articles. (Needs a Dialog w/ListBox)
      set artList [Articles::SelectArticlesDialog draw \
				-parent $win -grouplist $grouplist \
				-group $currentGroup -selectmode multiple \
				-title "Articles to delete" -geometry 750x400]
      foreach a $artList {
	set mfile [file join $mdir $a]
	if {[file exists "$mfile"] && [file writable "$mfile"]} {
	  file delete $mfile
	}
      }
      $grouplist updateGroupLineInTree $groupTree $currentGroup
      $articleList delete [$articleList items]
      $grouplist insertArticleList $articleList $currentGroup
    }
    method _RenumberArticles {} {
      if {[catch "set savedDirectories($currentGroup)" mdir]} {return}
      set mlist [glob -nocomplain [file join "$mdir" *]]
      set numMessages [Common::CountMessages $mlist]
      if {$numMessages == 0} {return}
      set firstMessage [Common::Lowestnumber $mlist]
      set lastMessage  [Common::Highestnumber $mlist]
      set n 1
      for {set im $firstMessage} {$im <= $lastMessage} {incr im} {
	set orgfile [file join $mdir $im]
	if {[file exists $orgfile]} {
#	  puts stderr "*** $self _RenumberArticles: im = $im, n = $n"
	  if {$im == $n} {
	    incr n
	    continue
	  }
	  set newfile [file join $mdir $n]
#	  puts stderr "*** $self _RenumberArticles: $orgfile = $orgfile, newfile = $newfile"
	  if {[catch [list file rename $orgfile $newfile]] == 0} {incr n}
	}
      }      
      $grouplist updateGroupLineInTree $groupTree $currentGroup
      $articleList delete [$articleList items]
      $grouplist insertArticleList $articleList $currentGroup
    }
    method _RecodeArticle {} {
      if {[catch "set savedDirectories($currentGroup)" mdir]} {return}
      set articleList [Articles::SelectArticlesDialog draw \
				-parent $win -grouplist $grouplist \
				-group $currentGroup -selectmode single]
      if {[llength $articleList] == 0} {return}
      
    }
    method _FlatfileArticles {} {
      if {[catch "set savedDirectories($currentGroup)" mdir]} {return}
      set mlist [glob -nocomplain [file join "$mdir" *]]
      set numMessages [Common::CountMessages $mlist]
      if {$numMessages == 0} {return}
      set firstMessage [Common::Lowestnumber $mlist]
      set lastMessage  [Common::Highestnumber $mlist]
      set saveFile "[tk_getSaveFile -defaultextension .text \
				-filetypes { {{Text Files} {.text .txt} TEXT}
					     {{All Files} {*} }
					   } \
				-parent $win -title {Enter filename: }]"
      if {$saveFile == {}} {return}
      if {[catch "open $saveFile a" outfp]} {
	error "Cannot create or append to file $saveFile: $outfp"
	return
      }
      for {set im $firstMessage} {$im <= $lastMessage} {incr im} {
	set mfile [file join $mdir $im]
	if {[file exists "$mfile"] && [file readable "$mfile"]} {
	  set ifp [open "$mfile" r]
	  fcopy $ifp $outfp
	  close $ifp
	}
      }
      close $outfp
    }
    # Process a mailto: URL
    method processURLinspool {url} {
      foreach {uri values} [split "$url" {?}] {break}
      array set components [::uri::split "$uri"]
      set components(subject) {}
      set components(body) {}
      foreach nv [split "$values" {&}] {
	foreach {name value} [split "$nv" =] {break}
	set components($name) [::ncgi::decode "$value"]
      }
      set emailAddress {}	
      catch {set emailAddress "$components(user)@$components(host)"}
      set haveEmailGroup no
      foreach postGroup [$grouplist activeGroups] {
	set groupWindow $win.[Common::GroupToWindowName $postGroup]
	set groupClass [Common::Capitialize [lindex [split $postGroup {.}] 0]]
	catch {destroy $groupWindow}
	frame $groupWindow -class $groupClass
	set IsEmail [option get $groupWindow isEmail IsEmail]
	if {$IsEmail} {set haveEmailGroup yes;break}
	destroy $groupWindow
      }
      if {!$haveEmailGroup} {
	error "$self processURLinspool: no EMail group!"
      }
      set draftFile /usr/tmp/$groupWindow.[pid]
      set signatureFile [option get $groupWindow signatureFile SignatureFile]
      set organizationString "[option get $groupWindow organization Organization]"
      set fromString "[option get $groupWindow from From]"
      set ccSelf [option get $groupWindow ccSelf CcSelf]
      # Create Base message (Empty To: & no Newsgroup: iff E-Mail)
      if {[catch [list open "$draftFile" w] draftFp]} {
	error "$self processURLinspool: open \"$draftFile\" w: $draftFp"
      }
      if {[string length "$fromString"] > 0} {
	puts $draftFp "From: $fromString"
      }
      if {[string length "$organizationString"] > 0} {
	puts $draftFp "Organization: $organizationString"
      }
      puts $draftFp "X-Newsreader: TkNews 2.0 ($::BUILDSYMBOLS::VERSION)"
      puts $draftFp "Subject: $components(subject)"
      if {[string length  "$emailAddress"] == 0} {
	AddressBook::GetToCcAddresses ToAddrs CCAddrs
	puts $draftFp "To: [join $ToAddrs {,}]"
	if {$ccSelf && [string length "$fromString"] > 0} {
	  lappend CCAddrs "$fromString"
	}
	puts $draftFp "Cc: [join $CCAddrs {,}]"
      } else {
	puts $draftFp "To: $emailAddress"
	if {$ccSelf && [string length "$fromString"] > 0} {
	  puts $draftFp "Cc: $fromString"
	}
      }
      puts $draftFp {}
      puts $draftFp "$components(body)"
      puts $draftFp {}
      puts $draftFp {-- }
      if {$signatureFile != {} && [file exists $signatureFile] && [file readable $signatureFile]} {
        set sf [open $signatureFile "r"]
	fcopy $sf $draftFp
	close $sf
      }
      close $draftFp
      $self editDraft $draftFile
      set attachmentList {}
      set result [$self whatnowPostMenu $draftFile $postGroup $groupWindow 1 attachmentList]
      while {$result == -1} {
	set result [$self whatnowPostMenu $draftFile $postGroup $groupWindow 1 attachmentList]
      }
      catch {destroy $groupWindow}
#      puts stderr "*** $self processURLinspool: result = $result, draftFile = $draftFile"
      if {!$result && 
	  [string equal [tk_messageBox -type yesno \
				       -icon question \
				       -parent $win \
				       -message "Save draft?"] yes]} {
	set saveDir $options(-drafts)
#	puts stderr "*** $self processURLinspool: saveDir = $saveDir"
	if {[string length "$saveDir"] > 0} {
	  if {![file exists "$saveDir"]} {
	    file mkdir $saveDir
	  }
	  set highMessage [Common::Highestnumber [glob -nocomplain "$saveDir/*"]]
	  set mnum [expr $highMessage + 1]
	  set saveFile [file join $saveDir $mnum]
	  file copy $draftFile $saveFile
	  Common::ServerMessage $win "Message not sent" "Draft saved in $saveFile"
	}
      }
      file delete $draftFile      
    }
    # Post or mail a message
    method _PostToGroup {{isEmail no}} {
      set theGroup $currentGroup
#      puts stderr "*** $self _PostToGroup: theGroup = $theGroup, isEmail = $isEmail"
      set postGroup [$self _PostGroup $theGroup]
      set groupWindow $win.[Common::GroupToWindowName $postGroup]
      set groupClass [Common::Capitialize [lindex [split $postGroup {.}] 0]]
      catch {destroy $groupWindow}
      frame $groupWindow -class $groupClass
#      puts stderr "*** $self _PostToGroup: postGroup = $postGroup, groupWindow = $groupWindow"
      set draftFile /usr/tmp/$groupWindow.[pid]
      set signatureFile [option get $groupWindow signatureFile SignatureFile]
      set followupWithXCommentTo [option get $groupWindow followupWithXCommentTo FollowupWithXCommentTo]
      set followupEmailTo [option get $groupWindow followupEmailTo FollowupEmailTo]
      set organizationString "[option get $groupWindow organization Organization]"
      set fromString "[option get $groupWindow from From]"
      set ccSelf [option get $groupWindow ccSelf CcSelf]
      # Create Base message (Empty To: & no Newsgroup: iff E-Mail)
      if {[catch [list open "$draftFile" w] draftFp]} {
	error "$self _PostToGroup: open \"$draftFile\" w: $draftFp"
      }
      if {[string length "$fromString"] > 0} {
	puts $draftFp "From: $fromString"
      }
      if {[string length "$organizationString"] > 0} {
	puts $draftFp "Organization: $organizationString"
      }
      puts $draftFp "X-Newsreader: TkNews 2.0 ($::BUILDSYMBOLS::VERSION)"
      puts $draftFp "Subject: "
#      puts stderr "*** $self _PostToGroup: isEmail = $isEmail"
      if {$isEmail} {
	AddressBook::GetToCcAddresses ToAddrs CCAddrs
	puts $draftFp "To: [join $ToAddrs {,}]"
	if {$ccSelf && [string length "$fromString"] > 0} {
	  lappend CCAddrs "$fromString"
	}
	puts $draftFp "Cc: [join $CCAddrs {,}]"
      } elseif {[string length "$followupEmailTo"] > 0} {
	puts $draftFp "To: $followupEmailTo"
      } else {
	puts $draftFp "Newsgroups: $postGroup"
      }
      puts $draftFp {}
      puts $draftFp {}
      puts $draftFp {-- }
      if {$signatureFile != {} && [file exists $signatureFile] && [file readable $signatureFile]} {
        set sf [open $signatureFile "r"]
	fcopy $sf $draftFp
	close $sf
      }
      close $draftFp
      $self editDraft $draftFile
      set attachmentList {}	
      set result [$self whatnowPostMenu $draftFile $postGroup $groupWindow $isEmail attachmentList]
      while {$result == -1} {
	set result [$self whatnowPostMenu $draftFile $postGroup $groupWindow $isEmail attachmentList]
      }
      catch {destroy $groupWindow}
#      puts stderr "*** $self _PostToGroup: result = $result, draftFile = $draftFile"
      if {!$result && 
	  [string equal [tk_messageBox -type yesno \
				       -icon question \
				       -parent $win \
				       -message "Save draft?"] yes]} {
	set saveDir $options(-drafts)
#	puts stderr "*** $self _PostToGroup: saveDir = $saveDir"
	if {[string length "$saveDir"] > 0} {
	  if {![file exists "$saveDir"]} {
	    file mkdir $saveDir
	  }
	  set highMessage [Common::Highestnumber [glob -nocomplain "$saveDir/*"]]
	  set mnum [expr $highMessage + 1]
	  set saveFile [file join $saveDir $mnum]
	  file copy $draftFile $saveFile
	  Common::ServerMessage $win "Message not sent" "Draft saved in $saveFile"
	}
      }
      file delete $draftFile
    }
    proc regexpQuote {s} {
      return [regsub -all {\.} $s {\.}]
    }
    method _FollowupArticle {{isEmail no}} {
      set theGroup $currentGroup
      set postGroup [$self _PostGroup $theGroup]
      set groupWindow $win.[Common::GroupToWindowName $postGroup]
      set groupClass [Common::Capitialize [lindex [split $postGroup {.}] 0]]
      catch {destroy $groupWindow}
      frame $groupWindow -class $groupClass
      set draftFile /usr/tmp/$groupWindow.[pid]
      set signatureFile [option get $groupWindow signatureFile SignatureFile]
      set followupWithXCommentTo [option get $groupWindow followupWithXCommentTo FollowupWithXCommentTo]
      set followupEmailTo [option get $groupWindow followupEmailTo FollowupEmailTo]
      set organizationString "[option get $groupWindow organization Organization]"
      set fromString "[option get $groupWindow from From]"
      set ccSelf [option get $groupWindow ccSelf CcSelf]
      # Folowup To news (Reply-To-All iff E-Mail (copy all (Reply-)To:,Cc: addresses))
      #---
      if {[catch [list open "$draftFile" w] draftFp]} {
	error "$self _FollowupArticle: open \"$draftFile\" w: $draftFp"
      }
      if {[string length "$fromString"] > 0} {
	puts $draftFp "From: $fromString"
      }
      if {[string length "$organizationString"] > 0} {
	puts $draftFp "Organization: $organizationString"
      }
      puts $draftFp "X-Newsreader: TkNews 2.0 ($::BUILDSYMBOLS::VERSION)"
      set subject [$articleViewWindow getHeader subject]
      if {[regexp -nocase {^Re:} "$subject"] < 1} {set subject "Re: $subject"}
      puts $draftFp "Subject: $subject"
      set references [$articleViewWindow getHeader references]
#      puts stderr "*** $self _FollowupArticle: references = $references"
      regsub -all {[[:space:]]+} "$references" {,} references
#      puts stderr "*** $self _FollowupArticle (whitespace to comma): references = $references"
      regsub -all {,,} "$references" {,} references
#      puts stderr "*** $self _FollowupArticle (duplicate comma fix): references = $references"
      set refList [split "$references" {,}]
#      puts stderr "*** $self _FollowupArticle: refList = \{$refList\}"
      set messageId [$articleViewWindow getHeader message-id]
#      puts stderr "*** $self _FollowupArticle: messageId = '$messageId'"
      if {[string length "$messageId"] > 0} {
        puts $draftFp "In-Reply-To: $messageId"
        lappend refList $messageId
      }
#      puts stderr "*** $self _FollowupArticle (final): refList = \{$refList\}"
      if {[llength $refList] > 0} {
#	puts stderr "*** $self _FollowupArticle: Generating References header"
	puts -nonewline $draftFp "References: "
	set col [string length "References: "]
	set comma {}
	foreach ref $refList {
	  set ref [string trim "$ref"]
	  if {[string length "$comma"] > 0} {
	    puts -nonewline $draftFp "$comma"
	    incr col
	  }
	  if {[expr $col + [string length "$ref"]] > 75 && 
		[string length "$comma"] > 0} {
	    puts $draftFp {}
	    puts -nonewline $draftFp {    }
	    set col 4
	  }
	  puts -nonewline $draftFp "$ref"
	  incr col [string length "$ref"]
#	  puts stderr "*** $self _FollowupArticle: put one ref: '$ref'"
	  set comma { }
	}
	puts $draftFp {}
      }
      if {$isEmail} {
	set replyto [$articleViewWindow getHeader reply-to]
	if {[string length "$replyto"] == 0} {
	  set replyto [$articleViewWindow getHeader from]
	}
	puts $draftFp "To: $replyto"
	set toList [split [$articleViewWindow getHeader to] {,}]
	set ccList [split [$articleViewWindow getHeader cc] {,}]
        set originalTo [$articleViewWindow getHeader X-Original-To]
	set deliveredTo [$articleViewWindow getHeader Delivered-To]
	set allCC  [concat $toList $ccList]
	#puts stderr "*** $self _FollowupArticle: allCC = $allCC"
	#puts stderr "*** $self _FollowupArticle: originalTo = $originalTo"
	#puts stderr "*** $self _FollowupArticle: deliveredTo = $deliveredTo"
	if {$originalTo ne "" && $deliveredTo ne ""} {
	  set allCC [regsub -nocase -all [regexpQuote $deliveredTo] $allCC $originalTo]
	  #puts stderr "*** $self _FollowupArticle: (after \[regsub -all [regexpQuote $deliveredTo] $allCC $originalTo\]) allCC = $allCC"
        }
	if {$ccSelf && [string length "$fromString"] > 0} {
	  lappend allCC "$fromString"
	}
	puts -nonewline $draftFp "Cc: "
	set comma {}
	set col 4
	foreach cc $allCC {
	  set cc [string trim "$cc"]
	  if {[string length "$comma"] > 0} {
	    puts -nonewline $draftFp "$comma"
	    incr col
	  }
	  if {[expr $col + [string length "$cc"]] > 75} {
	    puts $draftFp {}
	    puts -nonewline $draftFp {    }
	    set col 4
	  }
	  puts -nonewline $draftFp "$cc"
	  incr col [string length "$cc"]
	  set comma {,}
	}
	puts $draftFp {}
      } else {
	set replyto [$articleViewWindow getHeader from]
	puts $draftFp "Newsgroups: [$articleViewWindow getHeader newsgroups]"
	if {$followupWithXCommentTo} {
	  set replyto [$articleViewWindow getHeader reply-to]
	  if {[string length "$replyto"] == 0} {
	    set replyto [$articleViewWindow getHeader from]
	  }
	  puts $draftFp "X-Comment-To: $replyto"
	}
	if {[string length "$followupEmailTo"] > 0} {
	  puts $draftFp "To: $followupEmailTo"
	}
      }
      puts $draftFp {}
      $self _QuoteBody "$replyto" "[$articleViewWindow getHeader date]" \
			"[$articleViewWindow getBody]" $draftFp
      puts $draftFp {}
      puts $draftFp {-- }
      if {$signatureFile != {} && [file exists $signatureFile] && [file readable $signatureFile]} {
        set sf [open $signatureFile "r"]
	fcopy $sf $draftFp
	close $sf
      }
      close $draftFp
      $self editDraft $draftFile
      set result [$self whatnowPostMenu $draftFile $postGroup $groupWindow]
      while {$result == -1} {
	set result [$self whatnowPostMenu $draftFile $postGroup $groupWindow]
      }
      destroy $groupWindow
#      puts stderr "*** $self _FollowupArticle: result = $result, draftFile = $draftFile"
      if {!$result &&
	  [string equal [tk_messageBox -type yesno \
				       -icon question \
				       -parent $win \
				       -message "Save draft?"] yes]} {
	set saveDir $options(-drafts)
#	puts stderr "*** $self _FollowupArticle: saveDir = $saveDir"
	if {[string length "$saveDir"] > 0} {
	  if {![file exists "$saveDir"]} {
	    file mkdir $saveDir
	  }
	  set highMessage [Common::Highestnumber [glob -nocomplain "$saveDir/*"]]
	  set mnum [expr $highMessage + 1]
	  set saveFile [file join $saveDir $mnum]
	  file copy $draftFile $saveFile
	  Common::ServerMessage $win "Message not sent" "Draft saved in $saveFile"
	}
      }
      file delete $draftFile
    }
    method _MailReply {} {
      set theGroup $currentGroup
      set postGroup [$self _PostGroup $theGroup]
      set groupWindow $win.[Common::GroupToWindowName $postGroup]
      set groupClass [Common::Capitialize [lindex [split $postGroup {.}] 0]]
      catch {destroy $groupWindow}
      frame $groupWindow -class $groupClass
      set draftFile /usr/tmp/$groupWindow.[pid]
      set signatureFile [option get $groupWindow signatureFile SignatureFile]
      set followupWithXCommentTo [option get $groupWindow followupWithXCommentTo FollowupWithXCommentTo]
      set followupEmailTo [option get $groupWindow followupEmailTo FollowupEmailTo]
      set organizationString "[option get $groupWindow organization Organization]"
      set fromString "[option get $groupWindow from From]"
      set ccSelf [option get $groupWindow ccSelf CcSelf]
      # Reply To E-Mail (Reply-To-Sender only)
      #---
      if {[catch [list open "$draftFile" w] draftFp]} {
	error "$self _MailReply: open \"$draftFile\" w: $draftFp"
      }
      if {[string length "$fromString"] > 0} {
	puts $draftFp "From: $fromString"
      }
      if {[string length "$organizationString"] > 0} {
	puts $draftFp "Organization: $organizationString"
      }
      puts $draftFp "X-Newsreader: TkNews 2.0 ($::BUILDSYMBOLS::VERSION)"
      set subject [$articleViewWindow getHeader subject]
      if {[regexp -nocase {^Re:} "$subject"] < 1} {set subject "Re: $subject"}
      puts $draftFp "Subject: $subject"
      set references [$articleViewWindow getHeader references]
      regsub -all {[[:space:]]+} "$references" {,} references
      regsub -all {,,} "$references" {,} references
      set refList [split "$references" {,}]
      set messageId [$articleViewWindow getHeader message-id]
      if {[string length "$messageId"] > 0} {
        puts $draftFp "In-Reply-To: $messageId"
        lappend refList $messageId
      }
      if {[llength $refList] > 0} {
	puts -nonewline $draftFp "References: "
	set col [string length "References: "]
	set comma {}
	foreach ref $refList {
	  set ref [string trim "$ref"]
	  if {[string length "$comma"] > 0} {
	    puts -nonewline $draftFp "$comma"
	    incr col
	  }
	  if {[expr $col + [string length "$ref"]] > 75 && 
		[string length "$comma"] > 0} {
	    puts $draftFp {}
	    puts -nonewline $draftFp {    }
	    set col 4
	  }
	  puts -nonewline $draftFp "$ref"
	  incr col [string length "$ref"]
	  set comma { }
	}
	puts $draftFp {}
      }
      set replyto [$articleViewWindow getHeader reply-to]
      if {[string length "$replyto"] == 0} {
	set replyto [$articleViewWindow getHeader from]
      }
      puts $draftFp "To: $replyto"
      if {$ccSelf && [string length "$fromString"] > 0} {
	puts $draftFp "Cc: $fromString"
      }
      puts $draftFp {}
      $self _QuoteBody "$replyto" "[$articleViewWindow getHeader date]" \
			"[$articleViewWindow getBody]" $draftFp
      puts $draftFp {}
      puts $draftFp {-- }
      if {$signatureFile != {} && [file exists $signatureFile] && [file readable $signatureFile]} {
        set sf [open $signatureFile "r"]
	fcopy $sf $draftFp
	close $sf
      }
      close $draftFp
      $self editDraft $draftFile
      set attachmentList {}
      set result [$self whatnowPostMenu $draftFile $postGroup $groupWindow 1 attachmentList]
      while {$result == -1} {
	set result [$self whatnowPostMenu $draftFile $postGroup $groupWindow 1 attachmentList]
      }
      destroy $groupWindow
#      puts stderr "*** $self _MailReply: result = $result, draftFile = $draftFile"
      if {!$result &&
	  [string equal [tk_messageBox -type yesno \
				       -icon question \
				       -parent $win \
				       -message "Save draft?"] yes]} {
	set saveDir $options(-drafts)
#	puts stderr "*** $self _MailReply: saveDir = $saveDir"
	if {[string length "$saveDir"] > 0} {
	  if {![file exists "$saveDir"]} {
	    file mkdir $saveDir
	  }
	  set highMessage [Common::Highestnumber [glob -nocomplain "$saveDir/*"]]
	  set mnum [expr $highMessage + 1]
	  set saveFile [file join $saveDir $mnum]
	  file copy $draftFile $saveFile
	  Common::ServerMessage $win "Message not sent" "Draft saved in $saveFile"
	}
      }
      file delete $draftFile
    }
    method _ForwardTo {} {
      set theGroup $currentGroup
      set postGroup [$self _PostGroup $theGroup]
      set groupWindow $win.[Common::GroupToWindowName $postGroup]
      set groupClass [Common::Capitialize [lindex [split $postGroup {.}] 0]]
      catch {destroy $groupWindow}
      frame $groupWindow -class $groupClass
      set draftFile /usr/tmp/$groupWindow.[pid]
      set signatureFile [option get $groupWindow signatureFile SignatureFile]
      set followupWithXCommentTo [option get $groupWindow followupWithXCommentTo FollowupWithXCommentTo]
      set followupEmailTo [option get $groupWindow followupEmailTo FollowupEmailTo]
      set organizationString "[option get $groupWindow organization Organization]"
      set fromString "[option get $groupWindow from From]"
      set ccSelf [option get $groupWindow ccSelf CcSelf]
      # Reply To E-Mail (Reply-To-Sender only)
      #---
      if {[catch [list open "$draftFile" w] draftFp]} {
	error "$self _MailReply: open \"$draftFile\" w: $draftFp"
      }
      if {[string length "$fromString"] > 0} {
	puts $draftFp "From: $fromString"
      }
      if {[string length "$organizationString"] > 0} {
	puts $draftFp "Organization: $organizationString"
      }
      puts $draftFp "X-Newsreader: TkNews 2.0 ($::BUILDSYMBOLS::VERSION)"
      set subject [$articleViewWindow getHeader subject]
      set subject "Fwd: $subject"
      puts $draftFp "Subject: $subject"
      AddressBook::GetToCcAddresses ToAddrs CCAddrs
      puts $draftFp "To: [join $ToAddrs {,}]"
      if {$ccSelf && [string length "$fromString"] > 0} {
	lappend CCAddrs "$fromString"
      }
      puts $draftFp "Cc: [join $CCAddrs {,}]"
      puts $draftFp {}
      set replyto [$articleViewWindow getHeader reply-to]
      if {[string length "$replyto"] == 0} {
	set replyto [$articleViewWindow getHeader from]
      }
      $self _ForwardBody "[$articleViewWindow getSimpleHeaders]" \
			"[$articleViewWindow getBody]" $draftFp
      puts $draftFp {}
      puts $draftFp {-- }
      if {$signatureFile != {} && [file exists $signatureFile] && [file readable $signatureFile]} {
        set sf [open $signatureFile "r"]
	fcopy $sf $draftFp
	close $sf
      }
      close $draftFp
      $self editDraft $draftFile
      set attachmentList {}	
      set result [$self whatnowPostMenu $draftFile $postGroup $groupWindow yes attachmentList]
      while {$result == -1} {
	set result [$self whatnowPostMenu $draftFile $postGroup $groupWindow yes attachmentList]
      }
      catch {destroy $groupWindow}
#      puts stderr "*** $self _PostToGroup: result = $result, draftFile = $draftFile"

      if {!$result && 
	  [string equal [tk_messageBox -type yesno \
				       -icon question \
				       -parent $win \
				       -message "Save draft?"] yes]} {
	set saveDir $options(-drafts)
#	puts stderr "*** $self _PostToGroup: saveDir = $saveDir"
	if {[string length "$saveDir"] > 0} {
	  if {![file exists "$saveDir"]} {
	    file mkdir $saveDir
	  }
	  set highMessage [Common::Highestnumber [glob -nocomplain "$saveDir/*"]]
	  set mnum [expr $highMessage + 1]
	  set saveFile [file join $saveDir $mnum]
	  file copy $draftFile $saveFile
	  Common::ServerMessage $win "Message not sent" "Draft saved in $saveFile"
	}
      }
      file delete $draftFile
    }
    method _QuoteBody {from date body draftFp} {
      puts $draftFp "At $date $from wrote:"
      puts $draftFp {}
      foreach line [split "$body" "\n"] {
	if {[string equal "$line" {-- }]} {break}
	puts $draftFp "> $line"
      }
    }
    method _ForwardBody {simpleHeaders body draftFp} {
      puts $draftFp "Forwarded Message:\n\n$simpleHeaders"
      puts $draftFp {}
      foreach line [split "$body" "\n"] {
	if {[string equal "$line" {-- }]} {break}
	puts $draftFp "$line"
      }
    }
    method _PostGroup {group} {
      while {[catch "set savedDirectories($group)"] == 0} {
	set group [file rootname $group]
      }
      return $group
    }
    # Post/Mail action callback
    # Returns:
    #   -1 -- Call back later...
    #	 0 -- Aborted
    #    1 -- posted/mailed
    method whatnowPostMenu {draftFile group groupWindow {useEmailProgram 0} 
							{attachmentListVar {}}} {
      if {[string length "$attachmentListVar"] > 0} {
	upvar $attachmentListVar attachmentList
      } else {
	set attachmentList {}
      }
      set articlePostMenu [Spool::ArticlePostMenu $win.articlePostMenu%AUTO% \
				-parent $win -draftfile $draftFile \
				-group $group -groupwindow $groupWindow \
				-spool $self -useemail $useEmailProgram \
				-attachments "$attachmentList"]
      set result [$articlePostMenu draw]
      set attachmentList [$articlePostMenu cget -attachments]
      destroy $articlePostMenu
      return $result
    }
    method replaceKeys {string group} {
      global QWKReplyProg
      set result "$string"
      regsub -all {\$QWKREPLY} "$result" "$QWKReplyProg" result
      regsub -all {%spool} "$result" "$options(-spooldirectory)" result
      regsub -all {%active} "$result" "$options(-activefile)" result
      regsub -all {%group} "$result" "$group" result
      return $result
    }
    method editDraft {draftFile} {
      if {[string equal "$options(-externaleditor)" {}]} {
	set edit [Articles::SimpleDraftEditor \
				create $win.articleEditor%AUTO% -parent $win]
	$edit editfile "$draftFile"
	destroy $edit
      } else {
	set edit [Common::WaitExternalProgramASync create editor%AUTO% \
			-commandline "$options(-externaleditor) $draftFile"]
	$edit wait
	$edit destroy
      }
    }
    method iconify {} {
      wm iconify $win
    }
    method addSavedDirectory {name dir} {
      set savedDirectories($name) $dir
    }
    method savedDirectory {name} {
      return $savedDirectories($name)
    }
    method NNTP_LoadArticleHead {group artnumber listbox {pattern {.}} {nread {}}} {
      set subject {}
      set from {}
      set date {}
      set lines 0

      if {[$self srv_cmd "group $group" buff] < 0} {
	error "NNTP_LoadArticleHead: Error sending group command"
	return 0 
      }
      if {[string first {411} "$buff"] == 0} {return 0}
      if {[$self srv_cmd "head $artnumber" buff] < 0} {
	error "NNTP_LoadArticleHead: Error sending head command"
	return 0
      }
      if {[string first {221} "$buff"] != 0} {
	return 0
      }
      while {[$self srv_recv line] != -1} {
	if {[string compare $line {.}] == 0} {break}
	if {[string first "Subject: " $line] == 0} {
	  set subject "[string range $line 9 end]"
	  continue
	}	
	if {[string first "From: " $line] == 0} {
	  set from [string range $line 6 end]
	  continue
	}
	if {[string first "Date: " $line] == 0} {
	  set date [string range $line 6 end]
	  continue
	}
	if {[string first "Lines: " $line] == 0} {
	  set lines [string range $line 7 end]
	  continue
	}
      }
      set from [Common::GetRFC822Name $from]
      if {[regexp -nocase -- "$pattern" "$subject"] && 
	  [$self _PassKillFile "$from" "$subject"]} {
	if {[string length $subject] > 36} {set subject [string range $subject 0 35]}
	if {[string length $from] > 20} {set from [string range $from 0 19]}
	if {[string length $date] > 25} {set date [string range $date 0 24]}
	set line "[format  {%6d %s%-36s %-20s %-25s %5d} $artnumber $nread $subject $from $date $lines]"
#	set font [option get $listbox font Font]
#        puts stderr "*** ${type}::NNTP_LoadArticleHead: listbox = $listbox, font = $font"
	$listbox insert end $artnumber -data $artnumber -text "$line"
	return 1
      }
      return 0
    }
    variable killFilePatternList
    method _PassKillFile {from subject} {
      if {[catch "set killFilePatternList"]} {
	set killFilePatternList {}
	if {![string equal "$options(-killfile)" {}]} {
	  if {[catch [list open "$options(-killfile)" r] kfp]} {
	    tk_messageBox -icon warning -type ok -message "Could not open killfile: $kfp" -parent $win
	  } else {
	    while {[gets "$kfp" oline] >= 0} {
	      regsub {(^|[^\\])#.*$} "$oline" {\1} line
	      set line [string trim "$line"]
	      if {[string length "$line"] == 0} {continue}
	      if {[regexp -nocase {^(from|subject):[[:space:]]*(.*)$} "$line" -> field pattern] > 0} {
		lappend killFilePatternList [list $field "$pattern"]
	      } else {
		tk_messageBox -icon warning -type ok -message "Syntax error in $options(-killfile) at $oline" -parent $win
	      }
	    }
	    close $kfp
	  }
	}
      }
      foreach fp $killFilePatternList {
	foreach {f p} $fp {
	  switch -exact "$f" {
	    from {
	      if {[regexp -nocase "$p" "$from"] > 0} {return no}
	    }
	    subject {
	      if {[regexp -nocase "$p" "$subject"] > 0} {return no}
	    }
	  }
	}
      }
      return yes
    }
  }
  snit::type GetSpoolNameDialog {
    pragma -hastypedestroy no
    pragma -hasinstances no
    pragma -hastypeinfo no

    typecomponent dialog
    typecomponent spoolListBox
    typecomponent spoolNameLE

    typeconstructor {
      set dialog [Dialog::create .getSpoolNameDialog \
			-class GetSpoolNameDialog -bitmap questhead \
			-default 0 -cancel 1 -modal local -transient yes \
			-parent . -side bottom -title {Select a spool}]
      $dialog add -name ok -text OK -command [mytypemethod _OK]
      $dialog add -name cancel -text Cancel -command [mytypemethod _Cancel]
      $dialog add -name help -text Help -command [list BWHelp::HelpTopic GetSpoolNameDialog]
      set frame [$dialog getframe]
      set spoolListBox $frame.spoolListBox
      set spoolNameLE $frame.spoolNameLE
      pack [ListBox::create $spoolListBox -selectmode single] \
		-expand yes -fill both
      $spoolListBox bindText <1> [mytypemethod _SelectFromList]
      $spoolListBox bindText <space> [mytypemethod _SelectFromList]
      $spoolListBox bindText <Double-Button-1> [mytypemethod _ReturnFromList]
      $spoolListBox bindText <Return> [mytypemethod _ReturnFromList]
      pack [LabelEntry::create $spoolNameLE -label "Spool:" -side left] -fill x
      $spoolNameLE bind <Return> [mytypemethod _OK]
    }
    typemethod _OK {} {
      set answer "[$spoolNameLE cget -text]"
      Dialog::withdraw $dialog
      return [Dialog::enddialog $dialog "$answer"]
    }
    typemethod _Cancel {} {
      Dialog::withdraw $dialog
      return [Dialog::enddialog $dialog {}]
    }
    typemethod _SelectFromList {selection} {
      $spoolNameLE configure -text [$spoolListBox itemcget $selection -text]
    }
    typemethod _ReturnFromList {selection} {
      $spoolNameLE configure -text [$spoolListBox itemcget $selection -text]
      $type _OK
    }
    typemethod draw {args} {
      set default [from args -defaultSpool {}]
      $spoolNameLE configure -text "$default"
      set loadedP [from args -loaded no]
      $spoolListBox delete [$spoolListBox items]
      if {$loadedP} {
	set spoolList [Spool::SpoolWindow loadedSpools]
      } else {
	set spoolList [option get . spoolList SpoolList]
      }
      foreach sp $spoolList {
	$spoolListBox insert end $sp -text $sp
      }
      set parent [from args -parent .]
      $dialog configure -parent $parent
      wm transient [winfo toplevel $dialog] $parent
      return [Dialog::draw $dialog]
    }
  }
  snit::widgetadaptor ArticlePostMenu {

    option -parent -readonly yes -default .
    option -draftfile -readonly yes
    option -group -readonly yes
    option {-groupwindow groupWindow GroupWindow} -readonly yes
    option -spool -readonly yes
    option -attachments {}
    option {-useemail useEmail UseEmail} -readonly yes -default no

    component   whomlistSW
    component   whomlist
    component   attachmentsSW
    component   attachments

    method _ValidateRequiredOption {option} {
      if {![info exists options($option)] ||
	  [string length $options($option)] == 0} {
	error "$option is a required option!"
      }
    }
    constructor {args} {
      set options(-parent) [from args -parent .]
      installhull using Dialog::create -parent $options(-parent) \
		-class ArticlePostMenu -default 1 -cancel 3 -modal local \
		-transient yes -side bottom -bitmap questhead \
		-title {What Now?}
      Dialog::add $win -name spell \
		       -text {Spell Check} \
		       -command [mymethod _SpellCheck]
      Dialog::add $win -name send \
		       -text {Send} \
		       -command [mymethod _SendMessage]
      Dialog::add $win -name sendencrypted \
			-text "Send\nEncrypted" \
			-command [mymethod _SendMessageEncrypted]
      Dialog::add $win -name dismis \
		       -text {Dismis} \
		       -command [mymethod _Dismis]
      Dialog::add $win -name reedit \
		       -text {Reedit} \
		       -command [mymethod _Reedit]
      wm protocol $win WM_DELETE_WINDOW [mymethod _Dismis]
      $self configurelist $args
      $self _ValidateRequiredOption -draftfile
      $self _ValidateRequiredOption -group
      $self _ValidateRequiredOption -groupwindow
      $self _ValidateRequiredOption -spool
      install whomlistSW using ScrolledWindow::create \
			[Dialog::getframe $win].whomlistSW \
		-scrollbar vertical -auto vertical
      pack $whomlistSW -expand yes -fill both -side left
      set wl [ScrolledWindow::getframe $whomlistSW].whomlist
      install whomlist using ListBox::create $wl \
		-selectmode none
      pack $whomlist -expand yes -fill both
      $whomlistSW setwidget $whomlist
      $self fillWhomList
      if {$options(-useemail)} {
	install attachmentsSW using ScrolledWindow::create \
			[Dialog::getframe $win].attachmentsSW \
		-scrollbar both -auto both
	pack $attachmentsSW  -expand yes -fill both -side left
	set al [ScrolledWindow::getframe $attachmentsSW].attachments
	install attachments using ListBox::create $al -selectmode none
	pack $attachments -expand yes -fill both
	$attachmentsSW setwidget $attachments
	$attachments bindText <3> [mymethod _ShowAttachment]
	$self fillAttachmentList
	Dialog::add $win -name attach \
			 -text {Attach File} \
			 -command [mymethod _AttachFile] 
      }
	
    }
    method _ShowAttachment {item} {
      set attachment [$attachments itemcget $item -data]
      foreach {ctype descr encoding filename} $attachment {
	tk_messageBox -type ok -icon info -message "$filename: $ctype; $encoding; $descr" -parent $win
      }
    }
    method draw {} {return [Dialog::draw $win]}
    method _SpellCheck {} {
      Dialog::withdraw $win
      set spell [Common::WaitExternalProgramASync create spellCheck%AUTO% \
	-commandline "[$options(-spool) cget -spellchecker] $options(-draftfile)"]
      $spell wait
      $spell destroy
      return [Dialog::enddialog $win -1]
    }
    method _SendMessage {} {
      Dialog::withdraw $win
      
      if {[catch {
	if {$options(-useemail)} {
	  set inject [option get $options(-groupwindow) emailProgram EmailProgram]
	} else {
	  set inject [option get $options(-groupwindow) injectProgram InjectProgram]
        }
#	puts stderr "*** $self _SendMessage: inject = $inject"
	set inject [$options(-spool) replaceKeys "$inject" $options(-group)]
#	puts stderr "*** $self _SendMessage (after _ReplaceKeys): inject = $inject"
	set dFp [open "$options(-draftfile)" r]
#	puts stderr "*** $self _SendMessage: dFp = $dFp (open \"$options(-draftfile)\" r)"
	set iFp [open "|$inject" w]
#	puts stderr "*** $self _SendMessage: iFp = $iFp (open \"|$inject\" w)"
#        puts stderr "*** $self _SendMessage: options(-attachments) = $options(-attachments)"
#        puts stderr "*** $self _SendMessage: llength \$options(-attachments) = [llength $options(-attachments)]"
        if {[llength $options(-attachments)] == 0} {
	  fcopy $dFp $iFp
	} else {
	  while {[gets $dFp line] > 0} {
	    puts $iFp "$line"
	  }
	  puts $iFp "MIME-Version: 1.0"
	  puts $iFp "Content-type: multipart/mixed;"
	  set boundary "[$self _CreateBoundary]"
	  puts $iFp "\tboundary=\"$boundary\""
	  puts $iFp "Content-ID: <[$self _CreateCID]>"
	  puts $iFp {
This is  a multimedia message in MIME  format.  If you are reading this
prefix, your mail reader does  not understand MIME.  You may wish
to look into upgrading to a newer version of  your mail reader.

}
	  puts $iFp "--$boundary"
	  puts $iFp "Content-ID: <[$self _CreateCID]>"
  	  puts $iFp "Content-type: text/plain; charset=us-ascii"
	  puts $iFp "Content-Transfer-Encoding: 7bit"
	  puts $iFp {}
	  fcopy $dFp $iFp
	  foreach attachment $options(-attachments) {
	    puts $iFp "--$boundary"
	    foreach {ctype descr encoding filename} $attachment {
	      puts $iFp "Content-ID: <[$self _CreateCID]>"
	      puts $iFp "Content-type: $ctype; name=[file tail $filename]"
	      if {[string length "$descr"] > 0} {
		puts $iFp "Content-Description: $descr"
	      }
	      puts $iFp "Content-Transfer-Encoding: $encoding"
	      puts $iFp {}
	      switch $encoding {
		7bit {
		  set fp [open "$filename" r]
		  fcopy $fp $iFp
		  close $fp
		}
		quoted-printable {
		  set fp [open "|[auto_execok mimencode] -q $filename" r]
		  fcopy $fp $iFp
		  close $fp
		}
		base64 {
		  set fp [open "|[auto_execok mimencode] -b $filename" r]
		  fcopy $fp $iFp
		  close $fp
		}
	      }
	    }
	  }
	  puts $iFp "--$boundary"
	}
	close $dFp
	close $iFp
	} message]} {
	Dialog::enddialog $win 0
	error "Error Sending message: $message"
      }
      return [Dialog::enddialog $win 1]
    }
    method _SendMessageEncrypted {} {
      Dialog::withdraw $win
      
      if {[catch {
	if {$options(-useemail)} {
	  set inject [option get $options(-groupwindow) emailProgram EmailProgram]
	} else {
	  set inject [option get $options(-groupwindow) injectProgram InjectProgram]
        }
#	puts stderr "*** $self _SendMessageEncrypted: inject = $inject"
	set inject [$options(-spool) replaceKeys "$inject" $options(-group)]
#	puts stderr "*** $self _SendMessageEncrypted (after _ReplaceKeys): inject = $inject"
        package require Gpgme
	set ctx [gpgme_new]
        
        #set encrypt [option get $options(-groupwindow) encryptProgram EncryptProgram]
	#set encryptRecpt [option get $options(-groupwindow) encryptRecpt EncryptRecpt]
        
	set dFp [open "$options(-draftfile)" r]
#	puts stderr "*** $self _SendMessageEncrypted: dFp = $dFp (open \"$options(-draftfile)\" r)"
#	puts stderr "*** $self _SendMessageEncrypted: iFp = $iFp (open \"|$inject\" w)"
#        puts stderr "*** $self _SendMessageEncrypted: options(-attachments) = $options(-attachments)"
#        puts stderr "*** $self _SendMessageEncrypted: llength \$options(-attachments) = [llength $options(-attachments)]"
	set recpts [list]
	set from {}
	set hbuffer {}
	while {[gets $dFp line] >= 0} {
	  #if {"$line" ne ""} {puts $iFp "$line"}
	  #puts stderr "*** $self _SendMessageEncrypted: line = '$line'"
	  if {[regexp {^[[:space:]]+[^[:space:]]} "$line"] > 0} {
	    append hbuffer " $line"
	  } else {
	    if {[string length "$hbuffer"] > 0} {
                #puts stderr "*** $self _SendMessageEncrypted: hbuffer is $hbuffer"
              if {[regexp -nocase {^from:[[:space:]]+(.*)$} "$hbuffer" -> fromwhome] > 0} {
                set fromwhome [string trim "$fromwhome"]
                set from [Common::GetRFC822EMail "$fromwhome"]
              } elseif {[regexp -nocase {^to:[[:space:]]+(.*)$} "$hbuffer" -> towhome] > 0 ||
		        [regexp -nocase {^cc:[[:space:]]+(.*)$} "$hbuffer" -> towhome] > 0 ||
		        [regexp -nocase {^bcc:[[:space:]]+(.*)$} "$hbuffer" -> towhome] > 0} {
	        #puts stderr "*** $self _SendMessageEncrypted: towhome = $towhome"
		set whoms [Common::SmartSplit "$towhome" ","]
	        #puts stderr "*** $self _SendMessageEncrypted: whoms = $whoms"
		foreach w $whoms {
		  set w [string trim "$w"]
		  set address [Common::GetRFC822EMail "$w"]
		  #puts stderr "*** $self _SendMessageEncrypted: address = $address"
		  if {[lsearch -exact $recpts $address] < 0} {
		    lappend recpts $address
		  }
	        }
		#puts stderr "*** $self _SendMessageEncrypted: recpts = $recpts"
	      }
	    }
	    set hbuffer [string trim "$line"]
	    if {"$line" eq ""} {break}
	  }
	}
        set keys [list]
        set from_keys 0
	foreach recpt $recpts {
	  #append encrypt " "
	  #append encrypt [regsub -all "%recpt" $encryptRecpt $recpt]
          gpgme_op_keylist_start $ctx $recpt 0
          set recpt_keycnt 0
          while {[catch {gpgme_op_keylist_next $ctx} key] == 0} {
              if {[$key cget -can_encrypt]} {
                  if {$from eq $recpt} {incr from_keys}
                  lappend keys $key
                  incr recpt_keycnt
              } else {
                  gpgme_key_release $key
              }
          }
          if {$recpt_keycnt == 0} {
              tk_messageBox -icon warning -type ok -message "$recpt has no public key suitable for encrypting -- not encrypting for $recpt" -parent $win
          }
	}
	if {[llength $keys] == $from_keys} {
            tk_messageBox -icon info -type ok -message "No public keys can encrypt, send encrypt aborted"  -parent $win
            foreach k $keys {gpgme_key_release $k}
            gpgme_release $ctx
            error "" "" RETURN
        }
        set iFp [open "|$inject" w]
        seek $dFp 0 start
        while {[gets $dFp line] >= 0} {
            if {"$line" ne ""} {
                puts $iFp "$line"
            } else {
                break
            }
        }
        #puts stderr "*** $self _SendMessageEncrypted (final): recpts = $recpts"
	puts $iFp "MIME-Version: 1.0"
	puts $iFp "Content-type: multipart/encrypted;"
	puts $iFp "\tprotocol=\"application/pgp-encrypted\";"
	set boundary "[$self _CreateBoundary]"
	puts $iFp "\tboundary=\"$boundary\""
	puts $iFp {
This is an OpenPGP/MIME encrypted message (RFC 2440 and 3156)

}
	puts $iFp "--$boundary"
	puts $iFp "Content-type: text/plain; charset=us-ascii"
	puts $iFp "Content-Description: PGP/MIME version identification"
	puts $iFp {}
	puts $iFp "Version: 1"
	puts $iFp {}
	puts $iFp "--$boundary"
	puts $iFp "Content-Type: application/octet-stream; name=\"encrypted.asc\""
	puts $iFp "Content-Description: OpenPGP encrypted message"
	puts $iFp "Content-Disposition: inline; filename=\"encrypted.asc\""
	puts $iFp {}
	#puts stderr "*** $self _SendMessageEncrypted: encrypt = $encrypt"
	#set encryptedFile /usr/tmp/$options(-groupwindow).[pid].encrypted.asc
	#set encrypt [regsub -all "%encrypted" "$encrypt" "$encryptedFile"]
	#puts stderr "*** $self _SendMessageEncrypted (after regsub ... %encrypted): encrypt = $encrypt"
	#puts stderr "*** $self _SendMessageEncrypted (after appending recpts): encrypt = $encrypt"
        set clearTextFile /usr/tmp/$options(-groupwindow).[pid].clearTextFile
        set eFp [open $clearTextFile w]
	if {[llength $options(-attachments)] == 0} {
	  fcopy $dFp $eFp
	} else {
	  puts $eFp "MIME-Version: 1.0"
	  puts $eFp "Content-type: multipart/mixed;"
	  set boundary2 "[$self _CreateBoundary]"
	  puts $eFp "\tboundary=\"$boundary2\""
	  puts $eFp {
This is  a multimedia message in MIME  format.  If you are reading this
prefix, your mail reader does  not understand MIME.  You may wish
to look into upgrading to a newer version of  your mail reader.

}
	  puts $eFp "--$boundary2"
	  puts $eFp "Content-ID: <[$self _CreateCID]>"
	  puts $eFp "Content-type: text/plain; charset=us-ascii"
	  puts $eFp "Content-Transfer-Encoding: 7bit"
	  puts $eFp {}
	  fcopy $dFp $eFp
	  foreach attachment $options(-attachments) {
	    puts $eFp "--$boundary2"
	    foreach {ctype descr encoding filename} $attachment {
	      puts $eFp "Content-ID: <[$self _CreateCID]>"
	      puts $eFp "Content-type: $ctype; name=[file tail $filename]"
	      if {[string length "$descr"] > 0} {
		puts $eFp "Content-Description: $descr"
	      }
	      puts $eFp "Content-Transfer-Encoding: $encoding"
	      puts $eFp {}
	      switch $encoding {
		7bit {
		  set fp [open "$filename" r]
		  fcopy $fp $eFp
		  close $fp
		}
		quoted-printable {
		  set fp [open "|[auto_execok mimencode] -q $filename" r]
		  fcopy $fp $eFp
		  close $fp
		}
		base64 {
		  set fp [open "|[auto_execok mimencode] -b $filename" r]
		  fcopy $fp $eFp
		  close $fp
		}
	      }
	    }
	  }
	  puts $eFp "--$boundary2"
	}
	close $dFp
	close $eFp
        set clFp [open $clearTextFile r]
        set plain [gpgme_data_new_from_fd $clFp]
        flush $iFp
        set cipher [gpgme_data_new_from_fd $iFp]
        gpgme_set_armor $ctx 1
        if {[catch {gpgme_op_encrypt $ctx $keys 0 $plain $cipher} result]} {
            if {$result eq "GPG_ERR_UNUSABLE_PUBKEY"} {
                set message "Some recipients did not have a usuable public key:\n"
                set encrypt_result [gpgme_op_encrypt_result $ctx]
                if {$encrypt_result ne "NULL"} {
                    set invalid_recipients [$encrypt_result cget -invalid_recipients]
                    while {$invalid_recipients ne "NULL"} {
                        set next_r [$invalid_recipients cget -next]
                        set fpr    [$invalid_recipients cget -fpr]
                        set reason [$invalid_recipients cget -reason]
                        append message "   $fpr: $reason\n"
                        set invalid_recipients $next_r
                    }
                }
                tk_messageBox -icon warning -type ok -message "$message"  -parent $win
            } else {
                tk_messageBox -icon error -type ok -message "$result" -parent $win
                gpgme_data_release $plain
                gpgme_data_release $cipher
                puts $iFp "--$boundary"
                close $iFp
                close $clFp
                file delete -force $clearTextFile
                foreach k $keys {gpgme_key_release $k}
                gpgme_release $ctx
                error "" "" RETURN
            }
        }
        puts $iFp "--$boundary"                
        gpgme_data_release $plain
        gpgme_data_release $cipher
	close $iFp
        close $clFp
        file delete -force $clearTextFile
        foreach k $keys {gpgme_key_release $k}
        gpgme_release $ctx
      } message]} {
        if {$::errorCode eq "RETURN"} {
            return [Dialog::enddialog $win -1]
        } else {
            Dialog::enddialog $win 0
            error "Error Sending message: $message" $::errorInfo $::errorCode
        }
      }
      return [Dialog::enddialog $win 1]
    }
    variable _baseCID {}
    variable _CIDindex -1
    method _CreateCID {} {
      if {[string length $_baseCID] == 0} {
	set _baseCID [clock format [clock scan now] -format {%a_%b_%d_%H_%M_%S_%Z_%Y}]
      }
      incr _CIDindex
      return "${_baseCID}_${_CIDindex}@[exec hostname]"
    }
    method _CreateBoundary {} {
      return "[exec hostname].[pid].[clock format [clock scan now] -format {%a.%b.%d.%H.%M.%S.%Z.%Y}]"
    }
    method _Dismis {} {
      Dialog::withdraw $win
      return [Dialog::enddialog $win 0]
    }
    method _Reedit {} {
      Dialog::withdraw $win
      $options(-spool) editDraft $options(-draftfile)
      return [Dialog::enddialog $win -1]
    }
    method _AttachFile {} {
      set attachment [Spool::GetAttachment draw -parent $win]
#      puts stderr "*** $self _AttachFile:  attachment = $attachment"
      if {[llength $attachment] > 0} {
	lappend options(-attachments) $attachment
	foreach {ctype descr encoding filename} $attachment {
	  $attachments insert end #auto -text [file tail "$filename"] \
					-data $attachment
	}
      }
    }
    method fillAttachmentList {} {
      $attachments delete [$attachments items]
      foreach attachment $options(-attachments) {
	foreach {ctype descr encoding filename} $attachment {
	  $attachments insert end #auto -text [file tail "$filename"] \
					-data $attachment
	}
      }
    }
    method fillWhomList {} {
      $whomlist delete [$whomlist items]
      if {[catch [list open "$options(-draftfile)" r] draftFp]} {return}
      set hbuffer {}
      while {[gets $draftFp line] >= 0} {
        if {[regexp {^[[:space:]]+[^[:space:]]} "$line"] > 0} {
	  append hbuffer " $line"
	} else {
	  if {[string length "$hbuffer"] > 0} {
#	    puts stderr "*** $type fillWhomList: hbuffer = '$hbuffer'"
	    if {[regexp -nocase {^to:[[:space:]]+(.*)$} "$hbuffer" -> towhome] > 0 ||
		[regexp -nocase {^cc:[[:space:]]+(.*)$} "$hbuffer" -> towhome] > 0} {
	      
	      set whoms [Common::SmartSplit "$towhome" ","]
	      foreach w $whoms {
		set w [string trim "$w"]
		set address [Common::GetRFC822Name "$w"]
		if {![$whomlist exists $address]} {
		  $whomlist insert end $address -text "MailTo: $w"
		}
	      }
	    } elseif {[regexp -nocase {^bcc:[[:space:]]+(.*)$} "$hbuffer" -> towhome] > 0} {
	      set whoms [Common::SmartSplit "$towhome" ","]
	      foreach w $whoms {
		set w [string trim "$w"]
		set address [Common::GetRFC822Name "$w"]
		if {![$whomlist exists $address]} {
		  $whomlist insert end $address -text "MailTo (blind): $w"
		}
	      }
	    } elseif {[regexp -nocase {^newsgroups: (.*)$} "$hbuffer" -> groups] > 0} {
	      set groups [split "$groups" ","]
	      foreach ng $groups {
		set ng [string trim "$ng"]
		if {![$whomlist exists $ng]} {
		  $whomlist insert end $ng -text "NewsGroup: $ng"
		}
	      }
	    }
	  }
	  set hbuffer [string trim "$line"]
	}
	if {[string length "$hbuffer"] == 0} {break}
      }
      close $draftFp		
    }
  }
  snit::type GetAttachment {
    pragma -hastypedestroy no
    pragma -hasinstances no
    pragma -hastypeinfo no

    typecomponent dialog
    typecomponent filenameLF
    typecomponent   filenameE
    typecomponent   filenameB
    typecomponent encodingLF
    typecomponent   encodingCB
    typecomponent descrLE
    typecomponent contentTypeLF
    typecomponent   contentTypeE
    typecomponent   contentTypeB
    typevariable  _labelWidth 15

    typeconstructor {
      set dialog [Dialog::create .getAttachment \
			-class GetAttachment -bitmap questhead \
			-default 0 -cancel 1 -modal local -transient yes \
			-parent . -side bottom -title {Attach a file}]
      $dialog add -name attach -text Attach -command [mytypemethod _Attach]
      $dialog add -name cancel -text Cancel -command [mytypemethod _Cancel]
      $dialog add -name help -text Help -command [list BWHelp::HelpTopic GetAttachment]
      set frame [$dialog getframe]
      set filenameLF [LabelFrame::create $frame.filenameLF \
						-width $_labelWidth \
						-text "Filename:" \
						-side left]
      pack $filenameLF -fill x
      set fnfr [$filenameLF getframe]
      set filenameE [Entry::create $fnfr.filenameE]
      pack $filenameE -expand yes -fill x -side left
      set filenameB [Button::create $fnfr.filenameB \
					-text Browse \
					-command [mytypemethod _BrowseFile]]
      pack $filenameB -side right
      set encodingLF [LabelFrame::create $frame.encodingLF \
						-width $_labelWidth \
						-text "Encoding:" \
						-side left]
      pack $encodingLF -fill x
      set enfr [$encodingLF getframe]
      set encodingCB [ComboBox::create $enfr.encodingCB \
				-values {7bit quoted-printable base64} \
				-editable no]
      $encodingCB setvalue first
      pack $encodingCB -expand yes -fill x
      set descrLE [LabelEntry::create $frame.descrLE \
						-labelwidth $_labelWidth \
						-label "Description:" \
						-side left]
      pack $descrLE -fill x
      set contentTypeLF [LabelFrame::create $frame.contentTypeLF \
						-width $_labelWidth \
						-text "Content Type:" \
						-side left]
      pack $contentTypeLF -fill x
      set ctfr [$contentTypeLF getframe]
      set contentTypeE [Entry::create $ctfr.contentTypeE]
      pack $contentTypeE -expand yes -fill x -side left
      set contentTypeB [Button::create $ctfr.contentTypeB \
				-text "Get Type" \
				-command [mytypemethod _GetType]]
      pack $contentTypeB -side right
    }
    typemethod _Attach {} {
      Dialog::withdraw $dialog
      return [Dialog::enddialog $dialog [list "[$contentTypeE cget -text]" \
					      "[$descrLE cget -text]" \
					      "[$encodingCB cget -text]" \
					      "[$filenameE cget -text]"]]
    }
    typemethod _Cancel {} {
      Dialog::withdraw $dialog
      return [Dialog::enddialog $dialog {}]
    }
    typemethod _BrowseFile {} {
      set oldfile "[$filenameE cget -text]"
      set olddir  "[file dirname $oldfile]"
      set newfile [tk_getOpenFile -initialdir "$olddir" \
				  -initialfile  "$oldfile" \
				  -parent $dialog \
				  -title "Name of file to attach"]
      if {[string length "$newfile"] > 0} {
	$filenameE configure -text "$newfile"
      }
    }
    typemethod _GetType {} {
      set file "[$filenameE cget -text]"
      set ctype [exec [auto_execok file] -ib "$file"]
      $contentTypeE configure -text "$ctype"
      if {[regexp {^text/} "$ctype"] > 0} {
	$encodingCB configure -text 7bit
      } else {
	$encodingCB configure -text base64
      }
    }
    typemethod draw {args} {
      set parent [from args -parent .]
      $dialog configure -parent $parent
      wm transient [winfo toplevel $dialog] $parent
      return [$dialog draw]
    }
  }
}

proc Spool::GetSpoolName { {default ""} {LoadedP 1} } {
  return [GetSpoolNameDialog draw -defaultSpool "$default" -loaded $LoadedP \
		-parent .]
}

proc Spool::ReviewSpool {{spool {}} {iconic 0}} {
  if {$spool == {}} {set spool [GetSpoolName local 0]}
  if {$spool == {}} {return}
  SpoolWindow getOrMakeSpoolByName $spool -iconic $iconic -reload yes
}

proc Spool::LoadQWKToSpool {qwkFile args} {
#  puts stderr "*** Spool::LoadQWKToSpool $qwkFile"
  set spoolname [file rootname [file tail $qwkFile]]
  set spool [SpoolWindow getOrMakeSpoolByName $spoolname \
			-reload yes -fromQWK $qwkFile]
}

SplashWorkMessage "Loaded Spool Functions" 33.33

package provide SpoolFunctions 1.0

