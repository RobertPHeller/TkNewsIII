#* 
#* ------------------------------------------------------------------
#* AddressBook.tcl - Address book functions
#* Created by Robert Heller on Mon Aug 18 12:42:40 2008
#* ------------------------------------------------------------------
#* Modification History: $Log: headerfile.text,v $
#* Modification History: Revision 1.1  2002/07/28 14:03:50  heller
#* Modification History: Add it copyright notice headers
#* Modification History:
#* ------------------------------------------------------------------
#* Contents:
#* ------------------------------------------------------------------
#*  
#*     Generic Project
#*     Copyright (C) 2005  Robert Heller D/B/A Deepwoods Software
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

# $Id$

package require Tk
package require tile
package require MainFrame
package require Dialog
package require ButtonBox
package require CommonFunctions
package require IconImage
package require HTMLHelp
package require snit

snit::enum AddressFlags -values {collected hidden}

snit::type AddressBook {
    typevariable addresses -array {}
    typevariable nicknames -array {}
    typevariable names -array {}
    typevariable organizations -array {}
    typevariable cities -array {}
    typevariable zipcodes -array {}
    typevariable phones -array {}
    typevariable filename ~/.TkNewsAddresses
    typevariable sortarray addresses
    typevariable isdirtyP no
    

    option -nickname -default {}
    option -email -default {} -readonly yes -type RFC822
    option -name  -default {}
    option -organization -default {}
    option -phone -default {} \
          -type {snit::stringtype
        -regexp {^(([[:digit:]]+-)?[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9])?$}}
    option -streetaddress -default {}
    option -city -default {}
    option -state -default {}
    option -zipcode -default {} \
          -type {snit::stringtype 
        -regexp {^([0-9][0-9][0-9][0-9][0-9](-[0-9][0-9][0-9][0-9])?)?$}}
    option -flags -default {} -type {snit::listtype -type AddressFlags}
    constructor {args} {
        #      puts stderr "*** $type create $self $args"
        $self configurelist $args
        set options(-email) [string tolower "$options(-email)"]
        if {[string length "$options(-email)"] > 0 && 
            [catch {set addresses([$options(-email)])}]} {
            set addresses($options(-email)) $self
            lappend nicknames($options(-nickname)) $self
            lappend names($options(-name)) $self
            lappend organizations($options(-organization)) $self
            lappend phones($options(-phone)) $self
            lappend zipcodes($options(-zipcode)) $self
            lappend cities($options(-city)) $self
            set isdirtyP yes
            $type _UpdateViewEditList $self
        } else {
            error "Duplicate or empty Address: $options(-email)"
        }
    }
    destructor {
        if {"$_viewEditDialog" ne "" && [winfo exists $_viewEditDialog]} {
            $viewEditTree delete $self
        }
        if {![catch {unset addresses($options(-email))}]} {
            set isdirtyP yes
        }
    }
    typemethod CheckNewAddresses {tofield} {
        set tolist [RFC822 SmartSplit [string trim "$tofield"] ","]
        foreach to $tolist {
            set to [string trim "$to"]
            set toEM [string tolower [RFC822 EMail "$to"]]
            set toName [RFC822 Name "$to"]
            if {![RFC822 validate "$toEM"]} {continue}
            if {[catch {set addresses($toEM)} old]} {
                $type create %AUTO% -email "$toEM" -name "$toName" -flags collected
            }
        }
        #      parray addresses
    }
    typemethod WriteAddressBookFileIfDirty {} {
        if {!$isdirtyP} {return}
        catch {file copy -force "$filename" "${filename}~"}
        if {[catch {open "$filename" w} outfp]} {
            tk_messageBox -icon error -type ok -message "WriteAddressBookFileIfDirty: open \"$filename\": $outfp"
            return
        }
        foreach em [lsort -dictionary [array names addresses]] {
            $addresses($em) writetofile $outfp
        }
        close $outfp
        set isdirtyP no
        catch {$viewEditDirtyInd configure \
                  -background black}
    }
    typemethod LoadAddressBookFile {_filename} {
        set filename "$filename"
        if {[catch {open "$filename" r} infp]} {
            set isdirtyP no
            return
        }
        while {[$type readoneaddress $infp]} {}
        close $infp
        set isdirtyP no
    }
    method writetofile {fp} {
        puts $fp [list "$options(-email)" "$options(-nickname)" \
                  "$options(-name)" "$options(-organization)" \
                  "$options(-phone)" "$options(-streetaddress)" \
                  "$options(-city)" "$options(-state)" "$options(-zipcode)" \
                  $options(-flags)]
    }
    typemethod readoneaddress {fp} {
        set buffer {}
        set nl  {}
        while {[gets $fp line] >= 0} {
            append buffer "$nl$line"
            if {[info complete "$buffer"]} {break}
            set nl "\n"
        }
        if {[string length "$buffer"] == 0} {return false}
        set buffer [string trim "$buffer"]
        if {[string length "$buffer"] == 0} {return true}
        foreach {email nickname name organization phone streetaddress city state \
                  zipcode flags} $buffer {break}
        if {[string length "$email"] > 0} {
            $type create %AUTO% -email "$email" -nickname "$nickname" \
                  -name "$name" -organization "$organization" \
                  -phone "$phone" -streetaddress "$streetaddress" \
                  -city "$city" -state "$state" -zipcode "$zipcode" \
                  -flags $flags
        }
        return true
    }
    typemethod Export {args} {
        set exportFileName [tk_getSaveFile \
                            -defaultextension .csv \
                            -filetypes { {{CSV Files} {.csv} TEXT}
                            {{All Files} *      TEXT} } \
                              -parent [from args -parent .] -title "File to Export Address Book to"]
        if {[string length "$exportFileName"] == 0} {return}
        if {[catch {open "$exportFileName" w} csvfp]} {
            tk_messageBox -icon error -type ok -message "Export open \"$exportFileName\": $csvfp"
            return
        }
        $type writetocsvfileheader $csvfp
        foreach em [lsort -dictionary [array names addresses]] {
            $addresses($em) writetocsvfile $csvfp
        }
        close $csvfp
    }
    typemethod writetocsvfileheader {fp} {
        puts $fp {"EMail","Nickname","Name","Organization","Phone","Street Address","City","State","Zipcode"}
    }
    method writetocsvfile  {fp} {
        if {[lsearch $options(-flags) hidden] >= 0} {return}
        set comma {}
        foreach field {-email -nickname -name -organization -phone 
            -streetaddress -city -state -zipcode} {
            puts -nonewline $fp "$comma"
            puts -nonewline $fp {"}
            regsub -all {"} "$options($field)" {\\"} field
            regsub -all "\n" "$field" {\\n} field
            puts -nonewline $fp "$field"
            puts -nonewline $fp {"}
            set comma {,}
        }
        puts $fp {}
    }
    typecomponent _viewEditDialog
    typecomponent  viewEditMain
    typevariable menu { 
	"&File" {file:menu} {file} 0 {
	    {command "&New" {file:new} "Clear Address Book" {Ctrl n} -command "[mytypemethod _ClearAddressBook]"}
	    {command "&Save" {file:save} "Save Address Book" {Ctrl s} -command "[mytypemethod WriteAddressBookFileIfDirty]"}
	    {command "&Export" {file:export} "Export Address Book" {Alt e} -command "[mytypemethod Export -parent $_viewEditDialog]"}
	    {separator}
	    {command "&Close" {file:close} "Close Address Book" {Ctrl c} -command "[mytypemethod _CloseViewEdit]"}
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
        }
        "&Options" {options:menu} {options} 0 {
        }
        "&Help" {help:menu} {help} 0 {
            {command "On &Help..." {help:help} "Help on help" {} 
                -command "HTMLHelp help Help"}
            {command "&Index..." {help:index} "Help index" {} 
                -command "HTMLHelp help Index"}
            {command "&Tutorial..." {help:tutorial} "Tutorial" {}  
                -command "HTMLHelp help Tutorial"}
            {command "On &Version" {help:version} "Version" {} 
                -command "HTMLHelp help Version"}
            {command "Warranty" {help:warranty} "Warranty" {} 
                -command "HTMLHelp help Warranty"}
            {command "Copying" {help:copying} "Copying" {} 
                -command "HTMLHelp help Copying"}
        } 
    }
    typecomponent    viewEditNowhere
    typevariable     viewEditMainStatus {}
    typevariable     viewEditMainProgress 0
    typecomponent    viewEditToolBar
    typecomponent      viewEditToolBarNewAddress
    typecomponent      viewEditToolBarShowHideHidden
    typevariable	viewEditToolBarShowHidden no
    typecomponent      viewEditToolBarDeleteAddress
    typecomponent    viewEditDirtyInd
    typecomponent    viewEditPane
    typecomponent      viewEditTreeSW
    typecomponent	 viewEditTree
    typevariable columnheadings -array {
        nickname,stretch yes
        nickname,text {Nickname}
        nickname,width 75
        nickname,anchor w
        nickname,sort nicknames
        email,stretch yes
        email,text {EMail Address}
        email,width 100
        email,anchor w
        email,sort addresses
        name,stretch yes
        name,text {Name}
        name,width 100
        name,anchor w
        name,sort names
        organization,stretch yes
        organization,text {Organization}
        organization,anchor w
        organization,sort organizations
        phone,stretch yes
        phone,text {Telephone}
        phone,width 50
        phone,anchor w
        phone,sort phones
        streetaddress,stretch yes
        streetaddress,text {Street Address}
        streetaddress,anchor w
        city,stretch yes
        city,text {City}
        city,width 50
        city,anchor w
        city,sort cities
        state,stretch no
        state,text {State}
        state,width 36
        state,anchor w
        zipcode,stretch no
        zipcode,text {Zipcode}
        zipcode,width 50
        zipcode,anchor w
        zipcode,sort zipcodes
        flags,stretch no
        flags,text FL
        flags,width 24
        flags,anchor w
    }
    typevariable columns {nickname email name organization phone 
        streetaddress city state zipcode flags}

    typecomponent      viewEditAddress
    typecomponent        viewEditAddressButtons
    typecomponent	 viewEditAddressEmail
    typevariable         viewEditAddressEmail_TV
    typecomponent	 viewEditAddressNickname
    typevariable         viewEditAddressNickname_TV
    typecomponent	 viewEditAddressName
    typevariable         viewEditAddressName_TV
    typecomponent	 viewEditAddressOrganization
    typevariable         viewEditAddressOrganization_TV
    typecomponent	 viewEditAddressPhone
    typevariable         viewEditAddressPhone_TV
    typecomponent	 viewEditAddressStreetAddress
    typevariable         viewEditAddressStreetAddress_TV
    typecomponent	 viewEditAddressCity
    typevariable         viewEditAddressCity_TV
    typecomponent	 viewEditAddressState
    typevariable         viewEditAddressState_TV
    typecomponent	 viewEditAddressZipcode
    typevariable         viewEditAddressZipcode_TV
    typecomponent        viewEditAddressFlags
    typecomponent	   viewEditAddressHiddenFlag
    typevariable	   viewEditAddressHiddenFlagVar no
    typecomponent	   viewEditAddressCollectedFlag
    typevariable	   viewEditAddressCollectedFlagVar no
    typemethod _CreateViewEditDialog {args} {
        if {![string equal "$_viewEditDialog" {}]} {return}
        set _viewEditDialog [tk::toplevel ._viewEditDialog]
        wm iconbitmap $_viewEditDialog [IconBitmap bitmap TkNewsIIIicon]
        wm iconmask   $_viewEditDialog [IconBitmap bitmap TkNewsIIIicon_mask]
        wm maxsize $_viewEditDialog 1024 768
        wm minsize $_viewEditDialog 640 10
        wm title $_viewEditDialog "TkNews: Address Book"
        wm iconname $_viewEditDialog "AddressBook"
        wm protocol $_viewEditDialog WM_DELETE_WINDOW [mytypemethod _CloseViewEdit]
        set newGeo [from args -geometry [option get $_viewEditDialog addressBookGeometry AddressBookGeometry]]
        if {[string length "$newGeo"] > 0} {
            wm geometry $_viewEditDialog "$newGeo"
        }
        set viewEditNowhere [canvas $_viewEditDialog.viewEditNowhere]
        set themenu [subst $menu]
        set viewEditMain [MainFrame $_viewEditDialog.viewEditMain \
                          -menu $themenu \
                          -textvariable [mytypevar viewEditMainStatus] \
                          -progressvar [mytypevar viewEditMainProgress] \
                          -progressmax 100]
        pack $viewEditMain -expand yes -fill both
        $viewEditMain showstatusbar progression
        set viewEditToolBar [$viewEditMain addtoolbar]
        set viewEditToolBarNewAddress \
              [ttk::button $viewEditToolBar.viewEditToolBarNewAddress \
               -text "New Address" -command [mytypemethod _CreateNewAddress]]
        pack $viewEditToolBarNewAddress -side left
        set viewEditToolBarShowHideHidden \
              [ttk::button $viewEditToolBar.viewEditToolBarShowHideHidden \
               -text "Show Hidden" -command [mytypemethod _ToggleHidden]]
        pack $viewEditToolBarShowHideHidden -side left
        set viewEditToolBarDeleteAddress \
              [ttk::button $viewEditToolBar.viewEditToolBarDeleteAddress \
               -text "Delete Address" -state disabled \
               -command [mytypemethod _DeleteSelectedAddress]]
        pack $viewEditToolBarDeleteAddress -side left
        set viewEditDirtyInd [$viewEditMain addindicator -background black \
                              -image [IconImage image gray50 \
                                      -filetype xbm \
                                      -foreground [ttk::style lookup . \
                                                   -background] \
                                      -background {}]]
        set mframe [$viewEditMain getframe]
        set viewEditPane [ttk::panedwindow $mframe.viewEditPane -orient vertical]
        pack $viewEditPane -expand yes -fill both
        set viewEditTreeSW [ScrolledWindow $viewEditPane.viewEditTreeSW -auto both -scrollbar both]
        $viewEditPane add $viewEditTreeSW -weight 1
        set viewEditTree [ttk::treeview [$viewEditTreeSW getframe].viewEditTree \
              -show {headings} -columns $columns -displaycolumns $columns \
              -selectmode browse]
        $viewEditTreeSW setwidget $viewEditTree
        $viewEditTree tag bind row <Double-Button-1> [mytypemethod _SelectRow %x %y]
        set viewEditAddress [ttk::labelframe $viewEditPane.viewEditAddress]
        $viewEditPane add $viewEditAddress -weight 3
        set vaframe $viewEditAddress
        set viewEditAddressButtons [ButtonBox $vaframe.viewEditAddressButtons \
                                    -orient horizontal]
        pack $viewEditAddressButtons -fill x
        $viewEditAddressButtons add ttk::button save \
              -text Save \
              -command [mytypemethod _UpdateAddress]
        $viewEditAddressButtons configure -default save
        $viewEditAddressButtons add ttk::button cancel \
              -text Cancel \
              -command [mytypemethod _RestoreAddress]
        foreach w {Email Nickname Name Organization Phone StreetAddress City 
            State Zipcode} {
            if {[string equal "$w" "Email"]} {
                set state readonly
            } else {
                set state normal
            }
            set f [ttk::frame $vaframe.viewEditAddressFrame$w]
            pack $f -fill x
            set l [ttk::label $f.l -text $w -width 20 -anchor w]
            pack $l -side left
            set viewEditAddress$w [ttk::entry $f.viewEditAddress$w \
                                   -textvariable [mytypevar \
                                                  viewEditAddress${w}_TV] \
                                   -state $state]
            pack [set viewEditAddress$w] -fill x -expand yes -side left
        }
        set viewEditAddressFlags [ttk::frame $vaframe.viewEditAddressFlags]
        pack $viewEditAddressFlags -fill x
        pack [ttk::label $viewEditAddressFlags.l -text Flags: -width 20 \
              -anchor w] -side left
        set flframe $viewEditAddressFlags
        set viewEditAddressHiddenFlag [ttk::checkbutton $flframe.viewEditAddressHiddenFlag \
                                       -text hidden \
                                       -offvalue no -onvalue yes \
                                       -variable [mytypevar viewEditAddressHiddenFlagVar]]
        pack $viewEditAddressHiddenFlag -side left
        set viewEditAddressCollectedFlag [ttk::checkbutton $flframe.viewEditAddressCollectedFlag \
                                          -text collected \
                                          -offvalue no -onvalue yes \
                                          -variable [mytypevar viewEditAddressCollectedFlagVar]]
        pack $viewEditAddressCollectedFlag -side left
        foreach c $columns {
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
            if {[llength $copts] > 0} {
                eval [list $viewEditTree column $c] $copts
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
                eval [list $viewEditTree heading $c] $hopts
            }
            if {[info exists columnheadings($c,sort)]} {
                $viewEditTree heading $c \
                      -command [mytypemethod _sortcolumn $columnheadings($c,sort)]
            }
        }
        set idlist [$type _sortedidlist]
        foreach id $idlist {
            $viewEditTree insert {} end -id $id \
                  -values [list [$id cget -nickname] [$id cget -email] \
                           [$id cget -name] [$id cget -organization] \
                           [$id cget -phone] [$id cget -streetaddress] \
                           [$id cget -city] [$id cget -state] \
                           [$id cget -zipcode] \
                           [_formflags [$id cget -flags]]] \
                  -tags row
        }
    }
    proc _formflags {flaglist} {
        set result {}
        foreach f $flaglist {
            append result [string toupper [string index $f 0]]
        }
        return $result
    }
    typemethod _ToggleHidden {} {
        if {$viewEditToolBarShowHidden} {
            $viewEditToolBarShowHideHidden configure -text "Show Hidden"
            set viewEditToolBarShowHidden no
            if {$SelectedItem ne "" && $viewEditAddressHiddenFlagVar} {
                $type _SelectItem ""
            }
            foreach em [array names addresses] {
                set id $addresses($em)
                if {[lsearch [$id cget -flags] hidden] >= 0} {
                    $viewEditTree detach $id
                }
            }
        } else {
            $viewEditToolBarShowHideHidden configure -text "Hide Hidden"
            set viewEditToolBarShowHidden yes
            set idlist [$type _sortedidlist]
            set index 0
            foreach id $idlist {
                if {[lsearch [$id cget -flags] hidden] >= 0} {
                    $viewEditTree move $id {} $index
                }
                incr index
            }
        }
        
        $type _UpdateViewEditList      
    }
    typemethod _sortedidlist {} {
        switch $sortarray {
            addresses {
                set idlist [list]
                foreach em [lsort -dictionary [array names addresses]] {
                    lappend idlist $addresses($em)
                }
            }
            nicknames -
            names -
            organizations -
            cities -
            zipcodes -
            phones {
                set idlist [list]
                foreach n [lsort -dictionary [array names $sortarray]] {
                    #puts stderr "*** $type _sortedidlist: n = $n"
                    foreach id [set [set sortarray]($n)] {
                        #puts stderr "*** $type _sortedidlist: id is $id"
                        lappend idlist $id
                    }
                }
            }
        }
        return $idlist
    }
    typemethod _sortcolumn {arrayname} {
        if {$arrayname eq $sortarray} {return}
        set sortarray $arrayname
        $viewEditTree detach [$viewEditTree children {}]
        set idlist [$type _sortedidlist]
        #puts stderr "*** $type _sortcolumn: idlist is $idlist"
        foreach id $idlist {
            #puts stderr "*** $type _sortcolumn: id is $id"
            set flags [$id cget -flags]
            #puts stderr "*** $type _sortcolumn: flags (of $id) is $flags"
            set hindex [lsearch $flags hidden]
            #puts stderr "*** $type _sortcolumn: hindex (of $id) is $hindex"
            if {$viewEditToolBarShowHidden || $hindex < 0} {
                if {[$viewEditTree exists $id]} {
                    $viewEditTree move $id {} end
                } else {
                    $viewEditTree insert {} end -id $id \
                          -values [list [$id cget -nickname] [$id cget -email] \
                                   [$id cget -name] [$id cget -organization] \
                                   [$id cget -phone] [$id cget -streetaddress] \
                                   [$id cget -city] [$id cget -state] \
                                   [$id cget -zipcode] \
                                   [_formflags [$id cget -flags]]] \
                          -tags row
                    set isdirtyP yes
                }
            }
        }
        #puts stderr "*** $type _sortcolumn: isdirtyP = $isdirtyP"
        if {$isdirtyP} {
            $viewEditDirtyInd configure -background red
        } else {
            $viewEditDirtyInd configure -background black
        }
    }
    typemethod _UpdateViewEditList {{newid {}}} {
        #      puts stderr "*** $type _UpdateViewEditList"
        if {[string equal "$_viewEditDialog" {}]} {return}
        if {$newid ne ""} {
            set idlist [$type _sortedidlist]
            set index [lsearch -exact $idlist $newid]
            if {[$viewEditTree exists $newid]} {
                $viewEditTree move $newid {} $index
            } else {
                $viewEditTree insert {} $index -id $newid \
                      -values [list [$newid cget -nickname] [$newid cget -email] \
                               [$newid cget -name] [$newid cget -organization] \
                               [$newid cget -phone] [$newid cget -streetaddress] \
                               [$newid cget -city] [$newid cget -state] \
                               [$newid cget -zipcode] \
                               [_formflags [$newid cget -flags]]] \
                      -tags row
            }
        }
        #puts stderr "*** $type _UpdateViewEditList: isdirtyP = $isdirtyP"
        if {$isdirtyP} {
            $viewEditDirtyInd configure -background red
        } else {
            $viewEditDirtyInd configure -background black
        }
    }
    typevariable WatchList -array {}
    typemethod SetWatchCursor {w} {
        if {![catch {$w cget -cursor} oldcursor] && 
            [winfo ismapped $w] &&
            [catch {set WatchList($w)}]} {
            if {![string equal "$oldcursor" watch]} {
                set WatchList($w) $oldcursor
                catch {$w configure -cursor watch}
            }
        }
        foreach iw [winfo children $w] {
            $type SetWatchCursor $iw
        }
    }
    typemethod UnSetWatchCursor {} {
        #      parray WatchList
        foreach w [array names WatchList] {
            catch {$w configure -cursor "$WatchList($w)"}
        }
    }
    typemethod SetBusy {w flag} {
        #      puts stderr "*** $type SetBusy $w $flag"
        #      puts stderr "*** $type SetBusy (entry) \[grab current $w\] = [grab current $w]"
        if {$flag} {
            if {[string equal [grab current $w] $viewEditNowhere]} {return}
            catch {array unset WatchList}
            $type SetWatchCursor [winfo toplevel $w]
            grab $viewEditNowhere
        } else {
            if {![string equal [grab current $w] $viewEditNowhere]} {return}
            $type UnSetWatchCursor
            grab release $viewEditNowhere
            
        }
        #      puts stderr "*** $type SetBusy (exit) \[grab current $w\] = [grab current $w]"
        update
    }
    typemethod _SelectRow {x y} {
        $type _SelectItem [$viewEditTree identify row $x $y]
    }
    typevariable SelectedItem
    typemethod _SelectItem {id} {
        $type _ClearAddress
        $viewEditToolBarDeleteAddress configure -state disabled
        set SelectedItem $id
        if {$SelectedItem eq ""} {return}
        $type _FillAddress $id
        $viewEditToolBarDeleteAddress configure -state normal
    }
    typemethod _RestoreAddress {} {
        $type _SelectItem $SelectedItem
    }
    typemethod _FillAddress {id} {
        set viewEditAddressEmail_TV [$id cget -email]
        set viewEditAddressNickname_TV [$id cget -nickname]
        set viewEditAddressName_TV [$id cget -name]
        set viewEditAddressOrganization_TV [$id cget -organization]
        set viewEditAddressPhone_TV [$id cget -phone]
        set viewEditAddressStreetAddress_TV [$id cget -streetaddress]
        set viewEditAddressCity_TV [$id cget -city]
        set viewEditAddressState_TV [$id cget -state]
        set viewEditAddressZipcode_TV [$id cget -zipcode]
        set flags [$id cget -flags]
        if {[lsearch $flags hidden] < 0} {
            set viewEditAddressHiddenFlagVar no
        } else {
            set viewEditAddressHiddenFlagVar yes
        }
        if {[lsearch $flags collected] < 0} {
            set viewEditAddressCollectedFlagVar no
        } else {
            set viewEditAddressCollectedFlagVar yes
        }
    }
    typemethod _ClearAddress {} {
        set viewEditAddressEmail_TV {}
        set viewEditAddressNickname_TV {}
        set viewEditAddressName_TV {}
        set viewEditAddressOrganization_TV {}
        set viewEditAddressPhone_TV {}
        set viewEditAddressStreetAddress_TV {}
        set viewEditAddressCity_TV {}
        set viewEditAddressState_TV {}
        set viewEditAddressZipcode_TV {}
        set viewEditAddressHiddenFlagVar no
        set viewEditAddressCollectedFlagVar no
    }
    typemethod _UpdateAddress {} {
        if {![info exists addresses($viewEditAddressEmail_TV)]} {return}
        set id $addresses($viewEditAddressEmail_TV)
        set detached no
        set colsupdated no
        set addnew [expr {![$viewEditTree exists $id]}]
        if {$viewEditAddressNickname_TV ne [$id cget -nickname]} {
            set colsupdated yes
            if {$sortarray eq "nicknames"} {
                if {!$addnew} {
                    $viewEditTree detach $id
                    set detached yes
                }
                if {[info exists nicknames([$id cget -nickname])]} {
                    set idlist $nicknames([$id cget -nickname])
                    set indx [lsearch -exact $idlist $id]
                    if {$indx >= 0} {
                        set nicknames([$id cget -nickname]) \
                              [lreplace $idlist $indx $indx]
                    }
                }
            }
            $id configure -nickname $viewEditAddressNickname_TV
            lappend nicknames([$id cget -nickname]) $id
        }
        if {$viewEditAddressName_TV ne [$id cget -name]} {
            set colsupdated yes
            if {$sortarray eq "names"} {
                if {!$addnew} {
                    $viewEditTree detach $id
                    set detached yes
                }
                if {[info exists names([$id cget -name])]} {
                    set idlist $names([$id cget -name])
                    set indx [lsearch -exact $idlist $id]
                    if {$indx >= 0} {
                        set names([$id cget -name]) \
                              [lreplace $idlist $indx $indx]
                    }
                }
            }
            $id configure -name $viewEditAddressName_TV
            lappend names([$id cget -name]) $id
        }
        if {$viewEditAddressOrganization_TV ne [$id cget -organization]} {
            set colsupdated yes
            if {$sortarray eq "organizations"} {
                if {!$addnew} {
                    $viewEditTree detach $id
                    set detached yes
                }
                if {[info exists organizations([$id cget -organization])]} {
                    set idlist $organizations([$id cget -organization])
                    set indx [lsearch -exact $idlist $id]
                    if {$indx >= 0} {
                        set organizations([$id cget -organization]) \
                              [lreplace $idlist $indx $indx]
                    }
                }
            }
            $id configure -organization $viewEditAddressOrganization_TV
            lappend organizations([$id cget -organization]) $id
        }
        if {$viewEditAddressPhone_TV ne [$id cget -phone]} {
            set colsupdated yes
            if {$sortarray eq "phones"} {
                if {!$addnew} {
                    $viewEditTree detach $id
                    set detached yes
                }
                if {[info exists phones([$id cget -phone])]} {
                    set idlist $phones([$id cget -phone])
                    set indx [lsearch -exact $idlist $id]
                    if {$indx >= 0} {
                        set phones([$id cget -phone]) \
                              [lreplace $idlist $indx $indx]
                    }
                }
            }
            $id configure -phone $viewEditAddressPhone_TV
            lappend phones([$id cget -phone]) $id
        }
        if {$viewEditAddressStreetAddress_TV ne [$id cget -streetaddress]} {
            set colsupdated yes
            $id configure -streetaddress $viewEditAddressStreetAddress_TV
        }
        if {$viewEditAddressCity_TV ne [$id cget -city]} {
            set colsupdated yes
            if {$sortarray eq "cities"} {
                if {!$addnew} {
                    $viewEditTree detach $id
                    set detached yes
                }
                if {[info exists cities([$id cget -city])]} {
                    set idlist $cities([$id cget -city])
                    set indx [lsearch -exact $idlist $id]
                    if {$indx >= 0} {
                        set cities([$id cget -city]) \
                              [lreplace $idlist $indx $indx]
                    }
                }
            }
            $id configure -city $viewEditAddressCity_TV
            lappend cities([$id cget -city]) $id
        }
        if {$viewEditAddressState_TV ne [$id cget -state]} {
            set colsupdated yes
            $id configure -state $viewEditAddressState_TV
        }
        if {$viewEditAddressZipcode_TV ne [$id cget -zipcode]} {
            set colsupdated yes
            if {$sortarray eq "zipcodes"} {
                if {!$addnew} {
                    $viewEditTree detach $id
                    set detached yes
                }
                if {[info exists zipcodes([$id cget -zipcode])]} {
                    set idlist $zipcodes([$id cget -zipcode])
                    set indx [lsearch -exact $idlist $id]
                    if {$indx >= 0} {
                        set zipcodes([$id cget -zipcode]) \
                              [lreplace $idlist $indx $indx]
                    }
                }
            }
            $id configure -zipcode $viewEditAddressZipcode_TV
            lappend zipcodes([$id cget -zipcode]) $id
        }
        set flags [$id cget -flags]
        set ih [lsearch $flags hidden]
        if {$viewEditAddressHiddenFlagVar} {
            if {$ih < 0} {
                lappend flags hidden
                set colsupdated yes
                $id configure -flags $flags
            }
        } elseif {$ih >= 0} {
            set flags [lreplace $flags $ih $ih]
            set colsupdated yes
            $id configure -flags $flags
        }
        set ic [lsearch $flags collected]
        if {$viewEditAddressCollectedFlagVar} {
            if {$ic < 0} {
                lappend flags collected
                set colsupdated yes
                $id configure -flags $flags
            }
        } elseif {$ic >= 0} {
            set flags [lreplace $flags $ic $ic]
            set colsupdated yes
            $id configure -flags $flags
        }        
        set idlist [$type _sortedidlist]
        set index  [lsearch -exact $idlist $id]
        if {$detached} {
            $viewEditTree move $id {} $index
        }
        if {$addnew} {
            $viewEditTree insert {} $index -id $id \
                  -values [list [$id cget -nickname] [$id cget -email] \
                           [$id cget -name] [$id cget -organization] \
                           [$id cget -phone] [$id cget -streetaddress] \
                           [$id cget -city] [$id cget -state] \
                           [$id cget -zipcode] \
                           [_formflags [$id cget -flags]]] \
                  -tags row
            set isdirtyP yes
        }
        if {$colsupdated} {
            $viewEditTree item $id \
                  -values [list [$id cget -nickname] [$id cget -email] \
                           [$id cget -name] [$id cget -organization] \
                           [$id cget -phone] [$id cget -streetaddress] \
                           [$id cget -city] [$id cget -state] \
                           [$id cget -zipcode] \
                           [_formflags [$id cget -flags]]]
            set isdirtyP yes
        }
        #puts stderr "*** $type _UpdateAddress: isdirtyP = $isdirtyP"
        if {$isdirtyP} {
            $viewEditDirtyInd configure -background red
        } else {
            $viewEditDirtyInd configure -background black
        }
        
    }
    typecomponent _newEMailAddressDialog
    typecomponent   newEMailAddressF
    typecomponent   newEMailAddressL
    typecomponent   newEMailAddressE
    typemethod _CreateNewEMailAddressDialog {} {
        if {![string equal "$_newEMailAddressDialog" {}]} {return}
        set _newEMailAddressDialog [Dialog ._newEMailAddressDialog \
                                    -class NewEMailAddressDialog \
                                    -bitmap questhead -default create \
                                    -cancel cancel -modal local -transient yes \
                                    -parent $_viewEditDialog -side bottom]
        $_newEMailAddressDialog add create -text Create -command [mytypemethod _CreateANewEmailAddress]
        $_newEMailAddressDialog add cancel -text Cancel -command [mytypemethod _CancelANewEmailAddress]
        $_newEMailAddressDialog add help -text Help -command [list HTMLHelp help "New EMail Address Dialog"]
        set frame [$_newEMailAddressDialog getframe]
        pack [set newEMailAddressF [ttk::frame $frame.newEMailAddressF]] \
              -fill x
        pack [set newEMailAddressL [ttk::label $newEMailAddressF.l -text "EMail Address:" \
                                    -anchor w]] -side left
        pack [set newEMailAddressE [ttk::entry $newEMailAddressF.e]] \
              -side left -fill x -expand yes
    }
    typemethod _CreateNewAddress {} {
        if {[string equal "$_newEMailAddressDialog" {}]} {$type _CreateNewEMailAddressDialog}
        $_newEMailAddressDialog draw
    }
    typemethod _CreateANewEmailAddress {} {
        #      puts stderr "*** $type _CreateANewEmailAddress"
        set EM [string tolower "[$newEMailAddressLE cget -text]"]
        #      puts stderr "*** $type _CreateANewEmailAddress: EM = $EM"
        $_newEMailAddressDialog withdraw
        #      puts stderr "*** $type _CreateANewEmailAddress: \[RFC822 validate \{$EM\}\] => [RFC822 validate $EM]"
        #      puts stderr "*** $type _CreateANewEmailAddress: \[catch {set addresses($EM)} old\] => [catch {set addresses($EM)} old]"
        if {[RFC822 validate "$EM"] && ![info exists addresses($EM)]} {
            set id [$type create %AUTO% -email [$newEMailAddressLE cget -text]]
            $type _SelectItem $id
        }
        return [$_newEMailAddressDialog enddialog create]
    }
    typemethod _CancelANewEmailAddress {} {
        $_newEMailAddressDialog withdraw
        return [$_newEMailAddressDialog enddialog cancel]
    }
    typemethod _DeleteSelectedAddress {} {
        set email [$viewEditAddressEmail get]
        if {![info exists addresses($email)]} {return}
        set id $addresses($email)
        $type _SelectItem {}
        $id destroy
    }
    typemethod ViewEdit {args} {
        if {[string equal "$_viewEditDialog" {}]} {
            $type _CreateViewEditDialog $args
        }
        wm deiconify $_viewEditDialog
        update idle
    }
    typemethod _CloseViewEdit {} {wm withdraw $_viewEditDialog}
    typemethod _ClearAddressBook {} {
        foreach ad [array names addresses] {
            $addresses($ad) destroy
        }
    }
    
    typecomponent _getToCcAddressesDialog
    typecomponent   getToCcAddressesDialogLeft
    typecomponent     getToCcAddressesDialogAllSW
    typecomponent       getToCcAddressesDialogAll
    typecomponent   getToCcAddressesDialogRight
    typecomponent     getToCcAddressesDialogToBF
    typecomponent       getToCcAddressesDialogToButton
    typecomponent       getToCcAddressesDialogToListSW
    typecomponent         getToCcAddressesDialogToList
    typecomponent     getToCcAddressesDialogCcBF
    typecomponent       getToCcAddressesDialogCcButton
    typecomponent       getToCcAddressesDialogCcListSW
    typecomponent         getToCcAddressesDialogCcList
    typemethod _CreateGetToCcAddressesDialog {} {
        if {![string equal "$_getToCcAddressesDialog" {}]} {return}
        set _getToCcAddressesDialog [Dialog ._getToCcAddressesDialog \
                                     -class GetToCcAddressesDialog \
                                     -bitmap questhead -default ok \
                                     -cancel cancel -modal local -transient yes \
                                     -parent . -side bottom]
        $_getToCcAddressesDialog add ok -text OK -command [mytypemethod _GetToCcAddressesDialog_OK]
        $_getToCcAddressesDialog add cancel -text Cancel -command [mytypemethod _GetToCcAddressesDialog_Cancel]
        $_getToCcAddressesDialog add help -text Help -command [list HTMLHelp help "Get To and Cc Addresses Dialog"]
        set frame [$_getToCcAddressesDialog getframe]
        set getToCcAddressesDialogLeft [ttk::frame $frame.getToCcAddressesDialogLeft -relief flat]
        pack $getToCcAddressesDialogLeft -side left -expand yes -fill both
        set getToCcAddressesDialogAllSW [ScrolledWindow $getToCcAddressesDialogLeft.getToCcAddressesDialogAllSW -auto both -scrollbar both]
        pack $getToCcAddressesDialogAllSW -fill both -expand yes
        set getToCcAddressesDialogAll [ttk::treeview [$getToCcAddressesDialogAllSW getframe].getToCcAddressesDialogAll -selectmode extended -show {tree}]
        $getToCcAddressesDialogAllSW setwidget $getToCcAddressesDialogAll
        set getToCcAddressesDialogRight [ttk::frame $frame.getToCcAddressesDialogRight -relief flat]
        pack $getToCcAddressesDialogRight -side right -expand yes -fill both
        set getToCcAddressesDialogToBF [ttk::frame $getToCcAddressesDialogRight.getToCcAddressesDialogToBF -relief flat]
        pack $getToCcAddressesDialogToBF -expand yes -fill both
        set getToCcAddressesDialogToButton [ttk::button $getToCcAddressesDialogToBF.getToCcAddressesDialogToButton -text ">> To:" -command [mytypemethod _MoveAddressToToList]]
        pack $getToCcAddressesDialogToButton -side left
        set getToCcAddressesDialogToListSW [ScrolledWindow $getToCcAddressesDialogToBF.getToCcAddressesDialogToListSW -auto both -scrollbar both]
        pack $getToCcAddressesDialogToListSW -side right -expand yes -fill both
        set getToCcAddressesDialogToList [ttk::treeview [$getToCcAddressesDialogToListSW getframe].getToCcAddressesDialogToList -selectmode none -show {tree}]
        $getToCcAddressesDialogToListSW setwidget $getToCcAddressesDialogToList
        set getToCcAddressesDialogCcBF [frame $getToCcAddressesDialogRight.getToCcAddressesDialogCcBF -relief flat]
        pack $getToCcAddressesDialogCcBF -expand yes -fill both
        set getToCcAddressesDialogCcButton [ttk::button $getToCcAddressesDialogCcBF.getToCcAddressesDialogCcButton -text ">> Cc:" -command [mytypemethod _MoveAddressToCcList]]
        pack $getToCcAddressesDialogCcButton -side left
        set getToCcAddressesDialogCcListSW [ScrolledWindow $getToCcAddressesDialogCcBF.getToCcAddressesDialogCcListSW -auto both -scrollbar both]
        pack $getToCcAddressesDialogCcListSW -side right -expand yes -fill both
        set getToCcAddressesDialogCcList [ttk::treeview [$getToCcAddressesDialogCcListSW getframe].getToCcAddressesDialogCcList -selectmode none -show {tree}]
        $getToCcAddressesDialogCcListSW setwidget $getToCcAddressesDialogCcList
    }
    typemethod _MoveAddressToToList {} {
        set selection [$getToCcAddressesDialogAll selection]
        foreach id $selection {
            $getToCcAddressesDialogToList insert {} end -id $id \
                  -text "[$id cget -name] <[$id cget -email]>"
            $getToCcAddressesDialogAll delete $id
        }
    }
    typemethod _MoveAddressToCcList {} {
        set selection [$getToCcAddressesDialogAll selection]
        foreach id $selection {
            $getToCcAddressesDialogCcList insert {} end -id $id \
                  -text "[$id cget -name] <[$id cget -email]>"
            $getToCcAddressesDialogAll delete $id
        }
    }
    typemethod GetToCcAddresses {ToAddrsVar CCAddrsVar args} {
        if {[string equal "$_getToCcAddressesDialog" {}]} {$type _CreateGetToCcAddressesDialog}
        $getToCcAddressesDialogAll delete [$getToCcAddressesDialogAll children {}]
        set allwidth 0
        set toccwidth 0
        set tvFont [ttk::style lookup Treeview -font]
        foreach n [lsort -dictionary [array names nicknames]] {
            foreach ad $nicknames($n) {
                if {[lsearch [$ad cget -flags] hidden] < 0 && 
                    [string length "[$ad cget -nickname]"] > 0} {
                    set alltext "[$ad cget -nickname] ([$ad cget -name]) <[$ad cget -email]>"
                    set tocctext "[$ad cget -name] <[$ad cget -email]>"
                    set wall [font measure $tvFont -displayof $_getToCcAddressesDialog $alltext]
                    if {$wall > $allwidth} {set allwidth $wall}
                    set wtc [font measure $tvFont -displayof $_getToCcAddressesDialog $tocctext]
                    if {$wtc > $toccwidth} {set toccwidth $wtc}
                    $getToCcAddressesDialogAll insert {} end -id $ad \
                          -text $alltext
                }
            }
        }
        $getToCcAddressesDialogAll column #0 -minwidth $allwidth
        $getToCcAddressesDialogToList delete [$getToCcAddressesDialogToList children {}]
        $getToCcAddressesDialogCcList delete [$getToCcAddressesDialogCcList children {}]
        $getToCcAddressesDialogToList column #0 -minwidth $toccwidth
        $getToCcAddressesDialogCcList column #0 -minwidth $toccwidth
        set parent [from args -parent .]
        $_getToCcAddressesDialog configure -parent $parent
        wm transient [winfo toplevel $_getToCcAddressesDialog] $parent
        set result [$_getToCcAddressesDialog draw]
        #puts stderr "*** $type GetToCcAddresses: result = $result"
        if {$result eq "ok"} {
            upvar $ToAddrsVar tolist
            set tolist {}
            foreach to [$getToCcAddressesDialogToList children {}] {
                lappend tolist \
                      "[$to cget -name] <[$to cget -email]>"
            }
            upvar $CCAddrsVar cclist
            set cclist {}
            foreach cc [$getToCcAddressesDialogCcList children {}] {
                lappend cclist \
                      [$cc cget -name] <[$cc cget -email]>"
            }
        }
        return $result
    }
    typemethod _GetToCcAddressesDialog_OK {} {
        $_getToCcAddressesDialog withdraw
        return [$_getToCcAddressesDialog enddialog ok]
    }
    typemethod _GetToCcAddressesDialog_Cancel {} {
        $_getToCcAddressesDialog withdraw
        return [$_getToCcAddressesDialog enddialog cancel]
    }
    typeconstructor {
        set _viewEditDialog {}
        set _getToCcAddressesDialog {}
        set _newEMailAddressDialog {}
    }
}

package provide AddressBook 1.0
