/* $Id: grammar.y,v 1.1 2004-05-03 05:17:48 behdad Exp $
 *
 * yacc grammar for C manual page generator
 * This was derived from the grammar given in Appendix A of
 * "The C Programming Language" by Kernighan and Ritchie.
 */

/* identifiers that are not reserved words */
%token T_IDENTIFIER T_TYPEDEF_NAME

/* storage class */
%token T_AUTO T_EXTERN T_REGISTER T_STATIC T_TYPEDEF
/* This keyword included for compatibility with C++. */
%token T_INLINE

/* type specifiers */
%token T_CHAR T_DOUBLE T_FLOAT T_INT T_VOID
%token T_LONG T_SHORT T_SIGNED T_UNSIGNED
%token T_ENUM T_STRUCT T_UNION

/* type qualifiers */
%token T_CONST T_VOLATILE
/* These keywords included for compatibility with MSDOS C compilers. */
%token T_CDECL T_FAR T_HUGE T_INTERRUPT T_NEAR T_PASCAL

/* paired braces and everything between them: { ... } */
%token T_BRACES

/* paired square brackets and everything between them: [ ... ] */
%token T_BRACKETS

/* three periods */
%token T_ELLIPSIS

/* equal sign followed by constant expression or stuff between braces */
%token T_INITIALIZER

/* string literal */
%token T_STRING_LITERAL

/* text inside a regular comment, and one at the end of a non-empty line */
%token T_COMMENT T_EOLCOMMENT

%type <declaration> declaration
%type <parameter> function_definition
%type <decl_spec> declaration_specifiers declaration_specifier
%type <decl_spec> storage_class type_specifier type_qualifier
%type <decl_spec> struct_or_union_specifier enum_specifier
%type <decl_list> declarator_list init_declarator_list
%type <declarator> init_declarator declarator direct_declarator
%type <declarator> parameter_declarator abstract_parameter_declarator
%type <declarator> abstract_declarator direct_abstract_declarator
%type <param_list> parameter_type_list parameter_list
%type <parameter> parameter_declaration
%type <param_list> opt_identifier_list identifier_list
%type <enumerator> enumerator
%type <enum_list> enumerator_list
%type <identifier> identifier
%type <text> struct_or_union
%type <text> pointer type_qualifier_list
%type <text> opt_comment opt_eolcomment
%type <text> any_id T_IDENTIFIER T_TYPEDEF_NAME
%type <text> T_BRACKETS
%type <text> T_COMMENT T_EOLCOMMENT T_STRING_LITERAL

%{
#include "c2man.h"
#include "semantic.h"
#include "strconcat.h"
#include "strappend.h"
#include "manpage.h"
#include "enum.h"

#ifdef I_STDARG
#include <stdarg.h>
#endif
#ifdef I_VARARGS
#include <varargs.h>
#endif

int yylex();

#define YYMAXDEPTH 150

/* where are we up to scanning through an enum? */
static enum { NOENUM, KEYWORD, BRACES } enum_state = NOENUM;

/* Pointer to parameter list for the current function definition. */
static ParameterList *func_params;

/* Table of typedef names */
SymbolTable *typedef_names;

boolean first_comment;	/* are we still looking for the first comment? */
static char *body_comment = NULL;/* last comment found at start of func body */
%}
%%

program
	: /* empty */
	| translation_unit
	;

translation_unit
	: external_declaration
	| translation_unit external_declaration
	;

external_declaration
	: declaration opt_eolcomment
	{
	    remember_declarations(NULL, &$1.decl_spec, &$1.decl_list, $2);
	}
	| T_COMMENT declaration opt_eolcomment
	{
	    remember_declarations($1, &$2.decl_spec, &$2.decl_list, $3);
	}
	| function_definition opt_eolcomment
	{
	    if (look_at_body_start && body_comment) {	
				/* Use the body comment */
	      new_manual_page(body_comment,&$1.decl_spec,$1.declarator);
	      body_comment = NULL; /* Prevent it being free'ed */
	    } else {
	      free_declarator($1.declarator);
	      free_decl_spec(&$1.decl_spec);
	    }
	}
	| T_COMMENT function_definition opt_eolcomment
	{
	    if (body_start_only) {
	      if (body_comment) {
		new_manual_page(body_comment,&$2.decl_spec,$2.declarator);
		body_comment = NULL; /* Prevent it being free'ed */
	      } else {
		free_declarator($2.declarator);
		free_decl_spec(&$2.decl_spec);
		safe_free($1);
	      }      
	    } else {
	      new_manual_page($1,&$2.decl_spec,$2.declarator);
	    }
	    safe_free($3);
	}
	| function_definition ';' opt_eolcomment
	{
	    if (look_at_body_start && body_comment) {
	      new_manual_page(body_comment,&$1.decl_spec,$1.declarator);
	      body_comment = NULL; /* Prevent it being free'ed */
	    } else {
	      free_declarator($1.declarator);
	      free_decl_spec(&$1.decl_spec);
	    }
	    safe_free($3);
	}
	| T_COMMENT function_definition ';' opt_eolcomment
	{
	    if (body_start_only) {
	      if (body_comment) {
		new_manual_page(body_comment,&$2.decl_spec,$2.declarator);
		body_comment = NULL; /* Prevent it being free'ed */
	      } else {
		free_declarator($2.declarator);
		free_decl_spec(&$2.decl_spec);
		safe_free($1);
	      }      
	    } else {
	      new_manual_page($1,&$2.decl_spec,$2.declarator);
	    }
	    safe_free($4);
	}
	| linkage_specification
	| T_COMMENT T_EOLCOMMENT
	{
	    free($1);
	    free($2);
	}
	| T_COMMENT
	{
	    if (inbasefile && first_comment)
	    {
		remember_terse($1);
		first_comment = FALSE;
	    }
	    free($1);
	}
	| T_EOLCOMMENT
	{
	    free($1);
	}
	| error ';'
	{
	    yyerrok;
	}
	;

linkage_specification
	: T_EXTERN T_STRING_LITERAL T_BRACES
	{
	    /* Provide an empty action here so bison will not complain about
	     * incompatible types in the default action it normally would
	     * have generated.
	     */
	}
	| T_EXTERN T_STRING_LITERAL declaration
	{
	    /* empty */
	}
	;

function_definition
	: declaration_specifiers declarator opt_eolcomment
	{
	    if ($2->type != DECL_FUNCTION) {
		yyerror("syntax error");
		YYERROR;
	    }
	    func_params = &($2->head->params);
            if ($3)	comment_last_parameter(&$2->head->params, $3);
	}
	  opt_declaration_list T_BRACES
	{
	    func_params = NULL;
	    $2->type = DECL_FUNCDEF;

	    $$.decl_spec = $1;
	    $$.declarator = $2;
	}
	| declarator opt_eolcomment
	{
	    if ($1->type != DECL_FUNCTION) {
		yyerror("syntax error");
		YYERROR;
	    }
	    func_params = &($1->head->params);
            if ($2)	comment_last_parameter(&$1->head->params, $2);
	}
	  opt_declaration_list T_BRACES
	{
	    DeclSpec	decl_spec;

	    func_params = NULL;
	    $1->type = DECL_FUNCDEF;

	    new_decl_spec(&$$.decl_spec, "int", DS_NONE);
	    $$.declarator = $1;
	}
	;

declaration
	: declaration_specifiers ';'
	{
	    $$.decl_spec = $1;
	    $$.decl_list.first = NULL;
	}
	| declaration_specifiers init_declarator_list ';'
	{
	    $$.decl_spec = $1;
	    $$.decl_list = $2;
	}
	| T_TYPEDEF declaration_specifiers declarator_list ';'
	{
	    new_typedef_symbols(&$2,&$3);
	    $$.decl_spec = $2;
	    $$.decl_list = $3;
	}
	;

declarator_list
	: declarator
	{
	    new_decl_list(&$$, $1);
	}
        | declarator_list ',' opt_eolcomment declarator
        {
            if ($3)	comment_last_decl(&$1, $3);
            add_decl_list(&$$, &$1, $4);
        }
        | declarator_list opt_eolcomment
        {
            $$ = $1;
            if ($2)	comment_last_decl(&$1, $2);
        }
	;

opt_declaration_list
	: /* empty */
	| declaration_list
	| declaration_list T_ELLIPSIS
	;

declaration_list
	: opt_comment declaration opt_eolcomment
	{
	    set_param_types(func_params, &$2.decl_spec, &$2.decl_list, $1, $3);
	}
	| declaration_list opt_comment declaration opt_eolcomment
	{
	    set_param_types(func_params, &$3.decl_spec, &$3.decl_list, $2, $4);
	}
	;

declaration_specifiers
	: declaration_specifier
	| declaration_specifiers declaration_specifier
	{
	    join_decl_specs(&$$, &$1, &$2);
	}
	;

declaration_specifier
	: storage_class
	| type_specifier
	| type_qualifier
	;

storage_class
	: T_AUTO
	{
	    new_decl_spec(&$$, "auto", DS_NONE);
	}
	| T_EXTERN
	{
	    new_decl_spec(&$$, "extern", DS_EXTERN);
	}
	| T_REGISTER
	{
	    new_decl_spec(&$$, "register", DS_NONE);
	}
	| T_STATIC
	{
	    new_decl_spec(&$$, "static", DS_STATIC);
	}
	| T_INLINE
	{
	    new_decl_spec(&$$, "inline", DS_INLINE);
	}
	;

type_specifier
	: T_CHAR
	{
	    new_decl_spec(&$$, "char", DS_CHAR);
	}
	| T_DOUBLE
	{
	    new_decl_spec(&$$, "double", DS_NONE);
	}
	| T_FLOAT
	{
	    new_decl_spec(&$$, "float", DS_FLOAT);
	}
	| T_INT
	{
	    new_decl_spec(&$$, "int", DS_NONE);
	}
	| T_LONG
	{
	    new_decl_spec(&$$, "long", DS_NONE);
	}
	| T_SHORT
	{
	    new_decl_spec(&$$, "short", DS_SHORT);
	}
	| T_SIGNED
	{
	    new_decl_spec(&$$, "signed", DS_NONE);
	}
	| T_UNSIGNED
	{
	    new_decl_spec(&$$, "unsigned", DS_NONE);
	}
	| T_VOID
	{
	    new_decl_spec(&$$, "void", DS_NONE);
	}
	| struct_or_union_specifier
	| enum_specifier
	| T_TYPEDEF_NAME
	{
	    Symbol *s = find_symbol(typedef_names, $1);
	   
	    new_enum_decl_spec(&$$, $1, s->flags,
		s->valtype == SYMVAL_ENUM ? s->value.enum_list
					  : (EnumeratorList *)NULL);
	}
	;

type_qualifier
	: T_CONST
	{
	    new_decl_spec(&$$, "const", DS_NONE);
	}
	| T_VOLATILE
	{
	    new_decl_spec(&$$, "volatile", DS_NONE);
	}
	| T_CDECL
	{
	    new_decl_spec(&$$, "cdecl", DS_NONE);
	}
	| T_INTERRUPT
	{
	    new_decl_spec(&$$, "interrupt", DS_NONE);
	}
	| T_FAR
	{
	    new_decl_spec(&$$, "far", DS_NONE);
	}
	| T_HUGE
	{
	    new_decl_spec(&$$, "huge", DS_NONE);
	}
	| T_NEAR
	{
	    new_decl_spec(&$$, "near", DS_NONE);
	}
	| T_PASCAL
	{
	    new_decl_spec(&$$, "pascal", DS_NONE);
	}
	;

struct_or_union_specifier
	: struct_or_union any_id T_BRACES
	{
	    dyn_decl_spec(&$$, strconcat($1, " ",$2," {}",NULLCP), DS_NONE);
	    free($2);
	}
	| struct_or_union T_BRACES
	{
	    dyn_decl_spec(&$$, strconcat($1," {}",NULLCP), DS_NONE);
	}
	| struct_or_union any_id
	{
	    dyn_decl_spec(&$$, strconcat($1, " ",$2,NULLCP), DS_NONE);
	    free($2);
	}
	;

struct_or_union
	: T_STRUCT
	{
	    $$ = "struct";
	}
	| T_UNION
	{
	    $$ = "union";
	}
	;

init_declarator_list
	: init_declarator
	{
	    new_decl_list(&$$, $1);
	}
        | init_declarator_list ',' opt_eolcomment init_declarator
        {
            if ($3)	comment_last_decl(&$1, $3);
            add_decl_list(&$$, &$1, $4);
        }
        | init_declarator_list opt_eolcomment
        {
            $$ = $1;
            if ($2)	comment_last_decl(&$1, $2);
        }
	;

init_declarator
	: declarator
	| declarator T_INITIALIZER
	;

enum_specifier
	: T_ENUM any_id '{' opt_eolcomment enumerator_list '}'
	{
	    add_enum_symbol($2, $5);
	    new_enum_decl_spec(&$$, strconcat("enum ",$2," {}",NULLCP),
		   DS_NONE, $5);
	    free($2);
	    safe_free($4);
	    enum_state = NOENUM;
	}
	| T_ENUM '{' opt_eolcomment enumerator_list '}'
	{
	    new_enum_decl_spec(&$$, strduplicate("enum {}"), DS_NONE, $4);
	    safe_free($3);
	    enum_state = NOENUM;
	}
	| T_ENUM any_id
	{
	    new_enum_decl_spec(&$$, strconcat("enum ",$2,NULLCP), DS_NONE,
	    	find_enum_symbol($2));
	    free($2);
	    enum_state = NOENUM;
	}
	;

enumerator_list
	: enumerator
	{
	    $$ = new_enumerator_list(&$1);
	}
	| enumerator_list ',' opt_eolcomment enumerator
	{
	    $$ = $1;
	    if ($3)	comment_last_enumerator($$, $3);
	    add_enumerator_list($$, &$4);
	}
	| enumerator_list opt_eolcomment
	{
	    $$ = $1;
	    if ($2)	comment_last_enumerator($$, $2);
	}
	| enumerator_list ',' opt_eolcomment
	{
	    $$ = $1;
	    if ($3)     comment_last_enumerator($$, $3);
	}
	;
	
enumerator
	: identifier
	{
	    new_enumerator(&$$,$1.name,$1.comment_before,$1.comment_after);
	}
	;
	
any_id
	: T_IDENTIFIER
	| T_TYPEDEF_NAME
	| any_id T_COMMENT
	{
	    $$ = $1;
	    free($2);
	}
	| any_id T_EOLCOMMENT
	{
	    $$ = $1;
	    free($2);
	}
	;

declarator
	: pointer T_EOLCOMMENT direct_declarator
	{
	    char *newtext = strappend($1,$3->text,NULLCP);
	    free($3->text);
	    $$ = $3;
	    $$->text = newtext;
	    if ($$->type == DECL_SIMPLE)
		$$->type = DECL_COMPOUND;
	    $$->retcomment = $2;
	}
	| pointer direct_declarator
	{
	    char *newtext = strappend($1,$2->text,NULLCP);
	    free($2->text);
	    $$ = $2;
	    $$->text = newtext;
	    if ($$->type == DECL_SIMPLE)
		$$->type = DECL_COMPOUND;
	}
	| T_EOLCOMMENT direct_declarator
	{
	    $$ = $2;
	    $$->retcomment = $1;
	}
	| direct_declarator
	{
	    $$ = $1;
	}
	;

parameter_declarator
	: pointer direct_declarator
	{
	    char *newtext = strappend($1,$2->text,NULLCP);
	    free($2->text);
	    $$ = $2;
	    $$->text = newtext;
	    if ($$->type == DECL_SIMPLE)
		$$->type = DECL_COMPOUND;
	}
	| direct_declarator
	{
	    $$ = $1;
	}
	;

direct_declarator
	: T_IDENTIFIER
	{
	    $$ = new_declarator($1, strduplicate($1));
	}
	| '(' declarator ')'
	{
	    char *newtext = strconcat("(",$2->text,")",NULLCP);
	    free($2->text);
	    $$ = $2;
	    $$->text = newtext;
	}
	| direct_declarator T_BRACKETS
	{
	    $$ = $1;
	    $$->text = strappend($1->text,$2,NULLCP);
	    free($2);
	}
	| direct_declarator '(' parameter_type_list ')'
	{
	    $$ = new_declarator(strduplicate("%s()"), strduplicate($1->name));
	    $$->params = $3;
	    $$->func_stack = $1;
	    $$->head = ($1->func_stack == NULL) ? $$ : $1->head;
	    $$->type = ($1->type == DECL_SIMPLE) ? DECL_FUNCTION : $1->type;
	}
	| direct_declarator '(' opt_identifier_list ')'
	{
	    $$ = new_declarator(strduplicate("%s()"), strduplicate($1->name));
	    $$->params = $3;
	    $$->func_stack = $1;
	    $$->head = ($1->func_stack == NULL) ? $$ : $1->head;
	    $$->type = ($1->type == DECL_SIMPLE) ? DECL_FUNCTION : $1->type;
	}
	;

pointer
	: '*' type_qualifier_list
	{
	    $$ = strconcat("*",$2, NULLCP);
	    safe_free($2);
	}
	| '*' type_qualifier_list pointer
	{
	    $$ = $2 ? strconcat("*",$2, $3, NULLCP)
		    : strconcat("*", $3, NULLCP);
	    safe_free($2);
	    free($3);
	}
	;

type_qualifier_list
	: /* empty */
	{
	    $$ = NULL;
	}
	| type_qualifier_list type_qualifier
	{
	    $$ = $1 ? strconcat($1," ",$2.text," ",NULLCP)
		    : strconcat($2.text," ",NULLCP);
	    safe_free($1);
	    free_decl_spec(&$2);
	}
	;

parameter_type_list
	: parameter_list opt_eolcomment
	{
	    $$ = $1;
	    if ($2)	comment_last_parameter(&$1, $2);
	}
	| parameter_list ',' opt_eolcomment
		opt_comment T_ELLIPSIS opt_comment opt_eolcomment
	{
	    Identifier ellipsis;

	    if ($3)	comment_last_parameter(&$1, $3);
	    ellipsis.name = strduplicate("...");

	    if ($4 && $6 && $7)
	    {
		yyerror("ellipsis parameter has multiple comments");
		free($7);
		free($6);
		free($4);
		ellipsis.comment_before = ellipsis.comment_after = NULL;
	    }
	    else
	    {
		ellipsis.comment_before = $4;
		ellipsis.comment_after = $6 ? $6 : $7;
	    }

	    add_ident_list(&$$, &$1, &ellipsis);
	}
	;

parameter_list
	: parameter_declaration
	{
	    new_param_list(&$$, &$1);
	}
	| parameter_list ',' opt_eolcomment parameter_declaration
	{
	    if ($3)	comment_last_parameter(&$1, $3);
	    add_param_list(&$$, &$1, &$4);
	}
	;

parameter_declaration
	: opt_comment declaration_specifiers parameter_declarator opt_comment
	{
	    new_parameter(&$$, &$2, $3, $1, $4);
	}
	| opt_comment declaration_specifiers abstract_parameter_declarator opt_comment
	{
	    new_parameter(&$$, &$2, $3, $1, $4);
	}
	| opt_comment declaration_specifiers opt_comment
	{
	    new_parameter(&$$, &$2, (Declarator *)NULL, $1, $3);
	}
	;

opt_identifier_list
	: /* empty */
	{
	    new_ident_list(&$$);
	}
	| identifier_list opt_eolcomment
	{
	    $$ = $1;
	    if ($2)	comment_last_parameter(&$1, $2);
	}
	;

identifier_list
	: identifier
	{
	    new_ident_list(&$$);
	    add_ident_list(&$$, &$$, &$1);
	}
	| identifier_list ',' opt_eolcomment identifier
	{
	    if ($3)	comment_last_parameter(&$1, $3);
	    add_ident_list(&$$, &$1, &$4);
	}
	;

identifier
	: opt_comment T_IDENTIFIER opt_comment
	{
	    $$.comment_before = $1;
	    $$.comment_after = $3;
	    $$.name = $2;
	}
	
abstract_declarator
	: pointer
	{
	    $$ = new_declarator($1, NULLCP);
	}
	| pointer T_EOLCOMMENT direct_abstract_declarator
	{
	    char *newtext = strappend($1,$3->text,NULLCP);
	    free($3->text);
	    $$ = $3;
	    $$->text = newtext;
	    if ($$->type == DECL_SIMPLE)
		$$->type = DECL_COMPOUND;
	    $$->retcomment = $2;
	}
	| pointer direct_abstract_declarator
	{
	    char *newtext = strappend($1,$2->text,NULLCP);
	    free($2->text);
	    $$ = $2;
	    $$->text = newtext;
	    if ($$->type == DECL_SIMPLE)
		$$->type = DECL_COMPOUND;
	}
	| T_EOLCOMMENT direct_abstract_declarator
	{
	    $$ = $2;
	    $$->retcomment = $1;
	}
	| direct_abstract_declarator
	{
	    $$ = $1;
	}
	;

abstract_parameter_declarator
	: pointer
	{
	    $$ = new_declarator($1, NULLCP);
	}
	| pointer direct_abstract_declarator
	{
	    char *newtext = strappend($1,$2->text,NULLCP);
	    free($2->text);
	    $$ = $2;
	    $$->text = newtext;
	    if ($$->type == DECL_SIMPLE)
		$$->type = DECL_COMPOUND;
	}
	| direct_abstract_declarator
	{
	    $$ = $1;
	}
	;

direct_abstract_declarator
	: '(' abstract_declarator ')'
	{
	    char *newtext = strconcat("(",$2->text,")",NULLCP);
	    free($2->text);
	    $$ = $2;
	    $$->text = newtext;
	}
	| direct_abstract_declarator T_BRACKETS
	{
	    $$ = $1;
	    $$->text = strappend($1->text,$2,NULLCP);
	    free($2);
	}
	| T_BRACKETS
	{
	    $$ = new_declarator($1, NULLCP);
	}
	| direct_abstract_declarator '(' parameter_type_list ')'
	{
	    $$ = new_declarator(strduplicate("%s()"), NULLCP);
	    $$->params = $3;
	    $$->func_stack = $1;
	    $$->head = ($1->func_stack == NULL) ? $$ : $1->head;
	    $$->type = ($1->type == DECL_SIMPLE) ? DECL_FUNCTION : $1->type;
	}
	| direct_abstract_declarator '(' ')'
	{
	    $$ = new_declarator(strduplicate("%s()"), NULLCP);
	    $$->func_stack = $1;
	    $$->head = ($1->func_stack == NULL) ? $$ : $1->head;
	    $$->type = ($1->type == DECL_SIMPLE) ? DECL_FUNCTION : $1->type;
	}
	| '(' parameter_type_list ')'
	{
	    Declarator *d;
	    
	    d = new_declarator(NULL, NULL);
	    $$ = new_declarator(strduplicate("%s()"), NULLCP);
	    $$->params = $2;
	    $$->func_stack = d;
	    $$->head = $$;
	}
	| '(' ')'
	{
	    Declarator *d;
	    
	    d = new_declarator(NULL, NULL);
	    $$ = new_declarator(strduplicate("%s()"), NULLCP);
	    $$->func_stack = d;
	    $$->head = $$;
	}
	;

opt_comment
	: /* empty */
	{
	    $$ = NULL;
	}
	| T_COMMENT
	;

opt_eolcomment
	: /* empty */
	{
	    $$ = NULL;
	}
	| T_EOLCOMMENT
	;

%%
#ifdef MSDOS
#include "lex_yy.c"
#else
#ifdef VMS
#include "lexyy.c"
#else
#include "lex.yy.c"
#endif /* !VMS   */
#endif /* !MSDOS */

#ifdef I_STDARG
void yyerror(const char *format, ...)
#else
void yyerror(va_alist)
    va_dcl
#endif
{
#ifndef I_STDARG
    const char *format;
#endif
    va_list args;

    output_error();

#ifdef I_STDARG
    va_start(args, format);
#else
    va_start(args);
    format = va_arg(args, char *);
#endif

    vfprintf(stderr, format, args);
    va_end(args);
    putc('.',stderr);
    putc('\n',stderr);
}

void
parse_file (start_file)
const char *start_file;
{
    const char *s;
#ifdef FLEX_SCANNER
    static boolean restart = FALSE;
#endif

    cur_file = start_file ? strduplicate(start_file) : NULL;

    if (basefile && strlen(basefile) > 2) {
	s = basefile + strlen(basefile) - 2;
	if (strcmp(s, ".l") == 0 || strcmp(s, ".y") == 0)
	    BEGIN LEXYACC;
    }

    typedef_names = create_symbol_table();
    enum_table = create_symbol_table();

    line_num = 1;
    ly_count = 0;
    first_comment = group_together && !terse_specified;

    /* flex needs a yyrestart before every file but the first */
#ifdef FLEX_SCANNER
    if (restart)	yyrestart(yyin);
    restart = TRUE;
#endif

    yyparse();

    destroy_symbol_table(enum_table);
    destroy_symbol_table(typedef_names);

    safe_free(cur_file);
}
