/* $Id: html.c,v 1.1 2004-05-03 05:17:49 behdad Exp $
 * functions for html style output.
 */
#include "c2man.h"
#include "manpage.h"
#include "output.h"
#include <ctype.h>

static int html_in_code = 0;

void html_terse_sep();
void html_description _((const char *text));

void html_char(c)
const int c;
{
  switch (c)
  {
  case '<':
    put_string("&lt;");
    break;
  case '>':
    put_string("&gt;");
    break;
  case '&':
    put_string("&amp;");
    break;
  case '"':
    put_string("&quot;");
    break;
  default:
    putchar(c);
    break;
  }
}

void html_text(text)
const char *text;
{
  while(*text)
  {
    html_char(*text++);
  }
}


void html_comment()
{
  put_string("<!");
}

void html_header(firstpage, input_files, grouped, name, terse, section)
   ManualPage         *firstpage;
   int                 input_files;
   boolean             grouped;
   const char         *name;
   const char         *terse;
   const char         *section;
{

  output_warning();
  put_string("<header>\n");
  put_string("<title>");
  html_text(name);
  html_terse_sep();
  html_text(terse);
  put_string("</title>\n");
  put_string("</header>\n");
  put_string("<body>\n");
}

void html_file_end()
{
  put_string("\n</body>\n");
}

void html_dash()
{
  put_string("-");
}

void html_section(name)
const char         *name;
{
  put_string("<h1>");
  html_text(name);
  put_string("</h1>\n");
}

void html_sub_section(name)
const char *name;
{
  put_string("<h2>");
  html_text(name);
  put_string("</h2>");
}

void html_break_line()
{
  if (!html_in_code)
  {
    put_string("<br>\n");
  }
}

void html_blank_line()
{
  if (!html_in_code)
  {
    put_string("<p>\n");
  }
  else
  {
    putchar('\n');
  }
}

void html_code_start()
{
  put_string("<pre>");
  html_in_code = 1;
}

void html_code_end()
{
  put_string("</pre>\n");
  html_in_code = 0;
}

void html_code(text)
const char *text;
{
  html_code_start();
  html_text(text);
  html_code_end();
}

void html_tag_list_start()
{
  put_string("<dl>");
}

void html_tag_list_end()
{
  put_string("</dl>\n");
}

void html_tag_entry_start()
{   
  put_string("<dt>\n");
}   
    
void html_tag_entry_start_extra()
{   
  put_string("<dt>\n");
}   
    
void html_tag_entry_end()
{
  put_string("<dd>\n");
}

void html_tag_entry_end_extra(text)
const char *text;
{
  put_string(" <em>");
  put_string(text);
  put_string("</em>)");
  put_string("<dd>\n");
}

void html_table_start(longestag)
const char *longestag;
{
  put_string("<ul>");
}

void html_table_entry(name, description)
const char         *name;
const char         *description;
{
  put_string("<li>");
  html_text(name);
  if (description)
  {
    html_terse_sep();
    html_description(description);
  }
  put_string("<p>\n");
}

void html_table_end()
{
  put_string("</ul>");
}

void html_indent()
{
  put_string("\t");
}

void html_list_start()
{
  put_string("<ul>");
}


void html_list_end()
{
  put_string("</ul>");
}

void html_list_entry(name)
const char *name;
{
  put_string("<li>");
  put_string(name);
  put_string("\n");
}

void html_list_separator()
{
  put_string(",\n");
}

void html_include(filename)
const char *filename;
{
  printf(".so %s\n", filename);
}

void html_name(name)
const char *name;
{
  if (name)
    html_text(name);
  else
    html_section("NAME");
}

void html_terse_sep()
{
  html_char(' ');
  html_dash();
  html_char(' ');
}

void html_reference(name)
const char *name;
{
  put_string("<a href=");
  put_string(name);
  put_string(".html>");
  put_string(name);
  put_string("</a>\n");
}  

void html_emphasized(text)
const char *text;
{
  put_string("<em>");
  put_string(text);
  put_string("</em>");
}

/* ideally, this should be made aware of embedded html commands */
void html_description(text)
const char *text;
{
    enum { TEXT, PERIOD, CAPITALISE } state = CAPITALISE;
    boolean new_line = TRUE;
    
    /* correct punctuation a bit as it goes out */
    for (;*text;text++)
    {
	int c = *text;

	if (new_line && (c == '-' || c == '*' || c == '\n' ||
							    is_numbered(text)))
	{
	    output->break_line();
	    state = CAPITALISE;
	}
	else if (new_line && c == '\n') {  /* Two newlines - Paragraph break */
	    output->blank_line();
	}
	else if (c == '.')
	    state = PERIOD;
	else if (isspace(c) && state == PERIOD)
	    state = CAPITALISE;
	else if (isalnum(c))
	{   
	    if (islower(c) && state == CAPITALISE)	c = toupper(c);
	    state = TEXT;
	}
           
	output->character(c);
	new_line = c == '\n';
    }

    /* do a full stop if there wasn't one */
    if (state == TEXT)	output->character('.');
}

/* ideally, this should be made aware of embedded html commands */
void
html_returns(comment)
const char *comment;
{
    enum { TEXT, PERIOD, CAPITALISE } state = CAPITALISE;
    char lastchar = '\n';
    boolean tag_list_started = FALSE;

    /* for each line... */
    while (*comment)
    {
	boolean tagged = FALSE;

	{
	    const char *c = comment;

	    /* search along until the end of a word */
	    while (*c && *c != ':' && !isspace(*c))
		c++;

	    /* skip all spaces or tabs after the first word */
	    while (*c && *c != '\n')
	    {
		if (*c == '\t' || *c == ':')
		{
		    tagged = TRUE;
		    break;
		}
		else if (!isspace(*c))
		    break;

		c++;
	    }
	}

	/* is it tagged?; explicitly reject dot commands */
	if (tagged)
	{
	    /* output lingering newline if necessary */
	    if (lastchar != '\n')
	    {
		if (state == TEXT && !ispunct(lastchar))	output->character('.');
		output->character(lastchar = '\n');
	    }

	    if (!tag_list_started)
	    {
		output->tag_list_start();
		tag_list_started = TRUE;
	    }

	    /* output the taggy bit */
	    output->tag_entry_start();
	    while (*comment && *comment != ':' && !isspace(*comment))
		output->character(*comment++);
	    output->tag_entry_end();

	    /* skip any extra tabs or spaces */
	    while (*comment == ':' || (isspace(*comment) && *comment != '\n'))
		comment++;

	    state = CAPITALISE;
	}

	/* terminate the previous line if necessary */
	if (lastchar != '\n')	output->character(lastchar = '\n');

	/* correct punctuation a bit as the line goes out */
	for (;*comment && *comment != '\n'; comment++)
	{
	    char c = *comment;

	    if (c == '.')
		state = PERIOD;
	    else if (isspace(c) && state == PERIOD)
		state = CAPITALISE;
	    else if (isalnum(c))
	    {   
		if (islower(c) && state == CAPITALISE && fixup_comments)
		    c = toupper(c);
		state = TEXT;
	    }

	    output->character(lastchar = c);
	}

	/* if it ended in punctuation, just output the nl straight away. */
	if (ispunct(lastchar))
	{
	    if (lastchar == '.')	state = CAPITALISE;
	    output->character(lastchar = '\n');
	}

	if (*comment)	comment++;
    }

    /* output lingering newline if necessary */
    if (lastchar != '\n')
    {
	if (state == TEXT && !ispunct(lastchar) && fixup_comments)
	    output->character('.');
	output->character('\n');
    }

    if (tag_list_started)
	output->tag_list_end();
}


struct Output       html_output =
{
  html_comment,
  html_header,
  html_dash,
  html_section,
  html_sub_section,
  html_break_line,
  html_blank_line,
  html_code_start,
  html_code_end,
  html_code,
  html_tag_list_start,
  html_tag_list_end,
  html_tag_entry_start,
  html_tag_entry_start_extra,
  html_tag_entry_end,
  html_tag_entry_end_extra,
  html_table_start,
  html_table_entry,
  html_table_end,
  html_indent,
  html_list_start,
  html_list_entry,
  html_list_separator,
  html_list_end,
  html_include,
  html_file_end,
  html_text,
  html_char,
  NULL,				/* html_parse_option */
  dummy,			/* html_print_options */
  html_name,
  html_terse_sep,
  html_reference,      
  html_emphasized,
  html_description,
  html_returns
  };
