 /****************************************************************
 *
 * NAME
 *		Hippo.c
 *
 * DESCRIPTION
 *		Hippo routines for abbs
 *
 * AUTHOR
 *	Geir Inge Høsteng
 *
 * $Id$
 *
 * MODIFICATION HISTORY
 * $Log$
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

#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/utility.h>

#include <string.h>
#include <ctype.h>
#include <dos.h>

#define	a4a5 register __a4 struct ramblocks *nodebase,register __a5 struct Mainmemory *mainmeory
#define	usea4a5	nodebase,mainmeory

__asm int hippopackmessages(a4a5);
__asm int hippounpackmessages (a4a5);
__asm int dohippograbmsg (register __d0 int nr, register __d1 int conf,register __d2 BPTR msgfil,a4a5,
				register __d3 int *msgnr,register __d4 int *touser,register __d5 int *numgrabbed);
__asm int hippounpackmsg (register __d0 BPTR msgfil,a4a5);

extern far ULONG exebase;
extern far struct DosLibrary *DOSBase;
extern far struct Library *UtilityBase;
extern far char	logentermsgtext[];
extern far char	logreplymsgtext[];
extern far UBYTE	fraISOtilIBN[128];
extern far UBYTE	fraIBNtilISO[128];

extern far int msprintf(char *, const char *, ...);
extern __asm far writetexto (register __a0 char *text,a4a5);
extern __asm far writeerroro (register __a0 char *text,a4a5);
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
extern __asm int kanskrive (register __a0 struct MessageRecord *msgheader,
				register __d0 UWORD confnr,a4a5);
extern __asm int getfromname (register __a0 struct MessageRecord *msgheader,
				register __a1 UBYTE *msgtext,a4a5);
extern __asm int gettoname (register __a0 struct MessageRecord *msgheader,
				register __a1 UBYTE *msgtext,a4a5);
extern __asm int skipnetnames (register __a0 UBYTE *msgtext,register __d0 int msgsize,a4a5);

extern __asm far void removefromqueue (register __d0 ULONG msgnr,a4a5);
extern __asm far ULONG	gettopqueue (a4a5);
extern __asm far void unjoin (a4a5);
extern __asm short getnextconfnr (register __d0 short conf,a4a5);

__asm int hippounpackmessages (a4a5)
{
	return (0);
}

/* returns -1 for fatal errors, 1 for endoffile, 2 for non-fatal error (msg skipped)
	and 0 for all ok (1 message parsed)
*/
__asm int hippounpackmsg (register __d0 BPTR msgfil,a4a5)
{
	return (0);
}

__asm int hippopackmessages(a4a5)
{
	BPTR	msgfil;
	char	tmpstring[40];
	int	conf;
	int	message,msgpacked,touser,tousertot;
	int	dobreak,highmsg;
	int	ret = 1;
	int	msgnr = 1,tmp;
	int	startconf;
	char	string[80];
	struct ConfigRecord *configdata = &mainmeory->config;

	putreg (REG_A6,exebase);
	writetexto ("**************************** Making HIPPO Packet *****************************\n",usea4a5);
	writetexto ("Conference                        High #    Total     For You",usea4a5);

	while (1) {
		msprintf (tmpstring,"%ls/%s.HD",nodebase->Nodemem.TmpPath,
				configdata->BaseName);
		if (!(msgfil = Open(tmpstring,MODE_NEWFILE))) {
			putreg (REG_A6,exebase);
			writeerroro ("Error opening msg file",usea4a5);
			break;
		}
		putreg (REG_A6,exebase);

		startconf = nodebase->confnr/2;
		dobreak = 0;
		msgpacked = 0;
		touser = 0;

		while ((message = gettopqueue(usea4a5)) && !dobreak) {
			if (dohippograbmsg (message,startconf,msgfil,usea4a5,&msgnr,&touser,&msgpacked)) {
				dobreak = 1;
				break;
			}
			removefromqueue (message,usea4a5);
		}
		if (dobreak)
			break;
		unjoin(usea4a5);

		if (msgpacked) {
			msprintf (string,"%-33ls %-9ld %-9ld %ld",
					configdata->firstconference[startconf].n_ConfName,
					configdata->firstconference[startconf].n_ConfDefaultMsg,
					msgpacked,touser);
			writetexto (string,usea4a5);
		}
		tousertot = touser;

		conf = startconf;
		do {
			conf = getnextconfnr(conf*2,usea4a5)/2;
			if (conf >= configdata->Maxconferences)
				conf = 0;
			tmp = 0;

			if (!*(configdata->firstconference[conf].n_ConfName))
				continue;

			if (!(nodebase->CU.firstuserconf[conf].uc_Access & ACCF_Read))
				continue;

			msgpacked = 0;
			touser = 0;

			highmsg = configdata->firstconference[conf].n_ConfDefaultMsg;

			message = nodebase->CU.firstuserconf[conf].uc_LastRead+1;

/* Sjekker om vi skal bruke max scan */
			if (message == 1) {
				if ((highmsg - message) > configdata->firstconference[conf].n_ConfMaxScan)
					message = highmsg - configdata->firstconference[conf].n_ConfMaxScan;
			}

			for (; message <= highmsg; message++) {
				if (!message)
					continue;

				tmp = 1;
				if (dohippograbmsg (message,conf,msgfil,usea4a5,&msgnr,&touser,&msgpacked)) {
					dobreak = 1;
					break;
				}
			}
/* Mark read
*/
			if (!dobreak && tmp) {
				nodebase->CU.firstuserconf[conf].uc_LastRead = highmsg;
				msprintf (string,"%-33ls %-9ld %-9ld %ld",
						configdata->firstconference[conf].n_ConfName,
						configdata->firstconference[startconf].n_ConfDefaultMsg,
						msgpacked,touser);
				writetexto (string,usea4a5);
				tousertot += touser;
			}

		} while (!dobreak && (conf != startconf));

		if (dobreak)
			break;

		msprintf (string,"\nNumber of messages       %-9ld",msgnr-1);
		writetexto (string,usea4a5);

		msprintf (string,"\nMessages to you          %-9ld",tousertot);
		writetexto (string,usea4a5);

		writetexto ("\nPacking...",usea4a5);

		ret = 0;
		break;
	}

	if (msgfil)
		Close (msgfil);

	if (ret)
		DeleteFile (tmpstring);

	putreg (REG_A6,exebase);
	return (ret ? -1L : (msgnr-1));
}

__asm int dohippograbmsg (register __d0 int nr, register __d1 int conf,register __d2 BPTR msgfil,a4a5,
				register __d3 int *msgnr,register __d4 int *touser,register __d5 int *numgrabbed)
{
	struct ClockData dt;
	ULONG	secs;
	char	*ptr,*ptr2;
	char	string[256];
	int	msgsize;
	int	ret = 1;
	struct	MessageRecord *msgheader;
	struct ConfigRecord *configdata = &mainmeory->config;

	msgheader = &nodebase->tmpmsgheader;

	putreg (REG_A6,exebase);
	if (loadmsg (nodebase->tmpmsgmem,msgheader,nr,conf*2,usea4a5)) {
		msprintf (string,"Error loading message (%ls:%ld)",
		configdata->firstconference[conf].n_ConfName,nr);
		writeerroro (string,usea4a5);
		return (1);
	}

	if (kanskrive (msgheader,conf*2,usea4a5))
		return (0);

	while (TRUE) {
		if (FPuts (msgfil,"Command: Message\n")) {
			putreg (REG_A6,exebase); writeerroro ("File error",usea4a5); break;
		}

		msprintf (string,"Area: %ls\n",configdata->firstconference[conf].n_ConfName);
		if (FPuts (msgfil,string)) {
			putreg (REG_A6,exebase); writeerroro ("File error",usea4a5); break;
		}

		if ((msgheader->MsgStatus & MSTATF_MsgRead) ||
				(msgheader->Security & SECF_SecReceiver)) {
			strcpy (string,"Status:");

			if (msgheader->MsgStatus & MSTATF_MsgRead)
				strcat (string," Private");
			if (msgheader->Security & SECF_SecReceiver)
				strcat (string," Read");

			strcat (string,"\n");

			if (FPuts (msgfil,string))
			{
				putreg (REG_A6,exebase); writeerroro ("File error",usea4a5); break;
			}
		}

		msprintf (string,"Number: %ld\n",msgheader->Number);
		if (FPuts (msgfil,string))
		{
			putreg (REG_A6,exebase); writeerroro ("File error",usea4a5); break;
		}

		if	(msgheader->RefTo)
		{
			msprintf (string,"Reply: %ld\n",msgheader->RefTo);
			if (FPuts (msgfil,string))
			{
				putreg (REG_A6,exebase); writeerroro ("File error",usea4a5); break;
			}
		}

		if	(msgheader->RefBy)
		{
			msprintf (string,"Next: %ld\n",msgheader->RefBy);
			if (FPuts (msgfil,string))
			{
				putreg (REG_A6,exebase); writeerroro ("File error",usea4a5); break;
			}
		}

		if	(msgheader->RefNxt)
		{
			msprintf (string,"NReply: %ld\n",msgheader->RefNxt);
			if (FPuts (msgfil,string))
			{
				putreg (REG_A6,exebase); writeerroro ("File error",usea4a5); break;
			}
		}

		secs = msgheader->MsgTimeStamp.ds_Days*24*60*60;
		secs += msgheader->MsgTimeStamp.ds_Minute*60;
		secs += msgheader->MsgTimeStamp.ds_Tick/TICKS_PER_SECOND;
		Amiga2Date (secs,&dt);
		msprintf (string,"Subject: %ls\nDate: %ld%02ld%02ld%02ld%02ld%02ld\n",
			msgheader->Subject,dt.year,dt.month,dt.mday,dt.hour,
			dt.min,dt.sec);
		if (FPuts (msgfil,string))
		{
			putreg (REG_A6,exebase); writeerroro ("File error",usea4a5); break;
		}

		putreg (REG_A6,exebase);
		getfromname (msgheader,nodebase->tmpmsgmem,usea4a5); ptr = (UBYTE *) getreg (REG_A0);
		msprintf (string,"From: %ls\n",ptr);
		if (FPuts (msgfil,string))
		{
			putreg (REG_A6,exebase); writeerroro ("File error",usea4a5); break;
		}

		putreg (REG_A6,exebase);
		gettoname (msgheader,nodebase->tmpmsgmem,usea4a5); ptr = (UBYTE *) getreg (REG_A0);
		msprintf (string,"To: %ls\n",ptr);
		if (FPuts (msgfil,string))
		{
			putreg (REG_A6,exebase); writeerroro ("File error",usea4a5); break;
		}

		msprintf (string,"Lines: %ld\n",
			msgheader->NrLines > 0 ? msgheader->NrLines : -msgheader->NrLines);
		if (FPuts (msgfil,string))
		{
			putreg (REG_A6,exebase); writeerroro ("File error",usea4a5); break;
		}

		*msgnr += 1;

		putreg (REG_A6,exebase);
		msgsize = skipnetnames (nodebase->tmpmsgmem,msgheader->NrBytes,usea4a5);
		ptr2 = (UBYTE *) getreg (REG_A0);


		if (1 != FWrite (msgfil,ptr2,msgsize,1)) {
			putreg (REG_A6,exebase); writeerroro ("File error",usea4a5); break;
		}

		if (FPuts (msgfil,"\n"))
		{
			putreg (REG_A6,exebase); writeerroro ("File error",usea4a5); break;
		}

		ret = 0;
		break;
	}

	putreg (REG_A6,exebase);

	if (!ret)
		*numgrabbed += 1;

	return (ret);
}

static __asm unsigned char	convertchartoiso (register __d0 unsigned char c,a4a5)
{
	if (c > 127) {
		c = fraIBNtilISO[c-128];
		if (!c)
			c = ' ';
	}

	return (c);
}

static __asm unsigned char	convertcharfromiso (register __d0 unsigned char c,a4a5)
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

