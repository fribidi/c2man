%{
/* $Id: lex.l,v 1.1 2004-05-03 05:17:48 behdad Exp $
 *
 * C manual page generator
 * Lexical analyzer specification
 */

#include <ctype.h>

extern boolean inbasefile;  /* Steven Haehn  Mar 19, 1996 */

static char *cur_file;			/* current file name (malloced) */
int line_num = 1;		/* current line number in file */
static int curly = 0;		/* number of curly brace nesting levels */
static int square = 0;		/* number of square bracket nesting levels */
static int ly_count = 0;	/* number of occurrences of %% */
static int embedded = 0;	/* flag for embedded compiler directives */

/* temporary string buffer */
static char buf[MAX_TEXT_LENGTH];

#define DYNBUF_ALLOC	240	/* size of increment of dynamic buf */
static char *dynbuf;		/* start of dynamic buf */
static int dynbuf_size;		/* number of bytes allocated */
static int dynbuf_current;	/* current end of buffer */

static boolean comment_ateol;	/* does comment start & end at end of a line? */
static boolean comment_remember;/* remember contents of current comment? */
static boolean comment_caller;	/* state we were in before */
static boolean body_start = FALSE; /* At the start of a function body */ 

typedef struct {
#ifdef FLEX_SCANNER
    YY_BUFFER_STATE buffer;
#else
    FILE *fp;
#endif
    char *file;
    int line_num;
} IncludeStack;

static int inc_depth = 0;			/* include nesting level */
static IncludeStack inc_stack[MAX_INC_DEPTH];	/* stack of included files */

static void update_line_num _((void));
static void do_include _((char *filename, int sysinc));
static void new_dynbuf();
static void add_dynbuf _((int c));
static char *return_dynbuf();
static void get_cpp_directive();
static boolean process_line_directive _((const char *new_file));

/*
 * The initial comment processing is done primarily by the rather complex lex
 * rules in the various comment start states, the main functions being removal
 * of leading *'s, /'s and whitespace on a line, the removal of trailing
 * whitespace on a line, and the coalescing of separate comments on adjacent
 * lines.  The remaining bits of textual content are collected by the following
 * functions, which simply strip leading and trailing blank lines.
 */
void start_comment _((boolean ateol));
int end_comment _((boolean ateol));
void add_comment _((const char *s));
void newline_comment _((void));

static int comment_newlines;	/* number of newlines hit in comment */
static boolean comment_started;	/* have preceding empty lines been skipped */

#ifdef FLEX_SCANNER	/* flex uses YY_START instead of YYSTATE */
#define YYSTATE	YY_START
#ifndef YY_START	/* flex 2.3.8 & before didn't support it at all */
#define YY_START ((yy_start - 1) / 2)
#endif
#endif

#undef yywrap	/* for flex */

/* SKIP		skipping value assignment in an enum */
%}

WS		[ \t]
WLF		[ \t\n\f]*
LETTER		[A-Za-z_]
DIGIT		[0-9]
ID		{LETTER}({LETTER}|{DIGIT})*
STRING		\"(\\.|\\\n|[^"\\])*\"
QUOTED		({STRING}|\'(\\\'|[^'\n])*\'|\\.)

%p 5000
%e 2000
%s CPP1 INIT1 INIT2 CURLY SQUARE LEXYACC SKIP COMMENT COMMLINE CPPCOMMENT EMBEDDED
%%


<LEXYACC>^"%%"		{
			    if (++ly_count >= 2)
				BEGIN INITIAL;
			}
<LEXYACC>^"%{"		BEGIN INITIAL;
<LEXYACC>{QUOTED}	update_line_num();
<LEXYACC>.		;
<INITIAL>^"%}"		BEGIN LEXYACC;

<INITIAL>^{WS}*#{WS}*	BEGIN CPP1;

<CPP1>define{WS}+{ID}	{
			    sscanf(yytext, "define %s", buf);
			    get_cpp_directive();
			    new_symbol(typedef_names, buf, DS_EXTERN);
			}

<CPP1>include{WS}*\"[^"]+\"     {
			    sscanf(yytext, "include \"%[^\"]\"", buf);
			    get_cpp_directive();
			    do_include(buf, FALSE);
			}
<CPP1>include{WS}*\<[^>]+\>	{
			    sscanf(yytext, "include <%[^>]>", buf);
			    get_cpp_directive();
			    do_include(buf, TRUE);
			}

<CPP1>line{WS}+[0-9]+{WS}+\".*$  {
			    sscanf(yytext, "line %d \"%[^\"]\"",
				    &line_num, buf);
			    --line_num;
			    BEGIN INITIAL;

			    if (process_line_directive(buf))
			        inbasefile = yylval.boolean;
			}
<CPP1>[0-9]+{WS}+\".*$	{
			    sscanf(yytext, "%d \"%[^\"]\"", &line_num, buf);
			    --line_num;
			    BEGIN INITIAL;

			    if (process_line_directive(buf))
			        inbasefile = yylval.boolean;
			}
<CPP1>[0-9]+.*$		{
			    sscanf(yytext, "%d ", &line_num);
			    --line_num;
			    BEGIN INITIAL;
			}

<CPP1>.			get_cpp_directive();

<INITIAL>"("		return '(';
<INITIAL>")"		return ')';
<INITIAL>"*"		return '*';
<INITIAL,SKIP>","	{
			    BEGIN INITIAL;	/* stop skipping */
			    return ',';
			}
<INITIAL>";"		return ';';
<INITIAL>"..."		return T_ELLIPSIS;
<INITIAL>{STRING}	{ update_line_num(); return T_STRING_LITERAL; }

<INITIAL>auto		return T_AUTO;
<INITIAL>extern		return T_EXTERN;
<INITIAL>register	return T_REGISTER;
<INITIAL>static		return T_STATIC;
<INITIAL>typedef	return T_TYPEDEF;
<INITIAL>char		return T_CHAR;
<INITIAL>double		return T_DOUBLE;
<INITIAL>float		return T_FLOAT;
<INITIAL>int		return T_INT;
<INITIAL>void		return T_VOID;
<INITIAL>long		return T_LONG;
<INITIAL>short		return T_SHORT;
<INITIAL>signed		return T_SIGNED;
<INITIAL>__signed__	return T_SIGNED;
<INITIAL>__signed	return T_SIGNED;
<INITIAL>unsigned	return T_UNSIGNED;
<INITIAL>enum		{ enum_state = KEYWORD; return T_ENUM; }
<INITIAL>struct		return T_STRUCT;
<INITIAL>union		return T_UNION;
<INITIAL>const		return T_CONST;
<INITIAL>__const__	return T_CONST;
<INITIAL>__const	return T_CONST;
<INITIAL>volatile	return T_VOLATILE;
<INITIAL>__volatile__	return T_VOLATILE;
<INITIAL>__volatile	return T_VOLATILE;
<INITIAL>inline		return T_INLINE;
<INITIAL>__inline__	return T_INLINE;
<INITIAL>__inline	return T_INLINE;
<INITIAL>cdecl		return T_CDECL;
<INITIAL>far		return T_FAR;
<INITIAL>huge		return T_HUGE;
<INITIAL>interrupt	return T_INTERRUPT;
<INITIAL>near		return T_NEAR;
<INITIAL>pascal		return T_PASCAL;
<INITIAL>__extension__	;

<INITIAL>__attribute__	{
			    BEGIN EMBEDDED;
			}
<EMBEDDED>"("		++embedded;
<EMBEDDED>")"		{
			    if (--embedded == 0)
				BEGIN INITIAL;
			}
<EMBEDDED>{ID}|","|{DIGIT}+|{WS} ;
<EMBEDDED>{QUOTED}	update_line_num();

<INITIAL>{ID}		{
			    if (enum_state == BRACES)	BEGIN SKIP;
			    yylval.text = strduplicate(yytext);
			    if (is_typedef_name(yytext))
				return T_TYPEDEF_NAME;
			    else
				return T_IDENTIFIER;
			}

<INITIAL>"="		BEGIN INIT1;
<INIT1>"{"		{ curly = 1; BEGIN INIT2; }
<INIT1>[,;]		{
			    unput(yytext[yyleng-1]);
			    BEGIN INITIAL;
			    return T_INITIALIZER;
			}
<INIT1>{QUOTED}		update_line_num();
<INIT1>.		;

<INIT2>"{"		++curly;
<INIT2>"}"		{
			    if (--curly == 0) {
				BEGIN INITIAL;
				return T_INITIALIZER;
			    }
			}
<INIT2>{QUOTED}		update_line_num();
<INIT2>.		;

<INITIAL,SKIP>"{"	{
			    if (enum_state == KEYWORD)
			    {
				enum_state = BRACES;
				return '{';
			    }
			    else
			    {
				curly = 1;
				BEGIN CURLY;
				body_start = TRUE; /* Look for first comment
						    * in the func body.
						    */
				safe_free(body_comment);
				body_comment = NULL;
			    }
			}
<INITIAL,SKIP>"}"	{
 			    BEGIN INITIAL;	/* stop skipping */
			    return '}';
			}

<CURLY>"{"		++curly;
<CURLY>"}"		{
			    if (--curly == 0) {
				BEGIN INITIAL;
				return T_BRACES;
			    }
			}
<CURLY,SKIP>{QUOTED}	update_line_num();
<CURLY,SKIP>.		body_start = FALSE;

<INITIAL>"["		{
			  new_dynbuf(); add_dynbuf(yytext[0]);
			  square = 1; BEGIN SQUARE;
			}
<SQUARE>"["		{ ++square; add_dynbuf(yytext[0]); }
<SQUARE>"]"		{
			    add_dynbuf(yytext[0]);
			    if (--square == 0) {
				BEGIN INITIAL;
				yylval.text = return_dynbuf();
				return T_BRACKETS;
			    }
			}
<SQUARE>{QUOTED}|.	{
			    int i;
			    for (i = 0; i < yyleng; ++i)
			    {
				if (yytext[i] == '\n') ++line_num;
				add_dynbuf(yytext[i]);
			    }
			}

<INITIAL,INIT1,INIT2,CURLY,SQUARE,LEXYACC,SKIP,EMBEDDED>^{WS}*"/*"[*=-]*{WS}+	{
				comment_caller = YYSTATE;
				start_comment(FALSE);
				BEGIN COMMENT; }
<INITIAL,INIT1,INIT2,CURLY,SQUARE,LEXYACC,SKIP,EMBEDDED>^{WS}*"/*"[*=-]*[^/]	{
				yyless(yyleng-1);
				comment_caller = YYSTATE;
				start_comment(FALSE);
				BEGIN COMMENT; }
<INITIAL,INIT1,INIT2,CURLY,SQUARE,LEXYACC,SKIP,EMBEDDED>"/*"[*=-]*{WS}+		{
				comment_caller = YYSTATE;
				start_comment(TRUE);
				BEGIN COMMENT; }
<INITIAL,INIT1,INIT2,CURLY,SQUARE,LEXYACC,SKIP,EMBEDDED>"/*"[*=-]*[^/]		{
				yyless(yyleng-1);
				comment_caller = YYSTATE;
				start_comment(TRUE);
				BEGIN COMMENT; }
<COMMLINE>^{WS}*"/"+{WS}*	|
<COMMLINE>^{WS}*"/"*"*"*{WS}+	BEGIN COMMENT;
<COMMLINE>^{WS}*"/"*"*"*[^/]	{ yyless(yyleng-1); BEGIN COMMENT; }
<COMMLINE>.			{ yyless(0); BEGIN COMMENT; }
<COMMLINE>\n			newline_comment();
<COMMENT>{WS}*"*"+"/"{WS}*\n{WS}*"/*""*"*{WS}+	newline_comment();
<COMMENT>{WS}*"*"+"/"{WS}*\n{WS}*"/*""*"*[^/]	{
				yyless(yyleng-1); newline_comment(); }
<COMMENT>{WS}*[*=-]*"*/"{WS}*$	{ int ret = end_comment(TRUE);
				  BEGIN comment_caller;
				  if (ret)	return ret; }
<COMMENT>{WS}*[*=-]*"*/"	{ int ret = end_comment(FALSE);
				  BEGIN comment_caller;
				  if (ret)	return ret; }
<COMMENT>[^*\n \t]*		|
<COMMENT>{WS}*			|
<COMMENT>"*"+[^*/\n]*		add_comment(yytext);
<COMMENT>{WS}*\n		{ newline_comment(); BEGIN COMMLINE; }

<INITIAL,INIT1,INIT2,CURLY,SQUARE,LEXYACC,SKIP,EMBEDDED>^{WS}*"//"[/*=-]*{WS}*	{
				comment_caller = YYSTATE;
				start_comment(FALSE);
				BEGIN CPPCOMMENT; }
<INITIAL,INIT1,INIT2,CURLY,SQUARE,LEXYACC,SKIP,EMBEDDED>"//"[/*=-]*{WS}*		{
				comment_caller = YYSTATE;
				start_comment(TRUE);
				BEGIN CPPCOMMENT; }
<CPPCOMMENT>.*			add_comment(yytext);
<CPPCOMMENT>\n{WS}*"//"[/*=-]*{WS}*	newline_comment();
<CPPCOMMENT>\n			{ int ret = end_comment(TRUE);
				  ++line_num;
				  BEGIN comment_caller;
				  if (ret)	return ret; }

[ \t\f]+		;
\n			++line_num;

.			{
			    output_error();
			    fprintf(stderr, "bad character '%c'\n", yytext[0]);
			}
%%

/* If the matched text contains any new line characters, then update the
 * current line number.
 */
static void
update_line_num ()
{
    const char *p = (const char *)yytext;
    while (*p != '\0') {
	if (*p++ == '\n')
	    line_num++;
    }
}

void start_comment(ateol)
boolean ateol;	/* does comment start at end of an existing line? */
{
    comment_remember =	(look_at_body_start && body_start) ||
		    ((comment_caller == INITIAL || comment_caller == SKIP) &&
			(inbasefile || enum_state == BRACES));

    if (comment_remember)
    {
	comment_ateol = ateol;
	comment_newlines = 0;
	comment_started = FALSE;
	new_dynbuf();
    }
}

int end_comment(ateol)
boolean ateol;	/* does comment end at end of line? */
{
    if (comment_remember)
    {
	if (!ateol)	comment_ateol = FALSE;
	yylval.text = return_dynbuf();
	if (yylval.text[0] == '\0' ||
	    /* ignore lint directives entirely */
	    strcmp("EMPTY",       yylval.text) == 0 ||
	    strcmp("FALLTHROUGH", yylval.text) == 0 ||
	    strcmp("FALLTHRU",    yylval.text) == 0 ||
	    strcmp("LINTED",      yylval.text) == 0 ||
	    strcmp("LINTLIBRARY", yylval.text) == 0 ||
	    strcmp("LINTSTDLIB",  yylval.text) == 0 ||
	    strcmp("NOTDEFINED",  yylval.text) == 0 ||
	    strcmp("NOTREACHED",  yylval.text) == 0 ||
	    strcmp("NOTUSED",     yylval.text) == 0 ||
	    strncmp("ARGSUSED",   yylval.text,  8) == 0 ||
	    strncmp("PRINTFLIKE", yylval.text, 10) == 0 ||
	    strncmp("SCANFLIKE",  yylval.text,  9) == 0 ||
	    strncmp("VARARGS",    yylval.text,  7) == 0)
	{
	    free(yylval.text);
	    return 0;
	}
	if (body_start) {	/* first comment at start of func body */
	  safe_free(body_comment);
	  body_comment = yylval.text;
	  body_start = FALSE;
	  return 0;
	}
#ifdef DEBUG
	fprintf(stderr,"`%s'\n", yylval.text);
#endif
	return comment_ateol ? T_EOLCOMMENT : T_COMMENT;
    }
    return 0;
}

/* add a newline to the comment, deferring to remove trailing ones */
void newline_comment()
{
    ++line_num;

    if (!comment_remember || !comment_started)	return;

    comment_newlines++;
}

/* add some true text to the comment */
void add_comment(s)
const char *s;
{
#ifdef DEBUG
    fprintf(stderr,"`%s'\n", s);
#endif
    if (!comment_remember)	return;

    comment_started = TRUE;

    while (comment_newlines)
    {
	add_dynbuf('\n');
	comment_newlines--;
    }

    while(*s)
	add_dynbuf(*s++);
}

/* Scan rest of preprocessor statement.
 */
static void
get_cpp_directive ()
{
    int c, lastc = '\0';

    while ((c = input()) > 0) {
	switch (c) {
	case '\n':
	    if (lastc != '\\') {
		unput(c);
		BEGIN INITIAL;
		return;
	    }
	    line_num++;
	    break;
	case '*':
	    if (lastc == '/')
	    {
		/* might be able to attach comments to #defines one day */
		comment_caller = YYSTATE;
		start_comment(TRUE);
		BEGIN COMMENT;
	    }
	    break;
	case '/':
	    if (lastc == '/')
	    {
		/* might be able to attach comments to #defines one day */
		comment_caller = YYSTATE;
		start_comment(TRUE);
		BEGIN CPPCOMMENT;
	    }
	    break;
	}
	lastc = c;
    }
}

/* Process include directive.
 */
static void
do_include (filename, sysinc)
char *filename;		/* file name */
int sysinc;		/* 1 = do not search current directory */
{
    char path[MAX_TEXT_LENGTH];
    int i;
    FILE *fp;
    IncludeStack *sp;

    if (inc_depth >= MAX_INC_DEPTH) {
	output_error();
	fprintf(stderr, "includes too deeply nested\n");
	return;
    }

    for (i = sysinc != 0; i < num_inc_dir; ++i) {
	 strcpy(path, inc_dir[i]);
	 strcat(path, filename);
	 if ((fp = fopen(path, "r")) != NULL) {
	     sp = inc_stack + inc_depth;
	     sp->file = cur_file;
	     sp->line_num = line_num;
#ifdef FLEX_SCANNER
	     sp->buffer = YY_CURRENT_BUFFER;
	     yy_switch_to_buffer(yy_create_buffer(fp, YY_BUF_SIZE));
#else
	     sp->fp = yyin;
	     yyin = fp;
#endif
	     ++inc_depth;
	     cur_file = strduplicate(filename);
	     line_num = 0;
	     return;
	 }
    }
}

/* returns TRUE if the basefile status has changed */
static boolean process_line_directive(new_file)
const char *new_file;
{
    boolean new_stdin;

    /* strip leading ./ that Sun acc prepends */
    if (!strncmp(new_file,"./",2))
	new_file += 2;

    new_stdin = new_file[0] == '\0' || !strcmp(new_file,"stdin");

    /* return BASEFILE token only when file changes */
    if ((cur_file == NULL && !new_stdin) ||
	(cur_file != NULL &&strcmp(cur_file, new_file)))
    {
	safe_free(cur_file);
	cur_file = new_stdin ? NULL : strduplicate(new_file);
	yylval.boolean = basefile ? !strcmp(cur_file,basefile) :
				    cur_file == basefile;
	return TRUE;
    }
    return FALSE;
}

/* When the end of the current input file is reached, pop any
 * nested includes.
 */
int
yywrap ()
{
    IncludeStack *sp;

    if (inc_depth > 0) {
	--inc_depth;
	sp = inc_stack + inc_depth;
	fclose(yyin);
#ifdef FLEX_SCANNER
	yy_delete_buffer(YY_CURRENT_BUFFER);
	yy_switch_to_buffer(sp->buffer);
#else
	yyin = sp->fp;
#endif
	safe_free(cur_file);
	cur_file = sp->file;
	line_num = sp->line_num + 1;
	return 0;
    } else {
	return 1;
    }
}


static void new_dynbuf()
{
    if ((dynbuf = malloc(dynbuf_size = DYNBUF_ALLOC)) == 0)
	outmem();
	
    dynbuf_current = 0;
}

static void add_dynbuf(c)
int c;
{
    if (dynbuf_current == dynbuf_size &&
	((dynbuf = realloc(dynbuf,dynbuf_size += DYNBUF_ALLOC)) == 0))
	    outmem();
	
    dynbuf[dynbuf_current++] = c;
}

static char *return_dynbuf()
{
    add_dynbuf('\0');

    /* chop it back to size */
    if ((dynbuf = realloc(dynbuf,dynbuf_current)) == 0)
	outmem();

    return dynbuf;	
}

/* Output an error message along with the current line number in the
 * source file.
 */
void
output_error ()
{
    errors++;
    fprintf(stderr, "%s:%d: ", cur_file ? cur_file : "stdin", line_num);
    fprintf(stderr, "\n(%s) ", yytext);
}
