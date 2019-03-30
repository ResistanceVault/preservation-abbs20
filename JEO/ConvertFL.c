;/*
sc5 -j73 -v ConvertFL
copy ConvertFL.c -J:ConvertFL.c
slink LIB:c.o+"ConvertFL.o" to ConvertFL LIB LIB:sc.lib LIB:JEO.lib ADDSYM
copy ConvertFL.c dabbs:JEO/
copy ConvertFL dabbs:JEO/
quit
*/

#include <bbs.h>
#include <proto/exec.h>
#include <exec/memory.h>
#include <proto/dos.h>
#include <stdio.h>
#include <string.h>

void typeconfig (struct ConfigRecord *config);
BOOL Convert_FL (char *FName);
void FindFLName (void);

UBYTE ConfigFName[] = "ABBS:Config/ConfigFile";
struct ConfigRecord *config;
struct OldConfigRecord oldconfig;

char *vers = "\0$VER: ConvertFL v1.01 - 26.10.97";

UBYTE Dummy[1000];

ULONG main (VOID)
{
	BPTR	file = NULL;
	ULONG	ret = 10;
	char	string[10];
	int	configsize = 0, n;

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
				FindFLName ();
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

	FreeVec (config);
	return (ret);
}

void FindFLName (void)
{
	struct FileDirRecord *dirarray;
	ULONG n;

	dirarray = (struct FileDirRecord *)
			(((int) config) + (SIZEOFCONFIGRECORD) +
			(config->Maxconferences * sizeof (struct ConferenceRecord)));

	for (n = 0; n < config->MaxfileDirs; n++)
	{
		if (dirarray[n].n_DirName[0])
			Convert_FL (dirarray[n].n_DirName);
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
	char to[] = "T:fl.new", FileName[50];
	UBYTE Hold[50];

	strcpy (Hold, FName);
	RemoveSpace (Hold);
	sprintf (FileName, "ABBS:Fileheaders/%s.fl", Hold);
	printf ("Converting: '%s'\n", FileName);
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
			sprintf (Dummy, "C:Copy \"%s\" TO \"%s\"", to, FileName);
			Execute (Dummy, NULL, NULL);
			DeleteFile (to);
		}
		else
			printf ("\n Error opening file '%s'!\n\n", FileName);
	}
	else
		printf ("\n Error allocating memory (%d bytes)!\n\n", config->UserrecordSize);

	return (ret);
}
