/***************************************************************************
*									Listfiles 1.0 (1/04-94)
*
*	List files from cli
*
*	Usage : 
*
***************************************************************************/
#include <bbs.h>

#include <exec/ports.h>
#include <exec/memory.h>
#include <dos/dosextens.h>
#include <dos/rdargs.h>
#include <dos/datetime.h>
#include <utility/date.h>

#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/utility.h>

#include <stdio.h>
#include <string.h>
#include <ctype.h>

struct ABBSmsg msg;
struct MsgPort *rport = NULL;
struct Library *UtilityBase = NULL;

int	main(int argc, char **argv);
int	HandleMsg (struct ABBSmsg *msg);
int	Setup (void);
void	Cleanup (void);
void	printdatestamp (struct DateStamp *ds);
unsigned char *upstring (unsigned char *string);
unsigned char upchar (unsigned char c);

#define TEMPLATE "Since/K,ToConf/S,Upcase/S,Upload/S,All/S,Check/S,Fix/S"
#define OPT_COUNT 7

char *vers = "\0$VER: ListFiles v1.0 (1.4.94)\n\r";	/* day,month,year */

struct ConfigRecord *config;

int main(int argc, char **argv)
{
	int	ret = 10,n,r,k;
	int	err,first;
	BPTR	lock;
	struct Fileentry fentry;
	char	string[160];
	struct RDArgs *RDArg;
	LONG	*result[OPT_COUNT] = {0,0,0,0,0,0,0};
	struct DateTime dt;

	if (RDArg = ReadArgs(TEMPLATE,(long *) result,NULL)) {
		if (Setup()) {
			while (1) {
				if (result[0]) {
					dt.dat_Format	= FORMAT_DOS;	/* FORMAT_DEF; */
					dt.dat_Flags	= 0;
					dt.dat_StrDate = (unsigned char *) result[0];
					dt.dat_StrTime	= NULL;
					if (!StrToDate (&dt)) {
						printf ("Error paring SINCE parameter\n");
						break;
					}
				}

				for (n = 0; n < config->ActiveDirs; n++) {
					r = config->FileOrder[n]-1;

/* Lister ikke private engang hvis vi ikke har all
*/
					if (!r && !result[4])
						continue;

/* Viser ikke upload hvis ikke all eller Upload er satt
*/
					if ((r == 1) && (!result[4] && !result[3]))
							continue;

					if (*config->DirNames[r]) {
						printf ("\n(%s)\n",config->DirNames[r]);
						first = 1;
					} else
						continue;

					for (k = 1; 1; k++) {
						msg.Command = Main_loadfileentry;
						msg.UserNr = r;
						msg.arg = k;
						msg.Data = (ULONG) &fentry;
						err = HandleMsg (&msg);

						if (err == Error_EOF)
							break;

						if (err != Error_OK) {
							printf ("Error reading fileentry\n");
							break;
						}

						if (fentry.Filestatus & (FILESTATUSF_Filemoved|FILESTATUSF_Fileremoved))
							continue;

/* Har vi all, viser vi alt. Basta
*/
						if (!result[4]) {

/* Viser ikke privat til person
*/
							if (fentry.Filestatus & FILESTATUSF_PrivateUL)
								continue;

/* Hvis ikke ToConf, tar vi ikke filer som er private til conf
*/
							if (!result[1] && (fentry.Filestatus & FILESTATUSF_PrivateConfUL))
								continue;
						}

						if (result[0])
							if (dt.dat_Stamp.ds_Days > fentry.ULdate.ds_Days)
								continue;

						if (result[5] || result[6]) {
							strcpy (string,config->DirPaths[r]);
							if (AddPart (string,fentry.Filename,160))
								if (lock = Lock (string,SHARED_LOCK)) {
									UnLock (lock);
									continue;
								}
							if (result[6]) {
								fentry.Filestatus |= FILESTATUSF_Fileremoved;
								msg.Command = Main_savefileentry;
								msg.UserNr = r;
								msg.arg = k;
								msg.Data = (ULONG) &fentry;
								err = HandleMsg (&msg);
							}
						}

						if (first) {
							printf ("\n  File name        Date     Kb Dls File description\n"
										 "  ---------        ----     -- --- ----------------\n");
							first = 0;
						}

						if (result[2])
							upstring ((unsigned char *) &fentry.Filename);

						printf ("%c %-17s",(fentry.Infomsgnr ? 'I' : ' '),fentry.Filename);
						printdatestamp (&fentry.ULdate);
						printf ("%5d %3d %-39s",fentry.Fsize/1024,fentry.AntallDLs,
							fentry.Filedescription);
						printf ("%s%s%s\n",
							((fentry.Filestatus & FILESTATUSF_PrivateUL) ? " (PrivToPerson)" : ""),
							((fentry.Filestatus & FILESTATUSF_PrivateConfUL) ? " (PrivToConf)" : ""),
							((fentry.Filestatus & FILESTATUSF_FreeDL) ? " (Free)" : ""));
					}

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

void printdatestamp (struct DateStamp *ds)
{
	int	tmp;
	struct ClockData dt;

	tmp = (ds->ds_Days*24*60 + ds->ds_Minute) * 60;
	tmp += ds->ds_Tick/TICKS_PER_SECOND;
	Amiga2Date (tmp,&dt);
	printf ("%02d%02d%02d",dt.year % 100,dt.mday,dt.month);
}

int HandleMsg (struct ABBSmsg *msg)
{
	struct MsgPort *mainport,*inport;
	struct ABBSmsg *inmsg;
	int	ret;

	inport = msg->msg.mn_ReplyPort;
	Forbid();
	if (mainport = FindPort(MainPortName)) {
		PutMsg(mainport,msg);
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
unsigned char *upstring (unsigned char *string)
{
	char	*ptr = string;

	while (*ptr) {
		*ptr = upchar (*ptr);
		ptr += 1;
	}

	return (string);
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

int Setup (void)
{
	int	ret = 0;

	if (FindPort (MainPortName)) {
		if (UtilityBase = OpenLibrary ("utility.library",36)) {
			if (msg.msg.mn_ReplyPort = CreateMsgPort()) {
/* Get access to config structure
*/
				msg.Command = Main_testconfig;
				if (HandleMsg (&msg) || !msg.UserNr) {
					printf ("Error talking to ABBS\n");
				} else {
					config = (struct ConfigRecord *) msg.Data;
					ret = 1;
				}
			} else
				printf ("Error creating message port\n");
		} else
			printf ("Error opening utility.library\n");
	} else
		printf ("ABBS must be running for Listfiles to work\n");

	if (!ret)
		Cleanup();

	return (ret);
}

void Cleanup (void)
{
	if (msg.msg.mn_ReplyPort) DeleteMsgPort(msg.msg.mn_ReplyPort);
	if (UtilityBase) CloseLibrary (UtilityBase);
}
