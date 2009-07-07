# Makefile to build linux D runtime library libphobos2.a and its unit test
# Targets:
#	<default> | release
#		-release -O
# The release build also puts a link to libphobos2.a in the current directory.
#	unittest/release
#		-unittest -release -O
#	debug
#		-g
#	unittest/debug
#		-unittest -g
#	clean
#		Delete all files created by build process

CFLAGS=-m32
DFLAGS=

ifeq (,$(MAKECMDGOALS))
    MAKECMDGOALS := release
endif
ifeq (unittest/release,$(MAKECMDGOALS))
    CFLAGS:=$(CFLAGS) -O
    DFLAGS:=$(DFLAGS) -release -unittest
    OBJDIR=obj/unittest/release
endif
ifeq (unittest/debug,$(MAKECMDGOALS))
    CFLAGS:=$(CFLAGS) -g
    DFLAGS:=$(DFLAGS) -g -unittest -debug
    OBJDIR=obj/unittest/debug
endif
ifeq (debug,$(MAKECMDGOALS))
    CFLAGS:=$(CFLAGS) -g
    DFLAGS:=$(DFLAGS) -g -debug
    OBJDIR=obj/debug
endif
ifeq (release,$(MAKECMDGOALS))
    CFLAGS:=$(CFLAGS) -O
    DFLAGS:=$(DFLAGS) -O -release
    OBJDIR=obj/release
endif
ifeq (clean,$(MAKECMDGOALS))
    OBJDIR=none
endif
ifeq (html,$(MAKECMDGOALS))
    OBJDIR=none
endif

ifndef OBJDIR
    $(error Cannot make $(MAKECMDGOALS). Please make either \
debug, release, unittest/debug, unittest/release, clear, or html)
endif

ifneq (none,$(OBJDIR))
  DUMMY := $(shell mkdir --parents $(OBJDIR))
  DUMMY += $(shell mkdir --parents $(OBJDIR)/etc/c/zlib)
endif

LIB=$(OBJDIR)/libphobos2.a
DOC_OUTPUT_DIR=web/phobos
CC=gcc
#DMD=/dmd/bin/dmd
DMD=dmd

.SUFFIXES: .d
$(OBJDIR)/%.o : %.c
	$(CC) -c $(CFLAGS) -o $@ $<

$(OBJDIR)/%.o : %.cpp
	g++ -c $(CFLAGS) -o $@ $<

$(OBJDIR)/%.o : %.d
	$(DMD) -I$(dir $<) -c $(DFLAGS) -of$@ $<

$(OBJDIR)/%.o : %.asm
	$(CC) -c -o $@ $<

debug release unittest/debug unittest/release : $(OBJDIR)/unittest

$(OBJDIR)/unittest : $(OBJDIR)/unittest.o \
                   $(OBJDIR)/all_std_modules_generated.o $(LIB)
	$(CC) -o $@ $^ -lpthread -lm -g -ldl
ifeq (release,$(MAKECMDGOALS))
	ln -sf $(OBJDIR)/libphobos2.a .
endif

$(OBJDIR)/unittest.o : unittest.d all_std_modules_generated.d

all_std_modules_generated.d : $(MAKEFILE_LIST)
	for m in $(STD_MODULES); do echo public import std.$$m\;; done > $@

INTERNAL_MODULES = aApply aApplyR aaA adi alloca arraycast arraycat cast cmath2 \
	deh2 dmain2 invariant llmath memset obj object qsort switch trace \
	arrayassign
INTERNAL_CMODULES = complex critical monitor
INTERNAL_CMODULES_NOTBUILT = deh
INTERNAL_EXTRAFILES = internal/mars.h internal/minit.asm

INTERNAL_GC_MODULES = gc gcold gcx gcbits gclinux
INTERNAL_GC_EXTRAFILES = \
	internal/gc/gcstub.d \
	internal/gc/win32.d \
	internal/gc/testgc.d \
	internal/gc/win32.mak \
	internal/gc/linux.mak

STD_MODULES = algorithm array asserterror base64 bind bitarray		\
        bitmanip boxer compiler complex contracts conv cover cpuid	\
        cstream ctype date dateparse demangle encoding file format	\
        functional gc getopt hiddenfunc intrinsic iterator loader math	\
        md5 metastrings mmfile moduleinit numeric openrj outbuffer	\
        outofmemory path perf process random regexp signals socket	\
        socketstream stdint stdio stream string switcherr syserror	\
        system thread traits typecons typetuple uni uri utf variant	\
        xml zip zlib
STD_MODULES_NOTBUILT = stdarg

STD_C_MODULES = stdarg stdio
STD_C_MODULES_NOTBUILT = fenv math process stddef stdlib string time locale

STD_C_LINUX_MODULES = linux socket
STD_C_LINUX_MODULES_NOTBUILT = linuxextern pthread termios

STD_C_WINDOWS_MODULES_NOTBUILT = windows com winsock stat

STD_WINDOWS_MODULES_NOTBUILT = registry iunknown charset

ZLIB_CMODULES = adler32 compress crc32 gzio uncompr deflate \
	trees zutil inflate infback inftrees inffast

TYPEINFO_MODULES = \
	ti_wchar ti_uint \
	ti_short ti_ushort \
	ti_byte ti_ubyte \
	ti_long ti_ulong \
	ti_ptr \
	ti_float ti_double \
	ti_real ti_delegate \
	ti_creal ti_ireal \
	ti_cfloat ti_ifloat \
	ti_cdouble ti_idouble \
	ti_dchar \
	ti_Ashort \
	ti_Ag \
	ti_AC ti_C \
	ti_int ti_char \
	ti_Aint \
	ti_Along \
	ti_Afloat ti_Adouble \
	ti_Areal \
	ti_Acfloat ti_Acdouble \
	ti_Acreal \
	ti_void

ETC_MODULES_NOTBUILT = gamma

ETC_C_MODULES = zlib

SRC = errno.c object.d unittest.d crc32.d gcstats.d

SRC_ZLIB = \
	ChangeLog README adler32.c algorithm.txt compress.c crc32.c crc32.h \
	deflate.c deflate.h example.c gzio.c infback.c inffast.c inffast.h \
	inffixed.h inflate.c inflate.h inftrees.c inftrees.h linux.mak \
	minigzip.c trees.c trees.h uncompr.c win32.mak zconf.h zconf.in.h \
	zlib.3 zlib.h zutil.c zutil.h
SRC_ZLIB := $(addprefix etc/c/zlib/,$(SRC_ZLIB))

SRC_DOCUMENTABLES = \
	phobos.d \
	$(addprefix std/,$(addsuffix .d,$(STD_MODULES) $(STD_MODULES_NOTBUILT))) \
	$(addprefix std/c/,$(addsuffix .d,$(STD_C_MODULES) $(STD_C_MODULES_NOTBUILT))) \
	$(addprefix std/c/linux/,$(addsuffix .d,$(STD_C_LINUX_MODULES) $(STD_C_LINUX_MODULES_NOTBUILT)))


SRC_RELEASEZIP = \
	linux.mak win32.mak phoboslicense.txt \
	$(SRC) $(SRC_ZLIB) \
	\
	$(INTERNAL_EXTRAFILES) \
	$(INTERNAL_GC_EXTRAFILES) \
	$(addprefix internal/,$(addsuffix .c,$(INTERNAL_CMODULES_NOTBUILT))) \
	$(addprefix internal/,$(addsuffix .c,$(INTERNAL_CMODULES))) \
	$(addprefix internal/,$(addsuffix .d,$(INTERNAL_MODULES))) \
	$(addprefix internal/gc/,$(addsuffix .d,$(INTERNAL_GC_MODULES))) \
	$(addprefix std/,$(addsuffix .d,$(STD_MODULES) $(STD_MODULES_NOTBUILT))) \
	$(addprefix std/c/,$(addsuffix .d,$(STD_C_MODULES) $(STD_C_MODULES_NOTBUILT))) \
	$(addprefix std/c/linux/,$(addsuffix .d,$(STD_C_LINUX_MODULES) $(STD_C_LINUX_MODULES_NOTBUILT))) \
	$(addprefix std/c/windows/,$(addsuffix .d,$(STD_C_WINDOWS_MODULES_NOTBUILT))) \
	$(addprefix std/typeinfo/,$(addsuffix .d,$(TYPEINFO_MODULES))) \
	$(addprefix std/windows/,$(addsuffix .d,$(STD_WINDOWS_MODULES_NOTBUILT))) \
	$(addprefix etc/,$(addsuffix .d,$(ETC_MODULES_NOTBUILT))) \
	$(addprefix etc/c/,$(addsuffix .d,$(ETC_C_MODULES)))

OBJS = crc32.o errno.o gcstats.o \
	$(addprefix std/,$(addsuffix .o,$(STD_MODULES))) \
	$(addprefix std/c/,$(addsuffix .o,$(STD_C_MODULES))) \
	$(addprefix std/c/linux/,$(addsuffix .o,$(STD_C_LINUX_MODULES))) \
	$(addprefix std/typeinfo/,$(addsuffix .o,$(TYPEINFO_MODULES))) \
	$(addprefix internal/,$(addsuffix .o,$(INTERNAL_MODULES))) \
	$(addprefix internal/,$(addsuffix .o,$(INTERNAL_CMODULES))) \
	$(addprefix internal/gc/,$(addsuffix .o,$(INTERNAL_GC_MODULES))) \
	$(addprefix etc/c/,$(addsuffix .o,$(ETC_C_MODULES))) \
	$(addprefix etc/c/zlib/,$(addsuffix .o,$(ZLIB_CMODULES)))

OBJS := $(addprefix $(OBJDIR)/,$(OBJS))

$(LIB) : $(OBJS) $(MAKEFILE_LIST)
	rm -f $(LIB)
	@echo ar -r $@ "<...tonz of filez...>"
	@ar -r $@ $(OBJS) 2>/tmp/deleteme || cat /tmp/deleteme >&2
	@rm /tmp/deleteme

###########################################################
# Dox

STDDOC = docsrc/std.ddoc
DOCDOC = docsrc/doc.ddoc

$(DOC_OUTPUT_DIR)/%.html : %.d $(STDDOC)
	$(DMD) -c -o- $(DFLAGS) -Df$@ $(STDDOC) $<

$(DOC_OUTPUT_DIR)/std_%.html : std/%.d $(STDDOC)
	$(DMD) -c -o- $(DFLAGS) -Df$@ $(STDDOC) $<

$(DOC_OUTPUT_DIR)/std_c_%.html : std/c/%.d $(STDDOC)
	$(DMD) -c -o- $(DFLAGS) -Df$@ $(STDDOC) $<

$(DOC_OUTPUT_DIR)/std_c_linux_%.html : std/c/linux/%.d $(STDDOC)
	$(DMD) -c -o- $(DFLAGS) -Df$@ $(STDDOC) $<

$(DOC_OUTPUT_DIR)/../web/glossary.html : docsrc/glossary.d $(DOCDOC)
	$(DMD) -c -o- $(DFLAGS) -Df$@ $(DOCDOC) $<

html : $(addprefix $(DOC_OUTPUT_DIR)/,$(subst /,_,$(subst .d,.html,$(SRC_DOCUMENTABLES)))) $(DOC_OUTPUT_DIR)/../web/glossary.html

##########################################################

zip : $(SRC_RELEASEZIP)
	$(RM) phobos.zip
	zip phobos $(SRC_RELEASEZIP)

clean:
	$(RM) libphobos2.a all_std_modules_generated.d
	$(RM) -r $(DOC_OUTPUT_DIR) obj

