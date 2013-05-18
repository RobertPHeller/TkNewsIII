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

package require snit
package require BWidget

namespace eval AddressBook {
  snit::type AddressBook {
    typevariable addresses -array {}
    typevariable filename ~/.TkNewsAddresses
    typevariable isdirtyP no


    option -nickname -default {}
    option -email -default {} -readonly yes
    option -name  -default {}
    option -organization -default {}
    option -phone -default {}
    option -streetaddress -default {}
    option -city -default {}
    option -state -default {}
    option -zipcode -default {}
    option -flags -default {}
    constructor {args} {
#      puts stderr "*** $type create $self $args"
      $self configurelist $args
      if {[string length "$options(-email)"] > 0 && 
	  [catch {set addresses([$options(-email)])}]} {
	set addresses($options(-email)) $self
	set isdirtyP yes
	$type _UpdateViewEditList
      } else {
	error "Duplicate or empty Address: $options(-email)"
      }
    }
    destructor {
      if {![catch {unset addresses($options(-email))}]} {
	set isdirtyP yes
	$type _UpdateViewEditList
      }
    }
    typemethod CheckNewAddresses {tofield} {
      set tolist [Common::SmartSplit [string trim "$tofield"] ","]
      foreach to $tolist {
	set to [string trim "$to"]
	set toEM [string tolower [Common::GetRFC822EMail "$to"]]
        set toName [Common::GetRFC822Name "$to"]
	if {![Common::ValidEMailAddress "$toEM"]} {continue}
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
      catch {$viewEditDirtyInd configure -foreground black}
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
    typecomponent      viewEditListSW
    typecomponent	 viewEditList
    typevariable	   viewEditListRows 0
    typecomponent	   viewEditNicknameSortButton
    typevariable	   viewEditNicknameColumn
    typecomponent          viewEditEmailSortButton
    typevariable	   viewEditEmailColumn
    typecomponent	   viewEditNameSortButton
    typevariable	   viewEditNameColumn
    typecomponent	   viewEditOrganizationSortButton
    typevariable	   viewEditOrganizationColumn
    typecomponent	   viewEditPhoneSortButton
    typevariable	   viewEditPhoneColumn
    typecomponent	   viewEditStreetAddressSortButton
    typevariable	   viewEditStreetAddressColumn
    typecomponent	   viewEditCitySortButton
    typevariable	   viewEditCityColumn
    typecomponent	   viewEditStateSortButton
    typevariable	   viewEditStateColumn
    typecomponent	   viewEditZipcodeSortButton
    typevariable	   viewEditZipcodeColumn
    typecomponent	   viewEditFlagsLabel
    typevariable	   viewEditFlagsColumn
    typecomponent      viewEditAddress
    typecomponent	 viewEditAddressEmail
    typecomponent	 viewEditAddressNickname
    typecomponent	 viewEditAddressName
    typecomponent	 viewEditAddressOrganization
    typecomponent	 viewEditAddressPhone
    typecomponent	 viewEditAddressStreetAddress
    typecomponent	 viewEditAddressCity
    typecomponent	 viewEditAddressState
    typecomponent	 viewEditAddressZipcode
    typecomponent        viewEditAddressFlags
    typecomponent	   viewEditAddressHiddenFlag
    typevariable	   viewEditAddressHiddenFlagVar no
    typecomponent	   viewEditAddressCollectedFlag
    typevariable	   viewEditAddressCollectedFlagVar no
    typemethod _CreateViewEditDialog {args} {
      if {![string equal "$_viewEditDialog" {}]} {return}
      set _viewEditDialog [toplevel ._viewEditDialog]
      global IconBitmap IconBitmapMask
      wm iconbitmap $_viewEditDialog $IconBitmap
      wm iconmask   $_viewEditDialog $IconBitmapMask
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
      set menu [list \
	"&File" {file:menu} {file} 0 [list \
	    [list command "&New" {file:new} "Clear Address Book" {Ctrl n} -command [mytypemethod _ClearAddressBook]] \
	    [list command "&Save" {file:save} "Save Address Book" {Ctrl s} -command [mytypemethod WriteAddressBookFileIfDirty]] \
	    [list command "&Export" {file:export} "Export Address Book" {Ctrl e} -command [mytypemethod Export -parent $_viewEditDialog]] \
	    {separator} \
	    [list command "&Close" {file:close} "Close Address Book" {Ctrl c} -command [mytypemethod _CloseViewEdit]] \
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
      set viewEditMain [MainFrame $_viewEditDialog.viewEditMain -menu $menu \
				-textvariable [mytypevar viewEditMainStatus] \
				-progressvar [mytypevar viewEditMainProgress] \
				-progressmax 100]
      pack $viewEditMain -expand yes -fill both
      $viewEditMain showstatusbar progression
      set viewEditToolBar [$viewEditMain addtoolbar]
      set viewEditToolBarNewAddress \
	[Button $viewEditToolBar.viewEditToolBarNewAddress -name new \
		-text "New Address" -command [mytypemethod _CreateNewAddress]]
      pack $viewEditToolBarNewAddress -side left
      set viewEditToolBarShowHideHidden \
	[Button $viewEditToolBar.viewEditToolBarShowHideHidden -name showhide \
		-text "Show Hidden" -command [mytypemethod _ToggleHidden]]
      pack $viewEditToolBarShowHideHidden -side left
      set viewEditToolBarDeleteAddress \
	[Button $viewEditToolBar.viewEditToolBarDeleteAddress -name delete \
		-text "Delete Address" -state disabled \
		-command [mytypemethod _DeleteSelectedAddress]]
      pack $viewEditToolBarDeleteAddress -side left
      set viewEditDirtyInd [$viewEditMain addindicator -bitmap gray50]
      set mframe [$viewEditMain getframe]
      set viewEditPane [PanedWindow $mframe.viewEditPane -side left]
      pack $viewEditPane -expand yes -fill both
      set  top [$viewEditPane add -minsize 10 -weight 1]
      set  bottom [$viewEditPane add -weight 3]
      set viewEditListSW [ScrolledWindow $top.viewEditListSW -auto both -scrollbar both]
      pack $viewEditListSW -expand yes -fill both
      set viewEditList [ScrollableFrame [$viewEditListSW getframe].viewEditList]
      pack $viewEditList -expand yes -fill both
      $viewEditListSW setwidget $viewEditList
      set lframe [$viewEditList getframe]
      set col 0
      foreach w {Nickname Email Name Organization Phone StreetAddress City 
		 State Zipcode} {
	set viewEdit${w}SortButton [Button $lframe.viewEdit${w}SortButton\
					-text $w -command [mytypemethod _SortViewBy$w]]
	grid [set viewEdit${w}SortButton] -column $col -row 0 -sticky news
	set viewEdit${w}Column $col
	incr col
      }
      set viewEditFlagsLabel [Label $lframe.viewEditFlagsLabel -relief raised \
      				-text Flags -anchor c]
      grid $viewEditFlagsLabel -column $col -row 0 -sticky news
      set viewEditFlagsColumn $col
      incr col
      set viewEditAddress [TitleFrame $bottom.viewEditAddress -side left]
      pack $viewEditAddress -expand yes -fill both
      set vaframe [$viewEditAddress getframe]
      foreach w {Email Nickname Name Organization Phone StreetAddress City 
		 State Zipcode} {
	if {[string equal "$w" "Email"]} {
	  set editable no
	} else {
	  set editable yes
	}
	set viewEditAddress$w [LabelEntry $vaframe.viewEditAddress$w \
						   -label ${w}: \
						   -labelwidth 20 \
						   -editable $editable]
	pack [set viewEditAddress$w] -fill x
	if {$editable} {
	  [set viewEditAddress$w] bind <Return> [mytypemethod _UpdateAddress]
	}
      }
      set viewEditAddressFlags [LabelFrame $vaframe.viewEditAddressFlags \
					-text Flags: -width 20]
      pack $viewEditAddressFlags -fill x
      set flframe [$viewEditAddressFlags getframe]
      set viewEditAddressHiddenFlag [checkbutton $flframe.viewEditAddressHiddenFlag \
					-command [mytypemethod _UpdateAddress] \
					-indicatoron yes -text hidden \
					-offvalue no -onvalue yes \
					-variable [mytypevar viewEditAddressHiddenFlagVar]]
      pack $viewEditAddressHiddenFlag -side left
      set viewEditAddressCollectedFlag [checkbutton $flframe.viewEditAddressCollectedFlag \
					-command [mytypemethod _UpdateAddress] \
					-indicatoron yes -text collected \
					-offvalue no -onvalue yes \
					-variable [mytypevar viewEditAddressCollectedFlagVar]]
      pack $viewEditAddressCollectedFlag -side left
    }
    typemethod _ToggleHidden {} {
      if {$viewEditToolBarShowHidden} {
	$viewEditToolBarShowHideHidden configure -text "Show Hidden"
	set viewEditToolBarShowHidden no
	if {$SelectedRow > 0 &&
	    $viewEditAddressHiddenFlagVar} {$type _SelectRow 0}
      } else {
	$viewEditToolBarShowHideHidden configure -text "Hide Hidden"
	set viewEditToolBarShowHidden yes
      }
      $type _UpdateViewEditList      
    }
    typevariable _CurrentSort Nickname
    typemethod _SortViewByNickname {} {
      $type _InsertNewView [lsort -command [mytypemethod _SortByNickname] [array names addresses]]
      set _CurrentSort Nickname
    }
    typemethod _SortByNickname {a b} {
      return [string compare -nocase "[$addresses($a) cget -nickname]" \
				     "[$addresses($b) cget -nickname]"]
    }
    typemethod _SortViewByEmail {} {
      $type _InsertNewView [lsort -dictionary [array names addresses]]
      set _CurrentSort Email
    }
    typemethod _SortViewByName {} {
      $type _InsertNewView [lsort -command [mytypemethod _SortByName] [array names addresses]]
      set _CurrentSort Name
    }
    typemethod _SortByName {a b} {
      return [string compare -nocase "[$addresses($a) cget -name]" \
				     "[$addresses($b) cget -name]"]
    }
    typemethod _SortViewByOrganization {} {
      $type _InsertNewView [lsort -command [mytypemethod _SortByOrganization] [array names addresses]]
      set _CurrentSort Organization
    }
    typemethod _SortByOrganization {a b} {
      return [string compare -nocase "[$addresses($a) cget -organization]" \
				     "[$addresses($b) cget -organization]"]
    }
    typemethod _SortViewByPhone {} {
      $type _InsertNewView [lsort -command [mytypemethod _SortByPhone] [array names addresses]]
      set _CurrentSort Phone
    }
    typemethod _SortByPhone {a b} {
      return [string compare -nocase "[$addresses($a) cget -phone]" \
				     "[$addresses($b) cget -phone]"]
    }
    typemethod _SortViewByStreetAddress {} {
      $type _InsertNewView [lsort -command [mytypemethod _SortByStreetAddress] [array names addresses]]
      set _CurrentSort StreetAddress
    }
    typemethod _SortByStreetAddress {a b} {
      return [string compare -nocase "[$addresses($a) cget -streetaddress]" \
				     "[$addresses($b) cget -streetaddress]"]
    }
    typemethod _SortViewByCity {} {
      $type _InsertNewView [lsort -command [mytypemethod _SortByCity] [array names addresses]]
      set _CurrentSort City
    }
    typemethod _SortByCity {a b} {
      return [string compare -nocase "[$addresses($a) cget -city]" \
				     "[$addresses($b) cget -city]"]
    }
    typemethod _SortViewByState {} {
      $type _InsertNewView [lsort -command [mytypemethod _SortByState] [array names addresses]]
      set _CurrentSort State
    }
    typemethod _SortByState {a b} {
      return [string compare -nocase "[$addresses($a) cget -state]" \
				     "[$addresses($b) cget -state]"]
    }
    typemethod _SortViewByZipcode {} {
      $type _InsertNewView [lsort -command [mytypemethod _SortByZipcode] [array names addresses]]
      set _CurrentSort Zipcode
    }
    typemethod _SortByZipcode {a b} {
      return [string compare -nocase "[$addresses($a) cget -zipcode]" \
				     "[$addresses($b) cget -zipcode]"]
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
    typemethod _InsertNewView {indexlist} {
      $type SetBusy $_viewEditDialog yes
      set viewEditMainStatus "Inserting new view..."
      set irow 0
      set done 0
      set count 0
      set lframe [$viewEditList getframe]
#      puts stderr "*** $type _InsertNewView: viewEditListRows = $viewEditListRows"
      set maxrows [expr {double([llength $indexlist])}]
      set tenth [expr {int($maxrows / 10.0)}]
      foreach i $indexlist {
	incr count
	if {$count == $tenth} {
	  incr done $tenth
	  set viewEditMainProgress [expr {int(100*(double($done) / $maxrows))}]
	  set count 0
	  update
	} 
	if {!$viewEditToolBarShowHidden &&
	    [lsearch [$addresses($i) cget -flags] hidden] >= 0} {continue}
	incr irow
#	puts stderr "*** $type _InsertNewView: i = $i, irow = $irow"
	foreach opt {-nickname -email -name -organization -phone 
		     -streetaddress -city -state -zipcode -flags} \
		wid {nickname email name organization phone streetaddress city 
		     state zipcode flags} \
	        www {Nickname Email Name Organization Phone StreetAddress City
		     State Zipcode Flags} {
	  if {$irow <= $viewEditListRows} {
	    $lframe.$wid$irow configure -text [$addresses($i) cget $opt]
	    grid $lframe.$wid$irow
	  } else {
	    Label $lframe.$wid$irow -text [$addresses($i) cget $opt] -anchor w 
	    set WatchList($lframe.$wid$irow) {}
	    bind $lframe.$wid$irow <1> [mytypemethod _SelectRow $irow]
	    set col [set viewEdit${www}Column]
	    grid $lframe.$wid$irow -row $irow -column $col -sticky news
	  }
	}
      }
      if {$irow > $viewEditListRows} {
	set viewEditListRows $irow
      } elseif {$irow < $viewEditListRows} {
	while {$irow < $viewEditListRows} {
	  incr irow
	  foreach wid {nickname email name organization phone streetaddress city
                     state zipcode flags} {
	    grid remove $lframe.$wid$irow
	  }
	}
      }
      set viewEditMainProgress 100
      $type SetBusy $_viewEditDialog no
      set viewEditMainStatus "Done"
    }
    typevariable SelectedRow 0
    typemethod _SelectRow {row} {
      set lframe [$viewEditList getframe]
      if {$SelectedRow > 0} {
	foreach wid {nickname email name organization phone streetaddress city
                     state zipcode flags} {
	  set bg [$lframe.$wid$SelectedRow cget -background]
	  set fg [$lframe.$wid$SelectedRow cget -foreground]
	  $lframe.$wid$SelectedRow configure -background $fg -foreground $bg
	}
      }
      $type _ClearAddress
      $viewEditToolBarDeleteAddress configure -state disabled
      set SelectedRow $row
      if {$SelectedRow == 0} {return}
      foreach wid {nickname email name organization phone streetaddress city
                   state zipcode flags} {
	set bg [$lframe.$wid$SelectedRow cget -background]
	set fg [$lframe.$wid$SelectedRow cget -foreground]
	$lframe.$wid$SelectedRow configure -background $fg -foreground $bg
      }
      $type _FillAddress "[$lframe.email$SelectedRow cget -text]"
      $viewEditToolBarDeleteAddress configure -state normal
    }
    typemethod _FillAddress {email} {
      $viewEditAddress configure -text "[$addresses($email) cget -name]"
      foreach w {Email Nickname Name Organization Phone StreetAddress City
                 State Zipcode} \
	      o {-email -nickname -name -organization -phone -streetaddress 
		 -city -state -zipcode} {
	[set viewEditAddress$w] configure -text "[$addresses($email) cget $o]"
      }
      set flags [$addresses($email) cget -flags]
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
      $viewEditAddress configure -text {}
      foreach w {Email Nickname Name Organization Phone StreetAddress City
		 State Zipcode} {
	[set viewEditAddress$w] configure -text {}
      }
    }
    typemethod _UpdateAddress {} {
      set email [$viewEditAddressEmail cget -text]
      if {[catch {set addresses($email)} ad]} {return}
      $ad configure -nickname      "[$viewEditAddressNickname cget -text]"
      $ad configure -name          "[$viewEditAddressName cget -text]"
      $ad configure -organization  "[$viewEditAddressOrganization cget -text]"
      $ad configure -phone         "[$viewEditAddressPhone cget -text]"
      $ad configure -streetaddress "[$viewEditAddressStreetAddress cget -text]"
      $ad configure -city          "[$viewEditAddressCity cget -text]"
      $ad configure -state         "[$viewEditAddressState cget -text]"
      $ad configure -zipcode       "[$viewEditAddressZipcode cget -text]"
      set flags {}
      if {$viewEditAddressHiddenFlagVar} {lappend flags hidden}
      if {$viewEditAddressCollectedFlagVar} {lappend flags collected}
      $ad configure -flags $flags
      $viewEditAddress configure -text "[$ad cget -name]"
      set isdirtyP yes
      if {!$viewEditToolBarShowHidden && 
	  $viewEditAddressHiddenFlagVar} {$type _SelectRow 0}
      $type _UpdateViewEditList
    }
    typemethod _UpdateViewEditList {} {
#      puts stderr "*** $type _UpdateViewEditList"
      if {[string equal "$_viewEditDialog" {}]} {return}
      if {![winfo ismapped $_viewEditDialog]} {
#	puts stderr "*** $type _UpdateViewEditList: refresh deffered"
	set ViewEditRefresh yes
	return
      }
#      puts stderr "*** $type _UpdateViewEditList: refreshing now"
      $type _SortViewBy$_CurrentSort
      if {$isdirtyP} {
	$viewEditDirtyInd configure -foreground red
      } else {
	$viewEditDirtyInd configure -foreground black
      }
      set ViewEditRefresh no
    }
    typecomponent _newEMailAddressDialog
    typecomponent   newEMailAddressLE
    typemethod _CreateNewEMailAddressDialog {} {
      if {![string equal "$_newEMailAddressDialog" {}]} {return}
      set _newEMailAddressDialog [Dialog ._newEMailAddressDialog \
					-class NewEMailAddressDialog \
					 -bitmap questhead -default 0 \
					 -cancel 1 -modal local -transient yes \
					 -parent $_viewEditDialog -side bottom]
      $_newEMailAddressDialog add -name create -text Create -command [mytypemethod _CreateANewEmailAddress]
      $_newEMailAddressDialog add -name cancel -text Cancel -command [mytypemethod _CancelANewEmailAddress]
      $_newEMailAddressDialog add -name help -text Help -command [list BWHelp::HelpTopic NewEMailAddressDialog]
      set frame [$_newEMailAddressDialog getframe]
      set newEMailAddressLE [LabelEntry $frame.newEMailAddressLE -label "EMail Address:"]
      pack $newEMailAddressLE -fill x
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
#      puts stderr "*** $type _CreateANewEmailAddress: \[Common::ValidEMailAddress \{$EM\}\] => [Common::ValidEMailAddress $EM]"
#      puts stderr "*** $type _CreateANewEmailAddress: \[catch {set addresses($EM)} old\] => [catch {set addresses($EM)} old]"
      if {[Common::ValidEMailAddress "$EM"] && 
	  [catch {set addresses($EM)} old]} {
	$type create %AUTO% -email [$newEMailAddressLE cget -text]
	set lframe [$viewEditList getframe]
	for {set irow 1} {$irow < $viewEditListRows} {incr irow} {
	  if {[string equal "$EM" "[$lframe.email$irow cget -text]"]} {
	    $type _SelectRow $irow
	    break
	  }
	}
      }
      return [$_newEMailAddressDialog enddialog create]
    }
    typemethod _CancelANewEmailAddress {} {
      $_newEMailAddressDialog withdraw
      return [$_newEMailAddressDialog enddialog cancel]
    }
    typemethod _DeleteSelectedAddress {} {
      set email [$viewEditAddressEmail cget -text]
      if {[catch {set addresses($email)} ad]} {return}
      $type _SelectRow 0
      $ad destroy
    }
    typevariable ViewEditRefresh no
    typemethod ViewEdit {args} {
      if {[string equal "$_viewEditDialog" {}]} {
	$type _CreateViewEditDialog $args
	set ViewEditRefresh yes
      }
      wm deiconify $_viewEditDialog
      update idle
      if {$ViewEditRefresh} {
	$type _UpdateViewEditList
      }
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
					-bitmap questhead -default 0 \
					-cancel 1 -modal local -transient yes \
					-parent . -side bottom]
      $_getToCcAddressesDialog add -name ok -text OK -command [mytypemethod _GetToCcAddressesDialog_OK]
      $_getToCcAddressesDialog add -name cancel -text Cancel -command [mytypemethod _GetToCcAddressesDialog_Cancel]
      $_getToCcAddressesDialog add -name help -text Help -command [list BWHelp::HelpTopic GetToCcAddressesDialog]
      set frame [$_getToCcAddressesDialog getframe]
      set getToCcAddressesDialogLeft [frame $frame.getToCcAddressesDialogLeft -relief flat]
      pack $getToCcAddressesDialogLeft -side left -expand yes -fill both
      set getToCcAddressesDialogAllSW [ScrolledWindow $getToCcAddressesDialogLeft.getToCcAddressesDialogAllSW -auto both -scrollbar both]
      pack $getToCcAddressesDialogAllSW -fill both -expand yes
      set getToCcAddressesDialogAll [ListBox [$getToCcAddressesDialogAllSW getframe].getToCcAddressesDialogAll -selectmode multiple]
      pack $getToCcAddressesDialogAll -fill both -expand yes
      $getToCcAddressesDialogAllSW setwidget $getToCcAddressesDialogAll
      set getToCcAddressesDialogRight [frame $frame.getToCcAddressesDialogRight -relief flat]
      pack $getToCcAddressesDialogRight -side right -expand yes -fill both
      set getToCcAddressesDialogToBF [frame $getToCcAddressesDialogRight.getToCcAddressesDialogToBF -relief flat]
      pack $getToCcAddressesDialogToBF -expand yes -fill both
      set getToCcAddressesDialogToButton [Button $getToCcAddressesDialogToBF.getToCcAddressesDialogToButton -text ">> To:" -command [mytypemethod _MoveAddressToToList]]
      pack $getToCcAddressesDialogToButton -side left
      set getToCcAddressesDialogToListSW [ScrolledWindow $getToCcAddressesDialogToBF.getToCcAddressesDialogToListSW -auto both -scrollbar both]
      pack $getToCcAddressesDialogToListSW -side right -expand yes -fill both
      set getToCcAddressesDialogToList [ListBox [$getToCcAddressesDialogToListSW getframe].getToCcAddressesDialogToList -selectmode none]
      pack $getToCcAddressesDialogToList -expand yes -fill both
      $getToCcAddressesDialogToListSW setwidget $getToCcAddressesDialogToList
      set getToCcAddressesDialogCcBF [frame $getToCcAddressesDialogRight.getToCcAddressesDialogCcBF -relief flat]
      pack $getToCcAddressesDialogCcBF -expand yes -fill both
      set getToCcAddressesDialogCcButton [Button $getToCcAddressesDialogCcBF.getToCcAddressesDialogCcButton -text ">> Cc:" -command [mytypemethod _MoveAddressToCcList]]
      pack $getToCcAddressesDialogCcButton -side left
      set getToCcAddressesDialogCcListSW [ScrolledWindow $getToCcAddressesDialogCcBF.getToCcAddressesDialogCcListSW -auto both -scrollbar both]
      pack $getToCcAddressesDialogCcListSW -side right -expand yes -fill both
      set getToCcAddressesDialogCcList [ListBox [$getToCcAddressesDialogCcListSW getframe].getToCcAddressesDialogCcList -selectmode none]
      pack $getToCcAddressesDialogCcList -expand yes -fill both
      $getToCcAddressesDialogCcListSW setwidget $getToCcAddressesDialogCcList
    }
    typemethod _MoveAddressToToList {} {
      set selection [$getToCcAddressesDialogAll selection get]
      foreach s $selection {
	$getToCcAddressesDialogToList insert end $s -text [$getToCcAddressesDialogAll itemcget $s -text] -data [$getToCcAddressesDialogAll itemcget $s -data]
	$getToCcAddressesDialogAll delete $s
      }
    }
    typemethod _MoveAddressToCcList {} {
      set selection [$getToCcAddressesDialogAll selection get]
      foreach s $selection {
	$getToCcAddressesDialogCcList insert end $s -text [$getToCcAddressesDialogAll itemcget $s -text] -data [$getToCcAddressesDialogAll itemcget $s -data]
	$getToCcAddressesDialogAll delete $s
      }
    }
    typemethod GetToCcAddresses {args} {
      if {[string equal "$_getToCcAddressesDialog" {}]} {$type _CreateGetToCcAddressesDialog}
      $getToCcAddressesDialogAll delete [$getToCcAddressesDialogAll items]
      foreach a [lsort -command [mytypemethod _SortByNickname] [array names addresses]] {
	set ad $addresses($a)
	if {[lsearch [$ad cget -flags] hidden] < 0 && 
	    [string length "[$ad cget -nickname]"] > 0} {
	  $getToCcAddressesDialogAll insert end $a -text "[$ad cget -nickname] ([$ad cget -name]) <$a>" \
						 -data "[$ad cget -name] <$a>"
	}
      }
      $getToCcAddressesDialogToList delete [$getToCcAddressesDialogToList items]
      $getToCcAddressesDialogCcList delete [$getToCcAddressesDialogCcList items]
      set parent [from args -parent .]
      $_getToCcAddressesDialog configure -parent $parent
      wm transient [winfo toplevel $_getToCcAddressesDialog] $parent
      set result [$_getToCcAddressesDialog draw]
      if {[string equal "$result" "ok"]} {
        set tolist {}
        foreach to [$getToCcAddressesDialogToList items] {
	  lappend tolist "[$getToCcAddressesDialogToList itemcget $to -data]"
	}
        set cclist {}
        foreach cc [$getToCcAddressesDialogCcList items] {
	  lappend cclist "[$getToCcAddressesDialogCcList itemcget $cc -data]"
	}
        return [list $tolist $cclist]
      } else {
	return [list {} {}]
      }
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
  proc CheckNewAddresses {tofield} {AddressBook CheckNewAddresses "$tofield"}
  proc ViewEdit {args} {eval [list AddressBook ViewEdit] $args}
  proc GetToCcAddresses {ToAddrsVar CCAddrsVar args} {
    upvar $ToAddrsVar ToAddrs
    upvar $CCAddrsVar CCAddrs
    set addresses [eval [list AddressBook GetToCcAddresses] $args]
    set ToAddrs [lindex $addresses 0]
    set CCAddrs [lindex $addresses 1]
  }
  proc LoadAddressBookFile {filename} {AddressBook LoadAddressBookFile "$filename"}
  proc Export {args} {eval [list AddressBook Export] $args}
  proc WriteAddressBookFileIfDirty {} {AddressBook WriteAddressBookFileIfDirty}
}

package provide AddressBook 1.0
