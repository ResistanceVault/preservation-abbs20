 /****************************************************************
 *
 * NAME
 *		QWK.c
 *
 * DESCRIPTION
 *		QWK routines for abbs
 *
 * AUTHOR
 *	Geir Inge Høsteng
 *
 * $Id: QWK.c 1.1 1995/06/24 10:34:52 geirhos Exp geirhos $
 *
 * MODIFICATION HISTORY
 * $Log: QWK.c $
 * Revision 1.1  1995/06/24  10:34:52  geirhos
 * Initial revision
 *
 *
 ****************************************************************/

#include <exec/types.h>
#include <exec/memory.h>
#include <bbs.h>
#include <node.h>

#include <dos/dos.h>
#include <dos/dosextens.h>
#include <dos/filehandler.h>
#include <utility/date.h>
#include <devices/SCSIdisk.h>

#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/utility.h>

#include <string.h>
#include <ctype.h>
#include <dos.h>

#define	a4a5 register __a4 struct ramblocks *nodebase,register __a5 struct Mainmemory *mainmeory
#define	usea4a5	nodebase,mainmeory

__asm int packmessages(a4a5);
__asm int unpackmessages (a4a5);
__asm int dograbmsg (register __d0 int nr, register __d1 int conf,register __d2 BPTR msgfil,a4a5,
				register __d3 int *msgnr,register __d4 int *touser,register __d5 int *numgrabbed);

__asm int unpackmsg (register __d0 BPTR msgfil,a4a5);
__asm int doctrldatfile(register __d0 int msgnr,a4a5);
__asm ULONG	mygetusernumber (register __a2 char *name,a4a5);

__asm int initdatafile (register __d0 BPTR msgfil,a4a5);
__asm	void getbiggestdisksub (register __a0 char *name,register __d0 ULONG num);
__asm void getbiggestdisk (void);
int	mystricmp (char *ptr, char *ptr2);
int	strincmp (char *ptr, char *ptr2,int len);
char	*removespace(char *string,int maxlength);
__asm void	convertstringfromiso (register __a0 unsigned char *string,a4a5);
__asm unsigned char	convertcharfromiso (register __d0 unsigned char c,a4a5);
__asm unsigned char	convertchartoiso (register __d0 unsigned char c,a4a5);
__asm void	convertstringtoiso (register __a0 unsigned char *string,a4a5);
int readblocks (struct IOStdReq *SCSIIO,int num,ULONG length,void *buffer);
__asm ULONG	copybulletin (register __a0 char *fromname,
									register __a1 char *toname,a4a5);

extern far int msprintf(char *, const char *, ...);
extern __asm far writecontext (register __a0 char *text,a4a5);
extern __asm far writetexto (register __a0 char *text,a4a5);
extern __asm far writetexti (register __a0 char *text,a4a5);
extern __asm far writeerroro (register __a0 char *text,a4a5);
__asm far VOID ANSIwriteerroro (register __a0 char *text,a4a5);
extern __asm far UWORD loadmsg (register __a0 char *msgtext,
		register __a1 struct MessageRecord *msgheader,
		register __d0 ULONG msgnr, register __d1 UWORD confnr,a4a5);
extern __asm far UWORD savemsg (register __a0 char *msgtext,
		register __a1 struct MessageRecord *msgheader,
		register __d0 UWORD confnr,a4a5);

extern __asm far UWORD loadmsgheader (register __a0 struct MessageRecord *msgheader,
		register __d0 ULONG msgnr, register __d1 UWORD confnr,a4a5);
extern __asm far UWORD loadmsgtext (register __a0 UBYTE *msgbyf,
		register __a1 struct MessageRecord *msgheader,register __d0 UWORD confnr,a4a5);
extern __asm far UWORD savemsgheader (register __a0 struct MessageRecord *msgheader,
		register __d0 UWORD confnr,a4a5);
extern __asm far UWORD savemsgheader (register __a0 struct MessageRecord *msgheader,
		register __d0 UWORD confnr,a4a5);
extern __asm far strcopylen (register __a0 char *from,register __a1 char *to,
		register __d0 UWORD length,a4a5);
extern __asm far char *getusername (register __d0 ULONG usernr,a4a5);
extern __asm far void removefromqueue (register __d0 ULONG msgnr,a4a5);
extern __asm far ULONG getusernumber (register __a0 char *name,a4a5);
extern __asm far ULONG atoi (register __a0 char *text);
extern __asm far int checkmemberofconf (register __d0 ULONG usernr,register __d1 ULONG confnr,a4a5);
extern far int checkformsgerror (void);
extern far void clearmsgerror (void);
extern __asm far void unjoin (a4a5);
extern __asm far ULONG	gettopqueue (a4a5);
extern __asm void stopreviewmessages (register __d0 ULONG msgnr,a4a5);
extern __asm void sendintermsgmsg (register __a0 struct MessageRecord *msgheader,
				register __a1 char *text,register __d0 UWORD confnr,a4a5);
extern __asm void killrepwritelog (register __a0 char *logtext,register __d0 UWORD confnr,
				register __d1 ULONG msgnr,a4a5);
extern __asm void killrepwritelog (register __a0 char *logtext,register __d0 UWORD confnr,
				register __d1 ULONG msgnr,a4a5);
extern __asm int kanskrive (register __a0 struct MessageRecord *msgheader,
				register __d0 UWORD confnr,a4a5);

extern __asm int getfromname (register __a0 struct MessageRecord *msgheader,
				register __a1 UBYTE *msgtext,a4a5);
extern __asm int gettoname (register __a0 struct MessageRecord *msgheader,
				register __a1 UBYTE *msgtext,a4a5);
extern __asm int skipnetnames (register __a0 UBYTE *msgtext,register __d0 int msgsize,a4a5);
extern __asm int checkupdatedbulletins (register __d0 UWORD confnr,register __d1 int mode,a4a5);
extern __asm short getnextconfnr (register __d0 short conf,a4a5);
extern __asm int getnetsubject (register __a0 char *msgtext);

extern far ULONG exebase;
extern far struct DosLibrary *DOSBase;
extern far struct Library *UtilityBase;
extern far UBYTE	fraISOtilIBN[128];
extern far UBYTE	fraIBNtilISO[128];
extern far char	logentermsgtext[];
extern far char	logreplymsgtext[];
extern far char CursorOffData[];
extern far char CursorOnData[];

__asm int unpackmessages (a4a5)
{
	BPTR	msgfil = 0;
	char	tmpstring[80];
	int	ret = 1,tmp,nottotalok = 0;
	char	buffer[128+2];
	struct ConfigRecord *configdata = &mainmeory->config;
	int tmplines;

// Wait 3 seconds for slow Ncomm response
	Delay (3*TICKS_PER_SECOND);


	tmplines = nodebase->linesleft;
	nodebase->linesleft = 65535;	// Vi vil ikke ha noen more her..

	while (1)
	{
		msprintf (tmpstring, "%ls/%ls.MSG", nodebase->Nodemem.TmpPath, configdata->BaseName);
		if (!(msgfil = Open(tmpstring,MODE_OLDFILE)))
		{
			putreg (REG_A6,exebase);
			ANSIwriteerroro ("Error opening msg file!",usea4a5);
			break;
		}

		if (128 != Read (msgfil,buffer,128))
		{
			putreg (REG_A6,exebase);
			ANSIwriteerroro ("File error!",usea4a5);
			break;
		}

		if (strlen (configdata->BaseName) > 8)
		{
			if (strincmp (configdata->BaseName,buffer,8))
			{
				putreg (REG_A6,exebase);
				ANSIwriteerroro ("Wrong BBSid!",usea4a5);
				break;
			}
		}
		else
		{
			if (mystricmp (configdata->BaseName,buffer))
			{
				putreg (REG_A6,exebase);
				ANSIwriteerroro ("Wrong BBSid!",usea4a5);
				break;
			}
		}

		putreg (REG_A6,exebase);
		writetexto ("\n[32m******************************** Reading REP ********************************\n",usea4a5);
		putreg (REG_A6,exebase);
		writetexto ("[36mNumber Ref #  Conference         To                        Subject",usea4a5);
		putreg (REG_A6,exebase);
		writetexto ("------ ------ ------------------ ------------------------- ------------------",usea4a5);

		while (1)
		{
			putreg (REG_A6,exebase);
			tmp = unpackmsg(msgfil,usea4a5);
			if (!tmp)
				continue;

			if (tmp == 2)
			{
				nottotalok = 1;
				continue;
			}
			break;
		}

		if (tmp == 1)
		{
			ret = 0;
			putreg (REG_A6,exebase);
			writetexto ("[36m------ ------ ------------------ ------------------------- ------------------",usea4a5);
			if (nottotalok)
			{			
				putreg (REG_A6,exebase);
				writetexto ("\n[31mREPly file parsed with some errors!\n[0m",usea4a5);
			}
			else
			{
				putreg (REG_A6,exebase);
				writetexto ("\n32mREPly file parsed successfully.\n[0m",usea4a5);
			}
		}

		break;
	}

	if (msgfil)
		Close (msgfil);

	DeleteFile (tmpstring);

	nodebase->linesleft = tmplines;

	putreg (REG_A6,exebase);
	return (ret ? -1L : 0);
}

/* returns -1 for fatal errors, 1 for endoffile, 2 for non-fatal error (msg skipped)
	and 0 for all ok (1 message parsed)
*/
__asm int unpackmsg (register __d0 BPTR msgfil,a4a5)
{
	int	ret = -1;
	int	confnr,tmp,numblocks,replyto,msgnr;
	int	dobreak = 0,havreadmsg = 0,netmsg = 0;
	UBYTE	*ptr,*msgstart;
	struct ClockData dt;
	struct DateStamp ds;
	struct	MessageRecord *msgheader;
	char	buffer[128+2],tmpbuf[30],string[100],tmpbuf2[20],tmpbuf3[9];
	struct ConfigRecord *configdata = &mainmeory->config;

	msgheader = &nodebase->tmpmsgheader;

	while (1)
	{
		tmp = Read (msgfil,buffer,128);	/* Read first block in message */
		if (!tmp)
		{								/* if eof, return 1 */
			ret = 1;
			break;
		}

		if (128 != tmp)
		{
			putreg (REG_A6,exebase);
			ANSIwriteerroro ("Error reading first block a message!",usea4a5);
			break;
		}
		confnr = (buffer[124] * 256) + buffer[123];
		if ((confnr >= configdata->Maxconferences) ||
				!(*(configdata->firstconference[confnr].n_ConfName)))
		{
			buffer[71+25-1] = '\0';
			msprintf (string,"Unknown conference for message \"%ls\"!",removespace(&buffer[71],25));
			putreg (REG_A6,exebase);
			ANSIwriteerroro (string,usea4a5);
			ret = 2;		/* non fatal error */
			break;
		}

		if (!(nodebase->CU.firstuserconf[confnr].uc_Access & ACCF_Write) ||
				!(nodebase->CU.firstuserconf[confnr].uc_Access & ACCF_Read)) {
			msprintf (string,"You are not allowed to write to conference %ls!",
					configdata->firstconference[confnr].n_ConfName);
			putreg (REG_A6,exebase);
			ANSIwriteerroro (string,usea4a5);
			ret = 2;		/* non fatal error */
			break;
		}

		msgstart = nodebase->tmpmsgmem;

/* Reference to... */
		putreg (REG_A6,exebase);
		strcopylen (&buffer[108],tmpbuf,6,usea4a5);
		tmpbuf[6] = '\0';
		ptr = &tmpbuf[0];
		while (*ptr == ' ')
			ptr += 1;

		replyto = atoi (ptr);
		if (replyto)
		{
			putreg (REG_A6,exebase);
			if (loadmsgheader (msgheader,replyto,confnr*2,usea4a5))
			{
				msprintf (string,"Message refered to (%ld) not found. Removing reply number...",replyto);
				putreg (REG_A6,exebase);
				ANSIwriteerroro (string,usea4a5);
//				ret = 2;		// non fatal error
				replyto = FALSE;
				goto safe;
//				break;
			}

			putreg (REG_A6,exebase);
			if (kanskrive (msgheader,confnr*2,usea4a5))
			{
				msprintf (string,"Message refered to (%ld) not available for reply!",replyto);
				putreg (REG_A6,exebase);
				ANSIwriteerroro (string,usea4a5);
				ret = 2;		/* non fatal error */
				break;
			}

/* Sjekker om det er svar til en net bruker
*/
			if (msgheader->NrLines < 0)
			{
				putreg (REG_A6,exebase);
				if (loadmsgtext (nodebase->tmpmsgmem,msgheader,confnr*2,usea4a5))
				{
					msprintf (string,"Message refered to (%ld) not found!",replyto);
					putreg (REG_A6,exebase);
					ANSIwriteerroro (string,usea4a5);
					ret = 2;		/* non fatal error */
					break;
				}

				ptr = nodebase->tmpmsgmem;
				if (*ptr == '\x1e') {
					*ptr = '\x1f';
					while (*(ptr++) != '\n') ;
					msgstart = ptr;
					netmsg = 1;
				}
			}
// Can't check if netusers are member of conference
			if (!netmsg)
			{
				putreg (REG_A6,exebase);
				tmp = checkmemberofconf (msgheader->MsgFrom,confnr*2,usea4a5);
				if (!tmp)
				{
					if (tmp > 0)
				 	{
						msprintf (string,"Author of message %ld is not a member of conference %ls!",
							replyto,configdata->firstconference[confnr].n_ConfName);
						putreg (REG_A6,exebase);
						ANSIwriteerroro (string,usea4a5);
					}
					else
					{
						msprintf (string,"Error checking author of message %ld in conference %ls!",
							replyto,configdata->firstconference[confnr].n_ConfName);
						putreg (REG_A6,exebase);
						ANSIwriteerroro (string,usea4a5);
					}
					ret = 2;		/* non fatal error */
					break;
				}
			}
			msgheader->RefTo	= msgheader->Number;
			msgheader->MsgTo	= msgheader->MsgFrom;
			msgheader->MsgFrom = nodebase->CU.Usernr;

			if (!(msgheader->Security & SECF_SecReceiver))
			{
				if (buffer[0] == '*' || buffer[0] == '+')
					msgheader->Security = SECF_SecReceiver;
				else
					msgheader->Security = SECF_SecNone;
			}
		}
		else
safe:
		{
			msgheader->RefTo = 0;
			msgheader->Security = SECF_SecNone;
		}

		msgheader->MsgStatus = MSTATF_NormalMsg;
		msgheader->RefBy = 0;
		msgheader->RefNxt = 0;
		msgheader->MsgBits = '\0';

		dt.mday	= (buffer[11]-'0') * 10 + (buffer[12]-'0');
		dt.month	= (buffer[8]-'0') * 10 + (buffer[9]-'0');
		dt.year	= (buffer[14]-'0') * 10 + (buffer[15]-'0');
		dt.year 	+= (dt.year >= 78 ? 1900 : 2000);
		if (buffer[16] == ' ')
			dt.hour	= (buffer[17]-'0');
		else
			dt.hour	= (buffer[16]-'0') * 10 + (buffer[17]-'0');

		if (buffer[19] == ' ')
			dt.min	= (buffer[20]-'0');
		else
			dt.min	= (buffer[19]-'0') * 10 + (buffer[20]-'0');

		dt.sec	= 0;

		tmp = CheckDate (&dt);
		if (!tmp) {
			putreg (REG_A6,exebase);
			buffer[71+25-1] = '\0';
			msprintf (string,"Illegal date for message \"%ls\"!",removespace(&buffer[71],25));
			putreg (REG_A6,exebase);
			ANSIwriteerroro (string,usea4a5);
			ret = 2;		/* non fatal error (?)*/
			break;
		}
		msgheader->MsgTimeStamp.ds_Days = tmp / (24*60*60);
		tmp -= msgheader->MsgTimeStamp.ds_Days * (24*60*60);
		msgheader->MsgTimeStamp.ds_Minute = tmp / 60;
		msgheader->MsgTimeStamp.ds_Tick = 0;

		DateStamp (&ds);
		putreg (REG_A6,exebase);
		if (msgheader->MsgTimeStamp.ds_Days != ds.ds_Days) {
			msgheader->MsgTimeStamp.ds_Days	 = ds.ds_Days;
			msgheader->MsgTimeStamp.ds_Minute = ds.ds_Minute;
			msgheader->MsgTimeStamp.ds_Tick	 = ds.ds_Tick;
		}

		strncpy (msgheader->Subject,removespace(&buffer[71],25),25);
		for (tmp = 25; tmp < Sizeof_NameT; tmp++)
			msgheader->Subject[tmp] = '\0';

		putreg (REG_A6,exebase);
		convertstringtoiso (msgheader->Subject,usea4a5);

		if (!(msgheader->RefTo)) {
			msgheader->MsgFrom = nodebase->CU.Usernr;

/*
Tillater ikke folk å jukse med avsender..
			memset (tmpbuf,'\0',31);
			strncpy (tmpbuf,removespace(&buffer[46],25),25);
			putreg (REG_A6,exebase);
			convertstringtoiso (tmpbuf,usea4a5);
			putreg (REG_A6,exebase);
			msgheader->MsgFrom = mygetusernumber (tmpbuf,usea4a5);
			if (checkformsgerror ())
			{
				putreg (REG_A6,exebase);
				msprintf (string,"Unknown author for message \"%ls\"!",msgheader->Subject);
				putreg (REG_A6,exebase);
				ANSIwriteerroro (string,usea4a5);
				break;
			}
*/
			memset (tmpbuf,'\0',31);
			strncpy (tmpbuf,removespace(&buffer[21],25),25);
			putreg (REG_A6,exebase);
			convertstringtoiso (tmpbuf,usea4a5);

			if (strchr (tmpbuf,'@'))
			{
				if (!(configdata->firstconference[confnr].n_ConfSW & CONFSWF_Network))
				{
					msprintf (string,"No net addresses allowed in conference %ls!",
							configdata->firstconference[confnr].n_ConfName);
					putreg (REG_A6,exebase);
					ANSIwriteerroro (string,usea4a5);
					ret = 2;		/* non fatal error */
					break;
				}
				netmsg = 1;
				msprintf (msgstart,"\x1f%ls\n\0",tmpbuf);
				msgstart += strlen (msgstart);
				msgheader->MsgTo = configdata->SYSOPUsernr;
			}
			else
			{
				putreg (REG_A6,exebase);
				msgheader->MsgTo = mygetusernumber (tmpbuf,usea4a5);
				if (checkformsgerror ())
				{
					msprintf (string,"Unknown recipiant for message \"%ls\"!",msgheader->Subject);
					putreg (REG_A6,exebase);
					ANSIwriteerroro (string,usea4a5);
					ret = 2;		/* non fatal error */
					break;
				}
				putreg (REG_A6,exebase);
				tmp = checkmemberofconf (msgheader->MsgTo,confnr*2,usea4a5);
				if (!tmp)
				{
					if (tmp > 0)
					{
						msprintf (string,"Receiver of message %ls is not a member of conference %ls!",
							msgheader->Subject,configdata->firstconference[confnr].n_ConfName);
						putreg (REG_A6,exebase);
						ANSIwriteerroro (string,usea4a5);
					}
					else
					{
						msprintf (string,"Error checking receiver of message %ls in conference %ls!",
							msgheader->Subject,configdata->firstconference[confnr].n_ConfName);
						putreg (REG_A6,exebase);
						ANSIwriteerroro (string,usea4a5);
					}

					ret = 2;		/* non fatal error */
					break;
				}
			}
		}

		if (configdata->firstconference[confnr].n_ConfSW & CONFSWF_PostBox)
		{
			if (msgheader->MsgTo == -1)	// ALL 
			{
				msprintf (string,"No public messages in Post conference %ls (%ls)!",
						configdata->firstconference[confnr].n_ConfName,
						msgheader->Subject);
				putreg (REG_A6,exebase);
				ANSIwriteerroro (string,usea4a5);
				ret = 2;		/* non fatal error */
				break;
			}
			else
				msgheader->Security = SECF_SecReceiver;		/* Tvinger privat melding i post'er */
		}

		putreg (REG_A6,exebase);
		strcopylen (&buffer[116],tmpbuf,6,usea4a5);
		tmpbuf[6] = '\0';
		ptr = &tmpbuf[0];
		while (*ptr == ' ')
			ptr += 1;

		numblocks = atoi (ptr)-1;
		if (numblocks < 1)
		{
			msprintf (string,"To few msg text blocks for message %ls!",msgheader->Subject);
			putreg (REG_A6,exebase);
			ANSIwriteerroro (string,usea4a5);
			break;	/* Fatale error */
		}

		ptr = msgstart;
		for (tmp = 0 ; numblocks; numblocks--)
		{
			if (nodebase->msgmemsize < ((tmp+1) * 128))
			{
				Seek (msgfil,128,OFFSET_CURRENT);
				if (IoErr())
				{
					putreg (REG_A6,exebase);
					msprintf (string,"File error in message %ls!", msgheader->Subject);
					putreg (REG_A6,exebase);
					ANSIwriteerroro (string,usea4a5);
					dobreak = 1;
					break;
				}
			}
			else if (128 != Read (msgfil,ptr + (tmp*128),128))
			{
				putreg (REG_A6,exebase);
				msprintf (string,"File error in message %ls!",msgheader->Subject);
				putreg (REG_A6,exebase);
				ANSIwriteerroro (string,usea4a5);
				dobreak = 1;
				break;
			}
			tmp += 1;
		}
		putreg (REG_A6,exebase);
		havreadmsg = 1;

		if (dobreak)
			break;

		*(ptr + (tmp*128)) = 0;
		removespace(ptr + ((tmp-1)*128),128);

		msgheader->NrLines = 1;
		tmp = 0;
		for (ptr = msgstart; *ptr; ptr++)
		{
			if (*ptr == 227)
			{
				if (*(ptr+1))
				{
					*ptr = '\n';
					tmp = 0;
					msgheader->NrLines += 1;
				}
				else
				{
					*ptr = 0;
					break;
				}
			}
			else
			{
				tmp += 1;
				if (tmp > 79)
				{
					*ptr = '\n';
					tmp = 0;
					msgheader->NrLines += 1;
				}
				else if (*ptr > 127)
				{
					putreg (REG_A6,exebase);
					*ptr = convertchartoiso (*ptr,usea4a5);
				}
				else if (*ptr < 32)
					*ptr = ' ';
			}
		}
		while (*(ptr-1) == '\n')
		{
			ptr -= 1;
			*ptr = 0;
			msgheader->NrLines -= 1;
		}
		msgheader->NrBytes = (ULONG) ((ULONG) ptr - (ULONG) nodebase->tmpmsgmem);

		if (!msgheader->NrBytes)
		{
			msprintf (string,"Empty message : %ls!",msgheader->Subject);
			putreg (REG_A6,exebase);
			ANSIwriteerroro (string,usea4a5);
			ret = 2;
			break;	/* Non Fatale error */
		}

		if (netmsg)
			msgheader->NrLines = -msgheader->NrLines;

		putreg (REG_A6,exebase);
		if (savemsg (nodebase->tmpmsgmem,msgheader,confnr*2,usea4a5))
		{
			msprintf (string,"Error saving message %ls!",msgheader->Subject);
			putreg (REG_A6,exebase);
			ANSIwriteerroro (string,usea4a5);
			break;	/* Fatale */
		}

		tmp = msgheader->MsgTo; /* Husker hvem den var til */
		msgnr = msgheader->Number;
		putreg (REG_A6,exebase);
		stopreviewmessages (msgnr,usea4a5);
		nodebase->CU.MsgsLeft += 1;
		putreg (REG_A6,exebase);
		sendintermsgmsg (msgheader,nodebase->tmpmsgmem,confnr*2,usea4a5);
		putreg (REG_A6,exebase);
		killrepwritelog ((replyto ? logreplymsgtext : logentermsgtext),confnr*2,msgnr,usea4a5);

		while (replyto)
		{
			putreg (REG_A6,exebase);
			if (!(loadmsgheader (msgheader,replyto,confnr*2,usea4a5)))
			{
				if (!(msgheader->RefBy))
				{
					msgheader->RefBy = msgnr;
					putreg (REG_A6,exebase);
					if (savemsgheader (msgheader,confnr*2,usea4a5))
					{
						msprintf (string,"Error updating reply message (%sd:%ld)!", replyto,msgheader->Subject);
						putreg (REG_A6,exebase);
						ANSIwriteerroro (string,usea4a5);
					}
					break;
				}
				msgheader->RefNxt = msgheader->RefBy;

				while (msgheader->RefNxt)
				{
					putreg (REG_A6,exebase);
					if (loadmsgheader (msgheader,msgheader->RefNxt,confnr*2,usea4a5))
					{
						msprintf (string,"Error scanning reply message chain (from %sd:%ld)!",msgheader->RefNxt,msgheader->Subject);
						putreg (REG_A6,exebase);
						ANSIwriteerroro (string,usea4a5);
						dobreak = 1;
						break;
					}
				}
				if (dobreak)
					break;

				msgheader->RefNxt = msgnr;
				putreg (REG_A6,exebase);
				if (savemsgheader (msgheader,confnr*2,usea4a5))
				{
					msprintf (string,"Error updating last reply message (%sd:%ld)!",msgheader->Number,msgheader->Subject);
					putreg (REG_A6,exebase);
					ANSIwriteerroro (string,usea4a5);
					dobreak = 1;
					break;
				}
			}
			else
			{
				msprintf (string,"Error reading reply message (%sd:%ld)!",replyto,msgheader->Subject);
				putreg (REG_A6,exebase);
				ANSIwriteerroro (string,usea4a5);
				dobreak = 1;
				ret = 2;		/* non fatal error */
			}

			break;
		}
		if (dobreak)
			break;

		if (netmsg)
		{
			ptr = nodebase->tmpmsgmem; ptr += 1;
			while (*(ptr++) != '\n') ;
			*(--ptr) = '\0';
			ptr = nodebase->tmpmsgmem; ptr += 1;
		}
		else
		{
			putreg (REG_A6,exebase);
			getusername (tmp,usea4a5);
			ptr = (UBYTE *) getreg (REG_A0);
		}
		strncpy (tmpbuf,removespace(&buffer[71],19),19);
		tmpbuf[19] = '\0';
		strncpy (tmpbuf2,configdata->firstconference[confnr].n_ConfName,18);
		tmpbuf2[18] = '\0';
		if (replyto)
			msprintf (tmpbuf3,"%ld",replyto);
		else
			strcpy (tmpbuf3,"None ");

		msprintf (string,"[32m%6ld %6ls [33m%-18s [0m%-25ls [35m%ls[32m",msgnr,tmpbuf3,tmpbuf2,ptr,tmpbuf);
		putreg (REG_A6,exebase);
		writetexto (string,usea4a5);
		ret = 0;
		break;
	}

	if (ret == 2 && !havreadmsg)
	{
		while (1)
		{
			putreg (REG_A6,exebase);
			strcopylen (&buffer[116],tmpbuf,6,usea4a5);
			tmpbuf[6] = '\0';
			ptr = &tmpbuf[0];
			while (*ptr == ' ')
				ptr += 1;

			numblocks = atoi (ptr)-1;
			if (numblocks < 1)
			{
				buffer[71+25-1] = '\0';
				msprintf (string,"To few msg text blocks in \"%ls\"!",removespace(&buffer[71],25));
				putreg (REG_A6,exebase);
				ANSIwriteerroro (string,usea4a5);
				ret = -1;	/* Fatale error */
				break;
			}

			ptr = nodebase->tmpmsgmem;
			for ( ; numblocks; numblocks--)
			{
				if (128 != Read (msgfil,ptr,128))
				{
//					putreg (REG_A6,exebase);
					buffer[71+25-1] = '\0';
					msprintf (string,"File Error while reading message \"%ls\"!",removespace(&buffer[71],25));
					putreg (REG_A6,exebase);
					ANSIwriteerroro (string,usea4a5);
					ret = -1;	/* Fatale error */
					break;
				}
			}
			break;
		}
	}
	putreg (REG_A6,exebase);
	return (ret);
}

char *removespace(char *string,int maxlength)
{
	char *ptr;

	ptr = string + maxlength-2;
	if (*ptr != ' ')
		return (string);

	while (*(ptr--) == ' ')
		;

	*(ptr+2) = 0;
	return (string);
}

__asm int packmessages (a4a5)
{
	BPTR	msgfil;
	char	tmpstring[40];
	int	conf;
	int	message,msgpacked,touser,tousertot,totbul = 0;
	int	dobreak,highmsg;
	int	ret = 1;
	int	msgnr = 1,tmp;
	int	startconf;
	char	string[80];
	struct ConfigRecord *configdata = &mainmeory->config;
	char Scan_text[4][2] = { "|", "/", "-", "\\" };
	UBYTE scan_count, next_count;
	BOOL first_scan;
	int tmplines;

	putreg (REG_A6,exebase);
	writecontext (CursorOffData,usea4a5);

	if (nodebase->CU.ScratchFormat == 0)
	{
		putreg (REG_A6,exebase);
		ANSIwriteerroro ("QWK cannot be used with Archiveformat TEXT!",usea4a5);
		return (-1);
	}

	tmplines = nodebase->linesleft;
	nodebase->linesleft = 65535;

	putreg (REG_A6,exebase);
	writetexto ("[32m\n***************************** Making QWK Packet *****************************\n",usea4a5);
	putreg (REG_A6,exebase);
	writetexto ("[36mConference                     High #  Total   For You", usea4a5);
	putreg (REG_A6,exebase);
	writetexto ("------------------------------ ------- ------- -------", usea4a5);

	while (1)
	{
		msprintf (tmpstring,"%ls/messages.dat",nodebase->Nodemem.TmpPath);
		if (!(msgfil = Open(tmpstring,MODE_NEWFILE)))
		{
			putreg (REG_A6,exebase);
			ANSIwriteerroro ("Error opening msg file!",usea4a5);
			break;
		}
		putreg (REG_A6,exebase);
		if (initdatafile (msgfil,usea4a5))
			break;

		startconf = nodebase->confnr/2;
		dobreak = 0;
		msgpacked = 0;
		touser = 0;

		scan_count = 0;
		next_count = 1;
		first_scan = FALSE;
		putreg (REG_A6,exebase);
		writetexti ("[31m", usea4a5);
		putreg (REG_A6,exebase);
		while ((message = gettopqueue(usea4a5)) && !dobreak)
		{
			if (nodebase->CU.Userbits & USERF_ANSIMenus)
			{
				if (next_count == 1)
				{
					next_count = 1;
					if (first_scan)		// Har vi printet ut noe?
					{
						putreg (REG_A6,exebase);
						writetexti ("[D",usea4a5);		// JA ... til venstre
					}
					else
						first_scan = TRUE;
					putreg (REG_A6,exebase);
					writetexti (Scan_text[scan_count],usea4a5);
					if (scan_count == 3)
						scan_count = 0;
					else
						scan_count++;
				}
				else
					next_count++;
			}

			putreg (REG_A6,exebase);
			if (dograbmsg (message,startconf,msgfil,usea4a5,&msgnr,&touser,&msgpacked))
			{
				dobreak = 1;
				break;
			}
			putreg (REG_A6,exebase);
			removefromqueue (message,usea4a5);
		}
		if (dobreak)
			break;
		putreg (REG_A6,exebase);
		unjoin(usea4a5);

		if (first_scan)		// Har vi printet ut noe?
		{
			putreg (REG_A6,exebase);
			writetexti ("[D",usea4a5);		// JA ... til venstre
		}

		if (msgpacked)
		{
			msprintf (string,"[33m%-30ls [32m%7ld %7ld %7ld",
					configdata->firstconference[startconf].n_ConfName,
					configdata->firstconference[startconf].n_ConfDefaultMsg,
					msgpacked,touser);
			putreg (REG_A6,exebase);
			writetexto (string,usea4a5);
		}
		tousertot = touser;
		
		if (nodebase->CU.Userbits & USERF_SendBulletins)
		{
			putreg (REG_A6,exebase);
			totbul = checkupdatedbulletins (startconf,-1L,usea4a5);
		}

		conf = startconf;
		do
		{
			putreg (REG_A6,exebase);
			conf = getnextconfnr (conf*2, usea4a5) / 2;
			if (conf >= configdata->Maxconferences)
				conf = 0;
			tmp = 0;

			if (!*(configdata->firstconference[conf].n_ConfName))
				continue;

			if (!(nodebase->CU.firstuserconf[conf].uc_Access & ACCF_Read))
				continue;

			if ((nodebase->CU.Userbits & USERF_SendBulletins) && (startconf != conf))
			{
				putreg (REG_A6,exebase);
				totbul += checkupdatedbulletins (conf,-1L,usea4a5);
			}

			msgpacked = 0;
			touser = 0;

			highmsg = configdata->firstconference[conf].n_ConfDefaultMsg;

			message = nodebase->CU.firstuserconf[conf].uc_LastRead+1;

/* Sjekker om vi skal bruke max scan */
			if (message == 1) {
				if ((highmsg - message) > configdata->firstconference[conf].n_ConfMaxScan)
					message = highmsg - configdata->firstconference[conf].n_ConfMaxScan;
			}

			scan_count = 0;
			next_count = 1;
			first_scan = FALSE;
			putreg (REG_A6,exebase);
			writetexti ("[31m", usea4a5);
			for (; message <= highmsg; message++)
			{
				if (!message)
					continue;

				if (next_count == 1)
				{
					next_count = 1;
					if (first_scan)		// Har vi printet ut noe?
					{
						putreg (REG_A6,exebase);
						writetexti ("[D",usea4a5);		// JA ... til venstre
					}
					else
						first_scan = TRUE;
					putreg (REG_A6,exebase);
					writetexti (Scan_text[scan_count],usea4a5);
					if (scan_count == 3)
						scan_count = 0;
					else
						scan_count++;
				}
				else
					next_count++;

				tmp = 1;
				putreg (REG_A6,exebase);
				if (dograbmsg (message,conf,msgfil,usea4a5,&msgnr,&touser,&msgpacked))
				{
					dobreak = 1;
					break;
				}
			}
			if (first_scan)		// Har vi printet ut noe?
			{
				putreg (REG_A6,exebase);
				writetexti ("[D",usea4a5);		// JA ... til venstre
			}


/* Mark read
*/
			if (!dobreak && tmp)
			{
				nodebase->CU.firstuserconf[conf].uc_LastRead = highmsg;
				msprintf (string,"[33m%-30ls [32m%7ld %7ld %7ld",
						configdata->firstconference[conf].n_ConfName,
						configdata->firstconference[conf].n_ConfDefaultMsg,
						msgpacked,touser);
				putreg (REG_A6,exebase);
				writetexto (string,usea4a5);
				tousertot += touser;
			}

		} while (!dobreak && (conf != startconf));

		if (dobreak)
			break;

		putreg (REG_A6,exebase);
		writetexto ("[36m------------------------------ ------- ------- -------", usea4a5);
		msprintf (string,"\n36mNumber of messages:  %7ld", msgnr-1);
		putreg (REG_A6,exebase);
		writetexto (string,usea4a5);

		msprintf (string,"Messages to you:     %7ld", tousertot);
		putreg (REG_A6,exebase);
		writetexto (string,usea4a5);

		if (nodebase->CU.Userbits & USERF_SendBulletins)
		{
			msprintf (string,"Number of bulletins: %7ld", totbul);
			putreg (REG_A6,exebase);
			writetexto (string,usea4a5);
		}

		putreg (REG_A6,exebase);
		writetexto ("\n32mMaking control-files...",usea4a5);

		putreg (REG_A6,exebase);
		if (doctrldatfile(msgnr-1,usea4a5))
			break;

		putreg (REG_A6,exebase);
		writetexto ("\nPacking...[0m",usea4a5);

		ret = 0;
		break;
	}

	if (msgfil)
		Close (msgfil);

	if (ret)
		DeleteFile (tmpstring);

	putreg (REG_A6,exebase);
	writecontext (CursorOnData,usea4a5);

	nodebase->linesleft = tmplines;

	putreg (REG_A6,exebase);
	return (ret ? -1L : (msgnr-1));
}

__asm int doctrldatfile(register __d0 int msgnr,a4a5)
{
	BPTR	ctrlfil;
	int ret = 1,n,k;
	char	buffer[256];
	struct ClockData dt;
	struct DateStamp ds;
	struct ConfigRecord *configdata = &mainmeory->config;
	char	*ptr,*ptr2,c;

	while (1) {
		msprintf (buffer,"%ls/CONTROL.DAT",nodebase->Nodemem.TmpPath);
		ctrlfil = Open(buffer,MODE_NEWFILE);
		putreg (REG_A6,exebase);
		if (!ctrlfil)
			break;

		msprintf (buffer,"%ls\r\n%ls\r\n%ls\r\n%ls\r\n%ld,%ls\r\n",
			configdata->BaseName,NULL,NULL,configdata->SYSOPname,0,configdata->BaseName);
		if (FPuts (ctrlfil,buffer))
			break;

		DateStamp (&ds);
		n = ds.ds_Days*24*60*60;
		n += ds.ds_Minute*60;
		n += ds.ds_Tick/TICKS_PER_SECOND;
		Amiga2Date (n,&dt);

		msprintf (buffer,"%02ld-%02ld-%04ld,%02ld:%02ld:%02ld\r\n",
			dt.month,dt.mday,dt.year,dt.hour,dt.min,dt.sec);
		if (FPuts (ctrlfil,buffer))
			break;

		for (ptr = buffer,ptr2 = nodebase->CU.Name; *ptr2; ) {
			c = *(ptr2++);
			*(ptr++) = toupper(c);
		}
		*(ptr++) = '\r';
		*(ptr++) = '\n';
		*ptr = '\0';
		if (FPuts (ctrlfil,buffer))
			break;

		for (n = 0,k = 0; n < configdata->Maxconferences; n++)
			if (nodebase->CU.firstuserconf[n].uc_Access & ACCF_Read)
				k += 1;

		msprintf (buffer,"\r\n0\r\n%ld\r\n%ld\r\n",msgnr,k-1);
		if (FPuts (ctrlfil,buffer))
			break;

		for (n = 0; n < configdata->Maxconferences; n++)
		{
			if (nodebase->CU.firstuserconf[n].uc_Access & ACCF_Read)
			{
				msprintf (buffer,"%ld\r\n%ls\r\n",n,
					configdata->firstconference[n].n_ConfName);
				putreg (REG_A6,exebase);
				convertstringfromiso (buffer,usea4a5);
				if (FPuts (ctrlfil,buffer))
					break;
			}
		}

		if (n != configdata->Maxconferences)
			break;

		if (FPuts (ctrlfil,"\r\n\r\n\r\n"))
			break;

		ret = 0;
		break;
	}

	if (ctrlfil)
		Close (ctrlfil);
	else
	{
		putreg (REG_A6,exebase);
		ANSIwriteerroro ("Error opening control.dat file!",usea4a5);
	}

	if (ret) {
		msprintf (buffer,"%ls/CONTROL.DAT",nodebase->Nodemem.TmpPath);
		DeleteFile (buffer);
	}

	putreg (REG_A6,exebase);
	return (ret);
}			

__asm int initdatafile (register __d0 BPTR msgfil,a4a5)
{
	char	string[128+2];

	msprintf (string,"%-128ls","Produced by ABBS-QWK, (C) 1993 Geir Inge Høsteng.");
	if (128 != Write (msgfil,string,128))
	{
		putreg (REG_A6,exebase);
		ANSIwriteerroro ("File error!",usea4a5);
		return (1);
	}
	putreg (REG_A6,exebase);

	return (0);
}

__asm int dograbmsg (register __d0 int nr, register __d1 int conf,register __d2 BPTR msgfil,a4a5,
				register __d3 int *msgnr,register __d4 int *touser,register __d5 int *numgrabbed)
{
	struct ClockData dt;
	ULONG	secs;
	char	c;
	UBYTE	*ptr,*ptr2;
	int	msgsize;
	char	string[128+2];
	char	refnr[9];
	char	from[26],to[26];
	struct	MessageRecord *msgheader;
	struct ConfigRecord *configdata = &mainmeory->config;

	msgheader = &nodebase->tmpmsgheader;

	putreg (REG_A6,exebase);
	if (loadmsg (nodebase->tmpmsgmem,msgheader,nr,conf*2,usea4a5))
	{
		msprintf (string,"Error loading message (%ls:%ld)!",
		configdata->firstconference[conf].n_ConfName,nr);
		putreg (REG_A6,exebase);
		ANSIwriteerroro (string,usea4a5);
		return (1);
	}

	putreg (REG_A6,exebase);
	if (kanskrive (msgheader,conf*2,usea4a5))
		return (0);

	if (msgheader->MsgStatus & MSTATF_MsgRead)
	{
		if (msgheader->Security & SECF_SecReceiver)
			c = '+';
		else
			c = '-';
	}
	else
	{
		if (msgheader->Security & SECF_SecReceiver)
			c = '*';
		else
			c = ' ';
	}

// JEO her må en sjekke om det er en konfmessy...

	if (nodebase->CU.Usernr == msgheader->MsgTo)
	{
		*touser += 1;
		putreg (REG_A6,exebase);
		if (!(msgheader->MsgStatus & MSTATF_MsgRead),usea4a5)
		{
			msgheader->MsgStatus |= MSTATF_MsgRead;
			putreg (REG_A6,exebase);
			savemsgheader (msgheader,conf*2,usea4a5);
		}
	}

	nodebase->CU.MsgaGrab += 1;
	nodebase->tmsgsdumped += 1;

	putreg (REG_A6,exebase);
	getfromname (msgheader,nodebase->tmpmsgmem,usea4a5);
	ptr = (UBYTE *) getreg (REG_A0);
	putreg (REG_A6,exebase);
	strcopylen ((char *) ptr,from,25,usea4a5);
	putreg (REG_A6,exebase);
	convertstringfromiso (from,usea4a5);

	putreg (REG_A6,exebase);
	gettoname (msgheader,nodebase->tmpmsgmem,usea4a5);
	ptr = (UBYTE *) getreg (REG_A0);
	putreg (REG_A6,exebase);
	strcopylen ((char *) ptr,to,25,usea4a5);
	putreg (REG_A6,exebase);
	convertstringfromiso (to,usea4a5);

	if ((msgheader->NrLines < 0) && (!msgheader->Subject[0]))
	{
		if (getnetsubject(nodebase->tmpmsgmem))
		{
			ptr = (UBYTE *) getreg (REG_A0);
			putreg (REG_A6,exebase);
			strcopylen ((char *) ptr,msgheader->Subject,25,usea4a5);
		}
		else
		{
			putreg (REG_A6,exebase);
			strcopylen ("No Subject",msgheader->Subject,25,usea4a5);
		}
	}

	msgheader->Subject[25] = '\0';
	putreg (REG_A6,exebase);
	convertstringfromiso ((unsigned char *) msgheader->Subject,usea4a5);

	if (msgheader->RefTo)
		msprintf (refnr,"%-8ld",msgheader->RefTo);
	else
		strcpy (refnr,"        ");

	secs = msgheader->MsgTimeStamp.ds_Days*24*60*60;
	secs += msgheader->MsgTimeStamp.ds_Minute*60;
	secs += msgheader->MsgTimeStamp.ds_Tick/TICKS_PER_SECOND;
	Amiga2Date (secs,&dt);

	putreg (REG_A6,exebase);
	msgsize = skipnetnames (nodebase->tmpmsgmem,msgheader->NrBytes,usea4a5);
	ptr2 = (UBYTE *) getreg (REG_A0);

	to[25] = '\0';
	from[25] = '\0';
	msgheader->Subject[25] = '\0';
	msprintf  (string,"%lc%-7ld%02ld-%02ld-%02ld%02ld:%02ld%-25ls%-25ls%-25ls%-12ls%8ls%-6ld%lc%lc%lc%lc%lc ",
		c,msgheader->Number,dt.month,dt.mday,dt.year % 100,dt.hour,dt.min,
		to,from,msgheader->Subject,"",refnr,((msgsize+128)/128)+1,225,conf%256,
		conf/256,*msgnr%256,*msgnr/256);
	*msgnr += 1;

	if (128 != Write (msgfil,string,128))
	{
		putreg (REG_A6,exebase);
		ANSIwriteerroro ("File error!",usea4a5);
		return (4);
	}
	putreg (REG_A6,exebase);

/* Convert linefeed into ASCII 227 (pi character in IBM), and Translates the rest of the message into
	IBN
*/
	for (ptr = ptr2; *ptr; ptr++)
	{
		if (*ptr == '\n')
			*ptr = 227;
		else if (*ptr > 127)
		{
			putreg (REG_A6,exebase);
			*ptr = convertcharfromiso (*ptr,usea4a5);
		}
	}

/* Write the message
*/
	if (msgsize != Write (msgfil,ptr2,msgsize))
	{
		putreg (REG_A6,exebase);
		ANSIwriteerroro ("File error!",usea4a5);
		return (5);
	}
	putreg (REG_A6,exebase);

/* Pads message with null bytes
*/
	secs = 128 - (msgsize % 128);
	if (secs) {
		memset (string,'\0',secs);
		if (secs != Write (msgfil,string,secs))
		{
			putreg (REG_A6,exebase);
			ANSIwriteerroro ("File error!",usea4a5);
			return (6);
		}
	}
	putreg (REG_A6,exebase);

	*numgrabbed += 1;

	return (0);
}

__asm ULONG	copybulletin (register __a0 char *fromname,
									register __a1 char *toname,a4a5)
{
	int	n,k;
	BPTR	from,to;
	char	string[100];
	ULONG	ret = 10;

	if (from = Open(fromname,MODE_OLDFILE))
	{
		if (to = Open(toname,MODE_NEWFILE))
		{
			while (TRUE)
			{
				n =  Read (from,string,sizeof (string)-1);
				if (n > 0) {
					for (k = 0; k < n; k++)
					{
						putreg (REG_A6,exebase);
						string[k] = convertcharfromiso(string[k],usea4a5);
					}
					k = Write (to,string,n);
					if (k != n)
					{
						putreg (REG_A6,exebase);
						ANSIwriteerroro ("File write error!",usea4a5);
						break;
					}
				}
				else if (n != 0)
				{
					putreg (REG_A6,exebase);
					ANSIwriteerroro ("File write error!",usea4a5);
					break;
				}
				else
				{
					ret = 0;
					break;
				}
			}
			Close (to);
		}
		else
		{
			putreg (REG_A6,exebase);
			ANSIwriteerroro ("Error opening destination file!",usea4a5);
		}
		Close (from);
	}
	else
	{
		putreg (REG_A6,exebase);
		ANSIwriteerroro ("Error opening source file!",usea4a5);
	}

	return (ret);
}

__asm ULONG	mygetusernumber (register __a2 char *name,a4a5)
{
	struct ConfigRecord *configdata = &mainmeory->config;

	clearmsgerror();

	if (!mystricmp (name,"ALL"))
		return (-1);

	if (!mystricmp (name,"SYSOP"))
		return (configdata->SYSOPUsernr);

	putreg (REG_A6,exebase);
	return (getusernumber (name,usea4a5));
}

__asm void	convertstringfromiso (register __a0 unsigned char *string,a4a5)
{
	register unsigned char c;

	while (c = *(string++)) {
		if (c > 127) {
			c = fraISOtilIBN[c-128];
			if (!c)
				c = ' ';

			*(string-1) = c;
		}		
	}
}

__asm void	convertstringtoiso (register __a0 unsigned char *string,a4a5)
{
	register unsigned char c;

	while (c = *(string++)) {
		if (c > 127) {
			c = fraIBNtilISO[c-128];
			if (!c)
				c = ' ';

			*(string-1) = c;
		}		
	}
}

__asm unsigned char	convertchartoiso (register __d0 unsigned char c,a4a5)
{
	if (c > 127) {
		c = fraIBNtilISO[c-128];
		if (!c)
			c = ' ';
	}

	return (c);
}

__asm unsigned char	convertcharfromiso (register __d0 unsigned char c,a4a5)
{
	if (c > 127) {
		c = fraISOtilIBN[c-128];
		if (!c)
			c = ' ';
	}

	return (c);
}

/*
{
	int	n;

/ *	ingen oversetting hvis det er ISO
* /
	if (NodeBase->Charset) {
		if ((NodeBase->Charset < 3) || (NodeBase->Charset == 12)) {
			if (NodeBase->Charset == 12)
				n = 3;
			else
				n = NodeBase->Charset;

			if (c > 127) {
				c = convertISOtoxxx[n][c-128];
				if (!c)
					c = ' ';
			}
		} else {
		}
	}

	return (c);
*/

int mystricmp (char *ptr, char *ptr2)
{
	while (*ptr) {
		if ((toupper (*ptr)) != (toupper (*ptr2)))
			return (-1);
		else {
			ptr += 1;
			ptr2 += 1;
		}
	}

	if (*ptr2 && *ptr2 != ' ')
		return (-1);
	else
		return (0);
}

int strincmp (char *ptr, char *ptr2,int len)
{
	while (len--) {
		if ((toupper (*ptr)) != (toupper (*ptr2)))
			return (-1);
	}

	return (0);
}

__asm void getbiggestdisk (void)
{
	struct DosList *dl;
	struct DosEnvec *env;
	struct FileSysStartupMsg *msg;
	ULONG	size;

	putreg (REG_A6,(long) DOSBase);

	dl = LockDosList(LDF_DEVICES|LDF_READ);

	dl = FindDosEntry(dl,NULL,LDF_DEVICES|LDF_READ);

	while (dl) {
		if (dl->dol_Type == DLT_DEVICE) {

			msg = BADDR ((struct FileSysStartupMsg *) dl->dol_misc.dol_handler.dol_Startup);

			if (((ULONG) msg) > 0x1000) {
				env = BADDR (msg->fssm_Environ);

				if (env) {
					size = ((env->de_HighCyl - env->de_LowCyl +1) * env->de_BlocksPerTrack *
										 env->de_Surfaces - (env->de_PreAlloc + env->de_Reserved));

					size = size/(1024*2);

					if (size && size > 2) {
						getbiggestdisksub ((APTR) (((ULONG) (BADDR(msg->fssm_Device)))+1),msg->fssm_Unit);
						putreg (REG_A6,(long) DOSBase);
					}
				}
			}
		}
		dl = NextDosEntry (dl,LDF_DEVICES|LDF_READ);
	}

	UnLockDosList(LDF_DEVICES|LDF_READ);

	putreg (REG_A6,exebase);
}

__asm	void getbiggestdisksub (register __a0 char *name,register __d0 ULONG num)
{
	static char lastname[60];
	static ULONG lastnum = -1;
	struct MsgPort *MP;
	struct IOStdReq *IO;
	ULONG	offset;
	int	size,n;
	void *buffer;

	putreg (REG_A6,exebase);

	if (!(strcmp (lastname,name))	)
		if (num == lastnum)
			return;

	lastnum = num;
	strncpy (lastname,name,58);

	if (MP = CreatePort (NULL,NULL)) {
		if (IO = (struct IOStdReq *) CreateExtIO (MP,sizeof (struct IOStdReq))) {
			if (!OpenDevice (name,num,(struct IORequest *) IO,0L)) {
				for (size = 1024*1024; size > 0; ) {
					if (buffer = AllocMem (size,0))
						break;
					size -= 1024;
				}
				if (!buffer) {
					return;
				}

				offset = 0;
				while (TRUE) {
					IO->io_Command	= CMD_READ; /* CMD_WRITE */
					IO->io_Flags	= 0;
					IO->io_Length	= size;
					IO->io_Data		= buffer;
					IO->io_Offset	= offset/512;

					if (IO->io_Error)
						n = IO->io_Error;

					offset += size;

					if (n)
						break;
				}

				FreeMem (buffer,size);
				if (!(CheckIO ((struct IORequest *) IO)))
					AbortIO ((struct IORequest *) IO);
				WaitIO ((struct IORequest *) IO);
				CloseDevice ((struct IORequest *) IO);
			}
			DeleteIORequest((struct IORequest *) IO);
		}
		DeleteMsgPort(MP);
	}
}

__asm far VOID ANSIwriteerroro (register __a0 char *text,a4a5)
{
	char Ansi[100];

	msprintf (Ansi, "[31m%s", text);
	writeerroro (Ansi, usea4a5);
}

/*
Sort			[30m
Rød				[31m
Grønn			[32m
Gul				[33m
Mørkeblå	[34m
Lilla			[35m
Lyseblå		[36m
white			[37m
*/
