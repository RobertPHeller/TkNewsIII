#* 
#* ------------------------------------------------------------------
#* GroupFunctions.tcl - Group functions
#* Created by Robert Heller on Sat May 27 15:58:33 2006
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
package require CommonFunctions
#package require SpoolFunctions
package require ArticleFunctions
package require ScrollWindow
package require ButtonBox
package require Dialog

namespace eval Common {#dummy}

snit::type group {
    typevariable HeadListProg
    typeconstructor {
        global execbindir
        set HeadListProg [auto_execok [file join $execbindir headList]]
                bind $type <Motion>                [mytypemethod _Motion %W %x %y]
    }

    option -first -type snit::integer -default 1
    option -last  -type snit::integer -default 0
    option -postable -type snit::boolean -default yes
    option -subscribed -type snit::boolean -default no
    option -name -readonly yes
    option -spool -readonly yes -validatemethod _CheckSpool
    method _CheckSpool {option value} {
        if {[catch [list $value info type] thetype]} {
            error "Expected a SpoolWindow for $option, but got $value ($thetype)"
        } elseif {"$thetype" ne "::SpoolWindow"} {
            error "Expected a ::SpoolWindow for $option, but got a $thetype ($value)"
        } else {
            return $value
        }
    }
    variable ranges
    method setranges {rangelist} {
        foreach r $rangelist {
            if {[regexp {^[0-9]+-[0-9]+$} "$r"] > 0} {continue}
            if {[string is integer -strict "$r"]} {continue}
            error "Bad range in range list: $r"
        }
        set ranges $rangelist
    }
    method getranges {} {return $ranges}
    method groupComputeUnread {} {
        set s $options(-first)
        set e $options(-last)
        if {$s == 0} {set s 1}
        set result [expr $e - $s + 1]
        foreach range $ranges {
            if {[string first "-" $range] != -1} {
                set ltmp [split $range "-"]
                set first [lindex $ltmp 0] 
                set last [lindex $ltmp 1]
            } else {
                set first $range
                set last $range 
            }
            if {$first < $s} {
                set rs $s
            } else {
                set rs $first
            }
            if {$last > $e} {
                set re $e
            } else {
                set re $last
            }
            set ru [expr $re - $rs + 1]
            if {$ru > 0} {incr result [expr - $ru]}
        }
        if {$result < 0} {set result 0}
        return $result
    }
    constructor {args} {
        $self configurelist $args
        set ranges {}
    }
    method insertArticleListFromNNTP {articleList spool {pattern "."} 
        {unreadp "0"}} {
        set firstMessage $options(-first)
        set lastMessage  $options(-last)
        set numMessages [expr double($lastMessage - $firstMessage + 1)]
        $spool setstatus "Geting Headers from server"
        $spool setprogress 0
        update
        set imsg 0
        set unreadFlag {}
        if {$unreadp} {
            set unreadFlag {U }
        }
        set nextload $options(-first)
        foreach range $ranges {
            if {[string first "-" $range] != -1} {
                set ltmp [split $range "-"]
                set first [lindex $ltmp 0] 
                set last [lindex $ltmp 1]  
            } else {
                set first $range
                set last $range 
            }
            if {$first < $options(-first)} {
                set first $options(-first)
            }
            if {$last > $options(-last)} {
                set last $options(-last)
            }
            if {$first > $last} {
                continue
            }
            while {$nextload < $first} {
                if {[$spool NNTP_LoadArticleHead $options(-name) $nextload \
                     $articleList  "$pattern" "$unreadFlag"]} {
                    incr imsg
                    if {$imsg == 10} {
                        set mnum [expr $nextload - 1]
                        set mnum [expr double($mnum - $firstMessage)]
                        $spool setprogress [expr int(($mnum / $numMessages) * 100)]
                        update
                        set imsg 0
                    }
                }
                incr nextload
            }
            if {$unreadp} {
                while {$nextload <= $last} {
                    if {[$spool NNTP_LoadArticleHead $options(-name) $nextload $articleList  "$pattern" {R }]} {
                        incr imsg
                        if {$imsg == 10} {
                            set mnum [expr $nextload - 1]
                            set mnum [expr double($mnum - $firstMessage)]
                            $spool setprogress [expr int(($mnum / $numMessages) * 100)]
                            $spool setstatus "Geting Headers from server $mnum / $numMessages"
                            update
                            set imsg 0
                        }
                    }
                    incr nextload
                }
            } else {
                set nextload [expr $last + 1]
            }
            if {$imsg == 10} {
                set mnum [expr $nextload - 1]
                set mnum [expr double($mnum - $firstMessage)]
                $spool setprogress [expr int(($mnum / $numMessages) * 100)]
                $spool setstatus "Geting Headers from server $mnum / $numMessages"
                update
                set imsg 0
            }
        }
        while {$nextload <= $options(-last)} {
            if {[$spool NNTP_LoadArticleHead $options(-name) $nextload $articleList  "$pattern" "$unreadFlag"]} {
                incr imsg
                if {$imsg == 10} {
                    set mnum [expr $nextload - 1]
                    set mnum [expr double($mnum - $firstMessage)]
                    $spool setprogress [expr int(($mnum / $numMessages) * 100)]
                    $spool setstatus "Geting Headers from server $mnum / $numMessages"
                    update
                    set imsg 0
                }
            }
            incr nextload
        }
        $spool setprogress 100
        $spool setstatus "Geting Headers from server $numMessages messages"
    }
    method insertArticleListFromSpoolDir {articleList spool {pattern "."} 
        {unreadp "0"}} {
        set firstMessage $options(-first)
        set lastMessage  $options(-last)
        set numMessages [expr double($lastMessage - $firstMessage + 1)]
        set spoolDirectory [$spool cget -spooldirectory]
        set groupPath [GroupName Path $options(-name)]
        #      puts stderr "*** ${type}::insertArticleListFromSpoolDir: firstMessage = $firstMessage, lastMessage = $lastMessage"
        #      puts stderr "*** ${type}::insertArticleListFromSpoolDir: numMessages = $numMessages, spoolDirectory = $spoolDirectory"
        #      puts stderr "*** ${type}::insertArticleListFromSpoolDir: groupPath = $groupPath"
        set command [join [concat $HeadListProg $spoolDirectory $groupPath "$pattern" $unreadp $firstMessage $lastMessage $ranges] { }]
        #      puts stderr "*** ${type}::insertArticleListFromSpoolDir: command = $command"
        set pipeCmd "|$command"
        if {[catch [list open "$pipeCmd" r] pipe]} {
            error "pipe failed: $pipeCmd: $pipe"
            return
        }
        if {$numMessages > 100} {
            $spool setstatus "Geting Headers"
            $spool setprogress 0
            update
            set imsg 0
            while {[gets $pipe line] != -1} {
                #	  puts stderr "*** ${type}::insertArticleListFromSpoolDir: line = '$line'"
                scan "$line" {%6d } artNumber
                #	  puts stderr "*** ${type}::insertArticleListFromSpoolDir: artNumber = $artNumber"
                eval [list $articleList insertArticleHeader] $line
                incr imsg
                if {$imsg == 10} {
                    set line [string trim "$line"]
                    set mnum [lindex [split "$line" { }] 0]
                    set mnum [expr double($mnum - $firstMessage)]
                    $spool setprogress\
                          [expr int(($mnum / $numMessages) * 100)]
                    $spool setstatus "Geting Headers $mnum / $numMessages"
                    update
                    set imsg 0
                }
            }
            $spool setprogress 100
            $spool setstatus "Geting Headers $numMessages messages"
        } else {
            while {[gets $pipe line] != -1} {
                scan "$line" {%6d } artNumber
                $articleList insert end $artNumber -text "$line" -data $artNumber
            }
        }
        close $pipe
    }
    method findNextArticle {a {unread 1}} {
        incr a
        while {$a <= $options(-last)} {
            set range [$self findRange $a 0]
            if {$range == {}} {
                if {[$self articleExists $a]} {
                    return $a
                } else {
                    $self findRange $a 1
                    incr a
                    continue
                }
            }
            if {[string first "-" $range] != -1} {  
                set ltmp [split $range "-"]
                set first [lindex $ltmp 0]
                set last [lindex $ltmp 1]
            } else {
                set first $range 
                set last $range
            }
            set a [expr $last + 1]
        }
        return -1
    }
    method findPreviousArticle {a {unread 1}} {
        incr a -1
        while {$a >= $options(-first)} {
            set range [$self findRange $a 0]
            if {$range == {}} {
                if {[$self articleExists $a]} {
                    return $a
                } else {
                    $self findRange $a 1
                    incr a -1
                    continue
                }
            }
            if {[string first "-" $range] != -1} {  
                set ltmp [split $range "-"]
                set first [lindex $ltmp 0]
                set last [lindex $ltmp 1]
            } else {
                set first $range 
                set last $range
            }
            set a [expr $first - 1]
        }
        return -1
    }
    method findRange {a createP} {
        set nranges [llength $ranges]
        for {set r 0} {$r < $nranges} {incr r} {
            set range [lindex $ranges $r]
            if {[string first "-" $range] != -1} {  
                set ltmp [split $range "-"]
                set first [lindex $ltmp 0]
                set last [lindex $ltmp 1]
            } else {
                set first $range 
                set last $range
            }
            if {$a >= $first && $a <= $last} {
                return $range
            } elseif {$a < $first} {
                if {$createP} {
                    if {$r == 0} {
                        if {$a == [expr $first - 1]} {
                            set range "$a-$last"
                            set ranges [lreplace $ranges $r $r $range]
                            return $range
                        } else {
                            set nrange $a
                            set ranges [lreplace $ranges $r $r $nrange $range]
                            return $nrange
                        }
                    } else {
                        set p [expr $r - 1]
                        set prange [lindex $ranges $p]
                        if {[string first "-" $prange] != -1} {
                            set ltmp [split $prange "-"]
                            set pfirst [lindex $ltmp 0]
                            set plast [lindex $ltmp 1]
                        } else {
                            set pfirst $prange
                            set plast  $prange
                        }
                        if {[expr $plast + 1] == $a && $a == [expr $first - 1]} {
                            set range $pfirst-$last
                            set ranges [lreplace $ranges $p $r $range]
                            return $range
                        } elseif {$a == [expr $first - 1]} {
                            set range "$a-$last"
                            set ranges [lreplace $ranges $r $r $range]
                            return $range
                        } elseif {[expr $plast + 1] == $a} {
                            set prange $pfirst-$a
                            set ranges [lreplace $ranges $p $p $prange]
                            return $prange
                        } else {
                            set nrange $a
                            set ranges [lreplace $ranges $r $r $nrange $range]
                            return $nrange
                        }
                    }
                } else {
                    return {}
                }
            }
        }
        if {$createP} {
            if {$nranges == 0} {
                set range $a
                set ranges [list $range]
                return $range
            } else {
                incr r -1
                set range [lindex $ranges $r]
                if {[string first "-" $range] != -1} {  
                    set ltmp [split $range "-"]
                    set first [lindex $ltmp 0]
                    set last [lindex $ltmp 1]
                } else {
                    set first $range 
                    set last $range
                }
                if {[expr $last + 1] == $a} {
                    set range $first-$a
                    set ranges [lreplace $ranges $r $r $range]
                    return $range
                } else {
                    set range $a
                    lappend ranges $range
                    return $range
                }
            }
        } else {
            return {}
        }
    }
    method articleExists {a} {
        if {[$options(-spool) cget -useserver]} {
            if {[$options(-spool) srv_cmd "group $options(-name)" buff] < 0} {
                error "$self articleExists (NNTP): Error sending group command"
                return 0
            }
            if {[string first {411} "$buff"] == 0} {return 0}
            if {[string first {211} "$buff"] != 0} {
                error "$self articleExists (NNTP): Unexpected GROUP command result: $buff"
                return 0
            }
            if {[$options(-spool) srv_cmd "stat $a" buff] < 0} {
                error "$self articleExists (NNTP): Error sending stat command"
                return 0
            }
            return [expr [string first {223} "$buff"] == 0]
        } else {
            set spoolDirectory [$options(-spool) cget -spooldirectory]
            set filename [file join "$spoolDirectory" [GroupName Path $options(-name)] $a]
            if {![file exists $filename]} {return 0}
            if {![file readable $filename]} {return 0}
            return 1
        }
    }
    method setAllRead {} {
        set ranges [list "$options(-first)-$options(-last)"]
    }
    method cleanGroup {} {
        set spoolDirectory [$options(-spool) cget -spooldirectory]
        set groupFiles [file join "$spoolDirectory" [GroupName Path $options(-name)] *]
        catch {eval [list file delete -force] [glob -nocomplain $groupFiles]}
        $self configure -first 0 -last 0
        set ranges {}
    }
}

snit::widget GroupTreeFrame {
    hulltype tk::frame
    component groupTreeSW
    component   groupTree
    component groupLabelFrame
    component   groupNameLabel
    component   groupButtonBox
    delegate method {groupButtonBox *} to groupButtonBox
    delegate option -grouplabel to groupNameLabel as -text
    typevariable groupButtons -array {
        unread {-text "Unread\nGroup" -state {disabled} \
                  -command "[mymethod _UnreadGroup]"}
        read {-text "Read\nGroup"  -state {disabled}  \
                                -command "[mymethod _ReadAGroup]"}
        close {-text "Close\nGroup"  -state {disabled}  \
                  -command "[mymethod _CloseGroup]"}
        catchup {-text "Catch Up\nGroup"  -state {disabled}  \
                  -command "[mymethod _CatchUpGroup]"}
        unsubscribe {-text "Unsubscribe\nGroup"  \
                  -state {disabled}  \
                  -command "[mymethod _UnSubscribeGroup]"}
        groupdir {-text "Directory of\nall groups"  \
                  -command "[mymethod _DirectoryOfGroups]"}
        refresh {-text "Refresh\nGroup List"  \
                  -command "[mymethod _RefreshGroupList]"}
    }
    method _UnreadGroup {} {
        $options(-spool) _UnreadGroup
    }
    method _ReadAGroup {} {
        $options(-spool) _ReadAGroup
    }
    method _CloseGroup {} {
        $options(-spool) _CloseGroup
    }
    method _CatchUpGroup {} {
        $options(-spool) _CatchUpGroup
    }
    method _UnSubscribeGroup {} {
        $options(-spool) _UnSubscribeGroup
    }
    method _DirectoryOfGroups {} {
        $type DirectoryOfAllGroupsDialog draw -parent [winfo toplevel $win] \
              -grouptree $self \
              -subscribecallback "$options(-spool) _SubscribeToGroup"
    }
    method _RefreshGroupList {} {
        $self reloadActiveFile
        $options(-spool) _LoadGroupTree {.} 0 Brief
    }
    method _EnableGroupButtons {x y} {
        lassign [$groupTree identify $x $y] what selection detail
        if {[string length "$selection"] == 0} {return}
        #puts stderr "*** ${type}::_EnableGroupButtons: selection = $selection"
        $options(-spool) setSelectedGroup $selection
        #puts stderr "*** ${type}::_EnableGroupButtons: selectedGroup = $selectedGroup"
        #puts stderr "*** ${type}::_EnableGroupButtons: currentGroup = $currentGroup"
        $options(-spool) setmenustate file:read normal
        $groupButtonBox itemconfigure read  -state normal
        bind $options(-spool) <Control-r> "$options(-spool) _ReadAGroup"
    }
    method _ReadGroup {x y} {
        lassign [$groupTree identify $x $y] what selection detail
        #puts stderr "*** ${type}::_ReadGroup: selection = $selection"
        $options(-spool) setSelectedGroup $selection
        #puts stderr "*** ${type}::_ReadGroup:  selectedGroup = $selectedGroup"
        $options(-spool) setmenustate file:read normal
        $groupButtonBox itemconfigure read -state normal
        $groupButtonBox itemconfigure unread -state normal
        $groupButtonBox itemconfigure close -state normal
        $groupButtonBox itemconfigure catchup -state normal
        $groupButtonBox itemconfigure unsubscribe -state normal
        bind $options(-spool) <Control-r> "$options(-spool) _ReadAGroup"
        $options(-spool) _ReadAGroup
    }
    typevariable groupButtonsList {unread read close catchup unsubscribe 
        groupdir refresh}
    
    typevariable columnheadings -array {
        #0,stretch yes
        #0,text Name
        #0,anchor w
        #0,width 100
        range,stretch yes
        range,text Messages
        range,anchor w
        range,width 75
        unread,stretch no
        unread,text Unread
        unread,anchor e
        unread,width 75
    }
    typevariable columns {range unread}
    typevariable HeadListProg
    typeconstructor {
        global execbindir
        set HeadListProg [auto_execok [file join $execbindir headList]]
    }
    delegate option -height to groupTree
    delegate option -takefocus to groupTree
    delegate method selection to groupTree
    ###
    option -spool -readonly yes -validatemethod _CheckSpool
    option -method -readonly yes -type {snit::enum -values {NNTP File}} -default File
    variable groups -array {}
    variable activeGroupList {}
    method _CheckSpool {option value} {
        if {[catch [list $value info type] thetype]} {
            error "Expected a ::SpoolWindow for $option, but got $value ($thetype)"
        } elseif {"$thetype" ne "::SpoolWindow"} {
            error "Expected a ::SpoolWindow for $option, but got a $thetype ($value)"
        } else {
            return $value
        }
    }
    constructor {args} {
        install groupTreeSW using ScrolledWindow $win.groupTreeSW \
              -scrollbar vertical -auto vertical
        pack $groupTreeSW -fill both -expand yes 
        install groupTree using ttk::treeview \
              [$groupTreeSW getframe].groupTree \
              -columns $columns \
              -displaycolumns $columns -show {tree headings}
        $groupTree tag bind groupitem <ButtonPress-1> [mymethod _EnableGroupButtons %x %y]
        $groupTree tag bind groupitem <Double-ButtonPress-1> [mymethod _ReadGroup %x %y]
        $groupTreeSW setwidget $groupTree
        install groupLabelFrame using ttk::labelframe $win.groupLabelFrame
        pack $groupLabelFrame -fill x
        install groupNameLabel using ttk::label $groupLabelFrame.groupNameLabel
        $groupLabelFrame configure -labelwidget $groupNameLabel -labelanchor n
        # Group buttons
        install groupButtonBox using ButtonBox $groupLabelFrame.groupButtonBox
        pack $groupButtonBox -fill x
        foreach b $groupButtonsList {
            eval [list $groupButtonBox add ttk::button $b] [subst $groupButtons($b)]
        }
        $self configurelist $args
        #parray columnheadings
        set cols [concat #0 $columns]
        foreach c $cols {
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
                eval [list $groupTree column $c] $copts
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
                eval [list $groupTree heading $c] $hopts
            }
        }
        if {![info exists options(-spool)]} {
            error "The -spool option is a required option!"
        }
        switch -exact -- "$options(-method)" {
            File {$self _ReadActiveFile [$options(-spool) cget -activefile]}
            NNTP {$self _NNTP_GetActiveFile}
        }
        bind $win <Configure> [mymethod _ConfigureHeight %h]
    }
    proc _heightOfChildren {w} {
        set sum 0
        foreach c [winfo children $w] {
            incr sum [winfo height $c]
        }
        return $sum
    }
    proc _reqheightOfChildren {w} {
        set sum 0
        foreach c [winfo children $w] {
            incr sum [winfo reqheight $c]
        }
        return $sum
    }
    
    method _ConfigureHeight {newheight} {
        #puts stderr "*** $self _ConfigureHeight $newheight"
        set cheight [_heightOfChildren $win]
        #puts stderr "*** $self _ConfigureHeight: cheight is $cheight"
        set reqcheight [_reqheightOfChildren $win]
        #puts stderr "*** $self _ConfigureHeight: reqcheight = $reqcheight"
        if {$cheight < $reqcheight} {
            set diff [expr {$reqcheight - $cheight}]
            #puts stderr "*** $self _ConfigureHeight: diff = $diff"
            set headheight [font metrics [ttk::style lookup Heading -font] \
                            -displayof $win -linespace]
            #puts stderr "*** $self _ConfigureHeight: headheight = $headheight"
            set rowheight [font metrics [ttk::style lookup Treeview -font]  \
                           -displayof $win -linespace]
            #puts stderr "*** $self _ConfigureHeight: rowheight = $rowheight"
            set rows [$groupTree cget -height]
            #puts stderr "*** $self _ConfigureHeight: rows = $rows"
            set totalheight [expr {$headheight + ($rowheight * $rows)}]
            #puts stderr "*** $self _ConfigureHeight: totalheight = $totalheight"
            set rdiff [expr {int(ceil(double($diff) / double($rowheight)))}]
            #puts stderr "*** $self _ConfigureHeight: rdiff = $rdiff"
            set newrows [expr {$rows - $rdiff}]
            #puts stderr "*** $self _ConfigureHeight: newrows = $newrows"
            if {$newrows >= 0} {
                $groupTree configure -height $newrows
            }
        }        
    }
    method reloadActiveFile {} {
        switch -exact -- "$options(-method)" {
            File {$self _ReadActiveFile [$options(-spool) cget -activefile]}
            NNTP {$self _NNTP_GetActiveFile}
        }
    }
    destructor {
        if {[info exists activeGroupList]} {
            foreach g $activeGroupList {
                catch {$groups($g) destroy} message
                #	  puts stderr "*** ${type}::destructor: $groups($g) destroy done: $message"
            }
        }
        catch {array unset groups}
    }
    method _ReadActiveFile {activefile} {
        set File [open $activefile r]
        while {[gets $File line] != -1} {
            set line "[string trim $line]"
            if {[string equal $line ""]} {continue}
            set list [split $line " "]
            if {[string first "=" [lindex $list 3]] != -1} {
                continue
            }
            set name "[lindex $list 0]"
            set xlast "[string trimleft [lindex $list 1] {0}]"
            if {$xlast == {}} {
                set last 0
            } else {
                set last [expr int($xlast)]
            }
            set xfirst "[string trimleft [lindex $list 2] {0}]"
            if {$xfirst == {}} {
                set first 0
            } else {
                set first [expr int($xfirst)]
            }
            if {"[lindex $list 3]" == "y"} {
                set postable 1
            } else {
                set postable 0
            }
            if {[catch "set groups($name)" oldgroup]} {
                set groups($name) [group create \
                                   "[$options(-spool) cget -spoolname]_$name" \
                                   -first $first \
                                   -last $last \
                                   -postable $postable \
                                   -name $name -spool $options(-spool)]
                lappend activeGroupList $name
            } else {
                $oldgroup configure -first $first -last $last -postable $postable
            }
        }
        close $File
    }
    method _NNTP_GetActiveFile {} {
        if {[$options(-spool) srv_cmd list buff] < 0} {
            error "${self}:_NNTP_GetActiveFile: Error sending list command"
            return -1
        }
        if {[string first {215} "$buff"] != 0} {
            error "${self}:_NNTP_GetActiveFile: Unexpected LIST command result: $buff"
            return -1
        }
        while {[$options(-spool) srv_recv line] != -1} {
            set line "[string trim $line]"
            if {[string compare "$line" {.}] == 0} {break}
            if {[string equal $line ""]} {continue}
            set list [split $line " "]
            if {[string first "=" [lindex $list 3]] != -1} {
                continue
            }
            set name "[lindex $list 0]"
            set xlast "[string trimleft [lindex $list 1] {0}]"
            if {$xlast == {}} {
                set last 0
            } else {
                set last [expr int($xlast)]
            }
            set xfirst "[string trimleft [lindex $list 2] {0}]"
            if {$xfirst == {}} {
                set first 0
            } else {
                set first [expr int($xfirst)]
            }
            if {"[lindex $list 3]" == "y"} {
                set postable 1
            } else {
                set postable 0
            }
            if {[catch "set groups($name)" oldgroup]} {
                set groups($name) [group create \
                                   "[$options(-spool) cget -spoolname]_$name" \
                                   -first $first \
                                   -last $last \
                                   -postable $postable \
                                   -name $name -spool $options(-spool)]
                lappend activeGroupList $name
            } else {
                $oldgroup configure -first $first -last $last -postable $postable
            }
        }
    }
    method isActiveGroup {groupname} {
        return [expr [lsearch -exact $activeGroupList $groupname] != -1]
    }
    method activeGroups {} {
        return $activeGroupList
    }
    method groupcget {groupname option} {
        return [$groups($groupname) cget $option]
    }
    method groupconfigure {groupname args} {
        return [$groups($groupname) configurelist $args]
    }
    method groupsetranges {groupname rangelist} {
        return [$groups($groupname) setranges $rangelist]
    }
    method groupgetranges {groupname} {
        return [$groups($groupname) getranges]
    }
    method articleExists {groupname artNumber} {
        return [$groups($groupname) articleExists $artNumber]
    }
    method groupComputeUnread {groupname} {
        return [$groups($groupname) groupComputeUnread]
    }
    method loadGroupTree {pattern unsubscribedP format {savedP 1}} {
        $groupTree delete [$groupTree children {}]
        set activeGroups [$self activeGroups]
        set savedSpoolDirectory [$options(-spool) cget -savednews]
        if {[string equal "$pattern" {}]} {return}
        foreach name $activeGroups {
            if {[regexp -nocase -- "$pattern" $name]} {
                if {$unsubscribedP || [$self groupcget $name -subscribed]} {
                    $groupTree insert {} end \
                          -id $name \
                          -text $name \
                          -values [$self formRealGroupValues $name] \
                          -tags groupitem -open no
                    if {$savedP} {
                        set thisGroupSaved \
                              "$savedSpoolDirectory/[GroupName Path $name]"
                        foreach sg [lsort -dictionary [glob -nocomplain "$thisGroupSaved/*"]] {
                            $self _LoadSavedMessagesList $name $sg 
                        }
                    }
                }
            }
        }
    }
    method formRealGroupValues {name} {
        return [list [format {%6d-%-6d} \
                      [$self groupcget $name -first] \
                      [$self groupcget $name -last] \
                      ] [$self groupComputeUnread $name]]
    }
    method formatRealGroupLine {group {format {Brief}}} {
        set u [$self groupComputeUnread $group]
        if {$format == {Brief}} {
            set line [format {%-40s %6d-%-6d, unread: %4d}  \
                      $group \
                      [$self groupcget $group -first] \
                      [$self groupcget $group -last] $u]
        } else {
            set subFlag { }
            set postFlag { }
            if {[$self groupcget $group -subscribed]} {set subFlag {S}}
            if {[$self groupcget $group -postable]} {set postFlag {P}}
            set line [format {%-40s %s%s %6d-%-6d, unread: %4d}  \
                      $group $subFlag $postFlag  \
                      [$self groupcget $group -first]\
                      [$self groupcget $group -last] $u]
        }
        return "$line"
    }
    method addSavedGroupLineInTree {tree parent group} {
        if {[catch "$options(-spool) savedDirectory $group" mdir] == 0} {
            #set font [option get $tree font Font]
            set line [$self formatSavedGroupLine $group]
            $tree insert end $parent $group -data $group -text "$line" \
                  -font "$font"
        }
    }
    method updateGroupLineInTree {group {format {Brief}}} {
        if {![$groupTree exists $group]} {return}
        if {[catch "$options(-spool) savedDirectory $group" mdir] == 0} {
            $groupTree item $group -values [$self formSavedGroupValues $group]
        } else {
            $groupTree item $group -values \
                  [$self formRealGroupValues $group]
        }
    }
    method catchUpGroup {artList group} {
        $groups($group) setAllRead
        $self updateGroupLineInTree $group
        $artList deleteall
        $self insertArticleList $artList $group
    }
    method cleanGroup {groupTree artList group} {
        $groups($group) cleanGroup
        $self updateGroupLineInTree $groupTree $group
        if {![string equal "$artList" {}]} {
            $artList deleteall
            $self insertArticleList $artList $group
        }
        if {[string equal "$options(-method)" File]} {
            set activeFile "[$options(-spool) cget -activefile]"
            if {[file writable "$activeFile"]} {
                set newActiveFile "${activeFile}.new"
                set inFile [open $activeFile "r"]
                set outFile [open $newActiveFile "w"]
                while {[gets $inFile line] != -1} {
                    set list [split $line " "]
                    if {[lindex $list 0] == $group} {
                        puts $outFile "$group 0000000000 00001 y"
                    } else {
                        puts  $outFile "$line"
                    }
                }
                close $inFile
                close $outFile
                catch "file rename -force $activeFile $activeFile~"
                catch "file rename -force $newActiveFile $activeFile"
            }
        }
    }
    method findNextArticle {group a {unread 1}} {
        if {[catch "$options(-spool) savedDirectory $group" mdir] == 0} {
            incr a
            set lastMessage [MessageList Highestnumber [glob -nocomplain "$mdir/*"]]
            while {$a <= $lastMessage} {
                if {[file exists "$mdir/$a"] &&
                    [file readable "$mdir/$a"]} {return $a}
                incr a
            }
            return -1
        } else {
            return [$groups($group) findNextArticle $a $unread]
        }
    }
    method findPreviousArticle {group a {unread 1}} {
        if {[catch "$options(-spool) savedDirectory $group" mdir] == 0} {
            incr a -1
            set firstMessage [MessageList Lowestnumber [glob -nocomplain "$mdir/*"]]
            while {$a >= $firstMessage} {
                if {[file exists "$mdir/$a"] &&
                    [file readable "$mdir/$a"]} {return $a}
                incr a -1
            }
            return -1
        } else {
            return [$groups($group) findPreviousArticle $a $unread]
        }
    }
    method findRange {group a createP} {
        if {[catch "$options(-spool) savedDirectory $group" mdir] == 0} {
            return {}
        } else {
            return [$groups($group) findRange $a $createP]
        }
    }
    method _LoadSavedMessagesList {name sg} {
        #set font [option get $tree font Font]
        #      puts stderr "*** ${type}::_LoadSavedMessagesList: font = $font"
        if {[file exists "$sg"] == 1 && [file isdirectory "$sg"] == 1} {
            #	puts stderr "*** ${type}::_LoadSavedMessagesList: sg = $sg"
            regsub "[$options(-spool) cget -savednews]/" "$sg" {} subfoldname
            regsub -all {/} "$subfoldname" {.} subfoldname
            $options(-spool) addSavedDirectory $subfoldname $sg
            set mlist [lsort -dictionary [glob -nocomplain "$sg/*"]]
            set mcount [MessageList CountMessages $mlist]
            $groupTree insert $name end \
                  -id $subfoldname \
                  -text $subfoldname \
                  -values [list {} $mcount] \
                  -open no -tags groupitem
            foreach m $mlist {
                $self _LoadSavedMessagesList $subfoldname $m
            }
        }
    }
    method formSavedGroupValues {name} {
        set mdir [$options(-spool) savedDirectory $name]
        set subname [file tail $mdir]
        set mcount [MessageList CountMessages [glob -nocomplain "$mdir/*"]]
        return [list {} $mcount]
    }
    method formatSavedGroupLine {name} {
        set mdir [$options(-spool) savedDirectory $name]
        set subname [file tail $mdir]
        set mcount [MessageList CountMessages [glob -nocomplain "$mdir/*"]]
        return "[format {%-40s %d saved messages} $subname $mcount]"
    }
    method insertArticleList {articleList group {pattern "."} {unreadp "0"}} {
        if {[catch {$options(-spool) savedDirectory $group} mdir] == 0} {
            #	puts stderr "*** ${type}::insertArticleList: group = $group, mdir = $mdir"
            $self insertArticleListAllDir $articleList $mdir $pattern $unreadp
            return
        } elseif {[$options(-spool) cget -useserver]} {
            $groups($group) insertArticleListFromNNTP $articleList $options(-spool) \
                  $pattern $unreadp
        } else {
            $groups($group) insertArticleListFromSpoolDir $articleList \
                  $options(-spool) $pattern $unreadp
        }
        #$articleList see [$articleList items 0]
    }
    method unSubscribeGroup {group} {
        $groups($group) configure -subscribed no
        $groupTree delete $group
    }
    method subscribeGroup {tree group {savedP 1}} {
        #set font [option get $tree font Font]
        $groups($group) configure -subscribed yes
        set line [$self formatRealGroupLine $group Brief]
        $tree insert end root $group -data $group -text "$line" -font $font
        if {$savedP} {
            set savedSpoolDirectory "[$options(-spool) cget -savednews]"
            set thisGroupSaved "$savedSpoolDirectory/[GroupName Path $group]"
            foreach sg [lsort -dictionary [glob -nocomplain "$thisGroupSaved/*"]] {
                $self _LoadSavedMessagesList $tree $group $sg 
            }
        }
    }
    method insertArticleListAllDir {articleList mdir {pattern "."} 
        {unreadp "0"}} {
        #      puts stderr "*** ${type}::insertArticleListAllDir: mdir = $mdir"
        set mlist [glob -nocomplain [file join "$mdir" *]]
        #      puts stderr "*** ${type}::insertArticleListAllDir: mlist = $mlist"
        set numMessages [MessageList CountMessages $mlist]
        #      puts stderr "*** ${type}::insertArticleListAllDir: numMessages = $numMessages"
        if {$numMessages == 0} {return}
        set a [file dirname "$mdir"]
        set b [file tail    "$mdir"]
        set firstMessage [MessageList Lowestnumber $mlist]
        set lastMessage  [MessageList Highestnumber $mlist]
        #      puts stderr "*** ${type}::insertArticleListAllDir: firstMessage = $firstMessage, lastMessage = $lastMessage"
        set command [list $HeadListProg $a $b "$pattern" $unreadp $firstMessage $lastMessage]
        set pipeCmd "|$command"
        if {[catch [list open "$pipeCmd" r] pipe]} {
            error "pipe failed: $pipeCmd: $pipe"
            return
        }
        #      set font [option get $articleList font Font]
        #      puts stderr "*** ${type}::insertArticleListAllDir: articleList = $articleList (Class is [winfo class $articleList]), font = $font"
        #      set font fixed
        #      puts stderr "*** ${type}::insertArticleListAllDir: articleList = $articleList, font = $font"
        if {$numMessages > 100} {
            $options(-spool) setstatus "Geting Headers"
            $options(-spool) setprogress 0
            update
            set imsg 0
            set done 0
            while {[gets $pipe line] != -1} {
                eval [list $articleList insertArticleHeader] $line
                incr imsg
                if {$imsg == 10} {
                    incr done 10
                    $options(-spool) setprogress \
                          [expr int (100*(double($done)/double($numMessages)))]
                    $options(-spool) setstatus "Geting Headers $done / $numMessages"
                    update
                    set imsg 0
                }
            }
            $options(-spool) setprogress 100
            $options(-spool) setstatus "Geting Headers $numMessages messages"
        } else {
            set index 1
            while {[gets $pipe line] != -1} {
                eval [list $articleList insertArticleHeader] $line
                incr index
            }
        }
        close $pipe
        return 
    }
}


        

snit::type NewsList {
    option -file -readonly yes -validatemethod _CheckRWFile -default ~/.newsrc
    method _CheckRWFile {option value} {
        if {[file exists "$value"] && 
            [file readable "$value"] && 
            [file writable "$value"]} {
            return "$value"
        } else {
            error "Expected a read/writeable file for $option, but got $value"
        }
    }
    option -grouptree -validatemethod _CheckGroupTreeFrame
    method _CheckGroupTreeFrame {option value} {
        if {[catch [list $value info type] thetype]} {
            error "Expected a ::GroupTreeFrame for $option, but got $value"
        } elseif {![string equal "$thetype" ::GroupTreeFrame]} {
            error "Expected a ::GroupTreeFrame for $option, but got a $thetype ($value)"
        } else {
            return $value
        }
    }
    constructor {args} {
        $self configurelist $args
        if {![info exists options(-grouptree)]} {
            error "${type}::constructorThe -grouptree option is required!"
        }
        set File [open $options(-file) r]
        while {[gets $File line] != -1} {
            set splitC {:}
            set subscribed 1
            if {[string first {!} $line] >= 0} {
                set splitC {!}
                set subscribed 0
            } elseif {[string first {:} $line] < 0} {continue}
            set list [split $line $splitC]
            set name [lindex $list 0]
            set ranges [split [lindex $list 1] {,}]
            if {![$options(-grouptree) isActiveGroup $name]} {continue}
            $options(-grouptree) groupconfigure $name -subscribed $subscribed
            $options(-grouptree) groupsetranges $name $ranges
        }
        close $File
    }
    method write {} {
        set newsrc       "$options(-file)"
        set backupNewsrc "$options(-file)~"
        set newNewsrc    "$options(-file).new"
        set newsOut [open $newNewsrc w]
        set groups $options(-grouptree)
        if {[catch "open $options(-file) r" newsIn]} {
            foreach name [$groups activeGroups] {
                set subflag [$groups groupcget $name -subscribed]
                if {$subflag} {
                    puts -nonewline $newsOut "$name"
                    set comma {:}
                    set ranges [$groups groupgetranges $name]
                    foreach r $ranges {
                        puts -nonewline $newsOut "$comma$r"
                        set comma {,}
                    }
                    if {$comma == {:}} {puts -nonewline $newsOut "$comma"}
                    puts $newsOut {}
                }	
            }
        } else {
            while {[gets $newsIn line] != -1} {
                set splitC {:}
                if {[string first {!} $line] >= 0} {
                    set splitC {!}
                } elseif {[string first {:} $line] < 0} {
                    puts $newsOut "$line"
                    continue
                }
                set list [split $line $splitC]
                set name [lindex $list 0]
                puts -nonewline $newsOut "$name"
                if {[$groups isActiveGroup $name]} {
                    set subflag [$groups groupcget $name -subscribed]
                    set ranges [$groups groupgetranges $name]
                } else {
                    set subflag 0
                    set ranges {}
                }
                if {$subflag} {
                    set comma {:}
                } else {
                    set comma {!}
                }
                foreach r $ranges {
                    puts -nonewline $newsOut "$comma$r"
                    set comma {,}
                }
                if {$comma != {,}} {puts -nonewline $newsOut "$comma"}
                puts $newsOut {}
            }
            close $newsIn
        }
        close $newsOut
        catch "file rename -force $newsrc $backupNewsrc" message
        #      puts stderr "*** $self write: message = $message"
        catch "file rename -force $newNewsrc $newsrc"    message
        #      puts stderr "*** $self write: message = $message"
    }
}
snit::widgetadaptor DirectoryOfAllGroupsDialog {
    
    component groupTreeSW
    component groupTree
    component selectedGroupLE
    
    option {-grouptree groupTree GroupTree} -readonly yes \
          -validatemethod _CheckGroupTree
    method _CheckGroupTree {option value} {
        if {[catch [list $value info type] thetype]} {
            error "Expected a ::GroupTree for $option, but got $value ($thetype)"
        } elseif {![string equal "$thetype" ::GroupTree]} {
            error "Expected a ::GroupTree for $option, but got a $thetype ($value)"
        } else {
            return $value
        }
    }
    option -pattern -readonly yes -default .
    option {-subscribecallback subscribeCallback SubscribeCallback} \
          -readonly yes
    option -parent -readonly yes -default .
    delegate option -title to hull
    constructor {args} {
        set parent [from args -parent]
        installhull using Dialog -parent $parent \
              -class DirectoryOfAllGroupsDialog \
              -bitmap questhead -default 0 -cancel 0 \
              -modal none -transient yes -side bottom
        Dialog::add $win -name dismis -text Dismis -command [mymethod _Dismis]
        Dialog::add $win -name join   -text {Join Selected Group}   -command [mymethod _Join]
        Dialog::add $win -name help   -text Help   \
              -command [list BWHelp::HelpTopic DirectoryOfAllGroupsDialog]
        wm protocol $win WM_DELETE_WINDOW [mymethod _Dismis]
        install groupTreeSW using ScrolledWindow \
              [Dialog::getframe $win].groupTreeSW \
              -scrollbar both -auto both
        pack   $groupTreeSW -expand yes -fill both
        install groupTree using Tree [ScrolledWindow::getframe $groupTreeSW].groupTree \
              -selectcommand "[mymethod _SelectGroup] $groupTree" \
              -width 70 \
              -height [option get $parent spoolNumGroups \
                       SpoolNumGroups] \
              -selectfill yes
        pack   $groupTree -expand yes -fill both
        $groupTreeSW setwidget $groupTree
        install selectedGroupLE using LabelEntry \
              [Dialog::getframe $win].selectedGroupLE \
              -label {Selected Group:} -side left -editable no
        pack   $selectedGroupLE -fill x
        $self configurelist $args
        if {[string equal "$options(-subscribecallback)" {}]} {
            Dialog::itemconfigure $win join -state disabled
        }
        if {[string equal "$options(-grouptree)" {}]} {
            error "-GroupTree is a required option!"
        }
        $options(-grouptree) loadGroupTree $groupTree $options(-pattern) 1 Full 0
        Dialog::draw $win
    }
    method _Dismis {} {
        destroy $self
    }
    method _Join {} {
        set group "[$selectedGroupLE cget -text]"
        if {[string length "$group"] == 0} {return}
        uplevel #0 "eval $options(-subscribecallback) $group"
    }
    method _SelectGroup {gt selection} {
        $selectedGroupLE configure -text "[$gt itemcget $selection -data]"
    }
    typemethod draw {args} {
        set parent [from args -parent {.}]
        lappend args -parent $parent
        if {[lsearch $args -pattern] < 0} {
            set pattern [Common::SearchPatternDialog draw \
                         -parent $parent \
                         -title "Group Search Pattern" \
                         -pattern .]
            if {[string length "$pattern"] == 0} {return}
            lappend args -pattern "$pattern"
        }
        if {[string equal [string index "$parent" end] {.}]} {
            set window ${parent}directoryOfAllGroupsDialog%AUTO%
        } else {
            set window ${parent}.directoryOfAllGroupsDialog%AUTO%
        }
        return [eval [list $type create $window] $args]
    }
}

package provide GroupFunctions 1.0
