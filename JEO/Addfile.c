;/*
sc5 -j73 -v -O AddFile
slink LIB:c.o+"AddFile.o" to AddFile LIB LIB:sc.lib LIB:JEO.lib
Copy AddFile ABBS:Utils
Delete AddFile.o AddFile QUIET
quit
*/

/***************************************************************************
*									AddFile 2.9a (06.05.98)
*
*	Adds messages to ABBS from CLI.
*
*	Usage : FILE/A,AS/A,DIR/K,P=Private/K,C=Conf/K,I=Info/K,FREE/S,MOVE/S,
*				FROM/K,NOCOPY/S,DESC/A/F
*
***************************************************************************/
#include <bbs.h>

#include <exec/ports.h>
#include <exec/memory.h>
#include <dos/dosextens.h>
#include <dos/rdargs.h>
#include <dos/exall.h>

#include <proto/exec.h>
#include <proto/dos.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#define ExallBufSize 4096
#define MaxMsgSize 32768
#define CopyBufSize 65536
#define CopyBuf message

UBYTE	*message;
UBYTE *exallbuf = NULL;
struct ABBSmsg msg;
struct MsgPort *rport = NULL;
struct ConfigRecord *config;
struct MessageRecord *msgheader;
struct Fileentry *filentry = NULL;
struct ExAllControl *exallctrl = NULL;
struct ExAllData *exdata;

int	main(int argc, char **argv);
int	HandleMsg (struct ABBSmsg *msg);
int	Setup (void);
void	Cleanup (void);
int	readfile (char *filename,void *buffer,int length);
int instfile (char *path,char *name,int size,char *bbsname,ULONG privateto,
			UWORD filedir, char *description, char *fileinfo,int free,int move,
			int fromusernr,BOOL NoCopy);
int	copyfile (char *destname,char *sourcename);

#define TEMPLATE "FILE/A,AS/A,DIR/K,P=Private/K,C=Conf/K,I=Info/K,FREE/S,MOVE/S,FROM/K,NOCOPY/S,DESC/A/F"
#define OPT_COUNT 11

char *vers = "\0$VER: AddFile 2.9a (06.05.98)\n\r";	/* day,month,year */

int main(int argc, char **argv)
{
	int	ret = 10,n,k;
	int	privateto = -1,filedir,fromusernr,iswild;
	char	*ptr,*desc;
	BPTR	lock;
	struct RDArgs *RDArg;
	LONG	*result[OPT_COUNT] = {0,0,0,0,0,0,0,0,0,0,0};
	NameT	name;
	char	pattern[80];
	char	path[80];
	struct FileDirRecord *dirrecord;

	if (RDArg = ReadArgs(TEMPLATE,(long *) result,NULL)) {
		if (Setup()) {
			while (1) {

/*				printf ("file = %s, to = %s dir = %s, Private = %s, Conf = %s,"
							" Info = %s, FREE = %d, Descr = %s\n",
						(char *) result[0],(char *) result[1],(char *) result[2],
						(char *) result[3],(char *) result[4],(char *) result[5],
						result[6],(char *) result[10]);
				break;
*/
				desc = (char *) result[10];
				if (*desc == '"')
					desc += 1;

				n = strlen(desc)-1;
				if (n > 0) {
					if (desc[n] == '"')
						desc[n] = 0;
				}

				if (result[2] && !strlen ((char *) result[2])) result[2] = 0;
				if (result[3] && !strlen ((char *) result[3])) result[3] = 0;
				if (result[4] && !strlen ((char *) result[4])) result[4] = 0;
				if (result[5] && !strlen ((char *) result[5])) result[5] = 0;

/* Prevent private to user and conference at the same time
*/
				if (result[3] && result[4]) {
					printf ("Error: Can't have both private to user and conference!\n");					
					break;
				}

				if (strchr ((char *) result[0],' ') || strchr ((char *) result[1],' ')) {
					printf ("Space in filename is not allowed\n");
					break;
				}

/* Get access to config structure
*/
				msg.Command = Main_Getconfig;
				if (HandleMsg (&msg) || !msg.UserNr) {
					printf ("Error talking to ABBS\n");
					break;
				}
				config = (struct ConfigRecord *) msg.Data;

/* handles any private to conference
*/
				if (result[4]) {
					k = strlen ((char *) result[4]);
					for (n = 0; n < config->Maxconferences; n++)
						if (*(config->firstconference[n].n_ConfName))
							if (!strnicmp ((char *) result[4],config->firstconference[n].n_ConfName,k))
								break;

					if (n == config->Maxconferences) {
						printf  ("Error: Unknown conference (%s)\n",result[4]);
						break;
					}
					privateto = n*2;
				}

/* handles any private to user
*/
				if (result[3]) {
					strcpy (name,(char *) result[3]);
					ptr = name;
					n = sizeof (NameT);
					while (*ptr) {
						*ptr = toupper(*ptr);
						ptr += 1;
						n -= 1;
					}
					while (n-- > 0)
						*ptr++ = '\0';

					if (!strcmp ("SYSOP",name)) {
						privateto = config->SYSOPUsernr;
					} else {
						msg.Command = Main_getusernumber;
						msg.Data = 0;
						msg.Name = name;
						n = HandleMsg (&msg);

						if (n == Error_Not_Found) {
							printf ("Error: Unknown user (%s)\n",result[3]);
							break;
						} else if (n) {
							printf ("Error talking to ABBS\n");
							break;
						} else {
							privateto = msg.UserNr;
						}
					}
				}

/* Behandler fra brukernavn
*/
				if (result[8]) {
					strcpy (&name[0],(char *) result[8]);
					ptr = &name[0];
					n = sizeof (NameT);
					while (*(ptr++))
						n -= 1;
					while (--n > 0)
						*(ptr++) = '\0';

					if (!stricmp ("ALL",name)) {
						printf ("Can't add file from all!\n");
						break;
					} else if (!stricmp ("SYSOP",name)) {
						fromusernr = config->SYSOPUsernr;
					} else if (strchr (name,'@')) {
						printf ("Can't add file from net user!\n");
						break;
					} else {
						msg.Command = Main_getusernumber;
						msg.Data = 0;
						msg.Name = name;
						n = HandleMsg (&msg);

						if (n == Error_Not_Found) {
							printf ("Error: Unknown FROM user (%s)\n",result[8]);
							break;
						} else if (n) {
							printf ("Error talking to ABBS\n");
							break;
						}
						fromusernr = msg.UserNr;
					}
				} else
					fromusernr = config->SYSOPUsernr;

/* Handle filedir (if not private to user)
*/
				dirrecord = config->firstFileDirRecord;

				if (result[2] && !result[3]) {
					k = strlen ((char *) result[2]);
						for (n = 0; n < config->MaxfileDirs; n++)
							if (*(dirrecord[n].n_DirName))
								if (!strnicmp ((char *) result[2],dirrecord[n].n_DirName,k))
									break;

						if (n == config->MaxfileDirs) {
							printf  ("Error: Unknown filedir (%s)\n",result[2]);
							break;
						} else if (n == 0) {
							printf ("Error: Can't install into Private.\n");
							break;
						}
						filedir = n;
				} else
					filedir = (result[3] ? 0 : 1);

				ptr = FilePart ((char *) result[0]);
				if (!ptr || (-1 == (iswild = ParsePatternNoCase (ptr,pattern,
						sizeof (pattern))))) {
					printf ("Error parsing pattern.\n");
					break;
				}

				path[0] = '\0';
				if ((ptr = PathPart((char *) result[0])) != (char *) result[0]) {
					n = (long) ptr - (long) result[0];
					if (n > 80)
						n = 79;
					strncpy (path,(char *) result[0],n);
					path[n] = '\0';
					if (path[n-1] != ':' && path[n-1] != '/') {
						path[n] = '/';
						path[n+1] = '\0';
					}
				}

				if (!(lock = Lock(path,ACCESS_READ))) {
					printf ("Error locking source dir\n");
					break;
				}

				k = 0;
				name[0] = 0;
				exallctrl->eac_LastKey = 0;
				exallctrl->eac_MatchString = pattern;
				do {
					n = ExAll (lock,(struct ExAllData *) exallbuf,ExallBufSize,
								ED_SIZE,exallctrl);
					if (!exallctrl->eac_Entries || k)
						continue;

					exdata = (struct ExAllData *) exallbuf;
					while (exdata) {
						name[0] = 1;

						if (instfile (path,exdata->ed_Name,exdata->ed_Size,
									(iswild ? NULL : (char *) result[1]),privateto,
									filedir,desc,(char *) result[5],
									(int) result[6],(int) result[7],fromusernr,
									(BOOL) result[9])) {
							k = 1;				/* error, abort */
							exdata = NULL;
							continue;
						}
						exdata = exdata->ed_Next;
					}
				} while (n);

				if (!k)
					ret = 0;	/* Ser ut til at alt gikk bra. */

				UnLock (lock);

				if (!iswild && !name[0]) {
					printf ("Error: File not found (%s).\n",(char *) result[0]);
					ret = 10;
				}

				break;
			}
			Cleanup();
		}
		FreeArgs (RDArg);
	} else
		PrintFault(IoErr(),argv[0]);

	return (ret);
}

int instfile (char *path,char *name,int size,char *bbsname,ULONG privateto,
			UWORD filedir, char *description, char *fileinfo,int free,int move,
			int fromusernr,BOOL NoCopy)
{
	int	n,k,r;
	int	copy = 0;
	int	infomsgnr = 0;
	char	sourcename[80],destname[80],tmptext[10],*ptr,c;
	BPTR	lock1,lock2;
	struct FileDirRecord *dirrecord;

	dirrecord = config->firstFileDirRecord;

/*	printf ("path = %s, name = %s, size = %d\nbbsname = %s, privateto = %d, filedir = %d\ndescription = %s, fileinfo = %s,free = %d\n",
		path,name,size,bbsname,privateto,filedir,description,fileinfo,free);
	return (1);
*/
	if (!bbsname)
		bbsname = name;

	if (strlen (bbsname) > Sizeof_FileName) {
		bbsname[Sizeof_FileName] = '\0';
		printf ("Warning: dest name trucated to %s\n",bbsname);
	}

/* sjekker om fila finnes fra før
*/
	msg.Command = Main_findfile;
	msg.Name = bbsname;
	msg.arg = (ULONG) CopyBuf;
	for (n = 0,r = 0; r < config->ActiveDirs; n++) {
		if (*(dirrecord[n].n_DirName)) {
			msg.Data = (ULONG) filentry;
			msg.UserNr = n;
			k = HandleMsg (&msg);
			if (k != Error_Not_Found)
				break;
			r += 1;
		}
	}

	if (k == Error_OK) {
		printf ("Error: File %s already exist in abbs!\n",bbsname);
		return (1);
	}

	if (k != Error_Not_Found) {
		printf ("Error: Accessing abbs filelist\n");
		return (1);
	}

	if (!NoCopy) {
/*	 sjekke om copy trengs (ligger fila riktig ?)
	 hvis trengs, foreta copy (husk at vi tok copy)
*/
		sprintf (sourcename,"%s%s",path,name);
		strcpy (destname,dirrecord[filedir].n_DirPaths);
		n = strlen (destname);
		if (destname[n-1] != ':' && destname[n-1] != '/') {
			destname[n] = '/';
			destname[n+1] = 0;
		}
		strcat (destname,bbsname);

		lock1 = Lock (sourcename,ACCESS_READ);
		lock2 = Lock (destname,ACCESS_READ);

		if (!lock1) {
			if (lock2)
				UnLock(lock2);
			printf ("Error: locking %s\n",sourcename);
			return (1);
		}

		if (!lock2)
			n = LOCK_DIFFERENT;
		else
			n = SameLock (lock1,lock2);
		UnLock(lock1);
		if (lock2)
			UnLock(lock2);
		if (n != LOCK_SAME) {
			if ((n == LOCK_SAME_VOLUME) && move) {
				if (!(Rename (sourcename,destname))) {
					printf ("Error: moving file (%s->%s)\n",sourcename,destname);
					return (1);
				}
			} else {
				if (copyfile (destname,sourcename)) {
					printf ("Error: copying file (%s->%s)\n",sourcename,destname);
					DeleteFile (destname);
					return (1);
				}
				copy = 1;
				if (move)
					DeleteFile (sourcename);
			}
		}
		if (!(SetComment (destname,description)))
			printf ("Warning: Error setting filecomment on file %s\n",destname);
	}

/*	 Installere filinfo melding, hvis det er noen
*/
	k = 0;	/* ok */
	if (fileinfo) {
		n = readfile (fileinfo,message,MaxMsgSize);
		if (n < 0) {
			PrintFault(n * -1,"Error reading fileinfo message");
			k = 1;	/* huske at vi fikk en error */
		} else if (n == 0) {
			printf ("Error: fileinfo message file was empty\n");
			k = 1;	/* huske at vi fikk en error */
		} else {
			msgheader->MsgFrom = fromusernr;
			if ((privateto != -1) && !filedir) {
				msgheader->Security = SECF_SecReceiver;
				msgheader->MsgTo = privateto;
				msg.UserNr = 3*2;	/* Conf nr */
			} else {
				msgheader->MsgTo = -1L;
				msgheader->Security = SECF_SecNone;
				if (privateto != -1)
					msg.UserNr = privateto;	/* Conf nr */
				else
					msg.UserNr = 3*2;	/* Conf nr */
			}
			msgheader->NrBytes = n;

			n = size / 1000;
			if (n)
				sprintf (tmptext,"%d.%d",n,size % 1000);
			else
				sprintf (tmptext,"%d",size % 1000);
			sprintf (msgheader->Subject,"%s (%sb)",bbsname,tmptext);
			DateStamp (&msgheader->MsgTimeStamp);
			n = 1; ptr = message;
			while (c = *ptr++)
				if (c == 0x0a)
					n += 1;
			msgheader->NrLines = n;
			msgheader->RefBy = 0;
			msgheader->RefNxt = 0;
			msgheader->RefTo = 0;

			msg.Command = Main_savemsg;
			msg.Data = (ULONG) message;
			msg.Name = (char *) msgheader;
			n = HandleMsg (&msg);

			if (n != Error_OK) {
				if (n == Error_NoPort)
					printf ("Error talking to ABBS\n");
				else
					printf ("Error storing message\n");
				k = 1;	/* huske at vi fikk en error */
			} else
				infomsgnr = msgheader->Number;
		}
	}

/*	Fyller inn i fileentry'et
*/

	if (!k) {
		strncpy (filentry->Filename,bbsname,Sizeof_FileName);
		filentry->Filename[Sizeof_FileName] = 0;
		filentry->Fsize		= size;
		filentry->Uploader	= fromusernr;
		filentry->PrivateULto= (privateto == -1) ? 0 : privateto;
		filentry->AntallDLs  = 0;
		filentry->Infomsgnr	= infomsgnr;
		DateStamp (&filentry->ULdate);
		strncpy (filentry->Filedescription,description,Sizeof_FileDescription);
		filentry->Filedescription[Sizeof_FileDescription] = 0;

		filentry->Filestatus = (free ? FILESTATUSF_FreeDL : 0);

		if (privateto != -1) {
			if (filedir)
				filentry->Filestatus |= FILESTATUSF_PrivateConfUL;
			else
				filentry->Filestatus |= FILESTATUSF_PrivateUL;
		}

/*	add'e fila til abbs.
*/
		msg.Command = Main_addfile;
		msg.Data = (ULONG) filentry;
		msg.UserNr = filedir;
		k = HandleMsg (&msg);
	}

/*	hvis error, kill filinfo melding, slett fila hvis vi tok copy
*/
	if (k != Error_OK) {
		printf ("Error adding file %s to abbs\n",bbsname);
		if (copy)
			DeleteFile (destname);
		if (fileinfo && infomsgnr) {
			msgheader->MsgStatus |= MSTATF_KilledBySysop;
			msg.Command	= Main_savemsgheader;
			msg.Data		= (ULONG) msgheader;
			msg.UserNr	= 3 * 2;
			n = HandleMsg (&msg);
			if (n != Error_OK) {
				if (n == Error_NoPort)
					printf ("Error talking to ABBS\n");
				else
					printf ("Error killing fileinfo\n");
			}
		}
		return (1);
	}

	return (0);
}

int	copyfile (char *destname,char *sourcename)
{
	char	buff[200];

	sprintf (buff,"copy %s to %s",sourcename,destname);
	Execute (buff,NULL,NULL);

	return (0);
}

int readfile (char *filename,void *buffer,int length)
{
	BPTR	file;
	int	len;
	int	ret;

	if (file = Open (filename,MODE_OLDFILE)) {
		len = Read (file,message, length);
		if (len == -1)
			ret = IoErr()*-1;
		else
			ret = len;

		if (len == length) {
			len -= 1;
			Printf ("Warning: text file truncated\n");
		}
		((BYTE *) buffer)[len] = 0;

		Close (file);
	} else
		return (IoErr()*-1);

	return (ret);
}

int HandleMsg (struct ABBSmsg *msg)
{
	struct MsgPort *mainport,*inport;
	struct ABBSmsg *inmsg;
	int	ret;

	inport = msg->msg.mn_ReplyPort;
	Forbid();
	if (mainport = FindPort(MainPortName)) {
		PutMsg(mainport, (struct Message *)msg);
		Permit();
		while (1) {
			if (!WaitPort(inport))
				continue;

			if (inmsg = (struct ABBSmsg *) GetMsg (inport))
				break;
		}
		ret = inmsg->Error;
	} else {
		Permit();
		ret = Error_NoPort;
	}

	return (ret);
}

int Setup (void)
{
	int	ret = 0;

	if (FindPort (MainPortName)) {
		if (msg.msg.mn_ReplyPort = CreateMsgPort())
			if (filentry = AllocMem (sizeof (struct Fileentry) +
						sizeof(struct MessageRecord)+CopyBufSize,MEMF_CLEAR)) {
				msgheader = (struct MessageRecord * ) (filentry +
									(LONG) sizeof(struct Fileentry));
				message = (UBYTE *) ((LONG) msgheader + (LONG) sizeof(struct MessageRecord));

				if (exallctrl = AllocDosObject (DOS_EXALLCONTROL,NULL))
					if (exallbuf = AllocMem (ExallBufSize,0));
						ret = 1;

				if (ret != 1)
					printf ("Error allocating memory\n");
			} else
				printf ("Error allocating memory\n");
		else
			printf ("Error creating message port\n");
	} else
		printf ("ABBS must be running for AddFile to work\n");

	if (!ret)
		Cleanup();

	return (ret);
}

void Cleanup (void)
{
	if (exallbuf) FreeMem (exallbuf,ExallBufSize);
	if (exallctrl) FreeDosObject (DOS_EXALLCONTROL,exallctrl);
	if (filentry) FreeMem (filentry,sizeof (struct Fileentry) +
				sizeof(struct MessageRecord)+CopyBufSize);
	if (msg.msg.mn_ReplyPort) DeleteMsgPort(msg.msg.mn_ReplyPort);
}
