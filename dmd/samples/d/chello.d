/* Server for IHello
 * Heavily modified from:
 */
/*
 * SELFREG.CPP
 * Server Self-Registrtation Utility, Chapter 5
 *
 * Copyright (c)1993-1995 Microsoft Corporation, All Rights Reserved
 *
 * Kraig Brockschmidt, Microsoft
 * Internet  :  kraigb@microsoft.com
 * Compuserve:  >INTERNET:kraigb@microsoft.com
 */
// From an example from "Inside OLE" Copyright Microsoft

import std.c.stdio;
import std.c.stdlib;
import std.string;
import std.c.windows.windows;
import std.c.windows.com;

GUID CLSID_Hello = { 0x30421140, 0, 0, [0xC0,0,0,0,0,0,0,0x46] };
GUID IID_IHello  = { 0x00421140, 0, 0, [0xC0,0,0,0,0,0,0,0x46] };

interface IHello : IUnknown
{
    extern (Windows):
	int Print();
}


//Type for an object-destroyed callback
alias void (*PFNDESTROYED)();

/*
 * The class definition for an object that singly implements
 * IHello in D.
 */
class CHello : ComObject, IHello
{
    protected:
	IUnknown m_pUnkOuter;	// Controlling unknown

        PFNDESTROYED    m_pfnDestroy;   //To call on closure

	/*
	 *  pUnkOuter       LPUNKNOWN of a controlling unknown.
	 *  pfnDestroy      PFNDESTROYED to call when an object
	 *                  is destroyed.
	 */
    public this(IUnknown pUnkOuter, PFNDESTROYED pfnDestroy)
	{
	    m_pUnkOuter = pUnkOuter;
	    m_pfnDestroy = pfnDestroy;
	}

        ~this()
	{
	    MessageBoxA(null,"CHello.~this()",null,MB_OK);
	}

    extern (Windows):
	/*
	 *  Performs any intialization of a CHello that's prone to failure
	 *  that we also use internally before exposing the object outside.
	 * Return Value:
	 *  BOOL            true if the function is successful,
	 *                  false otherwise.
	 */

    public:
        BOOL Init()
	{
	    MessageBoxA(null,"CHello.Init()",null,MB_OK);
	    return true;
	}

    public:

	HRESULT QueryInterface(const(IID)* riid, LPVOID *ppv)
	{
	    MessageBoxA(null,"CHello.QueryInterface()",null,MB_OK);
	    if (IID_IUnknown == *riid)
		*ppv = cast(void*)cast(IUnknown)this;
	    else if (IID_IHello == *riid)
		*ppv = cast(void*)cast(IHello)this;
	    else
	    {	*ppv = null;
		return E_NOINTERFACE;
	    }

	    AddRef();
	    return NOERROR;
	}

        ULONG Release()
	{
	    MessageBoxA(null,"CHello.Release()",null,MB_OK);
	    if (0 != --count)
		return count;

	    /*
	     * Tell the housing that an object is going away so it can
	     * shut down if appropriate.
	     */
	    MessageBoxA(null,"CHello Destroy()",null,MB_OK);
	    if (m_pfnDestroy)
		(*m_pfnDestroy)();

	    //delete this;
	    return 0;
	}

        //IHello members
	HRESULT Print()
	{
	    MessageBoxA(null,"CHello.Print()",null,MB_OK);
	    return NOERROR;
	}
}

