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
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
echo "Extracting config.h (with variable substitutions)"
sed <<!GROK!THIS! >config.h -e 's!^#undef\(.*/\)\*!/\*#define\1 \*!' -e 's!^#un-def!#undef!'
/*
 * This file was produced by running the config_h.SH script, which
 * gets its values from config.sh, which is generally produced by
 * running Configure.
 *
 * Feel free to modify any of this as the need arises.  Note, however,
 * that running config_h.SH again will wipe out any changes you've made.
 * For a more permanent change edit config.sh and rerun config_h.SH.
 *
 * \$Id: config_h.SH,v 1.1 2004-05-03 05:17:48 behdad Exp $
 */

/*
 * Package name      : $package
 * Source directory  : $src
 * Configuration time: $cf_time
 * Configured by     : $cf_by
 * Target system     : $myuname
 */

#ifndef _config_h_
#define _config_h_

/* VMS:
 *	This symbol, if defined, indicates that the program is running under
 *	VMS.  It is currently only set in conjunction with the EUNICE symbol.
 */
/* BSD:
 *	This symbol, if defined, indicates that the program is running under
 *	a BSD system.
 */
#$d_eunice VMS		/**/
#$d_bsd BSD		/**/

/* CPP_FILE_COM:
 *	This symbol contains the first part of the string which will invoke
 *	the C preprocessor a file and produce to standard output, preserving
 *	comments. Typical value of "cc -E -C" or "/lib/cpp -C".
 */
/* CPP_STDIN_FLAGS:
 *	This variable contains any flags necessary to get CPP_FILE_COM to
 *	read from the standard input.
 */
/* CPP_IGN_HDRS:
 *	This symbol is defined if CPP_FILE_COM ignores *.h files.
 */
/* CPP_CAN_STDIN:
 *	This symbol is defined if CPP_FILE_COM can read standard input
 *	directly.
 */
#define CPP_FILE_COM "$cppfilecom"
#define CPP_STDIN_FLAGS "$cppstdinflags"
#$d_cppignhdrs CPP_IGN_HDRS		/* does CPP ignore .h files? */
#$d_cppcanstdin CPP_CAN_STDIN 	/* can CPP read stdin directly? */

/* HAS_ACCESS:
 *	This manifest constant lets the C program know that the access()
 *	system call is available to check for accessibility using real UID/GID.
 *	(always present on UNIX.)
 */
#$d_access HAS_ACCESS		/**/

/* HASATTRIBUTE:
 *	This symbol indicates the C compiler can check for function attributes,
 *	such as printf formats. This is normally only supported by GNU cc.
 */
#$d_attribut HASATTRIBUTE 	/**/
#ifndef HASATTRIBUTE
#define __attribute__(_arg_)
#endif

/* HASCONST:
 *	This symbol, if defined, indicates that this C compiler knows about
 *	the const type. There is no need to actually test for that symbol
 *	within your programs. The mere use of the "const" keyword will
 *	trigger the necessary tests.
 */
#$d_const HASCONST	/**/
#ifndef HASCONST
#define const
#endif

/* FLEXFILENAMES:
 *	This symbol, if defined, indicates that the system supports filenames
 *	longer than 14 characters.
 */
#$d_flexfnam	FLEXFILENAMES		/**/

/* HAS_LINK:
 *	This symbol, if defined, indicates that the link routine is
 *	available to create hard links.
 */
#$d_link HAS_LINK	/**/

/* HAS_OPEN3:
 *	This manifest constant lets the C program know that the three
 *	argument form of open(2) is available.
 */
#$d_open3 HAS_OPEN3		/**/

/* HAS_STRCHR:
 *	This symbol is defined to indicate that the strchr()/strrchr()
 *	functions are available for string searching. If not, try the
 *	index()/rindex() pair.
 */
/* HAS_INDEX:
 *	This symbol is defined to indicate that the index()/rindex()
 *	functions are available for string searching.
 */
#$d_strchr HAS_STRCHR	/**/
#$d_index HAS_INDEX	/**/

/* HAS_STRFTIME:
 *	This symbol, if defined, indicates that the strftime routine is
 *	available to format locale-specific times.
 */
#$d_strftime HAS_STRFTIME	/**/

/* HAS_STRSTR:
 *	This symbol, if defined, indicates that the strstr routine is
 *	available to find substrings.
 */
#$d_strstr HAS_STRSTR	/**/

/* HAS_SYMLINK:
 *	This symbol, if defined, indicates that the symlink routine is available
 *	to create symbolic links.
 */
#$d_symlink HAS_SYMLINK	/**/

/* Time_t:
 *	This symbol holds the type returned by time(). It can be long,
 *	or time_t on BSD sites (in which case <sys/types.h> should be
 *	included).
 */
#define Time_t $timetype		/* Time type */

/* Signal_t:
 *	This symbol's value is either "void" or "int", corresponding to the
 *	appropriate return type of a signal handler.  Thus, you can declare
 *	a signal handler using "Signal_t (*handler)()", and define the
 *	handler using "Signal_t handler(sig)".
 */
#define Signal_t $signal_t	/* Signal handler's return type */

/* HASVOLATILE:
 *	This symbol, if defined, indicates that this C compiler knows about
 *	the volatile declaration.
 */
#$d_volatile	HASVOLATILE	/**/
#ifndef HASVOLATILE
#define volatile
#endif

/* I_FCNTL:
 *	This manifest constant tells the C program to include <fcntl.h>.
 */
#$i_fcntl I_FCNTL	/**/

/* I_STDDEF:
 *	This symbol, if defined, indicates that <stddef.h> exists and should
 *	be included.
 */
#$i_stddef I_STDDEF	/**/

/* I_STDLIB:
 *	This symbol, if defined, indicates that <stdlib.h> exists and should
 *	be included.
 */
#$i_stdlib I_STDLIB		/**/

/* I_STRING:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <string.h> (USG systems) instead of <strings.h> (BSD systems).
 */
#$i_string I_STRING		/**/

/* I_SYS_FILE:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/file.h> to get definition of R_OK and friends.
 */
#$i_sysfile I_SYS_FILE		/**/

/* I_SYS_TYPES:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/types.h>.
 */
#$i_systypes	I_SYS_TYPES		/**/

/* I_TIME:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <time.h>.
 */
/* I_SYS_TIME:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <sys/time.h>.
 */
#$i_time I_TIME		/**/
#$i_systime I_SYS_TIME		/**/

/* I_UNISTD:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <unistd.h>.
 */
#$i_unistd I_UNISTD		/**/

/* I_STDARG:
 *	This symbol, if defined, indicates that <stdarg.h> exists and should
 *	be included.
 */
/* I_VARARGS:
 *	This symbol, if defined, indicates to the C program that it should
 *	include <varargs.h>.
 */
#$i_stdarg I_STDARG		/**/
#$i_varargs I_VARARGS	/**/

/* CAN_PROTOTYPE:
 *	If defined, this macro indicates that the C compiler can handle
 *	function prototypes.
 */
/* DOTS:
 *	This macro is used to specify the ... in function prototypes which
 *	have arbitrary additional arguments.
 */
/* NXT_ARG:
 *	This macro is used to separate arguments in the declared argument list.
 */
/* P_FUNC:
 *	This macro is used to declare "private" (static) functions.
 *	It takes three arguments: the function type and name, a parenthesized
 *	traditional (comma separated) argument list, and the declared argument
 *	list (in which arguments are separated with NXT_ARG, and additional
 *	arbitrary arguments are specified with DOTS).  For example:
 *
 *		P_FUNC(int foo, (bar, baz), int bar NXT_ARG char *baz[])
 */
/* P_FUNC_VOID:
 *	This macro is used to declare "private" (static) functions that have
 *	no arguments.  The macro takes one argument: the function type and name.
 *	For example:
 *
 *		P_FUNC_VOID(int subr)
 */
/* V_FUNC:
 *	This macro is used to declare "public" (non-static) functions.
 *	It takes three arguments: the function type and name, a parenthesized
 *	traditional (comma separated) argument list, and the declared argument
 *	list (in which arguments are separated with NXT_ARG, and additional
 *	arbitrary arguments are specified with DOTS).  For example:
 *
 *		V_FUNC(int main, (argc, argv), int argc NXT_ARG char *argv[])
 */
/* V_FUNC_VOID:
 *	This macro is used to declare "public" (non-static) functions that have
 *	no arguments.  The macro takes one argument: the function type and name.
 *	For example:
 *
 *		V_FUNC_VOID(int fork)
 */
/* _:
 *	This macro is used to declare function parameters for folks who want
 *	to make declarations with prototypes using a different style than
 *	the above macros.  Use double parentheses.  For example:
 *
 *		int main _((int argc, char *argv[]));
 */
#$prototype	CAN_PROTOTYPE	/**/
#ifdef CAN_PROTOTYPE
#define	NXT_ARG ,
#define	DOTS , ...
#define	V_FUNC(name, arglist, args)name(args)
#define	P_FUNC(name, arglist, args)static name(args)
#define	V_FUNC_VOID(name)name(void)
#define	P_FUNC_VOID(name)static name(void)
#define	_(args) args
#else
#define	NXT_ARG ;
#define	DOTS
#define	V_FUNC(name, arglist, args)name arglist args;
#define	P_FUNC(name, arglist, args)static name arglist args;
#define	V_FUNC_VOID(name)name()
#define	P_FUNC_VOID(name)static name()
#define	_(args) ()
#endif

/* CAN_VAPROTO:
 *	This variable is defined on systems supporting prototype declaration
 *	of functions with a variable number of arguments.
 */
/* _V:
 *	This macro is used to declare function parameters in prototypes for
 *	functions with a variable number of parameters. Use double parentheses.
 *	For example:
 *
 *		int printf _V((char *fmt, ...));
 *
 *	Remember to use the plain simple _() macro when declaring a function
 *	with no variable number of arguments, since it might be possible to
 *	have a non-effect _V() macro and still get prototypes via _().
 */
#$vaproto CAN_VAPROTO	/**/
#ifdef CAN_VAPROTO
#define	_V(args) args
#else
#define	_V(args) ()
#endif

/* VOIDFLAGS:
 *	This symbol indicates how much support of the void type is given by this
 *	compiler.  What various bits mean:
 *
 *	    1 = supports declaration of void
 *	    2 = supports arrays of pointers to functions returning void
 *	    4 = supports comparisons between pointers to void functions and
 *		    addresses of void functions
 *	    8 = suports declaration of generic void pointers
 *
 *	The package designer should define VOIDUSED to indicate the requirements
 *	of the package.  This can be done either by #defining VOIDUSED before
 *	including config.h, or by defining defvoidused in Myinit.U.  If the
 *	latter approach is taken, only those flags will be tested.  If the
 *	level of void support necessary is not present, defines void to int.
 */
#ifndef VOIDUSED
#define VOIDUSED $defvoidused
#endif
#define VOIDFLAGS $voidflags
#if (VOIDFLAGS & VOIDUSED) != VOIDUSED
#define void int		/* is void to be avoided? */
#define M_VOID			/* Xenix strikes again */
#endif

#endif
!GROK!THIS!
