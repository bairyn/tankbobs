/*
Tankbobs light string type.

Base tstr operations assume two things for performance:
no arguments passed share memory
no empty string are passed to t (for set/cat_tstr, this means they have data)

Also note that tstr_cstr and find is a slow operation, and may also be used
without a return value to make sure data is a valid null-terminated string

And finally, len and data (, and mem, if it really is needed) can always be accessed
externally.  Example uses are extended usage functions, stdlib's mem* operations, and etc.
*/

#ifndef TSTR_H
#define TSTR_H

#include <SDL.h> /* tstr requires SDL's types */

#include "crossdll.h"

typedef struct
{
	Uint32 len; /* size */
	Uint32 mem; /* capacity */
	char *data;
} tstr; /* a light string type */

#ifdef TSTR_C /* only define prototypes if called from tstr.c */
#undef TSTR_C
CDLL_PREFIX tstr *tstr_new(void);
CDLL_PREFIX void tstr_free(tstr *s);
CDLL_PREFIX void tstr_set(tstr *s, const char *t);
CDLL_PREFIX void tstr_lset(tstr *s, const char *t, Uint32 len);
CDLL_PREFIX void tstr_cat(tstr *s, const char *t);
CDLL_PREFIX void tstr_lcat(tstr *s, const char *t, Uint32 len);
CDLL_PREFIX void tstr_set_tstr(tstr *s, tstr *t);
CDLL_PREFIX void tstr_cat_tstr(tstr *s, tstr *t);
CDLL_PREFIX void tstr_base_set(tstr *s, const char *t);
CDLL_PREFIX void tstr_base_lset(tstr *s, const char *t, Uint32 len);
CDLL_PREFIX void tstr_base_cat(tstr *s, const char *t);
CDLL_PREFIX void tstr_base_lcat(tstr *s, const char *t, Uint32 len);
CDLL_PREFIX void tstr_base_set_tstr(tstr *s, tstr *t);
CDLL_PREFIX void tstr_base_cat_tstr(tstr *s, tstr *t);
CDLL_PREFIX const char *tstr_cstr(tstr *s);
CDLL_PREFIX void tstr_shrink(tstr *s);
CDLL_PREFIX void tstr_find(tstr *s, const char *t, Sint8 order, Sint32 start, Sint32 *firstOccuranceRelBegin, Sint32 *firstOccuranceRelEnd);  /* index + 1 - will NOT set values if not found */
#endif

#endif
