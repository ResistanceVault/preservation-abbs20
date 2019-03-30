;/*
sc5 -j73 -v -O AddMsg
slink LIB:c.o+"AddMsg.o" to AddMsg LIB LIB:sc.lib LIB:JEO.lib
Copy AddMsg ABBS:Utils
Delete AddMsg.o AddMsg QUIET
quit
*/

/***************************************************************************
*									AddMsg 2.4a (03.05.98)
*
*	Adds messages to ABBS from CLI.
*
*	Usage : <Filename> <Conf> <Subject> [TO <name>] [FROM <name>] [[Reply <nr>] [Private]
*
*	Version 2.1 (29/05-93) :
*	Version 2.1 (26/11-93) :
*	- Usernames is not forced to uppercase
*	- Added support for from name
*	- Added support for netnames
* Version 2.4
* - Added support for ABBS v2.x
***************************************************************************/

#include <JEO:JEO.h>
#include <bbs.h>
#include <exec/ports.h>
#include <exec/memory.h>
#include <dos/dosextens.h>
#include <dos/rdargs.h>

#include <proto/exec.h>
#include <proto/dos.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#define MaxMsgSize 32768

struct ABBSmsg msg;
struct MsgPort *rport = NULL;
struct MessageRecord *msgheader = NULL;
struct MessageRecord *tmpmsgheader;
UBYTE	*message;

int	main(int argc, char **argv);
int	HandleMsg (struct ABBSmsg *msg);
int	Setup (void);
void	Cleanup (void);
int	readfile (char *filename,void *buffer,int length);
int	loadmsgheader (struct MessageRecord *msgheader, ULONG msgnr, UWORD confnr);
int	savemsgheader (struct MessageRecord *msgheader, UWORD confnr);

#define TEMPLATE "Filename/A,Conf/A,Subject/A,TO/K,FROM/K,R=Reply/K/N,P=Private/S"
#define OPT_COUNT 7

char *vers = "\0$VER: AddMsg v2.4a - 03.05.98";

struct ConfigRecord *config;

int main(int argc, char **argv)
{
	struct ConferenceRecord *confarray;
	int	n,k;
	char	*ptr,c,*curstart;
	int	confnr,tousernr,fromusernr,netmsg = 0,curbuflength;
	NameT	name;
	LONG	*result[OPT_COUNT] = {0,0,0,0,0,0,0};
	int	ret = 10;
	struct RDArgs *RDArg;

	if (RDArg = ReadArgs(TEMPLATE,(long *) result,NULL)) {
		if (Setup()) {
			while (1) {
				curstart = message;
				curbuflength = MaxMsgSize;

				msg.Command = Main_Getconfig;
				if (HandleMsg (&msg) || !msg.UserNr) {
					printf ("Error talking to ABBS\n");
					break;
				}
				config = (struct ConfigRecord *) msg.Data;

				confarray = (struct ConferenceRecord *) 
					(((int) config) + (SIZEOFCONFIGRECORD));

				k = strlen ((char *) result[1]);
				for (n = 0; n < config->Maxconferences ; n++)
				{
					if (confarray[n].n_ConfName[0])
					{
						if (!strnicmp ((char *)result[1], confarray[n].n_ConfName, k))
							break;
					}
				}

				if (n == config->Maxconferences)
				{
					printf  ("Error: Unknown conference (%s)\n",result[1]);
					break;
				}
				else if (n == 2)	// OR n = 3
				{
					printf  ("Error: Not allowed to write to this conference (%s)\n",	confarray[n].n_ConfName);
					break;
				}
				confnr = n;

/* Behandler fra brukernavn
*/
				if (result[4])
				{
					strcpy (&name[0],(char *) result[4]);
					ptr = &name[0];
					n = sizeof (NameT);
					while (*(ptr++))
						n -= 1;
					while (--n > 0)
						*(ptr++) = '\0';

					if (!stricmp ("ALL",name))
					{
						printf ("Can't add message from all!\n");
						break;
					}
					else if (!stricmp ("SYSOP",name))
						fromusernr = config->SYSOPUsernr;
					else if (strchr (name,'@'))
					{
						netmsg = 1;
						sprintf (curstart,"\x1e%s\n\0",name);
						n = strlen (curstart);
						curstart += n;
						curbuflength -= n;
						fromusernr = config->SYSOPUsernr;
					}
					else
					{
						msg.Command = Main_getusernumber;
						msg.Data = 0;
						msg.Name = name;
						n = HandleMsg (&msg);

						if (n == Error_Not_Found)
						{
							printf ("Error: Unknown FROM user (%s)\n",result[4]);
							break;
						} else if (n) {
							printf ("Error talking to ABBS\n");
							break;
						}
						fromusernr = msg.UserNr;
					}
				} else {
					fromusernr = config->SYSOPUsernr;
				}

/* Behandler til brukernavn
*/
				if (result[3]) {
					strcpy (&name[0],(char *) result[3]);
					ptr = &name[0];
					n = sizeof (NameT);
					while (*(ptr++))
						n -= 1;
					while (--n > 0)
						*(ptr++) = '\0';

					if (!stricmp ("ALL",name)) {
						tousernr = -1L;
					} else if (!stricmp ("SYSOP",name)) {
						tousernr = config->SYSOPUsernr;
					} else if (strchr (name,'@')) {
						netmsg = 1;
						sprintf (curstart,"\x1f%s\n\0",name);
						n = strlen (curstart);
						curstart += n;
						curbuflength -= n;
						tousernr = config->SYSOPUsernr;
					} else {
						msg.Command = Main_getusernumber;
						msg.Data = 0;
						msg.Name = name;
						n = HandleMsg (&msg);

						if (n == Error_Not_Found) {
							printf ("Error: Unknown TO user (%s)\n",result[3]);
							break;
						} else if (n) {
							printf ("Error talking to ABBS\n");
							break;
						}
						tousernr = msg.UserNr;
					}
				} else
					tousernr = -1L;

				n = readfile ((char *) result[0],curstart,curbuflength);
				if (n < 0) {
					PrintFault(n * -1,argv[0]);
					break;
				} else if (n == 0) {
					printf ("Error: Empty file\n");
					break;
				}

				msgheader->MsgFrom = fromusernr;
				msgheader->MsgTo = tousernr;
				strncpy (msgheader->Subject,(char *) result[2],sizeof (NameT));
				DateStamp (&msgheader->MsgTimeStamp);
				msgheader->NrBytes = n + (MaxMsgSize - curbuflength);
				n = 1; ptr = curstart;
				while (c = *ptr++)
					if (c == 0x0a)
						n += 1;

				if (netmsg)
					msgheader->NrLines = -n;
				else
					msgheader->NrLines = n;

				if ((confarray[confnr].n_ConfSW & CONFSWF_PostBox) OR
						((confarray[confnr].n_ConfSW & CONFSWF_Private) AND result[6]))
					msgheader->Security = SECF_SecReceiver;
				else
					msgheader->Security = SECF_SecNone;

				if (tousernr == -1) {
					msgheader->Security = SECF_SecNone;
					if (confarray[confnr].n_ConfSW & CONFSWF_PostBox) {
						printf ("Error: You may not write to ALL in this conference\n");
						break;
					}
				}

				msgheader->RefBy = 0;
				msgheader->RefNxt = 0;
				if (result[5]) {
					msgheader->RefTo = *result[5];
					if (loadmsgheader (tmpmsgheader,*result[5],confnr))
						break;
					if (tmpmsgheader->MsgStatus & (MSTATF_KilledByAuthor|
						MSTATF_KilledBySigop|MSTATF_KilledBySysop|MSTATF_Dontshow)) {
						printf ("Error: Original not available for reply.\n");
						break;
					} else
						msgheader->MsgTo = tmpmsgheader->MsgFrom;
				} else
					msgheader->RefTo = 0;

				msg.Command = Main_savemsg;
				msg.Data = (ULONG) message;
				msg.Name = (char *) msgheader;
				msg.UserNr = confnr*2;
				n = HandleMsg (&msg);

				if (n != Error_OK) {
					if (n == Error_NoPort)
						printf ("Error talking to ABBS\n");
					else
						printf ("Error storing message\n");
					break;
				} else {

/*
; hvis reply, les inn msgheaderen til den vi svarer på
; er refby tom, legg vår melding inn i dens refby
; ikke tom, les inn melding i refby
; repeat until refNxt er tom : Les refNxt
; legg inn i refNxt
; save;

*/
					while (result[5]) {
						if (!(n = tmpmsgheader->RefBy))
							tmpmsgheader->RefBy = msgheader->Number;
						else {
							if (loadmsgheader (tmpmsgheader,n,confnr))
								break;
							while (n = tmpmsgheader->RefNxt)
								if (loadmsgheader (tmpmsgheader,n,confnr)) {
									n = -1;
									break;
								}
							if (n == -1)
								break;	/* Vi fikk en error, fant ikke tom RefNxt */

							tmpmsgheader->RefNxt = msgheader->Number;
						}

						savemsgheader (tmpmsgheader,confnr);
						break;
					}

					printf ("Message #%d%s in %s from %s to %s stored.\n",msgheader->Number,
						((msgheader->Security & SECF_SecReceiver) ? " (Private)" : ""),
						confarray[confnr].n_ConfName,
						(fromusernr == config->SYSOPUsernr ? config->SYSOPname: (char *)	result[4]),
						(tousernr == -1 ? "ALL" : (char *)	result[3]));
					ret = 0;
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

int loadmsgheader (struct MessageRecord *msgheader, ULONG msgnr, UWORD confnr)
{
	int	n;

	msg.Command	= Main_loadmsgheader;
	msg.Data		= (ULONG) msgheader;
	msg.UserNr	= msgnr - 1;
	msg.Error	= confnr * 2;
	n = HandleMsg (&msg);

	if (n != Error_OK) {
		if (n == Error_NoPort)
			printf ("Error talking to ABBS\n");
		else
			printf ("Error reading message header\n");
	}

	return (n);
}

int savemsgheader (struct MessageRecord *msgheader, UWORD confnr)
{
	int	n;

	msg.Command	= Main_savemsgheader;
	msg.Data		= (ULONG) msgheader;
	msg.UserNr	= confnr * 2;
	n = HandleMsg (&msg);

	if (n != Error_OK) {
		if (n == Error_NoPort)
			printf ("Error talking to ABBS\n");
		else
			printf ("Error writing message header\n");
	}

	return (n);
}

int readfile (char *filename,void *buffer,int length)
{
	BPTR	file;
	int	len;
	int	ret;

	if (file = Open (filename,MODE_OLDFILE)) {
		len = Read (file,buffer, length);
		if (len == -1)
			ret = (IoErr() * -1);
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
		PutMsg(mainport, (struct Message*)msg);
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
			if (msgheader = AllocMem (2*sizeof(struct MessageRecord)+MaxMsgSize,
						MEMF_CLEAR)) {
				tmpmsgheader = msgheader + (LONG) sizeof(struct MessageRecord);
				message = (UBYTE *) ((LONG) msgheader + (LONG) 2*sizeof(struct MessageRecord));
				ret = 1;
			} else
				printf ("Error allocating memory\n");
		else
			printf ("Error creating message port\n");
	} else
		printf ("ABBS must be running for AddMsg to work\n");

	if (!ret)
		Cleanup();

	return (ret);
}

void Cleanup (void)
{
	if (msgheader) FreeMem (msgheader,2*sizeof(struct MessageRecord)+MaxMsgSize);
	if (msg.msg.mn_ReplyPort) DeleteMsgPort(msg.msg.mn_ReplyPort);
}
