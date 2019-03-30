;/*
Delete Gen.o quiet
sc5 -j73 -v -O Gen
slink LIB:c.o+"Gen.o" to Gen LIB LIB:sc.lib LIB:JEO.lib SC SD NODEBUG
copy Gen S:
Delete Gen.o Gen.info QUIET
quit
*/

#include "JEO.h"
#include "proto/dos.h"
#include "exec/memory.h"
#include <proto/utility.h>
#include <proto/timer.h>
#include <time.h>

char *Dummy = 0;
#define DUMMYSIZE 5000

char firstFName[] = "dabbs:include/first.i";

ULONG sn, snrcoded = 0, snrrotverdi = 0x56CA34bf;

void CleanUp (void)
{
  if (Dummy)
  {
    FreeMem (Dummy, DUMMYSIZE);
    Dummy = 0;
  }
  exit (0);
}

void Generate (void)
{
	ULONG i;

	snrcoded = sn;

	for (i = 0; i < 5000; i++)
		snrcoded += ((i + snrrotverdi) * sn);
}

BOOL GetDateTime (UBYTE *Date, UBYTE *Time, BOOL mode)
{
	struct ClockData cd;
	struct Library *TimerBase;
	struct Library *UtilityBase;
	struct timerequest tr;
	struct timeval tv;
	BOOL ret = FALSE;
	char Tmp[5];
	char Hold[5];
	

	if (UtilityBase = OpenLibrary ("utility.library", 37))
	{
		if (!(OpenDevice ("timer.device", UNIT_VBLANK, (struct IORequest *)&tr, NULL)))
		{
			TimerBase = (struct Library *)tr.tr_node.io_Device;
			GetSysTime (&tv);
			Amiga2Date (tv.tv_secs,&cd);

			if (mode)	// 1999
				sprintf (Hold, "%ld", cd.year);
			else			// 99
			{
				sprintf (Tmp, "%ld", cd.year);
				strncpy (Hold, &Tmp[2], 2);
				Hold[2] = 0;
			}
			sprintf (Date, "%02ld.%02ld.%s", cd.mday, cd.month, Hold);
			sprintf (Time, "%02ld:%02ld:%02ld", cd.hour, cd.min, cd.sec);
			ret = TRUE;
			CloseDevice((struct IORequest *)&tr);
		}
		CloseLibrary (UtilityBase);
	}
	return (ret);
}

main (int argc, char **argv)
{
  char Hold[100], Date[30], Version[100];
  BPTR fh;

  if (argc != 3)
    exit (0);

  sn = atoi (argv[1]);
  strcpy (Version, argv[2]);
  if (sn >= 0)
  {
    if (Dummy = AllocMem (DUMMYSIZE, MEMF_CLEAR))
    {
      GetDateTime (Date, Dummy, 1);
			Generate ();
      strcpy (Dummy, "\tIFND FIRST_I\nFIRST_I SET 1\n\n;DEMO = 1\n\n");
      sprintf (Hold, "sn\t\tEQU\t%ld\nsnrcoded\tEQU\t%ld\nsnrrotverdi\tEQU\t$%lx\n\n", sn, snrcoded, snrrotverdi);
      strcat (Dummy, Hold);
      sprintf (Hold, "date\tMACRO\n\tdc.b\t' - %s'\n\tENDM\n\n", Date);
      strcat (Dummy, Hold);
      strcat (Dummy, "VERSION\t\tEQU 1 ; Brukes i Snapshot\n");
      strcat (Dummy, "REVISION\tEQU 1\n\n");
      sprintf (Hold, "version\tMACRO\n\tdc.b\t'v%s'\n", Version);
      strcat (Dummy, Hold);
      strcat (Dummy, "\tIFD DEMO\n\tdc.b\t' (demo)'\n\tENDC\n\tENDM\n\n");
      strcat (Dummy, "\tENDC\t; FIRST_I\n");
			if (fh = Open (firstFName, MODE_NEWFILE))
			{
    		Write (fh, Dummy, strlen (Dummy));
	      Close (fh);
			}
	    else
	      printf ("\n Error opening file: '%s'!\n\n", firstFName);
    }
    else
      printf ("\n Error allocating %ld bytes!\n\n", DUMMYSIZE);
  }
  else
    printf ("\n ABBS serial number must be higher than -1!\n\n");
  CleanUp ();
}
