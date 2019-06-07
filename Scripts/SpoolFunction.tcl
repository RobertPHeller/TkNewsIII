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
package require Tk
package require tile
package require snit
package require IconImage
package require MainFrame
package require ScrollWindow
package require ButtonBox
package require GroupFunctions
package require ArticleFunctions
package require Dialog
package require CommonFunctions
package require AddressBook                                                    
package require HTMLHelp

snit::widget SpoolWindow {
    widgetclass SpoolWindow
    hulltype tk::toplevel
    
    typevalidator
    
    typevariable _menu {
        "&File" {file:menu} {file} 0 {
            {command "&Fetch QWK File" {file:fetch} "Fetch QWK File" {Ctrl f} -command "[mymethod _FetchMyQWKFile]" -state disabled}
            {command "&Read Group" {file:read} "Read Group" {Ctrl r} -command "[mymethod _ReadAGroup]" -state disabled}
            {command "&Post"       {file:post} "Post To Group" {Ctrl p} -command "[mymethod _PostToGroup]" -state disabled}
            {command "C&lean"      {file:clean} "Clean Group" {Ctrl l} -command "[mymethod _CleanGroup]" -state disabled}
            {command "Clean All Groups" {file:cleanall} "Clean All Groups" {} -command "[mymethod _CleanAllGroups]" -state disabled}
            {separator}
            {command "&Close"	   {file:close} "Close Spool" {Ctrl c} -command "[mymethod _CloseSpool]"}
        }
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
        }
        "&View" {view:menu} {view} 0 {
            {command "&Address Book" {view:addrbook} "View / Edit Address book" {} -command {AddressBook ViewEdit}}
        }
        "&Options" {options:menu} {options} 0 {
        } 
        "&Help" {help:menu} {help} 0 {
            {command "On &Help..." {help:help} "Help on help" {} -command "HTMLHelp help Help"}
            {command "&Index..." {help:index} "Help index" {} -command "HTMLHelp help Index"}
            {command "&Tutorial..." {help:tutorial} "Tutorial" {}  -command "HTMLHelp help Tutorial"}
            {command "On &Version" {help:version} "Version" {} -command "HTMLHelp help Version"}
            {command "Warranty" {help:warranty} "Warranty" {} -command "HTMLHelp help Warranty"}
            {command "Copying" {help:copying} "Copying" {} -command "HTMLHelp help Copying"}
        }
    }
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
    
    typevariable QWKReplyProg
    typevariable PrintCommand
    typeconstructor {
        global execbindir
        set QWKReplyProg [auto_execok [file join $execbindir qwkReply]]
        set PrintCommand "[option get . printCommand PrintCommand]"
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
    
    typemethod LoadQWKToSpool {qwkFile args} {
        #  puts stderr "*** $type LoadQWKToSpool $qwkFile"
        set spoolname [file rootname [file tail $qwkFile]]
        set spool [$type getOrMakeSpoolByName $spoolname \
                   -reload yes -fromQWK $qwkFile]
    }
    
    typemethod GetSpoolName { {default ""} {LoadedP 1} } {
        return [GetSpoolNameDialog draw -defaultSpool "$default" -loaded $LoadedP -parent .]
    }
    typemethod ReviewSpool {{spool {}} {iconic 0}} {
        if {$spool == {}} {set spool [$type GetSpoolName local 0]}
        if {$spool == {}} {return}
        $type getOrMakeSpoolByName $spool -iconic $iconic -reload yes
    }
    component main
    delegate method setmenustate to main        
    component panes
    component groupPane
    component   groupTreeFrame
    component artlistPane
    component   articleListFrame
    
    option -spoolname -readonly yes
    
    component newslist

    component articleViewWindow
    
    component selectIdentityDialog
    
    variable serverchannel
    variable imapserverchannel
    variable currentArticle {}
    variable currentGroup {}
    variable selectedGroup {}
    variable userName {}
    variable savedDirectories
    variable status {}
    variable progress 0

    option {-activefile activeFile ActiveFile} -type FileOrNull -default {}
    option {-cleanfunction cleanFunction CleanFunction} -readonly yes -type snit::boolean -default no
    option {-newsrc newsRc NewsRc} -readonly yes -type File -default {}
    option {-savednews savedNews SavedNews} -readonly yes -type Directory -default {}
    option -drafts -readonly yes -type Directory -default {}
    option {-servername serverName ServerName} -readonly yes -type Host -default localhost
    option {-spellchecker spellChecker SpellChecker} -readonly yes -default {}
    option {-externaleditor externalEditor ExternalEditor} -readonly yes -default {}
    option {-spooldirectory spoolDirectory SpoolDirectory} -readonly yes -type DirectoryOrNull -default {}
    option {-useserver useServer UseServer} -readonly yes -type snit::boolean -default no
    option {-useimap4 useIMap4 UseIMap4} -readonly yes -type snit::boolean -default no
    option {-imap4server iMap4Server IMap4Server} -readonly yes -type Host -default localhost
    option {-imap4username iMap4Username IMap4Username} -readonly yes -default {}
    option {-imap4password iMap4Password IMap4Password} -readonly yes -default {}
    option {-geometry spoolGeometry SpoolGeometry} -readonly yes -default {}
    option {-iconic iconic Iconic} -readonly yes -default 0 -type snit::boolean
    option {-killfile killFile KillFile} -readonly yes -default {} -type File
    
    delegate option * to hull
    delegate method {main *} to main
    method setstatus {string} {set status $string}
    method setprogress {n} {set progress $n}
    variable lockFile ~/.tknewsSpoolLock
    constructor {args} {
        wm iconbitmap $win [IconBitmap bitmap TkNewsIIIicon]
        wm iconmask   $win [IconBitmap bitmap TkNewsIIIicon_mask]
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
        set options(-useimap4) [from args -useimap4 [option get $win useIMap4 UseIMap4]]
        set options(-imap4server) [from args -imap4server [option get $win iMap4Server IMap4Server]]
        set options(-imap4username) [from args -imap4username [option get $win iMap4Username IMap4Usernae]]
        set options(-imap4password) [from args -imap4password [option get $win iMap4Password IMap4Password]]
        set options(-geometry) [from args -geometry [option get $win spoolGeometry SpoolGeometry]]
        set options(-killfile) [from args -killfile [option get $win killFile KillFile]]
        set lockFile [file join [file dirname $options(-newsrc)] .tknewsSpoolLock]
        
        set mypid [pid]
        if {[file readable $lockFile]} {
            set lfp [open $lockFile r]
            set lpid [gets $lfp]
            close $lfp
            if {[catch {exec ps h -p $lpid} result] || $result eq ""} {
                tk_messageBox -type ok -icon info \
                      -message "Removing state lock file for PID $lpid"
                file delete $lockFile
            } else {
                tk_messageBox -type ok -icon warning \
                      -message "Spool is in use by PID $lpid"
                wm withdraw $win
                return
            }
        }
        set lfp [open $lockFile w]
        puts $lfp $mypid
        close $lfp
                
                
        
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
        if {![string equal "$options(-savednews)" {}]} {
            set options(-savednews) [file normalize "$options(-savednews)"]
        }
        if {![string equal "$options(-drafts)" {}]} {
            set options(-drafts) [file normalize "$options(-drafts)"]
        }
        if {$options(-useserver)} {
            $self _Srv_Connect
            ServerMessageDialog draw -parent $win \
                  -title "$options(-spoolname): $options(-servername):  Connection Response" \
                  -message "[$self srv_recv]" -geometry 600x100
            set options(-spooldirectory) {}
            set options(-activefile) {}
        } elseif {$options(-useimap4)} {
            package require tls
            package require imap4
            set ::imap4::use_ssl yes
            set imapserverchannel [::imap4::open $options(-imap4server)]
            ::imap4::login $imapserverchannel $options(-imap4username) $options(-imap4password)
            set options(-spooldirectory) {}
            set options(-activefile) {}
        } else {
            set options(-spooldirectory) [file normalize "$options(-spooldirectory)"]
            set options(-activefile) [file normalize "$options(-activefile)"]
            set options(-newsrc) [file normalize "$options(-newsrc)"]
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
    
        set menu [subst $_menu]
	

        # Main window
        install main using MainFrame $win.main -menu $menu \
              -textvariable [myvar status] -progressvar [myvar progress] -progressmax 100
        $main showstatusbar progression
        pack $main -expand yes -fill both
        install panes using ttk::panedwindow [$main getframe].panes \
              -orient vertical 
        pack $panes -expand yes -fill both
        install groupPane using ttk::frame $panes.groupPane
        $panes add $groupPane -weight 2
        # Group tree
        if {$options(-useserver)} {
            set method NNTP
        } elseif {$options(-useimap4)} {
            set method IMAP4
        } else {
            set method File
        }
        install groupTreeFrame using GroupTreeFrame $groupPane.groupTreeFrame \
              -height [option get $win spoolNumGroups SpoolNumGroups] \
              -takefocus 1 -spool $self -method $method
        pack $groupTreeFrame -expand yes -fill both
        
        install artlistPane using ttk::frame $panes.artlistPane
        $panes add $artlistPane -weight 1
        # Article list
        install articleListFrame using ArticleListFrame \
              $artlistPane.articleListFrame \
              -takefocus 1 -spool $self -imap4buttons $options(-useimap4) \
              -height [option get $win spoolNumArticles SpoolNumArticles]
        pack $articleListFrame -fill both -expand yes
        #      puts stderr "*** ${type}::constructor: winfo class $articleListFrame = [winfo class $articleListFrame]"
        install selectIdentityDialog using SelectIdentityDialog \
              $win.selectIdentityDialog
        $self configurelist $args
        set _LoadedSpools($options(-spoolname)) $self
        set qfile [from args -fromQWK {}]
        if {[string length "$qfile"] > 0} {
            set loaded [LoadQWKFile %AUTO% \
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
        $self _LoadNewsRc
        $self _LoadGroupTree {.}
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
            $main setmenustate file:fetch normal
        }
        focus $groupTreeFrame
        if {$options(-cleanfunction)} {
            $main setmenustate file:cleanall normal
        }
    }
    proc _adjustTree {w h tree pane adjsign} {
        if {$h < [winfo reqheight $w]} {
            ## Attempting to squish a button box -- ouch!
            # First defense: try to shorten a tree
            set th [$tree cget -height]
            incr th -1
            if {$th > 0} {
                $tree configure -height $th
            } else {
                # Tree already shortened as much as we can.
                # Compute min/max sash position
                set sp [$pane sashpos 0]
                if {$adjsign eq "+"} {
                    incr sp [expr {[winfo reqheight $w] - $h}]
                } else {
                    incr sp [expr {$h - [winfo reqheight $w]}]
                }
                # Reset sash pos
                $pane sashpos 0 $sp
                ## And lock sash at min/max values -- prevent excess movement.
                # (simulate button release)
                set ttk::panedwindow::State(pressed) 0
                ttk::panedwindow::ResetCursor $pane
            }
        }
    }
    destructor {
        #      puts stderr "*** ${type}::destructor"
        catch {$newslist destroy}
        #      puts stderr "*** ${type}::destructor: $newslist destroy done: $message"
        if {$options(-useserver)} {catch {$self _Srv_NetClose}}
        catch {unset _LoadedSpools($options(-spoolname))} message
        #      puts stderr "*** ${type}::destructor: unset _LoadedSpools($options(-spoolname)) done: $message"
        catch {file delete $lockFile}
    }
    method _FetchMyQWKFile {args} {
        eval [list QWKFileProcess GetQWKFile "$options(-spoolname)"] $args
    }
    method reload {args} {
        set qfile [from args -fromQWK {}]
        set recycleprocesswindow [from args -recycleprocesswindow {}]
        if {[string length "$qfile"] > 0} {
            #	puts stderr "*** $self reload: Loading '$qfile'"
            set loaded [LoadQWKFile %AUTO% \
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
        #      puts stderr "*** $self reload: $self _LoadGroupTree {.}"
        $self _LoadGroupTree {.}
    }
    method user {} {return "$userName"}
    method _CloseSpool {{dontask no}} {
        if {!$dontask} {
            set answer [tk_messageBox -icon question \
                        -type yesno \
                        -message {Really close this spool?} \
                        -parent $win]
        } else {
            set answer yes
        }
        if {[string equal "$answer" no]} {return}
        catch {$self _WriteNewsRc} message
        #puts stderr "*** $self _CloseSpool: $self _WriteNewsRc done: $message"
        destroy $self
    }
    method IMap4ServerChannel {} {return $imapserverchannel}
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
    
    method _ReLoadActiveList {} {
        $groupTreeFrame reloadActiveFile
    }
    method _LoadNewsRc {} {
        install newslist using NewsList \
              "${options(-spoolname)}_news" \
              -file $options(-newsrc) \
              -grouptree $groupTreeFrame
    }
    method _WriteNewsRc {} {
        $newslist write
    }
    method _LoadGroupTree {pattern} {
        if {[string length "$options(-savednews)"] > 0} {
            set saved 1
        } else {
            set saved 0
        }
        $groupTreeFrame loadSubscribedGroupTree $pattern $saved
    }
    method _ReadAGroup {} {
        #puts stderr "*** ${type}::_ReadAGroup: selectedGroup = $selectedGroup, currentGroup = $currentGroup"
        if {[string equal "$selectedGroup" {}]} {return}
        if {![string equal "$currentGroup" {}] && 
            ![string equal "$currentGroup" "$selectedGroup"]} {
            $self _CloseGroup 0
        }
        $main setmenustate file:post normal
        $groupTreeFrame groupButtonBox itemconfigure close -state normal
        bind $win <Control-p> [mymethod _PostToGroup]
        set notsaved [catch "set savedDirectories($selectedGroup)"]
        #puts stderr "*** ${type}::_ReadAGroup: notsaved = $notsaved"
        #puts stderr "*** ${type}::_ReadAGroup: options(-cleanfunction) = $options(-cleanfunction)"
        if {$notsaved && $options(-cleanfunction)} {
            $main setmenustate file:clean normal
            bind $win <Control-l> [mymethod _CleanGroup]
        } else {
            $main setmenustate file:clean disabled
            bind $win <Control-l> {}
        }
        if {$notsaved} {
            $groupTreeFrame groupButtonBox itemconfigure unread -state normal
            $groupTreeFrame groupButtonBox itemconfigure catchup -state normal
            $groupTreeFrame groupButtonBox itemconfigure unsubscribe -state normal
            $articleListFrame artlistButtonBox itemconfigure post -state normal
            $articleListFrame artlistButtonBox itemconfigure list -state normal
            $articleListFrame artlistButtonBox itemconfigure read -state normal
            $articleListFrame artlistButtonBox itemconfigure refresh -state normal
            $articleListFrame artlistButtonBox itemconfigure manage -state disabled
        } else {
            $groupTreeFrame groupButtonBox itemconfigure unread -state disabled
            $groupTreeFrame groupButtonBox itemconfigure catchup -state disabled
            $groupTreeFrame groupButtonBox itemconfigure unsubscribe -state disabled
            $articleListFrame artlistButtonBox itemconfigure post -state normal
            $articleListFrame artlistButtonBox itemconfigure list -state normal
            $articleListFrame artlistButtonBox itemconfigure read -state normal
            $articleListFrame artlistButtonBox itemconfigure refresh -state normal
            $articleListFrame artlistButtonBox itemconfigure manage -state normal
        }
        # ReadGroup1
        set currentGroup "$selectedGroup"
        set groupWindow $win.[GroupName WindowName $currentGroup]
        set groupClass [string totitle [lindex [split $currentGroup {.}] 0]]
        catch {destroy $groupWindow}
        frame $groupWindow -class $groupClass
        set IsEmail [option get $groupWindow isEmail IsEmail]
        destroy $groupWindow
        if {$IsEmail} {
            $main menu entryconfigure file 1 -command "[mymethod _PostToGroup] yes"
            $articleListFrame artlistButtonBox itemconfigure post \
                  -text {Compose} -command "[mymethod _PostToGroup] yes"
            $articleListFrame articleButtonBox itemconfigure followup \
                  -text {Reply To All} \
                  -command "[mymethod _FollowupArticle] yes"
        } else {
            $main menu entryconfigure file 1 -command "[mymethod _PostToGroup] no"
            $articleListFrame artlistButtonBox itemconfigure post \
                  -text {Post} -command "[mymethod _PostToGroup] no"
            $articleListFrame articleButtonBox itemconfigure followup \
                  -text {Followup} \
                  -command "[mymethod _FollowupArticle] no"
        }
        $articleListFrame deleteall
        $groupTreeFrame insertArticleList $articleListFrame $currentGroup
        $groupTreeFrame configure -grouplabel "$currentGroup"
        focus $articleListFrame
    }
    method setSelectedGroup {selection} {
        set selectedGroup $selection
    }
    method _CloseGroup {{disableButtons 1}} {
        if {$disableButtons} {
            $main setmenustate file:read disabled
            bind $win <Control-r> {}
            $main setmenustate file:post disabled
            bind $win <Control-p> {}
            $main setmenustate file:clean disabled
            bind $win <Control-l> {}
            $groupTreeFrame groupButtonBox itemconfigure unread  -state disabled
            $groupTreeFrame groupButtonBox itemconfigure catchup  -state disabled
            $groupTreeFrame groupButtonBox itemconfigure unsubscribe  -state disabled
            $groupTreeFrame groupButtonBox itemconfigure close  -state disabled
            $articleListFrame configure -artlistbuttonstate disabled
        }
        if {[string equal "$currentGroup" {}]} {return}
        # Really close the group.
        $articleListFrame deleteall
        catch {$articleViewWindow close}
        catch {$self _WriteNewsRc}
        set currentGroup {}
    }
    #### Art List API...
    method _ReadSelectedArticle {} {
        #puts stderr "*** $self _ReadSelectedArticle"
        set selection [$articleListFrame selection]
        #puts stderr "*** $self _ReadSelectedArticle: selection is $selection"
        if {[llength $selection] < 1} {return}
        $self _ReadArticle [lindex $selection 0]
    }
    method _ReadArticle {selection} {
        #puts stderr "*** $self _ReadArticle $selection"
        set artNumber [$articleListFrame articlenumber $selection]
        $self _ReadArticleN $artNumber
    }
    method _ReadArticleN {artNumber {unread 1}} {
        #puts stderr "*** $self _ReadArticleN $artNumber $unread"
        #puts stderr "*** $self _ReadArticleN: -useserver is $options(-useserver)"
        #puts stderr "*** $self _ReadArticleN: -useimap4 is $options(-useimap4)"
        if {[catch "set savedDirectories($currentGroup)" mdir] == 0} {
            set filename [file join $mdir $artNumber]
            if {![file exists $filename]} {return}
            if {![file readable $filename]} {return}
            set currentArticle $artNumber
            set useFile yes
        } elseif {$options(-useserver)} {
            if {![$groupTreeFrame articleExists $currentGroup $artNumber]} {return}
            set currentArticle $artNumber
            set useFile no
        } elseif {$options(-useimap4)} {
            if {![$groupTreeFrame articleExists $currentGroup $artNumber]} {return}
            set currentArticle $artNumber
            set useFile no
        } else {
            set filename [file join "$options(-spooldirectory)" [GroupName Path $currentGroup] $artNumber]
            if {![file exists $filename]} {return}
            if {![file readable $filename]} {return}
            set currentArticle $artNumber
            set useFile yes
        }
        set nextArticle [$groupTreeFrame findNextArticle $currentGroup $currentArticle $unread]
        set previousArticle [$groupTreeFrame findPreviousArticle $currentGroup $currentArticle $unread]
        if {[string equal $articleViewWindow {}]} {
            install articleViewWindow \
                  using ArticleViewer $win.articleViewWindow \
                  -parent $win -spool $self \
                  -imap4buttons $options(-useimap4)
        }
        $articleViewWindow draw      
        update idletasks
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
        #puts stderr "*** $self _ReadArticleN: useFile is $useFile"
        if {!$useFile} {
            if {$options(-useimap4)} {
                $articleViewWindow IMap4_GetArticleToText
            } else {
                $articleViewWindow NNTP_GetArticleToText
            }
        } else {
            $articleViewWindow readArticleFromFile $filename
        }
        $groupTreeFrame findRange $currentGroup $currentArticle yes
        $groupTreeFrame updateGroupLineInTree $currentGroup
        $articleListFrame articleButtonBox configure -state normal
        if {$options(-useimap4)} {
            $articleListFrame articleIMapButtonBox configure -state normal
        }
        $newslist write
    }
    method closeArticle {} {
        $articleListFrame articleButtonBox configure -state disabled
        if {$options(-useimap4)} {
            $articleListFrame articleIMapButtonBox configure -state disabled
        }
    }
    method _UnreadGroup {} {
        $groupTreeFrame groupsetranges $currentGroup {}
        $articleListFrame deleteall
        $groupTreeFrame insertArticleList $articleListFrame $currentGroup
        $newslist write
    }
    method _SaveArticle {} {
        $articleViewWindow buttons invoke save
    }
    method _FileArticle {} {
        $articleViewWindow buttons invoke file
    }
    method _MoveToFolder {} {
        $articleViewWindow imap4buttons invoke move
    }
    method _CopyToFolder {} {
        $articleViewWindow imap4buttons invoke copy
    }
    method _MoveToTrash {} {
        $articleViewWindow imap4buttons invoke trash
    }
    method _EmptyTrash {} {
        $articleViewWindow imap4buttons invoke empty
    }
    method _DeleteFolder {} {
        $articleViewWindow imap4buttons invoke delete
    }
    method _NewFolder {} {
        $articleViewWindow imap4buttons invoke new
    }
    method addSavedGroupLine {group newsaved} {
        $groupTreeFrame addSavedGroupLineInTree $group $newsaved
    }
    method updateGroupTreeLine {name} {
        $groupTreeFrame updateGroupLineInTree $name
    }
    method _PrintArticle {} {
        $articleViewWindow buttons invoke print
    }
    method _RefereshArticles {} {
        $articleListFrame deleteall
        $groupTreeFrame insertArticleList $articleListFrame $currentGroup
    }
    # Misc additional group functions
    method _CatchUpGroup {} {
        if {[catch "set savedDirectories($currentGroup)" mdir] == 0} {return}
        $groupTreeFrame catchUpGroup $articleListFrame $currentGroup
        $newslist write
    }
    method _CleanGroup {} {
        if {!$options(-cleanfunction)} {return}
        if {[catch "set savedDirectories($currentGroup)" mdir] == 0} {return}
        if {$options(-useserver)} {return}
        set answer [tk_messageBox -icon question \
                    -type yesno \
                    -message "Really clean group $currentGroup?" \
                    -parent $win]
        if {[string equal "$answer" no]} {return}
        $groupTreeFrame cleanGroup $articleListFrame $currentGroup
        $self _CloseGroup
    }
    method _CleanAllGroups {} {
        if {!$options(-cleanfunction)} {return}
        if {$options(-useserver)} {return}
        set answer [tk_messageBox -icon question \
                    -type yesno \
                    -message "Really clean all groups?" \
                    -parent $win]
        if {[string equal "$answer" no]} {return}
        $self _CloseGroup
        foreach group [$groupTreeFrame activeGroups] {
            if {[catch "set savedDirectories($group)" mdir] == 0} {continue}
            if {[string equal -nocase "$group" reply]} {continue}
            $groupTreeFrame cleanGroup {} $group
        }
        $self _LoadGroupTree {.}
        catch {$self _WriteNewsRc} message
        #puts stderr "*** $self _CleanAllGroups: $self _WriteNewsRc done: $message"
    }
    method _UnSubscribeGroup {} {
        if {[catch "set savedDirectories($currentGroup)" mdir]} {
            $groupTreeFrame unSubscribeGroup $currentGroup
        }
        $self _CloseGroup
    }
    method _SubscribeToGroup {newgroup} {
        if {[string length "$options(-savednews)"] > 0} {
            set saved 1
        } else {
            set saved 0
        }
        $groupTreeFrame subscribeGroup $newgroup $saved
        $newslist write
    }
    method _ListSearchArticles {} {
        SearchArticlesDialog draw \
              -parent $win -grouptree $groupTreeFrame \
              -group $currentGroup -readarticle [mymethod _ReadArticleN]
    }
    # Saved articles management menu
    method _PrintAllSavedArticles {} {
        if {[catch "set savedDirectories($currentGroup)" mdir]} {return}
        set mlist [glob -nocomplain [file join "$mdir" *]]
        set numMessages [MessageList CountMessages $mlist]
        if {$numMessages == 0} {return}
        set firstMessage [MessageList Lowestnumber $mlist]
        set lastMessage  [MessageList Highestnumber $mlist]
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
            ServerMessageDialog draw \
                  -parent $win \
                  -title "$PrintCommand messages" \
                  -message "$message" \
                  -geometry 600x200
        }
        
    }
    method _DeleteAllSavedArticles {} {
        if {[catch "set savedDirectories($currentGroup)" mdir]} {return}
        set mlist [glob -nocomplain [file join "$mdir" *]]
        set numMessages [MessageList CountMessages $mlist]
        if {$numMessages == 0} {return}
        set answer [tk_messageBox -icon question \
                    -type yesno \
                    -message "Really clean group $currentGroup?" \
                    -parent $win]
        if {[string equal "$answer" no]} {return}
        set firstMessage [MessageList Lowestnumber $mlist]
        set lastMessage  [MessageList Highestnumber $mlist]
        for {set im $firstMessage} {$im <= $lastMessage} {incr im} {
            set mfile [file join $mdir $im]
            if {[file exists "$mfile"] && [file writable "$mfile"]} {
                file delete $mfile
            }
        }
        $groupTreeFrame updateGroupLineInTree $currentGroup
        $articleListFrame deleteall
        $groupTreeFrame insertArticleList $articleListFrame $currentGroup
    }
    method _DeleteSelectedArticles {} {
        if {[catch "set savedDirectories($currentGroup)" mdir]} {return}
        # -- Delete selected articles. (Needs a Dialog w/ListBox)
        set artList [SelectArticlesDialog draw \
                     -parent $win -grouptree $groupTreeFrame \
                     -group $currentGroup -selectmode extended \
                     -title "Articles to delete" -geometry 750x400]
        foreach a $artList {
	    set mfile [file join $mdir $a]
            if {[file exists "$mfile"] && [file writable "$mfile"]} {
                file delete $mfile
            }
        }
        $groupTreeFrame updateGroupLineInTree $currentGroup
        $articleListFrame deleteall
        $groupTreeFrame insertArticleList $articleListFrame $currentGroup
    }
    method _RenumberArticles {} {
        if {[catch "set savedDirectories($currentGroup)" mdir]} {return}
        set mlist [glob -nocomplain [file join "$mdir" *]]
        set numMessages [MessageList CountMessages $mlist]
        if {$numMessages == 0} {return}
        set firstMessage [MessageList Lowestnumber $mlist]
        set lastMessage  [MessageList Highestnumber $mlist]
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
        $groupTreeFrame updateGroupLineInTree $currentGroup
        $articleListFrame deleteall
        $groupTreeFrame insertArticleList $articleListFrame $currentGroup
    }
    method _RecodeArticle {} {
        if {[catch "set savedDirectories($currentGroup)" mdir]} {return}
        set artList [SelectArticlesDialog draw \
                         -parent $win -grouptree $groupTreeFrame \
                         -group $currentGroup -selectmode browse]
        if {[llength $artList] == 0} {return}
        
    }
    method _FlatfileArticles {} {
        if {[catch "set savedDirectories($currentGroup)" mdir]} {return}
        set mlist [glob -nocomplain [file join "$mdir" *]]
        set numMessages [MessageList CountMessages $mlist]
        if {$numMessages == 0} {return}
        set firstMessage [MessageList Lowestnumber $mlist]
        set lastMessage  [MessageList Highestnumber $mlist]
        set saveFile [tk_getSaveFile -defaultextension .text \
                      -filetypes { {{Text Files} {.text .txt} TEXT} \
                      {{All Files} {*} } } \
                      -parent $win -title {Enter filename: }]
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
        foreach postGroup [$groupTreeFrame activeGroups] {
            set groupWindow $win.[GroupName WindowName $postGroup]
            set groupClass [string totitle [lindex [split $postGroup {.}] 0]]
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
        foreach {fromString organizationString} [$self getIdentity $groupWindow] {break}
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
            if {[AddressBook GetToCcAddresses ToAddrs CCAddrs] eq "ok"} {
                puts $draftFp "To: [join $ToAddrs {,}]"
                if {$ccSelf && [string length "$fromString"] > 0} {
                    lappend CCAddrs "$fromString"
                }
                puts $draftFp "Cc: [join $CCAddrs {,}]"
            } else {
                close $draftFp
                catch {destroy $groupWindow}
                file delete $draftFile
                return
            }
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
                set highMessage [MessageList Highestnumber [glob -nocomplain "$saveDir/*"]]
                set mnum [expr $highMessage + 1]
                set saveFile [file join $saveDir $mnum]
                file copy $draftFile $saveFile
                ServerMessageDialog Message $win "Message not sent" "Draft saved in $saveFile"
            }
        }
        file delete $draftFile      
    }
    # Get identity (from and organization)
    method getIdentity {window} {
        set identities [option get $window identities Identities]
        if {[llength $identities] == 0} {
            return [list "[option get $window from From]" \
                    "[option get $window organization Organization]"]
        } else {
            return [$selectIdentityDialog draw -identities $identities \
                    -fallbackid [list "[option get $window from From]" \
                                 "[option get $window organization Organization]"] \
                    -parent $win]
        }
    }
    
    # Post or mail a message
    method _PostToGroup {{isEmail no}} {
        set theGroup $currentGroup
        #      puts stderr "*** $self _PostToGroup: theGroup = $theGroup, isEmail = $isEmail"
        set postGroup [$self _PostGroup $theGroup]
        set groupWindow $win.[GroupName WindowName $postGroup]
        set groupClass [string totitle [lindex [split $postGroup {.}] 0]]
        catch {destroy $groupWindow}
        frame $groupWindow -class $groupClass
        #      puts stderr "*** $self _PostToGroup: postGroup = $postGroup, groupWindow = $groupWindow"
        set draftFile /usr/tmp/$groupWindow.[pid]
        set signatureFile [option get $groupWindow signatureFile SignatureFile]
        set followupWithXCommentTo [option get $groupWindow followupWithXCommentTo FollowupWithXCommentTo]
        set followupEmailTo [option get $groupWindow followupEmailTo FollowupEmailTo]
        foreach {fromString organizationString} [$self getIdentity $groupWindow] {break}
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
        puts $draftFp "X-Newsreader: TkNews 3.0 ($::BUILDSYMBOLS::VERSION)"
        puts $draftFp "Subject: "
        #puts stderr "*** $self _PostToGroup: isEmail = $isEmail"
        if {$isEmail} {
            if {[AddressBook  GetToCcAddresses ToAddrs CCAddrs] eq "ok"} {
                puts $draftFp "To: [join $ToAddrs {,}]"
                if {$ccSelf && [string length "$fromString"] > 0} {
                    lappend CCAddrs "$fromString"
                }
                puts $draftFp "Cc: [join $CCAddrs {,}]"
            } else {
                close $draftFp
                catch {destroy $groupWindow}
                file delete $draftFile
                return
            }
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
                set highMessage [MessageList Highestnumber [glob -nocomplain "$saveDir/*"]]
                set mnum [expr $highMessage + 1]
                set saveFile [file join $saveDir $mnum]
                file copy $draftFile $saveFile
                ServerMessageDialog Message $win "Message not sent" "Draft saved in $saveFile"
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
        set groupWindow $win.[GroupName WindowName $postGroup]
        set groupClass [string totitle [lindex [split $postGroup {.}] 0]]
        catch {destroy $groupWindow}
        frame $groupWindow -class $groupClass
        set draftFile /usr/tmp/$groupWindow.[pid]
        set signatureFile [option get $groupWindow signatureFile SignatureFile]
        set followupWithXCommentTo [option get $groupWindow followupWithXCommentTo FollowupWithXCommentTo]
        set followupEmailTo [option get $groupWindow followupEmailTo FollowupEmailTo]
        foreach {fromString organizationString} [$self getIdentity $groupWindow] {break}
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
        puts $draftFp "X-Newsreader: TkNews 3.0 ($::BUILDSYMBOLS::VERSION)"
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
                set highMessage [MessageList Highestnumber [glob -nocomplain "$saveDir/*"]]
                set mnum [expr $highMessage + 1]
                set saveFile [file join $saveDir $mnum]
                file copy $draftFile $saveFile
                ServerMessageDialog Message $win "Message not sent" "Draft saved in $saveFile"
            }
        }
        file delete $draftFile
    }
    method _MailReply {} {
        set theGroup $currentGroup
        set postGroup [$self _PostGroup $theGroup]
        set groupWindow $win.[GroupName WindowName $postGroup]
        set groupClass [string totitle [lindex [split $postGroup {.}] 0]]
        catch {destroy $groupWindow}
        frame $groupWindow -class $groupClass
        set draftFile /usr/tmp/$groupWindow.[pid]
        set signatureFile [option get $groupWindow signatureFile SignatureFile]
        set followupWithXCommentTo [option get $groupWindow followupWithXCommentTo FollowupWithXCommentTo]
        set followupEmailTo [option get $groupWindow followupEmailTo FollowupEmailTo]
        foreach {fromString organizationString} [$self getIdentity $groupWindow] {break}
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
        puts $draftFp "X-Newsreader: TkNews 3.0 ($::BUILDSYMBOLS::VERSION)"
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
                set highMessage [MessageList Highestnumber [glob -nocomplain "$saveDir/*"]]
                set mnum [expr $highMessage + 1]
                set saveFile [file join $saveDir $mnum]
                file copy $draftFile $saveFile
                ServerMessageDialog Message $win "Message not sent" "Draft saved in $saveFile"
            }
        }
        file delete $draftFile
    }
    method _ForwardTo {} {
        set theGroup $currentGroup
        set postGroup [$self _PostGroup $theGroup]
        set groupWindow $win.[GroupName WindowName $postGroup]
        set groupClass [string totitle [lindex [split $postGroup {.}] 0]]
        catch {destroy $groupWindow}
        frame $groupWindow -class $groupClass
        set draftFile /usr/tmp/$groupWindow.[pid]
        set signatureFile [option get $groupWindow signatureFile SignatureFile]
        set followupWithXCommentTo [option get $groupWindow followupWithXCommentTo FollowupWithXCommentTo]
        set followupEmailTo [option get $groupWindow followupEmailTo FollowupEmailTo]
        foreach {fromString organizationString} [$self getIdentity $groupWindow] {break}
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
        puts $draftFp "X-Newsreader: TkNews 3.0 ($::BUILDSYMBOLS::VERSION)"
        set subject [$articleViewWindow getHeader subject]
        set subject "Fwd: $subject"
        puts $draftFp "Subject: $subject"
        if {[AddressBook GetToCcAddresses ToAddrs CCAddrs] eq "ok"} {
            puts $draftFp "To: [join $ToAddrs {,}]"
            if {$ccSelf && [string length "$fromString"] > 0} {
                lappend CCAddrs "$fromString"
            }
            puts $draftFp "Cc: [join $CCAddrs {,}]"
            puts $draftFp {}
        } else {
            close $draftFp
            catch {destroy $groupWindow}
            file delete $draftFile
            return
        }
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
                set highMessage [MessageList Highestnumber [glob -nocomplain "$saveDir/*"]]
                set mnum [expr $highMessage + 1]
                set saveFile [file join $saveDir $mnum]
                file copy $draftFile $saveFile
                ServerMessageDialog Message $win "Message not sent" "Draft saved in $saveFile"
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
        set articlePostMenu [ArticlePostMenu $win.articlePostMenu%AUTO% \
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
        set result "$string"
        regsub -all {\$QWKREPLY} "$result" "$QWKReplyProg" result
        regsub -all {%spool} "$result" "$options(-spooldirectory)" result
        regsub -all {%active} "$result" "$options(-activefile)" result
        regsub -all {%group} "$result" "$group" result
        return $result
    }
    method editDraft {draftFile} {
        if {[string equal "$options(-externaleditor)" {}]} {
            set edit [SimpleDraftEditor \
                      create $win.articleEditor%AUTO% -parent $win]
            $edit editfile "$draftFile"
            destroy $edit
        } else {
            set edit [WaitExternalProgramASync create editor%AUTO% \
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
    method NNTP_LoadArticleHead {group artnumber articleList {pattern {.}} {nread {}}} {
        set subject {}
        set from {}
        set date {}
        set lines 0
        set size 0
        set messageid {}
        set intrplyto {}
        
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
            if {[string first "Message-ID: " $line] == 0} {
                set messageid [string range $line 12 end]
                continue
            }
            if {[string first "In-Reply-To: " $line] == 0} {
                set inreplyto [string range $line 13 end]
                continue
            }
        }
        set from [RFC822 Name $from]
        if {[regexp -nocase -- "$pattern" "$subject"] && 
            [$self _PassKillFile "$from" "$subject"]} {
            if {[string length $subject] > 36} {set subject [string range $subject 0 35]}
            if {[string length $from] > 20} {set from [string range $from 0 19]}
            if {[string length $date] > 25} {set date [string range $date 0 24]}
            set line "[format  {%6d %s%-36s %-20s %-25s %5d} $artnumber $nread $subject $from $date $lines]"
            #	set font [option get $listbox font Font]
            #        puts stderr "*** ${type}::NNTP_LoadArticleHead: listbox = $listbox, font = $font"
            $articleList insertArticleHeader $artnumber $nread $from $date $lines $size $messageid $inreplyto
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

################



snit::type GetSpoolNameDialog {
    pragma -hastypedestroy no
    pragma -hasinstances no
    pragma -hastypeinfo no
    
    typecomponent dialog
    typecomponent spoolTree
    typecomponent spoolNameFrame
    typecomponent   spoolNameLabel
    typecomponent   spoolNameEntry
    
    typeconstructor {
        set dialog [Dialog .getSpoolNameDialog \
                    -class GetSpoolNameDialog -bitmap questhead \
                    -default ok -cancel cancel -modal local -transient yes \
                    -parent . -side bottom -title {Select a spool}]
        $dialog add ok -text OK -command [mytypemethod _OK]
        $dialog add cancel -text Cancel -command [mytypemethod _Cancel]
        $dialog add help -text Help -command [list HTMLHelp help "Get Spool Name Dialog"]
        set frame [$dialog getframe]
        set spoolTree $frame.spoolTree
        set spoolNameFrame $frame.spoolNameFrame
        set spoolNameLabel $spoolNameFrame.spoolNameLabel
        set spoolNameEntry $spoolNameFrame.spoolNameEntry
        pack [ttk::treeview $spoolTree -selectmode browse -show {tree}] \
              -expand yes -fill both
        $spoolTree tag bind spool <1> [mytypemethod _SelectFromList %x %y]
        $spoolTree tag bind spool <space> [mytypemethod _SelectFromList %x %y]
        $spoolTree tag bind spool <Double-Button-1> [mytypemethod _ReturnFromList %x %y]
        $spoolTree tag bind spool <Return> [mytypemethod _ReturnFromList %x %y]
        pack [ttk::frame $spoolNameFrame] -fill x -expand yes
        pack [ttk::label $spoolNameLabel -text "Spool:" -anchor w] -side left
        pack [ttk::entry $spoolNameEntry] -side left -fill x -expand yes
        bind $spoolNameEntry <Return> [mytypemethod _OK]
    }
    typemethod _OK {} {
        set answer "[$spoolNameEntry get]"
        $dialog withdraw
        return [$dialog enddialog "$answer"]
    }
    typemethod _Cancel {} {
        $dialog withdraw
        return [$dialog enddialog {}]
    }
    typemethod _SelectFromList {x y} {
        set selection [$spoolTree identify row $x $y]
        $spoolNameEntry delete 0 end
        $spoolNameEntry insert end $selection
    }
    typemethod _ReturnFromList {x y} {
        $self _SelectFromList $x $y
        $type _OK
    }
    typemethod draw {args} {
        set default [from args -defaultSpool {}]
        $spoolNameEntry delete 0 end
        $spoolNameEntry insert end "$default"
        set loadedP [from args -loaded no]
        $spoolTree delete [$spoolTree children {}]
        if {$loadedP} {
            set spoolList [SpoolWindow loadedSpools]
        } else {
            set spoolList [option get . spoolList SpoolList]
        }
        foreach sp $spoolList {
            $spoolTree insert {} end -id $sp -text $sp
        }
        set parent [from args -parent .]
        $dialog configure -parent $parent
        wm transient [winfo toplevel $dialog] $parent
        return [$dialog draw]
    }
}

snit::widgetadaptor ArticlePostMenu {
    
    option -parent -readonly yes -default . -type snit::window
    option -draftfile -readonly yes -type File
    option -group -readonly yes
    option {-groupwindow groupWindow GroupWindow} -readonly yes -type snit::window
    option -spool -readonly yes -type SpoolWindow
    option -attachments -default {} -type snit::listtype
    option {-useemail useEmail UseEmail} -readonly yes -default no -type snit::boolean
    
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
        #puts stderr "*** $type create $self: $args"
        set options(-parent) [from args -parent .]
        installhull using Dialog -parent $options(-parent) \
              -class ArticlePostMenu -default send -cancel dismis\
              -modal local -transient yes -side bottom -bitmap questhead \
              -title {What Now?}
        #puts stderr "*** $type create $self: after installhull"
        $hull add spell \
              -text {Spell Check} \
              -command [mymethod _SpellCheck]
        $hull add send \
              -text {Send} \
              -command [mymethod _SendMessage]
        $hull add sendencrypted \
              -text "Send\nEncrypted" \
              -command [mymethod _SendMessageEncrypted]
        $hull add dismis \
              -text {Dismis} \
              -command [mymethod _Dismis]
        $hull add reedit \
              -text {Reedit} \
              -command [mymethod _Reedit]
        #puts stderr "*** $type create $self: buttons added"
        wm protocol $win WM_DELETE_WINDOW [mymethod _Dismis]
        #puts stderr "*** $type create $self: wm protocol WM_DELETE_WINDOW done"
        $self configurelist $args
        $self _ValidateRequiredOption -draftfile
        $self _ValidateRequiredOption -group
        $self _ValidateRequiredOption -groupwindow
        $self _ValidateRequiredOption -spool
        #puts stderr "*** $type create $self: required options checked"
        install whomlistSW using ScrolledWindow \
              [$hull getframe].whomlistSW \
              -scrollbar vertical -auto vertical
        pack $whomlistSW -expand yes -fill both -side left
        set wl [$whomlistSW getframe].whomlist
        install whomlist using ttk::treeview $wl \
              -selectmode none -show tree
        $whomlistSW setwidget $whomlist
        $self fillWhomList
        if {$options(-useemail)} {
            install attachmentsSW using ScrolledWindow \
                  [$hull getframe].attachmentsSW \
                  -scrollbar both -auto both
            pack $attachmentsSW  -expand yes -fill both -side left
            set al [$attachmentsSW getframe].attachments
            install attachments using ttk::treeview $al -selectmode none \
                  -show tree -columns {ctype descr encoding filename} \
                  -displaycolumns {}
            $attachmentsSW setwidget $attachments
            $attachments tag bind attachment <3> [mymethod _ShowAttachment]
            $self fillAttachmentList
            $hull add attach \
                  -text {Attach File} \
                  -command [mymethod _AttachFile] 
        }
    }
    method _ShowAttachment {x y} {
        set attachment [$attachments item [$attachments identify row $x $y] -columns]
        foreach {ctype descr encoding filename} $attachment {
            tk_messageBox -type ok -icon info -message "$filename: $ctype; $encoding; $descr" -parent $win
        }
    }
    method draw {} {return [$hull draw]}
    method _SpellCheck {} {
        $hull withdraw
        set spell [WaitExternalProgramASync create spellCheck%AUTO% \
                   -commandline "[$options(-spool) cget -spellchecker] $options(-draftfile)"]
        $spell wait
        $spell destroy
        return [$hull enddialog -1]
    }
    method _SendMessage1 {} {
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
            puts stderr "*** $self _SendMessage: copying base headers"
            while {[gets $dFp line] > 0 && [string trim "$line"] ne ""} {
                puts $iFp "$line"
                puts stderr "*** $self _SendMessage: line = '$line'"
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
    }
    method _SendMessage {} {
        $hull withdraw
        
        if {[catch {$self _SendMessage1} message]} {
            $hull enddialog 0
            error "Error Sending message: $message"
        }
        return [$hull enddialog 1]
    }
    method _SendMessageEncrypted1 {} { 
	if {$options(-useemail)} {
            set inject [option get $options(-groupwindow) emailProgram EmailProgram]
	} else {
            set inject [option get $options(-groupwindow) injectProgram InjectProgram]
        }
        #	puts stderr "*** $self _SendMessageEncrypted: inject = $inject"
	set inject [$options(-spool) replaceKeys "$inject" $options(-group)]
        #	puts stderr "*** $self _SendMessageEncrypted (after _ReplaceKeys): inject = $inject"
        package require Gpgme
        gpgme_check_version 0.0.0
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
                        set from [RFC822 EMail "$fromwhome"]
                    } elseif {[regexp -nocase {^to:[[:space:]]+(.*)$} "$hbuffer" -> towhome] > 0 ||
		        [regexp -nocase {^cc:[[:space:]]+(.*)$} "$hbuffer" -> towhome] > 0 ||
		        [regexp -nocase {^bcc:[[:space:]]+(.*)$} "$hbuffer" -> towhome] > 0} {
                        #puts stderr "*** $self _SendMessageEncrypted: towhome = $towhome"
                        set whoms [RFC822 SmartSplit "$towhome" ","]
                        #puts stderr "*** $self _SendMessageEncrypted: whoms = $whoms"
                        foreach w $whoms {
                            set w [string trim "$w"]
                            set address [RFC822 EMail "$w"]
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
            puts $eFp "MIME-Version: 1.0"
            puts $eFp "Content-type: text/plain"
            puts $eFp {}
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
    }
    method _SendMessageEncrypted {} {
        $hull withdraw
        
        if {[catch {$self _SendMessageEncrypted1} message]} {
            if {$::errorCode eq "RETURN"} {
                return [$hull enddialog -1]
            } else {
                $hull enddialog 0
                error "Error Sending message: $message" $::errorInfo $::errorCode
            }
        }
        return [$hull enddialog 1]
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
        $hull withdraw
        return [$hull enddialog 0]
    }
    method _Reedit {} {
        $hull withdraw
        $options(-spool) editDraft $options(-draftfile)
        return [$hull enddialog -1]
    }
    method _AttachFile {} {
        set attachment [GetAttachment draw -parent $win]
        #      puts stderr "*** $self _AttachFile:  attachment = $attachment"
        if {[llength $attachment] > 0} {
            lappend options(-attachments) $attachment
            foreach {ctype descr encoding filename} $attachment {
                $attachments insert {} end  -text [file tail "$filename"] \
                      -values $attachment
            }
        }
    }
    method fillAttachmentList {} {
        $attachments delete [$attachments children {}]
        foreach attachment $options(-attachments) {
            foreach {ctype descr encoding filename} $attachment {
                $attachments insert {} end -text [file tail "$filename"] \
                      -values $attachment
            }
        }
    }
    method fillWhomList {} {
        $whomlist delete [$whomlist children {}]
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
                        
                        set whoms [RFC822 SmartSplit "$towhome" ","]
                        foreach w $whoms {
                            set w [string trim "$w"]
                            set address [RFC822 Name "$w"]
                            if {![$whomlist exists $address]} {
                                $whomlist insert {} end -id $address -text "MailTo: $w"
                            }
                        }
                    } elseif {[regexp -nocase {^bcc:[[:space:]]+(.*)$} "$hbuffer" -> towhome] > 0} {
                        set whoms [RFC822 SmartSplit "$towhome" ","]
                        foreach w $whoms {
                            set w [string trim "$w"]
                            set address [RFC822 Name "$w"]
                            if {![$whomlist exists $address]} {
                                $whomlist insert {} end -id $address -text "MailTo (blind): $w"
                            }
                        }
                    } elseif {[regexp -nocase {^newsgroups: (.*)$} "$hbuffer" -> groups] > 0} {
                        set groups [split "$groups" ","]
                        foreach ng $groups {
                            set ng [string trim "$ng"]
                            if {![$whomlist exists $ng]} {
                                $whomlist insert {} end -id $ng -text "NewsGroup: $ng"
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
    typecomponent filenameF
    typecomponent   filenameL
    typecomponent   filenameE
    typecomponent   filenameB
    typecomponent encodingF
    typecomponent   encodingL
    typecomponent   encodingCB
    typecomponent descrF    
    typecomponent   descrL    
    typecomponent   descrE    
    typecomponent contentTypeF
    typecomponent   contentTypeL
    typecomponent   contentTypeE
    typecomponent   contentTypeB
    typevariable  _labelWidth 15
    
    typeconstructor {
        set dialog [Dialog .getAttachment \
                    -class GetAttachment -bitmap questhead \
                    -default attach -cancel cancel -modal local -transient yes \
                    -parent . -side bottom -title {Attach a file}]
        $dialog add attach -text Attach -command [mytypemethod _Attach]
        $dialog add cancel -text Cancel -command [mytypemethod _Cancel]
        $dialog add help -text Help -command [list HTMLHelp help GetAttachment]
        set frame [$dialog getframe]
        set filenameF [ttk::frame $frame.filenameF]
        pack $filenameF -fill x -expand yes
        set filenameL [ttk::label $filenameF.filenameL \
                       -text "Filename:" -anchor w -width $_labelWidth]
        pack $filenameL -side left
        set filenameE [ttk::entry $filenameF.filenameE]
        pack $filenameE -expand yes -fill x -side left
        set filenameB [ttk::button $filenameF.filenameB \
                       -text Browse \
                       -command [mytypemethod _BrowseFile]]
        pack $filenameB -side right
        set encodingF [ttk::frame $frame.encodingF]
        pack $encodingF -fill x
        set encodingL [ttk::label $encodingF.encodingL -width $_labelWidth \
                       -text "Encoding:" -anchor w]
        pack $encodingL -side left
        set encodingCB [ttk::combobox $encodingF.encodingCB \
                        -values {7bit quoted-printable base64} \
                        -state readonly]
        $encodingCB set 7bit
        pack $encodingCB -expand yes -fill x
        set descrF [ttk::frame $frame.descrF]
        pack $descrF -fill x
        set descrL [ttk::label $descrF.descrL -width $_labelWidth \
                    -text "Description:" -anchor w]
        pack $descrL -side left
        set descrE [ttk::entry $descrF.descrE]
        pack $descrE -side left -fill x -expand yes
        set contentTypeF [ttk::frame $frame.contentTypeF]
        pack $contentTypeF -fill x
        set contentTypeL [ttk::label $contentTypeF.contentTypeL \
                          -width $_labelWidth -text "Content Type:" -anchor w]
        pack $contentTypeL -side left
        set contentTypeE [ttk::entry $contentTypeF.contentTypeE]
        pack $contentTypeE -side left -fill x -expand yes
        set contentTypeB [ttk::button $contentTypeF.contentTypeB \
                          -text "Get Type" \
                          -command [mytypemethod _GetType]]
        pack $contentTypeB -side right
    }
    typemethod _Attach {} {
        $dialog withdraw
        return [$dialog enddialog [list "[$contentTypeE get]" \
                                           "[$descrE get]" \
                                           "[$encodingCB get]" \
                                           "[$filenameE get]"]]
    }
    typemethod _Cancel {} {
        $dialog withdraw
        return [$dialog enddialog {}]
    }
    typemethod _BrowseFile {} {
        set oldfile [$filenameE get]
        set olddir  [file dirname $oldfile]
        set newfile [tk_getOpenFile -initialdir $olddir \
                     -initialfile  $oldfile \
                     -parent $dialog \
                     -title "Name of file to attach"]
        if {$newfile ne ""} {
            $filenameE delete 0 end
            $filenameE insert end "$newfile"
        }
    }
    typemethod _GetType {} {
        set file "[$filenameE get]"
        set ctype [exec [auto_execok file] -ib "$file"]
        $contentTypeE delete 0 end
        $contentTypeE insert end "$ctype"
        if {[regexp {^text/} "$ctype"] > 0} {
            $encodingCB set 7bit
        } else {
            $encodingCB set base64
        }
    }
    typemethod draw {args} {
        set parent [from args -parent .]
        $dialog configure -parent $parent
        wm transient [winfo toplevel $dialog] $parent
        return [$dialog draw]
    }
}

snit::widgetadaptor SelectIdentityDialog {
    typeconstructor {
        ttk::style configure SelectIdentityDialog \
              ;
        bind SelectIdentityDialog <<ThemeChanged>> \
              [mytypemethod ThemeChanged %W]
    }
    typemethod ThemeChanged {W} {
        $W _ThemeChanged
    }
    method _ThemeChanged {} {
    }
    option -style -default SelectIdentityDialog
    option -identities -default {} -type snit::listtype
    option -fallbackid -default {} -type snit::listtype
    delegate option -title to hull
    delegate option -parent to hull
    delegate option -geometry to hull
    component idlistsw
    component   idlist
    constructor {args} {
        installhull using Dialog \
              -class SelectIdentityDialog -bitmap questhead \
              -default ok -cancel cancel -modal local -transient yes \
              -side bottom -title "Select an Identity"
        $hull add ok -text OK -command [mymethod _OK]
        $hull add cancel -text Cancel -command [mymethod _Cancel]
        wm protocol $win WM_DELETE_WINDOW [mymethod _Cancel]
        set frame [$hull getframe]
        install idlistsw using ScrolledWindow $frame.idlistsw -scrollbar both \
              -auto both
        pack $idlistsw -expand yes -fill both
        install idlist using ttk::treeview [$idlistsw getframe].idlist \
              -columns {from organization} \
              -displaycolumns {from organization} \
              -selectmode browse \
              -show headings
        $idlist column from -anchor w -minwidth 100
        $idlist column organization -anchor w -minwidth 300 -stretch yes
        $idlist heading from -text "From" -anchor w
        $idlist heading organization -text "Organization" -anchor w
        $idlistsw setwidget $idlist
        $self configurelist $args
    }
    method draw {args} {
        $self configurelist $args
        $idlist delete [$idlist children {}]
        foreach id $options(-identities) {
            $idlist insert {} end -values $id
        }
        return [$hull draw]
    }
    method _OK {} {
        set selected [lindex [$idlist selection] 0]
        $hull withdraw
        if {$selected eq {}} {
            return [$hull enddialog $options(-fallbackid)]
        } else {
            return [$hull enddialog [$idlist item $selected -values]]
        }
    }
    method _Cancel {} {
        $hull withdraw
        return [$hull enddialog $options(-fallbackid)]
    }              
}


package provide SpoolFunctions 1.0


