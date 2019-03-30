;/*
Delete Liste_base.o quiet
sc5 -j73 -v -q5e Liste_base
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

Liste_Sjef Liste_sjef;
ULONG liste_len;

ULONG liste_antall;
UBYTE file_start;
UBYTE file_len;
UBYTE cStart = 0;
ULONG file_offsett;
char Com[81];
static char Liste_navn[108] = "";

enum
{
	ISO = 0,
	IBN,
	IBM,
	IBMM, 
};

UBYTE CharSets[][9] =
{
	"Ê¯Â-∆ÿ≈|",
	"ëõÜÑíùèÑ",
	"ëîÜÑíôèÑ",
	"ëõÜÑíùèÑ"
};

BOOL Check_ASCII (UBYTE *Buffer)
{
  if (Buffer[0] == 0x00)		// Executable file
  if (Buffer[1] == 0x00)
  if (Buffer[2] == 0x03)
  if (Buffer[3] == 0xF3)
    return (FALSE);
  if (Buffer[0] == 0xE3)		// Icon file
  if (Buffer[1] == 0x10)
  if (Buffer[2] == 0x00)
  if (Buffer[3] == 0x01)
    return (FALSE );
  if (Buffer[0] == 0x0F)		// Font header file
  if (Buffer[1] == 0x00)
  if (Buffer[2] == 0x00)
    return (FALSE);
  if (Buffer[0] == 0xF3)		// info file
  if (Buffer[1] == 0x4C)
  if (Buffer[2] == 0x00)
  if (Buffer[3] == 0x12)
    return (FALSE);
  if (Buffer[0] == 0x44)		// BootBlock file
  if (Buffer[1] == 0x4F)
  if (Buffer[2] == 0x53)
  if (Buffer[3] == 0x00)
    return (FALSE);
  if (Buffer[0] == 0x46)		// Anc data
  if (Buffer[1] == 0x56)
  if (Buffer[2] == 0x4C)
  if (Buffer[3] == 0x30)
    return (FALSE);
  if (Buffer[0] == 0x00)		// Object file
  if (Buffer[1] == 0x00)
  if (Buffer[2] == 0x03)
  if (Buffer[3] == 0xE7 OR Buffer[3] == 0xFA)
    return (FALSE);
	if (!(strncmp, &Buffer[2], "-lh", 3))	// LHA, LZH archive
    return (FALSE);
	if (!(strncmp, Buffer, "PK", 2))	// ZIP archive
    return (FALSE);
	if (!(strncmp, Buffer, "LZX", 3))	// LZX archive
    return (FALSE);
	if (!(strncmp, Buffer, "DMS", 3))	// DMS archive
    return (FALSE);
	if (!(strncmp, Buffer, "Warp", 4))	// WRP archive
    return (FALSE);
	if (!(strncmp, Buffer, "PP20", 4))	// PP archive
    return (FALSE);
	if (!(strncmp, Buffer, "FORM", 4))	// IFF files
    return (FALSE);
	if (!(strncmp, Buffer, "PP20", 4))	// PP archive
    return (FALSE);

  return (TRUE);
}

BOOL FinnCommentStart (UBYTE *Buf, ULONG fillisteSize)
{
  ULONG i, j, lines;
  BOOL title;

	title = FALSE;
	Status (GLS (&txt_135));

// AMIGA LISTER
	file_len = 18;
// MC FLM
	lines = 0;
  for (i = 0, j = 0; i < fillisteSize; i++, j++)
 	{
    if (Buf[i] == '\n')
    {
    	lines++;
    	if (lines > 100)
	    	break;
	  }
	  else
	  {
			if (i + 10 < fillisteSize)
			{
				if (!(strncmp ("-*- MC FLM", &Buf[i], 10)))
		   	{
				 	file_start = 0;
   				cStart = 35;
   				file_offsett = i + 9;
	   			return (TRUE);
	   		}
  	 	}
  	}
	}

//	FLIM/FILM/FileList
	lines = 0;
	for (i = 0, j = 0; i < fillisteSize; i++, j++)
	{
		if (Buf[i] == '\n')
		{
			lines++;
			if (lines > 100)
				break;
			j = 0;
		}
		else
		{
			if (i + 16 < fillisteSize)
			{
				if (!(strncmp ("File description", &Buf[i], 16)))
			  {
				 	file_start = 2;
					cStart = j - 1;
					file_offsett = i + 30;
					return (TRUE);
				}
			}
		}
	}

// Aminet
	lines = 0;
  for (i = 0, j = 0; i < fillisteSize; i++, j++)
 	{
		if (!title)
 		{
			if (Buf[i] == '\n')
			{
				lines++;
				if (lines > 10)
					break;
			}
			if (i + 7 < fillisteSize)
			{
				if (!(strncmp ("Aminet ", &Buf[i], 7)))
	   			title = TRUE;
	   	}
    }
    else
    {
			if (Buf[i] == '\n')
			{
				lines++;
				if (lines > 200)
					break;
				j = 0;
			}
			else
			{
				if (i + 11 < fillisteSize)
				{
					if (!(strncmp ("Description", &Buf[i], 11)))
				  {
					 	file_start = 0;
						cStart = j - 1;
						file_offsett = i + 50;
						return (TRUE);
					}
				}
			}
		}
  }

// PC LISTER
	file_len = 12;
// AG-GRAB
	lines = 0;
  for (i = 0, j = 0; i < fillisteSize; i++, j++)
 	{
 		if (Buf[i] == 13)
 			continue;
		if (!title)
 		{
			if (Buf[i] == '\n')
			{
				lines++;
				if (lines > 200)
					break;
			}
			if (i + 7 < fillisteSize)
			{
				if (!(strncmp ("AG-GRAB", &Buf[i], 7)))
	   			title = TRUE;
	   	}
    }
    else
    {
			if (Buf[i] == '\n')
			{
				lines++;
				if (lines > 400)
					break;
				j = 0;
			}
			else
			{
				if (i + 11 < fillisteSize)
				{
					if (!(strncmp ("File Description", &Buf[i], 16)))
				  {
					 	file_start = 3;
						cStart = j - 1;
						file_offsett = i + 50;
						return (TRUE);
					}
				}
			}
		}
  }
  return (FALSE);
}

VOID Liste_SlettBase (VOID)
{
  ULONG s;
  struct Node *nd;

	Status (GLS (&txt_PLEASE));
  nd = Liste_sjef.list.lh_Head;
  for (s = 0; s < liste_len; s++)
  {
    Remove (nd);
    FreeMem ((UBYTE *)nd, sizeof (Listebase));
    nd = 0;
    nd = Liste_sjef.list.lh_Head;
  }
  liste_len = 0;
}

VOID Liste_Close (VOID)
{
  Listebase *bp;

  if (liste_len > 0)
  {
	  Liste_SlettBase ();
  	bp = (Listebase *)Liste_sjef.list.lh_Head;
	  while (bp = RemHead (&Liste_sjef.list))
  	{
	    FreeMem (bp, sizeof (Listebase));
  	  bp = 0;
	  }
	}
}

BOOL Sjekk_liste_norsk (UBYTE *Name)
{
  struct Node *nd;
  UBYTE Hold1[108], Hold2[18];

  nd = Liste_sjef.list.lh_Head;
  while (nd->ln_Succ)
  {
    strcpy (Hold1, nd->ln_Name);
    strcpy (Hold2, Name);
    JEOtoupper (Hold1);
    JEOtoupper (Hold2);
    if (!(strcmp (Hold1, Hold2)))
    {
      nd = nd->ln_Pred;
      return (TRUE);
    }
    nd = nd->ln_Succ;
  }
  return (FALSE);
}

BOOL Sjekk_liste (UBYTE *Name)
{
  struct Node *nd;

  nd = Liste_sjef.list.lh_Head;
  while (nd->ln_Succ)
  {
    if (!(stricmp (nd->ln_Name, Name)))
    {

      nd = nd->ln_Pred;
      return (TRUE);
    }
    nd = nd->ln_Succ;
  }
/*
  if (Sjekk_liste_norsk (Name))
    return (TRUE);
*/
	return (FALSE);
}

BOOL Liste_Insett (UBYTE *Name, UBYTE *Comment, ULONG flags)
{
  Listebase *bp = NULL;

  if (bp = (Listebase *)AllocMem (sizeof (Listebase), MEMF_CLEAR))
  {
    strcpy (bp->Name, Name);
    strcpy (bp->Comment, Comment);
    bp->flags = flags;

    bp->nd.ln_Name = bp->Name;
    AddTail (&Liste_sjef.list, &bp->nd);
    liste_len++;
    return (TRUE);
  }
  return (FALSE);
}

BOOL KopierNavn (UBYTE *Navn, UBYTE *Hold)
{
  UBYTE i, len, space, f¯rste;

	f¯rste = space = 0;
  for (i = file_start, len = 0; i < file_start + file_len; i++, len++)
  {
    Navn[len] = Hold[i];
    if (Navn[len] == ' ')
    {
    	if (!space)	// F¯rste spacen
    	{
	    	f¯rste = len;	
	    	space++;
	    }
    }
    else if (space)	// Allerede en space
			return (FALSE);
  }
	if (space)
		len = f¯rste;
  Navn[len] = 0;

	if (len == 0)
		return (FALSE);
	if (!(strncmp (Navn, "---------", 9)))
		return (FALSE);
	if (!(strcmp (Navn, "|File")))
		return (FALSE);
	if (!(strcmp (Navn, "|---------------")))
		return (FALSE);
	if (!(strncmp (Navn, "============", 12)))
		return (FALSE);

	return (TRUE);		
}

BOOL KopierComment (UBYTE *Comment, UBYTE *Hold)
{
  BYTE i, len;

  for (i = cStart, len = 0; Hold[i] != 0; i++, len++)
  {
    Comment[len] = Hold[i];
    if (len == 36)
    	break;
  }
	for (i = len - 1; i >= 0; i--)
	{
		if (Comment[i] != ' ')
		{
		  Comment[i + 1] = 0;
		  goto end;
		}
	}
	Comment[0] = 0;

end:
	if (!(strncmp (Comment, "File Description", 16)))
		return (FALSE);

	return (TRUE);
}

VOID Hent_filliste (VOID)
{
  BPTR fh = 0;
  UBYTE Head[8];
  UBYTE *Buf = 0;
  ULONG i, j;
  UBYTE Navn[18], Comment[40];
  UBYTE Hold[81];
  LONG size;
  WORD ret;
  static char Filskuff[108] = "RAM:";
  char Filename[108];

	ret = TRUE;
  if (FE_GetFileName (Filskuff, Liste_navn, GLS (&txt_124), GLS (&txt_125)))
  {
    rtSetWaitPointer (FileEditorWnd);
		sprintf (Filename, "%s%s", Filskuff, Liste_navn);
    size = FileSize (Filename);
    if (size > 0)
    {
      if ((fh = Open (Filename, MODE_OLDFILE)) != NULL)
      {
        Status (GLS (&txt_126));
        Read (fh, Head, 8);
        if (Check_ASCII (Head))
        {
	        if (Buf = AllocMem (size, MEMF_CLEAR))
  	      {
    	      Read (fh, Buf, size);
      	    Close (fh);
      	    fh = 0;
 	          if (FinnCommentStart (Buf, size))	// Jepp en liste :-)
 	          {
						  Liste_SlettBase ();	// Slett den gammle basen...
							liste_antall = 0;
					 		Status (GLS (&txt_127));
						  for (i = file_offsett, j = 0; i < size; i++)
						  {
						  	if (Buf[i] == 13)
						  		continue;
						  	Hold[j] = Buf[i];
						  	if (Buf[i] == '\n')
						  	{
						  		Hold[j] = 0;
						  		if (j > 35)
						  		{
							  		if (KopierNavn (Navn, Hold))
							  		{
							  			if (KopierComment (Comment, Hold))
							  			{
								  			if (!Liste_Insett (Navn, Comment, 0))	// Ikke nok minne
								  			{
								  				ret = -2;
								  				break;
								  			}
								  			else
								  				liste_antall++;
							  			}
							  		}
							  	}
						  		j = 0;
						  	}
						  	else
						  	{
							  	j++;
							  	if (j > 80)
							  	{
										JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_128), GLS (&txt_OK));
										break;
							  	}
							  }
						  }
						}
						else
							ret = -3;
  	      }
	        else
	        	ret = -2;
				}
  	    else
  	    	ret = -1;
      }
      else
      	ret = -4;
    }
    else
    	ret = -4;
  }
  else
    ret = FALSE;

	if (Buf)
	{
		FreeMem (Buf, size);
		Buf = 0;
	}
	if (fh)
	{
		Close (fh);
  	fh = 0;
	}

	if (ret < 0)
		cStart = 0;

	switch (ret)
	{
    case -1: JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_129), GLS (&txt_OK)); break;
    case -2: JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_030), GLS (&txt_OK));  break;
		case -3: JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_130), GLS (&txt_OK)); break;
		case -4: JEOReqRequest (GLS (&txt_MESSAGE), GLS (&txt_131), GLS (&txt_OK)); break;
	}
}

// ******************************************************************************
// ********************************** COMMENT ***********************************
// ******************************************************************************

BOOL Check_comment (UBYTE *Descr)
{
	if (strlen (Descr) <= 2)
		return (TRUE);
  if (!(strncmp (Descr, "FileEditor: No d", 16)))	// FileEditor
    return (TRUE);
  if (!(strncmp (Descr, "Local upload by", 15)))	// AFE, MakeComment
    return (TRUE);
  if (!(strncmp (Descr, "http://", 7)))
    return (TRUE);
  if (!(strncmp (Descr, "ftp://", 6)))
    return (TRUE);

   return (FALSE);
}

WORD FinnCommentFraListe (VOID)
{
  BOOL save_flagg = AV;
  struct Node *nd;
  Listebase *bp;

  if (fentry.Filedescription[0] == 0)
  {
    save_flagg = ON;
    strcpy (fentry.Filedescription, Comment_string);	// Legger inn standard string
		Com[0] = 0;
  }

	nd = Liste_sjef.list.lh_Head;
	bp = (Listebase *)nd;
	while (nd->ln_Succ)
	{
		if (CheckESC (FileEditorWnd))
			return (ERROR);
		if (!(stricmp (bp->Name, fentry.Filename)))	// Finner vi fila i lista?
		{
			strcpy (Com, bp->Comment);	// Jepp, kopierer over komment
			save_flagg = ON;
			return (TRUE);
		}
		nd = nd->ln_Succ;
		bp = (Listebase *)nd;
	}

  if (save_flagg)
    return (TRUE);
  else
    return (FALSE);
}

//BOOL cStart = FALSE;

VOID Lag_beskrivelse (VOID)
{
	int n;
	int temp_nr, temp_order;
	int updated = 0, o, err;

  if (!cStart)
  {
    Hent_filliste ();
    if (!cStart)
      return;
  }

  sprintf (Dummy, GLS (&txt_132), Liste_navn, liste_antall);
  if (!JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_072)))
    return;
	rtSetWaitPointer (FileEditorWnd);

	temp_nr = filedir_number;
	temp_order = file_order;
	for (n = 0; n < config->MaxfileDirs; n++)
	{
		if (*(config->firstFileDirRecord[n].n_DirName))	// Finnes navnet?
		{
			sprintf (Dummy, GLS (&txt_133), config->firstFileDirRecord[n].n_DirName);
			Status (Dummy);
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
					continue;	// Fila er ikke her!
    	  if (Check_comment (fentry.Filedescription))	// Trenger vi Â forandre?
	      {																						// JA!
  	      switch (FinnCommentFraListe ())						// Ny comment i Com[]
 	  	    {
   	  	    case TRUE:
     	  	  {
              if (Com[0])			// Regner med at vi fant noe....
              {
								strcpy (fentry.Filedescription, Com);
								Status (Com);
								SaveFileEntry ();
								updated++;
//								Lag_disk_beskrivelse (i, j);
    	        }
   	        	break;
      	    }
        	  case ERROR:	// Vi breaka
	            break;
  	      }
    	  }
    	}
    }
	}

	filedir_number = temp_nr;
	file_order = temp_order;
	if (selected)	// har vi valgt dir?
		SetupFiles ();
	sprintf (Dummy, GLS (&txt_134), updated, updated == 1 ? GLS (&txt_060) : GLS (&txt_061));
	JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_OK));
	Status (GLS (&txt_READY));
}

VOID Liste_Open (VOID)
{
  liste_len = 0;
  NewList (&Liste_sjef.list);
}
