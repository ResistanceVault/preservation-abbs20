;/*
sc5 -j73 -d4 -v ShowConfig
copy ShowConfig.c -J:ShowConfig.c
slink LIB:c.o+"ShowConfig.o" to ShowConfig LIB LIB:sc.lib LIB:JEO.lib ADDSYM
quit
*/

#include <JEO:JEO.h>
#include <bbs.h>
#include <proto/exec.h>
#include <exec/memory.h>
#include <proto/dos.h>
#include <stdio.h>

void typeconfig (struct ConfigRecord *config);

struct ConfigRecord *config;
struct UserRecord *users;

char *vers = "\0$VER: FixConferences v1.00 - 02.10.97";

BOOL ShowUserfile (VOID);
char UserFName[] = "ABBS:Config/UserFile";
char ConfigFName[] = "ABBS:Config/ConfigFile";
char string[10];
int	configsize = 0;
WORD JEO[501];

BOOL SaveConfigfile (struct ConfigRecord *config)
{
	BPTR file = 0;

	printf ("  Saving configfile...\n");
	if (file = Open (ConfigFName, MODE_OLDFILE))
	{
		Seek (file, 10, OFFSET_BEGINNING);
		if (Write (file,	((APTR) (((ULONG) config) + sizeof (string))), (configsize-sizeof (string))))
		{
			Close (file);
			file = NULL;
			return (TRUE);
		}
	}
	return (FALSE);
}

VOID __stdargs __main (char *Line)
{
	BPTR	file = NULL;
	ULONG	ret = 10;
	int n;
	int	usersize = 0;

	if (file = Open (ConfigFName, MODE_OLDFILE))
	{
		n = Read (file, string, sizeof (string));
		if (n == sizeof (string))
			configsize = ((struct ConfigRecord *) &string)->Configsize;
		else
			printf ("\n Error reading file %s!\n\n", ConfigFName);
		if (configsize && (config = AllocVec (configsize,NULL)))
		{
			memcpy (config,string,sizeof (string));

			if ((configsize-sizeof (string)) == Read (file,
					((APTR) (((ULONG) config) + sizeof (string))),
					(configsize-sizeof (string))))
			{
				Close (file);
				file = NULL;
				typeconfig (config);
				ret = 0;
			}
			else
				printf ("\n Error reading file %s!\n\n", ConfigFName);
			if (file)
				 Close (file);
		}
		else
			printf ("\n Error allocating memory!\n\n");
	}
	else
		printf ("\n Error opening file %s! \n\n", ConfigFName);

	ShowUserfile ();
	FreeVec (config);
	return (ret);
}


BOOL SaveConfigFile (VOID)
{
	BPTR file = 0;

	if (file = Open (ConfigFName, MODE_OLDFILE))
	{
		Seek (file, 10, OFFSET_BEGINNING);
		if (Write (file,	((APTR) (((ULONG) config) + sizeof (string))), (configsize-sizeof (string))))
		{
			Close (file);
			file = NULL;
			return (TRUE);
		}
	}
	return (FALSE);
}

void typeconfig (struct ConfigRecord *config)
{
	int	n, i;
	struct FileDirRecord *dirarray;
	BOOL flag;

	printf ("UWORD		Revision = %d\n",config->Revision);
	printf ("ULONG		Configsize = %d\n",config->Configsize);
	printf ("ULONG		UserrecordSize = %d\n",config->UserrecordSize);
	printf ("UWORD		Maxconferences = %d\n",config->Maxconferences);
	printf ("UWORD		MaxfileDirs = %d\n",config->MaxfileDirs);
	printf ("ULONG		Users = %d\n",config->Users);
	printf ("ULONG		MaxUsers = %d\n",config->MaxUsers);
	printf ("NameT		BaseName = %s\n",config->BaseName);
	printf ("NameT		SYSOPname = %s\n",config->SYSOPname);
	printf ("ULONG		SYSOPUsernr = %d\n",config->SYSOPUsernr);
	printf ("NPassT	SYSOPpassword = %s\n",config->SYSOPpassword);
	printf ("NPassT	ClosedPassword = %s\n",config->ClosedPassword);
	printf ("UWORD		MaxLinesMessage = %d\n",config->MaxLinesMessage);
	printf ("UWORD		ActiveConf = %d\n",config->ActiveConf);
	printf ("UWORD		ActiveDirs = %d\n",config->ActiveDirs);
	printf ("UWORD		NewUserTimeLimit = %d\n",config->NewUserTimeLimit);
	printf ("UWORD		SleepTime = %d\n",config->SleepTime);
	printf ("UBYTE		DefaultCharSet = %c\n",config->DefaultCharSet);
	printf ("UBYTE		Cflags = $%x\n",config->Cflags);
	printf ("UWORD		NewUserFileLimit = %d\n",config->NewUserFileLimit);
	printf ("UWORD		ByteRatiov = %d\n",config->ByteRatiov);
	printf ("UWORD		FileRatiov = %d\n",config->FileRatiov);
	printf ("UWORD		MinULSpace = %d\n",config->MinULSpace);
	printf ("UBYTE		Cflags2 = $%x\n",config->Cflags2);
	printf ("UBYTE		pad_a123 = %d\n",config->pad_a123);
	printf ("NPassT	dosPassword = %s\n",config->dosPassword);

	for (n = 0; n < config->Maxconferences; n++)
	{
		if (*(config->firstconference[n].n_ConfName))
		{
			printf ("\n");
			printf ("%03d:%-20s Or = %3d DM = %5d B = %2d M = %2d, 1st = %2d ",
			n,config->firstconference[n].n_ConfName,
			config->firstconference[n].n_ConfOrder,
			config->firstconference[n].n_ConfDefaultMsg,
			config->firstconference[n].n_ConfBullets,
			config->firstconference[n].n_ConfMaxScan,
			config->firstconference[n].n_ConfFirstMsg);

			if (config->firstconference[n].n_ConfSW & CONFSWF_ImmRead)
				printf ("R");
			if (config->firstconference[n].n_ConfSW & CONFSWF_ImmWrite)
				printf ("W");
			if (config->firstconference[n].n_ConfSW & CONFSWF_PostBox)
				printf ("A");
			if (config->firstconference[n].n_ConfSW & CONFSWF_Private)
				printf ("P");
			if (config->firstconference[n].n_ConfSW & CONFSWF_VIP)
				printf ("V");
			if (config->firstconference[n].n_ConfSW & CONFSWF_Resign)
				printf ("E");
			if (config->firstconference[n].n_ConfSW & CONFSWF_Network)
				printf ("N");
			if (config->firstconference[n].n_ConfSW & CONFSWF_Alias)
				printf ("?");
		}
	}

	dirarray = (struct FileDirRecord *)
			(((int) config) + (SIZEOFCONFIGRECORD) +
			(config->Maxconferences * sizeof (struct ConferenceRecord)));

// FixConferences
/*

	if (FindPort (MainPortName))
	{
		printf (" \nABBS must be down for FixConferences to work!\n\n");
		return;
	}

	flag = FALSE;
	for (n = 1; n <= config->Maxconferences; n++)
		JEO[n] = OFF;
	for (n = 0; n < config->Maxconferences; n++)
	{
		if (config->firstconference[n].n_ConfOrder == 0)
		{
			flag = TRUE;
			printf ("\nError in '%s'\n", config->firstconference[n].n_ConfName);
			for (i = 1; i <= config->Maxconferences; i++)
			{
				if (JEO[i] == OFF)
				{
					printf ("Next missing order are %ld\nFixing it...\n", i);
					config->firstconference[n].n_ConfOrder = i;
					JEO[i] = ON;
					break;
				}
			}
		}
		else
			JEO[config->firstconference[n].n_ConfOrder] = ON;
	}
	printf ("\n");
	if (flag)
		SaveConfigFile ();
	else
		printf ("  Conferences ok!\n\n");

	dirarray = (struct FileDirRecord *)
			(((int) config) + (SIZEOFCONFIGRECORD) +
			(config->Maxconferences * sizeof (struct ConferenceRecord)));

	printf ("dirarray = %ld\n", *dirarray);

	for (n = 0; n < config->MaxfileDirs; n++)
	{
		JEO[dirarray[n].n_FileOrder]++;
		if (dirarray[n].n_FileOrder == 0)
		{
			printf ("\nError: in file order!!\n");
			printf ("Dir %d = %-20s\tOr = %3d\tpath = %-20s\n", n, dirarray[n].n_DirName, dirarray[n].n_FileOrder, dirarray[n].n_DirPaths);

			for (i = 1; i <= config->MaxfileDirs; i++)
			{
				if (JEO[i] != 1)
				{
					printf ("Missing number are %ld\nFixing it...\n\n", i);
					dirarray[n].n_FileOrder = i;
					break;
				}
			}
		}
	}
	SaveConfigFile ();
*/
}


VOID ShowUser (struct UserRecord *user, UWORD nr)
{
	int	n;
	BOOL flag = FALSE;

	printf ("******************************************************************\n");
//	user->pass_10			= olduser->pass_10;
	printf ("(%ld) Usernr = %ld\n", nr, user->Usernr);
	printf ("Name: %s\n", user->Name);
//	printf ("Address: %s\n", user->Address);
//	printf ("State: %s\n", user->CityState);
//	printf ("HomeTelno: %s\n", user->HomeTelno);
//	printf ("WorkTelno: %s\n", user->WorkTelno);
//	user->pass_11			= olduser->pass_11;
//	printf ("TimeLimit: %ld\n", user->TimeLimit);
//	printf ("FileLimit: %ld\n", user->FileLimit);
//	printf ("PageLength: %ld\n", user->PageLength);
//	printf ("Protocol			= user->Protocol);
//	printf ("Charset			= user->Charset;
//	printf ("ScratchFormat	= user->ScratchFormat;
//	printf ("XpertLevel		= user->XpertLevel;

	if (user->Userbits & USERF_Killed)
		printf ("Killed!\n");

	printf ("Userbits: $%lx\n", user->Userbits);
//	strncpy (printf ("UserScript,user->UserScript,Sizeof_loginscript);
//	user->ResymeMsgNr		= oldprintf ("ResymeMsgNr;
//	user->MessageFilterV	= oldprintf ("MessageFilterV;
//	user->GrabFormat		= oldprintf ("GrabFormat;
//	user->u_ByteRatiov	= oldprintf ("u_ByteRatiov;
//	user->u_FileRatiov	= oldprintf ("u_FileRatiov;
//	user->Uploaded			= oldprintf ("Uploaded;
//	user->Downloaded		= oldprintf ("Downloaded;
//	user->KbUploaded		= oldprintf ("KbUploaded;
//	user->KbDownloaded	= oldprintf ("KbDownloaded;
//	printf ("Times on: %ld\n", user->TimesOn);
//	memcpy (&user->LastAccess,&user->LastAccess,sizeof (struct DateStamp));
//	printf ("TimeUsed			= user->TimeUsed;
//	printf ("MsgsLeft			= user->MsgsLeft;
//	printf ("MsgsRead			= user->MsgsRead;
//	printf ("Totaltime		= user->Totaltime;
//	printf ("NFday				= user->NFday;
//	printf ("FTimeUsed		= user->FTimeUsed;
//	printf ("Savebits			= user->Savebits;
//	printf ("MsgaGrab			= user->MsgaGrab;

	printf ("\n");
	for (n = 0; n < config->Maxconferences; n++)
	{
		if (*(config->firstconference[n].n_ConfName))
		{
			if ((user->firstuserconf[n].uc_Access & ACCF_Invited))
			{
				printf ("\n");
				printf ("%-30s LastRead: %5ld ", config->firstconference[n].n_ConfName, user->firstuserconf[n].uc_LastRead);

				if (user->firstuserconf[n].uc_Access & ACCF_Read)
					printf ("R");
				if (user->firstuserconf[n].uc_Access & ACCF_Write)
					printf ("W");
				if (user->firstuserconf[n].uc_Access & ACCF_Upload)
					printf ("U");
				if (user->firstuserconf[n].uc_Access & ACCF_Download)
					printf ("D");
				if (user->firstuserconf[n].uc_Access & ACCF_FileVIP)
					printf ("F");
				if (user->firstuserconf[n].uc_Access & ACCF_Invited)
					printf ("I");
				if (user->firstuserconf[n].uc_Access & ACCF_Sigop)
					printf ("S");
				if (user->firstuserconf[n].uc_Access & ACCF_Sysop)
					printf ("Z");
			}
		}
	}
	printf ("\n");
}

BOOL ShowUserfile (VOID)
{
	int	n, i;
	BPTR	in;
	struct UserRecord *user;
	BOOL ret = FALSE;

	printf ("\n\nUserRecord: %ld\n", config->UserrecordSize);
	printf ("MaxUsers: %ld\n\n", config->MaxUsers);
	if (user = AllocMem (config->UserrecordSize * config->MaxUsers, MEMF_CLEAR))
	{
		if (in = Open (UserFName, MODE_OLDFILE))
		{
			for (i = 0; i < config->MaxUsers; i++)
			{
				n = Read (in, user, config->UserrecordSize);
				ShowUser (user, i);
			}
			Close (in);
		}
		else
			printf ("\n Error opening file '%s'!\n\n", UserFName);
		FreeMem (user, config->UserrecordSize * config->MaxUsers);
	}
	else
		printf ("\n Error allocating memory (%d bytes)!\n\n", config->UserrecordSize);

	return (ret);
}
