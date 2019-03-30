;/*
sc5 -j73 -v -O SortFiles
copy SortFiles.c -J:SortFiles.c
slink LIB:c.o+"SortFiles.o" to SortFiles LIB LIB:sc.lib LIB:reqtools.lib LIB:JEO.lib
Copy SortFiles ABBS:Utils
quit
*/

#include <JEO:JEO.h>
#include <bbs.h>
#include <proto/exec.h>
#include <exec/memory.h>
#include <proto/dos.h>
#include <libraries/reqtools.h>
#include <proto/reqtools.h>

VOID SortConfs (VOID);
VOID SortDirs (VOID);
BOOL Do_files (VOID);

struct ReqToolsBase *ReqToolsBase = 0;
struct ConfigRecord *config;

char *vers = "\0$VER: SortFiles v1.03 - 21.08.98";
char Dummy[1000];
char Ok[] = "Ok";
char ConfigFName[] = "ABBS:Config/ConfigFile";
char string[10];
int	configsize = 0;
char Message[] = "Message";

#define MAX_FILES	5000
struct Fileentry far fl_all[MAX_FILES];
int max_files;

VOID main (VOID)
{
	BPTR file = NULL;
	int n;

  if (FindPort ("ABBS mainport"))
  {
		JEOEasyRequest (NULL, Message, "Please close ABBS!", Ok, NULL);
    exit (0);
	}

	if (!(ReqToolsBase = (struct ReqToolsBase *)OpenLibrary ("reqtools.library", REQTOOLSVERSION)))
	{
		sprintf (Dummy, "SortFiles needs '%s' v%ld +", REQTOOLSNAME, REQTOOLSVERSION);
		JEOEasyRequest (NULL, Message, Dummy, Ok, NULL);
		Exit (0);
	}

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
//				if (JEOReqRequest (Message, "Want to sort conferences?", "Yes|No"))
//					SortConfs ();
				if (JEOReqRequest (Message, "Want to sort directories?", "Yes|No"))
					SortDirs ();
				if (!Do_files ())
					printf ("\n  Error sorting files!\n\n");
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
	printf ("\n  Done!\n\n");
	if (ReqToolsBase)
		CloseLibrary ((struct Library *)ReqToolsBase);
}

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

VOID SortDirs (VOID)
{
	int	n;
	BOOL save_flag = OFF;
	struct FileDirRecord *dirarray, temp;
  int gap, i, j;

	dirarray = (struct FileDirRecord *)
			(((int) config) + (SIZEOFCONFIGRECORD) +
			(config->Maxconferences * sizeof (struct ConferenceRecord)));

	printf ("\n  Sorting directories...\n");
	n = config->MaxfileDirs;
  for (gap = n / 2; gap > 0; gap /= 2)
  {
    for (i = gap; i < n; i++)
    {
      for (j = i - gap; j >= 0 AND (stricmp (dirarray[j].n_DirName, dirarray[j + gap].n_DirName) > 0); j -= gap)
      {
				if (!(stricmp (dirarray[j].n_DirName, "UPLOAD")) OR (!(stricmp (dirarray[j].n_DirName, "PRIVATE"))))	// IKKE sorter
					JEOtoupper (dirarray[j].n_DirName);
				else
				{
					save_flag = ON;
	        CopyMem (&dirarray[j], &temp, sizeof (struct FileDirRecord));
 		      CopyMem (&dirarray[j + gap], &dirarray[j], sizeof (struct FileDirRecord));
   		    CopyMem (&temp, &dirarray[j + gap], sizeof (struct FileDirRecord));
				}
      }
    }
  }
	for (n = 0; n < config->MaxfileDirs; n++)
		dirarray[n].n_FileOrder = n + 1;
	if (save_flag)
		SaveConfigfile (config);
}

VOID SortConfs (VOID)
{
	int	n;
	BOOL save_flag = OFF;
	struct ConferenceRecord *confarray, temp;
  int gap, i, j;

	confarray = (struct ConferenceRecord *)
		(((int) config) + (SIZEOFCONFIGRECORD));

	printf ("\n  Sorting conferences...\n");
	n = config->Maxconferences;
  for (gap = n / 2; gap > 0; gap /= 2)
  {
    for (i = gap; i < n; i++)
    {
      for (j = i - gap; j >= 0 AND (stricmp (confarray[j].n_ConfName, confarray[j + gap].n_ConfName) > 0); j -= gap)
      {
//				if (!(stricmp (confarray[j].n_ConfName, "NEWS")) OR (!(stricmp (confarray[j].n_ConfName, "POST")) OR (!(stricmp (confarray[j].n_ConfName, "USERINFO")) OR (!(stricmp (confarray[j].n_ConfName, "FILEINFO"))))	// IKKE sorter
//					JEOtoupper (confarray[j].n_ConfName);
				if (j > 6)	// Ikke sorter de første...
				{
					save_flag = ON;
	        CopyMem (&confarray[j], &temp, sizeof (struct ConferenceRecord));
 		      CopyMem (&confarray[j + gap], &confarray[j], sizeof (struct ConferenceRecord));
   		    CopyMem (&temp, &confarray[j + gap], sizeof (struct ConferenceRecord));
				}
      }
    }
  }
	for (n = 0; n < config->Maxconferences; n++)
		confarray[n].n_ConfOrder = n + 1;
	if (save_flag)
		SaveConfigfile (config);
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

#define SORT_NAVN			0
#define SORT_DATO			1
#define SORT_DATO_MOTSATT	2

BOOL Sort_files (WORD mode)
{
  LONG gap, i, j, n;
  struct Fileentry *fl = 0;
  BOOL save_flag = OFF;

	fl = AllocMem (sizeof (struct Fileentry), MEMF_CLEAR);
	n = max_files;
  for (gap = n / 2; gap > 0; gap /= 2)
	{
		for (i = gap; i < n; i++)
    {
	  	if (mode == SORT_NAVN)
      {
				for (j = i - gap; j >= 0 AND (stricmp (fl_all[j].Filename, fl_all[j + gap].Filename) > 0); j -= gap)
				{
        	save_flag = ON;
	        CopyMem (&fl_all[j], fl, sizeof (struct Fileentry));
					CopyMem (&fl_all[j + gap], &fl_all[j], sizeof (struct Fileentry));
    	    CopyMem (fl, &fl_all[j + gap], sizeof (struct Fileentry));
      	}
	    }
  	  else if (mode == SORT_DATO)
    	{
      	for (j = i - gap; j >= 0 AND (fl_all[j].ULdate.ds_Days > fl_all[j + gap].ULdate.ds_Days); j -= gap)
	      {
  	    	save_flag = ON;
    	    CopyMem (&fl_all[j], fl, sizeof (struct Fileentry));
      	  CopyMem (&fl_all[j + gap], &fl_all[j], sizeof (struct Fileentry));
        	CopyMem (fl, &fl_all[j + gap], sizeof (struct Fileentry));
        }
	    }
  	  else
    	{
	     	for (j = i - gap; j >= 0 AND (fl_all[j].ULdate.ds_Days < fl_all[j + gap].ULdate.ds_Days); j -= gap)
        {
	        save_flag = ON;
  	      CopyMem (&fl_all[j], fl, sizeof (struct Fileentry));
          CopyMem (&fl_all[j + gap], &fl_all[j], sizeof (struct Fileentry));
          CopyMem (fl, &fl_all[j + gap], sizeof (struct Fileentry));
     	  }
      }
    }
  }
	FreeMem (fl, sizeof (struct Fileentry));
 	return (save_flag);
}

#define C_NONE			0
#define C_FIRST			1
#define C_ALL				2

BOOL Do_files (VOID)
{
	int size;
	int n,  i, j;
	BOOL ret = TRUE;
	char *Buffer = 0;
	struct Fileentry *temp;
	struct FileDirRecord *dirarray;
	char Hold[80];
	BPTR fh = 0;
	char Filename[108];
	WORD mode, c_mode;
	BOOL save_flag = FALSE;
	ULONG write;
	BOOL backup_flag;

	printf ("\n");
  switch (JEOReqRequest (Message, "Sort files by:", "Name|Date (new last)|Date (new first)|Cancel"))
  {
    case 1: mode = SORT_NAVN; break;
    case 2: mode = SORT_DATO; break;
    case 3: mode = SORT_DATO_MOTSATT; break;
    case 0: return (TRUE);
  }

  switch (JEOReqRequest (Message, "File name:", "No change|Capital first letter|Capital all|Cancel"))
  {
    case 1: c_mode = C_NONE; break;
    case 2: c_mode = C_FIRST; break;
    case 3: c_mode = C_ALL; break;
    case 0: return (TRUE);
  }

	dirarray = (struct FileDirRecord *)
			(((int) config) + (SIZEOFCONFIGRECORD) +
			(config->Maxconferences * sizeof (struct ConferenceRecord)));

	for (n = 0; n < config->MaxfileDirs; n++)
	{
		if (*(dirarray[n].n_DirName))
		{
			strcpy (Hold, dirarray[n].n_DirName);
			Do_fl_name (Hold);
			sprintf (Filename, "ABBS:Fileheaders/%s.fl", Hold);
			size = FileSize (Filename);
			if (size > 0)
			{
				if (fh = Open (Filename, MODE_OLDFILE))
				{
					if (Buffer = AllocMem (size, MEMF_CLEAR))
					{
						if (Read (fh, Buffer, size) == size)
						{
							Close (fh);
							fh = 0;
							j = max_files = 0;
							for (i = 0; i < size; i += sizeof (struct Fileentry))
							{
								temp = (struct Fileentry *)&Buffer[i];
								if (temp->Filename[0] == 0)
									continue;
								if (temp->Filestatus & FILESTATUSF_Filemoved)
									continue;
								if (temp->Filestatus & FILESTATUSF_Fileremoved)
									continue;
								CopyMem (temp, &fl_all[j], sizeof (struct Fileentry));
								switch (c_mode)
								{
									case C_ALL: JEOtoupper (fl_all[j].Filename); save_flag = TRUE; break;
									case C_FIRST:
									{  
						 	      Dummy[0] = fl_all[j].Filename[0];
	          				Dummy[1] = 0;
				  	        JEOtoupper (Dummy);
						 	      fl_all[j].Filename[0] = Dummy[0];
						 	      save_flag = TRUE;
				  	        break;
				  	      }
								}
								j++;
								if (j == MAX_FILES)
								{
									printf ("\n  You have over %ld in a directory, please ask for a upgrade of FileSort.\n\n", MAX_FILES);
									break;
								}
							}
							max_files = j;
							if (max_files > 1)
							{
								printf ("  Sorting files in directory %s...\n", dirarray[n].n_DirName);
								if (Sort_files (mode))
									save_flag = TRUE;
							}
							if (save_flag)
							{
								sprintf (Dummy, "%s_BACKUP", Filename);	// Vi sletter backup
								DeleteFile (Dummy);
								sprintf (Dummy, "C:Rename \"%s\" TO \"%s_BACKUP\"", Filename, Filename); 
								Execute (Dummy, NULL, NULL);						// Vi lager ny backup
								backup_flag = TRUE;
								if (fh = Open (Filename, MODE_NEWFILE))
								{
									for (i = 0; i < max_files; i++)
									{
										write = Write (fh, &fl_all[i], sizeof (struct Fileentry));
										if (write != sizeof (struct Fileentry))
										{
											printf ("\n  ERROR writing to file '%s'!\n\n", Filename);
											backup_flag = FALSE;
											break;
										}
									}
									Close (fh);
									fh = 0;
									if (backup_flag)	// Klarte vi å lagre hele?
									{									// De sletter vi backup
										sprintf (Dummy, "%s_BACKUP", Filename);
										DeleteFile (Dummy);
									}
								}
							}
						}
					}
				}
			}
		}
	}
end:
	return (ret);
}
