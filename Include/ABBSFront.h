#ifndef ABBSFRONT_H
#define ABBSFRONT_H

typedef char ModemStrT[61];
typedef char ModemSStrT[17];

struct ConnectMsg {
	ULONG		cm_fieldCnt;		/* Responses present, currently 4		*/
	ULONG		cm_baud;				/* Baud-rate as reported by modem		*/
	STRPTR	cm_connect;			/* Extended connect msg eg. /ARQ, /HST */
	STRPTR	cm_protocol;		/* Protocol as reported by modem		 */
	STRPTR	cm_compression;	/* Compression as reported by modem	 */
	/* More fields could follow here, check cm_fieldCnt */
};

struct FrontMsg {
	struct Message msg;
	UWORD		f_Command;
	UWORD		f_Error;
	struct ConnectMsg *f_Connect;
	STRPTR	f_LoginString;
	UWORD		f_Flags;
};

#define FFLAGSB_NoInit	0
#define FFLAGSB_NoHangup 1

#define FFLAGSF_NoInit		(1L<<0)
#define FFLAGSF_NoHangup	(1L<<1)

/* Commands
*/
#define	front_SleepSer			0	/* ingen parametre. Får abbs til å "glemme serieporten"	*/
#define	front_DoLogin			1	/* Du må fylle ut f_Connect og f_LoginString					*/
#define	front_DropCarrier		2	/* dropper carrier. Ingen parametre								*/
#define	front_ReplyNOW			3	/* Svarer på meldingen ASAP										*/
#define	front_AwakeSer			4	/* ingen parametre. Får abbs til å "huske serieporten"	*/
#define	front_GetSerDev		5	/* Get serial device info											*/

#define	F_Error_OK					0
#define	F_Error_UserOnline		1
#define	F_Error_NoSerial			2
#define	F_Error_NoMsgtoReply		3

struct FrontNodeRecord {
	UBYTE		f_NodeRecord_pad;
	UBYTE		f_CommsPort;				/* 0 = local, else port = n-1 */
	UBYTE		f_ConnectWait;				/* max time to wait from ring to connect (seconds) */
	UBYTE		f_NodeRecord_pad1;		/* Private */
	ULONG		f_MinBaud;					/* minimum baud to accept for this node */
	UWORD		f_Setup;						/* See Bit definitions below */
	ULONG		f_NodeBaud;					/* baud to use between modem-machine */
	ModemStrT	f_Serialdevicename;
	ModemStrT	f_ModemInitString;
	ModemSStrT	f_ModemAnswerString;
	ModemSStrT	f_ModemOffHookString;
	ModemSStrT	f_ModemOnHookString;
	ModemSStrT	f_ModemCallString;
	ModemSStrT	f_ModemRingString;
	ModemSStrT	f_ModemConnectString;
	ModemSStrT	f_ModemOKString;
	ModemSStrT	f_ModemATString;
	ModemSStrT	f_ModemNoCarrierString;
};

/* #define SETUPB_XonXoff			0 */	/* NOT IN USE */
#define FSETUPB_RTSCTS			1
#define FSETUPB_Lockedbaud		2
#define FSETUPB_SimpelHangup	3
#define FSETUPB_NullModem		4

/* #define FSETUPF_XonXoff			(1L<<0) */
#define FSETUPF_RTSCTS			(1L<<1)
#define FSETUPF_Lockedbaud		(1L<<2)
#define FSETUPF_SimpelHangup	(1L<<3)
#define FSETUPF_NullModem		(1L<<4)

#endif	/* ABBSFRONT_H */
