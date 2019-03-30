;/*
sc5 -j73 Comment
x FE.s
quit
*/

#include <JEO:JEO.h>
#include <proto/dos.h>
#include <exec/memory.h>
#include "FE:FE.h"

// ******************************************************************************
// ********************************** COMMENT ***********************************
// ******************************************************************************

BOOL Sjekk_kommentar (UBYTE *Descr)
{
  if (Descr[0] == 0)
    return (TRUE);
  if (!(strncmp (Descr, "FileEditor: No d", 16)))	// FileEditor
    return (TRUE);
  if (!(strncmp (Descr, "Local upload by", 15)))	// AFE, MakeComment
    return (TRUE);
  if (!(strncmp (Descr, "?", 1)))
    return (TRUE);
  if (!(strncmp (Descr, "http://", 7)))
    return (TRUE);
  if (!(strncmp (Descr, "ftp://", 6)))
    return (TRUE);

   return (FALSE);
}

WORD FinnCommentFraListe (ULONG nr, ULONG nr1)
{
  BOOL save_flagg = AV;
  struct Node *nd;
  Listebase *bp;

  if (fl_all[nr][nr1].fe_Descr[0] == 0)
  {
    save_flagg = PÅ;
    strcpy (fl_all[nr][nr1].fe_Descr, Comment_string);
		Com[0] = 0;
  }

	nd = Liste_sjef.list.lh_Head;
	bp = (Listebase *)nd;
	while (nd->ln_Succ)
	{
		if (CheckESC (MainWnd))
			return (ERROR);
		if (!(stricmp (bp->Name, fl_all[nr][nr1].fe_Name)))
		{
			strcpy (Com, bp->Comment);
			save_flagg = PÅ;
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

BOOL cStart = FALSE;

VOID Lag_beskrivelse (VOID)
{
  ULONG i, y, c, j, l;
  BOOL save_flagg;

  if (!cStart)
  {
    Hent_filliste ();
    if (!cStart)
      return;
  }

  sprintf (Dummy, "Do comments from '%s'?", Liste_navn);
  if (!JEOReqRequest (GLS (&txt_MESSAGE), Dummy, "Ja|Avbryt"))
    return;
	rtSetWaitPointer (FileEditorWnd);
  save_flagg = AV;
	for (i = 0; i < 100; i++)	// Må forandres
	{
		if (configfile->bc_FileDirNames[i][0])
		{
	    fl_lagt_til[i] = AV;
  	  sprintf (Dummy, "%-30s", configfile->bc_FileDirNames[i]);
	    Status (Dummy);
	    for (j = 0; j < fl_size[i] / sizeof (struct FileEntry); j++)
  	  {
				if ((fl_all[i][j].fe_Flags & FEF_ZAPPED) OR (fl_all[i][j].fe_Flags & FEF_MOVED))	// Funnet, men slettet
  	      continue;
    	  if (Sjekk_kommentar (fl_all[i][j].fe_Descr))	// Let etter søk comment
	      {
	        switch (FinnCommentFraListe (i, j))
  	      {
    	      case TRUE:
      	    {
	            fl_lagt_til[i] = save_flagg = PÅ;
              if (Com[0])
              {
								strcpy (fl_all[i][j].fe_Descr, Com);
									Lag_disk_beskrivelse (i, j);
  		          sprintf (Dummy, "%-16s", fl_all[i][j].fe_Name);
    		        strcpy (Name_out[c - 1], Dummy);
      		      JEOWrite (rp, NAVN + TAB, y - 8, Dummy, SORT);
        		    sprintf (Dummy, "%-38s", fl_all[i][j].fe_Descr);
	        	    strcpy (Com_out[c - 1], Dummy);
  	        	  JEOWrite (rp, COM + TAB, y - 8, Dummy, SORT);
    	        }
   	        	break;
      	    }
        	  case ERROR:
	            goto end;
  	      }
    	  }
    	}
    }
    Status (GLS (&txt_PLEASE));
  }
end:
  if (save_flagg)
    Lagre_alle_fl ();
}
*/
