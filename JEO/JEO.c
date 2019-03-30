;/*
sc JEO.c Data=FARONLY cpu=000 param=register Autoregister AbsFuncPointer NoStackCheck optimize
copy JEO.c -J:JEO.c
copy JEO.c dabbs:JEO/
copy JEO.o dabbs:JEO/
quit
*/

#include <JEO:JEO.h>
#include <exec/memory.h>
#include <bbs.h>
#include <node.h>

//#include <dos/dos.h>
//#include <dos/dosextens.h>
//#include <dos/filehandler.h>
//#include <utility/date.h>
//#include <devices/SCSIdisk.h>

#include <proto/exec.h>
#include <proto/dos.h>
//#include <proto/utility.h>

#include <string.h>
#include <ctype.h>
#include <dos.h>

#define	a4a5 register __a4 struct ramblocks *nodebase,register __a5 struct Mainmemory *mainmeory
#define	usea4a5	nodebase,mainmeory

extern far struct DosLibrary *DOSBase;
extern __asm far writetexto (register __a0 char *text,a4a5);

UBYTE Dummy[1000];

__asm VOID Test (a4a5)
{
	ULONG i;

	for (i = 0; i < 100; i++)
	{
		sprintf (Dummy, "[imFatman er en dritt!! HEHE\n", i);
		writetexto (Dummy, usea4a5);
		Delay (2);
	}
}

__asm VOID Bug (register __d0 int d0, register __d1 int d1, register __d2 d2,
                register __d3 int d3, register __d4 int d4, register __d5 d5,
        				register __d6 int d6)
{
	printf ("d0 = %ld - %08lx\n", d0);
	printf ("d2 = %ld - %08lx\n", d2);
}
