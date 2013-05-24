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
#  Last Modified : <130524.1522>
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
    
    option -style -default Dialog
    option -title -default {} -configuremethod _configTitle
    method _configTitle {option value} {
        set options($option) $value
        wm title $win $value
    }
    option -geometry -default {} -configuremethod _configGeometry \
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
          -type {snit::enum -values {none center left right above below}}
    
    component bbox
    component frame
    component sep
    component label
    typeconstructor {
        ttk::style layout Dialog {
            Dialog.bbox -side bottom -sticky we
            Dialog.frame -sticky nswe
            Dialog.sep -side bottom -sticky we
            Dialog.label -side left -sticky nw
        }
        ttk::style configure Dialog \
              -borderwidth [ttk::style lookup "." -borderwidth] \
              -background [ttk::style lookup "." -background] \
              -relief raised \
              -framerelief flat \
              -frameborderwidth 0 \
              ;
        
        
        bind Dialog <<ThemeChanged>> [mytypemethod _ThemeChanged %W]
        bind Dialog <Escape>         [mytypemethod _Escape %W]
        bind Dialog <Return>         [mytypemethod _Return %W]
    }
    typemethod _ThemeChanged {w} {
        $w _ThemeChanged
    }
    typemethod _Escape {w} {
        return [$w  _Escape]
    }
    typemethod _Return {w} {
        return [$w _Return]
    }
    method _ThemeChanged {} {
        set background [ttk::style lookup $options(-style) -background]
        $win configure \
              -borderwidth [ttk::style lookup $options(-style) -borderwidth] \
              -background $background \
              -relief [ttk::style lookup $options(-style) -relief]
        $frame configure \
              -borderwidth [ttk::style lookup $options(-style) \
                            -frameborderwidth] \
              -background $background \
              -relief [ttk::style lookup $options(-style) -framerelief]
        if {[info exists $label] &&
            [winfo exists $label]} {$label configure -background $background}
        if {[info exists $sep] &&
            [winfo exists $sep]} {$sep configure -background $background}
    }
    method _Escape {} {
        return [$bbox invoke $options(-cancel)]
    }
    method _Return {} {
        return [$bbox invoke default]
    }
    ##delegate method add to bbox
    delegate method itemconfigure to bbox
    delegate method itemcget to bbox
    delegate method invoke to bbox
    delegate method setfocus to bbox
    delegate option -state to bbox
    delegate option -default to bbox
    
    variable realized no
    variable nbut 0
    variable result
    variable savedfocus
    variable savedgrab
    variable savedgrabopt
    
    constructor {args} {
        set options(-style) [from args -style]
        set options(-class) [from args -class]
        installhull using tk::toplevel -class $options(-class) \
              -relief [ttk::style lookup $options(-style) -relief] \
              -borderwidth [ttk::style lookup $options(-style) -borderwidth]
        wm withdraw $win
        wm overrideredirect $win 1
        set options(-title) [from args -title]
        wm title $win $options(-title)
        set options(-parent) [from args -parent [winfo parent $win]]
        set options(-transient) [from args -transient]
        if {$options(-transient)} {
            wm transient $win [winfo toplevel $options(-parent)]
        }
        set options(-side) [from args -side]
        if {[lsearch {left right} $options(-side) ] >= 0} {
            set orient vertical
        } else {
            set orient horizontal
        }
        install bbox using ButtonBox $win.bbox -orient $orient
        install frame using ttk::frame $win.frame \
              -relief [ttk::style lookup $options(-style) -framerelief] \
              -borderwidth [ttk::style lookup $options(-style) \
                            -frameborderwidth]
        set background [ttk::style lookup $options(-style) -background]
        $win configure -background $background
        $frame configure -background $background
        set options(-bitmap) [from args -bitmap]
        set options(-image) [from args -image]
        if {$options(-bitmap) ne ""} {
            install label using ttk::label $win.label \
                  -bitmap $options(-bitmap) -background $background
        } elseif {$options(-image) ne ""} {
            install label using ttk::label $win.label \
                  -image $options(-image) -background $background
        }
        set options(-separator) [from args -separator]
        if {$options(-separator)} {
            install sep using ttk::separator $win.sep -orient $orient \
                  -background $background
        }
        $self configurelist $args
    }
    method getframe {} {return $frame}
    method add {name args} {
        set cmd [list $bbox add ttk::button $name \
                 -command [from args -command \
                           [mymethod enddialog $nbut]]]
        set res [eval $cmd $args]
        incr nbut
        return $res
    }
    method enddialog {res} {
        set result $res
    }
    method draw {{focus ""} {overrideredirect no} {geometry ""}} {
        set parent $options(-parent)
        if { !$realized } {
            set realized yes
            if { [llength [winfo children $bbox]] } {
                set side $options(-side)
                if {[lsearch {left right} $options(-side) ] >= 0} {
                    set pad -padx
                    set fill y
                } else {
                    set pad -pady
                    set fill x
                }
                pack $bbox -side $side -padx 1m -pady 1m \
                      -anchor $options(-anchor)
                if {[info exists $sep] &&
                    [winfo exists $sep]} {
                    pack $sep -side $side -fill $fill $pad 2m
                }
            }
            if {[info exists $label] &&
                [winfo exists $label]} {
                pack $label -side left -anchor n -padx 3m -pady 3m
            }
            pack $frame -padx 1m -pady 1m -fill both -expand yes
        }
        set geom $options(-geometry)
        if {$geometry eq "" && $geom eq ""} {
            set place $options(-place)
            if {$place ne "none"} {
                if {[winfo exists $parent]} {
                    _place $win 0 0 $place $parent
                } else {
                    _place $win 0 0 $place
                }
            }
        } else {
            if { $geom ne "" } {
                wm geometry $win $geom
            } else {
                wm geometry $win $geometry
            }
        }
        update idletasks
        wm overrideredirect $win $overrideredirect
        wm deiconify $win
        if {![winfo exists $parent] ||
            ([wm state [winfo toplevel $parent]] ne "withdrawn")} {
            tkwait visibility $win
        }
        set savedfocus [focus -displayof $win]
        focus $win
        if {[winfo exists $focus]} {
            focus -force $focus
        } else {
            $bbox setfocus default
        }
        if {[set grab $options(-modal)] ne "none"} {
            set savedgrab [grab current]
            if {[winfo exists $savedgrab]} {
                set savedgrabopt [grab status $savedgrab]
            }
            if {$grab eq "global"} {
                grab -global $win
            } else {
                grab $win
            }
            if {[info exists result]} {unset result}
            tkwait variable [myvar result]
            if {[info exists result]} {
                set res $result
                unset result
            } else {
                set res -1
            }
            $self withdraw $win
            return $res
        }
        return ""
    }
    method withdraw {} {
        focus $savedfocus
        if {[winfo exists $win]} {grab release $win}
        if {[winfo exists $savedgrab]} {
            if {$savedgrabopt eq "global"} {
                grab -global $savedgrab
            } else {
                grab $savedgrab
            }
        }
        if {[winfo exists $win]} {wm withdraw $win}
    }
    destructor {
        catch {$self enddialog -1}
        catch {focus $savedfocus}
        catch {grab release $win}
    }
}
 
package provide Dialog 1.0
