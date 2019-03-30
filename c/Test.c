#include <JEO:JEO.h>
#include <bbs.h>
#include <dos/dos.h>
#include <proto/exec.h>
#include <proto/dos.h>

UBYTE newpw[14];
UBYTE oldpw[14];

struct UserRecord user;

VOID main (int argc, char **argv)
{
	int n;
	char	*ptr, *ptr2;

	memset (newpw, '\0' , sizeof (newpw));
	memset (oldpw, '\0' , sizeof (oldpw));
	strcpy (oldpw, argv[1]);

	if (!(ACrypt (newpw, oldpw, "1 1")))
		printf ("Acrypt failed for user %s\n", "Jan_Erik Olausen");
	printf ("%s\n", newpw);

	ptr = newpw;
	ptr2 = oldpw;
	for (n = 0; n < sizeof (PassT); n++)
		*(ptr2++) = *(ptr++);
//	user.pass_10 = *(ptr++);
//	user.pass_11 = *(ptr++);
}
