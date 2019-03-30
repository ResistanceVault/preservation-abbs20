;/*
sc5 -j73 -v CheckABBSnr
slink LIB:c.o+"CheckABBSnr.o" to CheckABBSnr LIB LIB:sc.lib LIB:JEO.lib
;Copy CheckABBSnr ABBS:Utils
Delete CheckABBSnr.o QUIET
quit
*/

#include <JEO:JEO.h>
#include <exec/memory.h>
#include <proto/dos.h>

char Filename[108];

main (int argc, char**argv)
{
	BPTR fh;
	UBYTE *Buffer = 0;
	LONG size, i;

	if (argc != 2)
	{
		printf ("Error in argument\n");
		exit (0);
	}
	strcpy (Filename, argv[1]);
	size = FileSize (Filename);
	if (size > 150000)
	{
		Buffer = AllocMem (size, MEMF_CLEAR);
		if (fh = Open (Filename, MODE_OLDFILE))
		{
			Read (fh, Buffer, size);
			Close (fh);
			for (i = 0; i < size - 20; i++)
			{
				if (Buffer[i] == 0x56CA AND Buffer[i+1] == 0x34bf)
				{
					printf ("1 Found at i: %ld\n", i);
					printf ("%04lx%04lx\n", Buffer[i-2], Buffer[i-1]);
					printf ("%04lx%04lx\n", Buffer[i-4], Buffer[i-3]);
					printf ("%04lx%04lx\n", Buffer[i+1], Buffer[i+2]);
					printf ("%04lx%04lx\n", Buffer[i+3], Buffer[i+4]);
//					break;
				}
				if (Buffer[i] == -133592095)
					printf ("-133592095 Found at i: %ld\n", i);

				if ((ULONG)Buffer[i] == 221)
					printf ("221 Found at i: %ld\n", i);
			}
		}
		else
			printf ("Error 1\n");
	}
	else
		printf ("Error 2\n");

	if (Buffer)
		FreeMem (Buffer, size);
}
