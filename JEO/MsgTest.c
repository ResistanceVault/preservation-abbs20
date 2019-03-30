// Dette her er utklipp fra FileEditor. Kanskje du skjønner mere;

struct ABBSmsg msg;
struct MsgPort *rport = NULL;

BOOL Setup (void)
{
	BOOL ret = FALSE;

	if (FindPort (MainPortName))
	{
		if (UtilityBase = OpenLibrary ("utility.library",36))
		{
			if (msg.msg.mn_ReplyPort = CreateMsgPort())
			{
				msg.Command = Main_Getconfig;
				if (HandleMsg (&msg) || !msg.UserNr)
					printf ("Error talking to ABBS\n");
				else
				{
					config = (struct ConfigRecord *)msg.Data;
					ret = TRUE;
				}
			}
			else
				printf ("Error creating message port\n");
		}
		else
			printf ("Error opening utility.library\n");
	}
	else
		printf ("ABBS must be running for FileEditor to work\n");

	return (ret);
}

int HandleMsg (struct ABBSmsg *msg)
{
	struct MsgPort *mainport, *inport;
	struct ABBSmsg *inmsg;
	int	ret;

	inport = msg->msg.mn_ReplyPort;
	Forbid();
	if (mainport = FindPort(MainPortName))
	{
		PutMsg (mainport, (struct Message*)msg);
		Permit ();
		while (1)
		{
			if (!WaitPort(inport))
				continue;

			if (inmsg = (struct ABBSmsg *)GetMsg (inport))
				break;
		}
		ret = inmsg->Error;
	}
	else
	{
		Permit ();
		ret = Error_NoPort;
	}

	return (ret);
}

main ()
{
	struct Fileentry fentry;

	msg.Command = Main_loadfileentry;
	msg.UserNr = filedir_number;
	msg.arg = file_order;
	msg.Data = (ULONG)&fentry;
	err = HandleMsg (&msg);

	if (err != Error_OK)
		printf ("Error loading fileentry\n");
}
