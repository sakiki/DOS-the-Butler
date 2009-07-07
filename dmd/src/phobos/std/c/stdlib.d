/**
 * C's &lt;stdlib.h&gt;
 * D Programming Language runtime library
 * Authors: Walter Bright, Digital Mars, http://www.digitalmars.com
 * License: Public Domain
 * Macros:
 *	WIKI=Phobos/StdCStdlib
 */


module std.c.stdlib;

private import std.c.stddef;

extern (C):

enum
{
    _MAX_PATH   = 260,
    _MAX_DRIVE  = 3,
    _MAX_DIR    = 256,
    _MAX_FNAME  = 256,
    _MAX_EXT    = 256,
}

///
struct div_t { int  quot,rem; }
///
struct ldiv_t { int quot,rem; }
///
struct lldiv_t { long quot,rem; }

    div_t div(int,int);	///
    ldiv_t ldiv(int,int); /// ditto
    lldiv_t lldiv(long, long); /// ditto

    const int EXIT_SUCCESS = 0;	///
    const int EXIT_FAILURE = 1;	/// ditto

    int    atexit(void (*)());	///
    void   exit(int);	/// ditto
    void   _exit(int);	/// ditto

    int system(const char *);

    void *alloca(uint);	///

    void *calloc(size_t, size_t);	///
    void *malloc(size_t);	/// ditto
    void *realloc(void *, size_t);	/// ditto
    void free(void *);	/// ditto

    void *bsearch(in void *,in void *,size_t,size_t,
       int function(in void *,in void *));	///
    void qsort(void *base, size_t nelems, size_t elemsize,
	int (*compare)(in void *elem1, in void *elem2));	/// ditto

    char* getenv(const char*);	///
    int   setenv(const char*, const char*, int); /// extension to ISO C standard, not available on all platforms
    void  unsetenv(const char*); /// extension to ISO C standard, not available on all platforms

    int    rand();	///
    void   srand(uint);	/// ditto
    int    random(int num);	/// ditto
    void   randomize();	/// ditto

    int getErrno();	/// ditto
    int setErrno(int);	/// ditto

const int ERANGE = 34;	// on both Windows and linux

double atof(in char *);	///
int    atoi(in char *);	/// ditto
int    atol(in char *);	/// ditto
float  strtof(char *,char **);	/// ditto
double strtod(char *,char **);	/// ditto
real   strtold(char *,char **);	/// ditto
long   strtol(char *,char **,int);	/// ditto
uint   strtoul(char *,char **,int);	/// ditto
long   atoll(in char *);	/// ditto
long   strtoll(char *,char **,int);	/// ditto
ulong  strtoull(char *,char **,int);	/// ditto

char* itoa(int, char*, int);	///
char* ultoa(uint, char*, int);	/// ditto

int mblen(in char *s, size_t n);	///
int mbtowc(wchar_t *pwc, char *s, size_t n);	/// ditto
int wctomb(char *s, wchar_t wc);	/// ditto
size_t mbstowcs(wchar_t *pwcs, in char *s, size_t n);	/// ditto
size_t wcstombs(in char *s, wchar_t *pwcs, size_t n);	/// ditto
