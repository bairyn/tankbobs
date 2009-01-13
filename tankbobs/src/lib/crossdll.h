/*
Copyright (C) 2009 Byron James Johnson

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
 * crossdll.h
 *
 * crossdll.h enables a cross-platform interface to DLL's.  All handling is done
 * in crossdll.c.  When writing a crossdll dll, be sure to #include this file.
 * Then put CDLL_BEGIN at the beginning of the file and CDLL_END at the end.
 * For each function definition (prototypes excluded, and only the DLL
 * functions), place CDLL_PREFIX _immediately before_ the function name.  Also
 * remember that a main function is not allowed in crossdll because it is not
 * cross-platform.
 */

#ifndef CROSSDLL_H
#define CROSSDLL_H

/*
 * CDLL_FUNCTION
 *
 * CDLL_FUNCTION is an easier way to call cdll_function().  For example, do
 * CDLL_FUNCTION("mylib", "myFunction", void(*)(const char *))("Hello World!")
 */
#define CDLL_FUNCTION(l, f, t) (*((t)(cdll_function((l), (f)))))

#if defined(__WINDOWS__) || defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WIN__)
#include <windows.h>
#ifdef __cplusplus
#define CDLL_BEGIN extern "C" {
#define CDLL_END } BOOL WINAPI DllMain (HINSTANCE, DWORD, LPVOID){return 1;}
#else
#define CDLL_BEGIN
#define CDLL_END BOOL WINAPI DllMain (HINSTANCE, DWORD, LPVOID){return 1;}
#endif
#define CDLL_PREFIX __declspec(dllexport)
#else
#include <dlfcn.h>
#ifdef __cplusplus
#define CDLL_BEGIN extern "C" {
#define CDLL_END }
#else
#define CDLL_BEGIN
#define CDLL_END
#endif
#define CDLL_PREFIX
#endif

#define CDLL_MAX_BUF_CHARS 2048

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
void cdll_setError(const char *l, void (*f)(const char *));

/*
 * cdll_function
 *
 * cdll_function returns a pointer to the function
 * note here that the function signature should be cast properly.  It is only
 * as it is here to be OK with ISO C
 */
/* void *cdll_function(const char *l, const char *f); */
/* typedef void(*)(void) cdll_function_t; */
/* void(*)(void) cdll_function(const char *l, const char *f); */
void(*cdll_function(const char *l, const char *f))(void);

/*
 * cdll_cleanup
 *
 * if l is NULL cleanup everything
 */
void cdll_cleanup(const char *l);

/*
 * cdll_setExtension
 *
 * cdll_setExtensionresets the extension from the default system-dependant
 * extension.  'e' can also be NULL to remove the extension
 */
void cdll_setExtension(const char *e);

#endif
