case $CONFIG in
'')
	if test -f config.sh; then TOP=.;
	elif test -f ../config.sh; then TOP=..;
	elif test -f ../../config.sh; then TOP=../..;
	elif test -f ../../../config.sh; then TOP=../../..;
	elif test -f ../../../../config.sh; then TOP=../../../..;
	else
		echo "Can't find config.sh."; exit 1
	fi
	. $TOP/config.sh
	;;
esac
: This forces SH files to create target in same directory as SH file.
: This is so that make depend always knows where to find SH derivatives.
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
echo "Extracting flatten.sed (with variable substitutions)"
: This section of the file will have variable substitutions done on it.
: Move anything that needs config subs from !NO!SUBS! section to !GROK!THIS!.
: Protect any dollar signs and backticks that you do not want interpreted
: by putting a backslash in front.  You may delete these comments.
$spitshell >flatten.sed <<!GROK!THIS!
s!\$(privlib)!$privlib!
!GROK!THIS!

: In the following dollars and backticks do not need the extra backslash.
$spitshell >>flatten.sed <<'!NO!SUBS!'
/^.so *example.h$/{
r example.h
d
}

/^.so *example.inc$/{
r example.inc
d
}

/^.so *ctype_ex.h$/{
r ctype_ex.h
d
}

/^.so *ctype_ex.inc$/{
r ctype_ex.inc
d
}
!NO!SUBS!
chmod 755 flatten.sed
$eunicefix flatten.sed
