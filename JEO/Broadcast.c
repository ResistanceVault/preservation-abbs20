;/*
sc5 -j73 -v -O Broadcast
slink LIB:c.o+"Broadcast.o" to Broadcast LIB LIB:sc.lib LIB:JEO.lib
Copy Broadcast ABBS:Utils
Delete Broadcast.o Broadcast QUIET
quit
*/

/***************************************************************************
*									Broadcast 2.0 (17/04-93)
*
*	Sends node messages from CLI.
*
*	Usage : <nodenr> [FORCE] <text>
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
struct intermsg imsg;
struct MsgPort *rport = NULL;

int	main(int argc, char **argv);
int	HandleMsg (struct ABBSmsg *msg);
int	Setup (void);
void	Cleanup (void);

#define TEMPLATE "NR=Nodenr/A/N,F=Force/S,Text/F/A"
#define OPT_COUNT 3

char *vers = "\0$VER: Broadcast v2.0";

struct ConfigRecord *config;

int main(int argc, char **argv)
{
	int	ret = 10,n;
	struct RDArgs *RDArg;
	LONG	*result[OPT_COUNT] = {0,0,0};

	if (RDArg = ReadArgs(TEMPLATE,(long *) result,NULL)) {
		if (Setup()) {
			imsg.i_type = i_type_msg;
			imsg.i_pri = (UBYTE) result[1];
			imsg.i_franode = 0;
			strncpy ((char *) &imsg.i_msg,(char *) result[2],
					sizeof (struct intermsg) - 4 - 1); /* i_msg == 4 */

			msg.Command = Main_BroadcastMsg;
			msg.Data = (ULONG) &imsg;
			msg.UserNr = (ULONG) *result[0];
			if ((n = HandleMsg (&msg)) != Error_OK)
				printf ("Error sending node message %d\n",n);
			else
				ret = 0;

			Cleanup();
		}
		FreeArgs (RDArg);
	} else
		PrintFault(IoErr(),argv[0]);

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
			ret = 1;
		else
			printf ("Error creating message port\n");
	} else
		printf ("ABBS must be running for Broadcast to work\n");

	if (!ret)
		Cleanup();

	return (ret);
}

void Cleanup (void)
{
	if (msg.msg.mn_ReplyPort) DeleteMsgPort(msg.msg.mn_ReplyPort);
}
