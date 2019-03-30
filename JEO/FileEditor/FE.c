;/*
sc5 -j73 FE
x fe.s
quit
*/

char *vers = "\0$VER: FileEditor v0.17a - 03.10.98";
char Title[18] = "FileEditor v0.17a";

#include <JEO:JEO.h>
#include <exec/memory.h>
#include <exec/execbase.h>
#include <exec/lists.h>
#include <libraries/reqtools.h>
#include <proto/reqtools.h>
#include <proto/dos.h>
#include <proto/intuition.h>
#include <proto/graphics.h>
#include <proto/gadtools.h>
#include <proto/locale.h>
#include <libraries/locale.h>
#include <utility/tagitem.h>
#include "FE:FE.h"
#include <bbs.h>
#include <JEO:raw.h>
#include <-V:Status.h>
#include <ctype.h>

#define LOCALE_TEXT
#include <FE:FE_locale.h>

#include "FE:GUI.c"

BOOL SetupDirs (VOID);
VOID Remove_conf (VOID);
VOID Update_one_filesize (VOID);

#define GREY	0
#define BLACK	1
#define WHITE	2
#define BLUE	3

#define STATUSX		    5
#define STATUSY		   26

struct Library *LocaleBase = NULL;
struct Catalog *mycatalog = NULL;
char *CatalogName = "FileEditor.catalog";

char *GLS (struct LocText *loctext)
{
  if (mycatalog)
    GetCatalogStr (mycatalog, loctext->id, NULL);
	else
		return (loctext->text);
}

char WndTitle[81];
char Filename[108];

WORD filedir_order, filedir_number, filedir_view;
WORD file_order;
struct UserRecord *ur = 0;
struct RastPort *main_rp;
int usernumber;

BOOL menu_flag;
UBYTE selected = 0;

char *Dummy = 0;
struct Fileentry tempfentry, fentry;	// Føre vi forandrer noe...
struct ABBSmsg msg;
struct ReqToolsBase *ReqToolsBase = 0;

BOOL saveflag;	// Til fileentry

struct List listheader;
static struct Node *list = NULL;

struct ConfigRecord *config;
//struct MsgPort *rport = NULL;
struct Library *UtilityBase = NULL;

UBYTE mainX = 10;

// *********************************************************************
// ***********************  fileentry lists ****************************
// *********************************************************************

ULONG recCount;

typedef struct
{
  struct List list;
  ULONG howmany;
} Sjef;

Sjef sjef;

typedef struct
{
  struct Node nd;
	char Filename[19+2];	// Til "I "
	ULONG fentry_order;
} Base;

VOID KillBase (VOID)
{
  ULONG s;
  struct Node *nd;

  nd = sjef.list.lh_Head;
  for (s = 0; s < recCount; s++)
  {
    Remove (nd);
    FreeMem ((UBYTE *)nd, sizeof (Base));
    nd = 0;
    nd = sjef.list.lh_Head;
  }
  recCount = 0;
}

VOID CloseBase (VOID)
{
  Base *bp;

  if (recCount > 0)
  {
	  KillBase ();
	  bp = (Base *)sjef.list.lh_Head;
  	while (bp = RemHead (&sjef.list))
	  {
  	  FreeMem (bp, sizeof (Base));
    	bp = 0;
    }
  }
}

struct Node *FindTheOne (UBYTE *Name)
{
  register struct Node *nd;

  nd = sjef.list.lh_Head;
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

BOOL InsertBase (VOID)
{
  Base *bp=NULL;

  if (!(bp = (Base *)AllocMem (sizeof (Base), MEMF_PUBLIC)))
    return (FALSE);

	bp->fentry_order = file_order;
	strcpy (bp->Filename, fentry.Filename);
	sprintf (bp->Filename, "  %s", fentry.Filename);
	if (fentry.Infomsgnr)
		bp->Filename[0] = 'I';
  bp->nd.ln_Name = bp->Filename;
	AddTail (&sjef.list, &bp->nd);	// Alltid add her, ikke insert (sort)

  recCount++;
  return (TRUE);
}

BOOL DeleteOne (UBYTE *Name)
{
  register struct Node *nd;

  if (nd = FindName (&sjef.list, Name)) 
  {
    Remove (nd);
    FreeMem ((UBYTE *)nd, sizeof (Base));
    nd = 0;
    recCount--;
    return (TRUE);
  }
  else
    return (FALSE);
}

VOID FE_Menu (BOOL status)
{
  if (status == ON)
  {
    if (menu_flag == OFF)
    {
      Forbid ();
      FileEditorWnd->Flags ^= RMBTRAP;
      Permit ();
      menu_flag = ON;
    }
  }
  else	// OFF
  {
    if (menu_flag == ON)
    {
      Forbid ();
      FileEditorWnd->Flags ^= RMBTRAP;
      Permit ();
      menu_flag = OFF;
    }
  }
}

VOID All (BOOL mode)
{
  if (mode == OFF)
  {
    rtSetWaitPointer (FileEditorWnd);
    FE_Menu (OFF);
  }
  else // PÅ
  {
    FE_Menu (ON);
    ClearPointer (FileEditorWnd);
  }
}

VOID ChangeInfo (VOID)
{
	JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_NOT_YET), GLS (&txt_OK));
}

VOID EditGadgetUp (APTR Address)
{
  struct Gadget *gadget;
  UWORD nr;

  gadget = (struct Gadget *)Address;
  nr = gadget->GadgetID;

  switch (nr)
  {
		case GD_FILE_NAME:
			strcpy (fentry.Filename, GetString (gadget));
			saveflag = 2;
			ActivateEditGD (GD_COMMENT);
			break;
		case GD_COMMENT:
			strcpy (fentry.Filedescription, GetString (gadget));
			if (!saveflag)
				saveflag = 1;
			break;
		case GD_FILEINFO:
			ChangeInfo ();
			break;
		case GD_REMOVE_CONF:
			Remove_conf ();
			break;
		case GD_UPDATE_SIZE:
			Update_one_filesize ();
			break;
	}
}

BOOL HandleEditIDCMP (VOID)
{
	struct IntuiMessage	*m;
	UWORD	code;
 	ULONG class;
	struct IntuiMessage	tmpmsg;
	struct MenuItem *mi;
  BOOL ret = TRUE;

	while (m = GT_GetIMsg (EditWnd->UserPort))
	{
		CopyMem ((char *)m, (char *)&tmpmsg, (long)sizeof(struct IntuiMessage));
		GT_ReplyIMsg (m);
		code = tmpmsg.Code;
		class = tmpmsg.Class;
		switch (tmpmsg.Class)
		{
			case	IDCMP_RAWKEY:
			{
				switch (code)
				{
					case ESC:
						ret = FALSE;
						break;
				}
				break;
			}
			case	IDCMP_CLOSEWINDOW:
				ret = FALSE;
				break;
			case	IDCMP_GADGETUP:
				EditGadgetUp (tmpmsg.IAddress);
				break;
			case	IDCMP_MENUPICK:
			{
				while (code != MENUNULL)
				{
					switch (MENUNUM (code))
					{
						case 0:		// Project
						{
							switch (ITEMNUM (code))
							{
								case 0:	// Ok
									ret = FALSE;
									break;
								case 1:	// Cancel
									saveflag = OFF;
									ret = FALSE;
									break;
							}
							break;
						}
						case 1:		// Edit
						{
							switch (ITEMNUM (code))
							{
								case 0:	// Name
									ActivateEditGD (GD_FILE_NAME);
									break;
								case 1:	// Description
									ActivateEditGD (GD_COMMENT);
									break;
								case 2:	// Info
									ChangeInfo ();
									break;
							}
							break;
						}
					}
					mi = ItemAddress (EditMenus,code);
					code = mi->NextSelect;
				}
				break;
			}
		}
	}
	return (ret);
}

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

VOID ActivateEditGD (UWORD nr)
{
  ActivateGadget (EditGadgets[nr], EditWnd, NULL);
}

VOID EditInitGadget (UWORD num, LONG tagtype, LONG tagvalue)
{
  GT_SetGadgetAttrs (EditGadgets[num], EditWnd, NULL, tagtype, tagvalue, TAG_DONE);
}

VOID ErrorMsg (char *Text)
{
	JEOReqRequest (GLS (&txt_ERROR), Text, GLS (&txt_OK));
}

BOOL Delete_fentry (VOID)
{
	int err;
	BOOL ret = FALSE;

	Load_fentry ();
	sprintf (Dummy, GLS (&txt_012), fentry.Filename);
	if (JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_DELETE_CANCEL)))
	{
		sprintf (Dummy, "%s%s", config->firstFileDirRecord[filedir_number].n_DirPaths, fentry.Filename);

		fentry.Filestatus |= FILESTATUSF_Fileremoved;
		msg.Command = Main_savefileentry;
		msg.UserNr = filedir_number;
		msg.arg = file_order;
		msg.Data = (ULONG)&fentry;
		err = HandleMsg (&msg);
		if (err == Error_OK)
		{
			SetProtection (Dummy, 0);
			DeleteFile (Dummy);
			SetupFiles ();
			ret = TRUE;
		}
		else
			ErrorMsg (GLS (&txt_014));
	}
	return (ret);
}

VOID Save_config (VOID)
{
	int err;

	msg.Command = Main_saveconfig;
	msg.Data = (ULONG)0; // Intern config!
	err = HandleMsg (&msg);

	if (err != Error_OK)
		JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_015), GLS (&txt_OK));
	SetupDirs ();
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

VOID UpdateScreen (VOID)
{
	WORD x, y, col;
	struct RastPort *rp;
	struct ConferenceRecord *confarray;
	char Date[LEN_DATSTRING];
	int size;

	confarray = (struct ConferenceRecord *)(((int) config) + (SIZEOFCONFIGRECORD));
	rp = EditWnd->RPort;
	x = 22;
	y = 112;

	JEOWrite (rp, x, y,      GLS (&txt_016), BLACK);
	JEOWrite (rp, x, y += 8, GLS (&txt_017), BLACK);
	JEOWrite (rp, x, y += 8, GLS (&txt_018), BLACK);
	JEOWrite (rp, x, y += 8, GLS (&txt_019), BLACK);
	JEOWrite (rp, x, y += 8, GLS (&txt_020), BLACK);
	JEOWrite (rp, x, y += 8, GLS (&txt_021), BLACK);

	x = 22 + (12 * 8);
	y = 112;
	sprintf (Dummy, "%ld", fentry.AntallDLs);
	JEOWrite (rp, x, y, Dummy, WHITE);

	sprintf (Dummy, "%ld bytes (%ld Kb)", fentry.Fsize, fentry.Fsize / 1024);
	JEOWrite (rp, x, y += 8, Dummy, WHITE);

	stamptoDateTime (&fentry.ULdate, Date);
	sprintf (Dummy, "%s", Date);
	JEOWrite (rp, x, y += 8, Dummy, WHITE);

	GetUser (fentry.Uploader, Dummy);		// Hente bruker
	JEOWrite (rp, x, y += 8, Dummy, WHITE);

	if (fentry.Filestatus & FILESTATUSF_PrivateUL)	// Privat?
		GetUser (fentry.PrivateULto, Dummy);		// Hente bruker
	else
		strcpy (Dummy, GLS (&txt_022));
	JEOWrite (rp, x, y += 8, Dummy, WHITE);

	if (fentry.Filestatus & FILESTATUSF_PrivateConfUL)	// Privat til konf?
	{
		EditInitGadget (GD_REMOVE_CONF, GA_Disabled, OFF);
		sprintf (Dummy, "%s", confarray[fentry.PrivateULto/2].n_ConfName);
		col = WHITE;
	}
	else
	{
		EditInitGadget (GD_REMOVE_CONF, GA_Disabled, ON);
		strcpy (Dummy, GLS (&txt_023));
		col = BLUE;
	}
	JEOWrite (rp, x, y += 8, Dummy, col);

	sprintf (Filename, "%s%s", config->firstFileDirRecord[filedir_number].n_DirPaths, fentry.Filename);
	size = FileSize (Filename);
	if (size == -1)
	{
		sprintf (Dummy, GLS (&txt_024), Filename);
		if (JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_025)))
			Delete_fentry ();
	}
	else
	{
		if (fentry.Fsize != size)	// Like størrelser?
			EditInitGadget (GD_UPDATE_SIZE, GA_Disabled, OFF);
		else
			EditInitGadget (GD_UPDATE_SIZE, GA_Disabled, ON);
	}

  EditInitGadget (GD_FILE_NAME, GTST_String, (ULONG)fentry.Filename);
  EditInitGadget (GD_COMMENT, GTST_String, (ULONG)fentry.Filedescription);

	if (fentry.Infomsgnr)
		EditInitGadget (GD_FILEINFO, GA_Disabled, OFF);
}

VOID Update_one_filesize (VOID)
{
	int size;

	sprintf (Filename, "%s%s", config->firstFileDirRecord[filedir_number].n_DirPaths, fentry.Filename);
	size = FileSize (Filename);
	if (size == -1)
	{
		sprintf (Dummy, GLS (&txt_024), Filename);
		if (JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_025)))
			Delete_fentry ();
	}
	else
	{
		if (fentry.Fsize != size)
   	{
    	fentry.Fsize = size;
    	SaveFileEntry ();
			UpdateScreen ();
    }
	}
}

VOID Remove_conf (VOID)
{
	if (JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_026), GLS (&txt_027)))
	{
		fentry.Filestatus = 0;	// Tar bort priv til conf
		fentry.Infomsgnr = 0;		// Må ta bort info oxo, må fixes
		SaveFileEntry ();
		UpdateScreen ();
	}
}

BOOL RenameDiskFile (VOID)
{
	BOOL ret = FALSE;

	sprintf (Dummy, "C:Rename \"%s%s\" \"%s%s\"",
			config->firstFileDirRecord[filedir_number].n_DirPaths, tempfentry.Filename,
			config->firstFileDirRecord[filedir_number].n_DirPaths, fentry.Filename);
	Execute (Dummy, NULL, NULL);
	return (ret);
}

BOOL SaveFileEntry (VOID)
{
	int err;
	BOOL ret = FALSE;

	msg.Command = Main_savefileentry;
	msg.UserNr = filedir_number;
	msg.arg = file_order;
	msg.Data = (ULONG)&fentry;
	err = HandleMsg (&msg);
	if (err == Error_OK)
	{
		sprintf (Dummy, "%s%s", config->firstFileDirRecord[filedir_number].n_DirPaths, fentry.Filename);
		SetComment (Dummy, fentry.Filedescription);
		if (saveflag == 2)	// Forandra på navnet??	
		{
			RenameDiskFile ();
			SetupFiles ();
		}
		ret = TRUE;
	}
	else
	{
		sprintf (Dummy, GLS (&txt_028), fentry.Filename);
		JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_OK));
		ret = FALSE;
	}
	return (ret);
}

VOID Edit_file (VOID)
{
	ULONG	waitsigs, gotsigs;
	BOOL quit = 1;

	if (!(OpenEditWindow ()))
	{
		Load_fentry ();
	  CopyMem (&fentry, &tempfentry, sizeof (struct Fileentry));
		UpdateScreen ();
		waitsigs = (1L << EditWnd->UserPort->mp_SigBit);
		while (quit)
		{
			gotsigs = Wait (waitsigs);
			quit = HandleEditIDCMP ();
		}
		if (saveflag)	// Skal vi lagre fentry?
		{
			SaveFileEntry ();
			saveflag = OFF;
		}

		if (EditWnd)
			CloseEditWindow ();
	}
}

// ***********************************************************************
// **************************** SetupDirs ********************************
// ***********************************************************************

struct ueNode
{
	struct Node node;
	char Path[31];
	UWORD number;
	UWORD order;
} *nodes;

/*
VOID Make_list (VOID)
{
	int o, i, n, k, j;
	char Dir[31];

	printf ("\n            [0mFILE LIST\n\n");
	printf ("Dir:      Topics: (if any)
	printf ("----      ----------------
	for (n = 0; n < config->MaxfileDirs; n++)
	{
		if (*(config->firstFileDirRecord[n].n_DirName))
		{
			strcpy (Dir, config->firstFileDirRecord[n].n_DirName);
			for (i = 0; Dir[i] != 0; i++)
			{
				if (Dir[i] == '/')	// Topics found
		}

		}
	}
}
*/

BOOL SetupDirs (VOID)
{
	int	n, num, c;
	UWORD o;

	num = config->ActiveDirs;
	if (!(nodes = AllocVec (num * (sizeof (struct ueNode)), MEMF_CLEAR)))
		return (FALSE);

	if (list)
		FreeVec (list);
	list = (struct Node *)nodes;
	NewList (&listheader);

//	Forbid();
	c = 0;
	for (o = 1; o <= config->MaxfileDirs; o++)	// Sorterer
	{
		for (n = 0; n < config->MaxfileDirs; n++)
		{
			if (*(config->firstFileDirRecord[n].n_DirName))
			{
				if (o == config->firstFileDirRecord[n].n_FileOrder)
				{
//					printf ("Found order %ld: %s\n", config->firstFileDirRecord[n].n_FileOrder, config->firstFileDirRecord[n].n_DirName);
					nodes[c].node.ln_Name = (char *)&config->firstFileDirRecord[n].n_DirName;
					Do_slash (config->firstFileDirRecord[n].n_DirPaths);
					strcpy (nodes[c].Path, config->firstFileDirRecord[n].n_DirPaths);
					nodes[c].order = config->firstFileDirRecord[n].n_FileOrder;
					nodes[c].number = n;
					AddTail (&listheader,&nodes[c].node);
					c++;
					break;
				}
			}
		}
	}
//	Permit();

	GT_SetGadgetAttrs (FileEditorGadgets[GD_LIST_1], FileEditorWnd, NULL , GTLV_Labels,
										 &listheader, TAG_DONE, NULL);
	return (TRUE);
}

// ***********************************************************************
// **************************** SetupFiles *******************************
// ***********************************************************************

int Load_fentry (VOID)
{
	int err;

	msg.Command = Main_loadfileentry;
	msg.UserNr = filedir_number;
	msg.arg = file_order;
	msg.Data = (ULONG)&fentry;
	err = HandleMsg (&msg);
	return (err);
}

VOID Do_fl (char *Name)
{
	UWORD i;

	for (i = 0; Name[i] != 0; i++)
	{
		if (Name[i] == '/')
			Name[i] = ' ';
	}
}

BOOL SetupFiles (VOID)
{
	UBYTE FentryFName[80];
	ULONG o;
	int err;
	int	num, size;
	char Pathname[31];

	if (recCount != 0)
		KillBase ();

	strcpy (Pathname, config->firstFileDirRecord[filedir_number].n_DirName);
	Do_fl (Pathname);
	GT_SetGadgetAttrs (FileEditorGadgets[GD_LIST_2], FileEditorWnd, NULL , GTLV_Labels, 
										 NULL, TAG_DONE, NULL);

	sprintf (FentryFName, "ABBS:Fileheaders/%s.fl", Pathname);
	size = FileSize (FentryFName);
	if (size > 0)
	{
		num = size / sizeof (struct Fileentry);
//		Forbid ();
		for (o = 1;; o++)
		{
			file_order = o;
			err = Load_fentry ();
			if (err == Error_EOF)
				break;
			if (err != Error_OK)
			{
				ErrorMsg (GLS (&txt_029));
				break;
			}

			if (fentry.Filestatus & (FILESTATUSF_Filemoved | FILESTATUSF_Fileremoved))
				continue;

	    if (!(InsertBase ()))
	    {
				JEOReqRequest (GLS (&txt_ERROR), GLS (&txt_030), GLS (&txt_OK));
	    	CleanUp ();
	    }
		}
//		Permit();
		GT_SetGadgetAttrs (FileEditorGadgets[GD_LIST_2], FileEditorWnd, NULL,
			 GTLV_Labels, &sjef.list.lh_Head, TAG_DONE, NULL);
	}
	return (TRUE);
}

BOOL Find_dir (char *Name)
{
	int n;
	struct FileDirRecord *dirarray;

	dirarray = (struct FileDirRecord *)
			(((int) config) + (SIZEOFCONFIGRECORD) +
			(config->Maxconferences * sizeof (struct ConferenceRecord)));

	for (n = 0; n < config->MaxfileDirs; n++)
	{
		if (!(stricmp (dirarray[n].n_DirName, Name)))
			return (TRUE);	// Found!
	}
	return (FALSE);
}

BOOL Create_dir (char *Dirname) 
{
  BOOL flag;
  UWORD i;
  int err;
  char Path[108] = "F1:";

	if (!Dirname[0])	// Ikke noe her
	{
	  if (GetReqString (Dirname, 30, GLS (&txt_031)))
	  {
		 	flag = TRUE;
			if (Find_dir (Dirname))
			{
				sprintf (Dummy, GLS (&txt_032), Dirname);
				JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_OK));
				return (FALSE);
			}

  		for (i = 0; Dirname[i] != 0; i++)
	   	{
  	 		if (Dirname[i] == ' ' OR Dirname[i] == ':')
   			{
   				flag = FALSE;
   				break;
	   		}
   		}
   	}
   	else
   		return (TRUE);	// FALSE er kun for feil...
	}
	else
		flag = TRUE;	// Vi fikk et dir fra readme.

 	if (flag)
 	{
		strcat (Path, Dirname);
 		sprintf (Dummy, GLS (&txt_032), Dirname);
	 	if (GetDirName (Path, Dummy, GLS (&txt_OK)))
    {
     	if (strlen (Path) <= 30)
     	{
     		Do_slash (Path);
				msg.Command = Main_createfiledir;
				msg.Data = (ULONG)&Path;
				msg.Name = Dirname;
    		err = HandleMsg (&msg);
				if (err == Error_OK)
  	  		SetupDirs ();
    		else
    		{
					JEOReqRequest (GLS (&txt_ERROR), GLS (&txt_033), GLS (&txt_OK));
					flag = FALSE;
				}
    	}
    	else
    	{
				JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_034), GLS (&txt_OK));
				flag = FALSE;
			}
		}
 	}
 	else
		JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_035), GLS (&txt_OK));

	return (flag);
}

VOID Edit_dir_path (char *Dirpath)
{
	strcpy (Dirpath, config->firstFileDirRecord[filedir_number].n_DirPaths);
	sprintf (Dummy, GLS (&txt_036), config->firstFileDirRecord[filedir_number].n_DirName);
 	if (GetDirName (Dirpath, Dummy, GLS (&txt_OK)))
  {
		if (stricmp (Dirpath, config->firstFileDirRecord[filedir_number].n_DirPaths))	// Ulik
		{
	   	if (strlen (Dirpath) <= 30)
  	 	{
   			Do_slash (Dirpath);
				strcpy (config->firstFileDirRecord[filedir_number].n_DirPaths, Dirpath);
				Save_config ();
			}
	   	else
				JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_034), GLS (&txt_OK));
		}
 	}
}

VOID Update_size (VOID)
{
	int n;
	char FentryFName[108];
	int temp_nr, temp_order;
	int updated = 0, size, o, err;

	temp_nr = filedir_number;
	temp_order = file_order;
	for (n = 0; n < config->MaxfileDirs; n++)
	{
		if (*(config->firstFileDirRecord[n].n_DirName))	// Finnes navnet?
		{
			sprintf (Dummy, GLS (&txt_037), config->firstFileDirRecord[n].n_DirName);
			Status (Dummy);
			strcpy (Dummy, config->firstFileDirRecord[n].n_DirName);
			Do_fl (Dummy);
			sprintf (FentryFName, "ABBS:Fileheaders/%s.fl", Dummy);
			size = FileSize (FentryFName);
			if (size > 0)	// Noen filer i dette dirret?
			{
				filedir_number = n;
				for (o = 1;; o++)
				{
					file_order = o;
					err = Load_fentry ();
					if (err == Error_EOF)
						break;
					if (err != Error_OK)
					{
						ErrorMsg (GLS (&txt_029));
						break;
					}
					if (fentry.Filestatus & (FILESTATUSF_Filemoved | FILESTATUSF_Fileremoved))
						continue;

					sprintf (Filename, "%s%s", config->firstFileDirRecord[n].n_DirPaths, fentry.Filename);
					size = FileSize (Filename);
					if (size == -1)
					{
						sprintf (Dummy, GLS (&txt_024), Filename);
						if (JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_038)))
							Delete_fentry ();
					}
					else
					{
						if (fentry.Fsize != size)
  	 	    	{
	  	 	    	fentry.Fsize = size;
  	 		    	if (SaveFileEntry ())
   		  	  		updated++;
   		  	  }
   	  	  }
				}
     }
    }
	}
	filedir_number = temp_nr;
	file_order = temp_order;
	sprintf (Dummy, GLS (&txt_110), updated, updated == 1 ? GLS (&txt_111) : GLS (&txt_112));
	JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_OK));
	Status (GLS (&txt_READY));
}

VOID Move_not_installed_files (VOID)
{
	int n;
	char FentryFName[108];
	int temp_nr, temp_order;
	int size;
	int mode;
	static char Path[108] = "TEMP:";
	BOOL exists;
  char Pathname[31];
  struct Node *nd;
  Filbase *bp;
	ULONG files = 0;
	char From[108], To[108];
	WORD copy;

	mode = JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_108), GLS (&txt_109));

	if (!mode)
		return;

	if (mode == 1)	// Move
	{
	 	if (!GetDirName (Path, "Select directory to move files to", GLS (&txt_OK)))
	 		return;
	}
	Do_slash (Path);

	temp_nr = filedir_number;
	temp_order = file_order;
	for (n = 0; n < config->MaxfileDirs; n++)	// Ikke PRIVATE og UPLOAD
	{
		if (*(config->firstFileDirRecord[n].n_DirName))	// Finnes navnet?
		{
			sprintf (Dummy, GLS (&txt_037), config->firstFileDirRecord[n].n_DirName);
			Status (Dummy);
			strcpy (Dummy, config->firstFileDirRecord[n].n_DirName);
			Do_fl (Dummy);
			sprintf (FentryFName, "ABBS:Fileheaders/%s.fl", Dummy);
			size = FileSize (FentryFName);
			if (size > 0)	// Noen filer i dette dirret?
			{
		 		rtSetWaitPointer (FileEditorWnd);
		 		strcpy (Pathname, config->firstFileDirRecord[n].n_DirPaths);
				Do_slash (Pathname);
				fib_Open ();
				if (files = fib_read_files (Pathname, 1))	// 1 = tar også readme-filer
				{
		 		  nd = fib_sjef.list.lh_Head;
			   	bp = (Filbase *)nd;
					while (nd->ln_Succ)	// Går igjenom alle filene på disken...
		 		  {
				    exists = Find_file (bp->Filename);
						if (!exists)	// Legger på disken men er ikke installert...
						{
							sprintf (From, "%s%s", Pathname, bp->Filename);
							if (mode == 1)	// move files
							{
								sprintf (To, "%s%s", Path, bp->Filename);
								sprintf (Dummy, "Move file from '%s' to '%s'", From, To);
								if (JEOReqRequest (GLS (&txt_MESSAGE), Dummy, "Move|Skip file"))
								{							
									copy = Copyfile (From, To, 200);
									if (copy != COPYFILE_OK)
									{
										switch (copy)
										{
											case COPYFILE_OPENFROM: sprintf (Dummy, "COPYFILE: Error opening file: %s!", From); break;
											case COPYFILE_OPENTO: sprintf (Dummy, "COPYFILE: Error opening file: %s!", To); break;
											case COPYFILE_MEM: sprintf (Dummy, "COPYFILE: Not enough memory!"); break;
											case COPYFILE_WRITE: sprintf (Dummy, "COPYFILE: Error writing file %s!", To); break;
											case COPYFILE_NAME: sprintf (Dummy, "COPYFILE: Error in names!"); break;
											case COPYFILE_ZEROSIZE: sprintf (Dummy, "COPYFILE: Error in filesize (0) %s!", From); break;
										}
										JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_OK));
									}
									else
										DeleteFile (From);	// Vi skulle jo move!
								}
							}
							else	// Vi sletter!
							{
								sprintf (Dummy, GLS (&txt_039), From);
								if (JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_040)))
									DeleteFile (From);
							}
						}
						nd = nd->ln_Succ;
		 		    bp = (Filbase *)nd;
				  }
				}
				fib_Close ();
			}
		}
	}
	filedir_number = temp_nr;
	file_order = temp_order;
	Status (GLS (&txt_READY));
}

VOID Delete_dir (VOID)
{
	int err, n;
	BOOL last;

	if (filedir_number == 0 OR filedir_number == 1)
	{
		sprintf (Dummy, GLS (&txt_041), config->firstFileDirRecord[filedir_number].n_DirName);
		JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_OK));
		return;
	}
	
	sprintf (Dummy, GLS (&txt_042), config->firstFileDirRecord[filedir_number].n_DirName);
	if (JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_DELETE_CANCEL)))
	{
		// Sjekker om fila er den siste i rekka!
		last = TRUE;	// Går ut i fra at vi har den siste..
		if (filedir_number + 1 < config->MaxfileDirs)	// Må vi lete?
		{
			for (n = filedir_number + 1; n < config->MaxfileDirs; n++)
			{
				if (*(config->firstFileDirRecord[n].n_DirName))	// Noen her?
				{					
					last = FALSE;	// Jepp, da er vi ikke sist ;)
					break;
				}
			}
		}
		msg.Command = Main_DeleteDir;
		msg.UserNr = filedir_number;
	  err = HandleMsg (&msg);
		if (err == Error_OK)
		{
  		SetupDirs ();
			if (last)
				filedir_number--;
			else
				filedir_number++;
  	}
	  else
			ErrorMsg (GLS (&txt_043));
	}
}

VOID Count_files (VOID)
{
	ULONG n, o, tmp_file_order, tmp_filedir_number, file_count = 0, file_size = 0;
	int err;

	Status (GLS (&txt_PLEASE));
	tmp_file_order = file_order;
	tmp_filedir_number = filedir_number;
	for (n = 0; n < config->MaxfileDirs; n++)
	{
		if (*(config->firstFileDirRecord[n].n_DirName))	// Finnes filedirret?
		{
			filedir_number = n;
			for (o = 1;; o++)
			{
				file_order = o;
				err = Load_fentry ();
				if (err == Error_EOF)
					break;
				if (err != Error_OK)
				{
					ErrorMsg (GLS (&txt_029));
					break;
				}

				if (fentry.Filestatus & (FILESTATUSF_Filemoved | FILESTATUSF_Fileremoved))
					continue;
				else
				{
					file_count++;
					file_size += fentry.Fsize;
					sprintf (Dummy, GLS (&txt_044), file_count, file_size / (1024 * 1024));
					Status (Dummy);
				}
			}
		}
	}
	Status (GLS (&txt_PLEASE));
	sprintf (Dummy, GLS (&txt_045), file_count, file_size / (1024 * 1024));
	JEOReqRequest (GLS (&txt_046), Dummy, GLS (&txt_OK));
	file_order = tmp_file_order;
	filedir_number = tmp_filedir_number;
	Load_fentry ();								// Vi henter tilbake...
	Status (GLS (&txt_READY));
}

VOID handleidcmp (void)
{
	struct IntuiMessage	*m;
	int	n;
	UWORD	code;
 	ULONG class;
	struct IntuiMessage	tmpmsg;
	struct Node *node;
	struct MenuItem *mi;
  struct Node *nd;
  Base *bp;
  char Dirname[31];

	while (m = GT_GetIMsg (FileEditorWnd->UserPort))
	{
		CopyMem ((char *)m, (char *)&tmpmsg, (long)sizeof(struct IntuiMessage));
		GT_ReplyIMsg (m);
		code = tmpmsg.Code;
		class = tmpmsg.Class;
		switch (tmpmsg.Class)
		{
			case	IDCMP_MENUPICK:
			{
				while (code != MENUNULL)
				{
					switch (MENUNUM (code))
					{
						case 0:		// Project
						{
							switch (ITEMNUM (code))
							{
								case 0:	// About
									sprintf (Dummy, "Copyright © 1997-1998 Jan Erik Olausen\n\n%s", GLS (&txt_TRANSLATION));
									JEOReqRequest (GLS (&txt_ABOUT), Dummy, GLS (&txt_OK));
									break;
								case 2:	// Quit
									CleanUp ();
									break;
							}
							break;
						}
						case 1:		// Directories
						{
							switch (ITEMNUM (code))
							{
								case 0:	// New
								{
									All (OFF);
									Dirname[0] = 0;
									Create_dir (Dirname);	// Dirname = intern hold
									All (ON);
									break;
								}
								case 2:	// Change path
								{
									All (OFF);
									if (selected)
										Edit_dir_path (Dirname);
									else
										ErrorMsg (GLS (&txt_047));
									All (ON);
									break;
								}
								case 4:	// Delete
								{
									All (OFF);
									if (selected)
										Delete_dir ();
									else
										ErrorMsg (GLS (&txt_048));
									All (ON);
									break;
								}
								case 6:	// Update
								{
									All (OFF);
									Status (GLS (&txt_PLEASE));
									SetupDirs ();
									Status (GLS (&txt_READY));
									All (ON);
									break;
								}
								default: JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_NOT_YET), GLS (&txt_OK)); break;
							}
							break;
						}
						case 2:		// Files menu
						{
							switch (ITEMNUM (code))
							{
								case 0:	// Auto innstall to dir
								{
									Status (GLS (&txt_PLEASE));
									if (selected)
										Install_files (filedir_number);
									else
										JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_049), GLS (&txt_OK));
									Status (GLS (&txt_READY));
									break;
								}
								case 1:	// Edit file
								{
									if (selected == 2)
									{
										All (OFF);
										Edit_file ();
										All (ON);
									}
									else
										JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_050), GLS (&txt_OK));
									break;
								}
								case 2:	// Delete file
								{
									if (selected == 2)
										Delete_fentry ();
									else
										JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_051), GLS (&txt_OK));
									break;
								}
								case 4:	// Update file sizes
								{
									All (OFF);
									Update_size ();
									All (ON);
									break;
								}
								case 5:	// Count files
								{
									All (OFF);
									Count_files ();
									All (ON);
									break;
								}
								case 7:	// Update preview files
								{
									Status (GLS (&txt_PLEASE));
									Install_preview_files (filedir_number);
									Status (GLS (&txt_READY));
									break;
								}
							}
							break;
						}
						case 3:		// Make Comments
						{
							switch (ITEMNUM (code))
							{
								case 0:	// Load new file-list
								{
									All (OFF);
							    Hent_filliste ();
									Status (GLS (&txt_READY));
									All (ON);
									break;
								}
								case 1:	// From file-list
								{
									All (OFF);
									Lag_beskrivelse ();
									Status (GLS (&txt_READY));
									All (ON);
									break;
								}
							}
							break;
						}
						case 4:	
						{
							switch (ITEMNUM (code))
							{
								case 0:
								{
									All (OFF);
									Test_arc ();
									All (ON);
									break;
								}
								case 3:
								{
									All (OFF);
									Move_not_installed_files ();
									All (ON);
									break;
								}
							}
							break;
						}
						default: JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_NOT_YET), GLS (&txt_OK)); break;
						
					}
					mi = ItemAddress (FileEditorMenus,code);
					code = mi->NextSelect;
				}
				break;
			}
			case	IDCMP_CLOSEWINDOW:
				CleanUp ();
				break;

			case	IDCMP_GADGETUP:
			{
				switch (((struct Gadget *) tmpmsg.IAddress)->GadgetID)
				{
					case GD_LIST_1:
						All (OFF);
						node = listheader.lh_Head;
						for (n = 0; n < tmpmsg.Code; n++)
							node = node->ln_Succ;
						filedir_order = nodes[n].order;
						filedir_number = nodes[n].number;
						filedir_view = n;
						SetupFiles ();
						selected = 1;
						All (ON);
						break;
					case GD_LIST_2:
					  nd = sjef.list.lh_Head;
						for (n = 0; n < tmpmsg.Code; n++)
					    nd = nd->ln_Succ;
						bp = (Base *)nd;
						file_order = bp->fentry_order;
						selected = 2;
						break;
				}
				break;
			}
		}
	}
}

VOID CleanUp (VOID)
{

	if (FileEditorWnd)
		All (OFF);
	if (mycatalog)
		CloseCatalog (mycatalog);
	if (LocaleBase)
		CloseLibrary (LocaleBase);

	if (ur)
		FreeMem (ur, config->UserrecordSize);

	CloseBase ();
  Liste_Close ();

	if (msg.msg.mn_ReplyPort)
		DeleteMsgPort (msg.msg.mn_ReplyPort);

  if (ReqToolsBase)
    CloseLibrary ((struct Library *)ReqToolsBase);

	if (UtilityBase)
		CloseLibrary (UtilityBase);

	if (Dummy)
		FreeMem (Dummy, 5000);

	if (FileEditorWnd)
	{
		All (ON);
		CloseFileEditorWindow ();
	}
	CloseDownScreen ();

	exit (0);
}

BOOL Setup (void)
{
	BOOL ret = FALSE;

	if (LocaleBase = OpenLibrary ("locale.library", 38))
		mycatalog = OpenCatalogA (NULL, CatalogName, NULL);

	if (!(Dummy = AllocMem (5000, MEMF_CLEAR)))
		return (FALSE);
 
	selected = 0;
	if (!(ReqToolsBase = (struct ReqToolsBase *)OpenLibrary (REQTOOLSNAME, REQTOOLSVERSION)))
	{
		sprintf (Dummy, GLS (&txt_052), REQTOOLSNAME, REQTOOLSVERSION);
		JEOEasyRequest (NULL, GLS (&txt_ERROR), Dummy, GLS (&txt_OK), NULL);
		return (FALSE);
	}

	saveflag = OFF;
	if (FindPort (MainPortName))
	{
		if (UtilityBase = OpenLibrary ("utility.library",36))
		{
			if (msg.msg.mn_ReplyPort = CreateMsgPort())
			{
				msg.Command = Main_Getconfig;
				if (HandleMsg (&msg) || !msg.UserNr)
					ErrorMsg (GLS (&txt_053));
				else
				{
					config = (struct ConfigRecord *)msg.Data;
					ret = TRUE;
				}
			}
			else
				ErrorMsg (GLS (&txt_054));
		}
		else
			ErrorMsg (GLS (&txt_055));
	}
	else
		ErrorMsg (GLS (&txt_056));

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

VOID Convert_to_zeros (char *Name, UWORD size)
{
	char *Tmp_name;

	Tmp_name = AllocMem (size, MEMF_CLEAR);	
	strncpy (Tmp_name, Name, size);
	strncpy (Name, Tmp_name, size);	// Tar + 1 fordi slutt 0! 

	FreeMem (Tmp_name, size);
}

VOID Load_user (VOID)
{
	int err;
	NameT Username;

	while (1)
	{
		strcpy (Username, config->SYSOPname);
	  if (!GetReqString (Username, 30, GLS (&txt_001)))
	  	CleanUp ();
		if (*(Username))
		{
			Convert_to_zeros (Username, 31);
			msg.Command = Main_loaduser;
			msg.Name = Username;
			msg.Data = (ULONG)ur;

			err = HandleMsg (&msg);
			if (err == Error_OK)
				break;
			else
			{
				sprintf (Dummy, GLS (&txt_002), Username);
				if (!JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_003)))
					CleanUp ();
			}
		}
	}
}

VOID Save_user (VOID)
{
	int err;

	msg.Command = Main_saveuser;
	msg.Name = ur->Name;
	msg.Data = (ULONG)ur;
	err = HandleMsg (&msg);
	if (err != Error_OK)
	{
		sprintf (Dummy, GLS (&txt_004), ur->Name);
		JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_OK));
		CleanUp ();
	}
}

VOID Status (char *Streng)
{
	char S[61];

	if (strlen (Streng) >= 60)
	{
		strncpy (S, Streng, 60);
		S[58] = '>';
		S[59] = '>';
		S[60] = 0;
	}
	else
		JEOCopy (S, Streng, 60, ' ');
	JEOWrite (main_rp, mainX + STATUSX + 70, STATUSY, S, BLACK);
}

WORD Get_usernumber (char *Name)
{
	int err;

	Convert_to_zeros (Name, 31);

	msg.Command = Main_getusernumber;
	msg.Name = Name;
	msg.Data = 0L;
	err = HandleMsg (&msg);

	if (err == Error_OK)
		return ((WORD)msg.UserNr);
	return (ERROR);
}

VOID __stdargs __main (char *Line)
//void main ()
{
	ULONG	waitsigs, gotsigs;

	Liste_Open ();
	if (!Setup ())
		CleanUp ();

	if (SetupScreen ())
		CleanUp ();
	if (OpenFileEditorWindow ())
		CleanUp ();
	SetWindowTitles (FileEditorWnd, Title, NULL);

	main_rp = FileEditorWnd->RPort;
	DrawImage (main_rp, &Statusimg, mainX, STATUSY - 9);
	StyleIt2 (main_rp, mainX+STATUSX+62, 15, mainX+600,  32, BLACK, WHITE, STRING_STYLE);	/* Status */

	Status (GLS (&txt_PLEASE));

  menu_flag = ON;
	waitsigs = (1L << FileEditorWnd->UserPort->mp_SigBit);
	SetupDirs ();
  NewList (&sjef.list);
  recCount = 0;

	if (!(ur = AllocMem (config->UserrecordSize, MEMF_CLEAR)))
		CleanUp ();

	Load_user ();
	sprintf (WndTitle, GLS (&txt_005), Title, ur->Name);
	SetWindowTitles (FileEditorWnd, WndTitle, NULL);
	Status (GLS (&txt_READY));

//	Make_list ();

	FOREVER
	{
		gotsigs = Wait (waitsigs);
		handleidcmp ();
	}
}
