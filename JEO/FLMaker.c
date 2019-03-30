;/*
sc5 -j73 -v -O FLMaker
copy FLMaker.c -J:FLMaker.c
slink LIB:c.o+"FLMaker.o" to FLMaker LIB LIB:sc.lib LIB:JEO.lib
copy FLMaker ABBS:Utils
quit
*/

#include <JEO:JEO.h>
#include <bbs.h>
#include <proto/exec.h>
#include <exec/memory.h>
#include <proto/dos.h>

struct ConfigRecord *config;

char *vers = "\0$VER: FLMaker v1.04a - 01.02.98";
char ver[] = "v1.04a";

char ConfigFName[] = "ABBS:Config/ConfigFile";
char string[10];
int	configsize = 0;
char Line[200];
char DirHeader[] = "  File name          Date     Size    Dls File description\n  ------------------ -------- ------- --- ------------------------------------\n";
BPTR fh;
BOOL screen, add_private_conf;

BOOL Open_file (char *Filename)
{
	if (!screen)
	{
		if (!(fh = Open (Filename, MODE_NEWFILE)))
		return (FALSE);
	}
	return (TRUE);
}

BOOL Write_file (char *Buffer)
{
	int err, len;

	if (screen)
		printf ("%s", Buffer);
	else
	{
		len = strlen (Buffer);
		err = Write (fh, Buffer, len);
		if (err != len)
			return (FALSE);
	}
	return (TRUE);
}

VOID Close_file (VOID)
{
	if (!screen)
		Close (fh);
}

VOID Do_fl_name (char *String)
{
	ULONG i;

	for (i = 0; String[i] != 0; i++)
	{
		if (String[i] == '/')
			String[i] = ' ';
	}
}

VOID stamptoDateTime (struct DateStamp *stamp, char *Date)
{
	struct DateTime dt;
	char Day[LEN_DATSTRING], Time[LEN_DATSTRING];

	dt.dat_Stamp.ds_Days		= stamp->ds_Days;
	dt.dat_Stamp.ds_Minute	= stamp->ds_Minute;
	dt.dat_Stamp.ds_Tick		= stamp->ds_Tick;
	dt.dat_Format	= FORMAT_CDN;
	dt.dat_Flags	= 0;
	dt.dat_StrDay	 = Day;
	dt.dat_StrDate = Date;
	dt.dat_StrTime	= Time;
	DateToStr (&dt);
}

int MakeLine (struct Fileentry *fe)
{
	char Info[2] = " ";
	char Date[LEN_DATSTRING];

	if (fe->Filename[0] == 0)
		return (FALSE);
	if (fe->Filestatus & FILESTATUSF_PrivateUL)
		return (FALSE);
	if (fe->Filestatus & FILESTATUSF_Filemoved)
		return (FALSE);
	if (fe->Filestatus & FILESTATUSF_Fileremoved)
		return (FALSE);
	if (!add_private_conf)
	{
		if (fe->Filestatus & FILESTATUSF_PrivateConfUL)
			return (FALSE);
	}

	stamptoDateTime	(&fe->ULdate, Date);
	if (fe->Infomsgnr)
		Info[0] = 'I';
	
	sprintf (Line, "%s %-18s %s %7ld %3ld %s\n",
					Info, fe->Filename, Date, fe->Fsize, fe->AntallDLs, fe->Filedescription);
	if (!Write_file (Line))
		return (ERROR);
	else
		return ((int)fe->Fsize);
}

VOID FLMaker (struct ConfigRecord *config, char *Filename)
{
	int	n;
	struct FileDirRecord *dirarray;
	int i;
  char Hold[108], DirFilename[108];
  int size;
  char *Buffer;
  BPTR fh;
  ULONG files, fileSize, countSize, totFiles, totSize, totDls;
  char Date[10], Time[10];
	struct Fileentry *temp;

	dirarray = (struct FileDirRecord *)
			(((int) config) + (SIZEOFCONFIGRECORD) +
			(config->Maxconferences * sizeof (struct ConferenceRecord)));

	totFiles = totSize = totDls = 0;
	if (Open_file (Filename))
	{
		GetDateTime (Date, Time);
		sprintf (Line, "\n                Date and time of creation: %s  %s\n", Date, Time);
		Write_file (Line);
		for (n = 1; n < config->MaxfileDirs; n++)	// Skipper private
		{
			if (*(dirarray[n].n_DirName))
			{
				strcpy (Hold, dirarray[n].n_DirName);
				Do_fl_name (Hold);
				sprintf (DirFilename, "ABBS:Fileheaders/%s.fl", Hold);
				size = FileSize (DirFilename);
				if (size > 0)
				{
					sprintf (Line, "\nListing of directory %s:\n\n", dirarray[n].n_DirName);
					Write_file (Line);
					Write_file (DirHeader);
					if (Buffer = AllocMem (size, MEMF_CLEAR))
					{
						files = countSize = 0;
						if (fh = Open (DirFilename, MODE_OLDFILE))
						{
							Read (fh, Buffer, size);
							Close (fh);

							for (i = 0; i < size; i += sizeof (struct Fileentry)) 
							{
								temp = (struct Fileentry *)&Buffer[i];
								if (fileSize = MakeLine (temp))
								{
									totDls += temp->AntallDLs;
									files++;
									countSize += fileSize;
								}
							}
							totFiles += files;
							totSize += countSize;
							sprintf (Line, "\n %ld %s listed in directory %s, %ld Kb\n",  files, files == 1 ? "file" : "files", dirarray[n].n_DirName, countSize / 1024);
							Write_file (Line);
						}
						FreeMem (Buffer, size);
					}
				}
			}
		}
		Write_file ("\n\n      STATISTICS:\n\n");
		sprintf (Line, "     Directories: %6ld\n", config->ActiveDirs);
		Write_file (Line);
		sprintf (Line, "    Files listed: %6ld\n", totFiles);
		Write_file (Line);
		sprintf (Line, " Total file size: %6ld (Mb)\n", totSize / (1024 * 1024));
		Write_file (Line);
		sprintf (Line, " Total downloads: %6ld\n", totDls);
		Write_file (Line);
		sprintf (Line, "\n List created with FLMaker %s, written by Jan Erik Olausen\n", ver);
		Write_file (Line);
		Close_file ();
	}
}

BOOL main (int argc, char **argv)
{
	BPTR file;
	int n;
	char ConfigFName[] = "ABBS:Config/ConfigFile";
	char string[10];
	struct ConfigRecord *config;

	if (argc != 3)
	{
		printf ("\n Usage: FLMaker <file> <include private confs [ON/OFF]>\n\n");
		exit (0);
	}
	
	if (!(stricmp (argv[2], "ON")))
		add_private_conf = ON;
	else
		add_private_conf = OFF;
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
				FLMaker (config, argv[1]);
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
}
