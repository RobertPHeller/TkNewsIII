#!/usr/local/bin/tclkit
##############################################################################
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Thu May 16 20:21:44 2013
#  Last Modified : <130516.2243>
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
lappend auto_path  /usr/share/tcl8.4/tcllib-1.11.1 /usr/lib [pwd]
package require snit
package require Img

package require MainFrame
package require ScrollWindow
package require DynamicHelp
package require IconImage

pack [ScrolledWindow .sw -scrollbar vertical -auto vertical] -expand yes -fill both
.sw setwidget [ttk::treeview [.sw getframe].arts \
               -show {tree headings} -columns {subject from date size mindex} \
               -displaycolumns {subject from date size}]
set arts  [.sw getframe].arts

$arts column #0 -width 100 -stretch no -anchor w
$arts column subject -stretch yes -anchor w -width 300   
$arts heading subject -text Subject -anchor w
$arts column from -stretch yes -anchor w -width 200
$arts heading from -text From -anchor w
$arts column date -stretch yes -anchor w -width 200
$arts heading date  -text Date -anchor w
$arts column size -width 100 -anchor e
$arts heading size  -text Size -anchor e

set artdir {/home/heller/DeepSoft/Saved/comp/lang/tcl/cross-platform-printing}
set articlesUnsorted [glob -nocomplain -tails -directory $artdir *]
set articles [lsort -integer [lsearch -all -inline -regexp \
                              $articlesUnsorted {^[0-9]+$}]]
array set inreplytos {}
foreach a $articles {
    set file [file join $artdir $a]
    set size [file size $file]
    set fp [open $file r]
    set messageid {}
    set inreplyto {}
    set subject {}
    set date {}
    set from {}
    set hbuffer {}
    while {[gets $fp line] >= 0} {
        #puts stderr "*** line is '$line'"
        set line [string trimright $line]
        if {[regexp {^[[:space:]]} $line] > 0} {
            append hbuffer $line
            continue
        } elseif {$hbuffer ne {}} {
            #puts stderr "*** hbuffer is '$hbuffer'"
            if {[regexp {^([^\:]+):[[:space:]]+(.*)$} $hbuffer -> key value] > 0} {
                set key [string tolower $key]
                switch $key {
                    from {set from $value}
                    date {set date $value}
                    subject {set subject $value}
                    in-reply-to {set inreplyto $value}
                    message-id {set messageid $value}
                }
            }
        }
        set hbuffer $line
        if {$line eq {}} {break}
    }
    close $fp
    #    puts stderr "*** $inreplyto: $messageid: $subject $from $date $size $a"
    update idle
    set parent $inreplyto
    if {$inreplyto ne {}} {
        if {![$arts exists $inreplyto]} {set parent {}}
    }
    if {[$arts exists $messageid]} {
        $arts item $messageid -values [list $subject $from $date $size $a]
        if {[$arts parent $messageid] ne $inreplyto &&
            [$arts exists $inreplyto]} {
            $arts move $messageid $inreplyto end
            puts stderr "*** moved (1) $messageid under $inreplyto"
        }
    } else {
        $arts insert $parent end -id $messageid -text {} -open yes \
              -values [list $subject $from $date $size $a]
    }
    set inreplytos($messageid) $inreplyto
}
foreach messageid [array names inreplytos] {
    update idle
    set parent $inreplytos($messageid)
    #puts stderr "*** parent of $messageid is $parent"
    if {[$arts parent $messageid] eq $parent} {continue}
    if {![$arts exists $parent]} {continue}
    $arts move $messageid $parent end
    puts stderr "*** moved (2) $messageid under $parent"
}
