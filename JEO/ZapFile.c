;/*
sc5 -j73 -v -O ZapFile
slink LIB:c.o+"ZapFile.o" to ZapFile LIB LIB:sc.lib LIB:JEO.lib
Copy ZapFile ABBS:Utils
Delete ZapFile.o ZapFile QUIET
quit
*/

#include <JEO:JEO.h>
#include <bbs.h>
#include <exec/ports.h>
#include <exec/memory.h>
#include <proto/dos.h>

struct Library *UtilityBase = NULL;

struct ConfigRecord *config;
struct ABBSmsg msg;
struct MsgPort *rport = NULL;

struct Fileentry fentry;

int filedir_number = 0, file_order = 0;

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

BOOL Load_fentry (VOID)
{
	int err;

	msg.Command = Main_loadfileentry;
	msg.UserNr = filedir_number;
	msg.arg = file_order;
	msg.Data = (ULONG)&fentry;
	err = HandleMsg (&msg);

	if (err == Error_OK)
		return (TRUE);

	return (FALSE);
}

VOID Do_slash (UBYTE *Navn)
{
  ULONG len;

  len = strlen (Navn);

  if (Navn[len-1] == ':' OR Navn[len-1] == '/')
    return;
  else
  {
    Navn[len] = '/';
    Navn[len+1] = 0;
  }
}

char Diskname[108];

BOOL FindFile (UBYTE *Name)
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
				filedir_number = n;
				file_order = msg.UserNr;
				if (Load_fentry ())
				{
					strcpy (Diskname, config->firstFileDirRecord[n].n_DirPaths);
					Do_slash (Diskname);
					strcat (Diskname, fentry.Filename);
					return (TRUE);
				}
			}
		}
	}
	return (FALSE);
}

VOID CleanUp (VOID)
{
	if (UtilityBase)
		CloseLibrary (UtilityBase);

	if (msg.msg.mn_ReplyPort)
		DeleteMsgPort(msg.msg.mn_ReplyPort);

	exit (0);
}

VOID SetUp (void)
{
	BOOL ret = FALSE;

	if (FindPort (MainPortName))
	{
		if (UtilityBase = OpenLibrary ("utility.library", 36))
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
		printf ("ABBS must be running for ZapFile to work\n");

	if (!ret)
		CleanUp();
}

BOOL DeleteFileEntry (VOID)
{
	int err;
	BOOL ret = FALSE;

	fentry.Filestatus |= FILESTATUSF_Fileremoved;

	msg.Command = Main_savefileentry;
	msg.UserNr = filedir_number;
	msg.arg = file_order;
	msg.Data = (ULONG)&fentry;
	err = HandleMsg (&msg);
	if (err == Error_OK)
	{
		DeleteFile (Diskname);
		ret = TRUE;
	}
	else
		printf ("Error deleting '%s'", fentry.Filename);

	return (ret);
}

main (int argc, char **argv)
{
	if (argc != 2)
	{
		printf ("\n Usage: ZapFile <file>\n\n");
		exit (0);
	}

	SetUp ();

	if (FindFile (argv[1]))
	{
		if (DeleteFileEntry ())
			printf ("\n File deleted (%s)\n\n", fentry.Filename);
	}
	else
		printf ("\n File not found!\n\n");

	CleanUp ();
}
