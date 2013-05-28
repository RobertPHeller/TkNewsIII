#* 
#* ------------------------------------------------------------------
#* Makefile.am - Makefile for the C code
#* Created by Robert Heller on Sat May 27 13:37:18 2006
#* ------------------------------------------------------------------
#* Modification History: $Log$
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

execbindir = $(libdir)/$(PACKAGE)-$(VERSION)/execbin
scriptlibdir = $(datadir)/$(PACKAGE)-$(VERSION)/scriptlib
docdir = $(datadir)/$(PACKAGE)-$(VERSION)/documentation

execbin_PROGRAMS = QWKToSpool qwkReply SpoolToReply headList
#CFlags = -g
#LDFlags = -g

QWKToSpool_SOURCES = QWKToSpool.c qwk.h
qwkReply_SOURCES = qwkReply.c qwk.h
SpoolToReply_SOURCES = SpoolToReply.c qwk.h
headList_SOURCES = headList.c

include $(top_srcdir)/Rules.make


