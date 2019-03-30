;/*
sc5 -L -j73 -v -O FixFileInfo.c
copy FixFileInfo ABBS:Utils/
quit
*/

char *vers = "\0$VER: FixFileInfo v1.00a - 03.05.98";
char Ver[] = "1.00a";

#include <JEO:JEO.h>
#include <exec/memory.h>
#include <exec/execbase.h>
#include <proto/dos.h>
#include <bbs.h>
#include <ctype.h>

int HandleMsg (struct ABBSmsg *msg);

WORD dir_order, dir_number;
WORD file_order;
struct MessageRecord *msg_head = 0;
char *Dummy = 0;
struct Fileentry tempfentry, fentry;	// Føre vi forandrer noe...
struct ABBSmsg msg;

struct ConfigRecord *config;
struct Library *UtilityBase = NULL;

VOID CleanUp (VOID)
{
	if (msg.msg.mn_ReplyPort)
		DeleteMsgPort (msg.msg.mn_ReplyPort);

	if (UtilityBase)
		CloseLibrary (UtilityBase);

	if (Dummy)
		FreeMem (Dummy, 5000);
	if (msg_head)
		FreeMem (msg_head, sizeof (struct MessageRecord));
	exit (0);
}

BOOL SaveFileEntry (VOID)
{
	int err;
	BOOL ret;

	msg.Command = Main_savefileentry;
	msg.UserNr = dir_number;
	msg.arg = file_order;
	msg.Data = (ULONG)&fentry;
	err = HandleMsg (&msg);
	if (err == Error_OK)
		ret = TRUE;
	else
	{
		printf ("\n  Error saving '%s'", fentry.Filename);
		ret = FALSE;
	}
	return (ret);
}

int Load_fentry (VOID)
{
	int err;

	msg.Command = Main_loadfileentry;
	msg.UserNr = dir_number;
	msg.arg = file_order;
	msg.Data = (ULONG)&fentry;
	err = HandleMsg (&msg);
	return (err);
}

VOID Do_fl (char *Name)
{
	UWORD i;

	for (i = 0; Name[i] != 0; i++)
	{
		if (Name[i] == '/')
			Name[i] = ' ';
	}
}

BOOL Find_dir (char *Name)
{
	int n;
	struct FileDirRecord *dirarray;

	dirarray = (struct FileDirRecord *)
			(((int) config) + (SIZEOFCONFIGRECORD) +
			(config->Maxconferences * sizeof (struct ConferenceRecord)));

	for (n = 0; n < config->MaxfileDirs; n++)
	{
		if (!(stricmp (dirarray[n].n_DirName, Name)))
			return (TRUE);	// Found!
	}
	return (FALSE);
}

BOOL Setup (void)
{
	BOOL ret = FALSE;

	if (!(Dummy = AllocMem (5000, MEMF_CLEAR)))
		return (FALSE);
	if (!(msg_head = AllocMem (sizeof (struct MessageRecord), MEMF_CLEAR)))
		return (FALSE);
 
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

BOOL Find_file (UBYTE *Name)
{
	UWORD r, n;
	int err;
	ULONG matchbuffer[1024/4];
	struct Fileentry fl;

	for (n = 0; n < config->MaxfileDirs; n++)
	{
		if (*(config->firstFileDirRecord[n].n_DirName))	// Finnes filedirret?
		{
			r = config->firstFileDirRecord[n].n_FileOrder - 1;
			msg.Command = Main_findfile;
			msg.Name = Name;
			msg.arg = (ULONG)matchbuffer;	// am_Arg4
			matchbuffer[2] = 0;
			msg.UserNr = r;								// am_Arg3
			msg.Data = (ULONG)&fl;
			err = HandleMsg (&msg);
			if (err == Error_OK)	// Fila funnet?
			{
				dir_number = n;
				file_order = msg.UserNr;
				Load_fentry ();
				return (TRUE);
			}
		}
	}
	return (FALSE);
}

VOID Do_Subject (char *Subject)
{
	UBYTE i;

	for (i = 0; Subject[i] != 0; i++) 
	{
		if (Subject[i] == ' ')
			break;
	}
	Subject[i] = 0;
}

BOOL Load_msgheader (UWORD confnr, UWORD msg_nr)
{
	int err;
	BOOL ret;

	msg.Command = Main_loadmsgheader;
	msg.UserNr = msg_nr - 1;
	msg.Error = confnr * 2;
	msg.Data = (ULONG)msg_head;
	err = HandleMsg (&msg);
	if (err == Error_OK)
		ret = TRUE;
	else
	{
		printf ("\n  Error loading msgheader (%ld)!\n\n", msg.Error);
		ret = FALSE;
	}
	return (ret);
}

VOID main (int argc, char **argv)
{
	LONG confnr, i;
	ULONG count = 0;
	BOOL go_flag;
	char Filename[19];
	char Subject[31];
	BOOL kill_flag;

	if (argc != 2)
	{
		printf ("FixFileInfo v%s by Jan Erik Olausen\n\n  Usage: FixFileInfo <FileName>\n\n", Ver);
		exit (10);
	}

	if (strlen (argv[1]) > 18)
	{
		printf ("\nError: Filename (%s) too long!\n\n", argv[1]);
		exit (10);
	}
	if (Setup ())
	{
		strcpy (Filename, argv[1]);
		go_flag = TRUE;
		while (go_flag)
		{
			if (Find_file (argv[1]))
			{
				confnr = 3;	// Standard FILEINFO
				if (fentry.Filestatus & FILESTATUSF_PrivateConfUL)	// Privat til konf?
					confnr = fentry.PrivateULto / 2;	// JA!
				if (fentry.Infomsgnr == 0)	// Ikke lagt inn noe
				{
					fentry.Infomsgnr = config->firstconference[confnr].n_ConfDefaultMsg;
					// går ut i fra den siste
					for (i = fentry.Infomsgnr; i >= fentry.Infomsgnr - 5; i--)
					{
						if (!Load_msgheader (confnr, i))
							break;
						if (i < 0)
							break;

						kill_flag = FALSE;
						if (msg_head->MsgStatus & MSTATF_KilledByAuthor)
							kill_flag = TRUE;
						if (msg_head->MsgStatus & MSTATF_KilledBySysop)
							kill_flag = TRUE;
						if (msg_head->MsgStatus & MSTATF_KilledBySigop)
							kill_flag = TRUE;
						if (msg_head->MsgStatus & MSTATF_Moved)
							kill_flag = TRUE;
						if (msg_head->MsgStatus & MSTATF_Diskkilled)
							kill_flag = TRUE;
						if (msg_head->MsgStatus & MSTATF_Dontshow)
							kill_flag = TRUE;
						if (!kill_flag)	// Ikke killa
						{
							strcpy (Subject, msg_head->Subject);
							Do_Subject (Subject);
							if (!(stricmp (Subject, fentry.Filename)))
							{
								fentry.Infomsgnr = i;
								printf ("\n  Adding fileinfo to '%s' in conference: %s.\n\n", argv[1], config->firstconference[confnr].n_ConfName);
								SaveFileEntry ();
								break;
							}
						}
					}
				}
				go_flag = FALSE;	// Vi avslutter
			}
			else
			{
				if (count < 12)
				{
					Delay (60 * 5);	// 5 sekunder føre neste sjekk
					count++;
				}
				else	// Vi gidder ikke mere
				{
					printf ("\n  File '%s' not found\n\n", argv[1]);
					go_flag = FALSE;	// Vi avslutter
				}
			}
		}
	}
	CleanUp ();
}
