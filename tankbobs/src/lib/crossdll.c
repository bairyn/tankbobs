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
 * crossdll.c
 *
 * crossdll.c implements a cross-platform interface to DLL's.  All handling is done
 * in this file.  Note that this source file uses the following string
 * constants: ".dll", ".so", "Error code: %d\n", "\n" and ""; the following
 * string constants might be used: "LD_LIBRARY_PATH" and "PWD"
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "crossdll.h"
#if defined(__WINDOWS__) || defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WIN__)
#include <windows.h>
#include <strsafe.h>
#include <AltBase.h>
#include <AltConv.h>
static const char *extension = ".dll";
#else
#include <dlfcn.h>
static const char *extension = ".so";
#endif

static int cdll_initialized = 0;

static void cdll_private_init()
{
    cdll_initialized = 1;
}

typedef struct cdll_private_dll_s
{
    const char *name;
    void (*errorFunction)(const char *);
    void *handle;
    struct cdll_private_dll_s *next;
} cdll_private_dll;

static cdll_private_dll *cdll_private_table = NULL;

static void cdll_private_defaultErrorFunction(const char *error)
{
    fputs(error, stderr);
    abort();
}

static void cdll_private_dll_add(cdll_private_dll **cdll, const char *name, void (*errorFunction)(const char *), void *handle)
{
    cdll_private_dll *i;

    *cdll = malloc(sizeof(cdll_private_dll));
    (*cdll)->name = name;
    (*cdll)->errorFunction = errorFunction;
    (*cdll)->handle = handle;
    (*cdll)->next = NULL;
    for(i = cdll_private_table; i; (i = (i->next && i->next == i->next->next ? NULL : i->next)))
    {
        if(!i->next)
        {
            i->next = *cdll;
            break;
        }
    }
}

static cdll_private_dll *cdll_private_exists(const char *name, int mustBeLoaded)
{
    cdll_private_dll *i;

    for(i = cdll_private_table; i; (i = (i->next && i->next == i->next->next ? NULL : i->next)))
        if(!strcmp(i->name, name) && (i->handle || !mustBeLoaded))
            return i;

    return NULL;
}

/*
/8
 8 cdll_resolve
 8
 8 cdll_resolve dynamically resolves symbols (extern's, function protocols,
 8 etc).  lib is the file name without the extension appended.  To resolve
 8 
 8/
void cdll_resolve(const char *l)
{
    cdll_private_dll *i, *d;

    if(cdll_private_exists(l, 1))
    {
        /8 the lib has already been resolved 8/
        return;
    }
    else if((d = cdll_private_exists(l, 0)))
    {
        /8 the lib exists but hasn't been resolved yet 8/
        d->loaded = 1;
    }
    else
    {
        /8 the lib does not exist in the table 8/
        for(i = cdll_private_table; i; (i = (i->next && i->next == i->next->next ? NULL : i->next)))
        {
            if(!i->next)
            {
                cdll_private_dll_add(i->next, l, cdll_private_defaultErrorFunction, 1);
                d = i->next;
            }
        }
    }

#if defined(__WINDOWS__) || defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WIN__)
#else
#endif
}
*/

/*
 * cdll_setError
 *
 * cdll_setError sets the function to be called on error to f.
 * The default error function calls printf() and abort().  If lib is not NULL
 * then the function is only restricted to that library.  On an error the
 * function will always be called if the library that called it has an error
 * bound.  If not, the default error function will be called.  The error
 * function needs one argument.  If the lib doesn't exist then any future
 * errors calling the lib the do error
 */
void cdll_setError(const char *l, void (*f)(const char *))
{
    cdll_private_dll *i, *d;
    char lib[CDLL_MAX_BUF_CHARS];

    if(!cdll_initialized)
        cdll_private_init();

    strncpy(lib, l, CDLL_MAX_BUF_CHARS - strlen(extension));
    strcat(lib, extension);
    l = &lib[0];

    if(!(d = cdll_private_exists(l, 0)))
    {
        for(i = cdll_private_table; i; (i = (i->next && i->next == i->next->next ? NULL : i->next)))
        {
            if(!i->next)
            {
                cdll_private_dll_add(&i->next, l, &cdll_private_defaultErrorFunction, 0);
                d = i->next;
            }
        }
    }

    d->errorFunction = f;
}

/*
 * cdll_function
 *
 * cdll_function returns a pointer to the function
 */
void(*cdll_function(const char *l, const char *f))(void)
{
    cdll_private_dll *i, *d;
    void (*res)(void) = NULL;
    char lib[CDLL_MAX_BUF_CHARS];

    if(!cdll_initialized)
        cdll_private_init();

    strncpy(lib, l, CDLL_MAX_BUF_CHARS - strlen(extension));
    strcat(lib, extension);
    l = &lib[0];

    if((d = cdll_private_exists(l, 1)))
    {
        /* the lib has already been opened */
#if defined(__WINDOWS__) || defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WIN__)
        if(!(res = (void (*)(void))GetProcAddress((HINSTANCE)d->handle, f)))
        {
            char err[99];
            sprintf(err, "Error code: %d\n", GetLastError());
            d->errorFunction(err);
        }
#else
        char *err;
        void *tmp;

        tmp = dlsym(d->handle, f);
        memcpy(&res, &tmp, sizeof(void *));
        if((err = dlerror()))
        {
            char buf[CDLL_MAX_BUF_CHARS + 2];
            strncpy(buf, err, CDLL_MAX_BUF_CHARS + 2);
            buf[CDLL_MAX_BUF_CHARS] = 0;
            strcat(buf, "\n");
            d->errorFunction(buf);
        }
#endif
    }
    else if((d = cdll_private_exists(l, 0)))
    {
        /* the lib exists in the table but hasn't been opened yet */
#if defined(__WINDOWS__) || defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WIN__)
        if(!(d->handle = (void *)LoadLibrary(l)))
        {
            void (*e)(const char *) = d->errorFunction;
			LPVOID lpMsgBuf;
			LPVOID lpDisplayBuf;
			DWORD  dw;

            cdll_cleanup(d->name);

			dw = GetLastError();

			FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
					NULL,
					dw,
					MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
					(LPTSTR) &lpMsgBuf,
					0,
					NULL);

			lpDisplayBuf = (LPVOID)LocalAlloc(LMEM_ZEROINIT, (lstrlen((LPCTSTR)lpMsgBuf) + lstrlen((LPCSTR)d->name) + 128) * sizeof(TCHAR));
			StringCchPrintf((LPTSTR)lpDisplayBuf, LocalSize(lpDisplayBuf) / sizeof(TCHAR), TEXT("'%s' failed with error %d: %s"), TEXT(d->name), dw, lpMsgBuf);

			e(T2A(lpDisplayBuf));

			LocalFree(lpMsgBuf);
			LocalFree(lpDisplayBuf);

			return NULL;
        }

        if(!(res = (void (*)(void))GetProcAddress((HINSTANCE)d->handle, f)))
        {
            char err[99];
            sprintf(err, "Error code: %d\n", GetLastError());
            d->errorFunction(err);
        }
#else
        char *err;
        void *tmp;

        if(!(d->handle = dlopen(l, RTLD_NOW | RTLD_GLOBAL | RTLD_DEEPBIND)))
        {
            /* try a relative path */
            char buf[CDLL_MAX_BUF_CHARS];
            strcpy(buf, "./");
            strncat(buf, l, CDLL_MAX_BUF_CHARS - strlen("./"));
            if(!(d->handle = dlopen(buf, RTLD_NOW | RTLD_GLOBAL | RTLD_DEEPBIND)))
            {
                void (*e)(const char *) = d->errorFunction;
                char buf[CDLL_MAX_BUF_CHARS + 2];
                strncpy(buf, dlerror(), CDLL_MAX_BUF_CHARS + 2);
                buf[CDLL_MAX_BUF_CHARS] = 0;
                strcat(buf, "\n");
                cdll_cleanup(d->name);
                e(buf);
                return NULL;
            }
        }

        tmp = dlsym(d->handle, f);
        memcpy(&res, &tmp, sizeof(void *));
        if((err = dlerror()))
        {
            char buf[CDLL_MAX_BUF_CHARS + 2];
            strncpy(buf, err, CDLL_MAX_BUF_CHARS + 2);
            buf[CDLL_MAX_BUF_CHARS] = 0;
            strcat(buf, "\n");
            d->errorFunction(buf);
        }
#endif
    }
    else
    {
        char *err;
        void *tmp;

        /* the lib does not yet exist in the table */
        for(i = cdll_private_table; i; (i = (i->next && i->next == i->next->next ? NULL : i->next)))
        {
            if(!i->next)
            {
                cdll_private_dll_add(&i->next, l, &cdll_private_defaultErrorFunction, NULL);
                d = i->next;
            }
        }
        if(!cdll_private_table)
        {
            cdll_private_dll_add(&cdll_private_table, l, &cdll_private_defaultErrorFunction, NULL);
            d = cdll_private_table;
        }

#if defined(__WINDOWS__) || defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WIN__)
		(void)err;
		(void)tmp;
        if(!(d->handle = (void *)LoadLibrary(l)))
        {
			/*
            void (*e)(const char *) = d->errorFunction;
            cdll_cleanup(d->name);
            e(dlerror());
            return NULL;
			*/

            void (*e)(const char *) = d->errorFunction;
			LPVOID lpMsgBuf;
			LPVOID lpDisplayBuf;
			DWORD  dw;

            cdll_cleanup(d->name);

			dw = GetLastError();

			FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
					NULL,
					dw,
					MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
					(LPTSTR) &lpMsgBuf,
					0,
					NULL);

			lpDisplayBuf = (LPVOID)LocalAlloc(LMEM_ZEROINIT, (lstrlen((LPCTSTR)lpMsgBuf) + lstrlen((LPCSTR)d->name) + 128) * sizeof(TCHAR));
			StringCchPrintf((LPTSTR)lpDisplayBuf, LocalSize(lpDisplayBuf) / sizeof(TCHAR), TEXT("'%s' failed with error %d: %s"), TEXT(d->name), dw, lpMsgBuf);

			e(T2A(lpDisplayBuf));

			LocalFree(lpMsgBuf);
			LocalFree(lpDisplayBuf);

			return NULL;
        }

        if(!(res = (void (*)(void))GetProcAddress((HINSTANCE)d->handle, f)))
        {
            char err[CDLL_MAX_BUF_CHARS];
            sprintf(err, "Error code: %d\n", GetLastError());
            d->errorFunction(err);
        }
#else
        if(!(d->handle = dlopen(l, RTLD_NOW | RTLD_GLOBAL | RTLD_DEEPBIND)))
        {
            /* try a relative path */
            char buf[CDLL_MAX_BUF_CHARS];
            strcpy(buf, "./");
            strncat(buf, l, CDLL_MAX_BUF_CHARS - strlen("./"));
            if(!(d->handle = dlopen(buf, RTLD_NOW | RTLD_GLOBAL | RTLD_DEEPBIND)))
            {
                void (*e)(const char *) = d->errorFunction;
                char buf[CDLL_MAX_BUF_CHARS + 2];
                strncpy(buf, dlerror(), CDLL_MAX_BUF_CHARS + 2);
                buf[CDLL_MAX_BUF_CHARS] = 0;
                strcat(buf, "\n");
                cdll_cleanup(d->name);
                e(buf);
                return NULL;
            }
        }

        tmp = dlsym(d->handle, f);
        memcpy(&res, &tmp, sizeof(void *));
        if((err = dlerror()))
        {
            char buf[CDLL_MAX_BUF_CHARS + 2];
            strncpy(buf, err, CDLL_MAX_BUF_CHARS + 2);
            buf[CDLL_MAX_BUF_CHARS] = 0;
            strcat(buf, "\n");
            d->errorFunction(buf);
        }
#endif
    }

    return res;
}

/*
 * cdll_cleanup
 *
 * if l is NULL cleanup everything
 */
void cdll_cleanup(const char *l)
{
    cdll_private_dll *i;
    char lib[CDLL_MAX_BUF_CHARS];

    if(!cdll_initialized)
        cdll_private_init();

    strncpy(lib, l, CDLL_MAX_BUF_CHARS - strlen(extension));
    strcat(lib, extension);
    l = &lib[0];

    if(!l)
    {
        for(i = cdll_private_table; i; (i = (i->next && i->next == i->next->next ? NULL : i->next)))
        {
            if(i->handle)
            {
#if defined(__WINDOWS__) || defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WIN__)
                FreeLibrary((HINSTANCE)i->handle);
#else
                dlclose(i->handle);
#endif
                i->handle = NULL;
            }
        }
    }
    else if(cdll_private_exists(l, 0))
    {
        for(i = cdll_private_table; i; (i = (i->next && i->next == i->next->next ? NULL : i->next)))
        {
            if(i->handle && !strcmp(i->name, l))
            {
#if defined(__WINDOWS__) || defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WIN__)
                FreeLibrary((HINSTANCE)i->handle);
#else
                dlclose(i->handle);
#endif
                i->handle = NULL;
            }
        }
    }
}

/*
 * cdll_setExtension
 *
 * cdll_setExtensionresets the extension from the default system-dependant
 * extension.  'e' can also be NULL to remove the extension
 */
void cdll_setExtension(const char *e)
{
    if(e)
        extension = e;
    else
        extension = "";
}
