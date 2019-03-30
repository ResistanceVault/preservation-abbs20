;/*
sc5 -j73 -v -O FixIndex
slink LIB:c.o+"FixIndex.o" to FixIndex LIB LIB:sc.lib LIB:JEO.lib
Copy FixIndex ABBS:Utils
quit
*/

/***************************************************************************
*									FixIndex 2.00 (16.10.97)
*
*	Recreates the index files
*
* 2.00:  Works only with ABBS v2.x.
*	1.4 :  Addded KILLHIGH,FIXDUPLICATESNR, and FIXDUPLICATENAMES options.
*	1.3 :  Added CHECK option, to just check for errors, not to rewrite file
*	1.2 :  checks for abnormaly large usernumbers.
*	  		 Fixed bug where error allocating nrindex buffer crashed the machine
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
int	insertlogentry (struct Log_entry *index, struct Log_entry *tmplog);
int	comparestringsifull (unsigned char *string,unsigned char *string2, int length);
unsigned char upchar (unsigned char c);
static BOOL SaveCurrentUser (BPTR fil);

struct UserRecord *user = NULL;
struct Log_entry tmplog;

ULONG	users = 0;
char *vers = "\0$VER: FixIndex 2.00 - 17.10.97";
LONG user_size;

#define TEMPLATE "CHECK/S,KILLHIGH/S,FIXDUPLICATESNR/S,FIXDUPLICATENAMES/S"
#define OPT_COUNT 4

int main (int argc, char **argv)
{
	BPTR fil;
	int	n, maxusernr = 0, oldmaxusernr = 0, record, k;
	ULONG	*nrindex = NULL;
	struct Log_entry *index = NULL;
	BOOL	DoBreak = FALSE;
	char	userfname[50], indexfname[50], nrindexfname[50], configfname[50], *ptr;
	LONG	*result[OPT_COUNT] = {0,0,0,0};
	struct RDArgs *RDArg;

	if (FindPort (MainPortName))
	{
		printf ("\n  FixIndex won't work if ABBS is running...\n\n");
		return (0);
	}

	strcpy (userfname, "abbs:config/userfile");
	strcpy (indexfname, "abbs:config/userfile.index");
	strcpy (nrindexfname, "abbs:config/userfile.nrindex");
	strcpy (configfname, "abbs:config/configfile");

	if (RDArg = ReadArgs(TEMPLATE,(long *) result,NULL))
	{
		if (fil = Open (configfname, MODE_OLDFILE))
		{
			Seek (fil, 6, OFFSET_BEGINNING);
			n = IoErr();
			if (!n)	// Error seeking
			{
				if (4 == Read (fil, &user_size, 4))
				{
					Close (fil);
// ********************************************************************
//                       Start på main rutiner
// ********************************************************************
					while (1)
				  {
						if (!(user = AllocVec (user_size, NULL)))
						{
							printf ("Error allocating memory");
							break;
						}

						if (!(fil = Open (userfname, MODE_OLDFILE)))
						{
							printf ("Error opening userfile\n");
							break;
						}

						record = 0;
						do
						{
							n = Read (fil, user, user_size);
							if (user->Usernr > maxusernr)
							{
								oldmaxusernr = maxusernr;
								maxusernr = user->Usernr;
							}
//							printf ("%3ld: '%s'\n", user->Usernr, user->Name);

							if (user->Usernr > 100000)
							{
								printf ("Hiiiigh usernr %d for %s (%d)\n",user->Usernr, user->Name, record + 1);
								if (result[1])
								{
									maxusernr = oldmaxusernr;
									ptr = (char *) &user;
									for (k = 0; k < user_size; k++)
										*ptr = '0';
									user->Usernr = record;
									sprintf (user->Name,"Kill Me%d",record);

									if (!(SaveCurrentUser (fil))) {
										DoBreak = TRUE;
										break;
									}
								}
							}

							if (n == user_size)
								record += 1;
						} while (n == user_size);

						if (DoBreak)
							break;

						if (!n)
						{
							Seek (fil,0,OFFSET_BEGINNING);
							n = IoErr();
						}

						if (n)
						{
							printf ("Error reading userfile\n");
							break;
						}
						maxusernr += 1;

						printf ("%d users (%d bytes), maximum user number = %d\n",record,	user_size * record, maxusernr);

						if ((!(nrindex = AllocVec ((maxusernr * 4)+4,0))) ||
							(!(index = (struct Log_entry *) AllocVec ((maxusernr+1)  * sizeof (struct Log_entry),MEMF_CLEAR))))
						{
							printf ("Error allocating memory\n");
							break;
						}

						for (n = 0; n <= maxusernr; n++)
							nrindex[n] = -1L;

						record = 0;
						n = Read (fil, user, user_size);
						while (n == user_size)
						{
							tmplog.l_RecordNr = record;
							tmplog.l_UserNr = user->Usernr;

							for (k = 0; k < users; k++)
							{
								if (user->Usernr == index[k].l_UserNr)
								{
									printf ("Duplicate usernumbers for %s. Same as %s (%d)\n", user->Name, index[k].l_Name, user->Usernr);
									if (result[2])
									{
										user->Usernr = maxusernr+1;
										tmplog.l_UserNr = user->Usernr;
										if (!(SaveCurrentUser (fil)))
										{
											DoBreak = TRUE;
											break;
										}
										printf ("1 Usernumber crash problem fixed. Please restart\n");
										DoBreak = TRUE;
										break;
									}
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

							if (insertlogentry (index, &tmplog))
							{
								if (result[3])
								{
									sprintf (user->Name, "KILL ME_%d",record);
									if (!(SaveCurrentUser (fil)))
									{
										DoBreak = TRUE;
										break;
									}
									printf ("Username crash problem fixed. Please restart\n");
									DoBreak = TRUE;
									break;
								}
								n = 1;
								break;
							}
							record += 1;
							users += 1;

							if (strlen (user->Name) > Sizeof_NameT)
							{
								user->Name[Sizeof_NameT] = '\0';
								Seek (fil,-user_size,OFFSET_CURRENT);
								if (IoErr())
								{
									n = 0;
									printf ("Error fixing username\n");
								}
								else
									n = Write (fil,user,user_size);
							}

							if (n == user_size)
								n = Read (fil,user,user_size);
						}

						if (DoBreak)
							break;

						if (n)
						{
							printf ("Error reading userfile\n");
							break;
						}

						for (n = 0; n <= maxusernr; n++)
							nrindex[n] = -1L;

						for (record = 0; record < users; record++)
						{
							nrindex[index[record].l_UserNr] = record;
//							printf ("%s\n",index[record].l_Name);
						}
						Close (fil);

						if (!(fil = Open (indexfname, MODE_NEWFILE)))
						{
							printf ("Error creating index file\n");
							break;
						}
						n = sizeof (struct Log_entry) * users;
						if (n != Write (fil,index,n))
						{
							printf ("Error writing userfile.index\n");
							break;
						}
						Close (fil);

						if (!(fil = Open (nrindexfname,MODE_NEWFILE)))
						{
							printf ("Error creating nrindex file\n");
							break;
						}
						if (((maxusernr * 4)+4) != Write (fil,nrindex,(maxusernr * 4)+4))
						{
							printf ("Error writing userfile.nrindex\n");
							break;
						}
						Close (fil);

						if (!(fil = Open (configfname,MODE_READWRITE)))
						{
							printf ("Error opening config file\n");
							break;
						}

						Seek (fil, 14, OFFSET_BEGINNING);
						n = IoErr();

						if (n)
						{
							printf ("Error seek'ing configfile (%n)\n");
							break;
						}

						if ((4 != Write (fil,&users,4)) || (4 != Write (fil,&maxusernr,4)))
						{
							printf ("Error writing configfile\n");
							break;
						}
						break;
					}
				}
				else
					printf ("\n Error reading file %s!\n\n", configfname);
			}
			else
				printf ("\n Error seeking in configfile!\n\n");
		}
		else
			printf ("\n Error opening file %s! \n\n", configfname);

		FreeArgs (RDArg);
	}
	else
		PrintFault(IoErr(),argv[0]);	

	if (user)	FreeVec (user);
	if (index)	FreeVec (index);
	if (nrindex) FreeVec (nrindex);
	if (fil) Close (fil);

	return (0);
}

static BOOL SaveCurrentUser (BPTR fil)
{
	int	n;

	Seek (fil,-user_size,OFFSET_CURRENT);
	if (IoErr()) {
		n = 0;
	} else {
		n = Write (fil,user,user_size);
		if (n != user_size)
			n = 0;
	}

	if (!n)
		printf ("Error fixing user %d,%s\n",user->Usernr,user->Name);

	return ((BOOL) n);
}


int insertlogentry (struct Log_entry *index, struct Log_entry *tmplog)
{
	int	n,l;

	n = 0;

	while (1)
	{
		l = comparestringsifull (index[n].l_Name,tmplog->l_Name,sizeof (NameT));
		if (!l)
		{
			printf ("ERROR: Duplicate name: '%s' found in userfile!\n",tmplog->l_Name);
			return (1);
		}
		if ((l < 0) && (*index[n].l_Name))
		{
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
