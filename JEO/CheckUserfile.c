;/*
sc5 -j73 -v CheckUserfile
slink LIB:c.o+"CheckUserfile.o" to CheckUserfile LIB LIB:sc.lib LIB:JEO.lib
Copy CheckUserfile ABBS:Utils
Delete CheckUserfile.o QUIET
quit
*/


/***************************************************************************
*									CheckUserfiles 2.0 (21/03-94)
*
*	Checks index files for errors
*
*	Usage : [USER=<userfile>] [INDEX=<indexfile>] [NRINDEX=<nrindexfile>] [CONFIG=<configfile>]
*
***************************************************************************/
#include <bbs.h>

#include <exec/memory.h>
#include <dos/dos.h>
#include <dos/dosextens.h>

#include <proto/exec.h>
#include <proto/dos.h>
#include <stdio.h>
#include <string.h>

int	main(int argc, char **argv);
int	comparestringsifull (unsigned char *string,unsigned char *string2, int length);
unsigned char upchar (unsigned char c);
int	getfilelen (char *name);

char *vers = "\0$VER: CheckUserfiles 2.0 (21.3.94)\n\r";	/* day,month,year */

struct UserRecord user;
ULONG	*nrindex = NULL;
struct Log_entry *index;

#define TEMPLATE "USER,INDEX,NRINDEX,CONFIG"
#define OPT_COUNT 4

int main(int argc, char **argv)
{
	int n,k,nrsize,logsize;
	int	maxusernr = 0,users = 0,error = 0;
	BPTR	file = NULL;
	struct RDArgs *RDArg;
	LONG	*result[OPT_COUNT] = {0,0,0,0};
	char	*userfname,*indexfname,*nrindexfname,*configfnane;


	if (RDArg = ReadArgs(TEMPLATE,(long *) result,NULL)) {
		while (1) {
			userfname = result[0] ? (char *) result[0] : "userfile";
			indexfname = result[1] ? (char *) result[1] : "userfile.index";
			nrindexfname = result[2] ? (char *) result[2] : "userfile.nrindex";
			configfnane = result[3] ? (char *) result[3] : "configfile";

			k = getfilelen (userfname);
			nrsize = getfilelen (nrindexfname);
			logsize = getfilelen (indexfname);

			if (nrsize % 4)
			{
				printf ("Error in nrindex size\n");
				break;
			}

			if (logsize % (sizeof (struct Log_entry))) {
				printf ("Error in index size\n");
				break;
			}

//			if (!k || (k % (sizeof (struct UserRecord), (sizeof (struct Userconf) * 299))))
//			{
//				printf ("Error in userfile size\n");
//				break;
//			}

			if (!nrsize || !logsize) {
				printf ("Empty index file(s)\n");
				break;
			}

			if ((!(nrindex = AllocVec (nrsize+4,0))) ||
					(!(index = (struct Log_entry *) AllocVec (logsize,MEMF_CLEAR)))) {
				printf ("Error allocating memory\n");
				break;
			}

			if ((!(file = Open (nrindexfname,MODE_OLDFILE))) ||
				(nrsize != Read (file,nrindex,nrsize))) {
				printf ("Error opening/reading file\n");
				break;
			}
			Close (file); file = NULL;

			if ((!(file = Open (indexfname,MODE_OLDFILE))) ||
				(logsize != Read (file,index,logsize))) {
				printf ("Error opening/reading file\n");
				break;
			}
			Close (file); file = NULL;

			if (!(file = Open (userfname,MODE_OLDFILE))) {
				printf ("Error opening userfile\n");
				break;
			}

			nrsize /= 4;
			logsize /= sizeof (struct Log_entry);

			for (n = 0; n < nrsize; n++) {
				if (nrindex[n] == -1L)
					continue;			/* removed user */

				users += 1;
				if (index[nrindex[n]].l_UserNr > maxusernr)
					maxusernr = index[nrindex[n]].l_UserNr;

				if (index[nrindex[n]].l_UserNr != n) {
					printf ("Error: %d != %d (%s)\n",n,index[nrindex[n]].l_UserNr,index[nrindex[n]].l_Name);
					error = 1;
				}
				if (index[nrindex[n]].l_pad) {
					printf ("Warning, trash in index: %d,%s\n",n,index[nrindex[n]].l_Name);
					error = 1;
				}

				if (nrindex[n]) {
					if (comparestringsifull (index[nrindex[n]].l_Name,index[nrindex[n]-1].l_Name,sizeof (NameT)) < 0) {
						printf ("Error: Wrong sorting : (%d) %s,%s\n",nrindex[n],index[nrindex[n]].l_Name,index[nrindex[n]-1].l_Name);
						error = 1;
						break;
					}
				}

/*				if (nrindex[n] < (logsize-1)) {
					if (comparestringsifull (index[nrindex[n+1]].l_Name,index[nrindex[n]].l_Name,sizeof (NameT)) < 0) {
						printf ("Error: Wrong sorting : (%d) %s,%s\n",nrindex[n],index[nrindex[n]].l_Name,index[nrindex[n]+1].l_Name);
						error = 1;
						break;
					}
				}
*/

				SetIoErr (0);
				Seek (file,index[nrindex[n]].l_RecordNr * sizeof (struct UserRecord),OFFSET_BEGINNING);
				if (k = IoErr()) {
					printf ("Error seeking in userfile (%d) %d %d\n",k,index[nrindex[n]].l_RecordNr,index[nrindex[n]].l_RecordNr * sizeof (struct UserRecord));
					error = 1;
					break;
				}

				if (sizeof (struct UserRecord) != Read (file,&user,sizeof (struct UserRecord))) {
					printf ("Error reading userfile\n");
					error = 1;
					break;
				}

				if (index[nrindex[n]].l_UserNr != user.Usernr) {
					printf ("Error: %d != %d (%s)\n",index[nrindex[n]].l_UserNr,user.Usernr,index[nrindex[n]].l_Name);
					error = 1;
				}

				if (user.Usernr != n) {
					printf ("Error: %d != %d (%s)\n",n,user.Usernr,user.Name);
					error = 1;
				}

				if (strcmp (index[nrindex[n]].l_Name,user.Name)) {
					printf ("Error: %s != %s\n",index[nrindex[n]].l_Name,user.Name);
					error = 1;
				}
			}
			Close (file); file = NULL;

			if ((!(file = Open (configfnane,MODE_OLDFILE))) ||
				(8 != Read (file,nrindex,8))) {
				printf ("Error opening/reading config file\n");
				break;
			}

			maxusernr += 1;
			if ((users != nrindex[0]) || (maxusernr != nrindex[1])) {
				printf ("Error in configfile\n");
				break;
			}

			if (!error)
				printf ("Everything seams to be ok with the index files\n");
			break;
		}

		if (file)  Close (file);
		if (index) FreeVec (index);
		if (nrindex) FreeVec (nrindex);
		FreeArgs (RDArg);
	} else
		PrintFault(IoErr(),argv[0]);
}

int getfilelen (char *name)
{
	int	ret = 0;
	BPTR	lock;
	struct FileInfoBlock *fib;

	if (fib = AllocDosObject (DOS_FIB,NULL)) {
		if (lock = Lock (name,ACCESS_READ)) {
			if (Examine (lock,fib))
				ret = fib->fib_Size;
			UnLock (lock);
		}
		FreeDosObject (DOS_FIB,fib);
	}

	return (ret);
}

/*******************************
;result = comparestringsifull (streng,streng1,length)
;Zero bit		       a0.l   a1.l    d0.w
*******************************/

int comparestringsifull (unsigned char *string,unsigned char *string2, int length)
{
	unsigned char c,d;

	while (--length > 0) {
		c = upchar (*(string++));
		d = upchar (*(string2++));

		if (c == d)
			continue;

		if (c > d)
			return (1);

		if (c < d)
			return (-1);
	}

	return (0);
}

unsigned char upchar (unsigned char c)
{
	if (c < 'a')
		return (c);

	if (c <= 'z')
		return ((unsigned char) (c - 32));

	if (c < 0xe0)
		return (c);

	return ((unsigned char) (c - 32));
}
