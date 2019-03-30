
#include <bbs.h>

#include <dos/rdargs.h>
#include <exec/memory.h>

#include <proto/exec.h>
#include <proto/dos.h>

#include <stdio.h>
#include <string.h>

struct ConfigRecord *config;
struct OldConfigRecord oldconfig;

int	main(int argc, char **argv);
BOOL	buildnewconfigfile(void);
BOOL	convertuserfile (char *from,char *to);
void convertuser (struct OldUserRecord *olduser,struct UserRecord *newuser);

#define TEMPLATE "OldConfig/A,OldUserfile/A,Newconfig,Newuserfile"
#define OPT_COUNT 4

char *vers = "\0$VER: ConvertConfig v1.0";

int main(int argc, char **argv)
{
	BPTR	file = NULL;
	char	toname[80];
	char	usertoname[80];
	int	ret = 10;
	struct RDArgs *RDArg;
	LONG	*result[OPT_COUNT] = {0,0,0,0};

	if (RDArg = ReadArgs(TEMPLATE,(long *) result,NULL)) {
		if (file = Open ((char *) result[0],MODE_OLDFILE)) {
			if (sizeof (struct OldConfigRecord) == Read (file,&oldconfig,
					sizeof (struct OldConfigRecord))) {
				Close (file);

				if (buildnewconfigfile()) {
					if (result[2])
						strcpy (toname,(char *) result[2]);
					else
						sprintf (toname,"%s.new",(char *) result[0]);

					if (result[3])
						strcpy (usertoname,(char *) result[3]);
					else
						sprintf (usertoname,"%s.new",(char *) result[1]);

					if (file = Open (toname,MODE_NEWFILE)) {
						if (config->Configsize == Write (file,config,config->Configsize)) {
							ret = 0;
						} else
							printf ("Error writing file %s\n",toname);
						Close (file);
						file = NULL;
					} else
						printf ("Error opening file %s (for write)\n",toname);

					if (!ret)
						if (convertuserfile ((char *) result[1],usertoname))
							ret = 0;
						else
							ret = 10;

					if (config)
						FreeMem (config,config->Configsize);
				} else
					printf ("Error creating new config\n");
			} else
				printf ("Error reading file %s\n",(char *) result[0]);
			if (file)
				 Close (file);
		} else
			printf ("Error opening file %s\n",(char *) result[0]);
		FreeArgs (RDArg);
	} else
		PrintFault(IoErr(),argv[0]);

	return (ret);
}

BOOL	convertuserfile (char *from,char *to)
{
	int	n;
	BPTR	in,out;
	struct OldUserRecord olduser;
	struct UserRecord *newuser;
	BOOL	ret = FALSE;

	if (newuser = AllocMem (config->UserrecordSize,MEMF_CLEAR)) {
		if (in = Open (from,MODE_OLDFILE)) {
			if (out = Open (to,MODE_NEWFILE)) {
				while (TRUE) {
					n = Read (in,&olduser,sizeof (struct OldUserRecord));
					if (n != sizeof (struct OldUserRecord)) {
						if (!n) {
							ret = TRUE;
							break;
						}
						printf ("Error reading file %s\n",from);
						break;
					}
					convertuser (&olduser,newuser);

					if (config->UserrecordSize != Write (out,newuser,
							config->UserrecordSize)) {
						printf ("Error writing file %s\n",to);
						break;
					}
				}
				Close (out);
			} else
				printf ("Error opening file %s\n",to);
			Close (in);
		} else
			printf ("Error opening file %s\n",from);
	} else
		printf ("Error allocating memory (%d bytes)\n",config->UserrecordSize);

	return (ret);
}

void convertuser (struct OldUserRecord *olduser,struct UserRecord *newuser)
{
	int	n;

	memset (newuser,'\0',config->UserrecordSize);
	newuser->pass_10			= olduser->pass_10;
	newuser->Usernr			= olduser->Usernr;
	strncpy (newuser->Name,olduser->Name,Sizeof_NameT);
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

	for (n = 0; n < config->Maxconferences; n++) {
		newuser->firstuserconf[n].uc_Access		= olduser->ConfAccess[n];
		newuser->firstuserconf[n].uc_LastRead	= olduser->Conflastread[n];
	}
}

BOOL	buildnewconfigfile(void)
{
	int	n;
	int	numconfs = 100;
	int	numdirs = 100;
	struct ConferenceRecord *confarrray;
	struct FileDirRecord *dirarrray;

	n = SIZEOFCONFIGRECORD + 
		(sizeof (struct ConferenceRecord) * numconfs) +
		(sizeof (struct FileDirRecord) * numdirs);

/*	printf ("size = %d\n",n);
*/
	if (config = AllocMem (n,MEMF_CLEAR)) {
		config->Revision	= ConfigRev;
		config->Configsize = n;
		config->UserrecordSize = SIZEOFUSERRECORD +
				sizeof (struct Userconf)*numconfs;
		config->Maxconferences = numconfs;
		config->MaxfileDirs = numdirs;
		config->Users = oldconfig.Users;
		config->MaxUsers = oldconfig.MaxUsers;
		strncpy (config->BaseName,oldconfig.BaseName,Sizeof_NameT);
		strncpy (config->SYSOPname,oldconfig.SYSOPname,Sizeof_NameT);
		config->SYSOPUsernr = oldconfig.SYSOPUsernr;
		memset (config->SYSOPpassword,'\0',sizeof (config->SYSOPpassword));
		strncpy (config->SYSOPpassword,oldconfig.SYSOPpassword,Sizeof_PassT);
		config->MaxLinesMessage = oldconfig.MaxLinesMessage;
		config->ActiveConf = oldconfig.ActiveConf;
		config->ActiveDirs = oldconfig.ActiveDirs;
		config->NewUserTimeLimit = oldconfig.NewUserTimeLimit;
		config->SleepTime = oldconfig.SleepTime;
		memset (config->ClosedPassword,'\0',sizeof (config->ClosedPassword));
		config->DefaultCharSet = oldconfig.DefaultCharSet;
		config->Cflags = oldconfig.Cflags;
		config->NewUserFileLimit = oldconfig.NewUserFileLimit;
		config->ByteRatiov = oldconfig.ByteRatiov;
		config->FileRatiov = oldconfig.FileRatiov;
		config->MinULSpace = oldconfig.MinULSpace;
		config->Cflags2 = oldconfig.Cflags2;
		config->pad_a123 = 0;
		memset (config->dosPassword,'\0',sizeof (config->dosPassword));
		strncpy (config->dosPassword,oldconfig.dosPassword,Sizeof_PassT);
		memset (config->cnfg_empty,'\0',sizeof (config->cnfg_empty));
		config->firstFileDirRecord = 0;

		confarrray = (struct ConferenceRecord *) 
				(((int) config) + (SIZEOFCONFIGRECORD));

		for (n = 0; n < numconfs; n++) {
			if (*(oldconfig.ConfNames[n])) {
				strncpy (confarrray[n].n_ConfName,oldconfig.ConfNames[n],Sizeof_NameT);
				confarrray[n].n_ConfBullets = oldconfig.ConfBullets[n];
				confarrray[n].n_ConfDefaultMsg = oldconfig.ConfDefaultMsg[n];
				confarrray[n].n_ConfFirstMsg = 1;
				confarrray[n].n_ConfOrder = oldconfig.ConfOrder[n];
				confarrray[n].n_ConfSW = oldconfig.ConfSW[n];
				confarrray[n].n_ConfMaxScan = oldconfig.ConfMaxScan[n];
			} else {
				memset (&confarrray[n],'\0',sizeof (struct ConferenceRecord));
			}
		}

		dirarrray = (struct FileDirRecord *)
				(((int) config) + (SIZEOFCONFIGRECORD) +
				(numconfs * sizeof (struct ConferenceRecord)));

		for (n = 0; n < numdirs; n++) {
			if (*(oldconfig.DirNames[n])) {
				strncpy (dirarrray[n].n_DirName,oldconfig.DirNames[n],Sizeof_NameT);
				strncpy (dirarrray[n].n_DirPaths,oldconfig.DirPaths[n],Sizeof_NameT);
				dirarrray[n].n_FileOrder = oldconfig.FileOrder[n];
				dirarrray[n].n_PrivToConf = 0;
			} else {
				memset (&dirarrray[n],'\0',sizeof (struct FileDirRecord));
			}
		}

		return (TRUE);
	} else {
		printf ("Error allocating memory (%d bytes)\n",n);
		return (FALSE);
	}
}
