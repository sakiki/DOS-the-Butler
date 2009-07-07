// Written in the D programming language.

/**
Utilities for manipulating files and scanning directories.

Authors:

$(WEB digitalmars.com, Walter Bright), $(WEB erdani.org, Andrei
Alexandrescu)

Macros:

WIKI = Phobos/StdFile
*/

/*
 *  Copyright (C) 2001-2004 by Digital Mars, www.digitalmars.com
 * Written by Walter Bright, Christopher E. Miller, Andre Fornacon
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 */

module std.file;

private import std.c.stdio;
private import std.c.stdlib;
private import std.path;
private import std.string;
private import std.regexp;
private import std.gc;
private import std.c.string;
private import std.traits;
import std.conv;
private import std.stdio; // for testing only

/* =========================== Win32 ======================= */

version (Win32)
{

private import std.c.windows.windows;
private import std.utf;
private import std.windows.syserror;
private import std.windows.charset;
private import std.date;

int useWfuncs = 1;

static this()
{
    // Win 95, 98, ME do not implement the W functions
    useWfuncs = (GetVersion() < 0x80000000);
}

/***********************************
 * Exception thrown for file I/O errors.
 */

class FileException : Exception
{

    uint errno;			// operating system error code

    this(string name)
    {
	this(name, "file I/O");
    }

    this(string name, string message)
    {
	super(name ~ ": " ~ message);
    }

    this(string name, uint errno)
    {
	this(name, sysErrorString(errno));
	this.errno = errno;
    }
}

/* **********************************
 * Basic File operations.
 */

/********************************************
 * Read file name[], return array of bytes read.
 * Throws:
 *	FileException on error.
 */

void[] read(in string name)
{
    DWORD numread;
    HANDLE h;

    if (useWfuncs)
    {
	const(wchar*) namez = std.utf.toUTF16z(name);
	h = CreateFileW(namez,GENERIC_READ,FILE_SHARE_READ,null,OPEN_EXISTING,
	    FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN,cast(HANDLE)null);
    }
    else
    {
	const(char*) namez = toMBSz(name);
	h = CreateFileA(namez,GENERIC_READ,FILE_SHARE_READ,null,OPEN_EXISTING,
	    FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN,cast(HANDLE)null);
    }

    if (h == INVALID_HANDLE_VALUE)
	goto err1;

    auto size = GetFileSize(h, null);
    if (size == INVALID_FILE_SIZE)
	goto err2;

    auto buf = std.gc.malloc(size);
    if (buf)
	std.gc.hasNoPointers(buf.ptr);

    if (ReadFile(h,buf.ptr,size,&numread,null) != 1)
	goto err2;

    if (numread != size)
	goto err2;

    if (!CloseHandle(h))
	goto err;

    return buf[0 .. size];

err2:
    CloseHandle(h);
err:
    delete buf;
err1:
    throw new FileException(name, GetLastError());
}

/*********************************************
 * Write buffer[] to file name[].
 * Throws: FileException on error.
 */

void write(in string name, const void[] buffer)
{
    HANDLE h;
    DWORD numwritten;

    if (useWfuncs)
    {
	const(wchar*) namez = std.utf.toUTF16z(name);
	h = CreateFileW(namez,GENERIC_WRITE,0,null,CREATE_ALWAYS,
	    FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN,cast(HANDLE)null);
    }
    else
    {
	const(char*) namez = toMBSz(name);
	h = CreateFileA(namez,GENERIC_WRITE,0,null,CREATE_ALWAYS,
	    FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN,cast(HANDLE)null);
    }
    if (h == INVALID_HANDLE_VALUE)
	goto err;

    if (WriteFile(h,buffer.ptr,buffer.length,&numwritten,null) != 1)
	goto err2;

    if (buffer.length != numwritten)
	goto err2;
    
    if (!CloseHandle(h))
	goto err;
    return;

err2:
    CloseHandle(h);
err:
    throw new FileException(name, GetLastError());
}


/*********************************************
 * Append buffer[] to file name[].
 * Throws: FileException on error.
 */

void append(in string name, in void[] buffer)
{
    HANDLE h;
    DWORD numwritten;

    if (useWfuncs)
    {
	const(wchar*) namez = std.utf.toUTF16z(name);
	h = CreateFileW(namez,GENERIC_WRITE,0,null,OPEN_ALWAYS,
	    FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN,cast(HANDLE)null);
    }
    else
    {
	const(char*) namez = toMBSz(name);
	h = CreateFileA(namez,GENERIC_WRITE,0,null,OPEN_ALWAYS,
	    FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN,cast(HANDLE)null);
    }
    if (h == INVALID_HANDLE_VALUE)
	goto err;

    SetFilePointer(h, 0, null, FILE_END);

    if (WriteFile(h,buffer.ptr,buffer.length,&numwritten,null) != 1)
	goto err2;

    if (buffer.length != numwritten)
	goto err2;
    
    if (!CloseHandle(h))
	goto err;
    return;

err2:
    CloseHandle(h);
err:
    throw new FileException(name, GetLastError());
}


/***************************************************
 * Rename file from[] to to[].
 * Throws: FileException on error.
 */

void rename(in string from, in string to)
{
    BOOL result;

    if (useWfuncs)
	result = MoveFileW(std.utf.toUTF16z(from), std.utf.toUTF16z(to));
    else
	result = MoveFileA(toMBSz(from), toMBSz(to));
    if (!result)
	throw new FileException(to, GetLastError());
}


/***************************************************
 * Delete file name[].
 * Throws: FileException on error.
 */

void remove(in string name)
{
    BOOL result;

    if (useWfuncs)
	result = DeleteFileW(std.utf.toUTF16z(name));
    else
	result = DeleteFileA(toMBSz(name));
    if (!result)
	throw new FileException(name, GetLastError());
}


/***************************************************
 * Get size of file name[].
 * Throws: FileException on error.
 */

ulong getSize(in string name)
{
    HANDLE findhndl;
    uint resulth;
    uint resultl;

    if (useWfuncs)
    {
	WIN32_FIND_DATAW filefindbuf;

	findhndl = FindFirstFileW(std.utf.toUTF16z(name), &filefindbuf);
	resulth = filefindbuf.nFileSizeHigh;
	resultl = filefindbuf.nFileSizeLow;
    }
    else
    {
	WIN32_FIND_DATA filefindbuf;

	findhndl = FindFirstFileA(toMBSz(name), &filefindbuf);
	resulth = filefindbuf.nFileSizeHigh;
	resultl = filefindbuf.nFileSizeLow;
    }

    if (findhndl == cast(HANDLE)-1)
    {
	throw new FileException(name, GetLastError());
    }
    FindClose(findhndl);
    return (cast(ulong)resulth << 32) + resultl;
}

/*************************
 * Get creation/access/modified times of file name[].
 * Throws: FileException on error.
 */

void getTimes(in string name, out d_time ftc, out d_time fta, out d_time ftm)
{
    HANDLE findhndl;

    if (useWfuncs)
    {
	WIN32_FIND_DATAW filefindbuf;

	findhndl = FindFirstFileW(std.utf.toUTF16z(name), &filefindbuf);
	ftc = std.date.FILETIME2d_time(&filefindbuf.ftCreationTime);
	fta = std.date.FILETIME2d_time(&filefindbuf.ftLastAccessTime);
	ftm = std.date.FILETIME2d_time(&filefindbuf.ftLastWriteTime);
    }
    else
    {
	WIN32_FIND_DATA filefindbuf;

	findhndl = FindFirstFileA(toMBSz(name), &filefindbuf);
	ftc = std.date.FILETIME2d_time(&filefindbuf.ftCreationTime);
	fta = std.date.FILETIME2d_time(&filefindbuf.ftLastAccessTime);
	ftm = std.date.FILETIME2d_time(&filefindbuf.ftLastWriteTime);
    }

    if (findhndl == cast(HANDLE)-1)
    {
	throw new FileException(name, GetLastError());
    }
    FindClose(findhndl);
}


/***************************************************
 * Does file name[] (or directory) exist?
 * Return 1 if it does, 0 if not.
 */

int exists(string name)
{
    uint result;

    if (useWfuncs)
	// http://msdn.microsoft.com/library/default.asp?url=/library/en-us/fileio/base/getfileattributes.asp
	result = GetFileAttributesW(std.utf.toUTF16z(name));
    else
	result = GetFileAttributesA(toMBSz(name));

    return (result == 0xFFFFFFFF) ? 0 : 1;
}

/***************************************************
 * Get file name[] attributes.
 * Throws: FileException on error.
 */

uint getAttributes(string name)
{
    uint result;

    if (useWfuncs)
	result = GetFileAttributesW(std.utf.toUTF16z(name));
    else
	result = GetFileAttributesA(toMBSz(name));
    if (result == 0xFFFFFFFF)
    {
	throw new FileException(name, GetLastError());
    }
    return result;
}

/****************************************************
 * Is name[] a file?
 * Throws: FileException if name[] doesn't exist.
 */

int isfile(in string name)
{
    return (getAttributes(name) & FILE_ATTRIBUTE_DIRECTORY) == 0;
}

/****************************************************
 * Is name[] a directory?
 * Throws: FileException if name[] doesn't exist.
 */

int isdir(in string name)
{
    return (getAttributes(name) & FILE_ATTRIBUTE_DIRECTORY) != 0;
}

/****************************************************
 * Change directory to pathname[].
 * Throws: FileException on error.
 */

void chdir(in string pathname)
{   BOOL result;

    if (useWfuncs)
	result = SetCurrentDirectoryW(std.utf.toUTF16z(pathname));
    else
	result = SetCurrentDirectoryA(toMBSz(pathname));

    if (!result)
    {
	throw new FileException(pathname, GetLastError());
    }
}

/****************************************************
 * Make directory pathname[].
 * Throws: FileException on error.
 */

void mkdir(in string pathname)
{   BOOL result;

    if (useWfuncs)
	result = CreateDirectoryW(std.utf.toUTF16z(pathname), null);
    else
	result = CreateDirectoryA(toMBSz(pathname), null);

    if (!result)
    {
	throw new FileException(pathname, GetLastError());
    }
}

/****************************************************
 * Remove directory pathname[].
 * Throws: FileException on error.
 */

void rmdir(in string pathname)
{   BOOL result;

    if (useWfuncs)
	result = RemoveDirectoryW(std.utf.toUTF16z(pathname));
    else
	result = RemoveDirectoryA(toMBSz(pathname));

    if (!result)
    {
	throw new FileException(pathname, GetLastError());
    }
}

/****************************************************
 * Get current directory.
 * Throws: FileException on error.
 */

string getcwd()
{
    if (useWfuncs)
    {
	wchar c;

	auto len = GetCurrentDirectoryW(0, &c);
	if (!len)
	    goto Lerr;
	auto dir = new wchar[len];
	len = GetCurrentDirectoryW(len, dir.ptr);
	if (!len)
	    goto Lerr;
	return std.utf.toUTF8(dir[0 .. len]); // leave off terminating 0
    }
    else
    {
	char c;

	auto len = GetCurrentDirectoryA(0, &c);
	if (!len)
	    goto Lerr;
	auto dir = new char[len];
	len = GetCurrentDirectoryA(len, dir.ptr);
	if (!len)
	    goto Lerr;
	return cast(string)dir[0 .. len];	// leave off terminating 0
    }

Lerr:
    throw new FileException("getcwd", GetLastError());
}

/***************************************************
 * Directory Entry
 */

struct DirEntry
{
    string name;			/// file or directory name
    ulong size = ~0UL;			/// size of file in bytes
    d_time creationTime = d_time_nan;	/// time of file creation
    d_time lastAccessTime = d_time_nan;	/// time file was last accessed
    d_time lastWriteTime = d_time_nan;	/// time file was last written to
    uint attributes;		// Windows file attributes OR'd together

    void init(string path, in WIN32_FIND_DATA *fd)
    {
	wchar[] wbuf;
	size_t clength;
	size_t wlength;
	size_t n;

	clength = std.string.strlen(fd.cFileName.ptr);

	// Convert cFileName[] to unicode
	wlength = MultiByteToWideChar(0,0,fd.cFileName.ptr,clength,null,0);
	if (wlength > wbuf.length)
	    wbuf.length = wlength;
	n = MultiByteToWideChar(0,0,fd.cFileName.ptr,clength,cast(wchar*)wbuf,wlength);
	assert(n == wlength);
	// toUTF8() returns a new buffer
	name = std.path.join(path, std.utf.toUTF8(wbuf[0 .. wlength]));

	size = (cast(ulong)fd.nFileSizeHigh << 32) | fd.nFileSizeLow;
	creationTime = std.date.FILETIME2d_time(&fd.ftCreationTime);
	lastAccessTime = std.date.FILETIME2d_time(&fd.ftLastAccessTime);
	lastWriteTime = std.date.FILETIME2d_time(&fd.ftLastWriteTime);
	attributes = fd.dwFileAttributes;
    }

    void init(string path, in WIN32_FIND_DATAW *fd)
    {
	size_t clength = std.string.wcslen(fd.cFileName.ptr);
	name = std.path.join(path, std.utf.toUTF8(fd.cFileName[0 .. clength]));
	size = (cast(ulong)fd.nFileSizeHigh << 32) | fd.nFileSizeLow;
	creationTime = std.date.FILETIME2d_time(&fd.ftCreationTime);
	lastAccessTime = std.date.FILETIME2d_time(&fd.ftLastAccessTime);
	lastWriteTime = std.date.FILETIME2d_time(&fd.ftLastWriteTime);
	attributes = fd.dwFileAttributes;
    }

    /****
     * Return !=0 if DirEntry is a directory.
     */
    uint isdir()
    {
	return attributes & FILE_ATTRIBUTE_DIRECTORY;
    }

    /****
     * Return !=0 if DirEntry is a file.
     */
    uint isfile()
    {
	return !(attributes & FILE_ATTRIBUTE_DIRECTORY);
    }
}


/***************************************************
 * Return contents of directory pathname[].
 * The names in the contents do not include the pathname.
 * Throws: FileException on error
 * Example:
 *	This program lists all the files and subdirectories in its
 *	path argument.
 * ----
 * import std.stdio;
 * import std.file;
 *
 * void main(string[] args)
 * {
 *    auto dirs = std.file.listdir(args[1]);
 *
 *    foreach (d; dirs)
 *	writefln(d);
 * }
 * ----
 */

string[] listdir(string pathname)
{
    string[] result;
    
    bool listing(string filename)
    {
	result ~= filename;
	return true; // continue
    }
    
    listdir(pathname, &listing);
    return result;
}


/*****************************************************
 * Return all the files in the directory and its subdirectories
 * that match pattern or regular expression r.
 * Params:
 *	pathname = Directory name
 *	pattern = String with wildcards, such as $(RED "*.d"). The supported
 *		wildcard strings are described under fnmatch() in
 *		$(LINK2 std_path.html, std.path).
 *	r = Regular expression, for more powerful _pattern matching.
 * Example:
 *	This program lists all the files with a "d" extension in
 *	the path passed as the first argument.
 * ----
 * import std.stdio;
 * import std.file;
 *
 * void main(string[] args)
 * {
 *    auto d_source_files = std.file.listdir(args[1], "*.d");
 *
 *    foreach (d; d_source_files)
 *	writefln(d);
 * }
 * ----
 * A regular expression version that searches for all files with "d" or
 * "obj" extensions:
 * ----
 * import std.stdio;
 * import std.file;
 * import std.regexp;
 *
 * void main(string[] args)
 * {
 *    auto d_source_files = std.file.listdir(args[1], RegExp(r"\.(d|obj)$"));
 *
 *    foreach (d; d_source_files)
 *	writefln(d);
 * }
 * ----
 */

string[] listdir(string pathname, string pattern)
{   string[] result;
    
    bool callback(DirEntry* de)
    {
	if (de.isdir)
	    listdir(de.name, &callback);
	else
	{   if (std.path.fnmatch(de.name, pattern))
		result ~= de.name;
	}
	return true; // continue
    }
    
    listdir(pathname, &callback);
    return result;
}

/** Ditto */

string[] listdir(string pathname, RegExp r)
{   string[] result;
    
    bool callback(DirEntry* de)
    {
	if (de.isdir)
	    listdir(de.name, &callback);
	else
	{   if (r.test(de.name))
		result ~= de.name;
	}
	return true; // continue
    }
    
    listdir(pathname, &callback);
    return result;
}

/******************************************************
 * For each file and directory name in pathname[],
 * pass it to the callback delegate.
 *
 * Note:
 *
 * This function is being phased off. New code should use $(D_PARAM
 * dirEntries) (see below).
 * 
 * Params:
 *	callback =	Delegate that processes each
 *			filename in turn. Returns true to
 *			continue, false to stop.
 * Example:
 *	This program lists all the files in its
 *	path argument, including the path.
 * ----
 * import std.stdio;
 * import std.path;
 * import std.file;
 *
 * void main(string[] args)
 * {
 *    auto pathname = args[1];
 *    string[] result;
 *
 *    bool listing(string filename)
 *    {
 *      result ~= std.path.join(pathname, filename);
 *      return true; // continue
 *    }
 *
 *    listdir(pathname, &listing);
 *
 *    foreach (name; result)
 *      writefln("%s", name);
 * }
 * ----
 */

void listdir(in string pathname, bool delegate(string filename) callback)
{
    bool listing(DirEntry* de)
    {
	return callback(std.path.getBaseName(de.name));
    }

    listdir(pathname, &listing);
}

/******************************************************
 * For each file and directory DirEntry in pathname[],
 * pass it to the callback delegate.
 *
 * Note:
 *
 * This function is being phased off. New code should use $(D_PARAM
 * dirEntries) (see below).
 * 
 * Params:
 *	callback =	Delegate that processes each
 *			DirEntry in turn. Returns true to
 *			continue, false to stop.
 * Example:
 *	This program lists all the files in its
 *	path argument and all subdirectories thereof.
 * ----
 * import std.stdio;
 * import std.file;
 *
 * void main(string[] args)
 * {
 *    bool callback(DirEntry* de)
 *    {
 *      if (de.isdir)
 *        listdir(de.name, &callback);
 *      else
 *        writefln(de.name);
 *      return true;
 *    }
 *
 *    listdir(args[1], &callback);
 * }
 * ----
 */

void listdir(in string pathname, bool delegate(DirEntry* de) callback)
{
    string c;
    HANDLE h;
    DirEntry de;

    c = std.path.join(pathname, "*.*");
    if (useWfuncs)
    {
	WIN32_FIND_DATAW fileinfo;

	h = FindFirstFileW(std.utf.toUTF16z(c), &fileinfo);
	if (h != INVALID_HANDLE_VALUE)
	{
	    try
	    {
		do
		{
		    // Skip "." and ".."
		    if (std.string.wcscmp(fileinfo.cFileName.ptr, ".") == 0 ||
			std.string.wcscmp(fileinfo.cFileName.ptr, "..") == 0)
			continue;

		    de.init(pathname, &fileinfo);
		    if (!callback(&de))
			break;
		} while (FindNextFileW(h,&fileinfo) != FALSE);
	    }
	    finally
	    {
		FindClose(h);
	    }
	}
    }
    else
    {
	WIN32_FIND_DATA fileinfo;

	h = FindFirstFileA(toMBSz(c), &fileinfo);
	if (h != INVALID_HANDLE_VALUE)	// should we throw exception if invalid?
	{
	    try
	    {
		do
		{
		    // Skip "." and ".."
		    if (std.string.strcmp(fileinfo.cFileName.ptr, ".") == 0 ||
			std.string.strcmp(fileinfo.cFileName.ptr, "..") == 0)
			continue;

		    de.init(pathname, &fileinfo);
		    if (!callback(&de))
			break;
		} while (FindNextFileA(h,&fileinfo) != FALSE);
	    }
	    finally
	    {
		FindClose(h);
	    }
	}
    }
}

/******************************************
 * Since Win 9x does not support the "W" API's, first convert
 * to wchar, then convert to multibyte using the current code
 * page.
 * (Thanks to yaneurao for this)
 * Deprecated: use std.windows.charset.toMBSz instead.
 */

const(char)* toMBSz(in string s)
{
    return std.windows.charset.toMBSz(s);
}


/***************************************************
 * Copy a file from[] to[].
 */

void copy(in string from, in string to)
{
    BOOL result;

    if (useWfuncs)
	result = CopyFileW(std.utf.toUTF16z(from), std.utf.toUTF16z(to), false);
    else
	result = CopyFileA(toMBSz(from), toMBSz(to), false);
    if (!result)
         throw new FileException(to, GetLastError());
}


}

/* =========================== linux ======================= */

version (linux)
{

private import std.date;
private import std.c.linux.linux;

/***********************************
 */

class FileException : Exception
{

    uint errno;			// operating system error code

    this(string name)
    {
	this(name, "file I/O");
    }

    this(string name, string message)
    {
	super(name ~ ": " ~ message);
    }

    this(string name, uint errno)
    {	char[80] buf = void;
	auto s = strerror_r(errno, buf.ptr, buf.length);
	this(name, std.string.toString(s).idup);
	this.errno = errno;
    }
}

/********************************************
 * Read a file.
 * Returns:
 *	array of bytes read
 */

void[] read(in string name)
{
    uint numread;
    struct_stat statbuf;

    auto namez = toStringz(name);
    //printf("file.read('%s')\n",namez);
    auto fd = std.c.linux.linux.open(namez, O_RDONLY);
    if (fd == -1)
    {
        //printf("\topen error, errno = %d\n",getErrno());
        goto err1;
    }

    //printf("\tfile opened\n");
    if (std.c.linux.linux.fstat(fd, &statbuf))
    {
        //printf("\tfstat error, errno = %d\n",getErrno());
        goto err2;
    }
    auto size = statbuf.st_size;
    auto buf = std.gc.malloc(size);
    if (buf.ptr)
	std.gc.hasNoPointers(buf.ptr);

    numread = std.c.linux.linux.read(fd, buf.ptr, size);
    if (numread != size)
    {
        //printf("\tread error, errno = %d\n",getErrno());
        goto err2;
    }

    if (std.c.linux.linux.close(fd) == -1)
    {
	//printf("\tclose error, errno = %d\n",getErrno());
        goto err;
    }

    return buf[0 .. size];

err2:
    std.c.linux.linux.close(fd);
err:
    delete buf;

err1:
    throw new FileException(name.idup, getErrno());
}

/*********************************************
 * Write a file.
 * Returns:
 *	0	success
 */

void write(in string name, in void[] buffer)
{
    int fd;
    int numwritten;

    auto namez = toStringz(name);
    fd = std.c.linux.linux.open(namez, O_CREAT | O_WRONLY | O_TRUNC, 0660);
    if (fd == -1)
        goto err;

    numwritten = std.c.linux.linux.write(fd, buffer.ptr, buffer.length);
    if (buffer.length != numwritten)
        goto err2;

    if (std.c.linux.linux.close(fd) == -1)
        goto err;

    return;

err2:
    std.c.linux.linux.close(fd);
err:
    throw new FileException(name.idup, getErrno());
}


/*********************************************
 * Append to a file.
 */

void append(in string name, in void[] buffer)
{
    int fd;
    int numwritten;
    char *namez;

    namez = toStringz(name);
    fd = std.c.linux.linux.open(namez, O_APPEND | O_WRONLY | O_CREAT, 0660);
    if (fd == -1)
        goto err;

    numwritten = std.c.linux.linux.write(fd, buffer.ptr, buffer.length);
    if (buffer.length != numwritten)
        goto err2;

    if (std.c.linux.linux.close(fd) == -1)
        goto err;

    return;

err2:
    std.c.linux.linux.close(fd);
err:
    throw new FileException(name.idup, getErrno());
}


/***************************************************
 * Rename a file.
 */

void rename(in string from, in string to)
{
    char *fromz = toStringz(from);
    char *toz = toStringz(to);

    if (std.c.stdio.rename(fromz, toz) == -1)
	throw new FileException(to.idup, getErrno());
}


/***************************************************
 * Delete a file.
 */

void remove(in string name)
{
    if (std.c.stdio.remove(toStringz(name)) == -1)
	throw new FileException(name.idup, getErrno());
}


/***************************************************
 * Get file size.
 */

ulong getSize(in string name)
{
    struct_stat statbuf;
    if (std.c.linux.linux.stat(toStringz(name), &statbuf))
    {
        throw new FileException(name, getErrno());
    }
    return statbuf.st_size;
}

unittest
{
    scope(exit) system("rm -f /tmp/deleteme");
    // create a file of size 1
    assert(system("echo > /tmp/deleteme") == 0);
    assert(getSize("/tmp/deleteme") == 1);
    // create a file of size 3
    assert(system("echo ab > /tmp/deleteme") == 0);
    assert(getSize("/tmp/deleteme") == 3);
}

/***************************************************
 * Get file attributes.
 */

uint getAttributes(in string name)
{
    struct_stat statbuf;

    auto namez = toStringz(name);
    if (std.c.linux.linux.stat(namez, &statbuf))
    {
	throw new FileException(name.idup, getErrno());
    }

    return statbuf.st_mode;
}

/*************************
 * Get creation/access/modified times of file name[].
 * Throws: FileException on error.
 */

void getTimes(in string name, out d_time ftc, out d_time fta, out d_time ftm)
{
    struct_stat statbuf;
    char *namez;

    namez = toStringz(name);
    if (std.c.linux.linux.stat(namez, &statbuf))
    {
	throw new FileException(name.idup, getErrno());
    }

    ftc = cast(d_time)statbuf.st_ctime * std.date.TicksPerSecond;
    fta = cast(d_time)statbuf.st_atime * std.date.TicksPerSecond;
    ftm = cast(d_time)statbuf.st_mtime * std.date.TicksPerSecond;
}


/****************************************************
 * Does file/directory exist?
 */

int exists(in string name)
{
    return access(toStringz(name),0) == 0;

/+
    struct_stat statbuf;
    char *namez;

    namez = toStringz(name);
    if (std.c.linux.linux.stat(namez, &statbuf))
    {
	return 0;
    }
    return 1;
+/
}

unittest
{
    assert(exists("."));
}

/****************************************************
 * Is name a file?
 */

int isfile(in string name)
{
    return (getAttributes(name) & S_IFMT) == S_IFREG;	// regular file
}

/****************************************************
 * Is name a directory?
 */

int isdir(string name)
{
    return (getAttributes(name) & S_IFMT) == S_IFDIR;
}

/****************************************************
 * Change directory.
 */

void chdir(string pathname)
{
    if (std.c.linux.linux.chdir(toStringz(pathname)))
    {
	throw new FileException(pathname, getErrno());
    }
}

/****************************************************
 * Make directory.
 */

void mkdir(string pathname)
{
    if (std.c.linux.linux.mkdir(toStringz(pathname), 0777))
    {
	throw new FileException(pathname, getErrno());
    }
}

/****************************************************
 * Remove directory.
 */

void rmdir(string pathname)
{
    if (std.c.linux.linux.rmdir(toStringz(pathname)))
    {
	throw new FileException(pathname, getErrno());
    }
}

/****************************************************
 * Get current directory.
 */

string getcwd()
{
    auto p = std.c.linux.linux.getcwd(null, 0);
    if (!p)
    {
	throw new FileException("cannot get cwd", getErrno());
    }
    scope(exit) std.c.stdlib.free(p);
    auto len = std.string.strlen(p);
    return p[0 .. len].idup;
}

/***************************************************
 * Directory Entry
 */

struct DirEntry
{
    string name;			/// file or directory name
    ulong _size = ~0UL;			// size of file in bytes
    d_time _creationTime = d_time_nan;	// time of file creation
    d_time _lastAccessTime = d_time_nan; // time file was last accessed
    d_time _lastWriteTime = d_time_nan;	// time file was last written to
    ubyte d_type;
    ubyte didstat;			// done lazy evaluation of stat()

    void init(string path, dirent *fd)
    {	size_t len = std.string.strlen(fd.d_name.ptr);
	name = std.path.join(path, fd.d_name[0 .. len].idup);
	d_type = fd.d_type;
	didstat = 0;
    }

    int isdir()
    {
	return d_type & DT_DIR;
    }

    int isfile()
    {
	return d_type & DT_REG;
    }

    ulong size()
    {
	if (!didstat)
	    doStat();
	return _size;
    }

    d_time creationTime()
    {
	if (!didstat)
	    doStat();
	return _creationTime;
    }

    d_time lastAccessTime()
    {
	if (!didstat)
	    doStat();
	return _lastAccessTime;
    }

    d_time lastWriteTime()
    {
	if (!didstat)
	    doStat();
	return _lastWriteTime;
    }

    /* This is to support lazy evaluation, because doing stat's is
     * expensive and not always needed.
     */

    void doStat()
    {
	int fd;
	struct_stat statbuf;

	auto namez = toStringz(name);
	if (std.c.linux.linux.stat(namez, &statbuf))
	{
	    //printf("\tstat error, errno = %d\n",getErrno());
	    return;
	}
	_size = statbuf.st_size;
	_creationTime = cast(d_time)statbuf.st_ctime * std.date.TicksPerSecond;
	_lastAccessTime = cast(d_time)statbuf.st_atime * std.date.TicksPerSecond;
	_lastWriteTime = cast(d_time)statbuf.st_mtime * std.date.TicksPerSecond;

	didstat = 1;
    }
}


/***************************************************
 * Return contents of directory.
 */

string[] listdir(string pathname)
{
    string[] result;
    
    bool listing(string filename)
    {
	result ~= filename;
	return true; // continue
    }
    
    listdir(pathname, &listing);
    return result;
}

string[] listdir(string pathname, string pattern)
{   string[] result;
    
    bool callback(DirEntry* de)
    {
	if (de.isdir)
	    listdir(de.name, &callback);
	else
	{   if (std.path.fnmatch(de.name, pattern))
		result ~= de.name;
	}
	return true; // continue
    }
    
    listdir(pathname, &callback);
    return result;
}

string[] listdir(string pathname, RegExp r)
{   string[] result;
    
    bool callback(DirEntry* de)
    {
	if (de.isdir)
	    listdir(de.name, &callback);
	else
	{   if (r.test(de.name))
		result ~= de.name;
	}
	return true; // continue
    }
    
    listdir(pathname, &callback);
    return result;
}

void listdir(string pathname, bool delegate(string filename) callback)
{
    bool listing(DirEntry* de)
    {
	return callback(std.path.getBaseName(de.name));
    }

    listdir(pathname, &listing);
}

void listdir(string pathname, bool delegate(DirEntry* de) callback)
{
    DIR* h;
    dirent* fdata;
    DirEntry de;

    h = opendir(toStringz(pathname));
    if (h)
    {
	try
	{
	    while((fdata = readdir(h)) != null)
	    {
		// Skip "." and ".."
		if (!std.string.strcmp(fdata.d_name.ptr, ".") ||
		    !std.string.strcmp(fdata.d_name.ptr, ".."))
			continue;

		de.init(pathname, fdata);
		if (!callback(&de))	    
		    break;
	    }
	}
	finally
	{
	    closedir(h);
	}
    }
    else
    {
        throw new FileException(pathname, getErrno());
    }
}


/***************************************************
 * Copy a file. File timestamps are preserved.
 */

void copy(in string from, in string to)
{
  version (all)
  {
    struct_stat statbuf;

    char* fromz = toStringz(from);
    char* toz = toStringz(to);
    //printf("file.copy(from='%s', to='%s')\n", fromz, toz);

    int fd = std.c.linux.linux.open(fromz, O_RDONLY);
    if (fd == -1)
    {
        //printf("\topen error, errno = %d\n",getErrno());
        goto err1;
    }

    //printf("\tfile opened\n");
    if (std.c.linux.linux.fstat(fd, &statbuf))
    {
        //printf("\tfstat error, errno = %d\n",getErrno());
        goto err2;
    }

    int fdw = std.c.linux.linux.open(toz, O_CREAT | O_WRONLY | O_TRUNC, 0660);
    if (fdw == -1)
    {
        //printf("\topen error, errno = %d\n",getErrno());
        goto err2;
    }

    size_t BUFSIZ = 4096 * 16;
    void* buf = std.c.stdlib.malloc(BUFSIZ);
    if (!buf)
    {	BUFSIZ = 4096;
	buf = std.c.stdlib.malloc(BUFSIZ);
    }
    if (!buf)
    {
        //printf("\topen error, errno = %d\n",getErrno());
        goto err4;
    }

    for (size_t size = statbuf.st_size; size; )
    {	size_t toread = (size > BUFSIZ) ? BUFSIZ : size;

	auto n = std.c.linux.linux.read(fd, buf, toread);
	if (n != toread)
	{
	    //printf("\tread error, errno = %d\n",getErrno());
	    goto err5;
	}
	n = std.c.linux.linux.write(fdw, buf, toread);
	if (n != toread)
	{
	    //printf("\twrite error, errno = %d\n",getErrno());
	    goto err5;
	}
	size -= toread;
    }

    std.c.stdlib.free(buf);

    if (std.c.linux.linux.close(fdw) == -1)
    {
	//printf("\tclose error, errno = %d\n",getErrno());
        goto err2;
    }

    utimbuf utim;
    utim.actime = cast(__time_t)statbuf.st_atime;
    utim.modtime = cast(__time_t)statbuf.st_mtime;
    if (utime(toz, &utim) == -1)
    {
	//printf("\tutime error, errno = %d\n",getErrno());
	goto err3;
    }

    if (std.c.linux.linux.close(fd) == -1)
    {
	//printf("\tclose error, errno = %d\n",getErrno());
        goto err1;
    }

    return;

err5:
    std.c.stdlib.free(buf);
err4:
    std.c.linux.linux.close(fdw);
err3:
    std.c.stdio.remove(toz);
err2:
    std.c.linux.linux.close(fd);
err1:
    throw new FileException(from.idup, getErrno());
  }
  else
  {
    void[] buffer;

    buffer = read(from);
    write(to, buffer);
    delete buffer;
  }
}



}

unittest
{
    //printf("std.file.unittest\n");
    void[] buf;

    buf = new void[10];
    (cast(byte[])buf)[] = 3;
    write("unittest_write.tmp", buf);
    void buf2[] = read("unittest_write.tmp");
    assert(buf == buf2);

    copy("unittest_write.tmp", "unittest_write2.tmp");
    buf2 = read("unittest_write2.tmp");
    assert(buf == buf2);

    remove("unittest_write.tmp");
    if (exists("unittest_write.tmp"))
	assert(0);
    remove("unittest_write2.tmp");
    if (exists("unittest_write2.tmp"))
	assert(0);
}

unittest
{
    listdir (".", delegate bool (DirEntry * de)
    {
	auto s = std.string.format("%s : c %s, w %s, a %s", de.name,
		toUTCString (de.creationTime),
		toUTCString (de.lastWriteTime),
		toUTCString (de.lastAccessTime));
	return true;
    }
    );
}

/**
 * Dictates directory spanning policy for $(D_PARAM dirEntries) (see below). 
 */

enum SpanMode
{
    /** Only spans one directory. */
    shallow,
    /** Spans the directory depth-first, i.e. the content of any
     subdirectory is spanned before that subdirectory itself. Useful
     e.g. when recursively deleting files.  */
    depth,
    /** Spans the directory breadth-first, i.e. the content of any
     subdirectory is spanned right after that subdirectory itself. */
    breadth,
}

struct DirIterator
{
    string pathname;
    SpanMode mode;

    private int doIt(D)(D dg, DirEntry * de)
    {
        alias ParameterTypeTuple!(D) Parms;
        static if (is(Parms[0] : string))
        {
            return dg(de.name);
        }
        else static if (is(Parms[0] : DirEntry))
        {
            return dg(*de);
        }
        else
        {
            static assert(false, "Dunno how to enumerate directory entries"
                          " against type " ~ Parms[0].stringof);
        }
    }
    
    int opApply(D)(D dg)
    {
        int result = 0;
        string[] worklist = [ pathname ]; // used only in breadth-first traversal

        bool callback(DirEntry* de)
        {
            switch (mode)
            {
            case SpanMode.shallow:
                result = doIt(dg, de);
                break;
            case SpanMode.breadth:
                result = doIt(dg, de);
                if (!result && de.isdir)
                {
                    worklist ~= de.name;
                }
                break;
            default:
                assert(mode == SpanMode.depth);
                if (de.isdir)
                {
                    listdir(de.name, &callback);
                }
                if (!result)
                {
                    result = doIt(dg, de);
                }
                break;
            }
            return result == 0; 
        }
        
        // consume the worklist
        while (worklist.length)
        {
            auto listThis = worklist[$ - 1];
            worklist.length = worklist.length - 1;
            listdir(listThis, &callback);
        }
        return result;
    }
}

/**
 * Iterates a directory using foreach. The iteration variable can be
 * of type $(D_PARAM string) if only the name is needed, or $(D_PARAM
 * DirEntry) if additional details are needed. The span mode dictates
 * the how the directory is traversed. The name of the directory entry
 * includes the $(D_PARAM path) prefix.
 *
 * Example:
 *
 * ----
 // Iterate a directory in depth
 foreach (string name; dirEntries("destroy/me", SpanMode.depth))
 {
     remove(name);
 }
 // Iterate a directory in breadth
 foreach (string name; dirEntries(".", SpanMode.breadth))
 {
     writeln(name);
 }
 // Iterate a directory and get detailed info about it
 foreach (DirEntry e; dirEntries("dmd-testing", SpanMode.breadth))
 {
     writeln(e.name, "\t", e.size);
 }
 * ----
 */

DirIterator dirEntries(string path, SpanMode mode)
{
    DirIterator result;
    result.pathname = path;
    result.mode = mode;
    return result;
}

unittest
{
    assert(system("mkdir --parents dmd-testing") == 0);
    scope(exit) system("rm -rf dmd-testing");
    assert(system("mkdir --parents dmd-testing/somedir") == 0);
    assert(system("touch dmd-testing/somefile") == 0);
    assert(system("touch dmd-testing/somedir/somedeepfile") == 0);
    foreach (string name; dirEntries("dmd-testing", SpanMode.shallow))
    {
    }
    foreach (string name; dirEntries("dmd-testing", SpanMode.depth))
    {
        //writeln(name);
    }
    foreach (string name; dirEntries("dmd-testing", SpanMode.breadth))
    {
        //writeln(name);
    }
    foreach (DirEntry e; dirEntries("dmd-testing", SpanMode.breadth))
    {
        //writeln(e.name);
    }
}
