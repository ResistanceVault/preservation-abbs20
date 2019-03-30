#include <JEO:JEO.h>
#include <exec/ports.h>
#include <exec/memory.h>
#include <exec/nodes.h>
#include <bbs.h>

struct ABBSmsg msg;

void Cleanup (void)
{
	if (msg.msg.mn_ReplyPort)
		DeleteMsgPort (msg.msg.mn_ReplyPort);
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
	BOOL ret = FALSE;

	if (FindPort (MainPortName))
	{
		if (msg.msg.mn_ReplyPort = CreateMsgPort())
			ret = TRUE;
		else
			printf ("PORT ERROR...\n");
	}
	else
		printf ("ABBS must be running for Usereditor to work\n");

	if (!ret)
		Cleanup();

	return (ret);
}

main ()
{
	int	n;

	if (Setup ())
	{
		msg.Command	= Main_DeleteConference;
		msg.Name		= curuser.Name;
		msg.Data		= (ULONG) &curuser;
		msg.arg		= 0;
		n = HandleMsg (&msg);

		if (n != Error_OK)
			EasyRequestArgs (NULL, &saveerrorreq, NULL,NULL);
}
