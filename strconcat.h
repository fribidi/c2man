/* $Id: strconcat.h,v 1.1 2004-05-03 05:17:48 behdad Exp $
 * concatenate a list of strings, storing them in a malloc'ed region
 */
#include "config.h"

char *strconcat _V((const char *first, ...));
