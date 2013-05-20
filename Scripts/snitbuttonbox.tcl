##############################################################################
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Mon May 20 10:03:07 2013
#  Last Modified : <130520.1120>
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


snit::widget ButtonBox {
    hulltype ttk::frame
    widgetclass ButtonBox
    typeconstructor {
        ttk::style layout $type [ttk::style layout TFrame]
    }
    delegate option * to hull except {-class -style}
    variable buttons -array {}
    option -orient -default horizontal \
          -type {snit::enum -values {horizontal vertical}}
    constructor {args} {
        $hull configure -style $type
        $self configurelist $args
    }
    option -state -default normal \
          -type {snit::enum -values {normal disabled}} \
          -configuremethod _configState
    method _configState {option value} {
        set options($option) $value
        foreach b [array names buttons] {
            $buttons($b) configure -state $value
        }
    }
    method add {const name args} {
        switch $options(-orient) {
            horizontal {
                set col [llength [array names buttons]]
                set row 0
                grid columnconfigure $win $col -uniform buttoncol -weight 1 -pad 6
            }
            vertical {
                set row [llength [array names buttons]]
                set col 0
                grid rowconfigure $win $row -uniform buttoncol -weight 1 -pad 6
            }
        }
        set buttons($name) [eval [list $const $win.$name] $args]
        grid $buttons($name) -column $col -row $row -sticky news
        #$buttons($name) configure -state $options(-state)
    }
    method itemconfigure {name args} {
        return [eval [list $win.$name configure] $args]
    }
    method itemcget {name option} {
        return [eval [list $win.$name cget $option]]
    }
}

package provide ButtonBox 1.0
        