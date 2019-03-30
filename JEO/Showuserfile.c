#include <bbs.h>

#include <dos/rdargs.h>

#include <proto/exec.h>
#include <proto/dos.h>

#include <stdio.h>
#include <string.h>

int	main(int argc, char **argv);
static int	dsdiff (struct DateStamp *first, struct DateStamp *last);

#ifdef __SASC
__regargs int _CXBRK(void) { return(0); }  /* Disable Lattice CTRL/C handling */
__regargs int __chkabort(void) { return(0); }  /* really */
#endif

struct UserRecord *user = NULL;

#define TEMPLATE "config/A,userfile/A"
#define OPT_COUNT 2

char *vers = "\0$VER: ShowUserfile v0.1";

int main(int argc, char **argv)
{
	BPTR	file = NULL;
	int	ret = 10,n;
	struct RDArgs *RDArg;
	LONG	*result[OPT_COUNT] = {0,0};
	struct DateStamp now;
	int	usersize	= 0;
	char	string[80];

	DateStamp (&now);

	if (RDArg = ReadArgs(TEMPLATE,(long *) result,NULL)) {
		if (file = Open ((char *) result[0],MODE_OLDFILE)) {
			n = Read (file,string,sizeof (string));
			if (n == sizeof (string))
				usersize = ((struct ConfigRecord *) &string)->UserrecordSize;
			Close (file);
			file = NULL;
		}
		if (usersize) {
			if (!(user = AllocVec (usersize,NULL)))
				printf ("Error allocating memory\n");
		} else
			printf ("Error reading file %s\n",(char *) result[0]);

		if (user && (file = Open ((char *) result[1],MODE_OLDFILE))) {
			while (TRUE) {
				n = Read (file,user,usersize);
				if (n == 0) {
					ret = 0;
					break;
				} else
					if (usersize== n)
					{
//						if ((user->LastAccess.ds_Days + 30) > now.ds_Days)
						printf ("%06d\t%d\t%s\n",user->Usernr,	user->firstuserconf[0].uc_LastRead,user->Name);
					} else
						break;

				if (SIGBREAKF_CTRL_C & SetSignal(0L,0L))
					break;
			}

			Close (file);
			file = NULL;
		} else
			printf ("Error opening file %s\n",(char *) result[0]);
		if (user)
			FreeVec (user);
		FreeArgs (RDArg);
	} else
		PrintFault(IoErr(),argv[0]);

	return (ret);
}

static int dsdiff (struct DateStamp *first, struct DateStamp *last)
{
	return (((((last->ds_Days - first->ds_Days) * 24 * 60) +
					(last->ds_Minute - first->ds_Minute)) * 60) +
					(last->ds_Tick - first->ds_Tick)/TICKS_PER_SECOND);
}
