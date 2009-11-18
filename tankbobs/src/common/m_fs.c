/*
Copyright (C) 2008-2009 Byron James Johnson

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

/*
 * m_fs.c
 *
 * Values are stored as little-endian.
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
#include <assert.h>

#include "physfs.h"

#include "common.h"
#include "m_tankbobs.h"
#include "tstr.h"
#include "crossdll.h"

#if defined(__FILE) && defined(__LINE) && defined(TDEBUG)
#define CHECKFSINIT(i, L)                                                          \
do                                                                                 \
{                                                                                  \
	if(!PHYSFS_isInit())                                                           \
	{                                                                              \
		char buf[1024];                                                            \
		sprintf(buf, "filesystem used before initialization on line %d in %s.",    \
			__LINE, __FILE);                                                       \
		lua_pushstring(L, buf);                                                    \
		lua_error(L);                                                              \
	}                                                                              \
} while(0)
#elif defined(__FILE__) && defined(__LINE__) && defined(TDEBUG)
#define CHECKFSINIT(i, L)                                                          \
do                                                                                 \
{                                                                                  \
	if(!PHYSFS_isInit())                                                           \
	{                                                                              \
		char buf[1024];                                                            \
		sprintf(buf, "filesystem used before initialization on line %d in %s.",    \
			__LINE__, __FILE__);                                                   \
		lua_pushstring(L, buf);                                                    \
		lua_error(L);                                                              \
	}                                                                              \
} while(0)
#else
#define CHECKFSINIT(i, L)                                                          \
do                                                                                 \
{                                                                                  \
	if(!PHYSFS_isInit())                                                           \
	{                                                                              \
		lua_pushstring(L, "filesystem used before initialization.");               \
		lua_error(L);                                                              \
	}                                                                              \
} while(0)
#endif

const char *argv0 = NULL;

void fs_initNL(lua_State *L)
{
}

void fs_errorNL(lua_State *L, void *f_, const char *filename)
{
	int num = 0;
	const char *e;
	PHYSFS_File *f = (PHYSFS_File *) f_;

	++num; lua_pushstring(L, "file error");
	if((e = PHYSFS_getLastError()))
	{
		++num; lua_pushstring(L, ": \"");
		++num; lua_pushstring(L, e);
		++num; lua_pushstring(L, "\"");
	}
	if(filename)
	{
		++num; lua_pushstring(L, " (");
		++num; lua_pushstring(L, filename);
		++num; lua_pushstring(L, ")");
	}
	if(f)
	{
	}

	if(num <= 0)
	{
		++num; lua_pushstring(L, "");
	}
	lua_concat(L, num);
	lua_error(L);
}

/* Here we rewrite some lua loader code */

typedef struct fs_LoadF
{
	int extraline;
	PHYSFS_File *f;
	char buff[LUAL_BUFFERSIZE];
} fs_LoadF;

static const char *fs_getF(lua_State *L, void *ud, size_t *size)
{
	fs_LoadF *lf = (fs_LoadF *)ud;
	(void) L;
	if(lf->extraline)
	{
		lf->extraline = 0;
		*size = 1;
		return "\n";
	}
	if (PHYSFS_eof(lf->f))
	{
		return NULL;
	}
	*size = PHYSFS_read(lf->f, lf->buff, 1, sizeof(lf->buff));
	return (*size > 0) ? lf->buff : NULL;
}

/* static LUALIB_API int fs_luaL_loadfile(lua_State *L, const char *filename) */
static int fs_luaL_loadfile(lua_State *L, const char *filename)
{
	fs_LoadF lf;
	int status, status_;
	/*int readstatus;*/
	int c = 0;
	int fnameindex = lua_gettop(L) + 1;  /* index of filename on the stack */

	if(!init || !PHYSFS_isInit())
	{
		lua_pushnil(L);

		return 1;
	}

	lf.extraline = 0;
	if(!filename)
	{
		lua_pushstring(L, "fs_loadfile: filename must exist");
		lua_error(L);

		return 0;
	}
	/*
	if(filename == NULL)
	{
		lua_pushliteral(L, "=stdin");
		lf.f = stdin;
	}
	else
	{
	*/
		lua_pushfstring(L, "@%s", filename);
		lf.f = PHYSFS_openRead(filename);
		if(!lf.f)
		{
			fs_errorNL(L, lf.f, filename);

			return 0;
		}
		/*if (lf.f == NULL) return errfile(L, "open", fnameindex);*/
	/*
	}
	*/
	/*c = getc(lf.f);*/
	status = PHYSFS_read(lf.f, &c, 1, 1);
	if(status < 1 && !PHYSFS_eof(lf.f))
	{
		fs_errorNL(L, lf.f, filename);

		return 0;
	}
	else
	{
		if(c == '#')
		{  /* Unix exec. file? */
			lf.extraline = 1;
			while ((status = PHYSFS_read(lf.f, &c, 1, 1)) >= 1 && c != '\n') ;  /* skip first line */
			if(status < 1 && !PHYSFS_eof(lf.f))
			{
				fs_errorNL(L, lf.f, filename);

				return 0;
			}
			else if(status >= 1)
			{
				if (c == '\n')
					status = PHYSFS_read(lf.f, &c, 1, 1);
				if(status < 1 && !PHYSFS_eof(lf.f))
				{
					fs_errorNL(L, lf.f, filename);

					return 0;
				}
			}
		}
		if(status >= 1 && c == LUA_SIGNATURE[0] && filename)  /* binary file? */
		{
			/*
			PHYSFS_close(lf.f);
			lf.f = PHYSFS_openRead(filename);
			lf.f = freopen(filename, "rb", lf.f);  /8 reopen in binary mode 8/
			if(!lf.f)
			{
				fs_errorNL(L, lf.f, filename);

				return 0;
			}
			*/
			PHYSFS_seek(lf.f, 0);
			/*if (lf.f == NULL) return errfile(L, "reopen", fnameindex);*/
			/* skip eventual `#!...' */
			/*while ((c = getc(lf.f)) != EOF && c != LUA_SIGNATURE[0]) ;*/
			while ((status = PHYSFS_read(lf.f, &c, 1, 1)) >= 1 && c != LUA_SIGNATURE[0]) ;
			if(status < 1 && !PHYSFS_eof(lf.f))
			{
				fs_errorNL(L, lf.f, filename);

				return 0;
			}
			lf.extraline = 0;
		}
	}
	PHYSFS_seek(lf.f, PHYSFS_tell(lf.f) - 1);
	/*ungetc(c, lf.f);*/
	status = lua_load(L, fs_getF, &lf, lua_tostring(L, -1));
	/*readstatus = ferror(lf.f);*/
	/*fclose(lf.f);  /8 close file (even in case of errors) 8/*/
	status_ = PHYSFS_close(lf.f);  /* close file (even in case of errors) */
	if(!status_)
	{
		fs_errorNL(L, lf.f, filename);

		return 0;
	}
	/*
	if(readstatus)
	{
		lua_settop(L, fnameindex);  /8 ignore results from `lua_load' 8/
		return errfile(L, "read", fnameindex);
	}
	*/
	lua_remove(L, fnameindex);

	return status;
}

static int fs_readable(const char *filename)
{
	PHYSFS_File *file;

	if(!init || !PHYSFS_isInit())
		return 0;

	if(!PHYSFS_exists(filename))
		return 0;

	file = PHYSFS_openRead(filename);

	if(!file)
		return 0;

	PHYSFS_close(file);

	return 1;
}

static const char *pushnexttemplate(lua_State *L, const char *path)
{
	const char *l;

	while (*path == *LUA_PATHSEP)
		path++;  /* skip separators */
	if(*path == '\0')
		return NULL;  /* no more templates */
	l = strchr(path, *LUA_PATHSEP);  /* find next separator */
	if (l == NULL)
		l = path + strlen(path);
	lua_pushlstring(L, path, l - path);  /* template */

	return l;
}

static const char *fs_findfile(lua_State *L, const char *name, const char *pname)
{
	const char *path;

	name = luaL_gsub(L, name, ".", LUA_DIRSEP);
	lua_getfield(L, LUA_ENVIRONINDEX, pname);
	path = lua_tostring(L, -1);
	if(path == NULL)
		luaL_error(L, LUA_QL("package.%s") " must be a string", pname);
	lua_pushliteral(L, "");  /* error accumulator */
	while((path = pushnexttemplate(L, path)) != NULL)
	{
		const char *filename;

		filename = luaL_gsub(L, lua_tostring(L, -1), LUA_PATH_MARK, name);
		lua_remove(L, -2);  /* remove path template */
		if (fs_readable(filename))  /* does file exist and is readable? */
			return filename;  /* return that file name */
		lua_pushfstring(L, "\n\tno file " LUA_QS, filename);
		lua_remove(L, -2);  /* remove file name */
		lua_concat(L, 2);  /* add entry to possible error message */
	}

	return NULL;  /* not found */
}

#define LIBPREFIX "LOADLIB: "

static void **ll_register (lua_State *L, const char *path)
{
	void **plib;

	lua_pushfstring(L, "%s%s", LIBPREFIX, path);
	lua_gettable(L, LUA_REGISTRYINDEX);  /* check library in registry? */
	if(!lua_isnil(L, -1))  /* is there an entry? */
	{
		plib = (void **) lua_touserdata(L, -1);
	}
	else
	{  /* no entry yet; create one */
		lua_pop(L, 1);
		plib = (void **) lua_newuserdata(L, sizeof(const void *));
		*plib = NULL;
		luaL_getmetatable(L, "_LOADLIB");
		lua_setmetatable(L, -2);
		lua_pushfstring(L, "%s%s", LIBPREFIX, path);
		lua_pushvalue(L, -2);
		lua_settable(L, LUA_REGISTRYINDEX);
	}

	return plib;
}

#if defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WINDOWS__) || defined(__WINDOWS__)

/* windows.h should already be included */

#ifdef setprogdir
#undef setprogdir
#endif

static void setprogdir(lua_State *L)
{
	char buff[MAX_PATH + 1];
	char *lb;
	DWORD nsize = sizeof(buff)/sizeof(char);
	DWORD n = GetModuleFileNameA(NULL, buff, nsize);

	if (n == 0 || n == nsize || (lb = strrchr(buff, '\\')) == NULL)
	{
		luaL_error(L, "unable to get ModuleFileName");
	}
	else
	{
		*lb = '\0';
		luaL_gsub(L, lua_tostring(L, -1), LUA_EXECDIR, buff);
		lua_remove(L, -2);  /* remove original string */
	}
}

static void pusherror(lua_State *L)
{
	int error = GetLastError();
	char buffer[128];

	if(FormatMessageA(FORMAT_MESSAGE_IGNORE_INSERTS | FORMAT_MESSAGE_FROM_SYSTEM,
				NULL, error, 0, buffer, sizeof(buffer), NULL))
		lua_pushstring(L, buffer);
	else
		lua_pushfstring(L, "system error %d\n", error);
}

/*
static void ll_unloadlib(void *lib)
{
	FreeLibrary((HINSTANCE) lib);
}
*/

static void *fs_ll_load(lua_State *L, const char *path)
{
	int status;
	static char buf[BUFSIZE + MAX_PATH + 1] = {""};
	HINSTANCE lib;
	FILE *fout;
	PHYSFS_File *fin;
	char *filename = buf;

	/* Copy file to a temporary file */
	fin = PHYSFS_openRead(path);
	if(!fin)
	{
		lua_pushstring(L, PHYSFS_getLastError());
		/*fs_errorNL(L, fin, path);*/

		return NULL;
	}

	status = GetTempPath(BUFSIZE, buf);
	if(!status)
	{
		pusherror(L);

		return NULL;
	}
	status = GetTempFileName(buf, "tfsdll", 0, &buf[((strlen(buf) > 0) ? (strlen(buf) - 1) : (0))]);
	if(!status)
	{
		pusherror(L);

		return NULL;
	}
	if(!filename)
	{
		lua_pushstring(L, "could not create temporary file for loading library");

		return NULL;
	}

	fout = fopen(filename, "w");
	if(!fout)
	{
		lua_pushstring(L, "could not open temporary file for loading library");

		return NULL;
	}

	while(PHYSFS_read(fin, &c, 1, 1) >= 1 && (status = fputc(c, fout)) != EOF);
	if(status == EOF)
	{
		lua_pushstring(L, "could not write temporary file for loading library");

		return NULL;
	}

	status = PHYSFS_close(fin);
	if(!status)
	{
		lua_pushstring(L, PHYSFS_getLastError());
		/*fs_errorNL(L, fin, path);*/

		return NULL;
	}
	fclose(fout);

	/*LoadLibraryA(path);*/
	lib = LoadLibraryA(filename);
	if (lib == NULL)
		pusherror(L);
	return lib;
}

static lua_CFunction ll_sym(lua_State *L, void *lib, const char *sym)
{
	lua_CFunction f = (lua_CFunction)GetProcAddress((HINSTANCE)lib, sym);
	if (f == NULL) pusherror(L);
	return f;
}

#elif defined(__unix)

#include <dlfcn.h>
#include <stdio.h>

/*
static void ll_unloadlib(void *lib)
{
	dlclose(lib);
}
*/

static void *fs_ll_load(lua_State *L, const char *path)
{
	char c;
	int status;
	const char *filename;
	void *lib;
	FILE *fout;
	PHYSFS_File *fin;

	/* Copy file to a temporary file */
	fin = PHYSFS_openRead(path);
	if(!fin)
	{
		lua_pushstring(L, PHYSFS_getLastError());
		/*fs_errorNL(L, fin, path);*/

		return NULL;
	}

	/*filename = tempnam(NULL, "tfsdll");*/
	filename = tmpnam(NULL);
	if(!filename)
	{
		lua_pushstring(L, "could not create temporary file for loading library");

		/*free(filename);*/
		return NULL;
	}

	fout = fopen(filename, "w");
	if(!fout)
	{
		lua_pushstring(L, "could not open temporary file for loading library");

		/*free(filename);*/
		return NULL;
	}

	while(PHYSFS_read(fin, &c, 1, 1) >= 1 && (status = fputc(c, fout)) != EOF);
	if(status == EOF)
	{
		lua_pushstring(L, "could not write temporary file for loading library");

		/*free(filename);*/
		return NULL;
	}

	status = PHYSFS_close(fin);
	if(!status)
	{
		lua_pushstring(L, PHYSFS_getLastError());
		/*fs_errorNL(L, fin, path);*/

		return NULL;
	}
	fclose(fout);


	/*dlopen(path, RTLD_NOW);*/
	lib = dlopen(filename, RTLD_NOW);
	/*free(filename);*/
	if(lib == NULL)
		lua_pushstring(L, dlerror());

	return lib;
}

static lua_CFunction ll_sym(lua_State *L, void *lib, const char *sym)
{
	void *p;
	lua_CFunction f;
	p = dlsym(lib, sym);
	memcpy(&f, p, sizeof(f));
	/*lua_CFunction f = (lua_CFunction)dlsym(lib, sym);*/
	if (f == NULL)
		lua_pushstring(L, dlerror());
	return f;
}

#else

/* TODO reinvent the wheel for Mac OC X / Darwin implementation */

#endif
#define ERRLIB      1
#define ERRFUNC	    2
#define LUA_OFSEP   "_"
#define LUA_POF		"luaopen_"
#define POF	LUA_POF

static void loaderror(lua_State *L, const char *filename)
{
	luaL_error(L, "error loading module " LUA_QS " from file " LUA_QS ":\n\t%s",
			lua_tostring(L, 1), filename, lua_tostring(L, -1));
}

static int fs_ll_loadfunc(lua_State *L, const char *path, const char *sym)
{
	void **reg = ll_register(L, path);

	if (*reg == NULL)
	{
		*reg = fs_ll_load(L, path);
	}

	if (*reg == NULL)
	{
		return ERRLIB;  /* unable to load library */
	}
	else
	{
		lua_CFunction f = ll_sym(L, *reg, sym);
		if (f == NULL)
			return ERRFUNC;  /* unable to find function */
		lua_pushcfunction(L, f);

		return 0;  /* return function */
	}
}

static int fs_loader_Lua(lua_State *L)
{
	const char *filename;
	const char *name = luaL_checkstring(L, 1);

	filename = fs_findfile(L, name, "path");
	if(!filename)
		return 1;  /* library not found in this path */
printf("fs_load_Lua: reading %s", filename);
	if(fs_luaL_loadfile(L, filename) != 0)
		loaderror(L, filename);
	return 1;  /* library loaded successfully */
}

static const char *mkfuncname(lua_State *L, const char *modname)
{
	const char *funcname;
	const char *mark = strchr(modname, *LUA_IGMARK);

	if(mark)
		modname = mark + 1;

	funcname = luaL_gsub(L, modname, ".", LUA_OFSEP);
	funcname = lua_pushfstring(L, POF"%s", funcname);
	lua_remove(L, -2);  /* remove 'gsub' result */

	return funcname;
}

static int fs_loader_C(lua_State *L)
{
	const char *funcname;
	const char *name = luaL_checkstring(L, 1);
	const char *filename = fs_findfile(L, name, "cpath");

	if(filename == NULL)
		return 1;  /* library not found in this path */
	funcname = mkfuncname(L, name);
printf("fs_load_C: reading %s", filename);
	if(fs_ll_loadfunc(L, filename, funcname) != 0)
		loaderror(L, filename);

	return 1;  /* library loaded successfully */
}

static int fs_loader_Croot(lua_State *L)
{
	const char *funcname;
	const char *filename;
	const char *name = luaL_checkstring(L, 1);
	const char *p = strchr(name, '.');
	int stat;

	if(p == NULL)
		return 0;  /* is root */
	lua_pushlstring(L, name, p - name);
	filename = fs_findfile(L, lua_tostring(L, -1), "cpath");
	if(filename == NULL)
		return 1;  /* root not found */
	funcname = mkfuncname(L, name);
	if((stat = fs_ll_loadfunc(L, filename, funcname)) != 0)
	{
		if (stat != ERRFUNC)
			loaderror(L, filename);  /* real error */
		lua_pushfstring(L, "\n\tno module " LUA_QS " in file " LUA_QS,
				name, filename);

		return 1;  /* function not found */
	}

	return 1;
}

int fs_init(lua_State *L)
{
	int i;
	int status;
	const char *a = argv0;

	CHECKINIT(init, L);

	PHYSFS_permitSymbolicLinks(lua_toboolean(L, 1));

	if(!a)
	{
#if defined(__WINDOWS__) || defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WIN__)
		int num;
		LPWSTR *s;
		static char buf[BUFSIZE];

		s = CommandLineToArgvW(GetCommandline(), &num);

		if(num > 0)
		{
			int i = 0;

			while(i < sizeof(buf) - 1 && s[0][i])
				buf[i] = s[0][i];

			buf[i] = 0;

			a = buf;
		}
/*#else*/
#elif defined(__unix)
		FILE *fin;
		fin = fopen("/proc/self/cmdline", "r");

		if(fin)
		{
			char c;
			int i = 0;
			static char buf[BUFSIZE];

			while(i < sizeof(buf) - 1 && (c = fgetc(fin)) != EOF)
				buf[i] = c;

			buf[i] = 0;

			fclose(fin);

			/* our buffer now contains the command line separated by NULL bytes, so since argv0 is NULL terminated, pointing it to our buffer would make it point to argv[0] only */
			a = buf;
		}
#endif
	}

	if(!a)
	{
		/* couldn't get command line */
		lua_pushstring(L, "fs_init: couldn't get command line");
		lua_error(L);

		return 0;
	}

	status = PHYSFS_init(a);

	if(!status)
	{
		fs_errorNL(L, NULL, NULL);

		return 0;
	}

	/* add fs_loader_Lua and fs_loader_C to package.loaders after the first loader (preloader), and remove the rest of the loaders */
	lua_getglobal(L, "package");
	for(i = 2; i <= 4; ++i)
	{
		lua_pushinteger(L, 2);
		lua_pushnil(L);
		lua_settable(L, -3);
	}
	lua_pushinteger(L, 2);
	lua_pushcfunction(L, fs_loader_Lua);
	lua_settable(L, -3);
	lua_pushinteger(L, 3);
	lua_pushcfunction(L, fs_loader_C);
	lua_settable(L, -3);
	lua_pushinteger(L, 4);
	lua_pushcfunction(L, fs_loader_Croot);
	lua_settable(L, -3);
	lua_pop(L, 1);

	return 0;
}

int fs_quit(lua_State *L)
{
	int status;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	status = PHYSFS_deinit();

	if(!status)
	{
		fs_errorNL(L, NULL, NULL);

		return 0;
	}

	return 0;
}

int fs_setArgv0(lua_State *L)
{
	static char buf[BUFSIZE];

	CHECKINIT(init, L);

	strncpy(buf, luaL_checkstring(L, 1), sizeof(buf));

	lua_settop(L, 0);

	argv0 = buf;

	return 0;
}

int fs_getRawDirectorySeparator(lua_State *L)
{
	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	lua_pushstring(L, PHYSFS_getDirSeparator());

	return 1;
}

int fs_getCDDirectories(lua_State *L)
{
	const char **cds;
	const char **i;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	cds = (const char **) PHYSFS_getCdRomDirs();

	lua_newtable(L);

	for(i = cds; *i != NULL; ++i)
	{
		lua_pushinteger(L, cds - i + 1);
		lua_pushstring(L, *i);
		lua_settop(L, -3);
	}

	PHYSFS_freeList(cds);

	return 1;
}

int fs_getBaseDirectory(lua_State *L)
{
	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	lua_pushstring(L, PHYSFS_getBaseDir());

	return 1;
}

int fs_getUserDirectory(lua_State *L)
{
	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	lua_pushstring(L, PHYSFS_getUserDir());

	return 1;
}

int fs_getWriteDirectory(lua_State *L)
{
	const char *w;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	w = PHYSFS_getWriteDir();

	if(w)
		lua_pushstring(L, w);
	else
		lua_pushnil(L);

	return 1;
}

int fs_setWriteDirectory(lua_State *L)
{
	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	PHYSFS_setWriteDir(luaL_checkstring(L, 1));

	return 0;
}

int fs_getSearchPath(lua_State *L)
{
	const char **searchPath;
	const char **i;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	searchPath = (const char **) PHYSFS_getSearchPath();

	lua_newtable(L);

	for(i = searchPath; *i; ++i)
	{
		lua_pushinteger(L, searchPath - i + 1);
		lua_pushstring(L, *i);
		lua_settable(L, -3);
	}

	PHYSFS_freeList(searchPath);

	return 1;
}

int fs_mkdir(lua_State *L)
{
	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	int status = PHYSFS_mkdir(luaL_checkstring(L, 1));

	if(!status)
	{
		fs_errorNL(L, NULL, luaL_checkstring(L, 1));

		return 0;
	}

	return 0;
}

int fs_remove(lua_State *L)
{
	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	int status = PHYSFS_delete(luaL_checkstring(L, 1));

	if(!status)
	{
		fs_errorNL(L, NULL, luaL_checkstring(L, 1));

		return 0;
	}

	return 0;
}

int fs_which(lua_State *L)
{
	const char *d;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	d = PHYSFS_getRealDir(luaL_checkstring(L, 1));

	if(d)
		lua_pushstring(L, d);
	else
		lua_pushnil(L);

	return 1;
}

int fs_listFiles(lua_State *L)
{
	const char **files;
	const char **i;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	files = (const char **) PHYSFS_enumerateFiles(luaL_checkstring(L, 1));

	lua_newtable(L);

	for(i = files; *i != NULL; ++i)
	{
		lua_pushinteger(L, files - i + 1);
		lua_pushstring(L, *i);
		lua_settable(L, -3);
	}

	PHYSFS_freeList(files);

	return 1;
}

int fs_fileExists(lua_State *L)
{
	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	lua_pushboolean(L, PHYSFS_exists(luaL_checkstring(L, 1)));

	return 1;
}

int fs_directoryExists(lua_State *L)
{
	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	lua_pushboolean(L, PHYSFS_isDirectory(luaL_checkstring(L, 1)));

	return 1;
}

int fs_symbolicLinkExists(lua_State *L)
{
	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	lua_pushboolean(L, PHYSFS_isSymbolicLink(luaL_checkstring(L, 1)));

	return 1;
}

int fs_getModificationTime(lua_State *L)
{
	PHYSFS_sint64 time;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	time = PHYSFS_getLastModTime(luaL_checkstring(L, 1));

	if(time == -1)
		lua_pushnil(L);
	else
		lua_pushnumber(L, time);

	return 1;
}

int fs_openWrite(lua_State *L)
{
	PHYSFS_File *fout;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fout = PHYSFS_openWrite(luaL_checkstring(L, 1));

	if(!fout)
	{
		fs_errorNL(L, fout, luaL_checkstring(L, 1));

		return 0;
	}

	lua_pushlightuserdata(L, fout);

	return 1;
}

int fs_openAppend(lua_State *L)
{
	PHYSFS_File *fout;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fout = PHYSFS_openAppend(luaL_checkstring(L, 1));

	if(!fout)
	{
		fs_errorNL(L, fout, luaL_checkstring(L, 1));

		return 0;
	}

	lua_pushlightuserdata(L, fout);

	return 1;
}

int fs_openRead(lua_State *L)
{
	PHYSFS_File *fin;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fin = PHYSFS_openRead(luaL_checkstring(L, 1));

	if(!fin)
	{
		fs_errorNL(L, fin, luaL_checkstring(L, 1));

		return 0;
	}

	lua_pushlightuserdata(L, fin);

	return 1;
}

int fs_close(lua_State *L)
{
	int status = 0;
	PHYSFS_File *file;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	file = lua_touserdata(L, 1);

	if(file)
	{
		status = PHYSFS_close(file);

		if(!status)
		{
			fs_errorNL(L, file, NULL);

			return 0;
		}

		return 0;
	}

	return 0;
}

int fs_read(lua_State *L)
{
	PHYSFS_File *fin;
	PHYSFS_sint64 num;
	int len;
	static char staticBuffer[BUFSIZE];
	char *buf = staticBuffer;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fin = lua_touserdata(L, 1);
	len = luaL_checkinteger(L, 2);

	if(len > sizeof(buf))
	{
		buf = malloc(len);
		if(!buf)
		{
			lua_pushstring(L, "fs_read: could not allocate enough memory to read from file");
			lua_error(L);

			return 0;
		}
	}

	num = PHYSFS_read(fin, buf, 1, len);

	lua_pushlstring(L, buf, num);

	if(len > sizeof(buf))
	{
		free(buf);
	}

	if(num < len)
	{
		if(PHYSFS_eof(fin))
		{
			lua_pushboolean(L, true);
		}
		else
		{
			fs_errorNL(L, fin, NULL);

			return 0;
		}
	}
	else
	{
		lua_pushboolean(L, false);
	}

	return 2;
}

int fs_write(lua_State *L)
{
	PHYSFS_File *fout;
	PHYSFS_sint64 num;
	size_t len;
	const char *string;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fout = lua_touserdata(L, 1);
	string = luaL_checklstring(L, 2, &len);

	num = PHYSFS_write(fout, string, 1, len);

	if(num < len)
	{
		fs_errorNL(L, fout, NULL);

		return 0;
	}

	return 0;
}

int fs_tell(lua_State *L)
{
	int offset;
	PHYSFS_File *file;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	file = lua_touserdata(L, 1);

	offset = PHYSFS_tell(file);

	if(offset == -1)
	{
		fs_errorNL(L, file, NULL);

		return 0;
	}

	lua_pushinteger(L, offset);

	return 1;
}


int fs_seekFromStart(lua_State *L)
{
	int status;
	PHYSFS_File *file;
	PHYSFS_uint64 offset;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	file = lua_touserdata(L, 1);
	offset = luaL_checkinteger(L, 2);

	status = PHYSFS_seek(file, offset);

	if(!status)
	{
		fs_errorNL(L, file, NULL);

		return 0;
	}

	return 0;
}

int fs_fileLength(lua_State *L)
{
	PHYSFS_File *file;
	PHYSFS_uint64 len;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	file = lua_touserdata(L, 1);

	len = PHYSFS_fileLength(file);

	if(len == -1)
	{
		fs_errorNL(L, file, NULL);

		return 0;
	}

	return 1;
}

int fs_getInt(lua_State *L)
{
	int status;
	PHYSFS_file *fin;
	PHYSFS_uint32 value;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fin = lua_touserdata(L, 1);

	status = PHYSFS_readULE32(fin, &value);

	if(!status)
	{
		if(PHYSFS_eof(fin))
		{
			lua_pushnil(L);

			return 1;
		}
		else
		{
			fs_errorNL(L, fin, NULL);

			return 0;
		}
	}

	lua_pushinteger(L, value);

	return 1;
}

int fs_getShort(lua_State *L)
{
	int status;
	PHYSFS_file *fin;
	PHYSFS_uint16 value;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fin = lua_touserdata(L, 1);

	status = PHYSFS_readULE16(fin, &value);

	if(!status)
	{
		if(PHYSFS_eof(fin))
		{
			lua_pushnil(L);

			return 1;
		}
		else
		{
			fs_errorNL(L, fin, NULL);

			return 0;
		}
	}

	lua_pushinteger(L, value);

	return 1;
}

int fs_getChar(lua_State *L)
{
	int status;
	PHYSFS_file *fin;
	unsigned char value;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fin = lua_touserdata(L, 1);

	status = PHYSFS_read(fin, &value, 1, 1);

	if(status < 1)
	{
		if(PHYSFS_eof(fin))
		{
			lua_pushnil(L);

			return 1;
		}
		else
		{
			fs_errorNL(L, fin, NULL);

			return 0;
		}
	}

	lua_pushinteger(L, value);

	return 1;
}

int fs_getDouble(lua_State *L)
{
	int status;
	PHYSFS_file *fin;
	PHYSFS_uint64 value;
	double *n = (double *) &value;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fin = lua_touserdata(L, 1);

	status = PHYSFS_readULE64(fin, &value);

	if(!status)
	{
		if(PHYSFS_eof(fin))
		{
			lua_pushnil(L);

			return 1;
		}
		else
		{
			fs_errorNL(L, fin, NULL);

			return 0;
		}
	}

	lua_pushnumber(L, *n);

	return 1;
}

int fs_getFloat(lua_State *L)
{
	int status;
	PHYSFS_file *fin;
	PHYSFS_uint32 value;
	float *n = (float *) &value;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fin = lua_touserdata(L, 1);

	status = PHYSFS_readULE32(fin, &value);

	if(!status)
	{
		if(PHYSFS_eof(fin))
		{
			lua_pushnil(L);

			return 1;
		}
		else
		{
			fs_errorNL(L, fin, NULL);

			return 0;
		}
	}

	lua_pushnumber(L, *n);

	return 1;
}

int fs_getStr(lua_State *L)
{
	char c;
	char delimiter = 0;
	int status;
	static char buf[BUFSIZE];
	int numstrings = 0;
	int i;
	int all;
	PHYSFS_file *fin;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fin = lua_touserdata(L, 1);
	if(!lua_isnoneornil(L, 2))
		delimiter = *(lua_tostring(L, 2));
	all = lua_toboolean(L, 3);

	buf[0] = i = 0;
	while((status = PHYSFS_read(fin, &c, 1, 1)) >= 1 && c > 0 && c != delimiter)
	{
		if(i < sizeof(buf) - 1)
		{
			buf[i++] = c;
			buf[i]   = 0;
		}
		else
		{
			lua_pushstring(L, buf);
			++numstrings;
			i = 0;
			buf[i++] = c;
			buf[i]   = 0;
		}
	}

	if(status < 1)
	{
		if(PHYSFS_eof(fin) && !all)
		{
			lua_pop(L, numstrings);

			lua_pushnil(L);

			return 1;
		}
		else if(!all)
		{
			fs_errorNL(L, fin, NULL);

			return 0;
		}
	}

	lua_pushstring(L, buf);
	lua_concat(L, ++numstrings);

	return 1;
}

int fs_putInt(lua_State *L)
{
	int status;
	PHYSFS_file *fout;
	PHYSFS_uint32 value;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fout = lua_touserdata(L, 1);
	value = lua_tointeger(L, 2);

	status = PHYSFS_writeULE32(fout, value);

	if(!status)
	{
		fs_errorNL(L, fout, NULL);

		return 0;
	}

	return 0;
}

int fs_putShort(lua_State *L)
{
	int status;
	PHYSFS_file *fout;
	PHYSFS_uint16 value;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fout = lua_touserdata(L, 1);
	value = lua_tointeger(L, 2);

	status = PHYSFS_writeULE16(fout, value);

	if(!status)
	{
		fs_errorNL(L, fout, NULL);

		return 0;
	}

	return 0;
}

int fs_putChar(lua_State *L)
{
	int status;
	PHYSFS_file *fout;
	unsigned char value;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fout = lua_touserdata(L, 1);
	value = *(luaL_checkstring(L, 2));

	status = PHYSFS_write(fout, &value, 1, 1);

	if(status < 1)
	{
		fs_errorNL(L, fout, NULL);

		return 0;
	}

	return 0;
}

int fs_putDouble(lua_State *L)
{
	int status;
	PHYSFS_file *fout;
	PHYSFS_uint64 value;
	io64tv num;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fout = lua_touserdata(L, 1);
	num = lua_tonumber(L, 2);
	value = *((PHYSFS_uint64 *) &num);

	status = PHYSFS_writeULE64(fout, value);

	if(!status)
	{
		fs_errorNL(L, fout, NULL);

		return 0;
	}

	return 0;
}

int fs_putFloat(lua_State *L)
{
	int status;
	PHYSFS_file *fout;
	PHYSFS_uint32 value;
	io32tv num;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	fout = lua_touserdata(L, 1);
	num = lua_tonumber(L, 2);
	value = *((PHYSFS_uint32 *) &num);

	status = PHYSFS_writeULE32(fout, value);

	if(!status)
	{
		fs_errorNL(L, fout, NULL);

		return 0;
	}

	return 0;
}

int fs_mount(lua_State *L)
{
	int len;
	int status;

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	len = lua_objlen(L, 2);

	status = PHYSFS_mount(luaL_checkstring(L, 1), ((len > 0) ? (luaL_checkstring(L, 2)) : (NULL)), lua_toboolean(L, 3));

	if(!status)
	{
		fs_errorNL(L, NULL, luaL_checkstring(L, 1));

		return 0;
	}

	return 0;
}

static int load_aux(lua_State *L, int status)
{
	if(status == 0)  /* OK? */
	{
		return 1;
	}
	else
	{
		lua_pushnil(L);
		lua_insert(L, -2);  /* put before error message */

		return 2;  /* return nil plus error message */
	}
}

int fs_loadfile(lua_State *L)
{
	const char *fname = luaL_optstring(L, 1, NULL);

	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	return load_aux(L, fs_luaL_loadfile(L, fname));
}

int fs_permitSymbolicLinks(lua_State *L)
{
	CHECKINIT(init, L);
	CHECKFSINIT(init, L);

	PHYSFS_permitSymbolicLinks(lua_toboolean(L, 1));

	return 0;
}

const char *fs_createTemporaryFile(lua_State *L, const char *filename, const char *ext)
{
	FILE *fout;
	int status = 1;
	PHYSFS_File *fin;
	static char buf[FBUFSIZE];
	const char *tmpfilename;

	/* Copy file to a temporary file */
	fin = PHYSFS_openRead(filename);
	if(!fin)
	{
		fs_errorNL(L, fin, filename);

		return NULL;
	}

	/*tmpfilename = tempnam(NULL, "ext");*/
	tmpfilename = tmpnam(NULL);
	if(!tmpfilename)
	{
		lua_pushstring(L, "could not create temporary file for file");
		lua_error(L);

		/*free(tmpfilename);*/
		return NULL;
	}

	fout = fopen(tmpfilename, "w");
	if(!fout)
	{
		lua_pushstring(L, "could not open temporary file for file");
		lua_error(L);

		/*free(tmpfilename);*/
		return NULL;
	}

	while((status = PHYSFS_read(fin, buf, 1, sizeof(buf))) >= sizeof(buf))
	{
		int status2;

		status2 = fwrite(buf, 1, status, fout);
		/*if(status2 == EOF)*/
		if(status2 != status)
		{
			lua_pushstring(L, "could not write temporary file for file");
			lua_error(L);

			/*free(tmpfilename);*/
			return NULL;
		}
	}
	if(status < sizeof(buf) && !PHYSFS_eof(fin))
	{
		fs_errorNL(L, fin, filename);

		/*free(tmpfilename);*/
		return NULL;
	}
	else if(status < sizeof(buf))
	{
		int status2;

		status2 = fwrite(buf, 1, status, fout);
		/*if(status2 == EOF)*/
		if(status2 != status)
		{
			lua_pushstring(L, "could not write temporary file for file");
			lua_error(L);

			/*free(tmpfilename);*/
			return NULL;
		}
	}

	status = PHYSFS_close(fin);
	if(!status)
	{
		fs_errorNL(L, fin, filename);

		return NULL;
	}
	fclose(fout);

	/*free(tmpfilename);*/

	return tmpfilename;
}
