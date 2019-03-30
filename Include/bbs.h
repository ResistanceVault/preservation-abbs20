#ifndef BBS_H
#define BBS_H

#ifndef EXEC_TYPES_H
#include "exec/types.h"
#endif

#ifndef	EXEC_NODES_H
#include "exec/nodes.h"
#endif

#ifndef	EXEC_IO_H
#include "exec/io.h"
#endif

#ifndef LIBRARIES_DOS_H
#include "libraries/dos.h"
#endif

#define ConfigRev	1

#define 	ABBS_PUBLICSCREENNAME	"ABBS Screen"

#define LinesSize	equ	80

/* maks er 256.. */
#ifdef DEMO
#define NumMsgNrInQueue	100
#else
#define NumMsgNrInQueue	2000
#endif

#define MaxInterNodeMsg	10
#define InterNodeMsgsiz	84
#define MaxUsersGChat	5

#define Sizeof_NameT		30
#define Sizeof_PassT		8
#define Sizeof_NPassT		12
#define Sizeof_TelNo		16
#define Sizeof_FileDescription	36
#define Sizeof_FileName		18
#define Sizeof_loginscript	14

typedef char NameT[31];
typedef char NameTbug[30];
typedef char PassT[9];
typedef char NPassT[12];
typedef char TelNoT[17];
typedef char FileName[19];
typedef char FileDescription[37];
typedef char ModemStrT[61];
typedef char ModemSStrT[17];
typedef char LoginScript[14];

#define MainPortName	"ABBS mainport"
#define NetPortName1 "ABBSnet"
#define NetPortName2 ".port"

#define maksisøkebuffer 5

struct match {
	UBYTE		m_poeng;
	NameT		m_navn;
};

struct chatnode {
	APTR		c_Task;		/* = 0 -> denne brukes ikke i chat'en */
	LONG		c_Sigbit;	/* hvilket sigbit vi skal få tilsendt */
	UWORD		c_Rpos;		/* hvor langt vi har lest */
	NameT		c_Name;		/* usernavn på denne noden */
	UBYTE		c_pad;
	ULONG		c_Usernr;	/* usernr på denne noden */
	ULONG		c_Speed;	/* 0 = local */
	UWORD		c_Status;	/* se under */
	UWORD		c_color;	/* denne nodens farve (OBS : fylles i av lokal noden) */
	UWORD		c_Nodenr;	/* hvilken nodenr dette er */
};

#define statusB_Splitscreen 0
#define statusF_Splitscreen (1L<<0)

struct localchatnode {
	APTR		l_chatnode;		/* peker til vår chatnode hos den andre noden */
	APTR		l_chat;			/* peker til den andre nodens chat struktur	 */
};

struct chat {
	APTR		msgarea;				/* starten på meldingsområdet */
	APTR		msgareaend;			/* Slutten på meldingsområdet */
	UWORD		Wpos;					/* hvor langt har vi skrevet	*/
	UWORD		ChatNodeNr;
	struct	chatnode chatnodes[MaxUsersGChat-1];			/* public  */
	struct	localchatnode localchatnodes[MaxUsersGChat];	/* private */
};

struct ABBSmsg {
	struct Message msg;		// am_Msg
	UWORD		Command;	// am_Command
	UWORD		Error;		// am_Result
	ULONG		Data;		// am_Arg1
	char		*Name;		// am_Arg2
	ULONG		UserNr;		// am_Arg3
	ULONG		arg;		// am_Arg4
};

struct ABBSpubmsg {
	struct Message msg;
	UWORD		pm_Command;
	UWORD		pm_Error;
	ULONG		pm_Data;
	ULONG		pm_Arg;
	ULONG		pm_Arg2;
};

/* MainCommands
*/
#define Main_loaduser					0
#define Main_saveuser					1
#define Main_createuser					2
#define Main_getusername				3
#define Main_getusernumber				4
#define Main_saveconfig					5
#define Main_startnode					6
#define Main_shutdown					7
#define Main_savemsg					8
#define Main_loadmsg					9
#define Main_createconference			10

#define Main_loadmsgheader				11
//  Read a messageheader
//
//  In:
//   Error: (UWORD) confnumber*2
//   Data:   (struct AbbsMsgHeader *)
//   UserNr:   (ULONG) messagenr
//  Out:
// Error: 0 - ok
//             1 - error seeking (msg doesn't exist)
//              5 - error reading
// --------------------------------------------------------------------------

#define Main_loadmsgtext				12
#define Main_savemsgheader				13
#define Main_testconfig_dontuse		14
#define Main_createbulletin			15
#define Main_Clearbulletins			16
#define Main_createfiledir				17
#define Main_addfile						18
#define Main_findfile					19
#define Main_addfiledl					20
#define Main_loadfileentry				21
#define Main_savefileentry				22
#define Main_BroadcastMsg				23
#define Main_GetMaxConfDirs			24
#define Main_loadusernr					25
#define Main_saveusernr					26
#define Main_ChangeName					27
#define Main_DeleteDir					28
#define Main_RenameDir					29
#define Main_DeleteConference			30
#define Main_RenameConference			31
#define Main_NotAvailSysop				32
#define Main_loadusernrnr				33
#define Main_saveusernrnr				34
#define Main_MatchName					35
#define Main_CleanConference			36
#define Main_QuitBBS						37
#define Main_not_AddNetUser			38
#define Main_not_AddNetBBS				39
#define Main_PackUserFile				40
#define Main_OpenScreen					41
#define Main_CloseScreen				42
#define Main_Renamefileentry			43
#define Main_LockABBS					44
#define Main_UnLockABBS					45
#define Main_Getconfig					46
#define Main_LASTCOMM					47

/* Public error messages
*/
#define PError_OK							0
#define PError_NoPort					1
#define PError_PError_NoCarrier		2
#define PError_PError_NoMore			3

/* Error messages
*/
#define Error_OK							0
#define Error_Not_Found					1
#define Error_EOF							2
#define Error_Found						3
#define Error_Open_File					4
#define Error_Read						5
#define Error_Write						6
#define Error_File						7
#define Error_Nodeinit					8
#define Error_Conferencelist_full	9
#define Error_Bulletinlist_full		10
#define Error_No_Active_User			11
#define Error_User_Active				12
#define Error_Not_allowed				13
#define Error_Cant_shut_down			14
#define Error_SavingIndex				15
#define Error_IllegalCMD				16
#define Error_NoMem						17
#define Error_NoPort						18

/* Node commands
*/
#define	Node_WriteText					0
#define	Node_WriteTexto				1
#define	Node_FlushSer					2
#define	Node_WriteSerLen				3
#define	Node_ReadSerLen				4
#define	Node_QuitLogin					5
#define	Node_ReadSer					6
#define	Node_LASTCOMM					7

/* Private commands
*/
#define	Node_Reloaduser				0x8000
#define	Node_Eject						0x8001
#define	Node_Gotosleep					0x8002
#define	Node_Wakeupagain				0x8003
#define	Node_Killuser					0x8004
#define	Node_TmpSysop					0x8005
#define	Node_Show						0x8006
#define	Node_Hide						0x8007
#define	Node_chat						0x8008
#define	Node_ShowUser					0x8009
#define	Node_Shutdown					0x800a
#define	Node_GetRegs					0x800b
#define	Node_InitModem					0x800c
#define	Node_ReleasePort				0x800d
#define	Node_OffHook					0x800e
#define	Node_LASTPRIVCOMM				0x800f

/* Net commands
*/
#define Net_DoLogin	0
#define Net_LASTCOMM	1

/* line status
*/
#define OK			0
#define Timeout	1
#define NoCarrier	2
#define Thrownout	3

struct Nodenode {
	struct Node Nodenode;
	ULONG		Nodeusernr;
	UWORD		Nodenr;
	UWORD		Nodestatus;
	UBYTE		Nodedivstatus;	/* se under */
	UBYTE		NodeECstatus;	/* MNP eller V32bis */
	ULONG		NodesubStatus;
	ULONG		Nodespeed;
	ULONG		NodeTask;
	ULONG		InterMsgSig;
	UWORD		InterMsgread;
	UWORD		InterMsgwrite;
	NameT		Nodeuser;
	NameT		NodeuserCityState;
	char		NodeStatusText[120];
	UBYTE		InterNodeMsg[InterNodeMsgsiz*MaxInterNodeMsg];
	struct	ABBSmsg Nodemsg;
	APTR		nodenode_nodemem;
	ULONG		Nodenode_alloc;
};

#define NDSB_Notavail 0
#define NDSB_Stealth 1
#define NDSB_WaitforChatCon 2

#define NDSF_Notavail (1L<<0)
#define NDSF_Stealth (1L<<1)
#define NDSF_WaitforChatCon (1L<<2)

#define NECSB_MNP 0
#define NECSB_V42BIS 1
#define NECSB_UPDATED 2

#define NECSF_MNP (1L<<0)
#define NECSF_V42BIS (1L<<1)
#define NECSF_UPDATED (1L<<2)

struct intermsg {
	UBYTE		i_type;
	UBYTE		i_pri;
	UWORD		i_franode;
	ULONG		i_usernr;
	ULONG		i_usernr2;
	NameT		i_Name;
	NameT		i_Name2;
	UWORD		i_conf;
	ULONG		i_msgnr;
};
#define i_msg i_usernr

#define i_type_login		0
#define i_type_logout	1
#define i_type_msg		2
#define i_type_entermsg	3
#define i_type_chatreq	4

struct ParagonMsg {
	struct Message msg;
	UWORD		p_Command;
	UWORD		p_Data;
	UBYTE		p_string[72];
	APTR		p_msg;
	APTR		p_config;
	UWORD		p_carrier;
};

struct RexxParam {
	ULONG		rx_NumParam;
	APTR		rx_ptr1;
	APTR		rx_ptr2;
	APTR		rx_ptr3;
	APTR		rx_ptr4;
	APTR		rx_ptr5;
};

struct OldUserRecord {
	NameT		Name;				/* First AND Last name     */
	UBYTE		pass_10;
	ULONG		Usernr;			/* User number		   */
	PassT		Password;		/* users password          */
	NameT		Address;			/* Street address          */
	NameT		CityState;		/* City/State              */
	TelNoT	HomeTelno;		/* home telephone          */
	TelNoT	WorkTelno;		/* work telephone          */
	UBYTE		pass_11;
	UWORD		TimeLimit;		/* daily time limit        */
	UWORD		FileLimit;		/* daily file time limit   */
	UWORD		PageLength;		/* page length             */
	UBYTE		Protocol;		/* download protocol       */
	UBYTE		Charset;			/* character set           */
	UBYTE		ScratchFormat;
	UBYTE		XpertLevel;
	UWORD		Userbits;		/* See bit definitions     */
	UBYTE		ConfAccess[100*1];
/*	SEven */
	LoginScript	UserScript;
	LONG		ResymeMsgNr;
	UBYTE		MessageFilterV;
	UBYTE		GrabFormat;
	UWORD		u_ByteRatiov;	/*	i bytes */
	UWORD		u_FileRatiov;	/*	i filer */
	UWORD		Uploaded;	/* files uploaded          */
	UWORD		Downloaded;	/* files downloaded        */
	LONG		KbUploaded;
	LONG		KbDownloaded;
	UWORD		TimesOn;		/* number of times on      */
	struct	DateStamp LastAccess;
								/* last time on system     */
	UWORD		TimeUsed;	/* minutes on system today */
	UWORD		MsgsLeft;	/* messages entered	   */
	ULONG		MsgsRead;	/* messages read	   */
	ULONG		Totaltime;	/* total time on system	   */
	ULONG		Conflastread[100];
								/* zero is for MAIN	   */
	LONG		NFday;		/* last day user took Newfiles */
	UWORD		FTimeUsed;	/* file min's on system today */
	UWORD		Savebits;
	ULONG		MsgaGrab;
	UBYTE		u_reserved2[6];
};

struct	Userconf {
	UWORD		uc_Access;
	ULONG		uc_LastRead;
};

#define ACCB_Read			0
#define ACCB_Write		1
#define ACCB_Upload		2
#define ACCB_Download	3
#define ACCB_FileVIP		4
#define ACCB_Invited		5
#define ACCB_Sigop		6
#define ACCB_Sysop		7

#define ACCF_Read			(1L<<0)
#define ACCF_Write		(1L<<1)
#define ACCF_Upload		(1L<<2)
#define ACCF_Download	(1L<<3)
#define ACCF_FileVIP		(1L<<4)
#define ACCF_Invited		(1L<<5)
#define ACCF_Sigop		(1L<<6)
#define ACCF_Sysop		(1L<<7)

struct Log_entry {
	ULONG	l_RecordNr;			/* Hvilken record i userfile har han ? */
	ULONG	l_UserNr;
	NameT	l_Name;
	UBYTE	l_pad;
	UWORD	l_UserBits;			/* Er brukeren død ?? */
};

struct UserRecord {
	NameT		Name;				/* First AND Last name     */
	UBYTE		pass_10;
	ULONG		Usernr;			/* User number		   */
	PassT		Password;		/* users password          */
	NameT		Address;			/* Street address          */
	NameT		CityState;		/* City/State              */
	TelNoT	HomeTelno;		/* home telephone          */
	TelNoT	WorkTelno;		/* work telephone          */
	UBYTE		pass_11;
	UWORD		TimeLimit;		/* daily time limit        */
	UWORD		FileLimit;		/* daily file time limit   */
	UWORD		PageLength;		/* page length             */
	UBYTE		Protocol;		/* download protocol       */
	UBYTE		Charset;			/* character set           */
	UBYTE		ScratchFormat;
	UBYTE		XpertLevel;
	UWORD		Userbits;		/* See bit definitions     */
	NameT		UserScript;
	UBYTE		pad_1332;
	LONG		ResymeMsgNr;
	UBYTE		MessageFilterV;
	UBYTE		GrabFormat;
	UWORD		u_ByteRatiov;	/*	i bytes */
	UWORD		u_FileRatiov;	/*	i filer */
	UBYTE		u_reserved1[16];
/* startsave */
	UWORD		Uploaded;	/* files uploaded          */
	UWORD		Downloaded;	/* files downloaded        */
	LONG		KbUploaded;
	LONG		KbDownloaded;
	UWORD		TimesOn;		/* number of times on      */
	struct	DateStamp LastAccess;
								/* last time on system     */
	UWORD		TimeUsed;	/* minutes on system today */
	UWORD		MsgsLeft;	/* messages entered	   */
	ULONG		MsgsRead;	/* messages read	   */
	ULONG		Totaltime;	/* total time on system	   */
	LONG		NFday;		/* last day user took Newfiles */
	UWORD		FTimeUsed;	/* file min's on system today */
	UWORD		Savebits;
	ULONG		MsgaGrab;
	UBYTE		u_reserved2[20];
	struct Userconf	firstuserconf[1];
};

#define SIZEOFUSERRECORD	(sizeof (struct UserRecord)-sizeof (struct Userconf))

#define	u_startsave Uploaded
#define	u_endsave u_reserved2+6

#define USERB_Killed		0		/* user is dead				*/
#define USERB_FSE			1		/* use FSE						*/
#define USERB_ANSIMenus		2
#define USERB_ColorMessages	3
#define USERB_G_R			4		/* use G&R protocol			*/
#define USERB_KeepOwnMsgs	5		/* Mark written messages   */
#define USERB_ANSI			6
#define USERB_ClearScreen	7
#define USERB_RAW			8
#define USERB_NameAndAdress	9
#define USERB_Filter		10
#define USERB_SendBulletins	11
#define USERB_AutoQuote		12

#define USERF_Killed				(1L<<0)		/* user is dead				*/
#define USERF_FSE					(1L<<1)		/* use FSE						*/
#define USERF_ANSIMenus			(1L<<2)
#define USERF_ColorMessages	(1L<<3)
#define USERF_G_R					(1L<<4)		/* use G&R protocol			*/
#define USERF_KeepOwnMsgs		(1L<<5)		/* Mark written messages   */
#define USERF_ANSI				(1L<<6)
#define USERF_ClearScreen		(1L<<7)
#define USERF_RAW					(1L<<8)
#define USERF_NameAndAdress	(1L<<9)
#define USERF_Filter				(1L<<10)
#define USERF_SendBulletins	(1L<<11)

#define SAVEBITSB_FSEOverwritemode	0		/*  */
#define SAVEBITSB_FSEXYon				1		/*  */
#define SAVEBITSB_FSEAutoIndent		2		/*  */
#define SAVEBITSB_ReadRef				3		/*  */
#define SAVEBITSB_LostDL				4		/*  */
#define SAVEBITSB_Dontshowconfs		5		/*  */

#define SAVEBITSF_FSEOverwritemode	(1L<<0)		/*  */
#define SAVEBITSF_FSEXYon				(1L<<1)		/*  */
#define SAVEBITSF_FSEAutoIndent		(1L<<2)		/*  */
#define SAVEBITSF_ReadRef				(1L<<3)		/*  */
#define SAVEBITSF_LostDL				(1L<<4)		/*  */
#define SAVEBITSF_Dontshowconfs		(1L<<5)		/*  */

struct MessageRecord {
	ULONG		Number;		/* Message Number		*/
	UBYTE		MsgStatus;	/* Message Status		*/
	UBYTE		Security;	/* Message security	*/
	ULONG		MsgFrom;	/* user number			*/
	ULONG		MsgTo;		/* Ditto (-1=ALL)		*/
	NameT		Subject;	/* subject of message*/
	UBYTE		MsgBits;	/* Misc bits		   */
	struct	DateStamp MsgTimeStamp;	/* time entered*/
	ULONG		RefTo;		/* refers to		   */
	ULONG		RefBy;		/* first answer		*/
	ULONG		RefNxt;		/* next in this thread*/
	WORD		NrLines;	/* number of lines, negative if net names in message body */
	UWORD		NrBytes;	/* number of bytes	*/
	ULONG		TextOffs;	/* offset in text file*/
};

#define MSTATB_NormalMsg		0
#define MSTATB_KilledByAuthor	1
#define MSTATB_KilledBySysop	2
#define MSTATB_KilledBySigop	3
#define MSTATB_Moved			4
#define MSTATB_Diskkilled		5	// Slettet fysisk fra disken?
#define MSTATB_MsgRead			6
#define MSTATB_Dontshow			7	// Slettes av ABBS dersom brukeren er killa etc

#define MSTATF_NormalMsg		(1L<<0)
#define MSTATF_KilledByAuthor	(1L<<1)
#define MSTATF_KilledBySysop	(1L<<2)
#define MSTATF_KilledBySigop	(1L<<3)
#define MSTATF_Moved			(1L<<4)
#define MSTATF_Diskkilled		(1L<<5)		// Slettet fysisk fra disken?
#define MSTATF_MsgRead			(1L<<6)			/* read by receiver	   */
#define MSTATF_Dontshow			(1L<<7)

#define SECB_SecNone		0
#define SECB_SecPassword	1
#define SECB_SecReceiver	2

#define SECF_SecNone		(1L<<0)
#define SECF_SecPassword	(1L<<1)
#define SECF_SecReceiver	(1L<<2)

#define	MsgBitsB_FromNet	0
#define	MsgBitsF_FromNet	(1L<<0)

struct OldConfigRecord {
	ULONG		Users;				/* number of users registerd		*/
	ULONG		MaxUsers;			/* max number of users registred	*/
	NameT		BaseName;			/* name of this BBS					*/
	NameT		SYSOPname;
	ULONG		SYSOPUsernr;
	PassT		SYSOPpassword;		/* brukes ikke enda					*/
	BYTE			pad;
	UWORD		MaxLinesMessage;
	UWORD		ActiveConf;			/* limited to 100		*/
	UWORD		ActiveDirs;			/* limited to MaxFileDirs			*/
	UWORD		NewUserTimeLimit;
	UWORD		SleepTime;
	PassT		ClosedPassword;	/* brukes ikke enda					*/
	BYTE			pad2;
	UBYTE		DefaultCharSet;
	UBYTE		Cflags;
	UWORD		NewUserFileLimit;
	NameTbug		ConfNames[100];
	UBYTE		ConfSW[100];
	UBYTE		ConfOrder[100];
	ULONG		ConfDefaultMsg[100];
	NameTbug		DirNames[100];
	UBYTE		FileOrder[100];
	UBYTE		ConfBullets[100];
	NameTbug		DirPaths[100];
	UWORD		ConfMaxScan[100];
	UWORD		ByteRatiov;			/* i bytes								*/
	UWORD		FileRatiov;			/* i filer								*/
	UWORD		MinULSpace;			/* i KB									*/
	UBYTE		Cflags2;
	UBYTE		pad_a123;
	ULONG		pad_asdsad;
	ULONG		pad_sdsd;
	PassT		dosPassword;
	UBYTE		cnfg_empty[13];
};

struct ConferenceRecord {
	NameT		n_ConfName;
	UBYTE		n_ConfBullets;
	ULONG		n_ConfDefaultMsg;	/* Highest message in conference			*/
	ULONG		n_ConfFirstMsg;	/* First message number in conference	*/
	UWORD		n_ConfOrder;		/* order											*/
	UWORD		n_ConfSW;
	UWORD		n_ConfMaxScan;
};

struct ConfigRecord {
	UWORD	Revision;			/* ConfigRev = Revision of configfile */
	ULONG	Configsize;
	ULONG	UserrecordSize;
	UWORD	Maxconferences;
	UWORD	MaxfileDirs;
	ULONG	Users;				/* number of users registerd			*/
	ULONG	MaxUsers;			/* max number of users registred	*/
	NameT	BaseName;			/* name of this BBS								*/
	NameT	SYSOPname;
	ULONG	SYSOPUsernr;
	NPassT	SYSOPpassword;		/* brukes ved lokal login. Hvis tom, ikke noe passord.. */
	NPassT	ClosedPassword;		/* brukes ikke enda					*/
	UWORD	MaxLinesMessage;
	UWORD	ActiveConf;			/* limited to Maxconferences		*/
	UWORD	ActiveDirs;			/* limited to MaxFileDirs			*/
	UWORD	NewUserTimeLimit;
	UWORD	SleepTime;
	UBYTE	DefaultCharSet;
	UBYTE	Cflags;
	UWORD	NewUserFileLimit;

	UWORD	ByteRatiov;			/* i bytes								*/
	UWORD	FileRatiov;			/* i filer								*/
	UWORD	MinULSpace;			/* i KB									*/
	UBYTE	Cflags2;
	UBYTE	pad_a123;
	NPassT	dosPassword;
	UBYTE	cnfg_empty[256];
	struct FileDirRecord *firstFileDirRecord;
	struct ConferenceRecord firstconference[1];
};

#define SIZEOFCONFIGRECORD	(sizeof (struct ConfigRecord)-sizeof (struct ConferenceRecord))

struct FileDirRecord {
	NameT		n_DirName;
	NameT		n_DirPaths;
	UWORD		n_FileOrder;
	UWORD		n_PrivToConf;
};

/* confSW
*/

#define CONFSWB_ImmRead		0
#define CONFSWB_ImmWrite	1
#define CONFSWB_PostBox		2
#define CONFSWB_Private		3
#define CONFSWB_VIP			4
#define CONFSWB_Resign		5
#define CONFSWB_Network		6
#define CONFSWB_Alias		7

#define CONFSWF_ImmRead		(1L<<0)
#define CONFSWF_ImmWrite	(1L<<1)
#define CONFSWF_PostBox		(1L<<2)
#define CONFSWF_Private		(1L<<3)
#define CONFSWF_VIP			(1L<<4)
#define CONFSWF_Resign		(1L<<5)
#define CONFSWF_Network		(1L<<6)
#define CONFSWF_Alias		(1L<<7)

//Cflags
#define CFLAGSF_lace			(1L<<0)
#define CFLAGSF_8Col			(1L<<1)
#define CFLAGSF_Download		(1L<<2)
#define CFLAGSF_Upload			(1L<<3)
#define CFLAGSF_Byteratio		(1L<<4)
#define CFLAGSF_Fileratio		(1L<<5)
#define CFLAGSF_AllowTmpSysop	(1L<<6)
#define CFLAGSF_UseASL			(1L<<7)

//Cflags2
#define CFLAGS2F_NoGet		(1L<<0)
#define CFLAGS2F_CacheFL	(1L<<1)

#define BCCS_ISO	0
#define BCCS_IBM	1
#define BCCS_IBN	2

struct NodeRecord {
	UBYTE	NodeRecord_pad;
	UBYTE	CommsPort;					/* 0 = local, else port = n-1 */
	UBYTE	ConnectWait;				/* max time to wait from ring to connect */
	UBYTE	NodeSetup;					/* div bits for setup */
	ULONG	MinBaud;						/* minimum baud to accept for this node */
	UWORD	Setup;						/* See Bit definitions below */
	ULONG	NodeBaud;					/* baud to use between modem-machine */
	ModemStrT	Serialdevicename;
	ModemStrT	ModemInitString;
	ModemSStrT	ModemAnswerString;
	ModemSStrT	ModemOffHookString;
	ModemSStrT	ModemOnHookString;
	ModemSStrT	ModemCallString;
	ModemSStrT	ModemRingString;
	ModemSStrT	ModemConnectString;
	ModemSStrT	ModemOKString;
	ModemSStrT	ModemATString;
	ModemSStrT	ModemNoCarrierString;
/*	SEven */
	UBYTE	pad_1;
	UBYTE	HourMaxTime[24];			/* Maximum allowed time this hour */
	UBYTE	HourMinWait[24];			/* Minimum time between calls this hour */
	NameT	PublicScreenName;			/* abbs/wb(default)/any */
	NameT	HoldPath;
	NameT	TmpPath;						/* path for this nodes tmpdir (must end in a : or /) */
	NameT	Font;							/* name for this nodes font (must end in a : or /) */
	UWORD	FontSize;					/* font size */
	UWORD	win_big_x;					/* x pos for normal window */
	UWORD	win_big_y;					/* y pos for normal window */
	UWORD	win_big_height;			/* height for normal window */
	UWORD	win_big_width;				/* width for normal window */
	UWORD	win_tiny_x;					/* x pos for tiny window */
	UWORD	win_tiny_y;					/* y pos for tiny window */
};

/* #define SETUPB_XonXoff			0 */	/* NOT IN USE */
#define SETUPB_RTSCTS			1
#define SETUPB_Lockedbaud		2
#define SETUPB_SimpelHangup	3
#define SETUPB_NullModem		4
#define SETUPB_NoSleepTime		5

/* #define SETUPF_XonXoff			(1L<<0) */
#define SETUPF_RTSCTS			(1L<<1)
#define SETUPF_Lockedbaud		(1L<<2)
#define SETUPF_SimpelHangup	(1L<<3)
#define SETUPF_NullModem		(1L<<4)
#define SETUPF_NoSleepTime		(1L<<5)

#define NodeSetupB_TinyMode	0
#define NodeSetupB_DontShow	1
#define NodeSetupB_BackDrop	2
#define NodeSetupB_UseABBScreen	3

#define NodeSetupF_TinyMode	(1L<<0)
#define NodeSetupF_DontShow	(1L<<1)
#define NodeSetupF_BackDrop	(1L<<2)
#define NodeSetupF_UseABBScreen	(1L<<3)

struct OldFileEntry {
	UBYTE	fe_Name[17];		// Filnavn (16 tegn)
	UBYTE	pad1;			// En pad
	UWORD	fe_Flags;			// Diverse flags
	ULONG	fe_Size;			// Filstørrelse i bytes
	ULONG	fe_Sender;		// Hvem som uploada fila
	ULONG	fe_Receiver;		// Filas mottager / conf (conf = #/2+1)
	ULONG	fe_DLoads;		// Hvor mange som har downloada fila
	ULONG	fe_MsgNr;			// Meldingsnummer i FileInfo i filinfo konfen
	struct DateStamp fe_DateStamp; // Dato fila ble uploada
	UBYTE	fe_Descr[39];		// Filbeskrivelse (38 tegn)
	UBYTE	pad2;
};								

struct Fileentry {
	FileName	Filename;	// Filenavn (18 tegn)
	UBYTE		pad1;		// En pad.
	UWORD		Filestatus;	// Diverse flags 
	ULONG		Fsize;		// Filstørrelse i bytes
	ULONG		Uploader;	// Hvem som uploada fila
	ULONG		PrivateULto;	// Fila mottager / conf (conf = #/2+1)
	ULONG		AntallDLs;	// Hvor mange som har downloada fila
	ULONG		Infomsgnr;	// Meldingsnummer i FileInfo i filinfo konfen
	struct	DateStamp ULdate;	// Dato fila ble uploada
	FileDescription	Filedescription; // Filbeskrivelse (36 tegn)
	UBYTE		pad2;		// En pad til
};

/* filestatus
*/
#define FILESTATUSB_PrivateUL		0
#define FILESTATUSB_PrivateConfUL	1
#define FILESTATUSB_Filemoved		2
#define FILESTATUSB_Fileremoved		3
#define FILESTATUSB_FreeDL			4
#define FILESTATUSB_Selected		5
#define FILESTATUSB_Preview			6

#define FILESTATUSF_PrivateUL		(1L<<0)
#define FILESTATUSF_PrivateConfUL	(1L<<1)
#define FILESTATUSF_Filemoved		(1L<<2)
#define FILESTATUSF_Fileremoved		(1L<<3)
#define FILESTATUSF_FreeDL			(1L<<4)
#define FILESTATUSF_Selected		(1L<<5)
#define FILESTATUSF_Preview			(1L<<6)

#define PAD1STATUSB_ArcTested		0
#define PAD1STATUSB_VirusTested		1

#define PAD1STATUSF_ArcTested		(1L<<0)
#define PAD1STATUSF_VirusTested		(1L<<1)

#define PAD2STATUSB_ABBS_1		0
#define PAD2STATUSB_ABBS_2		1

struct mem_Fileentry {
	struct	Fileentry mem_fileentry;
	ULONG	mem_filefilenr;
	ULONG	mem_filenr;
	ULONG	mem_fnext;
	ULONG	mem_fnexthash;
};

struct fileentryheader {
	ULONG		fl_hash[72];
	APTR		first_file;
};

struct Mainmemory {
	UWORD	Nodes;
	UWORD	MainBits;
	ULONG	MainmemoryAlloc;
	ULONG	MaxNumLogEntries;
	ULONG	NrTabelladr;
	ULONG	LogTabelladr;
	ULONG	flpool;
	char	txtbuffer[80];
	char	txt2buffer[80];
	ULONG	keys[10];
	ULONG	keyfile;
	ULONG	userfile;
	struct ABBSmsg Mainmsg;
	APTR	n_Filedirfiles;
	APTR	n_MsgHeaderfiles;
	APTR	n_MsgTextfiles;
	struct ConfigRecord config;

/*	STRUCT	NrTabell,0		/ * denne har dynamisk størrelse
					/ * nrTabell(usernr) -> LogTabell
	STRUCT	LogTabell		/ * dynamisk size og plaseringen
*/
};

#ifdef sdfsdf

	BITDEF	MainBits,SysopNotAvail,0
	BITDEF	MainBits,ABBSLocked,1

#endif

#endif	/* BBS_H */
