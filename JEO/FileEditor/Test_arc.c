;/*
sc5 -j73 Test_arc
x fe.s
quit
*/

#include <JEO:JEO.h>
#include <proto/intuition.h>
#include <proto/dos.h>
#include <exec/memory.h>
#include <proto/reqtools.h>
#include <FE:FE.h>
#include <FE:GUI.h>
#include <bbs.h>
#include <JEO:raw.h>

#define PACK_PÅ		(UBYTE)'·'

VOID Finn_siste_linje (UBYTE *Buffer, UBYTE *Linje, BYTE pakk)
{
  LONG i, j, len;
  WORD cnt;
  UBYTE Hold[256];
  UWORD ln;

	switch (pakk)
	{
		case PACK_LHA: ln = 1; break;
		case PACK_ARC: ln = 1; break;
		case PACK_LZX: ln = 2; break;
		case PACK_DMS: ln = 2; break;
		case PACK_GIF: ln = 1; break;
		case PACK_ZIP: ln = 1; break;
		default: ln = 10;
	}

  cnt = 0;
  len = strlen (Buffer) - 1;
  for (i = len, j = 0; i > 0; i--)
  {
    Linje[j] = Buffer[i];
    if (Buffer[i] == '\n' OR Buffer[i] == 13 OR Buffer[i] == 0)
    {
      Linje[j] = 0;
			if (ln == 10)
			  printf ("%ld %s\n", cnt, Linje);
      if (cnt == ln)
        break;
      j = 0;
      cnt++;
    }
    else
    	j++;
  }
  len = strlen (Linje);
	if (len)
	{
		if (pakk == PACK_LZX)
		{
			if (len > 12)
				len = 12;
		  for (i = 0, j = len - 1; i < len; i++, j--)
  		  Hold[j] = Linje[i];
		  Hold[len] = 0;
		}
		else if (pakk == PACK_ZIP)
		{
			if (len > 3)
				len = 3;
		  for (i = 0, j = len - 1; i < len; i++, j--)
  		  Hold[j] = Linje[i];
		  Hold[len] = 0;
		}
		else
		{
		  for (i = 0, j = len - 1; i < len; i++, j--)
  		  Hold[j] = Linje[i];
		  Hold[len] = 0;
		}
  	strcpy (Linje, Hold);
  }
//  printf ("%s\n", Linje);
}

WORD Sjekk_pakkemetode (UBYTE *Navn)
{
  UWORD len, i, j;

  len = strlen (Navn);
  if (len < 4)
    return (ERROR);

  for (i = len - 4, j = 0; i < len; i++, j++)
    Dummy[j] = Navn[i];

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

VOID Test_arc (VOID)
{
  BPTR fh = 0;
 	char ErrorFname[] = "T:FE_Test_arc.ERROR";
  char ArcFname[] = "ABBS:-Arc.ERROR";
  UBYTE *Buffer = 0;
  UBYTE Fil[256];
  BYTE pakk;
  UBYTE ErrMsg[80];
  BOOL lagre;
  UBYTE test;
  UBYTE Hold[256];
  BOOL LHA_feil, LZX_feil, ARC_feil, DMS_feil, GIF_feil, ZIP_feil;
  ULONG sjekket = 0;
  ULONG feil = 0, n, o;
 	char FentryFName[80];
	int num, size, err;

  if (!(test = JEOReqRequest (GLS (&txt_103), GLS (&txt_057), GLS (&txt_058))))
    return;
  
  rtSetWaitPointer (FileEditorWnd);
  LHA_feil = LZX_feil = ARC_feil = DMS_feil = GIF_feil = ZIP_feil = AV;

  fh = Open (ArcFname, MODE_NEWFILE);				// Lage, åpne ny :)
	if (fh)
	{
    Close (fh);
    fh = 0;
  }

  lagre = AV;
	for (n = 0; n < config->MaxfileDirs; n++)
	{
		if (*(config->firstFileDirRecord[n].n_DirName))	// Finnes navnet?
		{
			strcpy (Dummy, config->firstFileDirRecord[n].n_DirName);
			Do_fl (Dummy);
			sprintf (FentryFName, "ABBS:Fileheaders/%s.fl", Dummy);
			size = FileSize (FentryFName);
			if (size > 0)
			{
				filedir_number = n;
				num = size / sizeof (struct Fileentry);
				for (o = 1;; o++)
				{
					if (CheckKey (FileEditorWnd, ESC))
						goto end;
					file_order = o;
					err = Load_fentry ();
					if (err == Error_EOF)
						break;
					if (err != Error_OK)
					{
						printf ("Error reading fileentry\n");
						break;
					}
					if (fentry.Filestatus & (FILESTATUSF_Filemoved | FILESTATUSF_Fileremoved))
						continue;

					if (fentry.pad1 & PAD1STATUSF_ArcTested)	// Allerede testet?
    	    {
	          if (test == 1)	// Test kun nye
  	          continue;
    	    }
	        if ((pakk = Sjekk_pakkemetode (fentry.Filename)) == ERROR)
	        	continue;
    	    strcpy (Fil, config->firstFileDirRecord[n].n_DirPaths);
	        Do_slash (Fil);
  	      strcat (Fil, fentry.Filename);
	        sprintf (Dummy, GLS (&txt_TESTING), Fil);
	        Status (Dummy);
  	      if (fh = Open (ErrorFname, MODE_NEWFILE))
    	    {
      	    switch (pakk)
	          {
  	          case PACK_LHA:
    	        {
      	        if (FileSize ("C:LHA") > 0)
        	      {
          	      sprintf (Dummy, "C:LHA t %s", Fil);
            	    Execute (Dummy, NULL, fh);
              	  strcpy (ErrMsg, "Operation successful.");
	              }
  	            else if (!LHA_feil)
    	          {
      	          ErrorMsg ("Error executing 'C:LHA'");
        	        LHA_feil = PÅ;
          	      rtSetWaitPointer (FileEditorWnd);
            	  }
	              break;
  	          }
  	          case PACK_ZIP:
    	        {
      	        if (FileSize ("C:ZIP") > 0)
        	      {
          	      sprintf (Dummy, "C:ZIP -T %s", Fil);
            	    Execute (Dummy, NULL, fh);
              	  strcpy (ErrMsg, " OK");
	              }
  	            else if (!ZIP_feil)
    	          {
      	          ErrorMsg ("Error executing 'C:ZIP'");
        	        LHA_feil = PÅ;
          	      rtSetWaitPointer (FileEditorWnd);
            	  }
	              break;
  	          }
	            case PACK_LZX:
  	          {
    	          if (FileSize ("C:LZX") > 0)
      	        {
        	        sprintf (Dummy, "C:LZX t %s", Fil);
          	      Execute (Dummy, NULL, fh);
            	    strcpy (ErrMsg, "all files OK");
	              }
  	            else if (!LZX_feil)
    	          {
      	          ErrorMsg ("Error executing 'C:LZX'");
        	        LZX_feil = PÅ;
          	      rtSetWaitPointer (FileEditorWnd);
	              }
  	            break;
    	        }
	            case PACK_ARC:
  	          {
    	          if (FileSize ("C:ARC") > 0)
      	        {
        	        sprintf (Dummy, "C:ARC t %s", Fil);
          	      Execute (Dummy, NULL, fh);
            	    strcpy (ErrMsg, "No errors detected");
              	}
	              else if (!ARC_feil)
  	            {
    	            ErrorMsg ("Error executing 'C:ARC'");
      	          ARC_feil = PÅ;
        	        rtSetWaitPointer (FileEditorWnd);
          	    }
	              break;
  	          }
    	        case PACK_DMS:
      	      {
        	      if (FileSize ("C:DMS") > 0)
          	    {
            	    sprintf (Dummy, "C:DMS test %s", Fil);
              	  Execute (Dummy, NULL, fh);
	                strcpy (ErrMsg, " All Done!");
  	            }
    	          else if (!DMS_feil)
      	        {
        	        ErrorMsg ("Error executing 'C:DMS'");
          	      DMS_feil = PÅ;
            	    rtSetWaitPointer (FileEditorWnd);
              	}
	              break;
  	          }
    	        case PACK_GIF:
      	      {
        	      if (FileSize ("C:GIFINFO") > 0)
          	    {
            	    sprintf (Dummy, "Failat 500000000\nC:GIFINFO -ver %s", Fil);
              	  Execute (Dummy, NULL, fh);
                	strcpy (ErrMsg, "            Size     =");
	              }
  	            else if (!GIF_feil)
    	          {
      	          ErrorMsg ("Error executing 'C:GIFINFO'");
        	        GIF_feil = PÅ;
          	      rtSetWaitPointer (FileEditorWnd);
            	  }
	              break;
  	          }
    	      }
      	    Close (fh);
        	  fh = 0;

	          size = FileSize (ErrorFname);
  	        if (size > 0)
    	      {
      	      if (Buffer = AllocMem (size, MEMF_CLEAR))
        	    {
	  	          if (fh = Open (ErrorFname, MODE_OLDFILE))
  	  	        {
    	  	        Read (fh, Buffer, size);
      	  	      Close (fh);
        	  	    fh = 0;
          	  	  DeleteFile (ErrorFname);
	          	  }
	          	}
	          	else
	          	{
          	    DB;
            	  ErrorMsg (GLS (&txt_030));
              	goto end;
              }

	            Finn_siste_linje (Buffer, Hold, pakk); // Eller nest siste :-)
  	          if (strnicmp (Hold, ErrMsg, strlen (ErrMsg)))	// ERROR
    	        {
      	      	if (fentry.pad1 & PAD1STATUSF_ArcTested)	// På?
      	      	{
									fentry.pad1 |= PAD1STATUSF_ArcTested;		// Slår av..
  		       	    SaveFileEntry ();
  		       	  }
  	            feil++;
    	          sprintf (Dummy, "Seems to be a problem with file: '%s'!\n", Fil);
    	          if (fh = Open (ArcFname, MODE_OLDFILE))
      	        {
        	        Seek (fh, 0, OFFSET_END);
          	      Write (fh, Dummy, strlen (Dummy));
            	    Close (fh);
              	  fh = 0;
	              }
      	      }
      	      else
      	      {
      	      	if (!(fentry.pad1 & PAD1STATUSF_ArcTested))	// Ikke på?
      	      	{
		         	    fentry.pad1 |= PAD1STATUSF_ArcTested;
  		       	    SaveFileEntry ();
  		       	   }
	 	       	  }
	            sjekket++;
  	          if (Buffer)
    	        {
      	        FreeMem (Buffer, size);
        	      Buffer = 0;
          	  }
          	}
          }
        }
      }
    }
  }
end:
  if (Buffer)
  {
    FreeMem (Buffer, size);
    Buffer = 0;
  }

  sprintf (Dummy, GLS (&txt_059), sjekket, sjekket == 1 ? GLS (&txt_060) : GLS (&txt_061));
  if (feil)
  {
    sprintf (Hold, GLS (&txt_062), feil, feil == 1 ? GLS (&txt_063) : GLS (&txt_064), ArcFname);
    strcat (Dummy, Hold);
  }
  else
    strcat (Dummy, GLS (&txt_065));
  
  JEOReqRequest (GLS (&txt_MESSAGE), Dummy, GLS (&txt_OK));
	Status (GLS (&txt_READY));
}

WORD CheckKey (struct Window *w, USHORT key)
{
  struct IntuiMessage *message;
  ULONG class;
  USHORT Code;

  while (message = (struct IntuiMessage *)GetMsg (w->UserPort))
  {
    class = message->Class;
    Code = message->Code;
    ReplyMsg ((struct Message *)message);

    switch (class)
    {
			case IDCMP_RAWKEY:
      {
        if (Code == key)
          return (TRUE);
      }
    }
  }
  return (FALSE);
}
