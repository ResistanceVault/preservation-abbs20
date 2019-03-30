;/*
sc5 -j73 -v -O FindUnread
slink LIB:c.o+"FindUnread.o" to FindUnread LIB LIB:sc.lib LIB:JEO.lib
Copy FindUnread ABBS:Utils
Delete FindUnread.o FindUnread QUIET
quit
*/

/***************************************************************************
*									FindUnread 0.2 (06.10.98)
*
*	Finds unread messages in conferenes.
*
*	Usage : <Conf>
*
*
***************************************************************************/
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

struct ABBSmsg msg;
struct MsgPort *rport = NULL;
struct MessageRecord msgheader;

int	main(int argc, char **argv);
int	HandleMsg (struct ABBSmsg *msg);
int	Setup (void);
void	Cleanup (void);
int	loadmsgheader (struct MessageRecord *msgheader, ULONG msgnr, UWORD confnr);

#define TEMPLATE "Conf/A"
#define OPT_COUNT 1

char *vers = "\0$VER: FindUnread v0.2 - 06.10.98";

struct ConfigRecord *config;

int main(int argc, char **argv)
{
	int	n, k, j;
	int	confnr;
	LONG	*result[OPT_COUNT] = {0};
	int	ret = 10;
	struct RDArgs *RDArg;

	if (RDArg = ReadArgs(TEMPLATE,(long *) result,NULL)) {
		if (Setup()) {
			while (1) {
				msg.Command = Main_Getconfig;
				if (HandleMsg (&msg) || !msg.UserNr) {
					printf ("Error talking to ABBS\n");
					break;
				}
				config = (struct ConfigRecord *) msg.Data;

				k = strlen ((char *) result[0]);
				for (n = 0; n < config->Maxconferences ; n++)
				{
					if (*config->firstconference[n].n_ConfName)
					{
						if (!strnicmp ((char *) result[0], config->firstconference[n].n_ConfName, k))
							break;
					}
				}

				if (n == config->Maxconferences)
				{
					printf  ("Error: Unknown conference (%s)\n",result[0]);
					break;
				}
				confnr = n;

				printf ("\nConfnr = %ld, maxmsg = %ld\n\n", confnr, 
					config->firstconference[confnr].n_ConfDefaultMsg);

				for (n = 1, j = 0; n < config->firstconference[confnr].n_ConfDefaultMsg; n++)
				{
					if (k = loadmsgheader (&msgheader,n,confnr))
					{
						printf ("Error loading message %d (%d)\n",n,k);
						break;
					}
					if (msgheader.MsgStatus & (MSTATF_KilledByAuthor|
						MSTATF_KilledBySigop|MSTATF_KilledBySysop|
						MSTATF_Dontshow|MSTATF_MsgRead|MSTATF_Moved))
						continue;

					if (msgheader.MsgTo == -1)
						continue;

					if (j == 15)
					{
						j = 0;
						printf ("\n");
					}
					else
						j++;
					printf ("%ld ", n);
				}
				printf ("\n");
				break;
			}
			Cleanup();
		}
		FreeArgs (RDArg);
	}
	else
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
			ret = 1;
		else
			printf ("Error creating message port\n");
	} else
		printf ("ABBS must be running for FindUnread to work\n");

	if (!ret)
		Cleanup();

	return (ret);
}

void Cleanup (void)
{
	if (msg.msg.mn_ReplyPort) DeleteMsgPort(msg.msg.mn_ReplyPort);
}
