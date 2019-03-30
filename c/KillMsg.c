/***************************************************************************
*									KillMsg 0.1 (14/04-95)
*
*	Kills messages from ABBS "forever".
*
*	Usage : Conf/A,NR=Number/N/A
*
***************************************************************************/
#include <bbs.h>

#include <exec/ports.h>
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
int	savemsgheader (struct MessageRecord *msgheader, UWORD confnr);

#define TEMPLATE "Conf/A,NR=Number/N/A"
#define OPT_COUNT 2

char *vers = "\0$VER: KillMsg v0.1";

struct ConfigRecord *config;

int main(int argc, char **argv)
{
	int	n,k;
	int	confnr;
	LONG	*result[OPT_COUNT] = {0,0};
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
				for (n = 0; n < config->Maxconferences; n++)
					if (*(config->firstconference[n].n_ConfName))
						if (!strnicmp ((char *) result[0],config->firstconference[n].n_ConfName,k))
							break;

				if (n == config->Maxconferences) {
					printf  ("Error: Unknown conference (%s)\n",result[0]);
					break;
				} else if (n == 2 || n == 3) {
					printf  ("Error: Not allowed to kill in this conference (%s)\n",
							config->firstconference[n].n_ConfName);
					break;
				}
				confnr = n;

				if (n = loadmsgheader (&msgheader,*result[1],confnr)) {
					printf ("Error loading message %s:%d (%d)\n",
						config->firstconference[confnr].n_ConfName,*result[1],n);
					break;
				}

				if (msgheader.MsgStatus & MSTATF_Dontshow) {
					printf ("Error: Message already killed\n");
					break;
				}

				printf ("%s:#%d subj:%s\n",
					config->firstconference[confnr].n_ConfName,msgheader.Number,
					msgheader.Subject);

				msgheader.MsgStatus |= MSTATF_Dontshow;

				if (n = savemsgheader (&msgheader,confnr))
					printf ("Error saving message %s:%d (%d)\n",
						config->firstconference[confnr].n_ConfName,msgheader.Number,n);

				ret = 0;

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

	if (n == Error_NoPort)
		printf ("Error talking to ABBS\n");

	return (n);
}

int savemsgheader (struct MessageRecord *msgheader, UWORD confnr)
{
	int	n;

	msg.Command	= Main_savemsgheader;
	msg.Data		= (ULONG) msgheader;
	msg.UserNr	= confnr * 2;
	n = HandleMsg (&msg);

	if (n == Error_NoPort)
		printf ("Error talking to ABBS\n");

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

int Setup (void)
{
	int	ret = 0;

	if (FindPort (MainPortName)) {
		if (msg.msg.mn_ReplyPort = CreateMsgPort())
			ret = 1;
		else
			printf ("Error creating message port\n");
	} else
		printf ("ABBS must be running for KillMsg to work\n");

	if (!ret)
		Cleanup();

	return (ret);
}

void Cleanup (void)
{
	if (msg.msg.mn_ReplyPort) DeleteMsgPort(msg.msg.mn_ReplyPort);
}
