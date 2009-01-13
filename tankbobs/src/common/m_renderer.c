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
#include <SDL/SDL_mixer.h>
#include <SDL/SDL_endian.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <luaconf.h>
#include <math.h>
#include <zlib.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_GLYPH_H

#include "common.h"
#include "m_tankbobs.h"
#include "crossdll.h"
#include "tstr.h"

#define MIN_VID_MEM    256
#define CHECK_INTERVAL 3000
#define NUMCHARS       255
#define TTD            10.0  /* really nice font */

extern Uint8 init;

typedef struct
{
	GLuint chars;
	GLuint *textures;
	FT_Face f;
} freefont;

static FT_Library ft;

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

	if(FT_Init_FreeType(&ft))
	{
		tstr *message = CDLL_FUNCTION("tstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("tstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "Error initializing FreeType\n");
		lua_pushstring(L, CDLL_FUNCTION("tstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("tstr", "tstr_free", void(*)(tstr *))
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

	if(!SDL_SetVideoMode(w, h, 0, SDL_OPENGL | ((f) ? (SDL_FULLSCREEN) : (0))))
	{
		fprintf(stdout, "Warning: could not init video mode.  Trying again with lower antialias multisampling\n");
		SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 8);
		if(!SDL_SetVideoMode(w, h, 0, SDL_OPENGL | ((f) ? (SDL_FULLSCREEN) : (0))))
		{
#ifdef TDEBUG
			fprintf(stdout, "Warning: could not init video mode.  Trying again with lower antialias multisampling\n");
#endif
			SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);
			if(!SDL_SetVideoMode(w, h, 0, SDL_OPENGL | ((f) ? (SDL_FULLSCREEN) : (0))))
			{
#ifdef TDEBUG
				fprintf(stdout, "Warning: could not init video mode.  Trying again again with no antialias multisampling\n");
#endif
				SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 0);
				SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 0);
				if(!SDL_SetVideoMode(w, h, 0, SDL_OPENGL | ((f) ? (SDL_FULLSCREEN) : (0))))
				{
#ifdef TDEBUG
					fprintf(stdout, "Warning: could not init video mode.  Trying again again again with no doublebuffer\n");
#endif
					SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 0);
					if(!SDL_SetVideoMode(w, h, 0, SDL_OPENGL | ((f) ? (SDL_FULLSCREEN) : (0))))
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
	Uint32 i, j, k;
	freefont *font = NULL;
	const char *filename = luaL_checkstring(L, 1);
	FT_Glyph g;
	FT_BitmapGlyph bg;
	GLint bufs, samples;
	/* GLfloat def[] = {1.0f, 1.0f, 1.0f, 0.0f}; */
	GLubyte *data;

	CHECKINIT(init, L);

	glGetIntegerv(GL_SAMPLE_BUFFERS, &bufs);
	glGetIntegerv(GL_SAMPLES, &samples);
	if(bufs > 0 && samples > 1)
	{
		glEnable(GL_MULTISAMPLE);
	}
	/* glTexEnvfv(GL_TEXTURE_ENV, GL_TEXTURE_ENV_COLOR, def); */
	/* glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_BLEND); */  /* This, above and def all make a really nice look,
		but it's awfully hard to tell the colors apart for the typical player. */
	/* glBlendFuncSeparate(GL_ONE, GL_ONE_MINUS_SRC_ALPHA, GL_SRC_ALPHA, GL_DST_ALPHA); */
	/* glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_SRC_ALPHA, GL_DST_ALPHA); */
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);  /* >:/ */
	glEnable(GL_BLEND);
	glEnable(GL_TEXTURE_2D);

	data = malloc(2 * 64 * 64);

	font = malloc(sizeof(freefont));
	font->textures = malloc(sizeof(GLuint) * NUMCHARS);

	if(FT_New_Face(ft, filename, 0, &font->f))
	{
		tstr *message = CDLL_FUNCTION("tstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("tstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "missing or corrupt font file `");
		CDLL_FUNCTION("tstr", "tstr_cat", void(*)(tstr *, const char *))
			(message, filename);
		CDLL_FUNCTION("tstr", "tstr_base_cat", void(*)(tstr *, const char *))
			(message, "'\n");
		lua_pushstring(L, CDLL_FUNCTION("tstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("tstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	if(FT_Set_Char_Size(font->f, 16 << 6, 16 << 6, 0, 0))
	{
		tstr *message = CDLL_FUNCTION("tstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("tstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "cannot set font size\n");
		lua_pushstring(L, CDLL_FUNCTION("tstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("tstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}

	glGenTextures(NUMCHARS, font->textures);
	font->chars = glGenLists(NUMCHARS);
	if(!font->chars)
	{
		tstr *message = CDLL_FUNCTION("tstr", "tstr_new", tstr *(*)(void))();
		CDLL_FUNCTION("tstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "could not enough memory font\n");
		lua_pushstring(L, CDLL_FUNCTION("tstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("tstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
	}
	for(i = 0; i < NUMCHARS; i++)
	{
		glBindTexture(GL_TEXTURE_2D, font->textures[i]);
		if(FT_Load_Glyph(font->f, FT_Get_Char_Index(font->f, i), FT_LOAD_DEFAULT))
		{
			tstr *message = CDLL_FUNCTION("tstr", "tstr_new", tstr *(*)(void))
				();
			CDLL_FUNCTION("tstr", "tstr_base_set", void(*)(tstr *, const char *))
				(message, "cannot set font size\n");
			lua_pushstring(L, CDLL_FUNCTION("tstr", "tstr_cstr", const char *(*)(tstr *))
								(message));
			CDLL_FUNCTION("tstr", "tstr_free", void(*)(tstr *))
				(message);
			lua_error(L);
		}
		if(FT_Get_Glyph(font->f->glyph, &g))
		{
			tstr *message = CDLL_FUNCTION("tstr", "tstr_new", tstr *(*)(void))
				();
			CDLL_FUNCTION("tstr", "tstr_base_set", void(*)(tstr *, const char *))
				(message, "cannot set font glyph\n");
			lua_pushstring(L, CDLL_FUNCTION("tstr", "tstr_cstr", const char *(*)(tstr *))
								(message));
			CDLL_FUNCTION("tstr", "tstr_free", void(*)(tstr *))
				(message);
			lua_error(L);
		}
		FT_Glyph_To_Bitmap(&g, FT_RENDER_MODE_NORMAL, 0, 1);
		bg = (FT_BitmapGlyph)g;
		for(j = 0; j < 64; j++)
		{
			for(k = 0; k < 64; k++)
			{
				data[2 * (k + j * 64)] = data[2 * (k + j * 64) + 1] = ((k >= bg->bitmap.width || j >= bg->bitmap.rows) ? (0) : (bg->bitmap.buffer[k + bg->bitmap.width * j]));
			}
		}
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 64, 64, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, data);
		glNewList(font->chars + i, GL_COMPILE);
		{
			glPushAttrib(GL_ENABLE_BIT | GL_TEXTURE_BIT);
			{
				glBindTexture(GL_TEXTURE_2D, font->textures[i]);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

				glBegin(GL_QUADS);
				{
					glTexCoord2d(0.0, 0.0);
						glVertex2d(-0.5 * TTD,  0.5 * TTD);
					glTexCoord2d(0.0, (double)bg->bitmap.rows / 64.0);
						glVertex2d(-0.5 * TTD, -0.5 * TTD);
					glTexCoord2d((double)bg->bitmap.width / 64.0, (double)bg->bitmap.rows / 64.0);
						glVertex2d( 0.5 * TTD, -0.5 * TTD);
					glTexCoord2d((double)bg->bitmap.width / 64.0, 0.0);
						glVertex2d( 0.5 * TTD,  0.5 * TTD);
				}
				glEnd();
			}
			glPopAttrib();
		}
		glEndList();
	}

	free(data);

	lua_pushlightuserdata(L, font);
	return 1;
}

int r_freeFont(lua_State *L)
{
	freefont *font = lua_touserdata(L, -1);

	CHECKINIT(init, L);

	FT_Done_Face(font->f);
	glDeleteLists(font->chars, NUMCHARS);
	glDeleteTextures(NUMCHARS, font->textures);
	free(font->textures);
	free(font);

	return 0;
}

int r_drawCharacter(lua_State *L)
{
	double x = luaL_checknumber(L, 1), y = luaL_checknumber(L, 2), w = luaL_checknumber(L, 3), h = luaL_checknumber(L, 4);
	freefont *font = lua_touserdata(L, 5);
	char c = ((lua_type(L, 6) == LUA_TNUMBER) ? (luaL_checkinteger(L, 6)) : (*luaL_checkstring(L, 6)));

	CHECKINIT(init, L);

	glPushMatrix();
	{
		glTranslated(x, y, 0);
		glScaled(w / TTD, h / TTD, 1.0);
		glCallList(font->chars + c);
	}
	glPopMatrix();

	return 0;
}

void r_quitFreeType(void)
{
	FT_Done_FreeType(ft);
}
