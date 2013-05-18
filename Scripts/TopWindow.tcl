##############################################################################
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Sat May 18 09:51:58 2013
#  Last Modified : <130518.1135>
#
#  Description	
#
#  Notes
#
#  History
#	
##############################################################################
#
#  Copyright (c) 2013 Deepwoods Software.
# 
#  All Rights Reserved.
# 
#  This  document  may  not, in  whole  or in  part, be  copied,  photocopied,
#  reproduced,  translated,  or  reduced to any  electronic  medium or machine
#  readable form without prior written consent from Deepwoods Software.
#
##############################################################################


package require MainFrame
package require ScrollWindow
package require QWKFunctions

snit::widgetadaptor TopWindow {
    typevariable _menu {
        "&File" {file:menu} {file} 0 {
            {command "&Open QWK File" {file:open} "Open QWK file" {Ctrl o} -command "[mymethod LoadTheSelectedSpool]"}
            {command "&Get QWK File" {file:getq} "Get QWK file" {Ctrl g} -command {QWKFileProcess GetQWKFile}}
            {command "Get &All QWK Files" {file:getaq} "Get All QWK Files" {Ctrl a} -command {QWKFileProcess GetAllQWKFiles}}
            {command "&Review Spool" {file:review} "Review Spool File" {Ctrl r} -command Spool::ReviewSpool}
            {command "Re&scan" {file:rescan} "Rescan spool directory" {Ctrl s} -command "[mymethod RescanQWKSpool]"}
            {command "Ma&ke QWK Reply" {file:make} "Make QWK Reply" {Ctrl k} -command {QWKReplyProcess MakeQWKReply}}
            {command "&Export Address Book" {file:exportab} "Export Address Book as CSV" {Ctrl e} -command AddressBook::Export}
            {command "&Close" {file:close} "Close the application" {Ctrl q} -command "[mymethod CarefulExit]"}
            {command "E&xit" {file:exit} "Exit the application" {Ctrl q} -command "[mymethod CarefulExit]"}
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
            {command "&Address Book" {view:addrbook} "View / Edit Address book" {} -command AddressBook::ViewEdit}
        }
        "&Options" {options:menu} {options} 0 {
        }
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
        }
    }
    component qwkList
    delegate method RescanQWKSpool to qwkList
    delegate method setmenustate to hull
    delegate option -width to hull
    delegate option -height to hull
    variable status
    constructor {args} {
        set menu [subst $_menu]
        installhull using MainFrame -menu $menu -textvariable [myvar status] \
              -width 500 -height 250
        set uframe [$hull getframe]
        set sw [ScrolledWindow $uframe.sw -scrollbar vertical -auto vertical]
        pack $sw -expand yes -fill both
        install qwkList using QWKList [$sw getframe].qwkList \
              -command [mymethod LoadSelectedQWKFile]
        $sw setwidget $qwkList
        set newGeo "[option get [winfo toplevel $win] tocGeometry TocGeometry]"
        #puts stderr "*** $type create $self: winfo toplevel $win is [winfo toplevel $win]"
        #puts stderr "*** $type create $self: newGeo = |$newGeo|"
        if {[string length "$newGeo"] > 0} {
            wm geometry [winfo toplevel $win] "$newGeo"
        }
        bind [winfo toplevel $win] <Control-c> [mymethod LoadTheSelectedSpool]
        bind [winfo toplevel $win] <Control-g> {QWKFileProcess GetQWKFile}
        bind [winfo toplevel $win] <Control-a> {QWKFileProcess GetAllQWKFiles}
        bind [winfo toplevel $win] <Control-r> Spool::ReviewSpool
        bind [winfo toplevel $win] <Control-s> [mymethod RescanQWKSpool]
        bind [winfo toplevel $win] <Control-k> {QWKReplyProcess MakeQWKReply}
        bind [winfo toplevel $win] <Control-q> [mymethod CarefulExit]
        wm protocol [winfo toplevel $win] WM_DELETE_WINDOW [mymethod CarefulExit]
        wm title [winfo toplevel $win] "Tk News III $::BUILDSYMBOLS::VERSION"
    }
    method LoadTheSelectedSpool {} {
        set selection [$qwkList selection]
        if {[llength $selection] == 0} {return}
        $self LoadSelectedQWKFile $selection
    }
    method LoadSelectedQWKFile {selection} {
        #puts stderr "*** $self LoadSelectedQWKFile $selection"
        set file [$qwkList filename "$selection"]
        #puts stderr "*** $self LoadSelectedQWKFile: file is $file"
        Spool::LoadQWKToSpool $file
    }
    method CarefulExit {{dontask no}} {
        #set loadedSpools [Spool::SpoolWindow loadedSpools]
        #if {[llength $loadedSpools] > 0} {
        #    set ans yes
        #    if {!$dontask} {
        #        set ans [tk_messageBox \
        #                 -icon question \
        #                 -type yesno \
        #                 -message {There are loaded spools -- Close them and exit?}]
        #    }
        #    if {$ans eq "yes"} {
        #        foreach spoolname $loadedSpools {
        #            set spool [Spool::SpoolWindow getSpoolByName $spoolname]
        #            destroy $spool
        #        }
        #        set dontask yes
        #    }
        #}
        if {$dontask} {
            set ans yes
        } else {
            set ans [tk_messageBox -icon question -type yesno \
                     -message {Really Exit }]
        }
        switch -exact "$ans" {
            no {return}
            yes {
                exit
            }
        }
    }
}

package provide TopWindow 1.0
