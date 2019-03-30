;/*
sc5 -j73 -v -O ConvertConfig
slink LIB:c.o+"ConvertConfig.o" to ConvertConfig LIB LIB:sc.lib LIB:JEO.lib
Copy ConvertConfig ABBS:Utils
Delete ConvertConfig.o ConvertConfig QUIET
quit
*/

char *vers = "\0$VER: ConvertConfig v1.09 - 16.11.97";

#include <JEO.h>
#include <bbs.h>
#include <exec/memory.h>
#include <proto/exec.h>
#include <proto/dos.h>
#include <libraries/reqtools.h>
#include <proto/reqtools.h>

struct ReqToolsBase *ReqToolsBase = 0;

struct ConfigRecord *config = 0;
struct OldConfigRecord *oldconfig;

BOOL new;
BOOL	buildnewconfigfile (VOID);
BOOL	convertuserfile (VOID);
VOID convertuser (struct OldUserRecord *olduser,struct UserRecord *newuser);
BOOL DoIndex (VOID);
UBYTE ConfigFName[] = "ABBS:Config/Configfile";
UBYTE UserFName[] = "ABBS:Config/Userfile";
UBYTE UserIndexFName[] = "ABBS:Config/Userfile.index";
UBYTE Dummy[1000];

int	numconfs, numdirs;

BOOL convertuserfile (VOID)
{
	int	n;
	BPTR	in,out;
	struct OldUserRecord olduser;
	struct UserRecord *newuser;
	BOOL	ret = FALSE;
	UBYTE to[] = "T:UserFile.new";
	WORD copy;

	if (newuser = AllocMem (config->UserrecordSize,MEMF_CLEAR))
	{
		if (in = Open (UserFName, MODE_OLDFILE))
		{
			if (out = Open (to, MODE_NEWFILE))
			{
				while (TRUE)
				{
					n = Read (in, &olduser,sizeof (struct OldUserRecord));
					if (n != sizeof (struct OldUserRecord))
					{
						if (!n)
						{
							ret = TRUE;
							break;
						}
						printf (" \nError reading file %s\n\n", UserFName);
						break;
					}
					convertuser (&olduser, newuser);

					if (config->UserrecordSize != Write (out, newuser, config->UserrecordSize))
					{
						printf ("\n Error writing file %s\n\n", to);
						ret = FALSE;
						break;
					}
				}
				Close (out);
			}
			else
				printf ("\n Error opening file '%s'!\n\n", to);
			Close (in);

			copy = Copyfile (to, UserFName, 200);
			if (copy != COPYFILE_OK)
			{
				switch (copy)
				{
					case COPYFILE_OPENFROM: printf ("\n COPYFILE: Error opening file: %s!\n\n", to); break;
					case COPYFILE_OPENTO: printf ("\n COPYFILE: Error opening file: %s!\n\n", UserFName); break;
					case COPYFILE_MEM: printf ("\n COPYFILE: Not enough memory!\n\n"); break;
					case COPYFILE_WRITE: printf ("\n COPYFILE: Error writeing file %s!\n\n", UserFName); break;
					case COPYFILE_NAME: printf ("\n COPYFILE: Error in names!\n\n"); break;
					case COPYFILE_ZEROSIZE: printf ("\n COPYFILE: Error in filesize (0) %s!\n\n", to); break;
				}
			}
			else
				DeleteFile (to);
		}
		else
			printf ("\n Error opening file '%s'!\n\n", UserFName);
	}
	else
		printf ("\n Error allocating memory (%d bytes)!\n\n", config->UserrecordSize);

	return (ret);
}

void convertuser (struct OldUserRecord *olduser,struct UserRecord *newuser)
{
	int	n;

	memset (newuser,'\0',config->UserrecordSize);
	newuser->pass_10			= olduser->pass_10;
	newuser->Usernr			= olduser->Usernr;

	if (new)	// BARE 1 bruker og det er sysop!
	{
		strncpy (newuser->Name, config->SYSOPname, Sizeof_NameT);
		DoIndex ();
	}
	else
		strncpy (newuser->Name, olduser->Name, Sizeof_NameT);
	memcpy (newuser->Password,olduser->Password,Sizeof_PassT+1);
	strncpy (newuser->Address,olduser->Address,Sizeof_NameT);
	strncpy (newuser->CityState,olduser->CityState,Sizeof_NameT);
	strncpy (newuser->HomeTelno,olduser->HomeTelno,Sizeof_TelNo);
	strncpy (newuser->WorkTelno,olduser->WorkTelno,Sizeof_TelNo);
	newuser->pass_11			= olduser->pass_11;
	newuser->TimeLimit		= olduser->TimeLimit;
	newuser->FileLimit		= olduser->FileLimit;
	newuser->PageLength		= olduser->PageLength;
	newuser->Protocol			= olduser->Protocol;
	newuser->Charset			= olduser->Charset;
	newuser->ScratchFormat	= olduser->ScratchFormat;
	newuser->XpertLevel		= olduser->XpertLevel;
	newuser->Userbits			= olduser->Userbits;
	strncpy (newuser->UserScript,olduser->UserScript,Sizeof_loginscript);
	newuser->pad_1332			= 0;
	newuser->ResymeMsgNr		= olduser->ResymeMsgNr;
	newuser->MessageFilterV	= olduser->MessageFilterV;
	newuser->GrabFormat		= olduser->GrabFormat;
	newuser->u_ByteRatiov	= olduser->u_ByteRatiov;
	newuser->u_FileRatiov	= olduser->u_FileRatiov;
	newuser->Uploaded			= olduser->Uploaded;
	newuser->Downloaded		= olduser->Downloaded;
	newuser->KbUploaded		= olduser->KbUploaded;
	newuser->KbDownloaded	= olduser->KbDownloaded;
	newuser->TimesOn			= olduser->TimesOn;
	memcpy (&newuser->LastAccess,&olduser->LastAccess,sizeof (struct DateStamp));
	newuser->TimeUsed			= olduser->TimeUsed;
	newuser->MsgsLeft			= olduser->MsgsLeft;
	newuser->MsgsRead			= olduser->MsgsRead;
	newuser->Totaltime		= olduser->Totaltime;
	newuser->NFday				= olduser->NFday;
	newuser->FTimeUsed		= olduser->FTimeUsed;
	newuser->Savebits			= olduser->Savebits;
	newuser->MsgaGrab			= olduser->MsgaGrab;
	
	for (n = 0; n < config->Maxconferences; n++) 
	{
		newuser->firstuserconf[n].uc_Access		= olduser->ConfAccess[n];
		newuser->firstuserconf[n].uc_LastRead	= olduser->Conflastread[n];
	}
}

VOID RemoveSpace (char *String)
{
	ULONG i;

	for (i = 0; String[i] != 0; i++)
	{
		if (String[i] == '/')
			String[i] = ' ';
	}
}

BOOL Convert_FL (char *FName)
{
	int	n;
	BPTR	in, out;
	struct OldFileEntry old_fl;
	struct Fileentry *new_fl;
	BOOL	ret = FALSE;
	char to[] = "T:fl.new", FileName[50], New_filename[50];
	UBYTE Hold[50];
	WORD copy;

	strcpy (Hold, FName);
	RemoveSpace (Hold);
	sprintf (FileName, "ABBS:Conferences/%s.fl", Hold);
	sprintf (New_filename, "ABBS:Fileheaders/%s.fl", Hold);
	if (FileSize (FileName) > 0)
	{
		if (new_fl = AllocMem (sizeof (struct Fileentry), MEMF_CLEAR))
		{
			if (in = Open (FileName, MODE_OLDFILE))
			{
				if (out = Open (to, MODE_NEWFILE))
				{
					while (TRUE)
					{
						n = Read (in, &old_fl,sizeof (struct Fileentry));	// Har samme størrelse
						if (n != sizeof (struct Fileentry))
						{
							if (!n)
							{
								ret = TRUE;
								break;
							}
							printf (" \nError reading file %s\n\n", FileName);
							break;
						}
						strcpy (new_fl->Filename, old_fl.fe_Name);
						new_fl->pad1 = 0;
						new_fl->Filestatus = old_fl.fe_Flags;
						new_fl->Fsize = old_fl.fe_Size;
						new_fl->Uploader = old_fl.fe_Sender;
						new_fl->PrivateULto = old_fl.fe_Receiver;
						new_fl->AntallDLs = old_fl.fe_DLoads;
						new_fl->Infomsgnr = old_fl.fe_MsgNr;
						new_fl->ULdate = old_fl.fe_DateStamp;
						strncpy (new_fl->Filedescription, old_fl.fe_Descr, Sizeof_FileDescription);
						new_fl->pad2 = 0;

						if (sizeof (struct Fileentry) != Write (out, new_fl, sizeof (struct Fileentry)))
						{
							printf ("\n Error writing file %s\n\n", to);
							ret = FALSE;
							break;
						}
					}
					Close (out);
				}
				else
					printf ("\n Error opening file '%s'!\n\n", to);
				Close (in);

				copy = Copyfile (to, New_filename, 200);
				if (copy == COPYFILE_OK)
				{
					DeleteFile (to);
					DeleteFile (FileName);
				}
				else switch (copy)
				{
					case COPYFILE_OPENFROM: printf ("\n COPYFILE: Error opening file: %s!\n\n", to); break;
					case COPYFILE_OPENTO: printf ("\n COPYFILE: Error opening file: %s!\n\n", FileName); break;
					case COPYFILE_MEM: printf ("\n COPYFILE: Not enough memory!\n\n"); break;
					case COPYFILE_WRITE: printf ("\n COPYFILE: Error writeing file %s!\n\n", FileName); break;
					case COPYFILE_NAME: printf ("\n COPYFILE: Error in names!\n\n"); break;
					case COPYFILE_ZEROSIZE: printf ("\n COPYFILE: Error in filesize (0) %s!\n\n", to); break;
				}
			}
			else
				printf ("\n Error opening file '%s'!\n\n", FileName);
		}
		else
			printf ("\n Error allocating memory (%d bytes)!\n\n", config->UserrecordSize);
	}

	return (ret);
}

typedef struct
{
	ULONG Dummy[2];
	NameT	Name;
} Index;

BOOL DoIndex (VOID)
{
	BPTR fh;
	Index index;
	BOOL ret = FALSE;

	if (fh = Open (UserIndexFName, MODE_OLDFILE))
	{
		if (Read (fh, &index, sizeof (Index)))
		{
			strncpy (index.Name, config->SYSOPname, Sizeof_NameT);
			Seek (fh, 0, OFFSET_BEGINNING);
			if (Write (fh, &index, sizeof (Index)))
				ret = TRUE;
		}
		Close (fh);
	}
	return (ret);
}

ULONG main (int argc, char **argv)
{
	BPTR file, lock;
	int	ret = 10;
	LONG size;

//	printf ("%ld %ld\n", sizeof (struct OldFileEntry), sizeof (struct Fileentry));

	if (argc != 3)
	{
		printf ("\n  Usage: ConvertConfig <# of file dirs> <# of conferences>\n\n");
		exit (0);
	}

	numdirs = atoi (argv[1]);
	if (numdirs < 100 OR numdirs > 500)
	{
		printf ("\n Error: # of file dirs (100-500)!\n\n");
		exit (0);
	}
	
	numconfs = atoi (argv[2]);
	if (numconfs < 100 OR numconfs > 500)
	{
		printf ("\n Error: # of conferences (100 - 500)!\n\n");
		exit (0);
	}

	if (FindPort (MainPortName))
	{
		printf ("\n  ABBS must be down for ConvertConfig to work!\n\n");
		exit (0);
	}

	if (!(oldconfig = AllocMem (sizeof (struct OldConfigRecord), MEMF_CLEAR)))
		exit (0);	

	if (ReqToolsBase = (struct ReqToolsBase *)OpenLibrary (REQTOOLSNAME, REQTOOLSVERSION))
	{
		if (file = Open (ConfigFName, MODE_OLDFILE))	// Gammel config
		{
			size = FileSize (ConfigFName);
			if (size == sizeof (struct OldConfigRecord))
			{
				if (Read (file, oldconfig, sizeof (struct OldConfigRecord)))
				{
					printf ("\n Converting '%s'...\n", ConfigFName);
					Close (file);
					file = 0;
		
				  lock = CreateDir ("ABBS:FileHeaders");
				 	if (lock)
			    	UnLock (lock);

					if (buildnewconfigfile ())	// Convert configfile
					{
						if (file = Open (ConfigFName, MODE_NEWFILE)) // Save configfile
						{
							if (config->Configsize == Write (file, config, config->Configsize))
								ret = 0;
							else
								printf ("\n Error writing file %s\n\n", ConfigFName);
							Close (file);
							file = NULL;
						}
						else
							printf ("\n Error writing '%s'!\n\n", ConfigFName);
						if (!ret)	// Alt ok?
						{
							printf (" Converting '%s'..\n", UserFName);
							if (convertuserfile ())
								ret = 0;
							else
								ret = 10;
							printf ("\n All done! Please start ABBS and run ConfigBBS\n\n");
						}
					}
					else
						printf ("\n Error creating new ConfigFile\n\n");
					if (config)
						FreeMem (config, config->Configsize);
				}
				else
					printf ("\n Error reading file '%s'!\n\n", ConfigFName);
			}
			else
				printf ("\n %s is allready converted!\n\n", ConfigFName);
			if (file)
				 Close (file);
		}
		else
			printf ("\n Error opening file '%s'!\n\n", ConfigFName);

	  if (ReqToolsBase)
	    CloseLibrary ((struct Library *)ReqToolsBase);
	}
	else
		printf ("\n Error loading 'reqtools.library'!\n\n");

	FreeMem (oldconfig, sizeof (struct OldConfigRecord));
	return (ret);
}

BOOL Check_name (char *Name)
{
	int i;
	UBYTE space = 0;

	for (i = 0; Name[i] != 0; i++)
	{
		if (Name[i] == ' ')
			space++;
	}
	if (space == 1)	// Vi må ha 1 space!
		return (TRUE);
	else
		return (FALSE);
}

BOOL buildnewconfigfile (void)
{
	int	n;
	struct ConferenceRecord *confarray;
	struct FileDirRecord *dirarray;

	n = SIZEOFCONFIGRECORD + 
		(sizeof (struct ConferenceRecord) * numconfs) +
		(sizeof (struct FileDirRecord) * numdirs);

//	printf ("size = %d\n",n);
	if (config = AllocMem (n, MEMF_CLEAR))
	{
		config->Revision = ConfigRev;
		config->Configsize = n;
		config->UserrecordSize = SIZEOFUSERRECORD +	sizeof (struct Userconf)*numconfs;
		config->Maxconferences = numconfs;
		config->MaxfileDirs = numdirs;
		config->Users = oldconfig->Users;
		config->MaxUsers = oldconfig->MaxUsers;

		new = FALSE;
		if (!(strcmp (oldconfig->SYSOPname, "·*· ·*·")))	// Ny :)
		{
			new = TRUE;
			while (!Check_name (config->SYSOPname))	// Bør vel ha riktig navn?
			{
				memset (config->SYSOPname, '\0', sizeof (config->SYSOPname));
				GetReqString (config->SYSOPname, Sizeof_NameT, "Enter sysop name:");
			}
		}
		else
			strncpy (config->SYSOPname, oldconfig->SYSOPname, Sizeof_NameT);

		memset (config->SYSOPpassword, '\0', sizeof (config->SYSOPpassword));
		if (!new)
			strncpy (config->SYSOPpassword, oldconfig->SYSOPpassword, Sizeof_PassT);

		memset (config->BaseName, '\0', sizeof (config->BaseName));
		if (new)
		{
			while (!(*(config->BaseName)))	// Bør vel ha navn?
			{
				memset (config->BaseName, '\0', sizeof (config->BaseName));
				GetReqString (config->BaseName, Sizeof_NameT, "Enter base name:");
			}
		}
		else
			strncpy (config->BaseName, oldconfig->BaseName, Sizeof_NameT);

		config->SYSOPUsernr = oldconfig->SYSOPUsernr;
		config->MaxLinesMessage = oldconfig->MaxLinesMessage;
		config->ActiveConf = oldconfig->ActiveConf;
		config->ActiveDirs = oldconfig->ActiveDirs;
		config->NewUserTimeLimit = oldconfig->NewUserTimeLimit;
		config->SleepTime = oldconfig->SleepTime;
		memset (config->ClosedPassword,'\0',sizeof (config->ClosedPassword));
		config->DefaultCharSet = oldconfig->DefaultCharSet;
		config->Cflags = oldconfig->Cflags;
		config->NewUserFileLimit = oldconfig->NewUserFileLimit;
		config->ByteRatiov = oldconfig->ByteRatiov;
		config->FileRatiov = oldconfig->FileRatiov;
		config->MinULSpace = oldconfig->MinULSpace;
		config->Cflags2 = oldconfig->Cflags2;
		config->pad_a123 = 0;
		memset (config->dosPassword,'\0',sizeof (config->dosPassword));
		strncpy (config->dosPassword,oldconfig->dosPassword,Sizeof_PassT);
		memset (config->cnfg_empty,'\0',sizeof (config->cnfg_empty));
		config->firstFileDirRecord = 0;

		confarray = (struct ConferenceRecord *) (((int) config) + (SIZEOFCONFIGRECORD));

		for (n = 0; n < numconfs; n++)
		{
			memset (&confarray[n], '\0', sizeof (struct ConferenceRecord));
			if (n < 100)	// Ikke over v1.1?
			{
				if (*(oldconfig->ConfNames[n]))
				{
					printf ("Conference name: %s\n", oldconfig->ConfNames[n]);
					strncpy (confarray[n].n_ConfName,oldconfig->ConfNames[n],Sizeof_NameT);
					confarray[n].n_ConfBullets = oldconfig->ConfBullets[n];
					confarray[n].n_ConfDefaultMsg = oldconfig->ConfDefaultMsg[n];
					confarray[n].n_ConfFirstMsg = 1;
					confarray[n].n_ConfSW = oldconfig->ConfSW[n];
					confarray[n].n_ConfMaxScan = oldconfig->ConfMaxScan[n];
				}
			}
			confarray[n].n_ConfOrder = n + 1;	// Vi gjør riktig her!
		}

		dirarray = (struct FileDirRecord *)
				(((int) config) + (SIZEOFCONFIGRECORD) +
				(numconfs * sizeof (struct ConferenceRecord)));

		for (n = 0; n < numdirs; n++)
		{
			memset (&dirarray[n], '\0', sizeof (struct FileDirRecord));
			if (n < 100)	// Ikke over v1.1
			{
				if (*(oldconfig->DirNames[n]))
				{
					printf ("File dir: %s\n", oldconfig->DirNames[n]);
					Convert_FL (oldconfig->DirNames[n]);
					strncpy (dirarray[n].n_DirName,oldconfig->DirNames[n],Sizeof_NameT);
					strncpy (dirarray[n].n_DirPaths,oldconfig->DirPaths[n],Sizeof_NameT);
					dirarray[n].n_FileOrder = oldconfig->FileOrder[n];
					dirarray[n].n_PrivToConf = 0;
				}
			}
			dirarray[n].n_FileOrder = n + 1;
		}

		return (TRUE);
	}
	else
	{
		printf ("Error allocating memory (%d bytes)\n",n);
		return (FALSE);
	}
}
