;/*
sc5 -j73 Install
x fe.s
quit
*/

#include <JEO:JEO.h>
#include <proto/intuition.h>
#include <proto/dos.h>
#include <exec/memory.h>
#include <libraries/reqtools.h>
#include <proto/reqtools.h>
#include <dos/datetime.h>
#include <exec/lists.h>
#include <time.h>
#include "FE:GUI.h"
#include "FE:FE.h"
#include <BBS.h>
#include <ctype.h>

char Comment_string[] = "FileEditor: No description found...";

VOID Lag_komma (UBYTE *String, LONG number)
{
  ULONG i, j;
  BOOL start;

  sprintf (Dummy, "%10ld", number);
  String[0] = Dummy[0];
  String[1] = '.';
  String[2] = Dummy[1];
  String[3] = Dummy[2];
  String[4] = Dummy[3];
  String[5] = '.';
  String[6] = Dummy[4];
  String[7] = Dummy[5];
  String[8] = Dummy[6];
  String[9] = '.';
  String[10] = Dummy[7];
  String[11] = Dummy[8];
  String[12] = Dummy[9];
  String[13] = 0;
  start = AV;
  for (i = 0, j = 0; i < 13; i++)
  {
    if (isdigit (String[i]))
      start = PÅ;
    if (start)
    {
      Dummy[j] = String[i];
      j++;
    }
  }
  Dummy[j] = 0;
  strcpy (String, Dummy);
}

struct DateStamp Now_stamp (VOID)
{
  struct DateTime datetime = { NULL };
  struct DateStamp stamp = { NULL };
  UBYTE Date[10], Time[10];

	GetDateTime (Date, Time, 0);
	datetime.dat_Format = FORMAT_CDN;	// dd-mm-yy
	datetime.dat_Flags = 0;
	datetime.dat_StrDate = Date;
	datetime.dat_StrTime = Time;
	StrToDate (&datetime);
	stamp = datetime.dat_Stamp;
	return (stamp);
}

//********************************************************************************

fib_Sjef fib_sjef;
ULONG fib_len;

VOID fib_SlettBase (VOID)
{
  ULONG s;
  struct Node *nd;

  nd = fib_sjef.list.lh_Head;
  for (s = 0; s < fib_len; s++)
  {
    Remove (nd);
    FreeMem ((UBYTE *)nd, sizeof (Filbase));
    nd = 0;
    nd = fib_sjef.list.lh_Head;
  }
  fib_len = 0;
}

VOID fib_Close (VOID)
{
  Filbase *bp;

  fib_SlettBase ();
  bp = (Filbase *)fib_sjef.list.lh_Head;
  while (bp = RemHead (&fib_sjef.list))
  {
    FreeMem (bp, sizeof (Filbase));
    bp = 0;
  }
}

struct Node *fib_FindTheOne (UBYTE *Name)	// Legger den alfabetisk i bufferen
{
  struct Node *nd;

  nd = fib_sjef.list.lh_Head;
  while (nd->ln_Succ)
  {
    if (stricmp (nd->ln_Name, Name) > 0)
    {
      nd = nd->ln_Pred;
      return (nd);
    }
    nd = nd->ln_Succ;
  }
  return (FALSE);
}

VOID fib_Rename (UBYTE *Name)
{
  struct Node *nd;
  Filbase *bp = NULL;

  nd = fib_FindTheOne (Name);
  nd = nd->ln_Succ;
  bp = (Filbase *)nd;

  strcpy (bp->Filename, Name);
  bp->nd.ln_Name = bp->Filename;
}

VOID fib_Insett (struct FileInfoBlock *fib)
{
  Filbase *bp = NULL;
  struct Node *nd;

  if (bp = (Filbase *)AllocMem (sizeof (Filbase), MEMF_CLEAR))
  {
    strcpy (bp->Filename, fib->fib_FileName);
    strncpy (bp->Comment, fib->fib_Comment, 36);
    bp->Comment[36] = 0;
    bp->size = fib->fib_Size;
    bp->stamp = fib->fib_Date;

    bp->nd.ln_Name = bp->Filename;
    if (!(nd = fib_FindTheOne (bp->Filename)))
      AddTail (&fib_sjef.list, &bp->nd);
    else
      Insert (&fib_sjef.list, &bp->nd, nd);

    fib_len++;
  }
}

char Readme[][8] = 
{
	".readme",
	".rea"
};

#define MAX_README (sizeof (Readme) / 8)
#define MIN_README_LEN 4
#define MAX_README_LEN 6

BOOL Check_readme_file (char *Name)	// Er ok!
{
  char Stripname[108];
  WORD len, start, i;

	len = strlen (Name);
	if (len > MIN_README_LEN)
	{
		strcpy (Stripname, Name);
		
		for (i = 0; i < MAX_README; i++)	// Filtrerer bort .readme .rea osv
		{
			start = len - strlen (Readme[i]);
			if (!(stricmp (&Stripname[start], Readme[i])))	// Funnet!
				return (TRUE);
		}
	}
	return (FALSE);
}

ULONG fib_read_files (UBYTE *Skuff, BOOL mode)	// 0 = ikke ta readme
{
  BOOL success = 0;
  BPTR lock = 0;
  struct FileInfoBlock *fileinfoblock = 0;
  ULONG files = 0;

//  fib_SlettBase ();

  fileinfoblock = (struct FileInfoBlock *) AllocMem (sizeof (struct FileInfoBlock), MEMF_CLEAR);
  if (lock = Lock (Skuff, ACCESS_READ))	// Kunne ikke locke
  {
	  if (success = Examine (lock, fileinfoblock)) // Kunne ikke examinere
	  {
		  FOREVER
		  {
		    success = ExNext (lock, fileinfoblock);	// FindNext File/Dir
		    if (!(success))				// End of directory ?
		      break;
		    if (fileinfoblock->fib_DirEntryType < 0)	// < 0 = a file, else a dir :)
		    {
					if (!mode)	// Ikke ta med readme
					{
						if (Check_readme_file (fileinfoblock->fib_FileName))
							continue;
					}
		      fib_Insett (fileinfoblock);
					files++;
		    }
		  }
		}
	}
  if (lock)
    UnLock (lock);
  if (fileinfoblock)
    FreeMem (fileinfoblock, sizeof (struct FileInfoBlock));

  return (files);
}

VOID fib_Open (VOID)
{
  fib_len = 0;
  NewList (&fib_sjef.list);
}

// ***************************************************************************

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
				filedir_number = n;
				file_order = msg.UserNr;
				Load_fentry ();
				return (TRUE);
			}
		}
	}
	return (FALSE);
}

// *************************************************************************
// *************************************************************************
// *************************************************************************

/*
BOOL Exctract_archive (WORD pack, char *File, char *Id)
{
	UBYTE Command[51];
	UBYTE FileName[108];
	BOOL flag;

	flag = FALSE;
	switch (pack)
	{
		case PACK_LHA: strcpy (Command, "C:LHA -q -N x"); flag = TRUE; break; 
		case PACK_LZX: strcpy (Command, "C:LZX x"); flag = TRUE; break; 
	}
	if (flag)
	{
		if (!(stricmp (Id, "FILE_ID.DIZ")))
			sprintf (Dummy, "%s \"%s\" \"%s\" \"%s\" >NIL:", Command, File, Id, To);
		else
			sprintf (Dummy, "%s \"%s\" \"%s%s\" \"%s\" >NIL:", Command, File, Name, Id, To);
		Execute (Dummy, NULL, NULL);
		sprintf (Dummy, "%s%s", To, Id);
		if (FileSize (Dummy) > 0)
		{
			if (!(stricmp (Id, "FILE_ID.DIZ")))
			{
				sprintf (FileName, "%s%s.readme", To, Name);
				SetProtection (Dummy, 0);
				Rename (Dummy, FileName);
				DeleteFile (Dummy);
			}
			return (TRUE);
		}
	}
	return (FALSE);
}

WORD Sjekk_pakkemetode (UBYTE *Filename)
{
  UWORD len, i, j;

  len = strlen (Filename);
  if (len < 4)
    return (ERROR);

  for (i = len - 4, j = 0; i < len; i++, j++)
    Dummy[j] = Filename[i];

  Dummy[j] = 0;
  if (!(stricmp (Dummy, ".LHA")))
    return (PACK_LHA);
  else if (!(stricmp (Dummy, ".LZH")))
    return (PACK_LHA);
  else if (!(stricmp (Dummy, ".LZX")))
    return (PACK_LZX);
  else if (!(stricmp (Dummy, ".ARC")))
    return (PACK_ARC);
  else if (!(stricmp (Dummy, ".DMS")))
    return (PACK_DMS);
  else if (!(stricmp (Dummy, ".GIF")))
    return (PACK_GIF);
  else if (!(stricmp (Dummy, ".ZIP")))
    return (PACK_ZIP);

	return (ERROR);
}

VOID Strip_FILEINFO (char *Filename, char *ReadmeFilename)
{
	BOOL LHA_feil, ZIP_feil, LZX_feil;
	UBYTE FName[108];
	WORD pack;

	pack = Sjekk_pakkemetode (FName);
	if (pack >= PACK_LHA)
	{
		LHA_feil = ZIP_feil = LZX_feil = AV;

		strcpy (FName, Filename);
		Strip_extention (FName);

		switch (pack)
		{
			case PACK_LHA:	// Og LZH
			{
				if (FileSize ("C:LHA") > 0)
				{
					if (Exctract_archive (pack, FName, "FILE_ID.DIZ"))
						break;
					if (Exctract_archive (pack, FName, ".readme"))
						break;
					if (Exctract_archive (pack, FName, ".rea"))
						break;
				}
				else if (!LHA_feil)
				{
					ErrorMsg (GLS (&txt_066));
					LHA_feil = PÅ;
					rtSetWaitPointer (MainWnd);
				}
				break;
			}
			case PACK_LZX:
			{
				if (FileSize ("C:LZX") > 0)
				{
					sprintf (Dummy, "'%s' -> Kopierer 'FILEINFO' til '%s'...", Name, oppsett->FILEINFO);
					Status (Dummy);

					if (Exctract_archive (pack, Path, "FILE_ID.DIZ", oppsett->FILEINFO, ABBS_name))
						break;
					if (Exctract_archive (pack, Path, ".readme", oppsett->FILEINFO, ABBS_name))
						break;
					if (Exctract_archive (pack, Path, ".rea", oppsett->FILEINFO, ABBS_name))
						break;
				}
				else if (!LZX_feil)
				{
					ErrorMsg (GLS (&txt_067));
					LZX_feil = PÅ;
					rtSetWaitPointer (MainWnd);
				}
				break;
			}
		}
	}
}
*/

BOOL FE_GetFileName (UBYTE *Dir, UBYTE *Name, UBYTE *Message, UBYTE *OkText)
{
  register struct rtFileRequester *filereq = 0;

  if (filereq = rtAllocRequestA (RT_FILEREQ, NULL))
  {
    strcpy (filereq->Dir, Dir);
    if (rtFileRequest (filereq, Name, Message, RT_ReqPos, REQPOS_CENTERSCR,
                                               RTFI_OkText, OkText, TAG_END))
    {
      if (strlen (filereq->Dir))
      {
        strcpy (Dir, filereq->Dir);
        if (Dir[strlen (Dir) - 1] != ':')
          strcat (Dir, "/");
      }
      else
        strcpy (Dir, ":");
    }
    else
    {
      rtFreeRequest (filereq);
      return (FALSE);
    }
    rtFreeRequest (filereq);
  }
  else
    return (FALSE);

  return (TRUE);
}

BOOL Check_readme (char *Path, char *ABBSname, char *ReadmeFilename)
{
	char HoldFname[108];
	char HoldPath[108];
	WORD len, i;
	BOOL flag = FALSE;

	strcpy (ReadmeFilename, ABBSname);
	strcpy (HoldPath, Path);
	Do_slash (HoldPath);
	len = strlen (ReadmeFilename);
	for (i = len; i > 0; i--)
	{
		if (ReadmeFilename[i] == '.')
		{
			flag = TRUE;
			ReadmeFilename[i] = 0;
			break;
		}
	}
	if (flag)
	{
		for (i = 0; i < MAX_README; i++)
		{
			strcpy (HoldFname, ReadmeFilename);
			strcat (HoldFname, Readme[i]);
			sprintf (Dummy, "%s%s", HoldPath, HoldFname);
			if (FileSize (Dummy) > 0)
			{
				strcpy (ReadmeFilename, Dummy);
				return (TRUE);
			}
		}
	}
	return (FALSE);
}

// ******************************************************************************
// ***************************** README stuff ***********************************
// ******************************************************************************

enum
{
  R_SHORT = 0,
  R_AUTHOR,
  R_UPLOADER,
  R_VERSION,
  R_TYPE,
	R_KURZ,
  R_REQUIRES,
  R_DATE,
  R_TESTED,
  R_REPLACES,
  R_DISTRIBUTION,
  R_SOURCE,
  R_WWW,
  R_URL,
	MAX_TYPES
};

char Readme_types[MAX_TYPES][14] =
{
	"Short:",
	"Author:",
	"Uploader:",
	"Version:",
	"Type:",
	"Kurz:",
	"Requires:",
	"Date:",
	"Tested:",
	"Replaces:",
	"Distribution:",
	"Source:",
	"WWW:",
	"Url:"
};

char rhead[MAX_TYPES][81];

int Find_text_start (char *Line)
{
	int i;
	BOOL flag;

	flag = OFF;
	for (i = 0; Line[i] != 0; i++)
	{
		if (Line[i] == ' ')	// Fant vi space?
			flag = ON;
		else if (flag)
			return (i);
	}			
}

VOID Strip_spaces (char *Text)
{
	UWORD i;

	for (i = 0; Text[i] != 0; i++)
	{
		if (Text[i] == ' ')
		{
			Text[i] = 0;
			break;
		}
	}
}


int Get_readme_info (char *Filename)
{
	int i, j, r, count, start;
	ULONG len, len1, len2;
	BPTR file = 0;
	UBYTE *Buffer = 0;
	LONG size;
	char Line[71];

	count = 0;	// Antall typer readme vi fant

	if (file = Open (Filename, MODE_OLDFILE))
	{
		size = FileSize (Filename);
		if (size > 6)
		{
			if (Buffer = AllocMem (size, MEMF_CLEAR))
			{
				if (Read (file, Buffer, size))
				{
					len = strlen (Buffer);
					for (i = 0, j = 0; Buffer[i] != 0; i++)
					{
						if (j == 70)
							j = 69;
//							Buffer[i] = '\n';	// Vi lurer'n her ;)
						Line[j] = Buffer[i];
						if (Buffer[i] == '\n')	// Ny linje
						{
							Line[j] = 0;
							j = 0;
							for (r = 0; r < MAX_TYPES; r++)
							{
								if (!rhead[r][0])	// Ikke noe her ennå!
								{
									len1 = strlen (Readme_types[r]);
//									sprintf (Dummy, "(%ld) '%s' - '%s'", len1, Readme_types[r], Line);
//									JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_OK));									
									if (!(strnicmp (Readme_types[r], Line, len1)))
									{
										start = Find_text_start (Line);
										len2 = strlen (Line);
										strncpy (rhead[r], &Line[start], len2 - start);
										rhead[r][len2 - start] = 0;
										count++;

										if (!(stricmp (Readme_types[r], "Type:")))
											Strip_spaces (rhead[r]);	

										break;
									}
								}
							}
							if (i < len - 1)
							{
								if (Buffer[i+1] == '\n')	// Ferdig
									break;
							}
						}
						else
							j++;
					}
				}
				FreeMem (Buffer, size);
				Buffer = 0;
			}
		}
		Close (file);
		file = 0;
	}
	return (count);
}

// ******************************************************************************
// ***************************** README stuff ***********************************
// ******************************************************************************

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

WORD Check_dir_exists (char *Type)
{
	WORD n;

	for (n = 0; n < config->MaxfileDirs; n++)
	{
		if (*(config->firstFileDirRecord[n].n_DirName))
		{
			if (!(stricmp (config->firstFileDirRecord[n].n_DirName, Type)))
				return (n);
		}
	}
	return (-1);
}

BOOL Check_same_dir (char *dir1, char *dir2)
{
	BOOL ret = FALSE;
	BPTR lock1 = 0, lock2 = 0;

	if (lock1 = Lock (dir1, MODE_OLDFILE))
	{
		if (lock2 = Lock (dir2, MODE_OLDFILE))
		{
			if (SameLock (lock1, lock2) == 0)
				ret = TRUE;
			UnLock (lock2);
		}
		UnLock (lock1);
	}
	return (ret);
}

//********************************************************************************

VOID Multi_create_dir (char *Dir)
{
	int i;
	BPTR lock;

	for (i = 0; Dir[i] != 0; i++)
	{
		if (Dir[i] == '/')
		{
			Dir[i] = 0;
		  lock = CreateDir (Dir);
		  if (lock)
		    UnLock (lock);
			Dir[i] = '/';
		}
	}
  lock = CreateDir (Dir);
  if (lock)
		UnLock (lock);
}

VOID Install_files (ULONG path)
{
	ULONG files = 0;
	LONG i, new_size, r;
	UBYTE c;
  struct Node *nd;
  Filbase *bp;
  char Filename[108];
  char Pathname[31], ToPathname[31];
  struct Fileentry *fl = 0;
  UBYTE Hold[108], Hold1[50], NameSize[15];
  WORD value;
	char ReadmeFilename[108];
	ULONG not_found = 0;
	BOOL exists;
	BOOL automatic = OFF;
	BOOL go_flag, flag;
	BOOL readme;
	WORD move_dir;
	ULONG old_path, replace_dl;
	BOOL check;
	char ReadmeFound[12];
	BOOL copy;
	BPTR fh = 0;
	char ErrorFname[] = "T:FE.Error";
	LONG error_size;
	char *Buffer = 0;
	int hold_order, hold_number;
	char *R_hold = 0;
	BOOL to_conf_flag = FALSE;

	old_path = path;
	All (OFF);

	for (i = 0; i < config->Maxconferences; i++)
	{
		if (*(config->firstconference[i].n_ConfName))	//  Noe her?
		{
			if (!(stricmp (config->firstFileDirRecord[path].n_DirName, config->firstconference[i].n_ConfName)))
			{
				if (ur->firstuserconf[i].uc_Access & ACCF_Upload)	// Har vi upload axx?
				{
					sprintf (Dummy, GLS (&txt_138), config->firstFileDirRecord[path].n_DirName);
					if (JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_072)))
						to_conf_flag = TRUE;
				}
				break;
			}
		}
	}

  if (fl = AllocMem (sizeof (struct Fileentry), MEMF_CLEAR))
  {
	  rtSetWaitPointer (FileEditorWnd);

		fib_Open ();
	 	strcpy (Pathname, config->firstFileDirRecord[path].n_DirPaths);
		Do_slash (Pathname);

		if (files = fib_read_files (Pathname, 0))	// Leser alle filene fra dirret
		{
  	  nd = fib_sjef.list.lh_Head;
    	bp = (Filbase *)nd;

	    while (nd->ln_Succ)	// Går igjenom alle filene på disken...
  	  {
  	  	replace_dl = 0;
				path = old_path;	// Husker alltid den vi kom i fra...
  	  	go_flag = TRUE;
				strcpy (Dummy, bp->Filename);
				while (go_flag)
				{
					if (strlen (Dummy) > 18)
					{
						strcpy (Dummy, bp->Filename);
						Dummy[18] = 0;
						sprintf (Hold, GLS (&txt_068), bp->Filename);
						if (GetReqString (Dummy, 18, Hold))
						{
							if (strcmp (Dummy, bp->Filename))	// renama
							{
								sprintf (Hold, "C:Rename \"%s%s\" \"%s%s\"", Pathname, bp->Filename, Pathname, Dummy);
								Execute (Hold, NULL, NULL);
							}
						}
						else
							strcpy (Dummy, bp->Filename);
					}
					else
					{
						strcpy (bp->Filename, Dummy);
						go_flag = FALSE;
					}
				}
		    sprintf (Filename, "%s%s", Pathname, bp->Filename);
				hold_order = file_order;
				hold_number = filedir_number;

				for (r = 0; r < MAX_TYPES; r++)	// Nullstill
					rhead[r][0] = 0;

				if (Check_readme (Pathname, bp->Filename, ReadmeFilename))
				{
					readme = TRUE;
					if (Get_readme_info (ReadmeFilename))	// Funnet fra readme, brukes
					{
						strncpy (bp->Comment, rhead[R_SHORT], 36);
						bp->Comment[36] = 0;
					}
				}
				else
				{
					ReadmeFilename[0] = 0;
					readme = FALSE;
				}
		    exists = Find_file (bp->Filename);
				if (exists)
 				{
					new_size = FileSize (Filename);	// Størrelsen på fila på HD'n
 					if (path == filedir_number)	// Ligger i samma dir...
 					{
						if (new_size != fentry.Fsize)	// Forskjellig størrelse!
						{															// Men i samma dir så vi oppdaterer
				    	fentry.Fsize = new_size;
				    	SaveFileEntry ();
						}
 					}
 					else	// Vi ligger i forskjellige dirs.... vi sjekker størrelsen...
 					{
						if (new_size != fentry.Fsize)	// Forskjellig størrelse!
						{
							sprintf (Dummy, GLS (&txt_069),
								 bp->Filename, fentry.Filedescription, fentry.Fsize, rhead[R_SHORT], new_size, new_size - fentry.Fsize);
							if (JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_070)))
							{
								replace_dl = fentry.AntallDLs;	// Vi husker downloads fra gammel fil
								Delete_fentry ();
								exists = FALSE;
							}
						}
					}
				}
				file_order = hold_order;
				filedir_number = hold_number;
				if (!exists)	// Ikke funnet i ABBS!
				{
					not_found++;
        	Lag_komma (NameSize, bp->size);

					move_dir = -1;
					copy = FALSE;
					if (rhead[R_TYPE][0])
					{
						if (stricmp (rhead[R_TYPE], config->firstFileDirRecord[path].n_DirName))	// Ikke samme dir
						{
							move_dir = Check_dir_exists (rhead[R_TYPE]);
							if (move_dir == -1)	// Not found
							{
								sprintf (Dummy, GLS (&txt_071), rhead[R_TYPE]);
		  	   	    if (JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_072)))
		  	   	    {
		  	   	    	if (Create_dir (rhead[R_TYPE]))
										move_dir = Check_dir_exists (rhead[R_TYPE]);
		  	   	    }
							}
						}
					}
					if (move_dir != -1)	// Meningen vi skal vi flytte fila?
					{
						if (!Check_same_dir (config->firstFileDirRecord[move_dir].n_DirPaths, config->firstFileDirRecord[path].n_DirPaths))
							copy = TRUE;	// Ikke samme fildir. Kopier fila til annet path...
					}

					if (!automatic)
					{
						if (ReadmeFilename[0])
							strcpy (ReadmeFound, GLS (&txt_073));
						else
							strcpy (ReadmeFound, GLS (&txt_074));

						if (move_dir == -1)	// Samme skuff som vi er i
						{
							strcpy (Hold, GLS (&txt_075));
							strcpy (Hold1, GLS (&txt_076));
							move_dir = filedir_number;	// Vi må legge inn skuffen igjen!
						}
						else
						{
							strcpy (Hold, GLS (&txt_077));
							strcpy (Hold1, GLS (&txt_078));
						}

						R_hold = AllocMem (2000, MEMF_CLEAR);
						strcpy (R_hold, "\n");
						if (readme)
						{
							flag = FALSE;
							for (r = 0; r < MAX_TYPES; r++)
							{
								if (*(rhead[r]))
								{
									flag = TRUE;
									sprintf (Dummy, "%13s %s\n", Readme_types[r], rhead[r]);
									strcat (R_hold, Dummy);
								}
							}
							if (flag)
								strcat (R_hold, "\n");
						}
						
  	 	      sprintf (Dummy, GLS (&txt_079),
							Hold, config->firstFileDirRecord[move_dir].n_DirName, bp->Filename, NameSize, R_hold, ReadmeFound);
						FreeMem (R_hold, 2000);

						strcat (Hold1, GLS (&txt_080));
  	   	    value = JEOReqRequest (GLS (&txt_MESSAGE), Dummy, Hold1);	// Legg til fil
  	   	  }
     	    if (!value)	// Move/Install = 1 AUTO INSTALL = 2  Skip file = 3
     	    	break;

					if (value == 2)		// Auto install (Value vil alltid være 2 hele tiden)
						automatic = ON;

					if (value != 3)		// Ikke skip file
					{
						if (move_dir != -1)
						{
							if (copy)	// Skal vi kopiere?
							{
							 	strcpy (ToPathname, config->firstFileDirRecord[move_dir].n_DirPaths);
								Do_slash (ToPathname);
								check = Exists (ToPathname);
								if (!check)
								{
									Multi_create_dir (ToPathname);
									check = Exists (ToPathname);
								}
								if (check)
								{
									sprintf (Dummy, "C:Copy \"%s\" \"%s\" >NIL:", Filename, ToPathname);
									Execute (Dummy, NULL, NULL);
									DeleteFile (Filename);
									sprintf (Filename, "%s%s", ToPathname, bp->Filename);
									path = move_dir;	// Den må alltid flyttes intern :)
								}
								else
								{
									sprintf (Dummy, GLS (&txt_081), ToPathname);
									ErrorMsg (Dummy);
								}
							}
							else
								path = move_dir;	// Den må alltid flyttes intern :)
						}
						sprintf (Dummy, "ABBS:Utils/AddFile \"%s\" %s DIR=%s FROM=\"%s\"", Filename, bp->Filename, config->firstFileDirRecord[path].n_DirName, "SYSOP");
						if (readme)
						{
							sprintf (Hold, " I=\"%s\"", ReadmeFilename);
							strcat (Dummy, Hold);
						}
						if (to_conf_flag)	// Skal den privat til conf?
						{
							sprintf (Hold, " C=\"%s\"", config->firstFileDirRecord[path].n_DirName);
							strcat (Dummy, Hold);
						}
	          if (bp->Comment[0] == 0)	// Ingen beskrivelse fra disken eller fra readmefila
  	        {
    	      	if (!automatic)	// da spør
      	    	{
      	    		bp->Comment[0] = 0;
								sprintf (Hold, GLS (&txt_082), bp->Filename);
  	      	 	  GetReqString (bp->Comment, 36, Hold);
							}
 	      	 	  if (bp->Comment[0] == 0)	// Igjen!
								strcpy (bp->Comment, Comment_string);	// Legger inn standard string
						}
						sprintf (Hold, " DESC=\"%s\"", bp->Comment);	// Til slutt!
						strcat (Dummy, Hold);
						fh = Open (ErrorFname, MODE_NEWFILE);
						Execute (Dummy, NULL, fh);
						Close (fh);

						if ((error_size = FileSize (ErrorFname)) == 0)	// Ingen error
						{
							if (replace_dl)	// Skal vi huske downloads?
							{
								if (Find_file (bp->Filename))	// Fant vi fila?
								{
									fentry.AntallDLs = replace_dl;
									SaveFileEntry ();
								}
							}
							DeleteFile (ReadmeFilename);
							ur->Uploaded++;
							ur->KbUploaded += (bp->size / 1024);
							ur->MsgsLeft++;
							Save_user ();
							if (!automatic)
							{
								if (!(strcmp (config->firstFileDirRecord[path].n_DirName, config->firstFileDirRecord[old_path].n_DirName))) 
									SetupFiles ();
							}
						}
						else if (fh = Open (ErrorFname, MODE_OLDFILE))
						{
							if (Buffer = AllocMem (error_size, MEMF_CLEAR))
							{
								Read (fh, Buffer, error_size);
								for (i = strlen (Buffer), c = 0; i >= 0; i--)	// Ta bort siste linje
								{
									if (Buffer[i] == '\n')
									{
										c++;
										if (c > 1)
										{
											Buffer[i] = 0;
											break;
										}
									}
								}
								ErrorMsg (Dummy);
							}
							FreeMem (Buffer, error_size);
							Close (fh);
						}
				  }
				}
	      nd = nd->ln_Succ;
  	    bp = (Filbase *)nd;
		  }
		}
		fib_Close ();
	}
	if (not_found == 0)
	{
		sprintf (Dummy, GLS (&txt_083), config->firstFileDirRecord[path].n_DirName);
		JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_OK));
	}
	else
	{
		if (automatic)	// Fordi vi ikke har gjort det fra før....
			SetupFiles ();
	}
	DeleteFile (ErrorFname);
	path = old_path;	// Just in case
	SetupFiles ();		// Hmmmm
	All (ON);
}

VOID Strip_preview (char *Name)	// tar bort _@PREVIEW@
{
	UBYTE len;

	len = strlen (Name);
	if (len > 11)
		Name[len-10] = 0;
}

VOID Install_preview_files (ULONG path)	// Path hvor er vi?
{
	ULONG files = 0;
  struct Node *nd;
  Filbase *bp;
  char Filename[108], Pathname[] = "ABBS:Previews/";
  struct Fileentry *fl = 0;
	BOOL exists;
	ULONG old_path, updated = 0;
	int hold_order, hold_number;

	old_path = path;
	All (OFF);
  if (fl = AllocMem (sizeof (struct Fileentry), MEMF_CLEAR))
  {
	  rtSetWaitPointer (FileEditorWnd);
		fib_Open ();
		if (files = fib_read_files (Pathname, 0))	// Leser alle filene fra dirret
		{
  	  nd = fib_sjef.list.lh_Head;
    	bp = (Filbase *)nd;
	    while (nd->ln_Succ)	// Går igjenom alle filene på disken...
  	  {
				path = old_path;	// Husker alltid den vi kom i fra...
  	  	Strip_preview (bp->Filename);
		    sprintf (Filename, "%s%s", Pathname, bp->Filename);
				hold_order = file_order;	// Vi husker ;)
				hold_number = filedir_number;
		    exists = Find_file (bp->Filename);	// Har vi fila i ABBS?
				if (exists)
 				{
/*
					if (fentry.Filestatus & FILESTATUSF_Preview)
					{
			    	fentry.Filestatus -= FILESTATUSF_Preview;			// Tar bort
			    	SaveFileEntry ();
			    }
*/

					if (!(fentry.Filestatus & FILESTATUSF_Preview))	// Er den ikke lagt inn?
					{
			    	fentry.Filestatus |= FILESTATUSF_Preview;			// Nei, da legger vi den inn
			    	SaveFileEntry ();
			    	updated++;
			    }
				}
	      nd = nd->ln_Succ;
  	    bp = (Filbase *)nd;
		  }
		}
		fib_Close ();
	}
  sprintf (Dummy, GLS (&txt_137), updated, updated == 1 ? GLS (&txt_060) : GLS (&txt_061));
	JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_OK));
	path = old_path;	// Just in case
	file_order = hold_order;	// Vi legger tilbake ;)
	filedir_number = hold_number;
	SetupFiles ();
	All (ON);
}

/*
    bp->Filename
    bp->Comment
    bp->size
    bp->stamp

fN8DZTvN
*/
