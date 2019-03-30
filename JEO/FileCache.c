;/*
sc5 -j73 -v -O FileCache
slink LIB:c.o+"FileCache.o" to FileCache LIB LIB:sc.lib LIB:reqtools.lib LIB:JEO.lib
Copy FileCache BBS:ABBS/Utils
Delete FileCache.o FileCache QUIET
quit
*/

char *vers = "\0$VER: FileCache v2.00 - 06.10.98";

#include <JEO.h>
#include <bbs.h>
#include <exec/memory.h>
#include <proto/exec.h>
#include <proto/dos.h>
#include <libraries/reqtools.h>
#include <proto/reqtools.h>

struct ConfigRecord *config = 0;
UBYTE ConfigFName[] = "ABBS:Config/Configfile";
char string[10];
int	configsize = 0;

BOOL SaveConfigfile (struct ConfigRecord *config)
{
	BPTR file;

	printf ("  Saving configfile...\n");
	if (file = Open (ConfigFName, MODE_OLDFILE))
	{
		Seek (file, 10, OFFSET_BEGINNING);
		if (Write (file,	((APTR) (((ULONG) config) + sizeof (string))), (configsize-sizeof (string))))
		{
			Close (file);
			return (TRUE);
		}
	}
	return (FALSE);
}

VOID main ()
{
	BPTR file;
	int n;

	if (FindPort (MainPortName))
	{
		printf ("\n  ABBS must be down for FileCache to work!\n\n");
		exit (0);
	}

	if (ReqToolsBase = (struct ReqToolsBase *)OpenLibrary (REQTOOLSNAME, REQTOOLSVERSION))
	{
		if (file = Open (ConfigFName, MODE_OLDFILE))
		{
			n = Read (file, string, sizeof (string));
			if (n == sizeof (string))
				configsize = ((struct ConfigRecord *) &string)->Configsize;
			else
				printf ("\n Error reading file '%s'!\n\n", ConfigFName);
			if (configsize && (config = AllocVec (configsize,NULL)))
			{
				memcpy (config, string, sizeof (string));
				if ((configsize-sizeof (string)) == Read (file,
					((APTR) (((ULONG) config) + sizeof (string))),
					(configsize-sizeof (string))))
				{
					Close (file);
					file = NULL;
//	************************ DO STUFF **************************************
					if (config->Cflags2 & CFLAGS2F_CacheFL)
					{
						if (JEOReqRequest ("File cache is ON", "Turn file cache OFF?", "Yes|Cancel"))
						{
							config->Cflags2 &= ~CFLAGS2F_CacheFL;
							SaveConfigfile (config);
						}
					}
					else
					{
						if (JEOReqRequest ("File cache is OFF", "Turn file cache ON?", "Yes|Cancel"))
						{
							config->Cflags2 |= CFLAGS2F_CacheFL;
							SaveConfigfile (config);
						}
					}
				}
				else
					printf ("\n Error reading file %s!\n\n", ConfigFName);
				if (file)
					Close (file);
			}
			else
				printf ("\n Error allocating memory!\n\n");
		}
		else
			printf ("\n Error opening file %s! \n\n", ConfigFName);
	}

	FreeVec (config);
}
