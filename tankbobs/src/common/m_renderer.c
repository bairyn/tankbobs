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

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <SDL/SDL.h>
#include <SDL/SDL_image.h>
#include <SDL/SDL_ttf.h>
#include <SDL/SDL_endian.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <luaconf.h>
#include <math.h>
#include <zlib.h>
#include <GL/gl.h>
#include <GL/glu.h>

#include "common.h"
#include "m_tankbobs.h"
#include "crossdll.h"
#include "tstr.h"

#define MIN_VID_MEM    256

#define POWER_OF_TWO 1

#define CHECKCURRENTFONT(L) \
do \
{ \
	if(!r_currentFont) \
	{ \
		lua_pushstring(L, "no font selected yet\n"); \
		lua_error(L); \
	} \
} while(0)

/* #define FONT_USEBLIT */

typedef struct r_font_s r_font_t;
struct r_font_s
{
	TTF_Font *font;
	char name[BUFSIZE];
	char filename[BUFSIZE];
	int size;
	r_font_t *next;
};

typedef struct r_font_t r_font;

typedef struct r_fontCache_s r_fontCache_t;
struct r_fontCache_s
{
	int active;

	int lastUsedTime;
	int prioritized;

	GLuint list;
	GLuint texture;
	double w, h;
	char string[BUFSIZE];
};

typedef struct r_fontCache_t r_fontCache;

static r_font_t *r_fonts = NULL;
static r_font_t *r_currentFont = NULL;
#define FONTCACHES 128
static r_fontCache_t r_fontCaches[FONTCACHES];

void r_init(lua_State *L)
{
	memset(r_fontCaches, 0, sizeof(r_fontCaches));
}

int r_initialize(lua_State *L)
{
	CHECKINIT(init, L);

/*
	int stereo  = config_get_d(CONFIG_STEREO)      ? 1 : 0;
	int stencil = config_get_d(CONFIG_REFLECTION)  ? 1 : 0;
	int buffers = config_get_d(CONFIG_MULTISAMPLE) ? 1 : 0;
	int samples = config_get_d(CONFIG_MULTISAMPLE);
	int vsync   = config_get_d(CONFIG_VSYNC)       ? 1 : 0;
	SDL_GL_SetAttribute(SDL_GL_STEREO,             stereo);
	SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE,       stencil);
	SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, buffers);
	SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, samples);
	SDL_GL_SetAttribute(SDL_GL_SWAP_CONTROL,       vsync);
*/

	SDL_GL_SetAttribute(SDL_GL_RED_SIZE,     5);
	SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE,   5);
	SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE,    5);
	SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE,  16);
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
	SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
	SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 16);

	if(TTF_Init() == -1)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "Error initializing SDL_ttf: ");
		CDLL_FUNCTION("libtstr", "tstr_cat", void(*)(tstr *, const char *))
			(message, TTF_GetError());
		CDLL_FUNCTION("libtstr", "tstr_base_cat", void(*)(tstr *, const char *))
			(message, "\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	return 0;
}

int r_checkRenderer(lua_State *L)
{
	const SDL_VideoInfo *videoInfo = SDL_GetVideoInfo();

	CHECKINIT(init, L);

	if(!videoInfo->hw_available)
	{
		fprintf(stderr, "hardware surfaces disabled\n");
	}
	if(!videoInfo->wm_available)
	{
		fprintf(stderr, "no window manager available\n");
	}
	if(!videoInfo->blit_hw)
	{
		fprintf(stderr, "hardware surface acceleration disabled\n");
	}
	if(!videoInfo->blit_hw_CC)
	{
		fprintf(stderr, "colored hardware surface acceleartion disabled\n");
	}
	if(!videoInfo->blit_hw_A)
	{
		fprintf(stderr, "HW alpha disabled\n");
	}
	if(!videoInfo->blit_sw)
	{
		fprintf(stderr, "software surface acceleration disabled\n");
	}
	if(!videoInfo->blit_sw_CC)
	{
		fprintf(stderr, "colored software surface acceleration disabled\n");
	}
	if(!videoInfo->blit_sw_A)
	{
		fprintf(stderr, "SW alpha is disabled\n");
	}
	if(!videoInfo->blit_fill)
	{
		fprintf(stderr, "accelearted color filling disabled\n");
	}
	if(videoInfo->video_mem < MIN_VID_MEM)
	{
		fprintf(stderr, """(%d) video mem against min %d\n", videoInfo->video_mem, MIN_VID_MEM);
	}

	return 0;
}

int r_newWindow(lua_State *L)
{
	int w = 0, h = 0, f = 0;
	const char *title, *icon;
	SDL_Surface *sicon;

	CHECKINIT(init, L);

	w = luaL_checkinteger(L, -5);
	h = luaL_checkinteger(L, -4);
	f = lua_toboolean(L, -3);
	title = luaL_checkstring(L, -2);
	icon = luaL_checkstring(L, -1);
	lua_pop(L, 3);

	if(w <= 0)
		w = 1;
	if(h <= 0)
		h = 1;

	SDL_FreeSurface(SDL_GetVideoSurface());

#ifdef FONT_USEBLIT
	if(!SDL_SetVideoMode(w, h, 0, SDL_OPENGL | ((f) ? (SDL_FULLSCREEN) : (0)) | SDL_OPENGLBLIT))
#else
	if(!SDL_SetVideoMode(w, h, 0, SDL_OPENGL | ((f) ? (SDL_FULLSCREEN) : (0))))
#endif
	{
#ifdef TDEBUG
		fprintf(stdout, "Warning: could not init video mode.  Trying again with lower antialias multisampling\n");
#endif
		SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 8);
#ifdef FONT_USEBLIT
		if(!SDL_SetVideoMode(w, h, 0, SDL_OPENGL | ((f) ? (SDL_FULLSCREEN) : (0)) | SDL_OPENGLBLIT))
#else
		if(!SDL_SetVideoMode(w, h, 0, SDL_OPENGL | ((f) ? (SDL_FULLSCREEN) : (0))))
#endif
		{
#ifdef TDEBUG
			fprintf(stdout, "Warning: could not init video mode.  Trying again with lower antialias multisampling\n");
#endif
			SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);
#ifdef FONT_USEBLIT
			if(!SDL_SetVideoMode(w, h, 0, SDL_OPENGL | ((f) ? (SDL_FULLSCREEN) : (0)) | SDL_OPENGLBLIT))
#else
			if(!SDL_SetVideoMode(w, h, 0, SDL_OPENGL | ((f) ? (SDL_FULLSCREEN) : (0))))
#endif
			{
#ifdef TDEBUG
				fprintf(stdout, "Warning: could not init video mode.  Trying again again with no antialias multisampling\n");
#endif
				SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 0);
				SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 0);
#ifdef FONT_USEBLIT
				if(!SDL_SetVideoMode(w, h, 0, SDL_OPENGL | ((f) ? (SDL_FULLSCREEN) : (0)) | SDL_OPENGLBLIT))
#else
				if(!SDL_SetVideoMode(w, h, 0, SDL_OPENGL | ((f) ? (SDL_FULLSCREEN) : (0))))
#endif
				{
#ifdef TDEBUG
					fprintf(stdout, "Warning: could not init video mode.  Trying again again again with no doublebuffer\n");
#endif
					SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 0);
#ifdef FONT_USEBLIT
					if(!SDL_SetVideoMode(w, h, 0, SDL_OPENGL | ((f) ? (SDL_FULLSCREEN) : (0)) | SDL_OPENGLBLIT))
#else
					if(!SDL_SetVideoMode(w, h, 0, SDL_OPENGL | ((f) ? (SDL_FULLSCREEN) : (0))))
#endif
					{
#ifdef TDEBUG
						fprintf(stderr, "Video mode failed: %s\n", SDL_GetError());
#endif
						lua_pushlstring(L, SDL_GetError(), strlen(SDL_GetError()));
						lua_error(L);
					}
					else
					{
#ifdef TDEBUG
						fprintf(stdout, "Starting in single-buffer mode.\n");
#endif
					}
				}
				else
				{
#ifdef TDEBUG
					fprintf(stdout, "Starting without multisampling.\n");
#endif
				}
			}
			else
			{
#ifdef TDEBUG
				fprintf(stdout, "Starting with minimal multisamplesamples.\n");
#endif
			}
		}
		else
		{
#ifdef TDEBUG
			fprintf(stdout, "Starting with low multisamplesamples.\n");
#endif
		}
	}

	SDL_WM_SetCaption(title, icon);
#ifndef __APPLE__
	sicon = IMG_Load(icon);
	SDL_WM_SetIcon(sicon, NULL);
	SDL_FreeSurface(sicon);
#endif

	return 0;
}

int r_ortho2D(lua_State *L)
{
	double l, r, b, t;

	CHECKINIT(init, L);

	t = luaL_checknumber(L, -1);
	b = luaL_checknumber(L, -2);
	r = luaL_checknumber(L, -3);
	l = luaL_checknumber(L, -4);

	gluOrtho2D(l, r, b, t);

	return 0;
}

int r_swapBuffers(lua_State *L)
{
	CHECKINIT(init, L);

	SDL_GL_SwapBuffers();

	return 0;
}

int r_newFont(lua_State *L)
{
	r_font_t *font;

	font = malloc(sizeof(r_font_t));
	memset(font, 0, sizeof(r_font_t));

	strncpy(font->name, luaL_checkstring(L, 1), sizeof(font->name));
	strncpy(font->filename, luaL_checkstring(L, 2), sizeof(font->filename));
	font->size = luaL_checkinteger(L, 3);
	font->next = NULL;

#ifndef FONT_USEBLIT
	memset(r_fontCaches, 0, sizeof(r_fontCaches));
#endif

	font->font = TTF_OpenFont(font->filename, font->size);
	if(!font->font)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "Error loading font '");
		if(font->filename[0])
		{
			CDLL_FUNCTION("libtstr", "tstr_cat", void(*)(tstr *, const char *))
				(message, font->filename);
		}
		CDLL_FUNCTION("libtstr", "tstr_base_cat", void(*)(tstr *, const char *))
			(message, "': ");
		CDLL_FUNCTION("libtstr", "tstr_cat", void(*)(tstr *, const char *))
			(message, TTF_GetError());
		CDLL_FUNCTION("libtstr", "tstr_base_cat", void(*)(tstr *, const char *))
			(message, "\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	if(!r_fonts)
	{
		r_fonts = r_currentFont = font;
	}
	else
	{
		r_font_t *i = r_fonts;

		while(i->next) i = i->next;

		i->next = font;
	}

	return 0;
}

int r_selectFont(lua_State *L)
{
	r_font_t *i;
	const char *name;
	tstr *message;

	CHECKINIT(init, L);

	name = luaL_checkstring(L, 1);

	for(i = r_fonts; i; i = i->next)
	{
		if(strcmp(i->name, name) == 0)
		{
			r_currentFont = i;

			return 0;
		}
	}

	message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
		();
	CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
		(message, "r_selectFont: couldn't find font with name '");
	if(name)
	{
		CDLL_FUNCTION("libtstr", "tstr_cat", void(*)(tstr *, const char *))
			(message, name);
	}
	CDLL_FUNCTION("libtstr", "tstr_base_cat", void(*)(tstr *, const char *))
		(message, "'\n");
	lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
						(message));
	CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
		(message);
	lua_error(L);

	return 0;
}

int r_fontName(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKCURRENTFONT(L);

	lua_pushstring(L, r_currentFont->name);

	return 1;
}

int r_fontSize(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKCURRENTFONT(L);

	lua_pushinteger(L, r_currentFont->size);

	return 1;
}

int r_fontFilename(lua_State *L)
{
	CHECKINIT(init, L);

	CHECKCURRENTFONT(L);

	lua_pushstring(L, r_currentFont->filename);

	return 1;
}

#ifdef __cplusplus
static inline int r_private_nextPowerOfTwo(int x)
#else
static int r_private_nextPowerOfTwo(int x)
#endif
{
	int r = 1;

	while(r < x)
		r <<= 1;

	return r;
}

int r_drawString(lua_State *L)
{
	vec2_t *v;
	const vec2_t *v2;
	const char *draw;
	SDL_Color c = {255, 255, 255, 255};
	SDL_Surface *s, *screen;
	SDL_Rect p;
	int i;
	r_fontCache_t *fc;
	int oldestTime = 0;
	double scalex, scaley;
	GLfloat fill[4];
	int priority = 0;

	CHECKINIT(init, L);

	CHECKCURRENTFONT(L);

	screen = SDL_GetVideoSurface();

	draw = luaL_checkstring(L, 1);
	v2 = CHECKVEC(L, 2);

	if(!*draw)
	{
		/* nothing to draw */
		v = (vec2_t *) lua_newuserdata(L, sizeof(vec2_t));

		luaL_getmetatable(L, MATH_METATABLE);
		lua_setmetatable(L, -2);

		v->x = v2->x;
		v->y = v2->y;
		v->R = v2->R;
		v->t = v2->t;

		return 1;
	}

	fill[0] = luaL_checknumber(L, 3);
	fill[1] = luaL_checknumber(L, 4);
	fill[2] = luaL_checknumber(L, 5);
	fill[3] = luaL_checknumber(L, 6);

	scalex = luaL_checknumber(L, 7);
	scaley = luaL_checknumber(L, 8);

	priority = lua_toboolean(L, 9);

	p.x = v2->x;
	p.y = v2->y;

#ifndef FONT_USEBLIT
	/* look for text in cache */
	for(i = 0; i < FONTCACHES; i++)
	{
		fc = &r_fontCaches[i];

		if(fc->active)
		{
			if(glIsList(fc->list) && glIsTexture(fc->texture) && strcmp(draw, fc->string) == 0)
			{
				fc->lastUsedTime = SDL_GetTicks();
				fc->prioritized = priority;

				glPushMatrix();
					glTranslated(p.x, p.y, 0.0);
					glScalef(scalex, scaley, 1.0);
					glTexEnvfv(GL_TEXTURE_ENV, GL_TEXTURE_ENV_COLOR, fill);
					glColor4fv(fill);
					glCallList(fc->list);
				glPopMatrix();

				v = (vec2_t *) lua_newuserdata(L, sizeof(vec2_t));

				luaL_getmetatable(L, MATH_METATABLE);
				lua_setmetatable(L, -2);

				v->x = p.x + fc->w * scalex;
				v->y = p.y + fc->h * scaley;
				MATH_POLAR(*v);

				return 1;
			}
		}
	}

	/* text not in cache */
	/* look for an unused cache slot first */
	fc = NULL;

	for(i = 0; i < FONTCACHES; i++)
	{
		if(!r_fontCaches[i].active)
		{
			fc = &r_fontCaches[i];
			break;
		}
	}

	/* use the non-prioritized oldest cache (and delete old texture and list) */
	if(!fc)
	{
		for(i = 0; i < FONTCACHES; i++)
		{
			if(!r_fontCaches[i].prioritized && (!oldestTime || r_fontCaches[i].lastUsedTime < oldestTime))
			{
				fc = &r_fontCaches[i];

				oldestTime = fc->lastUsedTime;

				if(glIsList(fc->list))
					glDeleteLists(fc->list, 1);
				if(glIsTexture(fc->texture))
					glDeleteTextures(1, &fc->texture);

				memset(fc, 0, sizeof(r_fontCache_t));

				break;
			}
		}
	}

	if(!fc)
	{
		for(i = 0; i < FONTCACHES; i++)
		{
			if(!oldestTime || r_fontCaches[i].lastUsedTime < oldestTime)
			{
				fc = &r_fontCaches[i];

				oldestTime = fc->lastUsedTime;

				if(glIsList(fc->list))
					glDeleteLists(fc->list, 1);
				if(glIsTexture(fc->texture))
					glDeleteTextures(1, &fc->texture);

				memset(fc, 0, sizeof(r_fontCache_t));

				break;
			}
		}
	}

	if(fc)
	{
		SDL_Surface *intermediary, *converted;
		SDL_PixelFormat fmt;
		int w, h;

		/* generate texture and list */

		strncpy(fc->string, draw, sizeof(fc->string));

		fc->active = 1;

		fc->prioritized = priority;

		fc->list = glGenLists(1);
		glGenTextures(1, &fc->texture);

		/* update texture */
		glBindTexture(GL_TEXTURE_2D, fc->texture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		/* load texture and upper right corner */
		s = TTF_RenderText_Blended(r_currentFont->font, draw, c);
		if(!s)
		{
			tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
				();
			CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
				(message, "r_drawString: could not render text: ");
			CDLL_FUNCTION("libtstr", "tstr_cat", void(*)(tstr *, const char *))
				(message, TTF_GetError());
			CDLL_FUNCTION("libtstr", "tstr_base_cat", void(*)(tstr *, const char *))
				(message, "\n");
			lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
								(message));
			CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
				(message);
			lua_error(L);
		}

		v = (vec2_t *) lua_newuserdata(L, sizeof(vec2_t));

		luaL_getmetatable(L, MATH_METATABLE);
		lua_setmetatable(L, -2);

		v->x = p.x + s->w * scalex;
		v->y = p.y + s->h * scaley;
		MATH_POLAR(*v);

		fc->w = s->w;
		fc->h = s->h;

		memcpy(&fmt, s->format, sizeof(SDL_PixelFormat));

		fmt.BitsPerPixel = 32;
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
		fmt.Rmask = 0xFF000000;
		fmt.Gmask = 0x00FF0000;
		fmt.Bmask = 0x0000FF00;
		fmt.Amask = 0x000000FF;
#else
		fmt.Rmask = 0x000000FF;
		fmt.Gmask = 0x0000FF00;
		fmt.Bmask = 0x00FF0000;
		fmt.Amask = 0xFF000000;
#endif
		fmt.colorkey = SDL_MapRGB(s->format, 237, 77, 207);
		fmt.alpha = 255;

		if(POWER_OF_TWO)
		{
			w = r_private_nextPowerOfTwo(s->w);
			h = r_private_nextPowerOfTwo(s->h);
		}
		else
		{
			w = s->w;
			h = s->h;
		}

		SDL_SetAlpha(s, 0, 0);

		intermediary = SDL_CreateRGBSurface(SDL_SRCALPHA, w, h, fmt.BitsPerPixel, fmt.Rmask, fmt.Gmask, fmt.Bmask, fmt.Amask);
		SDL_BlitSurface(s, NULL, intermediary, NULL);

		converted = SDL_ConvertSurface(intermediary, &fmt, SDL_SRCALPHA);

		if(SDL_MUSTLOCK(converted))
		{
			SDL_LockSurface(converted);
		}

		if(!converted->pixels)
		{
			lua_pushstring(L, "r_drawString: could not create texture\n");
			lua_error(L);
		}

		if(POWER_OF_TWO)
		{
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
			glTexSubImage2D(GL_TEXTURE_2D, 0, 0, h - converted->h, converted->w, converted->h, GL_RGBA, GL_UNSIGNED_BYTE, converted->pixels);
		}
		else
		{
			w = s->w;
			h = s->h;
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, converted->w, converted->w, 0, GL_RGBA, GL_UNSIGNED_BYTE, converted->pixels);
		}

		if(SDL_MUSTLOCK(converted))
		{
			SDL_UnlockSurface(converted);
		}

		SDL_FreeSurface(s);
		SDL_FreeSurface(converted);

		/* compile list */
		glPushMatrix();
			glTranslated(p.x, p.y, 0.0);
			glScalef(scalex, scaley, 1.0);
			glTexEnvfv(GL_TEXTURE_ENV, GL_TEXTURE_ENV_COLOR, fill);
			glColor4fv(fill);
			glNewList(fc->list, GL_COMPILE);  /* execute it so that text won't only be rendered after being placed in cache */
				glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
				glBindTexture(GL_TEXTURE_2D, fc->texture);
				glBegin(GL_QUADS);
					/* x texcoords are inverted */
					glTexCoord2d(0, 0); glVertex2d(0.0, h);
					glTexCoord2d(0, 1); glVertex2d(0.0, 0.0);
					glTexCoord2d(1, 1); glVertex2d(w, 0.0);
					glTexCoord2d(1, 0); glVertex2d(w, h);
				glEnd();
			glEndList();
		glPopMatrix();
	}
#else
	s = TTF_RenderText_Blended(r_currentFont->font, draw, c);
	if(!s)
	{
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "r_drawString: could not render text: ");
		CDLL_FUNCTION("libtstr", "tstr_cat", void(*)(tstr *, const char *))
			(message, TTF_GetError());
		CDLL_FUNCTION("libtstr", "tstr_base_cat", void(*)(tstr *, const char *))
			(message, "\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	v = (vec2_t *) lua_newuserdata(L, sizeof(vec2_t));

	luaL_getmetatable(L, MATH_METATABLE);
	lua_setmetatable(L, -2);

	v->x = p.x + s->w * scalex;
	v->y = p.y + s->h * scaley;
	MATH_POLAR(*v);

	SDL_BlitSurface(screen, NULL, s, &p); 
	SDL_FreeSurface(s);
#endif

	return 1;
}

int r_freeFont(lua_State *L)
{
	r_font_t *i, *last = NULL;
	const char *name;
	int j;
	tstr *message;

	CHECKINIT(init, L);

	name = luaL_checkstring(L, 1);

	for(i = r_fonts; i; i = i->next)
	{
		if(strcmp(i->name, name) == 0)
		{
			if(last)
				last->next = i->next;
			else
				r_fonts = i->next;

			TTF_CloseFont(i->font);
#ifndef FONT_USEBLIT
			for(j = 0; j < FONTCACHES; j++)
			{
				r_fontCache_t *c = &r_fontCaches[j];

				if(c->active)
				{
					if(glIsList(c->list))
						glDeleteLists(c->list, 1);
					if(glIsTexture(c->texture))
						glDeleteLists(c->texture, 1);
				}
			}

			memset(r_fontCaches, 0, sizeof(r_fontCaches));
#endif
			free(i);

			return 0;
		}

		last = i;
	}

	message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
		();
	CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
		(message, "r_freeFont: couldn't find font with name '");
	if(name)
	{
		CDLL_FUNCTION("libtstr", "tstr_cat", void(*)(tstr *, const char *))
			(message, name);
	}
	CDLL_FUNCTION("libtstr", "tstr_base_cat", void(*)(tstr *, const char *))
		(message, "'\n");
	lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
						(message));
	CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
		(message);
	lua_error(L);

	return 0;
}

void r_quitFont(void)
{
	TTF_Quit();
}

int r_loadImage2D(lua_State *L)
{
	const char *filename;
	SDL_Surface *img, *converted;
	SDL_PixelFormat fmt;

	CHECKINIT(init, L);

	filename = luaL_checkstring(L, 1);

	img = IMG_Load(filename);
	if(!img)
	{
		filename = luaL_checkstring(L, 2);

		img = IMG_Load(filename);
		if(!img)
		{
			tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
				();
			CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
				(message, "r_loadImage2D: could not load texture `");
			CDLL_FUNCTION("libtstr", "tstr_cat", void(*)(tstr *, const char *))
				(message, luaL_checkstring(L, 1));
			CDLL_FUNCTION("libtstr", "tstr_base_cat", void(*)(tstr *, const char *))
				(message, "' or default texture: '");
			CDLL_FUNCTION("libtstr", "tstr_cat", void(*)(tstr *, const char *))
				(message, filename);
			CDLL_FUNCTION("libtstr", "tstr_base_cat", void(*)(tstr *, const char *))
				(message, "'\n");
			lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
								(message));
			CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
				(message);
			lua_error(L);
		}
	}

	memcpy(&fmt, img->format, sizeof(SDL_PixelFormat));

	fmt.BitsPerPixel = 32;
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	fmt.Rmask = 0xFF000000;
	fmt.Gmask = 0x00FF0000;
	fmt.Bmask = 0x0000FF00;
	fmt.Amask = 0x000000FF;
#else
	fmt.Rmask = 0x000000FF;
	fmt.Gmask = 0x0000FF00;
	fmt.Bmask = 0x00FF0000;
	fmt.Amask = 0xFF000000;
#endif
	fmt.colorkey = SDL_MapRGB(img->format, 237, 77, 207);
	fmt.alpha = 255;

	converted = SDL_ConvertSurface(img, &fmt, SDL_SWSURFACE | SDL_SRCALPHA);

	if(SDL_MUSTLOCK(converted))
	{
		SDL_LockSurface(converted);
	}

	if(!converted->pixels)
	{
		lua_pushstring(L, "r_loadImage2D: could not create texture\n");
		lua_error(L);
	}

	if(POWER_OF_TWO)
	{
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, r_private_nextPowerOfTwo(converted->w), r_private_nextPowerOfTwo(converted->w), 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
		glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, converted->w, converted->h, GL_RGBA, GL_UNSIGNED_BYTE, converted->pixels);
	}
	else
	{
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, converted->w, converted->w, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	}

	if(SDL_MUSTLOCK(converted))
	{
		SDL_UnlockSurface(converted);
	}

	SDL_FreeSurface(img);
	SDL_FreeSurface(converted);

	return 0;
}
