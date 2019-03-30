#include <JEO:JEO.h>
#include <proto/dos.h>
#include <proto/utility.h>
#include <exec/memory.h>

//void Amiga2Date( unsigned long seconds, struct ClockData *result );
//ULONG Date2Amiga( struct ClockData *date );

struct ClockData *cd = 0;

main ()
{
	ULONG t = 8034;

	cd = AllocMem (sizeof (struct ClockData), MEMF_CLEAR);

	cd->sec = 0;
	cd->min = 0;
	cd->hour = 0;
	cd->mday = 5;
	cd->month = 1;
	cd->year = 2000;

	t = Date2Amiga (cd);
	printf ("t = %ld\n\n", t);

	Amiga2Date (4294967295, cd);

	printf ("%02ld:%02ld:%02ld\n", cd->hour, cd->min, cd->sec);
	printf ("%02ld %02ld %02ld %02ld\n", cd->mday, cd->month, cd->year, cd->wday);

	FreeMem (cd, sizeof (struct ClockData));
}
