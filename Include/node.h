#ifndef NODE_H
#define NODE_H
/***************************************************************
*								node variabler									*
***************************************************************/

#ifndef BBS_H
#include <bbs.h>
#endif	/* BBS_H */

#ifndef XPROTO_H
#include <xproto.h>
#endif	/* XPROTO_H */


#ifndef XPR_H
#include <xpr.h>
#endif	/* XPR_H */

struct ramblocks {
	UBYTE		con_tegn;
	UBYTE		Divmodes;	/* se def under */
#ifndef	DEMO
	UBYTE		ser_tegn;
#else
	UBYTE		pad_1241;
#endif
	UBYTE		tegn_fra;

	UWORD		loginmin;
	UWORD		joinfilemin;
	ULONG		lastdayonline;
	UWORD		lastminonline;

	ULONG		oldcliname;
	ULONG		filereqadr;
	ULONG		windowadr;
	LONG		pubscreenadr;
	LONG		fontadr;
	ULONG		windowtitleptr;
	ULONG		showuserwindowadr;
	ULONG		creadreq;
	ULONG		cwritereq;
#ifndef	DEMO
	ULONG		sreadreq;
	ULONG		swritereq;
#endif
	ULONG		timer1req;
	ULONG		timer2req;

	ULONG		nodestack;
	ULONG		waitbits;
	ULONG		gotbits;
	ULONG		consigbit;
#ifndef	DEMO
	ULONG		sersigbit;
#endif
	ULONG		intsigbit;
	ULONG		showwinsigbit;
	ULONG		timer1sigbit;
	ULONG		timer2sigbit;
	ULONG		intersigbit;
	ULONG		publicsigbit;
	ULONG		rexxsigbit;
	ULONG		intmsgport;
	ULONG		msg;
	ULONG		HighMsgQueue;
	ULONG		curprompt;
	ULONG		ULfilenamehack;
#define tmpstore ULfilenamehack;
	ULONG		ParamPass;
	ULONG		tmpval;
	ULONG		SerTotOut;

	ULONG		infoblock;
	UBYTE		readcharstatus;
	UBYTE		dosleepdetect;
	UBYTE		tmpsysopstat;
#ifndef	DEMO
	UBYTE		RealCommsPort;
#else
	UBYTE		pad_142;
#endif
	UBYTE		batch;
	UBYTE		cursorpos;

	ULONG		currentmsg;
	UWORD		menunr;
	UWORD		confnr;
	UWORD		linesleft;
	UBYTE		in_waitforcaller;
	UBYTE		readlinemore;
	UBYTE		ShutdownNode;
	UBYTE		active;
	UBYTE		activesysopchat;
	UBYTE		Dodiv;				/* See bit definistion below */
	UWORD		Historyoffset;

#ifndef	DEMO
	UWORD		cpsrate;
#endif
	UWORD		intextchar;
	UWORD		outtextchar;
	UWORD		outtextbufferpos;

	UBYTE		readingpassword;
	UBYTE		userok;
	UBYTE		Tinymode;
	UBYTE		warningtineindex;

	UWORD		OldTimelimit;
	UWORD		OldFilelimit;
	UBYTE		NodeError;
	UBYTE		DlUlstatus;
	UWORD		NodeNumber;
	ULONG		FrontDoorMsg;
	ULONG		nodeport;
	ULONG		rexxport;
	ULONG		nodepublicport;
	ULONG		nodenoden;
	ULONG		msgmemsize;
	APTR		tmpmsgmem;
	ULONG		exallctrl;
	APTR		node_menu;
	APTR		visualinfo;
	UBYTE		FSEditor;
	UBYTE		outlines;
	UBYTE		intersigbitnr;
	UBYTE		serescstat;
	UBYTE		lastchar;
	UBYTE		noglobal;
	UWORD		tmsgsread;
	UWORD		tmsgsdumped;
	UWORD		minchat;
	UWORD		minul;
	UWORD		tmpword;
	UWORD		PrevNodestatus;
	ULONG		PrevNodesubStatus;
	ULONG		waitforcallerstack;
	ULONG		pad2342;
	APTR		Tmpusermem;
	APTR		Loginlastread;
	UBYTE		windowsizepos[2*8];		/* top,left,width,height * 2 (zoom også) */
	struct	DateStamp lastchartime;
	struct	DateStamp tmpdatestamp;
	char		tmpnodestatustext[24];
	char		readlinebuffer[80];		// ??
	char		intextbuffer[82];		// Hele argumentlinja
	char		outtextbuffer[82*2];	// ??
	char		conouttextbuffer[82*2];
	char		transouttextbuffer[82*4];
	struct	NodeRecord Nodemem;
/*	SEven
*/
	char		logfilename[24];
	char		Publicportname[20];
	char		Paragonportname[16];			/* brukes bare når paragondoors kjøres */
#define tmpwhilenotinparagon	Paragonportname
	UWORD		pad_234234;
	UBYTE		Nodetaskname_BCPL;
	char		Nodetaskname[59];
	char		pastetext[80];
	char		tmpnametext[80];
	struct	MessageRecord tmpmsgheader;
	char		tmptext[80];
	char		maintmptext[80];
	struct	Fileentry tmpfileentry;
	struct	FileInfoBlock infoblockmem;
	UBYTE		infoblockmempad[2];
#define tmplargestore infoblockmem

	struct	XPR_IO	xpriomem;
	UBYTE		dummy[100];
#define tmptext2 dummy
	char			historybuffer[1024];
	ULONG			msgqueue[NumMsgNrInQueue+1];
	ULONG			prevqueue[52];
	struct UserRecord	CU;
};

/* Bits for the DoDiv field
*/
#define DoDivB_HideNode 0
#define DoDivF_HideNode (1L<<0)

#define DoDivB_NoInit 1
#define DoDivF_NoInit (1L<<1)

#define DoDivB_Sleep 2
#define DoDivF_Sleep (1L<<2)

#define DoDivB_ExitWaitforCaller 3
#define DoDivF_ExitWaitforCaller (1L<<3)

#ifdef sfdgsdfg
	BITDEF	DIV,QuickMode,0
	BITDEF	DIV,StealthMode,1
	BITDEF	DIV,InNewuser,2
	BITDEF	DIV,Browse,3
	BITDEF	DIV,InBrowse,4
	BITDEF	DIV,InNetLogin,5

	STRUCTURE	findfilestruct,0
	STRUCT		ff_infoblockmem,fib_SIZEOF
	ULONG		ff_lock
	STRUCT		ff_pattern,160
	STRUCT		ff_path,100
	STRUCT		ff_full,160
	LABEL		findfilestruct_sizeof
#endif

#define Net_FromCode	'\x1e'	 /* From	= Terminert av newline	*/
#define Net_ToCode	'\x1f'	 /* To		= Terminert av newline	*/
#define Net_SubjCode	'\x1d'	 /* Subject	= Terminert av newline	*/
#define Net_ExtDCode	'\x1c'	 /* ExtData	= Terminert av $FF byte	*/

#endif	/* NODE_H */
