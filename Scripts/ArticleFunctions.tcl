#* 
#* ------------------------------------------------------------------
#* ArticleFunctions.tcl - Article functions
#* Created by Robert Heller on Sat May 27 15:59:37 2006
#* ------------------------------------------------------------------
#* Modification History: $Log$
#* Modification History: Revision 1.5  2007/07/12 16:54:46  heller
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

namespace eval AddressBook {#dummy}


snit::widget ArticleListFrame {
    hulltype ttk::frame
    typevariable columnheadings -array {
        #0,stretch no
        #0,anchor w
        #0,text Threads
        #0,width 80
        articlenumber,stretch yes
        articlenumber,anchor e
        articlenumber,text #
        articlenumber,width 30
        subject,stretch yes
        subject,anchor w
        subject,text Subject
        subject,width 200
        from,stretch yes
        from,anchor w
        from,text From
        from,width 100
        date,stretch yes
        date,anchor w
        date,text Date
        date,width 75
        lines,stretch no
        lines,anchor e
        lines,text Lines
        lines,width 40
        size,stretch no
        size,anchor e
        size,text Size
        size,width 40
    }
    typevariable columns {articlenumber subject from date lines size}
    typeconstructor {
        global execbindir
    }
    component artlistButtonBox
    typevariable artlistButtons -array {
        post {ttk::button -text {Post}  -command "[mymethod _PostToGroup] no"}
        list {ttk::button -text "List/Search\nArticles" -command "[mymethod _ListSearchArticles]"}
        read {ttk::button -text "Read\nArticle" -command "[mymethod _ReadSelectedArticle]"}
        refresh {ttk::button -text "Refresh Article\nList" -command "[mymethod _RefereshArticles]"}
        manage {ttk::menubutton -text "Manage\nSaved\nArticles" -state disabled}
    }
    typevariable artlistButtonsList {post list read refresh manage}
    component manageSavedArticlesMenu
    component articleListSW
    component   articleList
    component articleButtonBox
    typevariable articleButtons -array {
        followup {-text {Followup} -command "[mymethod _FollowupArticle] no"}
        mailreply {-text "Mail Reply\nTo Sender" -command "[mymethod _MailReply]"}
        forwardto {-text {Forward To} -command "[mymethod _ForwardTo]"}
        save {-text {Save} -command "[mymethod _SaveArticle]"}
        file {-text {File} -command "[mymethod _FileArticle]"}
        print {-text {Print} -command "[mymethod _PrintArticle]"}
    }
    typevariable articleButtonsList {followup mailreply forwardto save file print}
    delegate option -height to articleList
    delegate option -takefocus to articleList
    delegate method selection to articleList
    method _ReadArticleAt {x y} {
        lassign [$articleList identify $x $y] what where detail
        $spoolwindow _ReadArticle $where
    }
    variable inreplyto -array {}
    variable messageid -array {}
    variable subjects -array {}
    variable froms -array {}
    variable dates -array {}
    variable nreads -array {}
    variable article_number -array {}
    method articlenumber {_messageid} {
        if {[info exists article_number($_messageid)]} {
            return $article_number($_messageid)
        }
    }
    method deleteall {} {
        $articleList delete [$articleList children {}]
        array unset inreplyto
        array unset messageid
        array unset subjects
        array unset froms
        array unset dates
        array unset nreads
        array unset article_number
    }
    method insertArticleHeader {artnumber nread subject from date lines size 
        _messageid _inreplyto} {
        #puts stderr "*** $self insertArticleHeader: $artnumber, $_messageid, $_inreplyto"
        if {[$articleList exists $_messageid]} {
            # Duplicate message id (message filed or sent multiple times?)
            set index 1
            set newid ${_messageid}.$index
            while {[$articleList exists $newid]} {
                incr index
                set newid ${_messageid}.$index
            }
            set _messageid $newid
        }
        set article_number($_messageid) $artnumber
        set messageid($artnumber) $_messageid
        set inreplyto($_messageid) $_inreplyto
        set nreads($_messageid) $nread
        lappend subjects($subject) $_messageid
        lappend froms($from) $_messageid
        if {[regexp {^(.*)[[:space:]]([+-][02][0-9][0-9][0-9])$} $date => gmt offset] > 0} {
            set timestamp [clock scan $gmt -gmt yes]
        } else {
            set timestamp [clock scan $date]
        }
        #puts stderr "*** $self insertArticleHeader: date = $date, timestamp = $timestamp"
        lappend dates($timestamp) $_messageid
        $articleList insert {} end -id $_messageid -text {} \
              -values [list $artnumber $subject $from $date $lines $size] \
              -tags   article
    }
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
    component spoolwindow
    delegate method * to spoolwindow
    delegate method {artlistButtonBox *} to artlistButtonBox except {add}
    delegate option -artlistbuttonstate to artlistButtonBox as -state
    delegate method {articleButtonBox *} to articleButtonBox except {add}
    delegate option -articlebuttonstate to articleButtonBox as -state
    option -panewindow -default {} -readonly yes -type snit::window
    option -sashsign -default - -readonly yes -type {snit::enum -values {+ -}}
    proc _adjustTree {w h groupTree pane adjsign} {
        if {$h < [winfo reqheight $w]} {
            ## Attempting to squish a button box -- ouch!
            # First defense: try to shorten a tree
            set th [$groupTree cget -height]
            incr th -1
            if {$th > 0} {
                $groupTree configure -height $th
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
    constructor {args} {
        install artlistButtonBox using ButtonBox $win.artlistButtonBox
        pack $artlistButtonBox -fill x
        foreach ab $artlistButtonsList {
            set opts $artlistButtons($ab)
            set command [lindex $opts 0]
            set opts [subst [lrange $opts 1 end]]
            eval [list $artlistButtonBox add $command $ab] $opts
            if {$command eq "ttk::menubutton"} {
                install manageSavedArticlesMenu using menu $artlistButtonBox.$ab.manageSavedArticlesMenu
                $artlistButtonBox itemconfigure $ab -menu $manageSavedArticlesMenu
            }
        }
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
        #bind $manageSavedArticlesMenu <Escape> {Common::UnPostMenu %W;break}
        $artlistButtonBox configure -state disabled
        install articleListSW using ScrolledWindow $win.articleListSW \
              -scrollbar vertical -auto vertical
        pack $articleListSW -fill both -expand yes
        install articleList using ttk::treeview \
              [$articleListSW getframe].articleList -columns $columns \
              -displaycolumns $columns -show {tree headings}
        $articleList tag bind article <Double-ButtonPress-1> [mymethod _ReadArticleAt %x %y]
        $articleListSW setwidget $articleList
        # Article buttons
        install articleButtonBox using ButtonBox $win.articleButtonBox
        pack $articleButtonBox -fill x
        foreach ab $articleButtonsList {
            set opts [subst $articleButtons($ab)]
            eval [list $articleButtonBox add ttk::button $ab] $opts
        }
        #      puts stderr "*** ${type}::constructor: before configurelist: args = $args"
        $articleButtonBox configure -state disabled
        $self configurelist $args
        set spoolwindow $options(-spool)
        bind $articleButtonBox <Configure> [myproc _adjustTree %W %h \
                                            $articleList \
                                            $options(-panewindow) \
                                            $options(-sashsign)]
        #parray columnheadings
        foreach c [concat #0 $columns] {
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
                eval [list $articleList column $c] $copts
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
                eval [list $articleList heading $c] $hopts
            }
        }
        $articleList heading #0 -command [mymethod _threadArticleList]
        $articleList heading articlenumber -command [mymethod _sortByArtNumber]
        $articleList heading date -command [mymethod _sortByDate]
        $articleList heading from -command [mymethod _sortBySender]
        $articleList heading subject -command [mymethod _sortBySubject]
    }
    method _threadArticleList {} {
        #puts stderr "*** $self _threadArticleList"
        $articleList detach [$articleList children {}]
        foreach an [lsort -integer [array names messageid]] {
            set parent $inreplyto($messageid($an))
            if {![$articleList exists $parent]} {set parent {}}
            #puts stderr "*** $self _threadArticleList: an = $an, messageid($an) = $messageid($an), inreplyto($messageid($an)) = $inreplyto($messageid($an))"
            #puts stderr "*** $self _threadArticleList: parent = $parent"
            $articleList move $messageid($an) $parent end
            if {$parent ne {}} {$articleList item $parent -open yes}
        }
        #if {[lsearch -exact [$articleList cget -show] tree] < 0} {
        #    set widthneeded [winfo width [winfo parent $win]]
        #    $articleList configure -show {tree headings}
        #    adjustHeadWidth $articleList $widthneeded
        #}
    }
    method _sortByArtNumber {} {
        #puts stderr "*** $self _sortByArtNumber"
        $articleList detach [$articleList children {}]
        foreach an [lsort -integer [array names messageid]] {
            $articleList item $messageid($an) -open no
            $articleList move $messageid($an) {} end
        }
        #if {[lsearch -exact [$articleList cget -show] tree] >= 0} {
        #    set widthneeded [winfo width [winfo parent $win]]
        #    $articleList configure -show {headings}
        #    adjustHeadWidth $articleList $widthneeded
        #}
    }
    method _sortByDate {} {
        #puts stderr "*** $self _sortByDate"
        $articleList detach [$articleList children {}]
        foreach date [lsort -integer [array names dates]] {
            #puts stderr "*** $self _sortByDate: date = $date, dates($date) = $dates($date)"
            foreach m $dates($date) {
                $articleList item $m -open no
                $articleList move $m {} end
            }
        }
        #if {[lsearch -exact [$articleList cget -show] tree] >= 0} {
        #    set widthneeded [winfo width [winfo parent $win]]
        #    $articleList configure -show {headings}
        #    adjustHeadWidth $articleList $widthneeded
        #}
    }
    method _sortBySender {} {
        #puts stderr "*** $self _sortBySender"
        $articleList detach [$articleList children {}]
        foreach from [lsort -dictionary [array names froms]] {
            foreach m $froms($from) {
                $articleList item $m -open no
                $articleList move $m {} end
            }
        }
        #if {[lsearch -exact [$articleList cget -show] tree] >= 0} {
        #    set widthneeded [winfo width [winfo parent $win]]
        #    $articleList configure -show {headings}
        #    adjustHeadWidth $articleList $widthneeded
        #}
    }
    method _sortBySubject {} {
        #puts stderr "*** $self _sortBySubject"
        $articleList detach [$articleList children {}]
        foreach subj [lsort -dictionary [array names subjects]] {
            foreach m $subjects($subj) {
                $articleList item $m -open no
                $articleList move $m {} end
            }
        }
        #if {[lsearch -exact [$articleList cget -show] tree] >= 0} {
        #    set widthneeded [winfo width [winfo parent $win]]
        #    $articleList configure -show {headings}
        #    adjustHeadWidth $articleList $widthneeded
        #}
    }
    proc computeHeadWidth {artlist} {
        set width 0
        foreach c [$artlist cget -displaycolumns] {
            set cw [$artlist column $c -width]
            incr width $cw
        }
        if {[lsearch [$artlist cget -show] tree] >= 0} {
            set cw [$artlist column #0 -width]
            incr width $cw
        }
        return $width
    }
    proc adjustHeadWidth {artlist widthneeded} {
        #puts stderr "*** ArticleList::adjustHeadWidth $artlist $widthneeded"
        set reqwidth [computeHeadWidth $artlist]
        #puts stderr "*** -: reqwidth = $reqwidth"
        set diff [expr {$widthneeded - $reqwidth}]
        #puts stderr "*** -: diff = $diff"
        set fract [expr {double($diff) / double($reqwidth)}]
        #puts stderr "*** -: fract = $fract"
        set stretchablecols [list]
        if {[lsearch [$artlist cget -show] tree] >= 0} {
            if {[$artlist column #0 -stretch]} {
                lappend stretchablecols #0
            }
        }
        set totalstretch 0
        foreach c [$artlist cget -displaycolumns] {
            if {[$artlist column $c -stretch]} {
                lappend stretchablecols $c
                incr totalstretch [$artlist column $c -width]
            }
        }
        if {[llength $stretchablecols] == 0} {return}
        set stretch [expr {$diff / [llength $stretchablecols]}]
        #puts stderr "*** -: stretch = $stretch"
        foreach c $stretchablecols {
            set cwf [expr {[$artlist column $c -width] + $stretch}]
            set percentstretch [expr {double([$artlist column $c -width]) / double($totalstretch)}]
            set stretchp [expr {int($diff * $percentstretch)}]
            #set stretchp [expr {int([$artlist column $c -width] * $fract)}]
            #puts stderr "*** -: ($c) stretchp = $stretchp"
            set cwp [expr {[$artlist column $c -width] + $stretchp}]
            #puts stderr "*** -: ($c) cwf = $cwf"
            #puts stderr "*** -: ($c) cwp = $cwp"
            $artlist column $c -width $cwp
        }
    }
        
}

        
namespace eval Articles {

  snit::widget Viewer {
    hulltype toplevel
    widgetclass Viewer

    component messageLabel
    component headerFrame
    component dateLE
    component fromLE
    component toLE
    component subjectLE
    component updateAddrBookBut
    component messageTextSW
    component messageText
    component articleButtonBox

    option -parent -readonly yes -default .
    option -spool  -readonly yes -validatemethod _CheckSpool
    method _CheckSpool {option value} {
      if {[catch [list $value info type] thetype]} {
	error "Expected a ::Spool::SpoolWindow for $option, but got $value ($thetype)"
      } elseif {![string equal "$thetype" ::Spool::SpoolWindow]} {
	error "Expected a ::Spool::SpoolWindow for $option, but got a $thetype ($value)"
      } else {
 	return $value
      }
    }
    option {-geometry articleGeometry ArticleGeometry} -readonly yes -default {}

    delegate method {buttons *} to articleButtonBox
    variable articleNumber
    variable groupName
    variable pipeFP
    variable processing
    variable EOH
    variable cc {}

    constructor {args} {
      set options(-parent) [from args -parent]
      set options(-spool)  [from args -spool]
      wm transient $win $options(-parent)
      wm protocol $win WM_DELETE_WINDOW [mymethod close]
      set options(-geometry) [from args -geometry [option get $win articleGeometry ArticleGeometry]]
      if {[string length "$options(-geometry)"] > 0} {
	wm geometry $win "$options(-geometry)"
      }
      install messageLabel using Label $win.messageLabel -text {}
      pack $messageLabel -fill x
      install headerFrame using frame $win.headerFrame \
		-relief ridge -borderwidth 4
      pack $headerFrame -fill x
      install dateLE using LabelEntry $headerFrame.dateLE \
		-labelwidth 10 -label "Date:" -side left -editable no
      pack $dateLE -fill x
      install fromLE using LabelEntry $headerFrame.fromLE \
		-labelwidth 10 -label "From:" -side left -editable no
      pack $fromLE -fill x
      install toLE using LabelEntry $headerFrame.toLE \
		-labelwidth 10 -label "To:" -side left -editable no
      pack $toLE -fill x
      install subjectLE using LabelEntry $headerFrame.subjectLE \
		-labelwidth 10 -label "Subject:" -side left -editable no
      pack $subjectLE -fill x
      install updateAddrBookBut using Button $headerFrame.updateAddrBookBut \
		-text "Collect Addresses" -command [mymethod _CollectAddresses]
      pack $updateAddrBookBut -fill x
      install messageTextSW using ScrolledWindow $win.messageTextSW \
		-scrollbar vertical -auto vertical
      pack $messageTextSW -expand yes -fill both
      install messageText using text [$messageTextSW getframe].messageText \
		-wrap word
      pack $messageText -expand yes -fill both
      $messageTextSW setwidget $messageText
      bindtags $messageText [list $messageText ROText $win all]
      install articleButtonBox using ButtonBox $win.articleButtonBox \
		-orient horizontal
      pack $articleButtonBox -fill x
      $articleButtonBox add -name close -text "Close" -command [mymethod close]
      $articleButtonBox add -name previous -text "Previous"
      $articleButtonBox add -name next -text "Next"
      $articleButtonBox add -name save -text "Save" -command [mymethod _Save]
      $articleButtonBox add -name file -text "File" -command [mymethod _File]
      $articleButtonBox add -name print -text "Print" -command [mymethod _Print]
      $articleButtonBox add -name decrypt -text "Decrypt" -command [mymethod _Decrypt]
      set articleNumber -1
      set groupName {}
    }
    method draw {} {wm deiconify $win}
    method close {} {
      wm withdraw $win
      $options(-spool) closeArticle
    }
    method setNumber {artNumber} {
      set articleNumber $artNumber
      $messageLabel configure -text "$artNumber"
    }
    method setGroup {group} {
      wm title $win "Reading group $group"
      set groupName $group
    }
    method NNTP_GetArticleToText {} {
      $messageText delete 1.0 end-1c
      if {[$options(-spool) srv_cmd "group $groupName" buff] < 0} {
	error "${type}::NNTP_GetArticleToText: Error sending group command"
	return 0
      }
      if {[string first {411} "$buff"] == 0} {return 0}
      if {[$options(-spool) srv_cmd "article $articleNumber" buff] < 0} {
	error "${type}::NNTP_GetArticleToText: Error sending article command"
	return 0
      }
      if {[string first {220} "$buff"] != 0} {return 0}
      $options(-spool) srv_rdTxtTextBox $messageText
      $self _GetHeaderFields
    }
    method readArticleFromFile {filename} {
      $messageText delete 1.0 end-1c
      set file [open $filename "r"]
      set block [read $file 4096]
      while {[string length "$block"] > 0} {
	$messageText insert end "$block"
	update idletasks
	set block [read $file 4096]
      }
      close $file
      $self _GetHeaderFields
    }
    method _CollectAddresses {} {
      set to "[$toLE cget -text]"
      if {[string length "$to"] > 0} {AddressBook::CheckNewAddresses "$to"}
      set from "[$fromLE cget -text]"
      if {[string length "$from"] > 0} {AddressBook::CheckNewAddresses "$from"}
      if {[string length "$cc"] > 0} {AddressBook::CheckNewAddresses "$cc"}
    }
    method _GetHeaderFields {} {
      regexp {^([0-9]*).[0-9]*$} [$messageText index end-1c] -> lastline
      set EOH 0
      set win1252 no
      $toLE configure -text {}
      $fromLE configure -text {}
      $dateLE configure -text {}
      $subjectLE configure -text {}
      for {set iline 1} {$iline < $lastline} {incr iline} {
	set line [$messageText get "${iline}.0" "${iline}.0 lineend"]
#	puts stderr "*** ${type}::_GetHeaderFields: line = '$line'"
	if {[string equal "$line" {}]} {
	  set EOH $iline
	  break
	}
	if {[regexp -nocase {^To: (.*)$} "$line" -> to] > 0} {
	  $toLE configure -text [string trim "$to"]
#	  AddressBook::CheckNewAddresses "$to"
	}
	if {[regexp -nocase {^Cc: (.*)$} "$line" -> cc] > 0} {
#	  AddressBook::CheckNewAddresses "$cc"
        }
	if {[regexp -nocase {^From: (.*)$} "$line" -> from] > 0} {
	  $fromLE configure -text [string trim "$from"]
#	  AddressBook::CheckNewAddresses "$from"
	}
	if {[regexp -nocase {^Date: (.*)$} "$line" -> date] > 0} {
	  $dateLE configure -text [string trim "$date"]
	}
	if {[regexp -nocase {^Subject: (.*)$} "$line" -> subject] > 0} {
	  $subjectLE configure -text [string trim "$subject"]
	}
	if {[regexp -nocase {charset="??windows-1252"??} "$line"] > 0} {
	  set win1252 yes
	}
      }
      if {$win1252} {
	set tempFile /tmp/[pid].recoded
	if {[catch [list open "$tempFile" w] tmpFP]} {
	  error "${type}::_GetHeaderFields: open \"$tempFile\" w: $tmpFP"
	  return
	}
	set tempBlock "[$messageText get "${EOH}.0" end-1c]"
	puts $tmpFP "$tempBlock"
        close $tmpFP
        if {[catch [list open "|recode < $tempFile windows-1252..iso-8859-1" r] pipeFP]} {
	  file delete -force "$tempFile"
	  error "${type}::_GetHeaderFields: open \"|recode < $tempFile windows-1252..iso-8859-1\" r: $pipeFP"
	  return
	}
	set processing 1
	$messageText delete "${EOH}.0" end-1c
	fileevent $pipeFP readable [mymethod _PipeToText]
	if {$processing > 0} {tkwait variable [myvar processing]}
	file delete -force "$tempFile"
      }
      regexp {^([0-9]*).[0-9]*$} [$messageText index end-1c] -> lastline
      set fract [expr double($EOH) / double($lastline)]
      $messageText yview moveto $fract
      AddressBook::WriteAddressBookFileIfDirty
    }
    method _PipeToText {} {
      if {[gets $pipeFP line] < 0} {
	catch "close $pipeFP"
	incr processing -1
      } else {
	$messageText insert end "$line\n"
      }
    }
    method _Save {} {
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
      puts $outfp "[$messageText get 1.0 end-1c]"
      close $outfp
    }
    method _File {} {
      if {[catch "$options(-spool) savedDirectory $groupName" baseDir]} {
	set baseDir [file join [$options(-spool) cget -savednews] \
			     [Common::GroupToPath $groupName]]
      }
      if {![file exists "$baseDir"]} {file mkdir $baseDir}
      set folder [Articles::SelectFolderDialog draw \
				-parent $win \
				-basedirectory $baseDir \
				-title "Select subfolder for $groupName"]
      if {[string length "$folder"] == 0} {return}
      set saveDir [file join $baseDir $folder]
      set newname "${groupName}.${folder}"
      if {![file exists "$saveDir"]} {
	file mkdir $saveDir
	$options(-spool) addSavedDirectory $newname $saveDir
	$options(-spool) addSavedGroupLine $groupName $newname
      }
      set highMessage [Common::Highestnumber [glob -nocomplain "$saveDir/*"]]
      set mnum [expr $highMessage + 1]
      set saveFile [file join $saveDir $mnum]
      if {[catch "open $saveFile w" outfp]} {
	error "Cannot create file $saveFile: $outfp"
	return
      }
      puts $outfp "[$messageText get 1.0 end-1c]"
      close $outfp
      $options(-spool) updateGroupTreeLine $newname
    }
    method _Print {} {
      global PrintCommand
      set printPipe "|$PrintCommand"
      if {[catch [list open "$printPipe" w] outfp]} {
        error "Cannot create pipeline: $printPipe: $outfp"
        return
      }
      puts $outfp "[$messageText get 1.0 end-1c]"
      catch "close $outfp" message
      if {[string length "$message"] > 0} {
	Common::ServerMessageDialog draw \
			-parent $win \
			-title "$PrintCommand messages" \
			-message "$message" \
			-geometry 600x200
      }
    }
    proc _hasMIMEheaders {body} {
      set seenHeaders no
      foreach line [split "$body" "\n"] {
	#puts stderr "*** [namespace current]_hasMIMEheaders: line is '$line'"
	#puts stderr "*** [namespace current]_hasMIMEheaders: seenHeaders is $seenHeaders"
	if {"[string trim $line]" eq ""} {
	  if {$seenHeaders} {
	    return no
	  } else {
	    continue
	  }
	}
	set seenHeaders yes	
	if {[regexp {^([^[:space:]]+)[[:space:]]+[^[:space:]]} "$line" -> headertag] > 0} {
	  #puts stderr "*** [namespace current]_hasMIMEheaders: headertag is $headertag"
	  if {[lsearch {MIME-Version: Content-Type: Content-type:} $headertag] >= 0} {return yes}
	} else {
	  return no
	}
      }
      return no
    }
    method _Decrypt {} {
      set body [$self getBody]
      set spoolWindow $options(-spool)
      #set decryptProgram [split [option get $spoolWindow decryptProgram decryptProgram]]
      #set decryptPassphrase [split [option get $spoolWindow decryptPassphrase DecryptPassphrase]]
      #set passPhrase [Articles::EnterPassPhraseDialog draw -parent $win]
      #foreach o $decryptPassphrase {
	#lappend decryptProgram [regsub -all "%passphrase" "$o" "$passPhrase"]
      #}
      #set bodyFile "/usr/tmp/$spoolWindow.[pid].asc"
      set index1 [string first "\n-----BEGIN PGP MESSAGE-----\n" "$body"]
      if {$index1 < 0} {return}
      set index2 [string last  "\n-----END PGP MESSAGE-----\n" "$body"]
      if {$index2 < 0} {
          set index2 end
      } else {
          incr index2 [string length "-----END PGP MESSAGE-----\n"]
      }
      set cipherBlock [string range "$body" $index1 $index2]
      package require Gpgme
      set ctx [gpgme_new]
      gpgme_set_armor $ctx 1
      gpgme_set_passphrase_cb $ctx [mymethod _passphrase_callback]
      set cipher [gpgme_data_new_from_mem $cipherBlock]
      set plain  [gpgme_data_new]
      if {[catch {gpgme_op_decrypt $ctx $cipher $plain} result]} {
          tk_messageBox -icon error -type ok -message $result" -parent $win
          gpgme_data_release $plain
          gpgme_data_release $cipher
          tcl_free_passphrase_cb $ctx
          gpgme_release $ctx
          return
      }
      set decriptBody [tcl_gpgme_data_release_and_get_mem $plain]
      gpgme_data_release $cipher
      tcl_free_passphrase_cb $ctx
      gpgme_release $ctx
      if {[string length "$decriptBody"] == 0} {return}
      if {![_hasMIMEheaders $decriptBody]} {
	$self putBody "\n$decriptBody"
      } else {
	set mailcaps [option get $spoolWindow mailcaps Mailcaps]
	if {$mailcaps ne ""} {
	  set ::env(MAILCAPS) "$mailcaps"
        }
        set metamailTmpdir [option get $spoolWindow metamailTmpdir MetamailTmpdir]
        if {$metamailTmpdir ne ""} {
	  set ::env(METAMAIL_TMPDIR) "$metamailTmpdir"
        }
        set mimeCommand [option get $spoolWindow mimeCommand MimeCommand]
	set bodyFile "/usr/tmp/$spoolWindow.[pid]"
	set bodyFP [open $bodyFile w]
	puts $bodyFP "$decriptBody"
	close $bodyFP
	set cmdPipeLine "|[regsub -all "%f" $mimeCommand $bodyFile]"
	set bodyFP [open "$cmdPipeLine" r]
	set body [read $bodyFP]
	catch {close $bodyFP} out
	$self putBody "\n$body"
      }
    }
    method _passphrase_callback {uid_hint passphrase_info prev_was_bad} {
        #puts stderr "*** $self _passphrase_callback passphrase_info is '$passphrase_info'"
        #puts stderr "*** $self _passphrase_callback uid_hint is '$uid_hint'"
        set passPhrase [Articles::EnterPassPhraseDialog draw -parent $win \
                        -uidhint [lrange $uid_hint 1 end] \
                        -prevwasbad $prev_was_bad]
    }
    method getSimpleHeaders {} {
      set result {}
      set copyingheader no
      for {set iline 1} {$iline < $EOH} {incr iline} {
	set line [$messageText get "${iline}.0" "${iline}.0 lineend"]
        if {[regexp {^[[:space:]]+[^[:space:]]} "$line"] > 0} {
	  if {$copyingheader} {append result "\n$line"}
	} else {
	  set copyingheader no
	  if {[regexp -nocase {^([^:]+):[[:space:]]} $line => field] > 0} {
	    if {[lsearch -exact {from to cc subject message-id 
				 date newsgroups} [string tolower $field]] >= 0} {
	      append result "\n$line"
	      set copyingheader yes
	    }
	  }
	}
      }
      return [string trimleft "$result" "\n"]
    }
    method getHeader {field} {
#      puts stderr "*** $self getHeader $field"
      set hbuffer {}
      for {set iline 1} {$iline < $EOH} {incr iline} {
	set line [$messageText get "${iline}.0" "${iline}.0 lineend"]
	if {[regexp {^[[:space:]]+[^[:space:]]} "$line"] > 0} {
	  append hbuffer " $line"
	} else {
	  if {[string length "$hbuffer"] > 0} {
	    if {[regexp -nocase "^$field:\[\[:space:\]\]+(.*)\$" "$hbuffer" -> result] > 0} {
	      return "$result"
	    }
	  }
	  set hbuffer [string trim "$line"]
	}
      }
      return {}
    }
    method getBody {} {
      return "[$messageText get ${EOH}.0 end-1c]"
    }
    method putBody {content} {
      $messageText delete ${EOH}.0 end-1c
      $messageText insert ${EOH}.0 "$content"
    }
  }
  snit::widgetadaptor SelectFolderDialog {
    typevariable dialogsByParent -array {}
    option -parent -readonly yes -default .
    option {-basedirectory baseDirectory BaseDirectory} \
		-validatemethod _CheckDirectory
    delegate option -title to hull

    component folderListSW
    component folderList
    component selectedFolderLE

    method _CheckDirectory {option value} {
      if {[file isdirectory "$value"]} {
        return $value
      } else {
        error "Expected an existing directory for $option, got $value"
      }
    }

    constructor {args} {
      set options(-parent) [from args -parent]
      installhull using Dialog::create \
			-class SelectFolderDialog -bitmap questhead \
			-default 0 -cancel 1 -modal local -transient yes \
			-parent $options(-parent) -side bottom
#      puts stderr "*** $self constructor: hull = $hull, win = $win, winfo class $win = [winfo class $win]"
      Dialog::add $win -name ok -text OK -command [mymethod _OK]
      Dialog::add $win -name cancel -text Cancel -command [mymethod _Cancel]
      Dialog::add $win -name help -text Help -command [list BWHelp::HelpTopic SelectFolderDialog]
      wm protocol $win WM_DELETE_WINDOW [mymethod _Cancel]
      install folderListSW using ScrolledWindow \
				[Dialog::getframe $win].folderListSW \
		-scrollbar vertical -auto vertical
#      puts stderr "*** $self constructor: folderListSW = $folderListSW, winfo class $folderListSW = [winfo class $folderListSW]"
      pack   $folderListSW -expand yes -fill both
      install folderList using ListBox \
			[ScrolledWindow::getframe $folderListSW].folderList \
		-selectmode single -selectfill yes
#      puts stderr "*** $self constructor: folderList = $folderList, winfo class $folderList = [winfo class $folderList]"
      pack $folderList -fill both -expand yes
      $folderListSW setwidget $folderList
      $folderList bindText <space> [mymethod _SelectFolder]
      $folderList bindText <1> [mymethod _SelectFolder]
      $folderList bindText <Return> [mymethod _SelectAndReturnFolder]
      $folderList bindText <Double-Button-1> [mymethod _SelectAndReturnFolder]
#      puts stderr "*** $self constructor: about to install selectedFolderLE"
      install selectedFolderLE using LabelEntry \
		[Dialog::getframe $win].selectedFolderLE \
		-label {Selected Folder:} -side left
#      puts stderr "*** $self constructor: selectedFolderLE = $selectedFolderLE, winfo class $selectedFolderLE = [winfo class $selectedFolderLE]"
      pack $selectedFolderLE -fill x
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
    method _SelectFolder {selection} {
      $selectedFolderLE configure -text "[$folderList itemcget $selection -data]"
    }
    method _SelectAndReturnFolder {selection} {
      $selectedFolderLE configure -text "[$folderList itemcget $selection -data]"
      $self _OK
    }
    method _Draw {args} {
      $self configurelist $args
      if {![info exists options(-basedirectory)]} {
	error "-basedirectory is a required option!"
      }
      $folderList delete [$folderList items]
      foreach dir [lsort -dictionary [glob -nocomplain \
					   [file join $options(-basedirectory) \
							*]]] {
	if {[file isdirectory $dir] && [file writable $dir]} {
	  set folder [file tail $dir]
	  $folderList insert end $folder -data $folder -text $folder
	}
      }
      switch -exact -- [Dialog::draw $win] {
        ok {return "[$selectedFolderLE cget -text]"}
	cancel -
	default {return {}}
      }
    }
    typemethod draw {args} {
      set parent [from args -parent {.}]
      if {[catch "set dialogsByParent($parent)" dialog]} {
	if {[string equal [string index $parent end] {.}]} {
	  set dialog ${parent}selectFolderDialog
	} else {
	  set dialog ${parent}.selectFolderDialog
	}
	set dialog [eval [list $type \
				create ${dialog} -parent $parent] \
			 $args]
      }
      return "[eval [list $dialog _Draw] $args]"
    }
  }
  snit::widgetadaptor SearchArticlesDialog {

    component articleListSW
    component articleList
    component selectedArticleLE

    option {-grouplist groupList GroupList} -readonly yes \
					    -validatemethod _CheckGroupList
    method _CheckGroupList {option value} {
      if {[catch [list $value info type] thetype]} {
	error "Expected a ::Groups::groupList for $option, but got $value ($thetype)"
      } elseif {![string equal "$thetype" ::Groups::groupList]} {
	error "Expected a ::Groups::groupList for $option, but got a $thetype ($value)"
      } else {
 	return $value
      }
    }
    option -pattern -readonly yes -default .
    option -group -readonly yes
    option {-readarticle readArticle ReadArticle} \
		-readonly yes
    option -parent -readonly yes -default .
    delegate option -title to hull
    constructor {args} {
      installhull using Dialog -parent [from args -parent] \
			       -class SearchArticlesDialog \
			       -bitmap questhead -default 0 -cancel 0 \
			       -modal none -transient yes -side bottom
      Dialog::add $win -name dismis -text Dismis -command [mymethod _Dismis]
      Dialog::add $win -name read   -text {Read Selected Article} \
			     -command [mymethod _ReadArticle]
      Dialog::add $win -name help   -text Help   \
		-command [list BWHelp::HelpTopic SearchArticlesDialog]
      wm protocol $win WM_DELETE_WINDOW [mymethod _Dismis]
      install articleListSW using ScrolledWindow \
					[Dialog::getframe $win].articleListSW \
		-scrollbar both -auto both
      pack   $articleListSW -expand yes -fill both
      install articleList using ListBox \
			[ScrolledWindow::getframe $articleListSW].articleList \
		-selectmode single -selectfill yes
      pack $articleList -fill both -expand yes
      $articleListSW setwidget $articleList
      $articleList bindText <space> [mymethod _SelectArticle]
      $articleList bindText <1> [mymethod _SelectArticle]
      install selectedArticleLE using LabelEntry \
		[Dialog::getframe $win].selectedArticleLE \
		-label {Selected Article:} -side left -editable no
      pack $selectedArticleLE -fill x
      $self configurelist $args
      if {[string equal "$options(-readarticle)" {}]} {
	Dialog::itemconfigure $win read -state disabled
      } else {
        $articleList bindText <Double-Button-1> [mymethod _SelectAndReadArticle]
        $articleList bindText <Return> [mymethod _SelectAndReadArticle]
      }
      if {[string equal "$options(-grouplist)" {}]} {
	error "-grouplist is a required option!"
      }
      if {[string equal "$options(-group)" {}]} {
	error "-group is a required option!"
      }
      $options(-grouplist) insertArticleList $articleList $options(-group) "$options(-pattern)" 1
      Dialog::draw $win
    }
    method _Dismis {} {
      destroy $self
    }
    method _SelectArticle {selection} {
      $selectedArticleLE configure \
				-text [$articleList itemcget $selection -data]
    }
    method _SelectAndReadArticle {selection} {
      $self _SelectArticle $selection
      $self _ReadArticle
    }
    method _ReadArticle {} {
      set artNumber "[$selectedArticleLE cget -text]"
      if {[string length "$artNumber"] == 0} {return}
      uplevel #0 "eval $options(-readarticle) $artNumber"
    }
    typemethod draw {args} {
      set parent [from args -parent {.}]
      lappend args -parent $parent
      if {[lsearch $args -pattern] < 0} {
	set pattern [Common::SearchPatternDialog draw \
			-parent $parent \
			-title "Article Search Pattern" \
			-pattern .]
	if {[string length "$pattern"] == 0} {return}
	lappend args -pattern "$pattern"
      }
      if {[string equal [string index "$parent" end] {.}]} {
	set window ${parent}searchArticlesDialog%AUTO%
      } else {
	set window ${parent}.searchArticlesDialog%AUTO%
      }
      return [eval [list $type create $window] $args]
    }
  }
  snit::widgetadaptor SelectArticlesDialog {
    component articleListSW
    component articleList
    option {-grouplist groupList GroupList} -readonly yes \
					    -validatemethod _CheckGroupList
    method _CheckGroupList {option value} {
      if {[catch [list $value info type] thetype]} {
	error "Expected a ::Groups::groupList for $option, but got $value ($thetype)"
      } elseif {![string equal "$thetype" ::Groups::groupList]} {
	error "Expected a ::Groups::groupList for $option, but got a $thetype ($value)"
      } else {
 	return $value
      }
    }
    option -group -readonly yes
    option -selectmode -readonly yes -default single
    option -parent -readonly yes -default .
    delegate option -title to hull
    delegate option -geometry to hull
    constructor {args} {
      installhull using Dialog -parent [from args -parent] \
			       -class SearchArticlesDialog \
			       -bitmap questhead -default 0 -cancel 1 \
			       -modal local -transient yes -side bottom
      Dialog::add $win -name ok -text OK -command [mymethod _OK]
      Dialog::add $win -name cancel -text Dismis -command [mymethod _Cancel]
      Dialog::add $win -name help   -text Help   \
		-command [list BWHelp::HelpTopic SelectArticlesDialog]
      wm protocol $win WM_DELETE_WINDOW [mymethod _Cancel]
      install articleListSW using ScrolledWindow \
					[Dialog::getframe $win].articleListSW \
		-scrollbar both -auto both
      pack   $articleListSW -expand yes -fill both
      install articleList using ListBox \
			[ScrolledWindow::getframe $articleListSW].articleList \
		-selectfill yes -selectmode [from args -selectmode]
      pack $articleList -fill both -expand yes
      $articleListSW setwidget $articleList
      $self configurelist $args
      if {[string equal "$options(-grouplist)" {}]} {
	error "-grouplist is a required option!"
      }
      if {[string equal "$options(-group)" {}]} {
	error "-group is a required option!"
      }
      $articleList delete [$articleList items]
      $options(-grouplist) insertArticleList $articleList $options(-group)
    }
    method _OK {} {
      Dialog::withdraw $win
      return [Dialog::enddialog $win ok]
    }
    method _Cancel {} {
      Dialog::withdraw $win
      return [Dialog::enddialog $win cancel]
    }
    method _Draw {} {return [Dialog::draw $win]}
    method _SelectedArticleNumbers {} {
      set result {}
      foreach sel [$articleList selection get] {
	lappend result [$articleList itemcget $sel -data]
      }
      return $result
    }
    typemethod draw {args} {
      set parent [from args -parent .]
      if {[string equal "$parent" {.}]} {
	set dialog [eval [list $type .selectArticlesDialog%AUTO% \
				-parent $parent] $args]
      } else {
	set dialog [eval [list $type ${parent}.selectArticlesDialog%AUTO% \
				-parent $parent] $args]
      }
      set answer [$dialog _Draw]
      if {[string equal $answer ok]} {
	set arts [$dialog _SelectedArticleNumbers]
      } else {
	set arts {}
      }
      destroy $dialog
      return $arts
    }
  }
  snit::widgetadaptor EnterPassPhraseDialog {
    typevariable dialogsByParent -array {}
    option -parent -readonly yes -default .
    delegate option -title to hull
    delegate option -uidhint to uidhintL as -text
    option -prevwasbad -default 0 -type snit::boolean \
          -configuremethod _confprevwasbad
    method _confprevwasbad {option value} {
        set options($option) $value
        if {$value} {
            catch {$prevwasbadL configure -text "Re-type the pass phrase"}
        } else {
            catch {$prevwasbadL configure -text ""}
        }
    }
    option -passphraseinfo {}
    component uidhintL
    component prevwasbadL
    component passphraseLE
    constructor {args} {
      set options(-parent) [from args -parent]
      installhull using Dialog::create \
	-class EnterPassPhraseDialog -bitmap questhead \
	-default 0 -modal local -transient yes \
	-parent $options(-parent) -side bottom
      Dialog::add $win -name ok -text OK -command [mymethod _OK]
      install uidhintL using Label \
            [Dialog::getframe $win].uidhintL -justify left -anchor w
      pack $uidhintL -fill x -expand yes
      install prevwasbadL using Label \
            [Dialog::getframe $win].prevwasbadL -justify left -anchor w
      pack $prevwasbadL -fill x -expand yes
      install passphraseLE using LabelEntry [Dialog::getframe $win].passphraseLE \
				-show * -label "Pass Phrase:"
      pack $passphraseLE -fill x
      $self configurelist $args
      set dialogsByParent($options(-parent)) $self
    }
    destructor {
      catch {unset dialogsByParent($options(-parent))}
    }
    method _OK {} {
      Dialog::withdraw $win
      return [Dialog::enddialog $win [$passphraseLE cget -text]]
    }
    method _Draw {args} {
      $self configurelist $args
      $passphraseLE configure -text {}
      return [Dialog::draw $win $passphraseLE.e]
    }
    typemethod draw {args} {
      set parent [from args -parent {.}]
      if {[catch "set dialogsByParent($parent)" dialog]} {
	if {[string equal [string index $parent end] {.}]} {
	  set dialog ${parent}enterPassPhraseDialog
	} else {
	  set dialog ${parent}.enterPassPhraseDialog
	}
	set dialog [eval [list $type \
			create ${dialog} -parent $parent] \
			$args]
	}
      return "[eval [list $dialog _Draw] $args]"
    }
  }
}



package provide ArticleFunctions 1.0
