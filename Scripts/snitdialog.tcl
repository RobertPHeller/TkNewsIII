##############################################################################
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Fri May 24 09:50:47 2013
#  Last Modified : <130524.1134>
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


package require Tk
package require tile
package require ButtonBox

snit::widgetadaptor Dialog {
    
    option -title -default {} -configuremethod _configTitle
    method _configTitle {option value} {
        set options($option) $value
        wm title $win $value
    }
    option -geometry -default {} -configmethod _configGeometry \
          -validatemethod _validateGeometry
    method _configGeometry {option value} {
        set options($option) $value
        wm geometry $win $value
    }
    method _validateGeometry {option value} {
        if {[regexp {^=?([[:digit:]]+x[[:digit:]]+)?([+-][[:digit:]]+[+-][[:digit:]]+)?$} "$value"] < 1} {
            error "Malformed value: $value for $option"
        }
    }
    option -modal -default local -type {snit::enum -values {none local global}}
    option -bitmap -default {} -readonly yes 
    option -image -default {} -readonly yes
    option -separator -default no -readonly yes -type snit::boolean
    option -cancel -default {}
    option -parent -default {} -type snit::window
    option -side -default bottom -readonly yes \
          -type {snit::enum -values {bottom left top right}}
    option -anchor -default c -readonly yes \
          -type {snit::enum -values {n e w s c}}
    option -class -default Dialog -readonly yes
    option -transient -default yes -readonly yes -type snit::boolean
    option -place -default center \
          -type {snit::enum {none center left right above below}}
    
    component bbox
    component frame
    component sep
    component label
    delegate method add to bbox
    delegate method itemconfigure to bbox
    delegate method itemcget to bbox
    delegate method invoke to bbox
    delegate method setfocus to bbox
    delegate option -state to bbox
    delegate option -default to bbox
    
    constructor {args} {
        set options(-class) [from args -class]
        installhull using tk::toplevel -class $options(-class) \
              -relief raised -borderwidth 1
        wm withdraw $win
        wm overrideredirect $win 1
        set options(-title) [from args -title]
        wm title $win $options(-title)
        set options(-parent) [from args -parent [winfo parent $win]]
        set options(-transient) [from args -transient]
        if {$options(-transient)} {
            wm transient $win [winfo toplevel $options(-parent)]
        }
        ####            
    }
}

