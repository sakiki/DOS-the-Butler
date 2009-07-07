// Written in the D programming language

module std.switcherr;

import std.stdio;

class SwitchError : Error
{
  private:

    uint linnum;
    char[] filename;

    this(char[] filename, uint linnum)
    {
	this.linnum = linnum;
	this.filename = filename;

	char[] buffer = new char[17 + filename.length + linnum.sizeof * 3 + 1];
	int len = sprintf(buffer.ptr, "Switch Default %.*s(%u)", filename, linnum);
	super(cast(string) buffer[0..len]);
    }


  public:

    /***************************************
     * If nobody catches the Assert, this winds up
     * getting called by the startup code.
     */

    override void print()
    {
	printf("Switch Default %s(%u)\n", cast(char *)filename, linnum);
    }
}

/********************************************
 * Called by the compiler generated module assert function.
 * Builds an Assert exception and throws it.
 */

extern (C) static void _d_switch_error(char[] filename, uint line)
{
    //printf("_d_switch_error(%s, %d)\n", cast(char *)filename, line);
    SwitchError a = new SwitchError(filename, line);
    //printf("assertion %p created\n", a);
    throw a;
}
