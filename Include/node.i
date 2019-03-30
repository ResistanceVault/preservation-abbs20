	IFND	NODE_I
NODE_I	SET	1
*****************************************************************
*			node variabler				*
*****************************************************************

	IFND BBS_I
	include 'bbs.i'
	ENDC	; BBS_I

	IFND XPR_I
	include 'xpr.i'
	ENDC	; XPR_I

	STRUCTURE	ramblocks,0
	BYTE		con_tegn
	BYTE		Divmodes	; se def under
	IFND DEMO
	BYTE		ser_tegn
	ELSEIF
	BYTE		pad_1241
	ENDC
	BYTE		tegn_fra

	UWORD		loginmin
	UWORD		joinfilemin
	LONG		lastdayonline
	UWORD		lastminonline

	LONG		oldcliname
	LONG		filereqadr
	LONG		windowadr
	LONG		pubscreenadr
	LONG		fontadr
	LONG		windowtitleptr
	LONG		showuserwindowadr
	LONG		creadreq
	LONG		cwritereq
	IFND DEMO
	LONG		sreadreq
	LONG		swritereq
	ENDC
	LONG		timer1req
	LONG		timer2req

	LONG		nodestack
	LONG		waitbits
	LONG		gotbits
	LONG		consigbit
	IFND DEMO
	LONG		sersigbit
	ENDC
	LONG		intsigbit
	LONG		showwinsigbit
	LONG		timer1sigbit
	LONG		timer2sigbit
	LONG		intersigbit
	LONG		publicsigbit
	LONG		rexxsigbit
	LONG		intmsgport
	LONG		msg
	LONG		HighMsgQueue
	LONG		curprompt
	LONG		ULfilenamehack
tmpstore	equ	ULfilenamehack
	LONG		ParamPass
	LONG		tmpval
	LONG		SerTotOut

	LONG		infoblock
	BYTE		readcharstatus
	BYTE		dosleepdetect
	BYTE		tmpsysopstat
	IFND DEMO
	BYTE		RealCommsPort
	ELSEIF
	BYTE		pad_142
	ENDC
	BYTE		batch
	BYTE		cursorpos

	LONG		currentmsg
	UWORD		menunr
	UWORD		confnr
	UWORD		linesleft
	BYTE		in_waitforcaller
	BYTE		readlinemore
	BYTE		ShutdownNode
	BYTE		active
	BYTE		activesysopchat
	BYTE		DoDiv
	UWORD		Historyoffset

	IFND DEMO
	UWORD		cpsrate
	ENDC
	UWORD		intextchar
	UWORD		outtextchar
	UWORD		outtextbufferpos

	BYTE		readingpassword
	BYTE		userok
	BYTE		Tinymode
	BYTE		warningtineindex

	UWORD		OldTimelimit
	UWORD		OldFilelimit
	UBYTE		NodeError
	UBYTE		DlUlstatus
	UWORD		NodeNumber
	ULONG		FrontDoorMsg
	ULONG		nodeport
	ULONG		rexxport
	ULONG		nodepublicport
	ULONG		nodenoden
	ULONG		msgmemsize
	APTR		tmpmsgmem
	ULONG		exallctrl
	APTR		node_menu
	APTR		visualinfo
	UBYTE		FSEditor
	UBYTE		outlines
	UBYTE		intersigbitnr
	UBYTE		serescstat
	UBYTE		lastchar
	UBYTE		noglobal
	UWORD		tmsgsread
	UWORD		tmsgsdumped
	UWORD		minchat
	UWORD		minul
	UWORD		tmpword
	UWORD		PrevNodestatus
	ULONG		PrevNodesubStatus
	ULONG		waitforcallerstack
	ULONG		pad34234
	APTR		Tmpusermem
	APTR		Loginlastread
	STRUCT		windowsizepos,2*8		; top,left,width,height * 2 (zoom også)
	STRUCT		lastchartime,ds_SIZEOF
	STRUCT		tmpdatestamp,ds_SIZEOF
	STRUCT		tmpnodestatustext,24
	STRUCT		readlinebuffer,80
	STRUCT		intextbuffer,82
	STRUCT		outtextbuffer,82*2
	STRUCT		conouttextbuffer,82*2
	STRUCT		transouttextbuffer,82*4
	STRUCT		Nodemem,NodeRecord_SIZEOF
	SEven
	STRUCT		logfilename,24
	STRUCT		Publicportname,20
	STRUCT		Paragonportname,16			; brukes bare når paragondoors kjøres
tmpwhilenotinparagon	equ	Paragonportname
	UWORD		pad_234234
	UBYTE		Nodetaskname_BCPL
	STRUCT		Nodetaskname,59
	STRUCT		pastetext,80
	STRUCT		tmpnametext,80
	STRUCT		tmpmsgheader,MessageRecord_SIZEOF
	STRUCT		tmptext,80
	STRUCT		maintmptext,80
	STRUCT		tmpfileentry,Fileentry_SIZEOF
	STRUCT		infoblockmem,fib_SIZEOF+2
tmplargestore	equ	infoblockmem
	STRUCT		xpriomem,XPR_IO_SIZEOF
	STRUCT		dummy,100
tmptext2	= dummy
	STRUCT		historybuffer,1024
	STRUCT		msgqueue,4*(NumMsgNrInQueue+1)
	STRUCT		prevqueue,4*52
	LABEL		CU		;UserRecord_SIZEOF

	LABEL		ramblocks_SIZE	; + UserRecord_SIZEOF*2+maxconferences*4

	BITDEF	DIV,QuickMode,0
	BITDEF	DIV,StealthMode,1
	BITDEF	DIV,InNewuser,2
	BITDEF	DIV,Browse,3
	BITDEF	DIV,InBrowse,4
	BITDEF	DIV,InNetLogin,5

	BITDEF	DoDiv,HideNode,0
	BITDEF	DoDiv,NoInit,1
	BITDEF	DoDiv,Sleep,2
	BITDEF	DoDiv,ExitWaitforCaller,3

	STRUCTURE	findfilestruct,0
	STRUCT		ff_infoblockmem,fib_SIZEOF
	ULONG		ff_lock
	STRUCT		ff_pattern,160
	STRUCT		ff_path,100
	STRUCT		ff_full,160
	LABEL		findfilestruct_sizeof

Net_FromCode	equ	$1e	 ; From		= Terminert av newline	*
Net_ToCode	equ	$1f	 ; To		= Terminert av newline	*
Net_SubjCode	equ	$1d	 ; Subject	= Terminert av newline	*
Net_ExtDCode	equ	$1c	 ; ExtData	= Terminert av $FF byte	*

	IFNE	Nodetaskname_BCPL&3
	FAIL	"Nodetaskname_BCPL er ikke på 4 byte boundry"
	ENDC


	ENDC	; NODE_I
