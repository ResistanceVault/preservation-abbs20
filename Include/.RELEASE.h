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

struct	Userconf {
	UWORD		uc_Access;
	ULONG		uc_LastRead;
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

#define ACCB_Read			0
#define ACCB_Write		1
#define ACCB_Upload		2
#define ACCB_Download	3
#define ACCB_FileVIP		4
/*#define ACCB_Invited		5 */
#define ACCB_Sigop		6
#define ACCB_Sysop		7

#define ACCF_Read			(1L<<0)
#define ACCF_Write		(1L<<1)
#define ACCF_Upload		(1L<<2)
#define ACCF_Download	(1L<<3)
#define ACCF_FileVIP		(1L<<4)
/*#define ACCF_Invited		(1L<<5) */
#define ACCF_Sigop		(1L<<6)
#define ACCF_Sysop		(1L<<7)

#define USERB_Killed				0		/* user is dead				*/
#define USERB_FSE					1		/* use FSE						*/
#define USERB_ANSIMenus			2
#define USERB_ColorMessages	3
#define USERB_G_R					4		/* use G&R protocol			*/
#define USERB_KeepOwnMsgs		5		/* Mark written messages   */
#define USERB_ANSI				6
#define USERB_ClearScreen		7
#define USERB_RAW					8
#define USERB_NameAndAdress	9
#define USERB_Filter				10
#define USERB_SendBulletins	11

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
#define FILESTATUSB_FreeDL		4
#define FILESTATUSB_ArcTested		5
#define FILESTATUSB_VirusTested		6

#define FILESTATUSF_PrivateUL		(1L<<0)
#define FILESTATUSF_PrivateConfUL	(1L<<1)
#define FILESTATUSF_Filemoved		(1L<<2)
#define FILESTATUSF_Fileremoved		(1L<<3)
#define FILESTATUSF_FreeDL		(1L<<4)
#define FILESTATUSF_ArcTested		(1L<<5)
#define FILESTATUSF_VirusTested		(1L<<6)

// **********************************
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
	NPassT	ClosedPassword;	/* brukes ikke enda					*/
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

struct ConferenceRecord {
	NameT		n_ConfName;
	UBYTE		n_ConfBullets;
	ULONG		n_ConfDefaultMsg;	/* Highest message in conference			*/
	ULONG		n_ConfFirstMsg;	/* First message number in conference	*/
	UWORD		n_ConfOrder;		/* order											*/
	UWORD		n_ConfSW;
	UWORD		n_ConfMaxScan;
};

#endif	/* BBS_H */
