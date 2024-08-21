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

bin_SCRIPTS = TkNewsIII$(EXEEXT) Split_flatmessagefile$(EXEEXT)
SUBDIRS = BuildScripts BuildData C Scripts Docs #GpgME
#doc_DATA = refman.pdf

LibraryScripts = BUILDSYMBOLS.tcl \
            Scripts/DynamicHelp.tcl Scripts/IconsAndImages.tcl \
            Scripts/snitmainframe.tcl Scripts/snitscrollw.tcl \
            Scripts/QWKFunctions.tcl Scripts/TopWindow.tcl \
            Scripts/SpoolFunction.tcl Scripts/GroupFunctions.tcl \
            Scripts/ArticleFunctions.tcl Scripts/snitbuttonbox.tcl \
            Scripts/snitdialog.tcl Scripts/CommonFunctions.tcl \
            Scripts/snitrotext.tcl Scripts/AddressBook.tcl \
            Scripts/snitHTMLHelp.tcl Scripts/HTMLArticle.tcl

#                Scripts/BWHelp.tcl Scripts/labelselectcolor.tcl \
#		Scripts/panedw.tcl Scripts/fileentry.tcl \
#		Scripts/labelspinbox.tcl Scripts/splash.tcl \
#		Scripts/labelcombobox.tcl Scripts/mainwindow.tcl \
#                Scripts/BWStdMenuBar.tcl Scripts/CommonFunctions.tcl \
#		Scripts/SpoolFunction.tcl Scripts/GroupFunctions.tcl \
#                Scripts/ArticleFunctions.tcl 
#		Scripts/AddressBook.tcl 
		
LibraryImages = Scripts/unknown.xpm Scripts/DeepwoodsBanner.png

#                Scripts/close.gif Scripts/new.gif Scripts/open.gif \
#		Scripts/print.gif Scripts/save.gif Scripts/DeepwoodsBanner.gif \
#		Scripts/TkNewsIIIicon.gif
LibraryXBMS =  Scripts/TkNewsIIIicon.xbm  Scripts/TkNewsIIIicon_mask.xbm \
                Scripts/questhead.xbm Scripts/info.xbm Scripts/gray50.xbm
TkNewsIIIDATA = $(LibraryScripts) $(LibraryImages) $(LibraryXBMS)
Split_flatmessagefileDATA =  Scripts/CommonFunctions.tcl

EXTRA_DIST = Rules.make  BUILDSYMBOLS.tcl.in bootstrap
CLEANFILES = TkNewsIII Split_flatmessagefile
TkNewsIII$(EXEEXT): Scripts/TkNewsIII.src $(TkNewsIIIDATA) \
			$(LibraryGIFS) $(LibraryXBMS) \
			html/index.html
	-rm -f  TkNewsIII.kit
	-rm -f  TkNewsIII$(EXEEXT)
	-rm -rf TkNewsIII.vfs
	$(TCLKIT) $(SDX) qwrap $(srcdir)/Scripts/TkNewsIII.src
	$(TCLKIT) $(SDX) unwrap TkNewsIII.kit
	-rm -f  TkNewsIII.kit
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsIII \
		lib $(SNITLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsIII \
		lib $(URILIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsIII \
		lib $(NCGILIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsIII \
		lib $(FILEUTILLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsIII \
		lib $(CMDLINELIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsIII \
		lib $(IMAP4LIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsIII \
		lib $(MIMELIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsIII \
		lib $(VIRTCHBASELIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsIII \
		lib $(VIRTCHCORELIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsIII \
		lib $(VIRTCHTRANSLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsIII \
		lib $(SASLLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsIII \
		lib $(BASE64LIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsIII \
		lib $(MD5LIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsIII \
		lib $(OTPLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit TkNewsIII \
		lib $(TLSLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) TkNewsIII \
		lib/Common $(TkNewsIIIDATA)
	$(TCLKIT) $(top_srcdir)/BuildScripts/MakePkgIndex.kit TkNewsIII \
		Common
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit TkNewsIII \
		HTML html/*.html html/*.css html/*.png
	$(TCLKIT) $(SDX) wrap TkNewsIII$(EXEEXT) -runtime $(TCLKITRUN)
	-rm -rf  TkNewsIII.vfs

#	tar xjf $(top_srcdir)/BuildData/$(IMG_TARBZ) -C TkNewsIII.vfs/lib
#	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit TkNewsIII \
#	        lib/GpgME GpgME/.libs/gpgme.so GpgME/pkgIndex.tcl

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

tls1.6.7/tls.tcl tls1.6.7/libtls1.6.7.so tls1.6.7/pkgIndex.tcl: FORCE
	$(MAKE) -C tls1.6.7

html/index.html : FORCE
	$(MAKE) -C Docs ../html/index.html

latex/refman.tex : FORCE
	$(MAKE) -C Docs ../latex/refman.tex

refman.pdf : latex/refman.tex
	$(MAKE) -C latex refman.pdf
	-cp latex/refman.pdf ./

FORCE:
