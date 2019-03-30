;/*
sc5 -j73 -v JEO
copy JEO.c -J:JEO.c
copy JEO.c dabbs:c/
copy JEO.o dabbs:c/
quit
*/

#include <exec/types.h>
#include <exec/memory.h>
#include <bbs.h>
#include <node.h>

#include <dos/dos.h>
#include <dos/dosextens.h>
#include <dos/filehandler.h>
#include <utility/date.h>
#include <devices/SCSIdisk.h>

#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/utility.h>

#include <string.h>
#include <ctype.h>
#include <dos.h>

#define	a4a5 register __a4 struct ramblocks *nodebase,register __a5 struct Mainmemory *mainmeory
#define	usea4a5	nodebase,mainmeory

extern __asm far writetexto (register __a0 char *text,a4a5);

__asm VOID Test (a4a5)
{
	writetexto ("Number Ref #  Conference         To                        Subject", usea4a5);
}
