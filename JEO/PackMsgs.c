;/*
sc5 -j73 -v -O PackMsgs
slink LIB:c.o+"PackMsgs.o" to PackMsgs LIB LIB:sc.lib LIB:reqtools.lib LIB:JEO.lib
Copy PackMsgs ABBS:Utils
Delete PackMsgs.o PackMsgs.info QUIET
quit
*/

#include <JEO:JEO.h>
#include <bbs.h>
#include <proto/exec.h>
#include <exec/memory.h>
#include <proto/dos.h>
//#include <libraries/reqtools.h>
//#include <proto/reqtools.h>


#ifdef __SASC
__regargs int _CXBRK(void) { return(0); }  /* Disable Lattice CTRL/C handling */
__regargs int __chkabort(void) { return(0); }  /* really */
#endif

struct ConfigRecord *config;
char *vers = "\0$VER: PackMsgs v1.01 - 30.10.97";
char Dummy[1000];
char Ok[] = "Ok";
char ConfigFName[] = "ABBS:Config/ConfigFile";
char string[10];
int	configsize = 0;
char Message[] = "Message";

int tot_killed = 0;
int tot_bytes = 0;

int from_msg, to_msg;

VOID Slash_to_space (char *S)
{
	while (*S)
	{
		if (*S == '/')
			*S = ' ';
		*S++;
	}
}

BOOL Check_if_any_killed (char *Buf, int size)
{
	int i;
	struct MessageRecord mr;

	for (i = 0; i < size; i += sizeof (struct MessageRecord))
	{
		CopyMem (&Buf[i], &mr, sizeof (struct MessageRecord));
		if (!(mr.MsgStatus & MSTATF_Diskkilled))	// Ikke killa fra før
		{
			if (mr.MsgStatus & MSTATF_KilledByAuthor)
				return (TRUE);
			else if (mr.MsgStatus & MSTATF_KilledBySysop)
				return (TRUE);
			else if (mr.MsgStatus & MSTATF_KilledBySigop)
				return (TRUE);
			else if (mr.MsgStatus & MSTATF_Moved)
				return (TRUE);
			else if (mr.MsgStatus & MSTATF_Dontshow)
				return (TRUE);
		}
	}
	return (FALSE);
}

VOID Err_no_mem (int size)
{
	printf ("\n  Error allocating memory (%ld bytes)!\n\n", size);
}

VOID Err_opening_file (char *Filename)
{
	printf ("\n  Error opening file '%s'!\n\n", Filename);
}

VOID Err_reading_file (char *Filename)
{
	printf ("\n  Error reading from file '%s'!\n\n", Filename);
}

VOID Err_writing_file (char *Filename)
{
	printf ("\n  Error writing to file '%s'!\n\n", Filename);
}

BOOL SaveConfigfile (VOID)
{
	BPTR file;

	printf ("  Saving configfile...\n");
	if (file = Open (ConfigFName, MODE_OLDFILE))
	{
		Seek (file, 10, OFFSET_BEGINNING);
		if (Write (file,	((APTR) (((ULONG) config) + sizeof (string))), (configsize-sizeof (string))))
		{
			Close (file);
			return (TRUE);
		}
	}
	return (FALSE);
}

VOID PackMessages (int nr, BOOL mode)
{
	char H_name[108], M_name[108];
	char Temp_h[] = "ABBS_P:ABBS_conf_temp.h";
	char Temp_m[] = "ABBS_P:ABBS_conf_temp.m";
	char Hold[81];
	BPTR fh_h, fh_m = 0, fh_temp_h = 0, fh_temp_m = 0;
	int i, size, n;
	struct MessageRecord mr;
	int killed = 0;
	int bytes = 0;
	BOOL kill, ret;
	int offset;
	char *H_buffer, *M_buffer;
	BOOL first;

	strcpy (Hold, config->firstconference[nr].n_ConfName);
	Slash_to_space (Hold);
	sprintf (H_name, "ABBS:Conferences/%s.h", Hold);
	sprintf (M_name, "ABBS:Conferences/%s.m", Hold);

	ret = TRUE;
	if (fh_h = Open (H_name, MODE_OLDFILE))
	{
		if (fh_m = Open (M_name, MODE_OLDFILE))
		{
			if (fh_temp_h = Open (Temp_h, MODE_NEWFILE))
			{
				if (!(fh_temp_m = Open (Temp_m, MODE_NEWFILE)))
				{
					Err_opening_file (Temp_m);
					ret = FALSE;
				}
			}
			else
			{
				Err_opening_file (Temp_h);
				ret = FALSE;
			}
		}
		else
		{
			Err_opening_file (M_name);
			ret = FALSE;
		}
	}
	else
	{
		Err_opening_file (H_name);
		ret = FALSE;
	}

	if (ret)
	{
		if ((size = FileSize (H_name)) > 0)
		{
			if (H_buffer = AllocMem (size, MEMF_CLEAR))
			{
				n = Read (fh_h, H_buffer, size);
				if (n == size)
				{
					if ((Check_if_any_killed (H_buffer, size)) OR (mode))	// Noen killa i den konfen???
					{
						printf ("\n\n  ********************************************************************\n\n", config->firstconference[nr].n_ConfName);
						printf ("  KILLING MESSAGES IN CONFERENCE '%s'\n", config->firstconference[nr].n_ConfName);
						offset = 0;	// Start på ny offset
						first = FALSE;
						for (i = 0; i < size; i += sizeof (struct MessageRecord))
						{
							CopyMem (&H_buffer[i], &mr, sizeof (struct MessageRecord));
							kill = FALSE;
							if (mr.MsgStatus & MSTATF_KilledByAuthor)
								kill = TRUE;
							else if (mr.MsgStatus & MSTATF_KilledBySysop)
								kill = TRUE;
							else if (mr.MsgStatus & MSTATF_KilledBySigop)
								kill = TRUE;
							else if (mr.MsgStatus & MSTATF_Moved)
								kill = TRUE;
							else if (mr.MsgStatus & MSTATF_Dontshow)
								kill = TRUE;
							else if (mr.MsgStatus & MSTATF_Diskkilled)
								kill = TRUE;

							if (mode)	// Har vi satt på manuell killing?
							{
								if ((mr.Number <= to_msg) AND (mr.Number >= from_msg))
									kill = TRUE;
							}
							if (kill)
							{
								if (!(mr.MsgStatus & MSTATF_Diskkilled))
								{
									printf ("%5ld: %s\n", (i / sizeof (struct MessageRecord)) + 1, mr.Subject);
									mr.MsgStatus = 0;
									mr.MsgStatus |= MSTATF_Dontshow;
									mr.MsgStatus |= MSTATF_Diskkilled;
									killed++;
									tot_killed++;
									bytes += mr.NrBytes;
									tot_bytes += mr.NrBytes;
									mr.TextOffs = 0;
									mr.NrBytes = 0;
								}
								Write (fh_temp_h, &mr, sizeof (struct MessageRecord));
							}
							else	// IKKE killa (HER MÅ DET LEGGES INN MERE ERRORSJEKKING
							{
								if (M_buffer = AllocMem (mr.NrBytes, MEMF_CLEAR))	// Da henter vi msg
								{
									if (!first)
									{
										config->firstconference[nr].n_ConfFirstMsg = mr.Number;
										first = TRUE;
									}
									Seek (fh_m, mr.TextOffs, OFFSET_BEGINNING);
									Read (fh_m, M_buffer, mr.NrBytes);
									mr.TextOffs = offset;	// offset i den nye tekstfila
									Write (fh_temp_m, M_buffer, mr.NrBytes);
									FreeMem (M_buffer, mr.NrBytes);
									offset += mr.NrBytes; // Vi må lage nye offsets
									Write (fh_temp_h, &mr, sizeof (struct MessageRecord));
								}
							}
						}
					}
				}
				else
					Err_reading_file (H_name);
				FreeMem (H_buffer, size);
			}
			else
				Err_no_mem (size);
		}
		else
		{
			if (size != 0)
				printf ("\n  Error in file size: %s\n\n", H_name);
		}
	}

	if (fh_h)
		Close (fh_h);
	if (fh_m)
		Close (fh_m);
	if (fh_temp_h)
		Close (fh_temp_h);
	if (fh_temp_m)
		Close (fh_temp_m);

	if (ret AND killed)	// Kopiere og slikt etter at filene er stengt!
	{
		if ((FileSize (Temp_h) >= 0) AND (FileSize (Temp_m) >= 0))	// Virkelig blitt noe?
		{
			printf ("\n  Deleted messages in this conf: %ld (%ld KB)\n", killed, bytes / 1024);
			printf ("        Totaly deleted messages: %ld (%ld KB)\n", tot_killed, tot_bytes / 1024);
			sprintf (Dummy, "C:Copy \"%s\" TO \"%s\"", Temp_h, H_name);
			Execute (Dummy, NULL, NULL);
			sprintf (Dummy, "C:Copy \"%s\" TO \"%s\"", Temp_m, M_name);
			Execute (Dummy, NULL, NULL);
			SaveConfigfile ();
		}
	}
	DeleteFile (Temp_h);
	DeleteFile (Temp_m);
}

BOOL Strip_confs (char *Conf)
{
	int n;
	BOOL all_flag = FALSE, mode;
	BOOL ret = FALSE;

	if (!(stricmp (Conf, "ALL")))
		all_flag = TRUE;

	mode = FALSE;
	for (n = 0; n < config->Maxconferences; n++)
	{
		if (*(config->firstconference[n].n_ConfName))
		{
			if (config->firstconference[n].n_ConfDefaultMsg > 0)	// For å slette...
			{
				if (!all_flag)	// Kun 1 conf?
				{
					if (!(stricmp (Conf, config->firstconference[n].n_ConfName)))
					{
						printf ("\n  Force to kill messages from: ");
						gets (Dummy);
						if (*(Dummy))
						{
							from_msg = atoi (Dummy);
							if (from_msg < 1 OR from_msg > config->firstconference[n].n_ConfDefaultMsg)
								printf ("\n  Error: wrong number!\n");
							else
							{
								printf ("  Enter to message (%ld-%ld): ", from_msg, config->firstconference[n].n_ConfDefaultMsg);
								gets (Dummy);
								if (*(Dummy))
								{
									to_msg = atoi (Dummy);
									if (to_msg < from_msg OR to_msg > config->firstconference[n].n_ConfDefaultMsg)
										printf ("\n  Error: wrong number!\n");
									printf ("\n  DELETING messages from %ld to %ld...", from_msg, to_msg);
									mode = TRUE;
								}
							}
						}
						PackMessages (n, mode);
						return (TRUE);
					}
				}
				else
				{
					PackMessages (n, mode);
					ret = TRUE;
				}
			}
		}
	}
	return (ret);
}

VOID main (int argc, char **argv)
{
	BPTR file;
	int n;
	BOOL ret;

  if (FindPort ("ABBS mainport"))
  {
		JEOEasyRequest (NULL, Message, "Please close ABBS!", Ok, NULL);
    exit (0);
	}

	if (argc != 2)
	{
		printf ("\n  Usage: PackMsgs ALL/<conf name>\n\n");
		exit (0);
	}

	if (file = Open (ConfigFName, MODE_OLDFILE))
	{
		n = Read (file, string, sizeof (string));
		if (n == sizeof (string))
			configsize = ((struct ConfigRecord *) &string)->Configsize;
		else
			Err_reading_file (ConfigFName);
		if (configsize && (config = AllocVec (configsize,NULL)))
		{
			memcpy (config,string,sizeof (string));

			if ((configsize-sizeof (string)) == Read (file,
					((APTR) (((ULONG) config) + sizeof (string))),
					(configsize-sizeof (string))))
			{
				Close (file);
				file = NULL;
				ret = Strip_confs (argv[1]);
			}
			else
				Err_reading_file (ConfigFName);
			if (file)
				 Close (file);
		}
		else
			Err_no_mem (configsize);
	}
	else
		Err_opening_file (ConfigFName);

	FreeVec (config);
	if (ret)
		printf ("\n  Done!\n\n");
	else
		printf ("\n  Error: Cant't find conference '%s'\n\n", argv[1]);
}

/*
struct MessageRecord {
	ULONG		Number;		// Message Number		
	UBYTE		MsgStatus;	// Message Status		
	UBYTE		Security;	// Message security	
	ULONG		MsgFrom;	// user number			
	ULONG		MsgTo;		// Ditto (-1=ALL)		
	NameT		Subject;	// subject of message
	UBYTE		MsgBits;	// Misc bits		   
	struct	DateStamp MsgTimeStamp;	// time entered
	ULONG		RefTo;		// refers to		   
	ULONG		RefBy;		// first answer		
	ULONG		RefNxt;		// next in this thread
	WORD		NrLines;	// number of lines, negative if net names in message body 
	UWORD		NrBytes;	// number of bytes	
	ULONG		TextOffs;	// offset in text file
};

#define MSTATF_NormalMsg		(1L<<0)
#define MSTATF_KilledByAuthor	(1L<<1)
#define MSTATF_KilledBySysop	(1L<<2)
#define MSTATF_KilledBySigop	(1L<<3)
#define MSTATF_Moved				(1L<<4)
#define MSTATF_MsgRead			(1L<<6)			// read by receiver
#define MSTATF_Dontshow			(1L<<7)

#define SECF_SecNone			(1L<<0)
#define SECF_SecPassword	(1L<<1)
#define SECF_SecReceiver	(1L<<2)

#define	MsgBitsF_FromNet	(1L<<0)
*/
