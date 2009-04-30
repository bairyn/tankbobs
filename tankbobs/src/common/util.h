#ifndef UTIL_H
#define UTIL_H

#ifdef __cplusplus
#include <string>
// #include <QApplication>
// std::string util_qtcp(const QString &s);
#endif
int         util_strncmp(const char *s1, const char *s2, int len);
int         util_atoi(const char *s);
#ifdef __cplusplus
bool        util_pip(int n, float *xp, float *yp, float x, float y);
#else
int         util_pip(int n, float *xp, float *yp, float x, float y);
#endif
void        util_fpermutation(void (*f)(int), const int *n, int s, int o);
void        util_permutation(int *n, int s, int o);
#ifdef __cplusplus
inline int  util_restrict(int x, int s, int l);
#else
int         util_restrict(int x, int s, int l);
#endif
/* UTIL_QATOI(str, result) */
/* UTIL_ARRAYELEMENTS(a) */
/* UTIL_SWAPINTEGERS(a, b) */
/* UTIL_SWAPBYTES(b, pa, pb) */
/* UTIL_SWAPELEMENTS(e, pa, pb) */
/* UTIL_CLAMP(v, s, l) */

/*
 * UTIL_QATOI
 *
 * faster inline implementation of stdlib's itoa
 */
#define UTIL_QATOI(str, result)                                                \
for(;;)                                                                        \
{                                                                              \
	char *s = str;                                                             \
	result = 0;                                                                \
	for(;;)                                                                    \
	{                                                                          \
		if(*s >= '0' && *s <= '9')                                             \
		{                                                                      \
			result *= 10;                                                      \
			result += *s++ - '0';                                              \
		}                                                                      \
		else                                                                   \
		{                                                                      \
			break;                                                             \
		}                                                                      \
	}                                                                          \
	break;                                                                     \
}

/*
 * UTIL_ARRAYELEMENTS
 *
 * number of elements of an array
 */
#define UTIL_ARRAYELEMENTS(a)                                                  \
sizeof(a) / sizeof(a[0])

/*
 * UTIL_SWAPINTEGERS
 *
 * swaps two integers
 */
#define UTIL_SWAPINTEGERS(a, b)                                                \
{                                                                              \
	a ^= b;                                                                    \
	b ^= a;                                                                    \
	a ^= b;                                                                    \
}                                                                              \

/*
 * UTIL_SWAPBYTES
 *
 * swaps data of equal size b in number of bytes
 */
#define UTIL_SWAPBYTES(b, pa, pb)                                              \
{                                                                              \
	int i;                                                                     \
                                                                               \
	for(i = 0; i < b; i++)                                                     \
	{                                                                          \
		unsigned char *a = (unsigned char *)pa;                                \
		unsigned char *b = (unsigned char *)pb;                                \
		UTIL_SWAPINTEGERS(a[i], b[i]);                                         \
	}                                                                          \
}                                                                              \

/*
 * UTIL_SWAPELEMENTS
 *
 * swaps data of equal size e in number of elements, typically arrays
 */
#define UTIL_SWAPELEMENTS(e, pa, pb)                                           \
{                                                                              \
	UTIL_SWAPBYTES(sizeof(pa[0]) * e);                                         \
}                                                                              \

/*
 * UTIL_CLAMP
 *
 * clamp v between s and l
 */

#define UTIL_CLAMP(v, s, l)                                                    \
(((v) > (l)) ? (l) : (((v) < (s)) ? (s) : (v)))

#endif
