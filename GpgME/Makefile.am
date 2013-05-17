pkglibdir=$(libdir)/$(PACKAGE)-$(VERSION)/execbin


pkglib_LTLIBRARIES = gpgme.la
INCLUDES = -I$(top_builddir)  -I. -I$(TCL_INCLUDES)
nodist_gpgme_la_SOURCES = gpgme_wrap.c
gpgme_la_LDFLAGS = -g -module -avoid-version 
gpgme_la_LIBADD = $(TCL_STUB_LIB_SPEC) $(GPGME_LIBS)
gpgme_la_CFLAGS = -DUSE_TCL_STUBS $(INCLUDES) $(GPGME_CFLAGS)
EXTRA_DIST = gpgme.i
CLEANFILES = gpgme_wrap.c pkgIndex.tcl
SWIG_FLAGS =  -tcl8 $(INCLUDES)

BUILT_SOURCES = gpgme_wrap.c

gpgme_wrap.c : gpgme.i
	$(SWIG) $(SWIG_FLAGS) -I/usr/include $(INCLUDES) -o gpgme_wrap.c $(srcdir)/gpgme.i
    
pkgIndex.tcl: gpgme.la
	echo 'package ifneeded Gpgme 0.0 [list load [file join $$dir gpgme[info sharedlibextension]] Gpgme]' > pkgIndex.tcl
    

