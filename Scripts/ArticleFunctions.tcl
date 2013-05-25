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

package require Tk;#                 GUI Toolkit
package require tile;#               Themed Widgets
package require snit;#               OO Framework
package require Img;#                Extended image support
package require MainFrame;#          Basic Main Frame
package require ScrollWindow;#       Scrolled Window
package require DynamicHelp;#        Dynamic Help Code
package require IconImage;#          Icon image Loader / cache
package require ButtonBox;#          Button Box
package require CommonFunctions
package require Dialog
package require ROText

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
        size,width 50
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
        if {[regexp {^(.*)[[:space:]]([+-][02][0-9][0-9][0-9])} $date => gmt offset] > 0} {
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
            set rows [$articleList cget -height]
            #puts stderr "*** $self _ConfigureHeight: rows = $rows"
            set totalheight [expr {$headheight + ($rowheight * $rows)}]
            #puts stderr "*** $self _ConfigureHeight: totalheight = $totalheight"
            set rdiff [expr {int(ceil(double($diff) / double($rowheight)))}]
            #puts stderr "*** $self _ConfigureHeight: rdiff = $rdiff"
            set newrows [expr {$rows - $rdiff}]
            #puts stderr "*** $self _ConfigureHeight: newrows = $newrows"
            if {$newrows >= 0} {
                $articleList configure -height $newrows
            }
        }        
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



snit::widget ArticleViewer {
    hulltype tk::toplevel
    widgetclass Viewer
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

    variable articleNumber
    variable groupName
    variable pipeFP
    variable processing
    variable EOH
    variable cc {}

    
    variable fullHeadersP no
    
    component articleHeaderFrame
    component   headerButtons
    component articlePanes
    component   articleHeaderSW
    component     articleHeader
    component   articleBodySW
    component     articleBody
    component bodyButtons
    delegate method {buttons *} to bodyButtons
    
    typeconstructor {
        ttk::style configure ArticleHeaders -background gray -borderwidth 0 \
              -font "helvetica 8" -foreground black
        ttk::style configure ArticleBody -background white -borderwidth 0 \
              -font "helvetica 10" -foreground black
    }
    constructor {args} {
        set options(-parent) [from args -parent]
        set options(-spool)  [from args -spool]
        set options(-geometry) [from args -geometry [option get $win articleGeometry ArticleGeometry]]
        wm transient $win $options(-parent)
        wm protocol $win WM_DELETE_WINDOW [mymethod close]
        wm withdraw $win
        install articleHeaderFrame using ttk::labelframe \
              $win.articleHeaderFrame -labelanchor n;# -height 190
        pack $articleHeaderFrame -fill both;# -expand yes
        install headerButtons using ButtonBox \
              $articleHeaderFrame.headerButtons \
              -orient horizontal
        grid columnconfigure $articleHeaderFrame 0 -uniform cols -weight 1
        grid columnconfigure $articleHeaderFrame 1 -uniform cols -weight 1
        grid $headerButtons -row 0 -column 1 -sticky ew
        $headerButtons add ttk::button collectAddresses \
              -text {Collect Addresses} \
              -command [mymethod _collectAddresses]
        $headerButtons add ttk::checkbutton headerMode \
              -text {Full Headers?} \
              -command [mymethod _GetHeaderFields yes] \
              -onvalue yes -offvalue no \
              -variable [myvar fullHeadersP]
        install articlePanes using ttk::panedwindow $win.articlePanes \
              -orient vertical
        pack $articlePanes -fill both -expand yes
        install articleHeaderSW using ScrolledWindow \
              $articlePanes.articleHeaderSW \
              -scrollbar both -auto both
        #pack $articleHeaderSW  -fill both;# -expand yes
        $articlePanes add $articleHeaderSW -weight 1
        install articleHeader using ROText \
              [$articleHeaderSW getframe].articleHeader \
              -height 5 -tabs {1in right 1in left} \
              -wrap none
        $articleHeaderSW setwidget $articleHeader
        bind $articleHeader <<ThemeChanged>> [mymethod _restyle_articleHeader]
        $articleHeader tag configure key -foreground #505050
        $articleHeader tag configure val -foreground black
        install articleBodySW using ScrolledWindow $articlePanes.articleBodySW \
              -scrollbar both -auto both
        $articlePanes add $articleBodySW -weight 10
        #pack $articleBodySW  -fill both -expand yes
        install articleBody using ROText \
              [$articleBodySW getframe].articleBody -height 1
        $articleBodySW setwidget $articleBody
        bind $articleBody <<ThemeChanged>> [mymethod _restyle_articleBody]
        install bodyButtons using ButtonBox \
              $win.bodyButtons -orient horizontal
        pack $bodyButtons -fill x;# -expand no
        $bodyButtons add ttk::button close -text "Close" -command [mymethod close]
        $bodyButtons add ttk::button previous -text "Previous"
        $bodyButtons add ttk::button next -text "Next"
        $bodyButtons add ttk::button save -text "Save" -command [mymethod _Save]
        $bodyButtons add ttk::button file -text "File" -command [mymethod _File]
        $bodyButtons add ttk::button print -text "Print" -command [mymethod _Print]
        $bodyButtons add ttk::button decrypt -text "Decrypt" -command [mymethod _Decrypt]
        $self configurelist $args
        $self _restyle_articleHeader
        $self _restyle_articleBody
        set articleNumber -1
        set groupName {}
        $articleHeaderFrame configure -text $articleNumber
        if {[string length "$options(-geometry)"] > 0} {
            #puts stderr "*** $type create $self: options(-geometry) is $options(-geometry)"
            wm geometry $win "$options(-geometry)"
        }
    }
    method _restyle_articleHeader {} {
        $articleHeader configure \
              -background [ttk::style lookup ArticleHeaders -background] \
              -borderwidth [ttk::style lookup ArticleHeaders -borderwidth] \
              -font [ttk::style lookup ArticleHeaders -font] \
              -foreground [ttk::style lookup ArticleHeaders -foreground]
    }
    method _restyle_articleBody {} {
        $articleBody configure \
              -background [ttk::style lookup ArticleBody -background] \
              -borderwidth [ttk::style lookup ArticleBody -borderwidth] \
              -font [ttk::style lookup ArticleBody -font] \
              -foreground [ttk::style lookup ArticleBody -foreground]
    }
    method draw {} {
        wm deiconify $win
    }
    method close {} {
      wm withdraw $win
      $options(-spool) closeArticle
    }
    method setNumber {artNumber} {
      set articleNumber $artNumber
      $articleHeaderFrame configure -text "$artNumber"
    }
    method setGroup {group} {
      wm title $win "Reading group $group"
      set groupName $group
    }
    method NNTP_GetArticleToText {} {
      $articleBody delete 1.0 end-1c
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
      $options(-spool) srv_rdTxtTextBox $articleBody
      $self _GetHeaderFields
    }
    method readArticleFromFile {filename} {
      $articleBody delete 1.0 end-1c
      set file [open $filename "r"]
      set block [read $file 4096]
      while {[string length "$block"] > 0} {
	$articleBody insert end "$block"
	update idletasks
	set block [read $file 4096]
      }
      close $file
      $self _GetHeaderFields
    }
    method _CollectAddresses {} {
        #set to "[$toLE cget -text]"
        #if {[string length "$to"] > 0} {AddressBook::CheckNewAddresses "$to"}
        #set from "[$fromLE cget -text]"
        #if {[string length "$from"] > 0} {AddressBook::CheckNewAddresses "$from"}
        #if {[string length "$cc"] > 0} {AddressBook::CheckNewAddresses "$cc"}
    }
    method _GetHeaderFields {{refetching no}} {
        $articleHeader delete 1.0 end
        if {$refetching} {
            set lastline [expr {$EOH + 1}]
        } else {
            regexp {^([0-9]*).[0-9]*$} [$articleBody index end-1c] -> lastline
            set EOH 0
        }
        set win1252 no
        set headerbuffer {}
        for {set iline 1} {$iline < $lastline} {incr iline} {
            set line [$articleBody get "${iline}.0" "${iline}.0 lineend"]
            #puts stderr "*** ${self} _GetHeaderFields: line = '$line'"
            if {[regexp {^[[:space:]]} $line] > 0} {
                append headerbuffer "\n$line"
                continue
            } elseif {$headerbuffer ne ""} {
                #puts stderr "*** ${self} _GetHeaderFields: headerbuffer = '$headerbuffer'"
                if {[regexp {^([^:]+):[[:space:]]+(.*)$} $headerbuffer => key value] > 0} {
                    #puts stderr "*** ${self} _GetHeaderFields: key = $key, value = '$value'"
                    if {[lsearch {to cc from date subject} [string tolower $key]] >= 0 ||
                        $fullHeadersP} {
                        set vls [split $value "\n"]
                        $articleHeader insert end "\t$key\t" key [lindex $vls 0] val "\n"
                        foreach hl [lrange $vls 1 end] {
                            $articleHeader insert end "\t\t" key "$hl" val "\n"
                        }
                    }
                }
                if {[regexp -nocase {charset="??windows-1252"??} "$headerbuffer"] > 0} {
                    set win1252 yes
                }
            }
            set headerbuffer $line
            if {[string equal "$headerbuffer" {}]} {
                if {!$refetching} {set EOH $iline}
                break
            }
        }
        if {$refetching} return
        if {$win1252} {
            set tempFile /tmp/[pid].recoded
            if {[catch [list open "$tempFile" w] tmpFP]} {
                error "${type}::_GetHeaderFields: open \"$tempFile\" w: $tmpFP"
                return
            }
            set tempBlock "[$articleBody get "${EOH}.0" end-1c]"
            puts $tmpFP "$tempBlock"
            close $tmpFP
            if {[catch [list open "|recode < $tempFile windows-1252..iso-8859-1" r] pipeFP]} {
                file delete -force "$tempFile"
                error "${type}::_GetHeaderFields: open \"|recode < $tempFile windows-1252..iso-8859-1\" r: $pipeFP"
                return
            }
            set processing 1
            $articleBody delete "${EOH}.0" end-1c
            fileevent $pipeFP readable [mymethod _PipeToText]
            if {$processing > 0} {tkwait variable [myvar processing]}
            file delete -force "$tempFile"
        }
        
        regexp {^([0-9]*).[0-9]*$} [$articleBody index end-1c] -> lastline
        set fract [expr double($EOH) / double($lastline)]
        update idletasks
        #$articleBody see $EOH.0
        $articleBody yview moveto $fract
        #AddressBook::WriteAddressBookFileIfDirty
    }
    method _PipeToText {} {
        if {[gets $pipeFP line] < 0} {
            catch "close $pipeFP"
            incr processing -1
        } else {
            $articleBody insert end "$line\n"
        }
    }
    method _Save {} {
        set saveFile [tk_getSaveFile -defaultextension .text \
                      -filetypes { {{Text Files} {.text .txt} TEXT}
                      {{All Files} {*} }
                  } \
                        -parent $win -title {Enter filename: }]
        if {$saveFile == {}} {return}
        if {[catch "open $saveFile a" outfp]} {
            error "Cannot create or append to file $saveFile: $outfp"
            return
        }
        puts $outfp "[$articleBody get 1.0 end-1c]"
        close $outfp
    }
    method _File {} {
        if {[catch "$options(-spool) savedDirectory $groupName" baseDir]} {
            set baseDir [file join [$options(-spool) cget -savednews] \
                         [GroupName Path $groupName]]
        }
        if {![file exists "$baseDir"]} {file mkdir $baseDir}
        set folder [SelectFolderDialog draw \
                    -parent $win \
                    -basedirectory $baseDir \
                    -title "Select subfolder for $groupName"]
        if {[string length "$folder"] == 0} {return}
        set elements [file split $folder]
        while {[llength $elements] > 0} {
            set saveDir [file join $baseDir [lindex $elements 0]]
            set newname "${groupName}.[lindex $elements 0]"
            if {![file exists "$saveDir"]} {
                file mkdir $saveDir
                $options(-spool) addSavedDirectory $newname $saveDir
                $options(-spool) addSavedGroupLine $groupName $newname
            }
            set groupName $newname
            set baseDir $saveDir
            set elements [lrange $elements 1 end]
        }
        set highMessage [MessageList Highestnumber [glob -nocomplain "$saveDir/*"]]
        set mnum [expr $highMessage + 1]
        set saveFile [file join $saveDir $mnum]
        if {[catch "open $saveFile w" outfp]} {
            error "Cannot create file $saveFile: $outfp"
            return
        }
        puts $outfp "[$articleBody get 1.0 end-1c]"
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
        puts $outfp "[$articleBody get 1.0 end-1c]"
        catch "close $outfp" message
        if {[string length "$message"] > 0} {
            ServerMessageDialog draw \
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
            set line [$articleBody get "${iline}.0" "${iline}.0 lineend"]
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
            set line [$articleBody get "${iline}.0" "${iline}.0 lineend"]
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
        return "[$articleBody get ${EOH}.0 end-1c]"
    }
    method putBody {content} {
        $articleBody delete ${EOH}.0 end-1c
        $articleBody insert ${EOH}.0 "$content"
    }
}



snit::widgetadaptor SelectFolderDialog {
    typevariable dialogsByParent -array {}
    option -parent -readonly yes -default .
    option {-basedirectory baseDirectory BaseDirectory} \
          -validatemethod _CheckDirectory
    delegate option -title to hull
    
    component folderTreeSW
    component folderTree
    component selectedFolderFrame
    component   selectedFolderLabel
    component   selectedFolder
    
    method _CheckDirectory {option value} {
        if {[file isdirectory "$value"]} {
            return $value
        } else {
            error "Expected an existing directory for $option, got $value"
        }
    }
    
    constructor {args} {
        set options(-parent) [from args -parent]
        installhull using Dialog \
              -class SelectFolderDialog -bitmap questhead \
              -default ok -cancel cancel -modal local -transient yes \
              -parent $options(-parent) -side bottom
        #      puts stderr "*** $self constructor: hull = $hull, win = $win, winfo class $win = [winfo class $win]"
        $hull add  ok -text OK -command [mymethod _OK]
        $hull add cancel -text Cancel -command [mymethod _Cancel]
        $hull add help -text Help -command [list BWHelp::HelpTopic SelectFolderDialog]
        wm protocol $win WM_DELETE_WINDOW [mymethod _Cancel]
        install folderTreeSW using ScrolledWindow \
              [$hull getframe].folderTreeSW \
              -scrollbar vertical -auto vertical
        #      puts stderr "*** $self constructor: folderTreeSW = $folderTreeSW, winfo class $folderTreeSW = [winfo class $folderTreeSW]"
        pack   $folderTreeSW -expand yes -fill both
        install folderTree using ttk::treeview \
              [$folderTreeSW getframe].folderTree \
              -selectmode browse -show {tree}
        #      puts stderr "*** $self constructor: folderTree = $folderTree, winfo class $folTree = [winfo class $folderTree]"
        $folderTreeSW setwidget $folderTree
        $folderTree tag bind row <space> [mymethod _SelectFolder %x %y]
        $folderTree tag bind row <Button-1> [mymethod _SelectFolder %x %y]
        $folderTree tag bind row <Return> [mymethod _SelectAndReturnFolder %x %y]
        $folderTree tag bind row <Double-Button-1> [mymethod _SelectAndReturnFolder %x %y]
        #      puts stderr "*** $self constructor: about to install selectedFolderLE"
        install selectedFolderFrame using ttk::frame \
              [$hull getframe].selectedFolderFrame
        pack $selectedFolderFrame -fill x -expand yes
        install selectedFolderLabel using ttk::label \
              $selectedFolderFrame.selectedFolderLabel \
              -text {Selected Folder:} -anchor w
        pack $selectedFolderLabel -side left
        install selectedFolder using ttk::entry \
              $selectedFolderFrame.selectedFolder
        bind $selectedFolder <Tab> [mymethod _ExpandName]
        bind $selectedFolder <Return> [mymethod _OK]
        pack $selectedFolder -side left -fill x -expand yes
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
    method _SelectFolder {x y} {
        set selection [$folderTree identify row $x $y]
        $selectedFolder delete 0 end
        $selectedFolder insert end [$folderTree item $selection -text]
    }
    method _SelectAndReturnFolder {x y} {
        set selection [$folderTree identify row $x $y]
        $selectedFolder delete 0 end
        $selectedFolder insert end [$folderTree item $selection -text]
        $self _OK
    }
    method _ExpandName {} {
        set current [$selectedFolder get]
        set files [lsort -dictionary \
                   [glob -nocomplain -directory $options(-basedirectory) \
                    -tails -types d "${current}*"]]
        if {[llength $files] == 0} {return}
        set nextletters [list]
        foreach f $files {
            if {[regexp "^${current}(.)" $f => letter] > 0} {
                if {[lsearch $nextletters $letter] < 0} {
                    lappend nextletters $letter
                }
            }
        }
        if {[llength $nextletters] == 1} {
            $selectedFolder insert end [lindex $nextletters 0]
            $self _ExpandName
        }
        return
    }        
    method _Draw {args} {
        $self configurelist $args
        if {![info exists options(-basedirectory)]} {
            error "-basedirectory is a required option!"
        }
        $folderTree delete [$folderTree children {}]
        _fillFolderTree $folderTree $options(-basedirectory) *
        switch -exact -- [$hull draw] {
            ok {return "[$selectedFolder get]"}
            cancel -
            default {return {}}
        }
    }
    proc _fillFolderTree {ft base pattern {parent {}}} {
        #puts stderr "*** SelectFolderDialog::_fillFolderTree: base = $base, pattern = $pattern"
        #puts stderr "*** SelectFolderDialog::_fillFolderTree: parent is $parent"
        foreach folder [lsort -dictionary \
                        [glob -nocomplain -directory $base \
                         -tails -types d $pattern]] {
            #puts stderr "*** SelectFolderDialog::_fillFolderTree: folder is $folder"
            if {[file writable [file join $base $folder]]} {
                #puts stderr "*** SelectFolderDialog::_fillFolderTree: $folder is writable"
                set child [$ft insert $parent end -text $folder \
                           -open no -tags row]
                #puts stderr "*** SelectFolderDialog::_fillFolderTree: child is $child"
                _fillFolderTree $ft $base [file join $folder *] $child
            }
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


namespace eval Articles {

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
	set pattern [SearchPatternDialog draw \
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
