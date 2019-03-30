;/*
sc5 -j73 -v ConfigBBS
copy ConfigBBS.c -J:ConfigBBS.c
slink LIB:cback.o+"ConfigBBS.o" to ConfigBBS LIB LIB:sc.lib LIB:reqtools.lib LIB:JEO.lib
Copy ConfigBBS ABBS:Utils
Delete ConfigBBS.o ConfigBBS QUIET
quit
*/

char Ver[] = "\0$VER: ConfigBBS II v1.03 (22.08.98)";
char Vers[] = "1.03";

#include <JEO:JEO.h>
#include <exec/memory.h>
#include <exec/execbase.h>
#include <proto/dos.h>
#include <proto/intuition.h>
#include <proto/graphics.h>
#include <proto/gadtools.h>
#include "dabbs:JEO/ConfigBBS_GUI.c"
#include <bbs.h>

char Message[] = "Message";
char Ok[] = "Ok";

VOID CleanUp (VOID);
int HandleMsg (struct ABBSmsg *msg);
BOOL Setup (void);
BOOL Save_user (UWORD nr, struct UserRecord *ur);
BOOL Load_user (UWORD nr, struct UserRecord *ur);
VOID Update_all (VOID);
VOID Update_user (VOID);

char SYSOPName[31];
int SYSOPUsernr;
char SYSOPpassword[9];
char BaseName[31];

char TmpSysop[31];

UBYTE Dummy[5000];

struct UserRecord *sysop = 0;
struct ConfigRecord *config, *tmp_config;
struct ABBSmsg msg;
struct MsgPort *rport = NULL;
struct Library *UtilityBase = NULL;
struct RastPort *rp;

BOOL save_flag;

VOID Convert_to_zeros (char *Name, UWORD size)
{
	char *Tmp_name;

	Tmp_name = AllocMem (size, MEMF_CLEAR);	
	strncpy (Tmp_name, Name, size);
	strncpy (Name, Tmp_name, size);	// Tar + 1 fordi slutt 0! 

	FreeMem (Tmp_name, size);
}

WORD Get_usernumber (char *Name)
{
	int err;

	msg.Command = Main_getusernumber;
	msg.Name = Name;
	msg.Data = 0L;
	err = HandleMsg (&msg);

	if (err == Error_OK)
		return ((WORD)msg.UserNr);
	return (ERROR);
}

WORD Check_valid (VOID)
{
	if (strlen (sysop->Address) == 0)
		return (GD_ADDRESS);
	if (strlen (sysop->CityState) == 0)
		return (GD_CITY);
	if (strlen (sysop->HomeTelno) == 0)
		return (GD_HOMEPHONE);
	if (strlen (sysop->WorkTelno) == 0)
		return (GD_WORKPHONE);
	if (strlen (config->BaseName) == 0)
		return (GD_BOARDNAME);
	return (ERROR);	// Her er ERROR ok!
}

BOOL Save_config (VOID)
{
	int err;

	if (Save_user (config->SYSOPUsernr, sysop))	// Saver address tlf ol
	{
		msg.Command = Main_saveconfig;
		msg.Data = (ULONG)0; // Intern config!
		err = HandleMsg (&msg);

		if (err != Error_OK)
			JEOReqRequest (Message, "Error saving configfile!", Ok);
		else
			return (TRUE);
	}
	else
		JEOReqRequest (Message, "Error saving sysop!", Ok);
}

BOOL Save_config_short (VOID)
{
	int err;

	msg.Command = Main_saveconfig;
	msg.Data = (ULONG)0; // Intern config!
	err = HandleMsg (&msg);
	if (err != Error_OK)
		JEOReqRequest (Message, "Error saving configfile!", Ok);
	else
		return (TRUE);
	return (FALSE);
}

BOOL Load_config (VOID)
{
	msg.Command = Main_Getconfig;
	if (HandleMsg (&msg) || !msg.UserNr)
	{
		printf ("Error talking to ABBS\n");
		return (FALSE);
	}
	else
	{
		config = (struct ConfigRecord *)msg.Data;
		CopyMem (config, tmp_config, sizeof (struct ConfigRecord));
		return (TRUE);
	}
}

VOID InitGadget (UWORD num, LONG tagtype, LONG tagvalue)
{
  GT_SetGadgetAttrs (ConfigBBSGadgets[num], ConfigBBSWnd, NULL, tagtype, tagvalue, TAG_DONE);
}

VOID ActivateConfigBBSGadget (UWORD nr)
{
  ActivateGadget (ConfigBBSGadgets[nr], ConfigBBSWnd, NULL);
}

UBYTE Check_sysop_name (char *Name)
{
	UBYTE space = 0;

	while (*Name)
	{
		if (*Name == ' ')
			space++;
		Name++;
	}
	return (space);
}

BOOL Check_space (char *Name)
{
	while (*Name)
	{
		if (*Name == ' ')
			return (FALSE);
		Name++;
	}
	return (TRUE);
}

BOOL Squeeze (char *String, char c)
{
	ULONG i, j;
	BOOL flag = TRUE;

	for (i = j = 0; String[i] != 0; i++)
	{
		if (String[i] != c)
			String[j++] = String[i];
		else
			flag = FALSE;
	}
	String[j] = 0;

	return (flag);
}

VOID GadgetUp (APTR *Address)
{
  struct Gadget *gadget;
  ULONG nr;
	char Name[31];
	char Pass[9];
	WORD user;
	UBYTE space;

  gadget = (struct Gadget *)Address;
  nr = gadget->GadgetID;

	switch (nr)
	{
		case GD_NAME:
		{
			strcpy (Name, GetString (gadget));
			space = Check_sysop_name (Name);
			if (space == 1)		// Er det bare 1 space?
			{
				Convert_to_zeros (Name, 31);
				user = Get_usernumber (Name);	// Ja, da finner usernummer
				if (user != ERROR)						// Er brukeren i ABBS?
				{															
					config->SYSOPUsernr = user;	// Ja, du bruker vi han!
					strncpy (config->SYSOPname, Name, 31);
					strcpy (sysop->Name, config->SYSOPname);
					Update_user ();
					ActivateConfigBBSGadget (GD_PASSWORD);
				}
				else
				{
					DB;
				  InitGadget (GD_NAME, GTST_String, (ULONG)"");
				  InitGadget (GD_NAME, GTST_String, (ULONG)TmpSysop);
					ActivateConfigBBSGadget (GD_NAME);
				}
			}
			else
			{
				DB;
				if (space == 0)
					JEOReqRequest (Message, "Two words in sysops name please!", Ok);
				else
					JEOReqRequest (Message, "Too many words in sysops name!", Ok);
			  InitGadget (GD_NAME, GTST_String, (ULONG)"");
			  InitGadget (GD_NAME, GTST_String, (ULONG)TmpSysop);
				ActivateConfigBBSGadget (GD_NAME);
			}
			break;
		}
		case GD_PASSWORD:
		{
			strcpy (Pass, GetString (gadget));
			strcpy (config->SYSOPpassword, Pass);
			ActivateConfigBBSGadget (GD_ADDRESS);	// nei ;)
			break;
		}
		case GD_ADDRESS:
		{
			strcpy (sysop->Address, GetString (gadget));
			ActivateConfigBBSGadget (GD_DOS_PASSWORD);
			break;
		}
		case GD_DOS_PASSWORD:
		{
			strcpy (Pass, GetString (gadget));
			strcpy (config->dosPassword, Pass);
			ActivateConfigBBSGadget (GD_CITY);
			break;
		}
		case GD_CITY:
		{
			strcpy (sysop->CityState, GetString (gadget));
			ActivateConfigBBSGadget (GD_HOMEPHONE);
			break;
		}
		case GD_HOMEPHONE:
		{
			strcpy (sysop->HomeTelno, GetString (gadget));
			ActivateConfigBBSGadget (GD_WORKPHONE);
			break;
		}
		case GD_WORKPHONE:
		{
			strcpy (sysop->WorkTelno, GetString (gadget));
			ActivateConfigBBSGadget (GD_BOARDNAME);
			break;
		}
		case GD_BOARDNAME:
		{
			strcpy (Name, GetString (gadget));
			if (Check_space (Name))	// Har vi noen?
			{
				strcpy (config->BaseName, Name);	// Nei, alt ok
				ActivateConfigBBSGadget (GD_TIMELIMIT);
			}
			else
			{
				DB;
				JEOReqRequest (Message, "No space allowed in here!", Ok);
			  InitGadget (GD_BOARDNAME, GTST_String, (ULONG)"");
			  InitGadget (GD_BOARDNAME, GTST_String, (ULONG)config->BaseName);
				ActivateConfigBBSGadget (GD_BOARDNAME);
			}
			break;
		}

// Andre rekke
		case GD_TIMELIMIT:
		{
			config->NewUserTimeLimit = atoi (GetString (gadget));
			ActivateConfigBBSGadget (GD_FILETIMELIMIT);
			break;
		}
		case GD_FILETIMELIMIT:
		{
			config->NewUserFileLimit = atoi (GetString (gadget));
			ActivateConfigBBSGadget (GD_MAXLINESINMSGS);
			break;
		}
		case GD_MAXLINESINMSGS:
		{
			config->MaxLinesMessage = atoi (GetString (gadget));
			if (config->MaxLinesMessage < 100)
			{
				DB;
				config->MaxLinesMessage = 100;
			}
		  InitGadget (GD_MAXLINESINMSGS, GTIN_Number, config->MaxLinesMessage);
			ActivateConfigBBSGadget (GD_SLEEPTIME);
			break;
		}
		case GD_SLEEPTIME:
		{
			config->SleepTime = atoi (GetString (gadget));
			if (config->SleepTime < 1)
			{
				DB;
				config->SleepTime = 1;
			}
		  InitGadget (GD_SLEEPTIME, GTIN_Number, config->SleepTime);
			if (config->Cflags & CFLAGSF_Byteratio)	// Er byte on?
				ActivateConfigBBSGadget (GD_KBRATIO);
			else if (config->Cflags & CFLAGSF_Fileratio)
				ActivateConfigBBSGadget (GD_FILERATIO);
			else
				ActivateConfigBBSGadget (GD_MINULSPACE);
			break;
		}
		case GD_KBRATIO:
		{
			config->ByteRatiov = atoi (GetString (gadget));

			if (config->Cflags & CFLAGSF_Fileratio)	// Er file on?
				ActivateConfigBBSGadget (GD_FILERATIO);
			else
				ActivateConfigBBSGadget (GD_MINULSPACE);
			break;
		}
		case GD_FILERATIO:
		{
			config->FileRatiov = atoi (GetString (gadget));
			ActivateConfigBBSGadget (GD_MINULSPACE);
			break;
		}
		case GD_MINULSPACE:
		{
			config->MinULSpace = atoi (GetString (gadget));
			break;
		}
		// Checkbox
		case GD_BYTE_ON:
		{
			if (config->Cflags & CFLAGSF_Byteratio)
			{
				config->Cflags &= ~CFLAGSF_Byteratio;
		    InitGadget (GD_KBRATIO, GA_Disabled, TRUE);
			}
			else
			{
				config->Cflags |= CFLAGSF_Byteratio;
		    InitGadget (GD_KBRATIO, GA_Disabled, FALSE);
				ActivateConfigBBSGadget (GD_KBRATIO);
			}
			break;
		}
		case GD_FILE_ON:
		{
			if (config->Cflags & CFLAGSF_Fileratio)
			{
				config->Cflags &= ~CFLAGSF_Fileratio;
		    InitGadget (GD_FILERATIO, GA_Disabled, TRUE);
			}
			else
			{
				config->Cflags |= CFLAGSF_Fileratio;
		    InitGadget (GD_FILERATIO, GA_Disabled, FALSE);
				ActivateConfigBBSGadget (GD_FILERATIO);
			}
			break;
		}
	}
}

BOOL handleidcmp (void)
{
	struct IntuiMessage	*m;
	BOOL	running = TRUE;
	UWORD	code;
	struct IntuiMessage	tmpmsg;
	struct MenuItem *mi;
  APTR Address;
  WORD valid;

	while (m = GT_GetIMsg (ConfigBBSWnd->UserPort))
	{
		CopyMem ((char *) m, (char *) &tmpmsg, (long) sizeof(struct IntuiMessage));
		GT_ReplyIMsg(m);
		Address = tmpmsg.IAddress;
		switch (tmpmsg.Class)
		{
      case IDCMP_GADGETUP:
      {
				GadgetUp (Address);
				break;
			}
			case IDCMP_MENUPICK:
			{
				code = tmpmsg.Code;
				while (code != MENUNULL)
				{
					switch (MENUNUM(code))
					{
						case 0:		// Project
						{
							switch (ITEMNUM (code))
							{
								case 0:	// Load config
								{
									CopyMem (tmp_config, config, sizeof (struct ConfigRecord));
//									Save_config_short ();
									Load_config ();
									Update_all ();
									break;
								}
								case 1:	// Save config
								{
									valid = Check_valid ();
									if (valid == ERROR)	// Her er ERROR ok!
									{
										if (Save_config ())
											running = FALSE;
									}
									else
									{
										DB;
										ActivateConfigBBSGadget (valid);
									}
									break;
								}
								case 3:	// quit
								{
									CopyMem (tmp_config, config, sizeof (struct ConfigRecord));
									running = FALSE;
									break;
								}
							}
							break;
						}
						case 1:		// Features
						{
							switch (ITEMNUM (code))
							{
								case 0:	// Interlaced
								{
									if (config->Cflags & CFLAGSF_lace)
										config->Cflags &= ~CFLAGSF_lace;
									else
										config->Cflags |= CFLAGSF_lace;
									break;
								}
								case 1:	// 8 colours
								{
									if (config->Cflags & CFLAGSF_8Col)
										config->Cflags &= ~CFLAGSF_8Col;
									else
										config->Cflags |= CFLAGSF_8Col;
									break;
								}
								case 2:	// Allow TmpSysop
								{
									if (config->Cflags & CFLAGSF_AllowTmpSysop)
										config->Cflags &= ~CFLAGSF_AllowTmpSysop;
									else
										config->Cflags |= CFLAGSF_AllowTmpSysop;
									break;
								}
								case 3:	// Use ASL
								{
									if (config->Cflags & CFLAGSF_UseASL)
										config->Cflags &= ~CFLAGSF_UseASL;
									else
										config->Cflags |= CFLAGSF_UseASL;
									break;
								}
								case 5:	// Charset
								{
									if (config->DefaultCharSet != SUBNUM (code))	// Forandre?
									{
										ItemAddress (ConfigBBSMenus, FULLMENUNUM (1, 5, config->DefaultCharSet))->Flags &= ~CHECKED;
										config->DefaultCharSet = SUBNUM (code);
									}
									break;
								}
							}
							break;
						}
						case 2:		// New users may
						{
							switch (ITEMNUM (code))
							{
								case 0:	// Upload
								{
									if (config->Cflags & CFLAGSF_Upload)
										config->Cflags &= ~CFLAGSF_Upload;
									else
										config->Cflags |= CFLAGSF_Upload;
									break;
								}
								case 1:	// Download
								{
									if (config->Cflags & CFLAGSF_Download)
										config->Cflags &= ~CFLAGSF_Download;
									else
										config->Cflags |= CFLAGSF_Download;
									break;
								}
							}
							break;
						}
					}
					mi = ItemAddress (ConfigBBSMenus, code);
					code = mi->NextSelect;
				}
				break;
			}
		}
	}
	return (running);
}

VOID CleanUp (VOID)
{
	if (tmp_config)
		FreeMem (tmp_config, sizeof (struct ConfigRecord));
	if (sysop)
		FreeMem (sysop, config->UserrecordSize);
	if (ConfigBBSWnd)
		CloseConfigBBSWindow ();
	CloseDownScreen ();

	if (msg.msg.mn_ReplyPort)
		DeleteMsgPort(msg.msg.mn_ReplyPort);
	if (UtilityBase)
		CloseLibrary (UtilityBase);

	exit (0);
}

BOOL Setup (void)
{
	BOOL ret = FALSE;

	if (tmp_config = AllocMem (sizeof (struct ConfigRecord), MEMF_CLEAR))
	{
		save_flag = FALSE;
		if (FindPort (MainPortName))
		{
			if (UtilityBase = OpenLibrary ("utility.library",36))
			{
				if (msg.msg.mn_ReplyPort = CreateMsgPort())
				{
					if (!Load_config ())
						printf ("Error talking to ABBS\n");
					else
					{
						strcpy (TmpSysop, config->SYSOPname);
						if (sysop = AllocMem (config->UserrecordSize, MEMF_CLEAR))
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
			printf ("ABBS must be running for ConfigBBS to work\n");
	}

	if (ret)
	{
		if (SetupScreen ())
			return (FALSE);
		if (OpenConfigBBSWindow ())
			return (FALSE);
	}

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

BOOL Load_user (UWORD nr, struct UserRecord *ur)
{
	int err;

	msg.Command = Main_loadusernr;
	msg.UserNr = nr;
	msg.Data = (ULONG)ur;
	err = HandleMsg (&msg);

	if (err != Error_OK)
	{
		JEOReqRequest (Message, "Error loading sysop!", Ok);
		return (FALSE);
	}
	return (TRUE);
}

BOOL Save_user (UWORD nr, struct UserRecord *ur)
{
	int err;

	msg.Command = Main_saveusernr;
	msg.UserNr = nr;
	msg.Data = (ULONG)ur;
	err = HandleMsg (&msg);

	if (err != Error_OK)
	{
		JEOReqRequest (Message, "Error saving sysop!", Ok);
		return (FALSE);
	}
	return (TRUE);
}

VOID Clear_all (VOID)
{
	struct MenuItem *mi;
	UBYTE i;

	for (i = 0; i <= 3; i++)
	{
		mi = ItemAddress (ConfigBBSMenus, FULLMENUNUM (1, i, 0));
		mi->Flags &= ~CHECKED;
	}
	for (i = 0; i <= 2; i++)
	{
		mi = ItemAddress (ConfigBBSMenus, FULLMENUNUM (1, 5, i));
		mi->Flags &= ~CHECKED;
	}

	for (i = 0; i <= 1; i++)
	{
		mi = ItemAddress (ConfigBBSMenus, FULLMENUNUM (2, i, 0));
		mi->Flags &= ~CHECKED;
	}
}

VOID Update_user (VOID)
{
	if (!Load_user (config->SYSOPUsernr, sysop))
		CleanUp ();
  InitGadget (GD_NAME, GTST_String, (ULONG)sysop->Name);
  InitGadget (GD_ADDRESS, GTST_String, (ULONG)sysop->Address);
  InitGadget (GD_CITY, GTST_String, (ULONG)sysop->CityState);
  InitGadget (GD_HOMEPHONE, GTST_String, (ULONG)sysop->HomeTelno);
  InitGadget (GD_WORKPHONE, GTST_String, (ULONG)sysop->WorkTelno);
}

VOID Update_all (VOID)
{
	struct MenuItem *mi;

	if (!Load_user (config->SYSOPUsernr, sysop))
		CleanUp ();
	Update_user ();
  InitGadget (GD_PASSWORD, GTST_String, (ULONG)config->SYSOPpassword);
  InitGadget (GD_DOS_PASSWORD, GTST_String, (ULONG)config->dosPassword);
  InitGadget (GD_BOARDNAME, GTST_String, (ULONG)config->BaseName);
  sprintf (Dummy, "%ld", config->NewUserTimeLimit);
  InitGadget (GD_TIMELIMIT, GTIN_Number, config->NewUserTimeLimit);
  InitGadget (GD_FILETIMELIMIT, GTIN_Number, config->NewUserFileLimit);
  InitGadget (GD_MAXLINESINMSGS, GTIN_Number, config->MaxLinesMessage);
  InitGadget (GD_SLEEPTIME, GTIN_Number, config->SleepTime);
  InitGadget (GD_KBRATIO, GTIN_Number, config->ByteRatiov);
  InitGadget (GD_FILERATIO, GTIN_Number, config->FileRatiov);
  InitGadget (GD_MINULSPACE, GTIN_Number, config->MinULSpace);

	if (config->Cflags & CFLAGSF_Byteratio)
	{
		InitGadget (GD_BYTE_ON, (GTCB_Checked), TRUE);
    InitGadget (GD_KBRATIO, GA_Disabled, FALSE);
	}
	else
	{
		InitGadget (GD_BYTE_ON, (GTCB_Checked), FALSE);
    InitGadget (GD_KBRATIO, GA_Disabled, TRUE);
	}

	if (config->Cflags & CFLAGSF_Fileratio)
	{
		InitGadget (GD_FILE_ON, (GTCB_Checked), TRUE);
    InitGadget (GD_FILERATIO, GA_Disabled, FALSE);
	}
	else
	{
	  InitGadget (GD_FILE_ON, (GTCB_Checked), FALSE);
    InitGadget (GD_FILERATIO, GA_Disabled, TRUE);
	}

	Clear_all ();
	if (config->Cflags & CFLAGSF_lace)
	{
		mi = ItemAddress (ConfigBBSMenus, FULLMENUNUM (1, 0, 0));
		mi->Flags |= CHECKED;
	}
	if (config->Cflags & CFLAGSF_8Col)
	{
		mi = ItemAddress (ConfigBBSMenus, FULLMENUNUM (1, 1, 0));
		mi->Flags |= CHECKED;
	}
	if (config->Cflags & CFLAGSF_AllowTmpSysop);
	{
		mi = ItemAddress (ConfigBBSMenus, FULLMENUNUM (1, 2, 0));
		mi->Flags |= CHECKED;
	}
	if (config->Cflags & CFLAGSF_UseASL)
	{
		mi = ItemAddress (ConfigBBSMenus, FULLMENUNUM (1, 3, 0));
		mi->Flags |= CHECKED;
	}

	mi = ItemAddress (ConfigBBSMenus, FULLMENUNUM (1, 5, config->DefaultCharSet));
	mi->Flags |= CHECKED;
	
	if (config->Cflags & CFLAGSF_Upload)
	{
		mi = ItemAddress (ConfigBBSMenus, FULLMENUNUM (2, 0, 0));
		mi->Flags |= CHECKED;
	}
	if (config->Cflags & CFLAGSF_Download)
	{
		mi = ItemAddress (ConfigBBSMenus, FULLMENUNUM (2, 1, 0));
		mi->Flags |= CHECKED;
	}
	ResetMenuStrip (ConfigBBSWnd, ConfigBBSMenus);
}

VOID __stdargs __main (char *Line)
{
	int	quit;
	ULONG	waitsigs, gotsigs;
	char Title[80];

	if (!Setup ())
		CleanUp ();

	sprintf (Title, "ConfigBBS II v%s - Copyright © 1997-1998 Jan Erik Olausen", Vers);
	SetWindowTitles (ConfigBBSWnd, Title, NULL);

  rp = ConfigBBSWnd->RPort;

	waitsigs = ((1L << ConfigBBSWnd->UserPort->mp_SigBit) | SIGBREAKF_CTRL_C);
	Update_all ();

	strcpy (Dummy, "File cache is ");
	if (config->Cflags2 & CFLAGS2F_CacheFL)
		strcat (Dummy, "on");
	else
		strcat (Dummy, "off");

	JEOWrite (rp, 30, 220, Dummy, 1);

	quit = FALSE;

	// Order test!

	config->firstconference[4].n_ConfOrder = 6;
	config->firstconference[5].n_ConfOrder = 8;
	config->firstconference[6].n_ConfOrder = 7;
	config->firstconference[7].n_ConfOrder = 5;

	ActivateConfigBBSGadget (GD_NAME);
	while (!quit)
	{
		gotsigs = Wait (waitsigs);
		quit = (!(handleidcmp()));
		if (gotsigs & SIGBREAKF_CTRL_C)
			quit = TRUE;
	}

	CleanUp ();
}

/*
#define CFLAGSF_lace					(1L<<0)
#define CFLAGSF_8Col					(1L<<1)
#define CFLAGSF_Download			(1L<<2)
#define CFLAGSF_Upload				(1L<<3)
#define CFLAGSF_Byteratio			(1L<<4)
#define CFLAGSF_Fileratio			(1L<<5)
#define CFLAGSF_AllowTmpSysop	(1L<<6)
#define CFLAGSF_UseASL				(1L<<7)

#define BCCS_ISO	0
#define BCCS_IBM	1
#define BCCS_IBN	2
*/
