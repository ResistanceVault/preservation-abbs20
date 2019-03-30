	IFND	BBS_I
BBS_I	SET	1

	IFND EXEC_TYPES_I
	INCLUDE "exec/types.i"
	ENDC	; EXEC_TYPES_I

	IFND	EXEC_IO_I
	INCLUDE "exec/io.i"
	ENDC	; EXEC_IO_I

	IFND  LIBRARIES_DOS_I
	INCLUDE "libraries/dos.i"
	ENDC

MainBase	equr	a5
NodeBase	equr	a4
LinesSize	equ	80

; maks er 256..
	IFD DEMO
MaxConferences	equ	3
MaxFileDirs	equ	3
NumMsgNrInQueue	equ	100
	ENDC

	IFND DEMO
MaxConferences	equ	100
MaxFileDirs	equ	100
NumMsgNrInQueue	equ	2000
	ENDC
MaxInterNodeMsg	equ	10
InterNodeMsgsiz	equ	84
MaxUsersGChat	equ	5

Sizeof_NameT	equ	30
Sizeof_PassT	equ	8
Sizeof_TelNo	equ	16
Sizeof_FileDescription	equ	38
Sizeof_FileName	equ	16
Sizeof_loginscript equ	14

SEven		MACRO
		IFNE	SOFFSET&1
SOFFSET		SET	SOFFSET+1
		ENDC
		ENDM

NameT		MACRO
\1		EQU	SOFFSET
SOFFSET		SET	SOFFSET+31
		ENDM

PassT		MACRO
\1		EQU	SOFFSET
SOFFSET		SET	SOFFSET+9
		ENDM

TelNoT		MACRO
\1		EQU	SOFFSET
SOFFSET		SET	SOFFSET+17
		ENDM

FileName	MACRO
\1		EQU	SOFFSET
SOFFSET		SET	SOFFSET+17
		ENDM

FileDescription	MACRO
\1		EQU	SOFFSET
SOFFSET		SET	SOFFSET+39
		ENDM

ModemStrT	MACRO
\1		EQU	SOFFSET
SOFFSET		SET	SOFFSET+61
		ENDM

ModemSStrT	MACRO
\1		EQU	SOFFSET
SOFFSET		SET	SOFFSET+17
		ENDM

maksisøkebuffer = 5

	STRUCTURE	match,0
	UBYTE		m_poeng
	NameT		m_navn
	LABEL		match_sizeof

	STRUCTURE	chatnode,0
	APTR		c_Task			; = 0 -> denne brukes ikke i chat'en
	LONG		c_Sigbit		; hvilket sigbit vi skal få tilsendt
	UWORD		c_Rpos			; hvor langt vi har lest
	NameT		c_Name			; usernavn på denne noden
	SEven
	ULONG		c_Usernr		; usernr på denne noden
	ULONG		c_Speed			; 0 = local
	UWORD		c_Status		; se under
	UWORD		c_color			; denne nodens farve (OBS : fylles i av lokal noden)
	UWORD		c_Nodenr		; hvilken nodenr dette er
	LABEL		chatnode_sizeof

	BITDEF	status,Splitscreen,0

	STRUCTURE	localchatnode,0
	APTR		l_chatnode			; peker til vår chatnode hos den andre noden
	APTR		l_chat				; peker til den andre nodens chat struktur
	LABEL		localchatnode_sizeof

	STRUCTURE	chat,0
	APTR		msgarea				; starten på meldingsområdet
	APTR		msgareaend			; Slutten på meldingsområdet
	UWORD		Wpos				; hvor langt har vi skrevet
	UWORD		ChatNodeNr
	STRUCT		chatnodes,chatnode_sizeof*(MaxUsersGChat-1)		; public
	STRUCT		localchatnodes,localchatnode_sizeof*MaxUsersGChat	; private
	LABEL		chat_sizeof

	STRUCTURE	ABBSmsg,MN_SIZE
	UWORD		m_Command
	UWORD		m_Error
	ULONG		m_Data
	ULONG		m_Name
	ULONG		m_UserNr
	ULONG		m_arg
	LABEL		ABBSmsg_SIZE

	STRUCTURE	ABBSpubmsg,MN_SIZE
	UWORD		pm_Command
	UWORD		pm_Error
	ULONG		pm_Data
	ULONG		pm_Arg
	ULONG		pm_Arg2
	LABEL		ABBSpubmsg_SIZE

	;MainCommands
	DEVINIT	0
	DEVCMD	Main_loaduser
	DEVCMD	Main_saveuser
	DEVCMD	Main_createuser
	DEVCMD	Main_getusername
	DEVCMD	Main_getusernumber
	DEVCMD	Main_saveconfig
	DEVCMD	Main_startnode
	DEVCMD	Main_shutdown
	DEVCMD	Main_savemsg
	DEVCMD	Main_loadmsg
	DEVCMD	Main_createconference
	DEVCMD	Main_loadmsgheader
	DEVCMD	Main_loadmsgtext
	DEVCMD	Main_savemsgheader
	DEVCMD	Main_testconfig
	DEVCMD	Main_createbulletin
	DEVCMD	Main_Clearbulletins
	DEVCMD	Main_createfiledir
	DEVCMD	Main_addfile
	DEVCMD	Main_findfile
	DEVCMD	Main_addfiledl
	DEVCMD	Main_loadfileentry
	DEVCMD	Main_savefileentry
	DEVCMD	Main_BroadcastMsg
	DEVCMD	Main_GetMaxConfDirs
	DEVCMD	Main_loadusernr
	DEVCMD	Main_saveusernr
	DEVCMD	Main_ChangeName
	DEVCMD	Main_DeleteDir
	DEVCMD	Main_RenameDir
	DEVCMD	Main_DeleteConference
	DEVCMD	Main_RenameConference
	DEVCMD	Main_NotAvailSysop
	DEVCMD	Main_loadusernrnr
	DEVCMD	Main_saveusernrnr
	DEVCMD	Main_MatchName
	DEVCMD	Main_CleanConference
	DEVCMD	Main_QuitBBS
	DEVCMD	not_Main_AddNetUser
	DEVCMD	not_Main_AddNetBBS
	DEVCMD	Main_PackUserFile
	DEVCMD	Main_OpenScreen
	DEVCMD	Main_CloseScreen
	DEVCMD	Main_Renamefileentry
	DEVCMD	Main_LASTCOMM


	; PublicErrors
	DEVINIT	0
	DEVCMD	PError_OK
	DEVCMD	PError_NoPort
	DEVCMD	PError_NoCarrier
	DEVCMD	PError_NoMore

	; Errors
	DEVINIT	0
	DEVCMD	Error_OK
	DEVCMD	Error_Not_Found
	DEVCMD	Error_EOF
	DEVCMD	Error_Found
	DEVCMD	Error_Open_File
	DEVCMD	Error_Read
	DEVCMD	Error_Write
	DEVCMD	Error_File
	DEVCMD	Error_Nodeinit
	DEVCMD	Error_Conferencelist_full
	DEVCMD	Error_Bulletinlist_full
	DEVCMD	Error_No_Active_User
	DEVCMD	Error_User_Active
	DEVCMD	Error_Not_allowed
	DEVCMD	Error_Cant_shut_down
	DEVCMD	Error_SavingIndex
	DEVCMD	Error_IllegalCMD
	DEVCMD	Error_Nomem
	DEVCMD	Error_NoPort

	;NodeCommands
	DEVINIT	0
	DEVCMD	Node_WriteText
	DEVCMD	Node_WriteTexto
	DEVCMD	Node_FlushSer
	DEVCMD	Node_WriteSerLen
	DEVCMD	Node_ReadSerLen
	DEVCMD	Node_QuitLogin
	DEVCMD	Node_ReadSer
	DEVCMD	Node_LASTCOMM

	; private nodecommands
	DEVINIT	$8000
	DEVCMD	Node_Reloaduser
	DEVCMD	Node_Eject
	DEVCMD	Node_Gotosleep
	DEVCMD	Node_Wakeupagain
	DEVCMD	Node_Killuser
	DEVCMD	Node_TmpSysop
	DEVCMD	Node_Show
	DEVCMD	Node_Hide
	DEVCMD	Node_chat
	DEVCMD	Node_ShowUser
	DEVCMD	Node_Shutdown
	DEVCMD	Node_GetRegs
	DEVCMD	Node_InitModem
	DEVCMD	Node_ReleasePort
	DEVCMD	Node_OffHook
	DEVCMD	Node_LASTPRIVCOMM

	;NetCommands
	DEVINIT	0
	DEVCMD	Net_DoLogin
	DEVCMD	Net_LASTCOMM

	DEVINIT	0
	DEVCMD	OK
	DEVCMD	Timeout
	DEVCMD	NoCarrier
	DEVCMD	Thrownout

	STRUCTURE	Nodenode,LN_SIZE	; node
	ULONG		Nodeusernr
	UWORD		Nodenr
	UWORD		Nodestatus
	UBYTE		Nodedivstatus		; se under
	UBYTE		NodeECstatus		; MNP eller V32bis
	ULONG		NodesubStatus
	ULONG		Nodespeed
	ULONG		NodeTask
	ULONG		InterMsgSig
	UWORD		InterMsgread
	UWORD		InterMsgwrite
	NameT		Nodeuser
	NameT		NodeuserCityState
	STRUCT		NodeStatusText,120
	SEven
	STRUCT		InterNodeMsg,InterNodeMsgsiz*MaxInterNodeMsg
	SEven
	STRUCT		Nodemsg,ABBSmsg_SIZE
	ULONG		Nodenode_alloc
	LABEL		Nodenode_SIZEOF

	BITDEF	NDS,Notavail,0
	BITDEF	NDS,Stealth,1
	BITDEF	NDS,WaitforChatCon,2

	BITDEF	NECS,MNP,0
	BITDEF	NECS,V42BIS,1
	BITDEF	NECS,UPDATED,2

	STRUCTURE	intermsg,0
	UBYTE		i_type
	UBYTE		i_pri		; pri != 0 => ignorer MF verdi
	UWORD		i_franode
	ULONG		i_usernr
	ULONG		i_usernr2
	NameT		i_Name
	NameT		i_Name2
	SEven
	UWORD		i_conf
	ULONG		i_msgnr
	LABEL		intermsg_sizeof
i_msg	equ		i_usernr

	STRUCTURE	RexxParam,0
	ULONG		rx_NumParam
	APTR		rx_ptr1
	APTR		rx_ptr2
	APTR		rx_ptr3
	APTR		rx_ptr4
	APTR		rx_ptr5
	LABEL		rx_sizeof

	STRUCTURE	UserRecord,0
	NameT		Name		;* First AND Last name     *
	UBYTE		pass_10
	ULONG		Usernr		;* User number		   *
	PassT		Password	;* users password          *
	NameT		Address		;* Street address          *
	NameT		CityState	;* City/State              *
	TelNoT		HomeTelno	;* home telephone          *
	TelNoT		WorkTelno	;* work telephone          *
	UBYTE		pass_11
	UWORD		TimeLimit	;* daily time limit        *
	UWORD		FileLimit	;* daily file time limit   *
	UWORD		PageLength	;* page length             *
	UBYTE		Protocol	;* download protocol       *
	UBYTE		Charset		;* character set           *
	UBYTE		ScratchFormat
	UBYTE		XpertLevel
	UWORD		Userbits	;* See bit definitions     *
	STRUCT		ConfAccess,(MaxConferences*1)
	SEven
	STRUCT		UserScript,Sizeof_loginscript	;* Arexx script to be run at login *
	LONG		ResymeMsgNr
	UBYTE		MessageFilterV
	UBYTE		GrabFormat
	UWORD		u_ByteRatiov			; i bytes
	UWORD		u_FileRatiov			; i filer

	LABEL		u_startsave
	UWORD		Uploaded	;* files uploaded          *
	UWORD		Downloaded	;* files downloaded        *
	LONG		KbUploaded
	LONG		KbDownloaded
	UWORD		TimesOn		;* number of times on      *
	STRUCT		LastAccess,ds_SIZEOF
					;* last time on system     *
	UWORD		TimeUsed	;* minutes on system today *
	UWORD		MsgsLeft	;* messages entered	   *
	ULONG		MsgsRead	;* messages read	   *
	ULONG		Totaltime	;* total time on system	   *
	STRUCT		Conflastread,MaxConferences*4
					;* zero is for MAIN	   *
	LONG		NFday		;* last day user took Newfiles *
	UWORD		FTimeUsed	;* file min's on system today *
	UWORD		Savebits
	ULONG		MsgaGrab
	STRUCT		u_reserved2,6
	LABEL		u_endsave
	LABEL		UserRecord_SIZEOF

	BITDEF	ACC,Read,0
	BITDEF	ACC,Write,1
	BITDEF	ACC,Upload,2
	BITDEF	ACC,Download,3
	BITDEF	ACC,FileVIP,4
	BITDEF	ACC,Invited,5
	BITDEF	ACC,Sigop,6
	BITDEF	ACC,Sysop,7

	BITDEF	USER,Killed,0		;* user is dead		   *
	BITDEF	USER,FSE,1		;* use FSE		   *
	BITDEF	USER,ANSIMenus,2	;* user wants ansi menus
	BITDEF	USER,ColorMessages,3	;* user wants color in messages
	BITDEF	USER,G_R,4		;* use G&R protocol	   *
	BITDEF	USER,KeepOwnMsgs,5	;* Mark written messages   *
	BITDEF	USER,ANSI,6
	BITDEF	USER,ClearScreen,7
	BITDEF	USER,RAW,8
	BITDEF	USER,NameAndAdress,9
	BITDEF	USER,Filter,10
	BITDEF	USER,SendBulletins,11

	BITDEF	SAVEBITS,FSEOverwritemode,0
	BITDEF	SAVEBITS,FSEXYon,1
	BITDEF	SAVEBITS,FSEAutoIndent,2
	BITDEF	SAVEBITS,ReadRef,3
	BITDEF	SAVEBITS,LostDL,4
	BITDEF	SAVEBITS,Dontshowconfs,5
	BITDEF	SAVEBITS,Browse,6

	STRUCTURE	MessageRecord,0
	ULONG		Number		;* Message Number	   *
	UBYTE		MsgStatus	;* Message Status	   *
	UBYTE		Security	;* Message security	   *
	ULONG		MsgFrom		;* user number	 	   *
	ULONG		MsgTo		;* Ditto (-1=ALL)	   *
	NameT		Subject		;* subject of message	   *
	UBYTE		MsgBits		;* Misc bits		   *
	STRUCT		MsgTimeStamp,ds_SIZEOF
					;* time entered		   *
	ULONG		RefTo		;* refers to		   *
	ULONG		RefBy		;* first answer		   *
	ULONG		RefNxt		;* next in this thread	   *
	WORD		NrLines		;* number of lines, negative if net names in message body *
	UWORD		NrBytes		;* number of bytes	   *
	ULONG		TextOffs	;* offset in text file 	   *
	LABEL		MessageRecord_SIZEOF

	BITDEF	MSTAT,NormalMsg,0
	BITDEF	MSTAT,KilledByAuthor,1
	BITDEF	MSTAT,KilledBySysop,2
	BITDEF	MSTAT,KilledBySigop,3
	BITDEF	MSTAT,Moved,4
	BITDEF	MSTAT,MsgRead,6		;* read by receiver	   *
	BITDEF	MSTAT,Dontshow,7

	BITDEF	SEC,SecNone,0
	BITDEF	SEC,SecPassword,1
	BITDEF	SEC,SecReceiver,2

	BITDEF	MsgBits,FromNet,0

	STRUCTURE	ConfigRecord,0
	ULONG		Users		; number of users registerd					0
	ULONG		MaxUsers	; max number of users registred. (Antall logentrys,nrentrys)	4
	NameT		BaseName	; name of this BBS						8
	NameT		SYSOPname									39
	SEven												70
	ULONG		SYSOPUsernr									70
	PassT		SYSOPpassword	; brukes ikke enda						74
	SEven												83
	UWORD		MaxLinesMessage									84
	UWORD		ActiveConf	; limited to MaxConferences					86
	UWORD		ActiveDirs	; limited to MaxFileDirs					88
	UWORD		NewUserTimeLimit
	UWORD		SleepTime
	PassT		ClosedPassword	; brukes ikke enda
	SEven
	UBYTE		DefaultCharSet
	UBYTE		Cflags
	UWORD		NewUserFileLimit
	STRUCT		ConfNames,MaxConferences*Sizeof_NameT
	STRUCT		ConfSW,MaxConferences*1
	SEven
	STRUCT		ConfOrder,MaxConferences*1
	SEven
	STRUCT		ConfDefaultMsg,MaxConferences*4
	STRUCT		DirNames,MaxFileDirs*Sizeof_NameT
	SEven
	STRUCT		FileOrder,MaxFileDirs*1
	SEven
	STRUCT		ConfBullets,MaxConferences*1
	SEven
	STRUCT		DirPaths,MaxFileDirs*Sizeof_NameT
	SEven
	STRUCT		ConfMaxScan,MaxConferences*2
	UWORD		ByteRatiov			; i bytes
	UWORD		FileRatiov			; i filer
	UWORD		MinULSpace			; i KB
	UBYTE		Cflags2
	UBYTE		pad_a123
	ULONG		pad_2344
	ULONG		pad_2343
	PassT		dosPassword
	STRUCT		cnfg_empty,13
	LABEL		ConfigRecord_SIZEOF

;confSW	:
	BITDEF	CONFSW,ImmRead,0
	BITDEF	CONFSW,ImmWrite,1
	BITDEF	CONFSW,PostBox,2
	BITDEF	CONFSW,Private,3
	BITDEF	CONFSW,VIP,4
	BITDEF	CONFSW,Resign,5
	BITDEF	CONFSW,Network,6
	BITDEF	CONFSW,Alias,7

;Cflags
	BITDEF	Cflags,Lace,0
	BITDEF	Cflags,8Col,1
	BITDEF	Cflags,Download,2
	BITDEF	Cflags,Upload,3
	BITDEF	Cflags,Byteratio,4
	BITDEF	Cflags,Fileratio,5
	BITDEF	Cflags,AllowTmpSysop,6
	BITDEF	Cflags,UseASL,7

;Cflags2
	BITDEF	Cflags,NoGet,0
	BITDEF	Cflags,CacheFL,1

	STRUCTURE	NodeRecord,0
	UBYTE		NodeRecord_pad
	UBYTE		CommsPort		; 0 = local, else port = n-1
	UBYTE		ConnectWait		; max time to wait from ring to connect
	UBYTE		NodeSetup		; div bits for setup
	ULONG		MinBaud			; minimum baud to accept for this node
	UWORD		Setup			; See Bit definitions below
	ULONG		NodeBaud		; baud to use between modem-machine
	ModemStrT	Serialdevicename
	ModemStrT	ModemInitString
	ModemSStrT	ModemAnswerString
	ModemSStrT	ModemOffHookString
	ModemSStrT	ModemOnHookString
	ModemSStrT	ModemCallString
	ModemSStrT	ModemRingString
	ModemSStrT	ModemConnectString
	ModemSStrT	ModemOKString
	ModemSStrT	ModemATString
	ModemSStrT	ModemNoCarrierString
	SEven
	STRUCT		HourMaxTime,24		; Maximum allowed time this hour
	STRUCT		HourMinWait,24		; Minimum time between calls this hour
	NameT		PublicScreenName	; abbs/wb(default)/any
	NameT		HoldPath
	NameT		TmpPath			; path for this nodes tmpdir (must end in a : or /)
	NameT		Font			; name for this nodes font (must end in a : or /)
	UWORD		FontSize		; font size
	UWORD		win_big_x		; x pos for normal window
	UWORD		win_big_y		; y pos for normal window
	UWORD		win_big_height		; height for normal window
	UWORD		win_big_width		; width for normal window
	UWORD		win_tiny_x		; x pos for tiny window
	UWORD		win_tiny_y		; y pos for tiny window
	LABEL		NodeRecord_SIZEOF

;	BITDEF	SETUP,XonXoff,0			; NOT USE
	BITDEF	SETUP,RTSCTS,1
	BITDEF	SETUP,Lockedbaud,2
	BITDEF	SETUP,SimpelHangup,3
	BITDEF	SETUP,NullModem,4
	BITDEF	SETUP,NoSleepTime,5

	BITDEF	NodeSetup,TinyMode,0
	BITDEF	NodeSetup,DontShow,1
	BITDEF	NodeSetup,BackDrop,2
	BITDEF	NodeSetup,UseABBScreen,3
;	BITDEF	NodeSetup,,4
;	BITDEF	NodeSetup,,5

	IFD	OLDNodeRecord

	STRUCTURE	NodeRecord,0
	UWORD		CommsPort
	UWORD		tinymode
	UWORD		OpenModemAt
	UWORD		NoCarrierPause
	UWORD		Setup		; See Bit definitions below
	ULONG		NodeBaud
	ModemStrT	Serialdevicename
	ModemStrT	ModemInitString
	ModemSStrT	ModemAnswerString
	ModemSStrT	ModemOffHookString
	ModemSStrT	ModemOnHookString
	ModemSStrT	ModemCallString
	ModemSStrT	ModemRingString
	ModemSStrT	ModemConnectString
	ModemSStrT	ModemOKString
	ModemSStrT	ModemATString
	LABEL		NodeRecord_SIZEOF

	BITDEF	SETUP,XonXoff,0
	BITDEF	SETUP,RTSCTS,1
	BITDEF	SETUP,Lockedbaud,2
	BITDEF	SETUP,SimpelHangup,3

	ENDC

	STRUCTURE Fileentry,0
	FileName	Filename
	SEven
	UWORD		Filestatus
	ULONG		Fsize
	ULONG		Uploader
	ULONG		PrivateULto		; Både konf nr og brukr nr.
	ULONG		AntallDLs
	ULONG		Infomsgnr
	STRUCT		ULdate,ds_SIZEOF
	FileDescription	Filedescription
	SEven
	LABEL	Fileentry_SIZEOF		; = $5c

Fileentry_SIZEOF_old = $5d

;filestatus
	BITDEF	FILESTATUS,PrivateUL,0
	BITDEF	FILESTATUS,PrivateConfUL,1
	BITDEF	FILESTATUS,Filemoved,2
	BITDEF	FILESTATUS,Fileremoved,3
	BITDEF	FILESTATUS,FreeDL,4
	BITDEF	FILESTATUS,Selected,5		; for use in browse menu

	STRUCTURE	fileentryheader,0
	STRUCT		fl_hash,72*4
	APTR		first_file
	LABEL		fileentryheader_sizeof

	STRUCTURE mem_Fileentry,0
	STRUCT	mem_fentry,Fileentry_SIZEOF	; actual file entry record, same as on disk
	ULONG	mem_filefilenr			; Filenr on disk [0 - n>
	ULONG	mem_filenr			; Filenr in memory [0 - n>
	ULONG	mem_fnext			; next sequential file entry
	ULONG	mem_fnexthash			; next file entry on this hash key
	LABEL	mem_Fileentry_SIZEOF

	STRUCTURE Log_entry,0
	ULONG	l_RecordNr			; Hvilken record i userfile har han ? (nummer 0,1 osv)
	ULONG	l_UserNr
	NameT	l_Name
	SEven
	UWORD	l_UserBits			; Er brukeren død ??
	LABEL	Log_entry_SIZEOF

	STRUCTURE Mainmemory,0
	STRUCT	config,ConfigRecord_SIZEOF
	UWORD	Nodes		; number of nodes running
	UWORD	MainBits
	ULONG	MaxNumLogEntries
	ULONG	NrTabelladr
	ULONG	LogTabelladr
	ULONG	flpool
	STRUCT	txtbuffer,80
	STRUCT	txt2buffer,80
	STRUCT	keys,4*10
	ULONG	keyfile
	ULONG	userfile
	STRUCT	Mainmsg,ABBSmsg_SIZE
	STRUCT	Filedirfiles,MaxFileDirs*4
	STRUCT	MsgHeaderfiles,MaxConferences*4
	STRUCT	MsgTextfiles,MaxConferences*4

;	STRUCT	NrTabell,0		; denne har dynamisk størrelse
					; nrTabell(usernr) -> LogTabell
;	STRUCT	LogTabell		; dynamisk size og plaseringen
	LABEL	Mainmemory_SIZEOF

	BITDEF	MainBits,SysopNotAvail,0

	STRUCTURE	ParagonMsg,MN_SIZE
	UWORD		p_Command
	UWORD		p_Data
	STRUCT		p_string,72
	APTR		p_msg
	APTR		p_config
	UWORD		p_carrier
	LABEL		ParagonMsg_SIZE

	ENDC	; BBS_I
