#include <QApplication>
#include <string>
#ifdef __cplusplus
#include <cstdlib>
#endif
#include "util.h"

/*
 * util_qtcp
 *
 * convert QString to string and return it
 */
std::string util_qtcp(const QString &s)
{
	std::string cps(s.toLatin1().constData());
	return cps;
}

/*
 * util_strncmp
 *
 * compares strings up to len in a strcmp matter
 */
int util_strncmp(const char *s1, const char *s2, int len)
{
	while(len)
	{
		if(!*s1 && !*s2)
			break;
		if(*s1++ != *s2++)
			return *--s2 - *--s1;
		len--;
	}
	return 0;
}

/*
 * util_atoi
 *
 * fast implementation of stdlib's atoi
 */
int util_atoi(const char *s)
{
	int result = 0;
	for(;;)
	{
		if(*s >= '0' && *s <= '9')
		{
			result *= 10;
			result += *s++ - '0';
		}
		else
		{
			break;
		}
	}

	return result;
}

// UTIL_QITOA(char *str, reference int result)

/*
 * util_pip
 *
 * Randolph Franklin(http://local.wasp.uwa.edu.au/~pbourke/geometry/insidepoly/)
 * n determines the number of points, xp is an array of points[n], and x and y
 * determines the position of the point.  Note that this algorithom may not
 * return the correct value if the horizontal ray crosses a vertex of the
 * polygon.  Another (possibly more computationally) expensive algorithm can be
 * used (#2 on the site)
 */
bool util_pip(int n, float *xp, float *yp, float x, float y)
{
	int i, j, c = false;

	// test each line (second to last + last/first(same point), then last/first + second, second + third, etc)
	for (i = 0, j = n - 1; i < n; j = i++)
	{
		// test for an intersection with the boundry(current line) with a horizontal ray
		if((((yp[i] <= y) && (y < yp[j])) || ((yp[j] <= y) && (y < yp[i]))) && (x < (xp[j] - xp[i]) * (y - yp[i]) / (yp[j] - yp[i]) + xp[i]))
		{
			// invert
			c = !c;
		}
	}

	return c;
}

/*
 * util_fpermutation
 *
 * calls function f for a random permutation
 */
void util_fpermutation(void (*f)(int) , const int *n, int s, int o)
{
	int i;
	char *p = (char *)calloc(s, sizeof(int));
	memcpy(p, (char *)n, s * sizeof(int));
	util_permutation((int *)p, s, o);
	for(i = 0; i < s; i++)
		f(*(((int *)p) + i));
	free(p);
}

/*
 * util_permutation
 *
 * Sets i of size s the order of o.  The order is unique inside of it's range.
 * Order is unique, NOT lexicographical
 */
void util_permutation(int *n, int s, int o)
{
	int i;

	o = util_restrict(o, 0, s * (s - 1));

	for(i = 2; i <= s; i++)
	{
		o /= i - 1;
		UTIL_SWAPINTEGERS(n[o % i], n[i - 1]);
	}
}

/*
 * util_restrict
 *
 * retrict x between s and l
 */
inline int util_restrict(int x, int s, int l)
{
	if(s >= --l)
		return 0;
	while(x >= l) x -= l - s;
	while(x <  s) x += l - s;
	return x;
}
