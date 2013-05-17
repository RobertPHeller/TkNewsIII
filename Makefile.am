#* 
#* ------------------------------------------------------------------
#* Makefile.am - Toplevel Makefile
#* Created by Robert Heller on Sat May 27 13:36:32 2006
#* ------------------------------------------------------------------
#* Modification History: $Log$
#* Modification History: Revision 1.2  2007/07/12 16:54:45  heller
#* Modification History: Lockdown: 1.0.4
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
ACLOCAL_AMFLAGS = -I m4

execbindir = $(libdir)/$(PACKAGE)-$(VERSION)/execbin
scriptlibdir = $(datadir)/$(PACKAGE)-$(VERSION)/scriptlib
docdir = $(datadir)/$(PACKAGE)-$(VERSION)/documentation

bin_SCRIPTS = TkNewsII$(EXEEXT) Split_flatmessagefile$(EXEEXT)
SUBDIRS = BuildScripts C Scripts Docs GpgME

LibraryScripts = Scripts/BWHelp.tcl Scripts/labelselectcolor.tcl \
		Scripts/panedw.tcl Scripts/fileentry.tcl \
		Scripts/labelspinbox.tcl Scripts/splash.tcl \
		Scripts/labelcombobox.tcl Scripts/mainwindow.tcl \
                Scripts/BWStdMenuBar.tcl Scripts/CommonFunctions.tcl \
		Scripts/SpoolFunction.tcl Scripts/GroupFunctions.tcl \
                Scripts/ArticleFunctions.tcl Scripts/QWKFunctions.tcl \
		Scripts/AddressBook.tcl \
		BUILDSYMBOLS.tcl
LibraryGIFS = Scripts/close.gif Scripts/new.gif Scripts/open.gif \
		Scripts/print.gif Scripts/save.gif Scripts/DeepwoodsBanner.gif \
		Scripts/TkNewsIIicon.gif
LibraryXBMS = Scripts/TkNewsIIicon.xbm  Scripts/TkNewsIIicon_mask.xbm
TkNewsIIDATA = $(LibraryScripts) $(LibraryGIFS) $(LibraryXBMS)
Split_flatmessagefileDATA = Scripts/CommonFunctions.tcl

EXTRA_DIST = Rules.make $(PACKAGE).spec.in $(PACKAGE).spec BUILDSYMBOLS.tcl.in \
            bootstrap
CLEANFILES = TkNewsII Split_flatmessagefile
TkNewsII$(EXEEXT): Scripts/TkNewsII.src $(TkNewsIIDATA) $(LibraryScripts) \
			$(LibraryGIFS) $(LibraryXBMS) \
			Help/index.hh Help/*.gif Help/hh.index \
			GpgME/gpgme.la GpgME/pkgIndex.tcl
	-rm -f  TkNewsII.kit
	-rm -f  TkNewsII$(EXEEXT)
	-rm -rf TkNewsII.vfs
	$(TCLKIT) $(SDX) qwrap $(srcdir)/Scripts/TkNewsII.src
	$(TCLKIT) $(SDX) unwrap TkNewsII.kit
	-rm -f  TkNewsII.kit
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsII \
		lib $(BWLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsII \
		lib $(SNITLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsII \
		lib $(URILIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsII \
		lib $(NCGILIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsII \
		lib $(FILEUTILLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsII \
		lib $(CMDLINELIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit TkNewsII \
	        lib/GpgME GpgME/.libs/gpgme.so GpgME/pkgIndex.tcl
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) TkNewsII \
		lib/Common $(TkNewsIIDATA)
	$(TCLKIT) $(top_srcdir)/BuildScripts/MakePkgIndex.kit TkNewsII \
		Common
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit TkNewsII \
		Help $(top_builddir)/Help/*.hh $(top_builddir)/Help/*.gif \
		     $(top_builddir)/Help/hh.index
	$(TCLKIT) $(SDX) wrap TkNewsII$(EXEEXT) -runtime $(TCLKITRUN)
	-rm -rf  TkNewsII.vfs

$(top_builddir)/Help/hh.index : \
	$(top_builddir)/Help/*.hh
	$(MAKE) -C $(top_builddir)/Help/hh.index

$(top_builddir)/Help/index.hh : \
	$(top_builddir)/Help/*.hh
	$(MAKE) -C $(top_builddir)/Help/index.hh


Split_flatmessagefile$(EXEEXT): Scripts/Split_flatmessagefile.src \
			$(Split_flatmessagefileDATA)
	-rm -f  Split_flatmessagefile.kit
	-rm -f  Split_flatmessagefile$(EXEEXT)
	-rm -rf Split_flatmessagefile.vfs
	$(TCLKIT) $(SDX) qwrap $(srcdir)/Scripts/Split_flatmessagefile.src
	$(TCLKIT) $(SDX) unwrap Split_flatmessagefile.kit
	-rm -f  Split_flatmessagefile.kit
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit Split_flatmessagefile \
		lib $(SNITLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) Split_flatmessagefile \
		lib/Common $(Split_flatmessagefileDATA)
	$(TCLKIT) $(top_srcdir)/BuildScripts/MakePkgIndex.kit Split_flatmessagefile \
		Common
	$(TCLKIT) $(SDX) wrap Split_flatmessagefile$(EXEEXT) -runtime $(TCLKITRUN)
	-rm -rf  Split_flatmessagefile.vfs


GpgME/gpgme.la : GpgME/gpgme.i
	$(MAKE) -C GpgME gpgme.la
	
GpgME/pkgIndex.tcl : GpgME/gpgme.la
	$(MAKE) -C GpgME pkgIndex.tcl
