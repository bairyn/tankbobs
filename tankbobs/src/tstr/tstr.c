/*
Copyright (C) 2008 Byron James Johnson

This file is part of Tankbobs.

	Tankbobs is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	Tankbobs is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
along with Tankbobs.  If not, see <http://www.gnu.org/licenses/>.
*/

#define TSTR_C
#include "tstr.h"
#include "crossdll.h"

#include <stdlib.h>

CDLL_BEGIN

static void tstr_private_init(tstr *s)
{
	s->len = s->mem = 0;
	s->data = NULL;
}

tstr *CDLL_PREFIX tstr_new()
{
	tstr *res = malloc(sizeof(tstr));
	tstr_private_init(res);
	return res;
}

void CDLL_PREFIX tstr_free(tstr *s)
{
	free(s->data);
	free(s);
}

void CDLL_PREFIX tstr_set(tstr *s, const char *t)
{
	Uint32 len = s->len = strlen(t);

	if(!len)
		return;

	if(len > s->mem)
	{
		free(s->data);
		s->data = malloc(len);
	}

	memmove(s->data, t, len);
}

void CDLL_PREFIX tstr_lset(tstr *s, const char *t, Uint32 len)
{
	s->len = len;

	if(!len)
		return;

	if(len > s->mem)
	{
		free(s->data);
		s->data = malloc(len);
	}

	memmove(s->data, t, len);
}

void CDLL_PREFIX tstr_cat(tstr *s, const char *t)
{
	Uint32 len = s->len = strlen(t) + s->len;

	if(!strlen(t))
		return;

	if(len > s->mem)
	{
		char *olddata = s->data;
		s->data = malloc(len);
		memmove(s->data, olddata, len - strlen(t));
		free(olddata);
	}

	memmove(&s->data[len - strlen(t)], t, strlen(t));
}

void CDLL_PREFIX tstr_lcat(tstr *s, const char *t, Uint32 len)
{
	if(!len)
		return;

	if(s->len + len > s->mem)
	{
		char *olddata = s->data;
		s->data = malloc(s->len + len);
		memmove(s->data, olddata, s->len);
		free(olddata);
	}

	memmove(&s->data[s->len], t, len);
	s->len += len;
}

void CDLL_PREFIX tstr_set_tstr(tstr *s, tstr *t)
{
	if(!t->len || !t->data || !t->mem)
		return;

	if((s->len = t->len) > s->mem)
	{
		free(s->data);
		s->data = malloc(s->len);
	}

	memmove(s->data, t->data, s->len);
}

void CDLL_PREFIX tstr_cat_tstr(tstr *s, tstr *t)
{
	if(!t->len || !t->data || !t->mem)
		return;

	if(s->len + t->len > s->mem)
	{
		char *olddata = s->data;
		s->data = malloc(s->len + t->len);
		memmove(s->data, olddata, s->len);
		free(olddata);
	}

	memmove(&s->data[s->len], t->data, t->len);
	s->len += t->len;
}

void CDLL_PREFIX tstr_base_set(tstr *s, const char *t)
{
	Uint32 len = s->len = strlen(t);

	if(len > s->mem)
	{
		free(s->data);
		s->data = malloc(len);
	}

	memcpy(s->data, t, len);
}

void CDLL_PREFIX tstr_base_lset(tstr *s, const char *t, Uint32 len)
{
	s->len = len;

	if(len > s->mem)
	{
		free(s->data);
		s->data = malloc(len);
	}

	memcpy(s->data, t, len);
}

void CDLL_PREFIX tstr_base_cat(tstr *s, const char *t)
{
	Uint32 len = s->len = strlen(t) + s->len;

	if(len > s->mem)
	{
		char *olddata = s->data;
		s->data = malloc(len);
		memcpy(s->data, olddata, len - strlen(t));
		free(olddata);
	}

	memcpy(&s->data[len - strlen(t)], t, strlen(t));
}

void CDLL_PREFIX tstr_base_lcat(tstr *s, const char *t, Uint32 len)
{
	if(s->len + len > s->mem)
	{
		char *olddata = s->data;
		s->data = malloc(s->len + len);
		memcpy(s->data, olddata, s->len);
		free(olddata);
	}

	memcpy(&s->data[s->len], t, len);
	s->len += len;
}

void CDLL_PREFIX tstr_base_set_tstr(tstr *s, tstr *t)
{
	if((s->len = t->len) > s->mem)
	{
		free(s->data);
		s->data = malloc(s->len);
	}

	memcpy(s->data, t->data, s->len);
}

void CDLL_PREFIX tstr_base_cat_tstr(tstr *s, tstr *t)
{
	if(s->len + t->len > s->mem)
	{
		char *olddata = s->data;
		s->data = malloc(s->len + t->len);
		memcpy(s->data, olddata, s->len);
		free(olddata);
	}

	memcpy(&s->data[s->len], t->data, t->len);
	s->len += t->len;
}

const char *CDLL_PREFIX tstr_cstr(tstr *s)
{
	if(s->len >= s->mem)
	{
		char *olddata = s->data;
		s->data = malloc(s->len + 1);
		memcpy(s->data, olddata, s->len);
		free(olddata);
	}
	s->data[s->len] = 0;

	return s->data;
}

void CDLL_PREFIX tstr_shrink(tstr *s)
{
	char *olddata = s->data;

	if(s->len >= s->mem)
		return;

	s->data = malloc(s->len);
	memcpy(s->data, olddata, s->len);
	free(olddata);
}

static Uint8 tstr_private_find(const char *pos, const char *end, const char *find)
{
	Uint32 i = 0;

	while(pos + i <= end && i < strlen(find))
	{
		if(pos[i] != find[i])
			return 0;
	}

	return 1;
}

void CDLL_PREFIX tstr_find(tstr *s, const char *t, Sint8 order, Sint32 start, Sint32 *firstOccuranceRelBegin, Sint32 *firstOccuranceRelEnd)
{
	const char *pos = s->data;

	if(start == 0 || s->len > strlen(t))
	{
		return;
	}
	else if(start > 0)
	{
		pos += start - 1;
	}
	else if(start < 0)
	{
		pos += s->len - 1;
		pos -= abs(start) - 1;
	}

	if(pos < s->data)
		pos = s->data;
	if(pos > s->data + s->len)
		pos = s->data + s->len;

	while(pos >= s->data && pos <= s->data + s->len)
	{
		if(tstr_private_find(pos, s->data + s->len, t))
		{
			*firstOccuranceRelBegin = pos - s->data;
			*firstOccuranceRelEnd = s->data - pos + s->len;
			return;
		}
		pos += order;
	}
}

CDLL_END
