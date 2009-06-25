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

#include "common.h"
#include "m_tankbobs.h"
#include "tstr.h"
#include "crossdll.h"

#define FREQUENCY 96000
#define FORMAT MIX_DEFAULT_FORMAT
#define CHANNELS 2
#define ALLOCATED_CHANNELS 12
#define CHUNKSIZE 3 * 1024
#define CACHEDSOUNDS 64
#define FADE_MS 1000

typedef struct sound_s sound_t;
struct sound_s
{
	int active;
	int lastUsedTime;

	char filename[FILENAME_MAX];
	Mix_Chunk *chunk;
} sounds[CACHEDSOUNDS];

static char musicFilename[FILENAME_MAX] = {""};
static Mix_Music *music = NULL;
static int audioInitialized = FALSE;

void a_initNL(lua_State *L)
{
}

int a_init(lua_State *L)
{
	CHECKINIT(init, L);

	if(audioInitialized)
		return 0;

	memset(&sounds, 0, sizeof(sounds));

	if(Mix_OpenAudio(FREQUENCY, FORMAT, CHANNELS, CHUNKSIZE) < 0)
	{
		/*
		tstr *message = CDLL_FUNCTION("libtstr", "tstr_new", tstr *(*)(void))
			();
		CDLL_FUNCTION("libtstr", "tstr_base_set", void(*)(tstr *, const char *))
			(message, "Error initializing audio: ");
		CDLL_FUNCTION("libtstr", "tstr_cat", void(*)(tstr *, const char *))
			(message, Mix_GetError());
		CDLL_FUNCTION("libtstr", "tstr_base_cat", void(*)(tstr *, const char *))
			(message, "\n");
		lua_pushstring(L, CDLL_FUNCTION("libtstr", "tstr_cstr", const char *(*)(tstr *))
							(message));
		CDLL_FUNCTION("libtstr", "tstr_free", void(*)(tstr *))
			(message);
		lua_error(L);
		*/

		/* continue without audio */

		audioInitialized = FALSE;

		fprintf(stderr, "Warning: couldn't initialize audio: %s\n", Mix_GetError());

		return 0;
	}

	Mix_AllocateChannels(ALLOCATED_CHANNELS);

	audioInitialized = TRUE;

	return 0;
}

int a_quit(lua_State *L)
{
	sound_t *i;

	CHECKINIT(init, L);

	if(!audioInitialized)
		return 0;

	if(music)
		Mix_FreeMusic(music);
	music = NULL;
	musicFilename[0] = 0;

	for(i = &sounds[0]; i - sounds < CACHEDSOUNDS; i++)
	{
		if(i->active && i->chunk)
		{
			Mix_FreeChunk(i->chunk);
			i->chunk = NULL;

			i->active = FALSE;
		}
	}

	Mix_CloseAudio();

	return 0;
}

int a_initSound(lua_State *L)
{
	const char *filename = NULL;

	CHECKINIT(init, L);

	if(!audioInitialized)
		return 0;

	if(lua_isstring(L, 1))
	{
		int oldestTime;
		sound_t *i;
		sound_t *oldestSound = NULL;

		filename = lua_tostring(L, 1);

		for(i = &sounds[0]; i - sounds < CACHEDSOUNDS; i++)
		{
			if(i->active && !strcmp(filename, i->filename))
			{
				/* re-initialize the chunk */
				if(i->chunk)
					Mix_FreeChunk(i->chunk);

				i->chunk = Mix_LoadWAV(filename);

				i->lastUsedTime = SDL_GetTicks();
				i->active = TRUE;

				return 0;
			}
		}

		/* find an unused chunk */
		for(i = &sounds[0]; i - sounds < CACHEDSOUNDS; i++)
		{
			if(!i->active)
			{
				i->chunk = Mix_LoadWAV(filename);

				strncpy(i->filename, filename, sizeof(i->filename));
				i->lastUsedTime = SDL_GetTicks();
				i->active = TRUE;

				return 0;
			}
		}

		/* use the oldest chunk */
		oldestTime = SDL_GetTicks();

		for(i = &sounds[0]; i - sounds < CACHEDSOUNDS; i++)
		{
			if(i->lastUsedTime < oldestTime)
			{
				oldestTime = i->lastUsedTime;
				oldestSound = i;
			}
		}

		if(oldestSound)
		{
			if(oldestSound->active && oldestSound->chunk)
				Mix_FreeChunk(oldestSound->chunk);

			strncpy(oldestSound->filename, filename, sizeof(oldestSound->filename));
			oldestSound->lastUsedTime = SDL_GetTicks();
			oldestSound->active = TRUE;
		}
		else
		{
			/* still haven't found a slot yet (time wrapped, maybe?) */
			/* so use the first one */
			if(sounds[0].active && sounds[0].chunk)
				Mix_FreeChunk(sounds[0].chunk);

			strncpy(sounds[0].filename, filename, sizeof(sounds[0].filename));
			sounds[0].lastUsedTime = oldestTime;  /* oldestTime is still set to SDL_GetTicks() if there are no older sounds */
			sounds[0].active = TRUE;
		}
	}

	return 0;
}

int a_freeSound(lua_State *L)
{
	const char *filename = NULL;

	CHECKINIT(init, L);

	if(!audioInitialized)
		return 0;

	if(lua_isstring(L, 1))
	{
		sound_t *i;

		filename = lua_tostring(L, 1);

		for(i = &sounds[0]; i - sounds < CACHEDSOUNDS; i++)
		{
			if(i->active && !strcmp(filename, i->filename))
			{
				/* free the chunk */
				if(i->chunk)
					Mix_FreeChunk(i->chunk);
				i->chunk = NULL;

				i->active = FALSE;

				return 0;
			}
		}

		/* the sound doesn't exist in the cache */
	}

	return 0;
}

int a_startMusic(lua_State *L)
{
	const char *filename = NULL;

	CHECKINIT(init, L);

	if(!audioInitialized)
		return 0;

	/* If filename isn't given, always continue the music.  If the music has already started playing, continue the music. */
	if(lua_isstring(L, 1))
	{
		filename = lua_tostring(L, 1);
	}
	else
	{
		if(Mix_PlayingMusic() && Mix_PausedMusic())
			Mix_ResumeMusic();

		return 0;
	}

	if(!strcmp(musicFilename, filename))
	{
		if(!music)
			music = Mix_LoadMUS(filename);

		else if(Mix_PausedMusic())
		{
			Mix_ResumeMusic();
		}
		else if(!Mix_PlayingMusic())
		{
			Mix_FadeInMusic(music, -1, FADE_MS);
		}

		return 0;
	}

	if(music)
		Mix_FreeMusic(music);

	strncpy(musicFilename, filename, sizeof(musicFilename));
	music = Mix_LoadMUS(filename);
	Mix_FadeInMusic(music, -1, FADE_MS);

	return 0;
}

int a_pauseMusic(lua_State *L)
{
	CHECKINIT(init, L);

	if(!audioInitialized)
		return 0;

	if(Mix_PlayingMusic() && Mix_PausedMusic())
		Mix_PauseMusic();

	return 0;
}

int a_stopMusic(lua_State *L)
{
	CHECKINIT(init, L);

	if(!audioInitialized)
		return 0;

	Mix_FadeOutMusic(FADE_MS);

	return 0;
}

int a_playSound(lua_State *L)
{
	/* similar to a_initSound */
	const char *filename = NULL;

	CHECKINIT(init, L);

	if(!audioInitialized)
		return 0;

	if(lua_isstring(L, 1))
	{
		int oldestTime;
		sound_t *i;
		sound_t *oldestSound = NULL;

		filename = lua_tostring(L, 1);

		for(i = &sounds[0]; i - sounds < CACHEDSOUNDS; i++)
		{
			if(i->active && !strcmp(filename, i->filename) && i->chunk)
			{
				i->lastUsedTime = SDL_GetTicks();
				i->active = TRUE;

				Mix_PlayChannel(-1, i->chunk, 0);

				return 0;
			}
		}

		/* find an unused chunk */
		for(i = &sounds[0]; i - sounds < CACHEDSOUNDS; i++)
		{
			if(!i->active)
			{
				i->chunk = Mix_LoadWAV(filename);

				strncpy(i->filename, filename, sizeof(i->filename));
				i->lastUsedTime = SDL_GetTicks();
				i->active = TRUE;

				Mix_PlayChannel(-1, i->chunk, 0);

				return 0;
			}
		}

		/* use the oldest chunk */
		oldestTime = SDL_GetTicks();

		for(i = &sounds[0]; i - sounds < CACHEDSOUNDS; i++)
		{
			if(i->lastUsedTime < oldestTime)
			{
				oldestTime = i->lastUsedTime;
				oldestSound = i;
			}
		}

		if(oldestSound)
		{
			if(oldestSound->active && oldestSound->chunk)
				Mix_FreeChunk(oldestSound->chunk);

			strncpy(oldestSound->filename, filename, sizeof(oldestSound->filename));
			oldestSound->lastUsedTime = SDL_GetTicks();
			oldestSound->active = TRUE;

			Mix_PlayChannel(-1, oldestSound->chunk, 0);
		}
		else
		{
			/* still haven't found a slot yet (time wrapped, maybe?) */
			/* so use the first one */
			if(sounds[0].active && sounds[0].chunk)
				Mix_FreeChunk(sounds[0].chunk);

			strncpy(sounds[0].filename, filename, sizeof(sounds[0].filename));
			sounds[0].lastUsedTime = oldestTime;  /* oldestTime is still set to SDL_GetTicks() if there are no older sounds */
			sounds[0].active = TRUE;

			Mix_PlayChannel(-1, sounds[0].chunk, 0);
		}
	}

	return 0;
}

int a_setMusicVolume(lua_State *L)
{
	int volume; 

	CHECKINIT(init, L);

	if(!audioInitialized)
		return 0;

	volume = luaL_checknumber(L, 1) * MIX_MAX_VOLUME;
	if(volume < 0)
		volume = 0;

	Mix_VolumeMusic(volume);

	return 0;
}

int a_setVolume(lua_State *L)
{
	int volume; 

	CHECKINIT(init, L);

	if(!audioInitialized)
		return 0;

	volume = luaL_checknumber(L, 1) * MIX_MAX_VOLUME;
	if(volume < 0)
		volume = 0;

	Mix_Volume(-1, volume);

	return 0;
}

int a_setVolumeChunk(lua_State *L)
{
	/* similar to a_initSound */
	int volume; 
	const char *filename = NULL;

	CHECKINIT(init, L);

	if(!audioInitialized)
		return 0;

	volume = luaL_checknumber(L, -1) * MIX_MAX_VOLUME;
	if(volume < 0)
		volume = 0;

	if(lua_isstring(L, 1))
	{
		int oldestTime;
		sound_t *i;
		sound_t *oldestSound = NULL;

		filename = lua_tostring(L, 1);

		for(i = &sounds[0]; i - sounds < CACHEDSOUNDS; i++)
		{
			if(i->active && !strcmp(filename, i->filename) && i->chunk)
			{
				i->lastUsedTime = SDL_GetTicks();
				i->active = TRUE;

				Mix_VolumeChunk(sounds[0].chunk, volume);

				return 0;
			}
		}

		/* find an unused chunk */
		for(i = &sounds[0]; i - sounds < CACHEDSOUNDS; i++)
		{
			if(!i->active)
			{
				i->chunk = Mix_LoadWAV(filename);

				strncpy(i->filename, filename, sizeof(i->filename));
				i->lastUsedTime = SDL_GetTicks();
				i->active = TRUE;

				Mix_VolumeChunk(sounds[0].chunk, volume);

				return 0;
			}
		}

		/* use the oldest chunk */
		oldestTime = SDL_GetTicks();

		for(i = &sounds[0]; i - sounds < CACHEDSOUNDS; i++)
		{
			if(i->lastUsedTime < oldestTime)
			{
				oldestTime = i->lastUsedTime;
				oldestSound = i;
			}
		}

		if(oldestSound)
		{
			if(oldestSound->active && oldestSound->chunk)
				Mix_FreeChunk(oldestSound->chunk);

			strncpy(oldestSound->filename, filename, sizeof(oldestSound->filename));
			oldestSound->lastUsedTime = SDL_GetTicks();
			oldestSound->active = TRUE;

			Mix_VolumeChunk(sounds[0].chunk, volume);
		}
		else
		{
			/* still haven't found a slot yet (time wrapped, maybe?) */
			/* so use the first one */
			if(sounds[0].active && sounds[0].chunk)
				Mix_FreeChunk(sounds[0].chunk);

			strncpy(sounds[0].filename, filename, sizeof(sounds[0].filename));
			sounds[0].lastUsedTime = oldestTime;  /* oldestTime is still set to SDL_GetTicks() if there are no older sounds */
			sounds[0].active = TRUE;

			Mix_VolumeChunk(sounds[0].chunk, volume);
		}
	}

	return 0;
}
