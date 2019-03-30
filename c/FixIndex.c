/***************************************************************************
*									FixIndex 1.4 (23/02-95)
*
*	Recreates the index files
*
*	Usage : [USER=<userfile>] [INDEX=<indexfile>] [NRINDEX=<nrindexfile>] [CONFIG=<configfile>] [CHECK]
*
*	1.4 : - Addded KILLHIGH,FIXDUPLICATESNR, and FIXDUPLICATENAMES options.
*	1.3 : - Added CHECK option, to just check for errors, not to rewrite file
*	1.2 : - checks for abnormaly large usernumbers.
*			- Fixed bug where error allocating nrindex buffer crashed the machine
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
int	insertlogentry (struct Log_entry *index,struct Log_entry *tmplog);
int	comparestringsifull (unsigned char *string,unsigned char *string2, int length);
unsigned char upchar (unsigned char c);
static BOOL SaveCurrentUser (BPTR fil);

struct UserRecord *user = NULL;
struct Log_entry tmplog;

ULONG	users = 0;

char *vers = "\0$VER: FixIndex 1.4 (23.2.95)\n\r";	/* day,month,year */

#define TEMPLATE "USER,INDEX,NRINDEX,CONFIG,CHECK/S,KILLHIGH/S,FIXDUPLICATESNR/S,FIXDUPLICATENAMES/S"
#define OPT_COUNT 8

#define	HACKSIZEOFUSERRECORD 882
/* Husk og fiks configfile skriving også...
*/

int main(int argc, char **argv)
{
	BPTR	fil = NULL;
	int	n,maxusernr = 0,oldmaxusernr = 0,record,k;
	ULONG	*nrindex = NULL;
	struct Log_entry *index = NULL;
	struct RDArgs *RDArg;
	BOOL	DoBreak = FALSE;
	LONG	*result[OPT_COUNT] = {0,0,0,0,0,0,0,0};
	char	*userfname,*indexfname,*nrindexfname,*configfnane,*ptr;

	if (RDArg = ReadArgs(TEMPLATE,(long *) result,NULL)) {
		userfname = result[0] ? (char *) result[0] : "userfile";
		indexfname = result[1] ? (char *) result[1] : "userfile.index";
		nrindexfname = result[2] ? (char *) result[2] : "userfile.nrindex";
		configfnane = result[3] ? (char *) result[3] : "configfile";

		while (1) {
			if (FindPort(MainPortName)) {
				printf ("FixIndex won't work if abbs is running..\n");
				break;
			}

			if (!(user = AllocVec (HACKSIZEOFUSERRECORD,0L))) {
				printf ("Error allocating memory");
				break;
			}

			if (!(fil = Open (userfname,MODE_OLDFILE))) {
				printf ("Error opening userfile\n");
				break;
			}

			record = 0;
			do {
				n = Read (fil,user,HACKSIZEOFUSERRECORD);
				if (user->Usernr > maxusernr) {
					oldmaxusernr = maxusernr;
					maxusernr = user->Usernr;
				}

				if (user->Usernr > 100000) {
					printf ("Hiiiigh usernr %d for %s (%d)\n",user->Usernr,user->Name,record+1);
					if (result[5]) {
						maxusernr = oldmaxusernr;
						ptr = (char *) &user;
						for (k = 0; k < HACKSIZEOFUSERRECORD; k++)
							*ptr = '0';
						user->Usernr = record;
						sprintf (user->Name,"Kill Me%d",record);

						if (!(SaveCurrentUser (fil))) {
							DoBreak = TRUE;
							break;
						}
					}
				}

				if (n == HACKSIZEOFUSERRECORD)
					record += 1;
			} while (n == HACKSIZEOFUSERRECORD);

			if (DoBreak)
				break;

			if (!n) {
				Seek (fil,0,OFFSET_BEGINNING);
				n = IoErr();
			}

			if (n) {
				printf ("Error reading userfile\n");
				break;
			}
			maxusernr += 1;

			printf ("%d users (%d bytes), maximum users = %d\n",record,
						HACKSIZEOFUSERRECORD * record,maxusernr);

			if ((!(nrindex = AllocVec ((maxusernr * 4)+4,0))) ||
				(!(index = (struct Log_entry *) AllocVec ((maxusernr+1)  * sizeof (struct Log_entry),MEMF_CLEAR)))) {
				printf ("Error allocating memory\n");
				break;
			}

			for (n = 0; n <= maxusernr; n++)
				nrindex[n] = -1L;

			record = 0;
			n = Read (fil,user,HACKSIZEOFUSERRECORD);
			while (n == HACKSIZEOFUSERRECORD) {
				tmplog.l_RecordNr = record;
				tmplog.l_UserNr = user->Usernr;

				for (k = 0; k < users; k++) {
					if (user->Usernr == index[k].l_UserNr) {
						printf ("Duplicate usernumbers for %s. Same as %s (%d)\n",user->Name,index[k].l_Name,user->Usernr);

						if (result[6]) {
							user->Usernr = maxusernr+1;
							tmplog.l_UserNr = user->Usernr;
							if (!(SaveCurrentUser (fil))) {
								DoBreak = TRUE;
								break;
							}
							printf ("1 Usernumber crash problem fixed. Please restart\n");
							DoBreak = TRUE;
							break;
						}

/*						if (!result[4])
*/							n = 1;
					}
				}
				if (DoBreak)
					break;

				if (n == 1)
					break;

				memset (tmplog.l_Name,'\0',sizeof (NameT));
				strncpy (tmplog.l_Name,user->Name,Sizeof_NameT);
				tmplog.l_pad = 0;
				tmplog.l_UserBits = user->Userbits;

				if (insertlogentry (index,&tmplog)) {
					if (result[7]) {
						sprintf (user->Name,"Kill Me%d",record);
						if (!(SaveCurrentUser (fil))) {
							DoBreak = TRUE;
							break;
						}
						printf ("1 Username crash problem fixed. Please restart\n");
						DoBreak = TRUE;
						break;
					}
					n = 1;
					break;
				}
				record += 1;
				users += 1;

				if (strlen (user->Name) > Sizeof_NameT) {
					user->Name[Sizeof_NameT] = '\0';
					Seek (fil,-HACKSIZEOFUSERRECORD,OFFSET_CURRENT);
					if (IoErr()) {
						n = 0;
						printf ("Error fixing username\n");
					} else
						n = Write (fil,user,HACKSIZEOFUSERRECORD);
				}

				if (n == HACKSIZEOFUSERRECORD)
					n = Read (fil,user,HACKSIZEOFUSERRECORD);
			}

			if (DoBreak)
				break;

			if (n) {
				printf ("Error reading userfile\n");
				break;
			}

			for (n = 0; n <= maxusernr; n++)
				nrindex[n] = -1L;

			for (record = 0; record < users; record++) {
			nrindex[index[record].l_UserNr] = record;
/*				printf ("%s\n",index[record].l_Name);
*/			}
			Close (fil);
			fil = NULL;

/*			if (!result[4]) {
*/				if (!(fil = Open (indexfname,MODE_NEWFILE))) {
					printf ("Error creating index file\n");
					break;
				}
				n = sizeof (struct Log_entry) * users;
				if (n != Write (fil,index,n)) {
					printf ("Error writing userfile.index\n");
					break;
				}
				Close (fil);

				if (!(fil = Open (nrindexfname,MODE_NEWFILE))) {
					printf ("Error creating nrindex file\n");
					break;
				}
				if (((maxusernr * 4)+4) != Write (fil,nrindex,(maxusernr * 4)+4)) {
					printf ("Error writing userfile.nrindex\n");
					break;
				}
				Close (fil);

				if (!(fil = Open (configfnane,MODE_READWRITE))) {
					printf ("Error opening config file\n");
					break;
				}

				Seek (fil,14,OFFSET_BEGINNING);
				n = IoErr();

				if (n) {
					printf ("Error Seek'ing config file (%n)\n");
					break;
				}

				if ((4 != Write (fil,&users,4)) || (4 != Write (fil,&maxusernr,4))) {
					printf ("Error writing configfile\n");
					break;
				}
/*			}
*/			break;
		}
		FreeArgs (RDArg);
	} else
		PrintFault(IoErr(),argv[0]);

	if (user)	FreeVec (user);
	if (index)	FreeVec (index);
	if (nrindex) FreeVec (nrindex);
	if (fil)		Close (fil);

	return (0);
}

static BOOL SaveCurrentUser (BPTR fil)
{
	int	n;

	Seek (fil,-HACKSIZEOFUSERRECORD,OFFSET_CURRENT);
	if (IoErr()) {
		n = 0;
	} else {
		n = Write (fil,user,HACKSIZEOFUSERRECORD);
		if (n != HACKSIZEOFUSERRECORD)
			n = 0;
	}

	if (!n)
		printf ("Error fixing user %d,%s\n",user->Usernr,user->Name);

	return ((BOOL) n);
}


int insertlogentry (struct Log_entry *index,struct Log_entry *tmplog)
{
	int	n,l;

	n = 0;

	while (1) {
		l = comparestringsifull (index[n].l_Name,tmplog->l_Name,sizeof (NameT));
		if (!l) {
			printf ("Duplicate name %s\n",tmplog->l_Name);
			return (1);
		}
		if ((l < 0) && (*index[n].l_Name)) {
			n += 1;
			continue;
		}

		for (l = users; l >= n; l--)
			memcpy (&index[l+1],&index[l],sizeof (struct Log_entry));

		memcpy (&index[n],tmplog,sizeof (struct Log_entry));

		break;
	}

	return (0);
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
