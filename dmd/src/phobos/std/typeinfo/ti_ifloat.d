
// ifloat

module std.typeinfo.ti_ifloat;

private import std.typeinfo.ti_float;

class TypeInfo_o : TypeInfo_f
{
    override string toString() { return "ifloat"; }
}

