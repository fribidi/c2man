
				c2man, Version 2
				by Graham Stoney

			    Copyright (c) 1992-1996
		 Canon Information Systems Research Australia
			      All rights reserved.

C2man is an automatic documentation tool that extracts comments from C source
code to generate functional interface documentation in the same format as
sections 2 & 3 of the Unix Programmer's Manual. It requires minimal effort from
the programmer by looking for comments in the usual places near the objects
they document, rather than imposing a rigid function-comment syntax or
requiring that the programmer learn and use a typesetting language.  Acceptable
documentation can often be generated from existing code with no modifications.

The program can generate nroff/troff -man, TeXinfo, LaTeX or HTML output
directly, and should run on virtually any Unix-like system, OS/2, VMS, MSDOS or
Amiga systems.

You will need lex or flex, plus yacc or bison, and a C compiler (traditional
K&R 1 or ISO/ANSI will do) to build the program. You'll also need a text
formatter to format its output.

This version of c2man is copyright, but may be freely redistributed and modified
so long as:

1. The names of all contributing authors remain on the documentation,
2. All derivative works are clearly documented as such,
3. All derivative works remain freely redistributable under the same conditions.

As such, there is no warranty.

The manual page includes some automatically generated examples, which will be
missing if you try to read it before doing a make.  Running make will generate
the complete manual page, which you can then copy around freely.

c2man does not currently support C++, but if you think this would be worth
while, look in the file "C++autodoc" for information on how I envisage C++
support could be added, and get ready to volunteer.  Note that this isn't
related to the Commodore Amiga AutoDoc backend; the name's just a coincidence.

The file "FAQ" in the c2man distribution contains answers to a number of
Frequently Asked Questions about c2man.

By popular demand, there are a few trivial examples of different comment
styles in the "eg" directory.  I'm open to submissions from users too.


There is a mailing list for c2man users; it is very low volume and has a very
low noise content.  This is the preferred place to ask questions about the
program and discuss modifications and additions with the author and other
users, but please check in the file "FAQ" first before asking questions on the
list, in case I've already answered it.  You are encouraged to join by sending
mail with no Subject: line to <listserv@research.canon.com.au> containing:

	SUBSCRIBE c2man Your name

Where `Your name' should be replaced with your real name.
Messages for distribution to everyone on the list should be sent to:
<c2man@research.canon.com.au>.


The time I have available for c2man support is rather limited, but if it lacks
any features you require, feel free to Email me (preferably to the mailing list
address above) asking about it.  Unless you request otherwise, I will probably
cc: to the list replies to any questions that I get mailed, to save me
answering them again for other people.  I encourage you to go ahead and make
any changes you like and send me the diffs for inclusion in the next patch, but
it's a good idea to ask first in case someone already has the feature you want
in the works.  In order for me to integrate your changes, they need to be
reasonably "clean", and you'll need to update manual page as appropriate.

Please try to remember to include the c2man version number in any bug reports.
You can find it by running: c2man -V /dev/null

If you'd like to be notified automatically about new releases and patches,
answer yes to the Configure question about sending mail to the author.


Special thanks for their direct and indirect contributions to c2man go to:
    Larry Wall, Raphael Manfredi, Harlan Stenn and the "dist" team, for writing
    various bits of metaconfig, which generated the Configure script.

    Darrel Hankerson for the OS/2 and MSDOS ports.
    Rick Flower for the VMS port.
    Stefan Ruppert for the Amiga port, and AutoDoc backend.

    Richard Kooijman for the LaTeX backend, and for fixing the TeXinfo backend.
    Diab Jerius too, for more work on the TeXinfo backend.
    Frank P.J. Ooms for the HTML backend.

    Vern Paxson for his suggestions on how to handle comment lexing better.

Thanks to the following people for suggestions & bug fixes is long overdue:
    Peter (P.) Barszczewski, Carlo Tarantola, Dennis Allison,
    Philip Yzarn de Louraille, Jerry Lieberthal, Mats Ohrman, Stefan Zimmermann,
    Dolf Grunbauer, Lele Gaifax, Carl R. Crawford, Jhon Honce, Chris Borchert,
    Jerry E. Dunmire, Marty Leisner, Dan Forrest, Ken Weinert, Ken Poppleton,
    Michael Hamilton, Thomas E. Dickey, Marco Nijdam.

Finally, c2man owes a huge debt to the public domain program cproto, by
Chin Huang, from which the original code was derived.

(Hmmm.  This is beginning to sound like an Academy Awards night...)


See the file "INSTALL" for Unix installation instructions.


Graham Stoney					  greyham@research.canon.com.au
Mailing List for general c2man Questions & Answers  c2man@research.canon.com.au
