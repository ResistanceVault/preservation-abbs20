#include <JEO:JEO.h>
#include <proto/exec.h>
#include <exec/memory.h>
#include <proto/dos.h>
#include <dos/datetime.h>
#include <bbs.h>
#include <node.h>
#include <proto/utility.h>
#include <string.h>
#include <ctype.h>
#include <dos.h>


int HandleMsg (struct ABBSmsg *msg);

char Dummy[3000];

struct ABBSmsg msg;

extern far int msprintf (char *, const char *, ...);
#define	a4a5 register __a4 struct ramblocks *nodebase,register __a5 struct Mainmemory *mainmeory
#define	usea4a5	nodebase,mainmeory
extern far ULONG exebase;

extern far char CursorOffData[];
extern far char CursorOnData[];
extern far char deltext[];
extern far char moretext[];
extern far char morenohelptext[];
extern far char accessbitstext[];
extern far char invalidacctext[];
extern far char deadtext[];
extern far char invalidacctext[];
extern far char versionstr[];

extern __asm far VOID CheckInvited (a4a5);
extern __asm far BOOL saveuser (register __a0 char *Name, register __a1 struct UserRecord *cu);
extern __asm far BOOL saveuserarea (register __d0 UWORD size, register __a0 UWORD access);
extern __asm far writecontext (register __a0 char *text,a4a5);
extern __asm far writetexto (register __a0 char *text,a4a5);	// Med return
extern __asm far loadusernrnr (register __d0 ULONG usernr, register __a0 struct UserRecord *ur, a4a5);	// Med return
extern __asm far writetexti (register __a0 char *text,a4a5);	// Uten return
extern __asm far writetext (register __a0 char *text,a4a5);
extern __asm far BOOL Handle_Preview (register __d0 int filedirnr, register __a0 struct Fileentry *fileentry, a4a5);
extern __asm far sendfile (register __a0 char *Filename,a4a5);
//extern __asm far sendpreviewfile (register __a0 char *Filename,a4a5);
extern __asm far VOID Write_user_CPS (register __d5 UWORD cps, a4a5);
extern __asm far readchar (a4a5);
extern __asm far readlineall (register __d0 int len, a4a5);
extern __asm far mayedlineprompt (register __d0 int len, register __a0 char *Text, register __a1 char *TextArg, a4a5);
extern __asm far VOID Hebbe (register __a0 char *Buf, register __d0 int len, a4a5);
__asm far VOID DelText (register __d0 UWORD nr, a4a5);

__asm far BOOL CheckTextMode (register __d1 int pos, register __d2 char Tegn,
                              register __d3 int len, register __a3 char *Buf, a4a5)
{
/*
	int i;
	BPTR fh;
	char Buffer[200];

	if (fh = Open ("PRT:", MODE_NEWFILE))
	{
		msprintf (Buffer, "pos = %ld, Tegn = %ld, len = %ld\n", pos, Tegn, len);
		Write (fh, Buffer, strlen (Buffer));
		Close (fh);
	}
	if (pos + 1 < len)
	{
		for (i = pos + 1; i < len; i++)
		{
			switch (Buf[i])
			{
				case ' ': return (FALSE);
				case '.': return (FALSE);
				case ',': return (FALSE);
				case Tegn: return (TRUE);
			}
		}
	}
*/
	return (FALSE);
}

#define START	0
#define GO		1
#define STOP	2

__asm far VOID WriteLineNr (a4a5)
{
	WORD i;

	if (!nodebase->readlinemore)
	{
		nodebase->linesleft = 65535;	// Vi vil ikke ha noen more her..
		putreg (REG_A6,exebase);
		writetexti ("\f[32m", usea4a5);
		for (i = 70; i >= 3; i--)
		{
			msprintf (Dummy, "%2ld\n", i);
			writetexti (Dummy, usea4a5);
		}
		writetexti ("[0m\n", usea4a5);
		nodebase->linesleft = nodebase->CU.PageLength;
	}
}


// Filer fra killa brukerer blir fra sysop i steden!
// 

LONG FileSize (UBYTE *Name)
{
  register BPTR lock = 0;
  register struct FileInfoBlock *fib = 0;
  register LONG size = ERROR;

  if (!(fib = (struct FileInfoBlock *)AllocMem (sizeof (struct FileInfoBlock), MEMF_CLEAR)))
    return (-2); 

  if (lock = Lock (Name, ACCESS_READ))
  {
    if (Examine (lock, fib))
      size = fib->fib_Size;
  }

  if (lock)
    UnLock (lock);
  if (fib)
    FreeMem (fib, sizeof (struct FileInfoBlock));

  return (size);
}

__asm far VOID PackUserDoFiles (a4a5)
{
	BPTR fh;

	if (fh = Open ("RAM:JEOJEO", MODE_NEWFILE))
	{
		Write (fh, &nodebase->tmpmsgmem, nodebase->msgmemsize);
		Close (fh);
	}
}

VOID Slash_to_space (char *S)
{
	while (*S)
	{
		if (*S == '/')
			*S = ' ';
		*S++;
	}
}

ULONG CenterText (UBYTE *String, UBYTE max)
{
	ULONG len;

	len = strlen (String);
	if (len >= max)
		return (0);

	return ((max / 2) - (len / 2));
}

__asm far VOID Make_conf_text (register __a0 char *Conf, a4a5)
{
	char Confname[51];
	char Hold[200];
	char Line[80];
	char Filename[108];
	BPTR fh = 0, lock = 0;
	int line;
	BOOL go_flag;
	char Conf_text_dir[] = "ABBS:Text/Conf_text";
	UBYTE start;

  lock = CreateDir (Conf_text_dir);
  if (lock)
    UnLock (lock);

	strcpy (Confname, Conf);
	Slash_to_space (Confname);
	msprintf (Filename, "%s/%s", Conf_text_dir, Confname);
	if (fh = Open (Filename, MODE_NEWFILE))
	{
		go_flag = TRUE;
		line = Dummy[0] = 0;

		strcpy (Dummy, "[1;1H[2J\n[32m                     __                                __\n");
		strcat (Dummy, "                 ___/ /                                \\ \\___\n");
		strcat (Dummy, "                 \\ / /\\     [31m      Conference           [32m/\\ \\ /\n");
		strcat (Dummy, "      ___________/ \\/\\ \\   [31m      ------------         [32m/ /\\/ \\___________\n");
		strcat (Dummy, "     /               / /                              \\ \\               \\\n");
		Write (fh, &Dummy, strlen (Dummy));

		start = CenterText (Conf, 71);
		strcpy (Hold, "     \\      ___      \\/[36m                                [32m\\/      ___      /\n");
		strncpy (&Hold[start+9], Conf, strlen (Conf));
		Write (fh, &Hold, strlen (Hold));

		strcpy (Dummy, "      \\__  /   \\______________________   _____________________/   \\  __/\n");
		strcat (Dummy, "         \\/                           \\_/                          \\/\n\n");
		Write (fh, &Dummy, strlen (Dummy));

		strcpy (Dummy, " [34m***************************************************************************\n");
		Write (fh, &Dummy, strlen (Dummy));

		putreg (REG_A6,exebase);
		writetexto ("\n[32mPlease enter conference text (enter on blank line quits)", usea4a5);
		putreg (REG_A6,exebase);
		writetexto ("[32mType ç (ALT-C) at the end of each line to allign text to center.", usea4a5);
		while (go_flag)
		{
			msprintf (Dummy, "[36m%02ld: [0m", line + 1);
			putreg (REG_A6,exebase);
			writetexti (Dummy, usea4a5);
			putreg (REG_A6,exebase);
			readlineall (71, usea4a5);
			if (*(nodebase->intextbuffer))
			{
				strcpy (Line, nodebase->intextbuffer);
				if (Line[strlen (Line) - 1] == 'ç')	// Skal vi sentrere?
				{
					Line[strlen (Line) - 1] = 0;	// Ta bort ç
					start = CenterText (Line, 71);		// Ja
					strcpy (Hold, "                                                                      ");
					strncpy (&Hold[start], Line, strlen (Line));
					msprintf (Dummy, "[34m * [33m%-71s [34m*\n", Hold);
				}
				else
					msprintf (Dummy, "[34m * [33m%-71s [34m*\n", nodebase->intextbuffer);
				if (*(Dummy))
				{
					Write (fh, &Dummy, strlen (Dummy));
					line++;
				}
			}
			else
			{
				if (line)	// Har vi skrevet noe?
				{
					strcpy (Dummy, " ***************************************************************************\n");
					Write (fh, &Dummy, strlen (Dummy));
				}
				go_flag = FALSE;
			}
		}
		strcpy (Dummy, "[0m");	// Resetter sakene ;)
		Write (fh, &Dummy, strlen (Dummy));
		Close (fh);
		if (line)
		{
			putreg (REG_A6,exebase);
			writetexto ("[32mDone.\n", usea4a5);
		}
	}
	else
	{
		msprintf (Dummy, "\n[31mError opening '%s'.\nCouldn't create conference text file...[0m\n\n", Filename);
		putreg (REG_A6,exebase);
		writetexti (Dummy, usea4a5);
	}
}

/*
__asm far char GetChar (a4a5)
{
	putreg (REG_A6,exebase);
	writetexti ("[32mTast inne et eller annet: [0m", usea4a5);
}
*/
/*
__asm far VOID Test (a4a5)
{
	putreg (REG_A6,exebase);
	writetexti ("[32mTast inne et eller annet: [0m", usea4a5);
	putreg (REG_A6,exebase);
	readline (usea4a5);
	msprintf (Dummy, "[31mDu tastet: [33m%s[0m", nodebase->intextbuffer);
	putreg (REG_A6,exebase);
	writetexto (Dummy, usea4a5);

//	msprintf (Dummy, "status = %ld\n", nodebase->readcharstatus);
//	writetexto (Dummy, usea4a5);
}
*/
/*
BOOL GetUser (ULONG nr, UBYTE *User)	// Henter bare navnet fra nummer...
{
	int err;
	BOOL ret = FALSE;

	msg.Command = Main_getusername;
	msg.UserNr = nr;
	err = HandleMsg (&msg);
	if (err == Error_OK)
	{
		strcpy (User, msg.Name);
		ret = TRUE;
	}
	return (ret);
}
*/

BOOL Check_bits (char *Scan_bits, ULONG access)
{
	UBYTE i;

	for (i = 0; Scan_bits[i] != 0; i++)	// Sjekker for valide bits
	{
		switch (Scan_bits[i])
		{
			case 'R':	{ if (!(access & ACCF_Read)) return (FALSE); break;	}
			case 'W':	{ if (!(access & ACCF_Write)) return (FALSE); break;	}
			case 'U':	{ if (!(access & ACCF_Upload)) return (FALSE); break;	}
			case 'D':	{ if (!(access & ACCF_Download)) return (FALSE); break;	}
			case 'F':	{ if (!(access & ACCF_FileVIP)) return (FALSE); break;	}
			case 'I':	{ if (!(access & ACCF_Invited)) return (FALSE); break;	}
			case 'S':	{ if (!(access & ACCF_Sigop)) return (FALSE); break;	}
			case 'Z':	{ if (!(access & ACCF_Sysop)) return (FALSE); break;	}
		}
	}
	return (TRUE);
}

VOID Do_bits (char *Bits, ULONG access)
{
	if (access & ACCF_Read)	strcat (Bits, "R");
	if (access & ACCF_Write)	strcat (Bits, "W");
	if (access & ACCF_Upload) 	strcat (Bits, "U");
	if (access & ACCF_Download)	strcat (Bits, "D");
	if (access & ACCF_FileVIP)	strcat (Bits, "F");
	if (access & ACCF_Invited)	strcat (Bits, "I");
	if (access & ACCF_Sigop)	strcat (Bits, "S");
	if (access & ACCF_Sysop)	strcat (Bits, "Z");
}

char Bits[] = "RWUDFISZ";

BOOL Parse_bits (char *Scan_bits)
{
	UBYTE i, j;
	BOOL flag;
	
	for (i = 0; Scan_bits[i] != 0; i++)	// Sjekker for valide bits
	{
		flag = FALSE;
		for (j = 0; Bits[j] != 0; j++)
		{
			if (Scan_bits[i] == Bits[j])
			{
				flag = TRUE;
				break;
			}
		}
		if (!flag)
			return (FALSE);
	}

	return (TRUE);
}

VOID ReverseString (char *String)
{
	ULONG i, len, x;
	UBYTE c;

	x = len = strlen (String);
	x >>= 1;	// Deler på 2
	len--;
	for (i = 0; i < x; i++, len--)
	{
		c = String[i];
		String[i] = String[len];
		String[len] = c;
	}
}

VOID Strip_access (char *Access)
{
	char Hold[10];
	BYTE i, j;

	for (i = strlen (Access) - 1, j = 0; i >= 0; i--, j++)
	{
		Hold[j] = Access[i];
		if (Hold[j] == ' ')
			break;
	}
	Hold[j] = 0;
	strcpy (Access, Hold);
	ReverseString (Access);
}

__asm far VOID ShowUsers_c (a4a5)
{
	struct ConfigRecord *config = &mainmeory->config;
	BOOL c_flag, go_flag = TRUE;
	char Time[15];
	char Access_scan[9];
	ULONG usernr, linesleft, listed = 0, killed = 0, i;
	char Date[20], Hold[30];
  struct DateTime dt = { NULL };
	char DayString[][4] = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" };
	char m1, m2, c;
	UBYTE month;
	UWORD active_conf;
	UWORD cur_line;
	BOOL sysop = FALSE;
	char Name[45];
	BOOL rip;
	char Bits[9];
	struct UserRecord *ur = 0;
	char User[] = "user", Users[] = "users";
	char MonthString[][4] = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul",
													"Aug", "Sep", "Oct", "Nov", "Dec" };

	if (!(ur = AllocMem (config->UserrecordSize, MEMF_CLEAR)))
		return;

	active_conf = nodebase->confnr / 2;

	strcpy (Access_scan, "R");
	if (nodebase->CU.firstuserconf[active_conf].uc_Access & ACCF_Sysop)
	{
		sysop = TRUE;
		putreg (REG_A6,exebase);
		mayedlineprompt (8, "[33mAccess type <RWUDFISZ>: [0m", Access_scan, usea4a5);
		strcpy (Access_scan, nodebase->intextbuffer);
		for (i = 0; Access_scan[i] != 0; i++)
			Access_scan[i] = toupper (Access_scan[i]);

		Strip_access (Access_scan);
		if (*(Access_scan))
		{
			if (!Parse_bits (Access_scan))
			{
				putreg (REG_A6,exebase);
				sprintf (Dummy, "[31m%s %s\n", invalidacctext, Access_scan);
				writetext (Dummy, usea4a5);
				goto end;
			}
		}
		else
			goto end;
	}

	linesleft = nodebase->linesleft;
	nodebase->linesleft = 65535;		// Slår av more-prompt
	if (sysop)
		cur_line = 1;
	else
		cur_line = 1;
	for (usernr = 0; usernr < config->MaxUsers; usernr++)
	{
		if (!go_flag)
			break;
		loadusernrnr (usernr, ur, usea4a5);
		strcpy (Name, ur->Name);

		if (usernr == 0)
		{
			putreg (REG_A6,exebase);
			writetext ("\n", usea4a5);
		}

		if (!Check_bits (Access_scan, ur->firstuserconf[active_conf].uc_Access))
			continue; 	// Ikke det vi spurte etter!

		rip = FALSE;
		if (ur->Userbits & USERF_Killed)	// Er killa?
		{
			killed++;
			if (sysop)	// Er det sysop som ser? ;)
			{
				sprintf (Dummy, "[31m%s", deadtext);
				strcat (Name, Dummy);
				rip = TRUE;
			}
			else
				continue;
		}

		dt.dat_Stamp.ds_Days		= ur->LastAccess.ds_Days;
		dt.dat_Stamp.ds_Minute	= ur->LastAccess.ds_Minute;
		dt.dat_Stamp.ds_Tick		= ur->LastAccess.ds_Tick;
		dt.dat_Format	= FORMAT_CDN;
		dt.dat_Flags	= 0;
		dt.dat_StrDate = Date;
		dt.dat_StrTime = Time;

		if (DateToStr (&dt))
		{
			if (ur->LastAccess.ds_Days > 0)
			{
				strncpy (Hold, Date, 3);
				Hold[3] = 0;
				m1 = Date[3];
				m2 = Date[4];
				month = 0;
				if (m1 == '1')
					month += 10;
				month += (m2 - 48);
				month--;
				strcat (Hold, MonthString[month]);
				strncat (Hold, &Date[5], 3);
				Time[5] = 0;
			}
			else
				strcpy (Hold, "N/A");
		}
		else
			strcpy (Hold, "DATE ERROR");

		strcpy (Bits, " ");
		if (sysop)
			Do_bits (Bits, ur->firstuserconf[active_conf].uc_Access);
		if (!rip)
			msprintf (Dummy, "%-39s [33m%s [35m%s [36m%s[31m%s[0m", Name, DayString[ur->LastAccess.ds_Days%7], Hold, Time, Bits);
		else
			msprintf (Dummy, "%-44s [33m%s [35m%s [36m%s[31m%s[0m", Name, DayString[ur->LastAccess.ds_Days%7], Hold, Time, Bits);
		putreg (REG_A6,exebase);
		writetexto (Dummy, usea4a5);
		listed++;
		cur_line++;
		if (cur_line == nodebase->CU.PageLength)	// Da spør vi om mere ;)
		{
			if (nodebase->CU.XpertLevel > 1)	// Er vi expert eller høyere
				msprintf (Dummy, "[0m%s", morenohelptext);
			else
				msprintf (Dummy, "[0m%s", moretext);
			putreg (REG_A6,exebase);
			writetexti (Dummy, usea4a5);
			c_flag = TRUE;
			while (c_flag)
			{
				nodebase->dosleepdetect = 1;
				c = readchar (usea4a5);
	      c = toupper (c);
				nodebase->dosleepdetect = 0;
				switch (c)
				{
					case 'Y':
					{
						c_flag = FALSE;
						if (nodebase->CU.XpertLevel > 1)	// Er vi expert eller høyere
							DelText (8, usea4a5);
						else
							DelText (17, usea4a5);
						cur_line = 0;
						break;
					}
					case ' ':		// Samme som Y
					{
						c_flag = FALSE;
						if (nodebase->CU.XpertLevel > 1)	// Er vi expert eller høyere
							DelText (8, usea4a5);
						else
							DelText (17, usea4a5);
						cur_line = 0;
						break;
					}
					case 13:		// Return da gir vi kun 1 linje
					{
						c_flag = FALSE;
						if (nodebase->CU.XpertLevel > 1)	// Er vi expert eller høyere
							DelText (8, usea4a5);
						else
							DelText (17, usea4a5);
						cur_line = nodebase->CU.PageLength - 1;
						break;
					}
					case 'N':
					{
						c_flag = FALSE;
						go_flag = FALSE;
						putreg (REG_A6,exebase);
						writetexti ("\n", usea4a5);
						break;
					}
					case -1:	// Ejecta?
					{
						c_flag = FALSE;
						go_flag = FALSE;
						putreg (REG_A6,exebase);
						writetexti ("\n", usea4a5);
						break;
					}
					case 0:	// Quit ABBS
					{
						c_flag = FALSE;
						go_flag = FALSE;
						putreg (REG_A6,exebase);
						writetexti ("\n", usea4a5);
						break;
					}
					case 'C':		// Vi fortsetter
					{
						c_flag = FALSE;
						if (nodebase->CU.XpertLevel > 1)	// Er vi expert eller høyere
							DelText (8, usea4a5);
						else
							DelText (17, usea4a5);
						cur_line = 35535;	// Skal vel holde det ;)
						break;
					}
				}
			}
		}
	}

end:
	if (sysop)
	{
		listed -= killed;
		sprintf (Dummy, "\n[32m%ld active %s and %ld killed %s listed.", listed, listed == 1 ? User : Users, killed, killed == 1 ? User : Users);
	}
	else
		sprintf (Dummy, "\n[32m%ld %s listed.", listed, listed == 1 ? User : Users);
	putreg (REG_A6,exebase);
	writetexto (Dummy, usea4a5);

	if (ur)
	{
		FreeMem (ur, 	config->UserrecordSize);
		ur = 0;
	}
	nodebase->linesleft = linesleft;
}

__asm far VOID DelText (register __d0 UWORD nr, a4a5)
{
	UWORD i;

	putreg (REG_A6,exebase);
	for (i = 0; i < nr; i++)
		writetexti (deltext, usea4a5);
}

UWORD Find_max_conf_name_len (struct ConfigRecord *config)
{
	UWORD n;
	UBYTE max = 0, len;

	for (n = 0; n < config->Maxconferences; n++)	// Går igjenom alle konfer 
	{
		if (*(config->firstconference[n].n_ConfName))	// Er det et navn her?
		{
			len = strlen (config->firstconference[n].n_ConfName);
			if (len > max)
				max = len;
		}
	}
	return (max);
}

// d0 = fildirnr
// a0 = fileentry

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

__asm far BOOL Handle_Preview (register __d0 int filedirnr, register __a0 struct Fileentry *fileentry, a4a5)
{
	char Filedir[] = "ABBS:Previews/";
	char Filename[108];
	char Holdpath[108];

	msprintf (Filename, "%s%s_@PREVIEW@", Filedir, fileentry->Filename);
	if (Exists (Filename))	// Eksisterer det?
	{
		strcpy (Holdpath, nodebase->Nodemem.HoldPath);
		if (Holdpath[strlen (Holdpath) - 1] != ':')	// Vi må sjekke etter slash
		{
			if (Holdpath[strlen (Holdpath) - 1] != '/')	// Er det en slash?
				strcat (Holdpath, "/");										// Nei, da legger vi til...
		}
		msprintf (Dummy, "C:Copy \"%s\" TO \"%s\"", Filename, Holdpath);
		Execute (Dummy, NULL, NULL);
		putreg (REG_A6,exebase);
		msprintf (Dummy, "[33mPreview file of '%s' has been moved to hold...\n", fileentry->Filename);
		writetexti (Dummy, usea4a5);
	}
	else
	{
		putreg (REG_A6,exebase);
		writetexti ("[31mFile has no preview attached!\n", usea4a5);
	}

	return (TRUE);
}

__asm far BOOL ShowConferencesAll (register __d1 char argument, a4a5)
{
	ULONG n, i, teller, k;
	BOOL member, show, go_flag, c_flag;
	char Hold[181], c;
	struct ConferenceRecord *confarray;
	struct ConfigRecord *config = &mainmeory->config;
	UWORD linesleft;
	UWORD cur_line;
	char Bulletins[19];
	UBYTE max_len, tot;

	if (argument != 'A')	// Ikke all
		return (FALSE);

	linesleft = nodebase->linesleft;
	nodebase->linesleft = 65535;		// Slår av more-prompt
	confarray = (struct ConferenceRecord *)(((int) config) + (SIZEOFCONFIGRECORD));
	putreg (REG_A6,exebase);
	writetexti ("\n", usea4a5);
	putreg (REG_A6,exebase);
	writetexti ("[32mConference status\n", usea4a5);
	putreg (REG_A6,exebase);
	writetexti ("-----------------\n", usea4a5);
	teller = 0;
	cur_line = 4;
	go_flag = TRUE;
	max_len = Find_max_conf_name_len (config);

	for (i = 0;; i++)	// Går igjenom alle konfer 
	{
		if (!go_flag)
			break;
		for (n = 0; n < config->Maxconferences; n++)	// Går igjenom alle konfer 
		{																							// for å finne neste order
			if (!go_flag)
				break;

			if (i == config->firstconference[n].n_ConfOrder)	// Leter etter neste rekkefølge
			{																									// FUNNET!!
				if (*(config->firstconference[n].n_ConfName))	// Er det et navn her?
				{
					teller++;
					member = FALSE;
					if (nodebase->CU.firstuserconf[n].uc_Access	&	ACCF_Read)	// Medlem?
					{
						strcpy (Hold, "[32mMember[0m");
						member = TRUE;
					}
					else
						strcpy (Hold, "[31mNon-member[0m");
	
					show = TRUE;
					if (confarray[n].n_ConfSW & CONFSWF_VIP)	// VIP conf?
					{
						if (!member)
							show = FALSE;
					}
					else	// Ikke vise READ ONLY i VIP konfer, de er jo alltid READ ONLY
					{			// fra starten av
						if (n > 3)
						{
							if (!(config->firstconference[n].n_ConfSW & CONFSWF_ImmWrite))	// Har vi READ ONLY?
								strcat (Hold, ", READ ONLY");
						}
					}
	
					if (show)
					{
						if (n == 2)
							strcat (Hold, ", USER INFO");
						if (n == 3)
							strcat (Hold, ", FILE INFO");
						if (config->firstconference[n].n_ConfSW & CONFSWF_PostBox)	// MAIL?
							strcat (Hold, ", MAIL");
						if (config->firstconference[n].n_ConfSW & CONFSWF_Private)	// Private meldinger?
							strcat (Hold, ", Private allowed");
						if (!(config->firstconference[n].n_ConfSW & CONFSWF_Resign))	// Obligatory?
							strcat (Hold, ", Obligatory");
						if (config->firstconference[n].n_ConfSW & CONFSWF_Network)	// MAIL?
							strcat (Hold, ", Network");

						Bulletins[0] = 0;
						if (config->firstconference[n].n_ConfBullets > 0)
							strcpy (Bulletins, "[33m(Bulletins)");

						msprintf (Dummy, "[36m%s", config->firstconference[n].n_ConfName);
						putreg (REG_A6,exebase);
						writetexti (Dummy, usea4a5);

						tot = max_len - strlen (config->firstconference[n].n_ConfName);
						for (k = 0; k < tot; k++)
							Dummy[k] = ' ';
						Dummy[tot] = ':';
						Dummy[tot + 1] = 0;
						putreg (REG_A6,exebase);
						writetexti (Dummy, usea4a5);

						msprintf (Dummy, " [0m%s. %s\n", Hold, Bulletins);
						putreg (REG_A6,exebase);
						writetexti (Dummy, usea4a5);

						cur_line++;
//						msprintf (Dummy, "status = %ld, n = %ld, linesleft = %ld, cursorpos = %ld\n", nodebase->outtextbufferpos, n, nodebase->linesleft, nodebase->cursorpos);
//						putreg (REG_A6,exebase);
//						writetexto (Dummy, usea4a5);
						if (cur_line == nodebase->CU.PageLength)	// Da spør vi om mere ;)
						{
							if (nodebase->CU.XpertLevel > 1)	// Er vi expert eller høyere
								msprintf (Dummy, "[0m%s", morenohelptext);
							else
								msprintf (Dummy, "[0m%s", moretext);
							putreg (REG_A6,exebase);
							writetexti (Dummy, usea4a5);
							c_flag = TRUE;
							while (c_flag)
							{
								nodebase->dosleepdetect = 1;
								c = readchar (usea4a5);
					      c = toupper (c);
								nodebase->dosleepdetect = 0;
								switch (c)
								{
									case 'Y':
									{
										c_flag = FALSE;
										if (nodebase->CU.XpertLevel > 1)	// Er vi expert eller høyere
											DelText (8, usea4a5);
										else
											DelText (17, usea4a5);
										cur_line = 0;
										break;
									}
									case ' ':		// Samme som Y
									{
										c_flag = FALSE;
										if (nodebase->CU.XpertLevel > 1)	// Er vi expert eller høyere
											DelText (8, usea4a5);
										else
											DelText (17, usea4a5);
										cur_line = 0;
										break;
									}
									case 13:		// Return da gir vi kun 1 linje
									{
										c_flag = FALSE;
										if (nodebase->CU.XpertLevel > 1)	// Er vi expert eller høyere
											DelText (8, usea4a5);
										else
											DelText (17, usea4a5);
										cur_line = nodebase->CU.PageLength - 1;
										break;
									}
									case 'N':
									{
										c_flag = FALSE;
										go_flag = FALSE;
										putreg (REG_A6,exebase);
										writetexti ("\n", usea4a5);
										break;
									}
									case -1:	// Ejecta?
									{
										c_flag = FALSE;
										go_flag = FALSE;
										putreg (REG_A6,exebase);
										writetexti ("\n", usea4a5);
										break;
									}
									case 0:	// Quit ABBS
									{
										c_flag = FALSE;
										go_flag = FALSE;
										putreg (REG_A6,exebase);
										writetexti ("\n", usea4a5);
										break;
									}
									case 'C':		// Vi fortsetter
									{
										c_flag = FALSE;
										if (nodebase->CU.XpertLevel > 1)	// Er vi expert eller høyere
											DelText (8, usea4a5);
										else
											DelText (17, usea4a5);
										cur_line = 35535;	// Skal vel holde det ;)
										break;
									}
/*
									default:
									{
										msprintf (Dummy, "%ld\n", c);
										putreg (REG_A6,exebase);
										writetexti (Dummy, usea4a5);
										break;
									}
*/
								}
							}
						}
					}
					if (teller == config->ActiveConf) 
						go_flag = FALSE;
				}
			}
		}
	}
	nodebase->linesleft = linesleft;
	return (TRUE);
}

// ******************************************************************************
// ***************************** CONFERENCE BROWSER (CB) ************************
// ******************************************************************************

#define MEMBER			31
#define OBLIGATORY	34
#define NON_MEMBER	36

typedef struct
{
	char Name[81];
	UWORD flag;
	UWORD confnr;
} CB_header;

CB_header far head[500];

__asm far VOID Update_names (register __d0 int active_conf, register __d1 int max_lines, register __d2 BOOL mode, a4a5)
{
	int n;
	int start;

	if (mode)	// ned
		start = active_conf - max_lines;
	else
		start = active_conf - 1;

	putreg (REG_A6,exebase);
	writecontext (CursorOffData,usea4a5);

	putreg (REG_A6,exebase);
	writetexti ("[4;1H", usea4a5);
	putreg (REG_A6,exebase);
	for (n = start; n < start + max_lines; n++)	// Printer ut...
	{
		msprintf (Dummy, "[%ldm%-30s", head[n].flag, head[n].Name);
		writetexti (Dummy, usea4a5);

		if (n < start + max_lines - 1)
			writetexti ("\n", usea4a5);
		else
		{
			msprintf (Dummy, "[%ld;1H", max_lines + 3);
			writetexti (Dummy, usea4a5);
		}
	}
	putreg (REG_A6,exebase);
	writecontext (CursorOnData,usea4a5);
}

BOOL Check_conf_text (char *Conf)
{
	char My_conf[31];
	char Filename[108] = "ABBS:Text/Conf_text/";

	strcpy (My_conf, Conf);
	Slash_to_space (My_conf);
	strcat (Filename, My_conf);
	if (FileSize (Filename) > 0)
		return (TRUE);
	else
		return (FALSE);
}

__asm far VOID ABBS_version (a4a5)
{
	BPTR fh;

	if (fh = Open ("ABBS:ABBS", MODE_OLDFILE))
	{
		putreg (REG_A6, exebase);
		sprintf (Dummy, "\n  [32m%s[0m\n\n", versionstr);
		writetexti (Dummy, usea4a5);
		Close (fh);
	}
}


__asm far VOID Conference_browser (a4a5)
{
	int cursor;
	struct ConfigRecord *config = &mainmeory->config;
	struct ConferenceRecord *confarray;
	int n;
	char c;
	BOOL flag = TRUE, m_flag;
	int max_confs;
	int active_conf = 1;
	int max_lines = 0;
	char Access[9];

	nodebase->linesleft = 65535;	// Vi vil ikke ha noen more her..
	max_confs = 0;
	confarray = (struct ConferenceRecord *) (((int) config) + (SIZEOFCONFIGRECORD));
	for (n = 0; n < config->Maxconferences; n++)	// Finner antall konfer som er tilgjengelig
	{
		if (*(confarray[n].n_ConfName))
		{
			m_flag = FALSE;
			if (confarray[n].n_ConfSW & CONFSWF_VIP)	// Her må vi sjekke om brukeren er read
			{
				if (nodebase->CU.firstuserconf[n].uc_Access & ACCF_Read)	// Read?
					m_flag = TRUE;
				else if (nodebase->CU.firstuserconf[n].uc_Access & ACCF_Sysop)	// Sysop?
					m_flag = TRUE;
				else if (nodebase->CU.firstuserconf[n].uc_Access & ACCF_Invited)	// Invited?
					m_flag = TRUE;
			}
			else
				m_flag = TRUE;
			if (m_flag)	// Godkjent som medlem?
			{
				max_confs++;	// Fordi vi starter på 1
				Access[0] = 0;
				if (nodebase->CU.firstuserconf[n].uc_Access & ACCF_Read)
					strcat (Access, "R");
				if (nodebase->CU.firstuserconf[n].uc_Access & ACCF_Write)
					strcat (Access, "W");
				if (nodebase->CU.firstuserconf[n].uc_Access & ACCF_Upload)
					strcat (Access, "U");
				if (nodebase->CU.firstuserconf[n].uc_Access & ACCF_Download)
					strcat (Access, "D");
				if (nodebase->CU.firstuserconf[n].uc_Access & ACCF_FileVIP)
					strcat (Access, "F");
				if (nodebase->CU.firstuserconf[n].uc_Access & ACCF_Invited)
					strcat (Access, "I");
				if (nodebase->CU.firstuserconf[n].uc_Access & ACCF_Sigop)
					strcat (Access, "S");
				if (nodebase->CU.firstuserconf[n].uc_Access & ACCF_Sysop)
					strcat (Access, "Z");

				msprintf (head[max_confs].Name, "%-30s [36m%6ld %-8s", confarray[n].n_ConfName, confarray[n].n_ConfDefaultMsg, Access);
				if (!(confarray[n].n_ConfSW & CONFSWF_Resign))	// Obligatorisk?
					head[max_confs].flag = OBLIGATORY;
				else if (nodebase->CU.firstuserconf[n].uc_Access & ACCF_Read)	// Er vi medlem?
					head[max_confs].flag = MEMBER;
				else
					head[max_confs].flag = NON_MEMBER;
			
				head[max_confs].confnr = n;
			}
		}
	}

	putreg (REG_A6,exebase);
	writetexti ("[2J", usea4a5);	// Sletter skjerm
	writetexti ("[1;1H", usea4a5);	// Cursor på topp

	writetexti ("\n[0m[32mConference name                High   Flags\n", usea4a5);
	writetexti ("---------------                ----   -----\n", usea4a5);

	max_lines = 0;
	cursor = 1; 
	for (n = 1; n <= max_confs; n++)	// Printer ut...
	{
		if (max_lines > nodebase->CU.PageLength - 7)	// 7 = headere og slikt
			break;

		if (head[n].flag == OBLIGATORY)
		{
			msprintf (Dummy, "[34m%-30s\n", head[n].Name);
			putreg (REG_A6,exebase);
			writetexti (Dummy, usea4a5);
		}
		else if (head[n].flag == MEMBER)
		{
			msprintf (Dummy, "[31m%-30s\n", head[n].Name);
			putreg (REG_A6,exebase);
			writetexti (Dummy, usea4a5);
		}
		else	// NON_MEMBER
		{
			msprintf (Dummy, "[36m%-30s\n", head[n].Name);
			putreg (REG_A6,exebase);
			writetexti (Dummy, usea4a5);
		}
		max_lines++;
	}
	putreg (REG_A6,exebase);
	writetexti ("[0m<more>\n", usea4a5);
	writetexti ("[32mSpace tags/untags,Info,Quit(exit),Untag all", usea4a5);
	writetexti ("[4;1H", usea4a5);	// Cursor på topp

	while (flag)
	{
		putreg (REG_A6,exebase);
		c = readchar (usea4a5);
		switch (c)
		{
			case 27: flag = FALSE; break;	// ESC
			case 32:	// SPACE
			{
				if (head[active_conf].flag != OBLIGATORY)
				{
					if (head[active_conf].flag == NON_MEMBER)
					{
						msprintf (Dummy, "[31m%-30s", head[active_conf].Name);
						putreg (REG_A6,exebase);
						writetexti (Dummy, usea4a5);
						head[active_conf].flag = MEMBER;
					}
					else if (head[active_conf].flag == MEMBER)
					{
						msprintf (Dummy, "[36m%-30s", head[active_conf].Name);
						putreg (REG_A6,exebase);
						writetexti (Dummy, usea4a5);
						head[active_conf].flag = NON_MEMBER;
					}
					if (cursor < max_lines)
					{
						putreg (REG_A6,exebase);
						writetexti ("\n", usea4a5);
						cursor++;
						active_conf++;
					}
					else	// Kommer ikke lengere ned, start på linja...
					{
						msprintf (Dummy, "[%ld;1H", cursor + 3);
						putreg (REG_A6,exebase);
						writetexti (Dummy, usea4a5);
					}
				}
				break;
			}
			case 113: flag = FALSE; break;	// Q
			case 20:	// Pil opp
			{
				if (cursor == 1)	// Er vi på topp???
				{
					if (active_conf > cursor)	// JA! Har vi flere tilbake?
					{
						putreg (REG_A6,exebase);
						Update_names (active_conf, max_lines, 0, usea4a5);	// Det hadde vi
						putreg (REG_A6,exebase);
						writetexti ("\n[0m<more> ", usea4a5);
						writetexti ("[4;1H", usea4a5);
						active_conf--;
					}
				}
				else	// NEI!
				{
					putreg (REG_A6,exebase);
					writetexti ("[1A", usea4a5); 	// JA!
					cursor--;
					active_conf--;
				}
				break;
			}
			case 21:	// Pil ned
			{
				if (active_conf < max_confs)
				{
					if (cursor == max_lines)	// Slutt på lista men vi har flere
					{
						putreg (REG_A6,exebase);
						Update_names (active_conf + 2, max_lines, 1, usea4a5);
						if (active_conf == max_confs - 1)
						{
							putreg (REG_A6,exebase);
							writetexti ("\n[0m<end> ", usea4a5);
							msprintf (Dummy, "[%ld;1H", max_lines + 3);
							putreg (REG_A6,exebase);
							writetexti (Dummy, usea4a5);
						}
					}							
					else if (active_conf < max_confs)
					{
						putreg (REG_A6,exebase);
						writetexti ("[1B", usea4a5); 
						cursor++;
					}
					active_conf++;
				}
				break;
			}
		}
	}
	msprintf (Dummy, "[%ld;1H[0m", nodebase->CU.PageLength);
	putreg (REG_A6,exebase);
	writetexti (Dummy, usea4a5);

	putreg (REG_A6,exebase);
	writetexti ("\n", usea4a5);
	flag = FALSE;
	for (n = 1; n <= max_confs; n++)
	{
		if ((head[n].flag == MEMBER) OR (head[n].flag == OBLIGATORY)) // Sjekker om vi er medlem...
		{
			if (!(nodebase->CU.firstuserconf[head[n].confnr].uc_Access & ACCF_Read)) // Ikke medlem
			{
				flag = TRUE;
				if (!(stricmp (config->SYSOPname, nodebase->CU.Name)))	// Supersysop?
				{
					nodebase->CU.firstuserconf[head[n].confnr].uc_Access = 0;
					nodebase->CU.firstuserconf[head[n].confnr].uc_Access |= ACCF_Read;
					nodebase->CU.firstuserconf[head[n].confnr].uc_Access |= ACCF_Write;
					nodebase->CU.firstuserconf[head[n].confnr].uc_Access |= ACCF_Upload;
					nodebase->CU.firstuserconf[head[n].confnr].uc_Access |= ACCF_Download;
					nodebase->CU.firstuserconf[head[n].confnr].uc_Access |= ACCF_Sysop;
				}
				else	// Ikke sysop! Må sjekke flags i confen
				{
					if (confarray[head[n].confnr].n_ConfSW & CONFSWF_ImmWrite)
					{
						nodebase->CU.firstuserconf[head[n].confnr].uc_Access |= ACCF_Read;
						nodebase->CU.firstuserconf[head[n].confnr].uc_Access |= ACCF_Write;
					}
					else if (confarray[head[n].confnr].n_ConfSW & CONFSWF_ImmRead)
						nodebase->CU.firstuserconf[head[n].confnr].uc_Access |= ACCF_Read;
				}
				msprintf (Dummy, "[36mJoining: %s\n", confarray[head[n].confnr].n_ConfName);
				putreg (REG_A6,exebase);
				writetexti (Dummy, usea4a5);
			}
		}
		else	// NON_MEMBER
		{
			if (nodebase->CU.firstuserconf[head[n].confnr].uc_Access & ACCF_Read) // Medlem?
			{
				flag = TRUE;
				nodebase->CU.firstuserconf[head[n].confnr].uc_Access = 0;
				msprintf (Dummy, "[31mResigning: %s\n", confarray[head[n].confnr].n_ConfName);
				putreg (REG_A6,exebase);
				writetexti (Dummy, usea4a5);
			}			
		}
	}
	nodebase->linesleft = nodebase->CU.PageLength;
	if (flag)
		saveuser (nodebase->CU.Name, &nodebase->CU);
	putreg (REG_A6,exebase);
	writetexti ("\n", usea4a5);
}

WORD Exists (char *Filename)
{
  BPTR lock = 0;
  struct FileInfoBlock *fib = 0;
  BOOL flag;

	flag = FALSE;
  if (!(fib = (struct FileInfoBlock *)AllocMem (sizeof (struct FileInfoBlock), MEMF_CLEAR)))
    return (ERROR); 

  if (lock = Lock (Filename, ACCESS_READ))
  {
    if (Examine (lock, fib))
      flag = TRUE;
  }

  if (lock)
    UnLock (lock);
  if (fib)
    FreeMem (fib, sizeof (struct FileInfoBlock));

  return (flag);
}

// ******************************************************************************
// ******************************* CheckInvited *********************************
// ******************************************************************************

char You_are_invited[] = "\n[32mYou are invited to the following conference(s):\n\n[33m";

__asm far VOID CheckInvited (a4a5)
{
	struct ConfigRecord *config = &mainmeory->config;
	int n;
	BOOL header_flag = FALSE;
	BOOL save_flag = FALSE;
	UWORD linesleft;

	linesleft = nodebase->linesleft;
	nodebase->linesleft = 65535;		// Slår av more-prompt

	for (n = 2; n < config->Maxconferences; n++)	// Går igjenom alle konfer
	{
		if (*(config->firstconference[n].n_ConfName))	// Er det et navn her?
		{
			if (nodebase->CU.firstuserconf[n].uc_Access & ACCF_Invited)	// Er vi invited?
			{
				nodebase->CU.firstuserconf[n].uc_Access ^= ACCF_Invited; // Sletter bit
				if (!(nodebase->CU.firstuserconf[n].uc_Access & ACCF_Read))
				{	// Ikke medlem
					if (!header_flag)
					{
						header_flag = TRUE;
						putreg (REG_A6,exebase);
						writetexti (You_are_invited, usea4a5);
					}
					nodebase->CU.firstuserconf[n].uc_Access |= ACCF_Read; // Melder inn
					if (config->firstconference[n].n_ConfSW & CONFSWF_ImmWrite)	// Har confen writeaxx??
						nodebase->CU.firstuserconf[n].uc_Access |= ACCF_Write; // Melder inn
					msprintf (Dummy, "%s\n", config->firstconference[n].n_ConfName);
					putreg (REG_A6,exebase);
					writetexti (Dummy, usea4a5);
					save_flag = TRUE;
				}
			}
		}
	}

	if (save_flag)
		saveuser (nodebase->CU.Name, &nodebase->CU);
	nodebase->linesleft = linesleft;	// Vi setter tilbake
}


// ******************************************************************************
// ******************************************************************************
// ******************************************************************************


__asm far VOID Write_user_CPS (register __d5 UWORD cps, a4a5)
{
	msprintf (Dummy, "\n          [0m cps = '%ld'\n", cps);
	putreg (REG_A6,exebase);
	writetexti (Dummy, usea4a5);
}


/*
	msprintf (Dummy, "NodeNumber: %ld", nodebase->NodeNumber);
	writetexto (Dummy, usea4a5);
*/

/*
Sort			[30m
Rød				[31m
Grønn			[32m
Gul				[33m
Mørkeblå	[34m
Lilla			[35m
Lyseblå		[36m
white			[37m

#define CONFSWF_ImmRead		(1L<<0)
#define CONFSWF_ImmWrite	(1L<<1)
#define CONFSWF_PostBox		(1L<<2)
#define CONFSWF_Private		(1L<<3)
#define CONFSWF_VIP			(1L<<4)
#define CONFSWF_Resign		(1L<<5)
#define CONFSWF_Network		(1L<<6)
#define CONFSWF_Alias		(1L<<7)

#define ACCF_Read			(1L<<0)
#define ACCF_Write		(1L<<1)
#define ACCF_Upload		(1L<<2)
#define ACCF_Download	(1L<<3)
#define ACCF_FileVIP	(1L<<4)
#define ACCF_Invited	(1L<<5)
#define ACCF_Sigop		(1L<<6)
#define ACCF_Sysop		(1L<<7)
*/

__asm far VOID JEO_NewFiles (register __d0 ULONG stamp, a4a5)
{
	char Tmp[10], Hold[10];
	char Date[7];
	struct ClockData cd;


	Amiga2Date (stamp, &cd);
	msprintf (Date, "%02ld%02ld%2ld", cd.year, cd.month, cd.mday);
	putreg (REG_A6,exebase);
	mayedlineprompt (6, "[33mDate to scan for YYMMDD: ", Date, usea4a5);
}
