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
package require HTMLHelp
package require mime
package require HTMLArticle
package require base64
snit::macro ArticleListMethods {} {
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
    component articleListSW
    component   articleList
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
    method insertArticleHeader {artnumber nread subject from date lines size _messageid _inreplyto} {
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
        if {[regexp {^(.*)[[:space:]]([+-][012][0-9][0-9][0-9])} $date => gmt offset] > 0} {
            if {[catch {set timestamp [clock scan $gmt -gmt yes]}]} {return}
        } else {
            if {[catch {set timestamp [clock scan $date]}]} {return}
        }
        set article_number($_messageid) $artnumber
        set messageid($artnumber) $_messageid
        set inreplyto($_messageid) $_inreplyto
        set nreads($_messageid) $nread
        lappend subjects($subject) $_messageid
        lappend froms($from) $_messageid
        #puts stderr "*** $self insertArticleHeader: date = $date, timestamp = $timestamp"
        lappend dates($timestamp) $_messageid
        $articleList insert {} end -id $_messageid -text {} \
              -values [list $artnumber $subject $from $date $lines $size] \
              -tags   article
    }
    method _constructArticleList {parent args} {
        set selectmode [from args -selectmode browse]
        install articleListSW using ScrolledWindow $parent.articleListSW \
              -scrollbar vertical -auto vertical
        pack $articleListSW -fill both -expand yes
        install articleList using ttk::treeview \
              [$articleListSW getframe].articleList -columns $columns \
              -displaycolumns $columns -show {tree headings} \
              -selectmode $selectmode
        $articleListSW setwidget $articleList
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
    method seeTop {} {
        $articleList see [lindex [$articleList children {}] 0]
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
        $self seeTop
    }
    method _sortByArtNumber {} {
        #puts stderr "*** $self _sortByArtNumber"
        $articleList detach [$articleList children {}]
        foreach an [lsort -integer [array names messageid]] {
            $articleList item $messageid($an) -open no
            $articleList move $messageid($an) {} end
        }
        $self seeTop
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
        $self seeTop
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
        $self seeTop
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
        $self seeTop
    }
}    

snit::widget ArticleListFrame {
    hulltype ttk::frame
    ArticleListMethods
    delegate option -height to articleList
    delegate option -takefocus to articleList
    delegate method selection to articleList
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
    option -imap4buttons -readonly yes -type snit::boolean
    component articleIMapButtonBox
    typevariable articleIMapButtons -array {
        move {-text {Move To Folder} -command "[mymethod _MoveToFolder]"}
        copy {-text {Copy To Folder} -command "[mymethod _CopyToFolder]"}
        trash {-text {Move To Trash} -command "[mymethod _MoveToTrash]"}
    }
    typevariable articleIMapButtonsList {move copy trash}
    method _ReadArticleAt {x y} {
        set selection [$articleList identify row $x $y]
        #puts stderr "*** $self _ReadArticleAt: selection is $selection"
        #puts stderr "*** $self _ReadArticleAt: info exists article_number($selection) = [info exists article_number($selection)]"
        $spoolwindow _ReadArticle $selection
    }
    option -spool -readonly yes -type SpoolWindow
    component spoolwindow
    delegate method * to spoolwindow
    delegate method {artlistButtonBox *} to artlistButtonBox except {add}
    delegate option -artlistbuttonstate to artlistButtonBox as -state
    delegate method {articleButtonBox *} to articleButtonBox except {add}
    delegate option -articlebuttonstate to articleButtonBox as -state
    delegate method {articleIMapButtonBox *} to articleIMapButtonBox except {add}
    delegate option -articleimapbuttonstate to articleIMapButtonBox as -state
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
        $self _constructArticleList $win
        $articleList tag bind article <Double-ButtonPress-1> [mymethod _ReadArticleAt %x %y]
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
        # extra imap buttonbox
        if {$options(-imap4buttons)} {
            install articleIMapButtonBox using ButtonBox $win.articleIMapButtonBox
            pack $articleIMapButtonBox -fill x
            foreach ab $articleIMapButtonsList {
                set opts [subst $articleIMapButtons($ab)]
                eval [list $articleIMapButtonBox add ttk::button $ab] $opts
            }
            $articleIMapButtonBox configure -state disabled
        }
        set spoolwindow $options(-spool)
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
}



snit::widget ArticleViewer {
    hulltype tk::toplevel
    widgetclass Viewer
    option -parent -readonly yes -default .
    option -spool  -readonly yes -type SpoolWindow
    option -imap4buttons -readonly yes -type snit::boolean
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
    component     articleHTMLBody
    component bodyButtons
    component imap4Buttons
    delegate method {buttons *} to bodyButtons
    delegate method {imap4buttons *} to imap4Buttons
    
    typevariable PrintCommand
    typeconstructor {
        set PrintCommand "[option get . printCommand PrintCommand]"
        ttk::style configure ArticleHeaders -background gray -borderwidth 0 \
              -font "Courier 8" -foreground black
        ttk::style configure ArticleBody -background white -borderwidth 0 \
              -font "Courier 8" -foreground black
    }
    constructor {args} {
        set options(-parent) [from args -parent]
        set options(-spool)  [from args -spool]
        set options(-imap4buttons)  [from args -imap4buttons]
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
        install articleHTMLBody using HTMLArticleBodyView \
              $articlePanes.articleHTMLBody
        #pack $articleBodySW  -fill both -expand yes
        install articleBody using ROText \
              [$articleBodySW getframe].articleBody -height 1
        $articleBodySW setwidget $articleBody
        bind $articleBody <<ThemeChanged>> [mymethod _restyle_articleBody]
        install bodyButtons using ButtonBox \
              $win.bodyButtons -orient horizontal
        pack $bodyButtons -fill x;# -expand no
        $bodyButtons add ttk::button close -text "Close" -underline 0 -command [mymethod close]
        bind $articleBody <C> [list $bodyButtons invoke close]
        bind $articleBody <c> [list $bodyButtons invoke close]
        $bodyButtons add ttk::button previous -text "Previous" -underline 0
        bind $articleBody <P> [list $bodyButtons invoke previous]
        bind $articleBody <p> [list $bodyButtons invoke previous]
        $bodyButtons add ttk::button next -text "Next" -underline 0
        bind $articleBody <N> [list $bodyButtons invoke next]
        bind $articleBody <n> [list $bodyButtons invoke next]
        $bodyButtons add ttk::button save -text "Save" -command [mymethod _Save]
        $bodyButtons add ttk::button file -text "File" -underline 0 -command [mymethod _File]
        bind $articleBody <F> [list $bodyButtons invoke file]
        bind $articleBody <f> [list $bodyButtons invoke file]
        $bodyButtons add ttk::button print -text "Print" -command [mymethod _Print]
        $bodyButtons add ttk::button decrypt -text "Decrypt" -underline 0 -command [mymethod _Decrypt]
        bind $articleBody <D> [list $bodyButtons invoke decrypt]
        bind $articleBody <d> [list $bodyButtons invoke decrypt]
        if {$options(-imap4buttons)} {
            install imap4Buttons using ButtonBox \
                  $win.imap4Buttons -orient horizontal
            pack $imap4Buttons -fill x;# -expand no
            $imap4Buttons add ttk::button move -text {Move To Folder} -command "[mymethod _MoveToFolder]"
            $imap4Buttons add ttk::button copy -text {Copy To Folder} -command "[mymethod _CopyToFolder]"
            $imap4Buttons add ttk::button trash -text {Move To Trash} -command "[mymethod _MoveToTrash]"
            $imap4Buttons add ttk::button empty -text {Empty Trash} -command "[mymethod _EmptyTrash]"
            $imap4Buttons add ttk::button delete -text {Delete Folder} -command "[mymethod _DeleteFolder]"
            $imap4Buttons add ttk::button new -text {New Folder} -command "[mymethod _NewFolder]"
        }
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
        focus $articleBody
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
      focus $articleBody
    }
    method IMap4_GetArticleToText {} {
        #puts stderr "*** $self IMap4_GetArticleToText"
        $articleBody delete 1.0 end-1c
        set imapserverchannel [$options(-spool) IMap4ServerChannel]
        catch {::imap4::close $imapserverchannel}
        ::imap4::examine $imapserverchannel $groupName
        ::imap4::fetch $imapserverchannel $articleNumber:$articleNumber HEADER TEXT
        $articleBody insert end [regsub -all "\r" [::imap4::msginfo $imapserverchannel $articleNumber HEADER] {}]
        $articleBody insert end [regsub -all "\r" [::imap4::msginfo $imapserverchannel $articleNumber TEXT] {}]
        $self _GetHeaderFields
        focus $articleBody
        ::imap4::close $imapserverchannel
    }
    proc matchencoding {enc} {
        #puts stderr "*** matchencoding: enc is '$enc'"
        if {$enc eq {}} {return ascii}
        set encs [encoding names]
        set i [lsearch -regexp -nocase $encs $enc]
        if {$i >= 0} {
            #puts stderr "*** matchencoding: i = $i, lindex $encs $i is '[lindex $encs $i]'"
            return [lindex $encs $i]
        } else {
            return ascii
        }
    }
    proc getCharset {mimepart} {
        #puts stderr "*** getCharset $mimepart"
        if {"params" in [::mime::getproperty $mimepart -names]} {
            set params [::mime::getproperty $mimepart params]
            #puts stderr "*** getCharset: params is $params"
            set c [lsearch -exact $params charset]
            #puts stderr "*** getCharset: c = $c"
            if {$c >= 0} {
                incr c
                set match [matchencoding [lindex $params $c]]
                #puts "*** getCharset returns '$match'"
                return $match
            } else {
                return ascii
            }
        } else {
            return ascii
        }
    }
    proc _insertBodyPart {plainbodyText htmlViewer p mtype lastContentType} {
        set pContent [::mime::getproperty $p content]
        
        if {$pContent eq {text/plain}} {
            catch {
                 set lastContentType [_insertBody $plainbodyText $htmlViewer $p \
                                      $lastContentType]
                 if {$mtype eq "alternative"} {
                 return $lastContentType
             }}
        }
        if {$pContent eq {text/html}} {
            set lastContentType [_insertBody $plainbodyText $htmlViewer $p \
                                 $lastContentType]
            if {$mtype eq "alternative"} {
                return $lastContentType
            }
        }
        if {[string match -nocase "multipart/*" $pContent]} {
            set lastContentType [_insertBody $plainbodyText $htmlViewer $p \
                                 $lastContentType]
            if {$mtype eq "alternative"} {
                return $lastContentType
            }
        }
        if {$lastContentType eq ""} {
            $plainbodyText insert end \
                  "No text/plain or text/html part!\n"
        }
        return $lastContentType
    }
    proc _insertBody {plainbodyText htmlViewer messagePart {lastContentType {}}} {
        #puts stderr "*** _insertBody $plainbodyText $htmlViewer $messagePart $lastContentType"
        #puts stderr "*** _insertBody: ::mime::getproperty $messagePart content is [::mime::getproperty $messagePart content]"
        switch -glob [::mime::getproperty $messagePart content] {
            text/plain {
                if {$lastContentType eq ""} {
                    $plainbodyText insert end "Content-Type: text/plain\n\n"
                }
                set temp [::mime::getbody $messagePart]
                #puts stderr "*** _insertBody temp = '$temp'"
                if {[string length $temp] == 0} {
                    error "Empty message part!"
                }
                $plainbodyText insert end \
                      "[encoding convertfrom [getCharset $messagePart] $temp]\n"
            }
            text/html {
                if {$lastContentType eq ""} {
                    $plainbodyText insert end "Content-Type: text/html\n\n"
                    #puts stderr "*** _insertBody: htmlViewer is \"$htmlViewer\""
                    if {$htmlViewer ne ""} {
                        $htmlViewer configure -htmlbody [encoding convertfrom [getCharset $messagePart] [::mime::getbody $messagePart]]
                    }
                    $plainbodyText insert end [encoding convertfrom [getCharset $messagePart] [::mime::getbody $messagePart]]
                }
            }
            multipart/* {
                regexp {^multipart/(.*)$} [::mime::getproperty $messagePart content] => mtype
                foreach p [::mime::getproperty $messagePart parts] {
                    set lastContentType [_insertBodyPart $plainbodyText $htmlViewer $p $mtype $lastContentType]
                }
            }
            default {
                $plainbodyText insert end \
                      "No text/plain or text/html part!\n"
            }
        }
        return [::mime::getproperty $messagePart content]
    }
    proc _insertAttachedMessage {message articleBody} {
        #puts stderr "*** _insertAttachedMessage $message $articleBody"
        
        foreach h [::mime::getheader $message -names] {
            if {[regexp {^From } $h] > 0} {
                $articleBody insert end "$h:[lindex [::mime::getheader $message $h] 0]\n"
            } else {
                foreach hv [::mime::getheader $message $h] {
                    $articleBody insert end "$h: $hv\n"
                }
            }
        }
        _insertBody $articleBody {} $message
    }
    proc decodeHeader {headerContent} {
        #puts stderr "*** decodeHeader $headerContent"
        while {[regexp {=\?([^?]+)\?([^?])\?([^?]+)\?=} $headerContent replace \
                charset encoding text] > 0} {
            #puts stderr "*** decodeHeader: charset is $charset, encoding is $encoding, text is $text, replace is $replace"
            switch $encoding {
                B {
                    set text [::base64::decode $text]
                }
                Q {
                    set text [::mime::qp_decode $text]
                }
            }
            set charset [::mime::reversemapencoding $charset]
            catch {
                set text [encoding convertfrom $charset $text]
            }
            #puts stderr "*** decodeHeader: text is now $text"
            #_printBytesHex "*** decodeHeader: text is now (hexbytes)" $text
            set first [string first $replace $headerContent]
            set last  [expr {$first + [string length $replace] - 1}]
            set headerContent [string replace $headerContent $first $last $text]
            #puts stderr "*** decodeHeader: headerContent is now '$headerContent'"
            #_printBytesHex "*** decodeHeader: headerContent is now (hexbytes)" "$headerContent"
        }
        set headerContent [_stripU16andCC $headerContent]
        #puts stderr "*** decodeHeader: headerContent after _stripU16andCC: '$headerContent'"
        #_printBytesHex "*** decodeHeader: headerContent after _stripU16andCC:" $headerContent
        return $headerContent
    }
    proc _stripU16andCC {string} {
        set bytes [split $string {}]
        set result {}
        foreach b $bytes {
            scan $b %c _b
            if {$_b < 32 || $_b > 127} {
                append result "?"
            } else {
                append result "$b"
            }
        }
        return $result
    }
    proc _printBytesHex {message string} {
        set bytes [split $string {}]
        puts -nonewline stderr $message
        foreach b $bytes {
            scan $b %c _b
            puts -nonewline stderr [format { %02x} $_b]
        }
        puts stderr {}
    }
        
    method readArticleFromFile {filename} {
        $articleBody delete 1.0 end-1c
        catch {$articlePanes forget $articleHTMLBody}  
        #puts stderr "*** $self readArticleFromFile $filename"
        set message [::mime::initialize -file $filename]
        #puts stderr "*** $self readArticleFromFile: message is $message"
        foreach h [::mime::getheader $message -names] {
            #puts stderr "*** $self readArticleFromFile: h is $h"
            if {[regexp {^From } $h] > 0} {
                $articleBody insert end "$h:[decodeHeader [lindex [::mime::getheader $message $h] 0]]\n"
            } else {
                foreach hv [::mime::getheader $message $h] {
                    #puts stderr "*** $self readArticleFromFile:  hv is $hv"
                    $articleBody insert end "$h: [decodeHeader $hv]\n"
                }
            }
            #update 
        }
        #$articleBody insert end "\n"
        #puts stderr "*** $self readArticleFromFile: about to insert body"
        if {[_insertBody $articleBody $articleHTMLBody $message] eq "text/html"} {
            $articlePanes insert $articleBodySW $articleHTMLBody -weight 10
        }
        if {[string match -nocase multipart/* [::mime::getproperty $message content]]} {
            $self _processAttachments $message
        }
        ::mime::finalize $message
        $self _GetHeaderFields
        focus $articleBody
    }
    method _processAttachments {message} {
        
        #puts stderr "*** $self _processAttachments: content property of message is [::mime::getproperty $message content]"
        #
        # Attachments
        #
        set attachmentDir [file join /usr/tmp/ [clock seconds] $groupName $articleNumber Attachments]
        foreach p [::mime::getproperty $message parts] {
            #puts stderr "*** $self _processAttachments (attachment loop): p is $p"
            #puts stderr "*** $self _processAttachments: properties of $p: [::mime::getproperty $p -names]"
            #puts stderr "*** $self _processAttachments: headers of $p: [::mime::getheader $p -names]"
            #puts stderr "*** $self _processAttachments: content of $p: [::mime::getproperty $p content]"
            #puts stderr "*** $self _processAttachments: params of $p: [::mime::getproperty $p params]"
            if {[::mime::getproperty $p content] eq {message/rfc822}} {
                #puts stderr "*** $self _processAttachments message/rfc822 attachment"
                _insertAttachedMessage [lindex [::mime::getproperty $p parts] 0] $articleBody
            } elseif {[string match -nocase "multipart/*" [::mime::getproperty $p content]]} {
                # recursion
                $self _processAttachments $p
            } elseif {"Content-Disposition" in [::mime::getheader $p -names]} {
                #puts stderr "*** $self _processAttachments: Content-Disposition of $p is [::mime::getheader $p Content-Disposition]"
                set disposition [::mime::getheader $p Content-Disposition]
                if {"Content-Description" in [::mime::getheader $p -names]} {
                    set description [::mime::getheader $p Content-Description]
                } else {
                    set description {}
                }
                set isAttach no
                set FileName {}
                set pattern [format {^%c([^%c]*)%c$} 123 125 125]
                #puts stderr "*** $self _processAttachments: pattern = $pattern"
                if {[regexp $pattern $disposition => bracestrip] > 0} {
                    set disposition $bracestrip
                }
                foreach field [split $disposition {;}] {
                    #puts stderr "*** $self _processAttachments: field = '$field'"
                    set field [string trim $field]
                    set key $field
                    set value {}
                    set exp [format {^([^=]+)=%c([^%c]+)%c$} 34 34 34]
                    set match [regexp $exp $field => key value]
                    #puts stderr "*** $self _processAttachments: match = $match"
                    set key [string tolower $key]
                    #puts stderr "*** $self _processAttachments: key = $key"
                    #puts stderr "*** $self _processAttachments: value = $value"
                    if {$key eq "attachment"} {
                        set isAttach yes
                    }
                    if {$key eq "filename"} {
                        set FileName $value
                        if {[regexp {^"(.*)"$} $FileName => noquotes] > 0} {
                            set FileName $noquotes
                        }
                        #puts stderr "*** $self _processAttachments: FileName is '$FileName'"
                        if {[regexp {^=\?([^?]+)\?B\?(.*)\?=$} $FileName => enc encstr] > 0} {
                            #puts stderr "*** $self _processAttachments: enc = '$enc'"
                            #puts stderr "*** $self _processAttachments (base64): encstr = '$encstr'"
                            set FileName [encoding convertfrom \
                                          [matchencoding $enc] \
                                          [base64::decode $encstr]]
                        } elseif {[regexp {^=\?([^?]+)\?Q\?(.*)\?=$} $FileName => enc encstr] > 0} {
                            #puts stderr "*** $self _processAttachments: enc = '$enc'"
                            #puts stderr "*** $self _processAttachments (QP): encstr = '$encstr'"
                            set FileName [encoding convertfrom \
                                          [matchencoding $enc] \
                                          [::mime::qp_decode $encstr]]
                        } elseif {[regexp {^=\?([^?]+)\?(.*)\?=$}  $FileName => enc encstr] > 0} {
                            #puts stderr "*** $self _processAttachments: enc = '$enc'"
                            #puts stderr "*** $self _processAttachments (none): encstr = '$encstr'"
                            set FileName [encoding convertfrom \
                                          [matchencoding $enc] \
                                          $encstr]
                        }
                    }
                }
                if {!$isAttach} {continue}
                if {![file exists $attachmentDir]} {
                    file mkdir $attachmentDir
                }
                #puts stderr "*** $self _processAttachments: Attachment ([::mime::getproperty $p content]) => $FileName"
                if {$FileName eq ""} {
                    set params [::mime::getproperty $p params]
                    #puts stderr "*** $self _processAttachments: FileName is null, params are: $params"
                    set nameIndex [lsearch -exact $params name]
                    if {$nameIndex >= 0} {
                        set FileName [string trim [lindex $params [expr {$nameIndex + 1}]]]
                    } else  {        
                        set FileName "attachment[clock seconds]"
                    }
                    #puts stderr "*** $self _processAttachments: FileName is now '$FileName'"
                    if {[regexp {^=\?([^?]+)\?B\?(.*)\?=$} $FileName => enc encstr] > 0} {
                        #puts stderr "*** $self _processAttachments: enc = '$enc'"
                        #puts stderr "*** $self _processAttachments (base64): encstr = '$encstr'"
                        set FileName [encoding convertfrom \
                                      [matchencoding $enc] \
                                      [base64::decode $encstr]]
                    } elseif {[regexp {^=\?([^?]+)\?Q\?(.*)\?=$} $FileName => enc encstr] > 0} {
                        #puts stderr "*** $self _processAttachments: enc = '$enc'"
                        #puts stderr "*** $self _processAttachments (QP): encstr = '$encstr'"
                        set FileName [encoding convertfrom \
                                      [matchencoding $enc] \
                                      [::mime::qp_decode $encstr]]
                    } elseif {[regexp {^=\?([^?]+)\?(.*)\?=$}  $FileName => enc encstr] > 0} {
                        #puts stderr "*** $self _processAttachments: enc = '$enc'"
                        #puts stderr "*** $self _processAttachments (none): encstr = '$encstr'"
                        set FileName [encoding convertfrom \
                                      [matchencoding $enc] \
                                      $encstr]
                    }
                }
                #puts stderr "*** $self _processAttachments: FileName is now '$FileName'"
                if {[catch {open [file join $attachmentDir $FileName] w} outfp]} {
                    set FileName "attachment[clock seconds]"
                    set outfp [open [file join $attachmentDir $FileName] w]
                }
                if {![string match -nocase "text/*" [::mime::getproperty $p content]]} {
                    fconfigure $outfp -translation binary
                }
                puts -nonewline $outfp [::mime::getbody $p]
                close $outfp
                $articleBody insert end "\nAttachment saved: [file join $attachmentDir $FileName] ([::mime::getproperty $p content])\n"
            }
        }
    }
    method _collectAddresses {} {
        set lastline [expr {$EOH + 1}]
        set headerbuffer {}
        for {set iline 1} {$iline <= $lastline} {incr iline} {
            set line [$articleBody get "${iline}.0" "${iline}.0 lineend"]
            if {[regexp {^[[:space:]]} $line] > 0} {
                append headerbuffer "\n$line"
                continue
            } elseif {$headerbuffer ne ""} {
                #puts stderr "*** $self _collectAddresses: headerbuffer = '$headerbuffer'"
                if {[regexp {^([^:]+):[[:space:]]+(.*)$} $headerbuffer => key value] > 0} {
                    if {[lsearch {to cc from} [string tolower $key]] >= 0} {
                        #puts stderr "*** $self _collectAddresses: key = $key, value = '$value'"
                        AddressBook CheckNewAddresses "$value"
                    }
                }
                set headerbuffer $line
                if {[string equal "$headerbuffer" {}]} {
                    break
                }
            }
        }
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
        AddressBook WriteAddressBookFileIfDirty
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
    method _MoveToFolder {} {
        set imapserverchannel [$options(-spool) IMap4ServerChannel]
        catch {::imap4::close $imapserverchannel}
        set dest [SelectIMap4FolderDialog draw -parent $win \
                  -imap4chan $imapserverchannel]
        if {$dest eq ""} {return}
        if {$dest eq $groupName} {return}
        ::imap4::select $imapserverchannel $groupName
        ::imap4::copy $imapserverchannel $articleNumber $dest
        ::imap4::store $imapserverchannel $articleNumber:$articleNumber +FLAGS "Deleted"
        ::imap4::close $imapserverchannel
    }
    method _CopyToFolder {} {
        set imapserverchannel [$options(-spool) IMap4ServerChannel]
        catch {::imap4::close $imapserverchannel}
        set dest [SelectIMap4FolderDialog draw -parent $win \
                  -imap4chan $imapserverchannel]
        if {$dest eq ""} {return}
        if {$dest eq $groupName} {return}
        ::imap4::examine $imapserverchannel $groupName
        ::imap4::copy $imapserverchannel $articleNumber $dest
        ::imap4::close $imapserverchannel
    }
    method _MoveToTrash {} {
        set imapserverchannel [$options(-spool) IMap4ServerChannel]
        catch {::imap4::close $imapserverchannel}
        set dest Trash
        if {$dest eq $groupName} {return}
        ::imap4::select $imapserverchannel $groupName
        ::imap4::copy $imapserverchannel $articleNumber $dest
        ::imap4::store $imapserverchannel $articleNumber:$articleNumber +FLAGS "Deleted"
        ::imap4::close $imapserverchannel
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
        #set passPhrase [EnterPassPhraseDialog draw -parent $win]
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
        gpgme_check_version 0.0.0
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
        set passPhrase [EnterPassPhraseDialog draw -parent $win \
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

snit::widgetadaptor SelectIMap4FolderDialog {
    typevariable dialogsByParent -array {}
    option -parent -readonly yes -default .
    option -imap4chan -default {}
    delegate option -title to hull
    
    component folderTreeSW
    component folderTree
    component selectedFolderFrame
    component   selectedFolderLabel
    component   selectedFolder
    
    constructor {args} {
        set options(-parent) [from args -parent]
        installhull using Dialog \
              -class SelectIMap4FolderDialog -bitmap questhead \
              -default ok -cancel cancel -modal local -transient yes \
              -parent $options(-parent) -side bottom
        #      puts stderr "*** $self constructor: hull = $hull, win = $win, winfo class $win = [winfo class $win]"
        $hull add  ok -text OK -command [mymethod _OK]
        $hull add cancel -text Cancel -command [mymethod _Cancel]
        $hull add help -text Help -command [list HTMLHelp help "Select Folder Dialog"]
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
        #bind $selectedFolder <Tab> "[mymethod _ExpandName];break"
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
    method _Draw {args} {
        $self configurelist $args
        if {$options(-imap4chan) eq {}} {return {}}
        $folderTree delete [$folderTree children {}]
        _fillFolderTree $folderTree $options(-imap4chan) *
        switch -exact -- [$hull draw] {
            ok {return "[$selectedFolder get]"}
            cancel -
            default {return {}}
        }
    }
    #method _ExpandName {} {
    #    set current [$selectedFolder get]
    #    
    #    set folders [lsort -dictionary [::imap4::folders $options(-imap4chan) -inline "" "${current}*"]]
    #    puts stderr "*** $self _ExpandName: current = $current, folders = $folders"
    #    if {[llength $folders] == 0} {return}
    #    set nextletters [list]
    #    foreach fF $folders {
    #        lassign $fF folder flags
    #        puts stderr "*** $self _ExpandName: folder is $folder"
    #        regsub {^"(+*)"$} $folder => folder
    #        if {[regexp "^${current}(.)" $folder => letter] > 0} {
    #            if {[lsearch $nextletters $letter] < 0} {
    #                lappend nextletters $letter
    #            }
    #        }
    #    }
    #    puts stderr "*** $self _ExpandName: nextletters is $nextletters"
    #    if {[llength $nextletters] == 1} {
    #        $selectedFolder insert end [lindex $nextletters 0]
    #        $self _ExpandName
    #    }
    #    return
    #}
    proc _fillFolderTree {ft imap4chan pattern {parent {}}} {
        #puts stderr "*** SelectIMap4FolderDialog::_fillFolderTree: base = $base, pattern = $pattern"
        #puts stderr "*** SelectIMap4FolderDialog::_fillFolderTree: parent is $parent"
        foreach folderWithFlags [lsort -dictionary [::imap4::folders $imap4chan -inline "" $pattern]] {
            lassign $folderWithFlags folder flags
            set folder [regsub {^"} $folder {}]
            set folder [regsub {"$} $folder {}]
            set child [$ft insert $parent end -text $folder \
                       -open no -tags row]
            #puts stderr "*** SelectFolderDialog::_fillFolderTree: child is $child"
        }
    }
    typemethod draw {args} {
        set parent [from args -parent {.}]
        if {[catch "set dialogsByParent($parent)" dialog]} {
            if {[string equal [string index $parent end] {.}]} {
                set dialog ${parent}selectIMap4FolderDialog
            } else {
                set dialog ${parent}.selectIMap4FolderDialog
            }
            set dialog [eval [list $type \
                              create ${dialog} -parent $parent] \
                              $args]
        }
        return "[eval [list $dialog _Draw] $args]"
    }
}
        

snit::widgetadaptor SelectFolderDialog {
    typevariable dialogsByParent -array {}
    option -parent -readonly yes -default .
    option {-basedirectory baseDirectory BaseDirectory} -type Directory
    delegate option -title to hull
    
    component folderTreeSW
    component folderTree
    component selectedFolderFrame
    component   selectedFolderLabel
    component   selectedFolder
    
    constructor {args} {
        set options(-parent) [from args -parent]
        installhull using Dialog \
              -class SelectFolderDialog -bitmap questhead \
              -default ok -cancel cancel -modal local -transient yes \
              -parent $options(-parent) -side bottom
        #      puts stderr "*** $self constructor: hull = $hull, win = $win, winfo class $win = [winfo class $win]"
        $hull add  ok -text OK -command [mymethod _OK]
        $hull add cancel -text Cancel -command [mymethod _Cancel]
        $hull add help -text Help -command [list HTMLHelp help "Select Folder Dialog"]
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
        pack $selectedFolderFrame -fill x
        install selectedFolderLabel using ttk::label \
              $selectedFolderFrame.selectedFolderLabel \
              -text {Selected Folder:} -anchor w
        pack $selectedFolderLabel -side left
        install selectedFolder using ttk::entry \
              $selectedFolderFrame.selectedFolder
        bind $selectedFolder <Tab> "[mymethod _ExpandName];break"
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
        $folderTree delete [$folderTree children {}]
        _fillFolderTree $folderTree $options(-basedirectory) [$selectedFolder get]*
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


snit::widgetadaptor SearchArticlesDialog {

    ArticleListMethods
    component selectedArticleFrame
    component   selectedArticleLabel
    component   selectedArticle

    
    option {-grouptree groupTree GroupTree} -readonly yes \
					    -type GroupTreeFrame
    option -pattern -readonly yes -default .
    option -group -readonly yes
    option {-readarticle readArticle ReadArticle} \
		-readonly yes
    option -parent -readonly yes -default .
    delegate option -title to hull
    constructor {args} {
        installhull using Dialog -parent [from args -parent] \
              -class SearchArticlesDialog \
              -bitmap questhead -default read -cancel dismis \
              -modal none -transient yes -side bottom
        $hull add dismis -text Dismis -command [mymethod _Dismis]
        $hull add read   -text {Read Selected Article} \
              -command [mymethod _ReadArticle]
        $hull add  help   -text Help   \
              -command [list HTMLHelp help "Search Articles Dialog"]
        wm protocol $win WM_DELETE_WINDOW [mymethod _Dismis]
        $self _constructArticleList [$hull getframe]
        $articleList tag bind article <space> [mymethod _SelectArticle %x %y]
        $articleList tag bind article <1> [mymethod _SelectArticle %x %y]
        
        install selectedArticleFrame using ttk::frame \
              [$hull getframe].selectedArticleFrame
        pack $selectedArticleFrame -fill x
        install selectedArticleLabel using ttk::label \
              $selectedArticleFrame.selectedArticleLabel \
              -text {Selected Article:} -anchor w
        pack $selectedArticleLabel -side left
        install selectedArticle using ttk::entry \
              $selectedArticleFrame.selectedArticle -state readonly \
              -textvariable [myvar currentArticleNumber]
        pack $selectedArticle -side left -fill x -expand yes
        $self configurelist $args
        if {[string equal "$options(-readarticle)" {}]} {
            $hull itemconfigure read -state disabled
        } else {
            $articleList tag bind article <Double-Button-1> [mymethod _SelectAndReadArticle %x %y]
            bind $articleList <Double-Button-1> {break}
            $articleList tag bind article <Return> [mymethod _SelectAndReadArticle %x %y]
        }
        if {[string equal "$options(-grouptree)" {}]} {
            error "-grouptree is a required option!"
        }
        if {[string equal "$options(-group)" {}]} {
            error "-group is a required option!"
        }
        $options(-grouptree) insertArticleList $self $options(-group) "$options(-pattern)" 1
        $hull draw
    }
    method _Dismis {} {
        destroy $self
    }
    method _SelectArticle {x y} {
        set selection [$articleList identify row $x $y]
        set currentArticleNumber $article_number($selection)
    }
    method _SelectAndReadArticle {x y} {
        $self _SelectArticle $x $y
        $self _ReadArticle
    }
    method _ReadArticle {} {
        set artNumber $currentArticleNumber
        if {[string length "$artNumber"] == 0} {return}
        catch {uplevel #0 "eval $options(-readarticle) $artNumber"}
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
    ArticleListMethods
    option {-grouptree groupTree GroupTree} -readonly yes \
          -type GroupTreeFrame
    option -group -readonly yes
    option -selectmode -readonly yes -default browse \
          -type {snit::enum -values {browse extended}}
    option -parent -readonly yes -default .
    delegate option -title to hull
    delegate option -geometry to hull
    constructor {args} {
        installhull using Dialog -parent [from args -parent] \
              -class SearchArticlesDialog \
              -bitmap questhead -default ok -cancel cancel \
              -modal local -transient yes -side bottom
        $hull add ok -text OK -command [mymethod _OK]
        $hull add cancel -text Dismis -command [mymethod _Cancel]
        $hull add help   -text Help   \
              -command [list HTMLHelp help "Select Articles Dialog"]
        wm protocol $win WM_DELETE_WINDOW [mymethod _Cancel]
        set options(-selectmode) [from args -selectmode]
        $self _constructArticleList [$hull getframe] \
              -selectmode $options(-selectmode)
        $self configurelist $args
        if {[string equal "$options(-grouptree)" {}]} {
            error "-grouptree is a required option!"
        }
        if {[string equal "$options(-group)" {}]} {
            error "-group is a required option!"
        }
        $self deleteall
        $options(-grouptree) insertArticleList $self $options(-group)
    }
    method _OK {} {
        $hull withdraw
        return [$hull enddialog ok]
    }
    method _Cancel {} {
        $hull withdraw
        return [$hull enddialog cancel]
    }
    method _Draw {} {return [$hull draw]}
    method _SelectedArticleNumbers {} {
        set result {}
        foreach sel [$articleList selection] {
            lappend result [$self articlenumber $sel]
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
    component passphraseFrame
    component   passphraseLabel
    component   passphraseEntry
    constructor {args} {
        set options(-parent) [from args -parent]
        installhull using Dialog \
              -class EnterPassPhraseDialog -bitmap questhead \
              -default ok -modal local -transient yes \
              -parent $options(-parent) -side bottom
        $hull add ok -text OK -command [mymethod _OK]
        install uidhintL using ttk::label \
              [$hull getframe].uidhintL -justify left -anchor w
        pack $uidhintL -fill x -expand yes
        install prevwasbadL using ttk::label \
              [$hull getframe].prevwasbadL -justify left -anchor w
        pack $prevwasbadL -fill x -expand yes
        install passphraseFrame using ttk::frame \
              [$hull getframe].passphraseFrame
        pack $passphraseFrame -fill x
        install passphraseLabel using ttk::label \
              $passphraseFrame.passphraseLabel -text "Pass Phrase:"
        pack $passphraseLabel -side left
        install passphraseEntry using ttk::entry \
              $passphraseFrame.passphraseEntry -show *
        bind $passphraseEntry <Return> [mymethod _OK]
        pack $passphraseEntry -side left -expand yes -fill x
        $self configurelist $args
        set dialogsByParent($options(-parent)) $self
    }
    destructor {
        catch {unset dialogsByParent($options(-parent))}
    }
    method _OK {} {
        $hull withdraw
        return [$hull enddialog [$passphraseEntry get]]
    }
    method _Draw {args} {
        $self configurelist $args
        $passphraseEntry delete 0 end
        return [$hull draw $passphraseEntry]
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

snit::widget SimpleDraftEditor {
    hulltype tk::toplevel

    component editBufferSW
    component   editBuffer
    component editButtons
    variable  filename {}
    variable  done 0
    
    typeconstructor {
        ttk::style configure SimpleDraftEditor.editBuffer \
              -background while \
              -forground  black \
              -relief     flat \
              -borderwidth 0
    }
    
    option -parent -default . -readonly yes -type snit::window
    constructor {args} {
        set options(-parent) [from args -parent]
        wm transient $win [winfo toplevel $options(-parent)]
        wm protocol $win WM_DELETE_WINDOW [mymethod _Dismis]
        wm withdraw $win
        install editBufferSW using ScrolledWindow $win.editBufferSW \
              -scrollbar both -auto both
        pack $editBufferSW -expand yes -fill both
        install editBuffer using text [$editBufferSW getframe].editBuffer
        $editBufferSW setwidget $editBuffer
        bind $editBuffer <<ThemeChanged>> [mymethod _editBuffer_ThemeChanged]
        install editButtons using ButtonBox $$win.editButtons \
              -orient horizontal
        pack $editButtons -fill x
        $editButtons add ttk::button dismis -text Dismis -command [mymethod _Dismis]
        $editButtons add ttk::button save   -text Save -command [mymethod _Save]
        $editButtons add ttk::button saveexit -text {Save and Exit} [mymethod _SaveExit]
        $self _editBuffer_ThemeChanged
    }
    method editfile {draftfile} {
        $editBuffer delete 0 end
        if {![catch {open $draftfile r} fp]} {
            $editBuffer insert end [read $fp]
            close $fp
        }
        set filename $draftfile
        wm deiconify $win
        set done 0
        tkwait variable [myvar done]
    }
    method _Dismis {} {
        wm withdraw $win
        incr done
    }
    method _Save {} {
        if {![catch {open $filename w} fp]} {
            puts $fp [$editBuffer get 0 end-1c]
            close $fp
        }
    }
    method _SaveExit {} {
        $self _Save
        $self _Dismis
    }
    method _editBuffer_ThemeChanged {} {
        $editBuffer configure \
              -background [ttk::style lookup SimpleDraftEditor.editBuffer \
                           -background] \
              -forground [ttk::style lookup SimpleDraftEditor.editBuffer \
                          -forground] \
              -relief [ttk::style lookup SimpleDraftEditor.editBuffer \
                        -relief] \
              -borderwidth [ttk::style lookup SimpleDraftEditor.editBuffer \
                            -borderwidth]
    }
}



package provide ArticleFunctions 1.0

