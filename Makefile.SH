case $CONFIG in
'')
	if test ! -f config.sh; then
		ln ../config.sh . || \
		ln ../../config.sh . || \
		ln ../../../config.sh . || \
		(echo "Can't find config.sh."; exit 1)
	fi 2>/dev/null
	. ./config.sh
	;;
esac
: This forces SH files to create target in same directory as SH file.
: This is so that make depend always knows where to find SH derivatives.
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
echo "Extracting Makefile (with variable substitutions)"
: This section of the file will have variable substitutions done on it.
: Move anything that needs config subs from !NO!SUBS! section to !GROK!THIS!.
: Protect any dollar signs and backticks that you do not want interpreted
: by putting a backslash in front.  You may delete these comments.
$spitshell >Makefile <<!GROK!THIS!
# $Id: Makefile.SH,v 1.1 2004-05-03 05:17:48 behdad Exp $
#
# UNIX makefile for manual page generator
# Note: any changes made here will be lost next time Configure is run!.

CC=$cc $optimize
YACC=$yacc $yaccflags
LEX=$lex $lexflags
SED=$sed
CAT=$cat
RM=$rm
MV=$mv
CP=$cp
ECHO=$echo
MKDEP=$mkdep

# where we get installed
bin=$binexp
privlib=$installprivlib

mansrc=$mansrc
manext=$manext
CFLAGS=$ccflags
WARNFLAGS=$warnflags
LDFLAGS=$ldflags
LIBS=$libs $liblex $libyacc
!GROK!THIS!

: In the following dollars and backticks do not need the extra backslash.
$spitshell >>Makefile <<'!NO!SUBS!'

# As Larry said, "Grrrr"
SHELL=/bin/sh

OSOURCES =	config.h c2man.h semantic.h symbol.h strconcat.h \
		strappend.h manpage.h enum.h output.h lex.l grammar.y
DCSOURCES =	c2man.c semantic.c string.c symbol.c strconcat.c \
		strappend.c manpage.c enum.c nroff.c texinfo.c latex.c html.c \
		autodoc.c
SOURCES =	$(OSOURCES) $(DCSOURCES)
CSOURCES =	$(DCSOURCES) y.tab.c
OBJECTS =	c2man.o semantic.o string.o symbol.o y.tab.o strconcat.o \
		strappend.o manpage.o enum.o nroff.o texinfo.o latex.o html.o \
		autodoc.o
GENERATED =	c2man example.inc ctype_ex.inc y.tab.c lex.yy.c y.output \
		fixexamp.sed flatten.sed


all: c2man c2man.1

install: all
	$(CP) c2man $(bin)
	$(CP) c2man.1 $(mansrc)/c2man.$(manext)
	-mkdir $(privlib)
	chmod 755 $(privlib)
	-mkdir $(privlib)/eg
	chmod 755 $(privlib)/eg
	$(CP) eg/*.[chly] $(privlib)/eg
	chmod 755 $(privlib)/eg/*

uninstall:
	$(RM) -f $(bin)/c2man $(mansrc)/c2man.$(manext)
	$(RM) -f $(privlib)/eg/*
	rmdir $(privlib)/eg
	rmdir $(privlib)

c2man: $(OBJECTS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJECTS) $(LIBS)

c2man.1: c2man.man c2man example.inc ctype_ex.inc flatten.sed
	$(SED) -f flatten.sed < c2man.man > c2man.1

.c.o:
	$(CC) $(CFLAGS) $(WARNFLAGS) -c $<

y.tab.c: grammar.y
	@$(ECHO) Expect 61 shift/reduce conflicts.
	$(YACC) grammar.y

# don't compile y.tab.c with all warnings; yacc/bison are not up to it.
y.tab.o: y.tab.c lex.yy.c
	$(CC) $(CFLAGS) -c y.tab.c

lex.yy.c: lex.l
	$(LEX) -n lex.l

example.inc: c2man example.h fixexamp.sed
	./c2man -o- example.h | $(SED) -f fixexamp.sed >example.inc

ctype_ex.inc: c2man ctype_ex.h fixexamp.sed
	./c2man -o- -g ctype_ex.h | $(SED) -f fixexamp.sed >ctype_ex.inc

fixexamp.sed: fixexamp.in
	$(SED) -e '/^#/d' fixexamp.in > fixexamp.sed

flatten.sed: flatten.SH config.sh
	sh flatten.SH

Makefile: Makefile.SH config.sh
	sh Makefile.SH

config.h: config_h.SH config.sh
	sh config_h.SH

TAGS: $(SOURCES)
	etags -t $(SOURCES)

clean:
	$(RM) -f *.o *.s *.bak *~ *.log $(GENERATED) core

distclean realclean: clean
	$(RM) -f Makefile config.sh mkdep c2man.kit?

lint:
	lint -b $(CFLAGS) $(CSOURCES)

print:
	cpr $(SOURCES) | lpr -J'c2man'

test: c2man
	@echo "Running c2man over the examples..." 1>&2
	@for file in eg/*.[chly]; do ./c2man -v -o- $$file; done
	@echo "Running c2man over its own source code..." 1>&2
	@for file in $(DCSOURCES); do ./c2man -v -o- $$file; done
	@echo "Hmmm, test seemed to go OK." 1>&2

depend:
	$(SED) -e '1,/^# DO NOT/!d' < Makefile > Makefile.new
	$(MKDEP) $(DCSOURCES) >> Makefile.new
	- test ! -f y.tab.c -o ! -f lex.yy.c || $(MKDEP) y.tab.c >> Makefile.new
	$(MV) -f Makefile.new Makefile

# y.tab.c dependancies updated manually since it won't exist yet when make
# depend is first run.
y.tab.o: c2man.h
y.tab.o: config.h
y.tab.o: confmagic.h
y.tab.o: enum.h
y.tab.o: manpage.h
y.tab.o: semantic.h
y.tab.o: strappend.h
y.tab.o: strconcat.h
y.tab.o: symbol.h

# DO NOT DELETE THIS LINE! make depend DEPENDS ON IT!
c2man.o:
	@echo "You must run a make depend first."; exit 1
!NO!SUBS!
chmod 755 Makefile
$eunicefix Makefile
