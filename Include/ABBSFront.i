	IFND	ABBSFRONT_I
ABBSFRONT_I	SET	1

	STRUCTURE	ConnectMsg,0
	ULONG	cm_fieldCnt	; Responses present, currently 4
	ULONG	cm_baud		; Baud-rate as reported by modem
	CPTR	cm_connect	; Extended connect msg eg. /ARQ, /HST
	CPTR	cm_protocol	; Protocol as reported by modem
	CPTR	cm_compression	; Compression as reported by modem
	LABEL		ConnectMsg_SIZE

	STRUCTURE	FrontMsg,MN_SIZE
	UWORD		f_Command
	UWORD		f_Error
	ULONG		f_Connect
	ULONG		f_LoginString
	UWORD		f_Flags
	LABEL		FrontMsg_SIZE

	BITDEF	f_flags,NoInit,0
	BITDEF	f_flags,NoHangup,1


* commands
	DEVINIT	0
	DEVCMD	front_SleepSer			; ingen parametre. Får abbs til å "glemme serieporten"
	DEVCMD	front_DoLogin			; Du må fylle ut f_Connect og f_LoginString
	DEVCMD	front_DropCarrier		; dropper carrier. Ingen parametre
	DEVCMD	front_ReplyNOW			; Svarer på meldingen ASAP
	DEVCMD	front_AwakeSer			; ingen parametre. Får abbs til å "huske serieporten" igjen.
	DEVCMD	front_GetSerDev		; Get serial device info

	DEVINIT	0
	DEVCMD	F_Error_OK
	DEVCMD	F_Error_UserOnline
	DEVCMD	F_Error_NoSerial
	DEVCMD	F_Error_NoMsgtoReply

	STRUCTURE	FrontNodeRecord,0
	UBYTE		f_NodeRecord_pad
	UBYTE		f_CommsPort		; 0 = local, else port = n-1
	UBYTE		f_ConnectWait		; max time to wait from ring to connect
	UBYTE		f_NodeRecord_pad1	; private
	UBYTE		f_NodeSetup		; div bits for setup
	ULONG		f_MinBaud		; minimum baud to accept for this node
	UWORD		f_Setup			; See Bit definitions below
	ULONG		f_NodeBaud		; baud to use between modem-machine
	ModemStrT	f_Serialdevicename
	ModemStrT	f_ModemInitString
	ModemSStrT	f_ModemAnswerString
	ModemSStrT	f_ModemOffHookString
	ModemSStrT	f_ModemOnHookString
	ModemSStrT	f_ModemCallString
	ModemSStrT	f_ModemRingString
	ModemSStrT	f_ModemConnectString
	ModemSStrT	f_ModemOKString
	ModemSStrT	f_ModemATString
	ModemSStrT	f_ModemNoCarrierString
	LABEL		FrontNodeRecord_SIZEOF

;	BITDEF	f_SETUP,XonXoff,0			; NOT IN USE
	BITDEF	f_SETUP,RTSCTS,1
	BITDEF	f_SETUP,Lockedbaud,2
	BITDEF	f_SETUP,SimpelHangup,3
	BITDEF	f_SETUP,NullModem,4

	ENDC	; ABBSFRONT_I
