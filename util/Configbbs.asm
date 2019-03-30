	include	'dabbs:include/first.i'

	include	'exec/types.i'
	include	'exec/memory.i'
	include	'libraries/dos.i'
	include	'intuition/intuition.i'

;debug = 1

	include	'asm.i'
	include	'bbs.i'

	XDEF	_SysBase

	section kode,code

;ToDo :
; fikse slik at man kan forrandre navn på conf'er og dir'er

start	move.l	4,a6
	move.l	a6,_SysBase
	moveq.l	#0,d7			; full setup eller foradre (= 0)
	moveq.l	#0,d6			; conf er aktiv
	openlib	dos
	openlib	int
	moveq.l	#0,d0
	lea	tmpportname,a0
	bsr	CreatePort		; setter opp vår reply port
	lea	noporttext,a0
	move.l	d0,port
	beq	error
	lea	msg,a0			; Fyller i msg
	move.l	d0,MN_REPLYPORT(a0)
	move.l	#ConfigRecord_SIZEOF,d0 ; allokerer config minne
	move.l	#MEMF_CLEAR,d1
	jsrlib	AllocMem
	lea	nomemtext,a0
	move.l	d0,mem
	beq	error
	move.l	d0,MainBase
;	bsr	getconfig		; henter inn config'en
;	lea	noabbstext,a0
;	bmi	error			; ingen msg port
;	bne.s	1$			; abbs er konfigurert
	moveq.l	#1,d7			;
	bsr	setupnewconfig
	lea	Worktlf,a0		; vi er ikke konfigurert, saa
	moveq.l	#0,d0			; vi tar og
	move.l	d0,(a0)			; slår av "fil requestor'en"
	lea	IText18,a0
	lea	IText20,a1
	move.l	a1,it_NextText(a0)
	lea	MenuItem1,a0		; Disabler Load'en
	and.w	#~ITEMENABLED,mi_Flags(a0)
	lea	News,a0
	and.w	#~GFLG_DISABLED,gg_Flags(a0)
	lea	Post,a0
	and.w	#~GFLG_DISABLED,gg_Flags(a0)
	lea	Userinfo,a0
	and.w	#~GFLG_DISABLED,gg_Flags(a0)
	lea	Fileinfo,a0
	and.w	#~GFLG_DISABLED,gg_Flags(a0)
	bra.s	2$
1$	move.l	SYSOPUsernr(MainBase),d0
	lea	userrec,a0		; henter inn sysop'en
	bsr	loadusernr
	lea	nosysoptext,a0
	beq	error
	bsr	setupgadgets
2$	move.l	intbase,a6		; Opp med vindu !
	lea	NewWindowStructure1,a0
	jsrlib	OpenWindow
	lea	nowindowtext,a0
	move.l	d0,winadr
	beq	error
	move.l	d0,a0
	move.l	wd_RPort(a0),a0		; ut med tekst !
	lea	IntuiTextList1,a1
	moveq.l	#0,d0
	moveq.l	#0,d1
	jsrlib	PrintIText
	move.l	winadr,a0		; Opp med meny
	lea	MenuList1,a1
	jsrlib	SetMenuStrip
	lea	nomenutext,a0
	tst.l	d0
	beq	error
	move.b	#1,menusta
	move.l	winadr,a0
	move.l	wd_UserPort(a0),msgport
	lea	GadgetList1,a0		; aktiviserer første gadgeten.
	move.l	winadr,a1
	sub.l	a2,a2
	move.l	intbase,a6
	jsrlib	ActivateGadget
	move.l	_SysBase,a6

vent	move.l	msgport,a0
	jsrlib	WaitPort
	tst.l	d0
	beq.s	vent
	tst.w	titlech
	beq.s	7$
	lea	NewWindowName1,a0	; setter tilbake orginal tittel
	moveq.l	#0,d0			; ikke noen blinking
	bsr	title
	move.w	#0,titlech
7$	move.l	msgport,a0
	jsrlib	GetMsg
	tst.l	d0
	beq.s	vent
	move.l	d0,a1
	move.l	im_Class(a1),d0
	cmp.l	#MENUPICK,d0
	beq	2$
	cmp.l	#GADGETUP,d0
	beq.s	1$
4$	jsrlib	ReplyMsg
	bra.s	vent

1$	move.l	im_IAddress(a1),a0
	move.w	gg_GadgetID(a0),d2
	beq.s	4$
	jsrlib	ReplyMsg
	tst.w	d2
	bmi.s	8$			; negative = spesielle
	sub.w	#1,d2
	asl.w	#2,d2
5$	lea	activetabell,a0		; aktiviserer neste gadget
	move.l	0(a0,d2.w),a0
	move.w	gg_Flags(a0),d0
	and.w	#GFLG_DISABLED,d0	; bare hvis den ikke er disabl'a
	beq.s	6$
	addq.l	#4,d2
	cmp.w	#17*4,d2
	bcs.s	5$
	moveq.l	#0,d2
	bra.s	5$

; d2 = gadget id.
8$	lea	specialjumptable,a0
	neg.w	d2
	sub.w	#1,d2
	lsl.w	#2,d2
	move.l	0(a0,d2.w),a0
	jsr	(a0)
	bra	vent

6$	move.l	winadr,a1
	sub.l	a2,a2
	move.l	intbase,a6
	jsrlib	ActivateGadget
	move.l	_SysBase,a6
	bra	vent

2$	move.w	im_Code(a1),-(a7)
	jsrlib	ReplyMsg
	move.w	(a7)+,d0
3$	cmp.w	#MENUNULL,d0
	beq	vent
	move.w	d0,d1
	and.w	#$1f,d0			; d0 er nå menu num
	bne.s	30$			; ikke 0
	move.w	d1,d0
	lsr.w	#5,d0
	and.w	#$3f,d0			; d0 er nå menu item
	bne.s	31$			; ikke item 0
	bsr	getconfig		; load config
	lea	noabbstext,a0
	bmi	error			; ingen msg port
	bsr	setupgadgetsspes
	lea	nomenutext,a0
	beq	error
	bra	vent
31$ 	cmp.w	#1,d0			; item 01 ?
	beq	lagre
	cmp.w	#2,d0			; item 02 ?
	beq	ut			; Ja
	bra	vent

30$	cmp.w	#1,d0			; menu num 1 ?
	bne	vent			; nei
	move.w	d1,d0
	lsr.w	#5,d0
	and.w	#$3f,d0			; d0 er nå menu item
	cmp.w	#2,d0			; item 12 ?
	bne	vent			; nei
	move.w	d1,d0
	lsr.w	#8,d0
	lsr.w	#3,d0
	and.w	#$1f,d0			; d0 er nå sub item (0-2)
	cmp.w	#2,d0
	bhi	vent			; ukjennt sub item
	move.w	d0,-(a7)
	move.l	intbase,a6
	move.l	winadr,a0		; fjerner meny
	jsrlib	ClearMenuStrip
	move.b	#0,menusta
	move.w	(a7)+,d0
	and.l	#$ffff,d0
	move.b	d0,charset
	lea	charsettext,a0
	lsl.l	#2,d0			; beregner fremm plassen til
	add.l	d0,a0			; tegnsett plassen
	lea	ITextText6+8,a1		; strcopy subitem13{1-3}'s tekst
	moveq.l	#3,d0			; inn i menyitem 13's tekst,
	bsr	strcopymaxlen		; dvs "Charset [xxx]"
	move.l	winadr,a0		; Opp med meny
	lea	MenuList1,a1
	jsrlib	SetMenuStrip
	move.l	_SysBase,a6
	tst.l	d0
	lea	nomenutext,a0
	beq	error
	move.b	#1,menusta
	bra	vent

lagre	bsr	sjekkinput
	beq	vent
	bsr	saveconfig
	bmi.s	ut		; ferdig (ikke fullt oppsett)
	beq	vent
	bsr	createconfs
	bmi.s	ut
	beq	vent
	bsr	createdirs
	bmi.s	ut
	beq	vent
	bsr	createsysop
	bmi.s	ut
	beq	vent
	bra.s	ut

error	bsr	writedostext
ut	bsr	cleanup
	closlib	int
no_int	closlib	dos
no_dos	rts

sjekkinput
	lea	Boardname,a0
	bsr	20$
	beq	9$
	lea	Sysopname,a0
	bsr	30$
	beq	9$
	tst.l	d7			; fullt settup
	beq.s	1$			; nei, da tillater vi tomt her.
	lea	SysopPassword,a0
	bsr	10$
	beq	9$
1$	lea	SysopAddress,a0
	bsr	20$
	beq	9$
	lea	postal,a0
	bsr	20$
	beq	9$
	lea	Hometlf,a0
	bsr	20$
	beq	9$
	lea	Worktlf,a0
	bsr	20$
	beq	9$
	lea	maxmsglines,a0
	moveq.l	#100,d0			; min verdi
	bsr	40$
	beq	9$
	lea	newtime,a0
	moveq.l	#5,d0			; min verdi
	bsr	40$
	beq.s	9$
	lea	sleeptime,a0
	moveq.l	#1,d0			; min verdi
	bsr	40$
	beq.s	9$
	lea	newfiletime,a0
	moveq.l	#0,d0			; min verdi
	bsr	40$
	beq.s	9$
	lea	News,a0
	bsr	10$
	beq.s	9$
	lea	Post,a0
	bsr	10$
	beq.s	9$
	lea	Userinfo,a0
	bsr	10$
	beq.s	9$
	lea	Fileinfo,a0
	bsr	10$
	beq.s	9$
	lea	byteratio,a0
	moveq.l	#0,d0			; min verdi
	bsr	40$
	beq.s	9$
	lea	fileratio,a0
	moveq.l	#0,d0			; min verdi
	bsr	40$
	beq.s	9$
	lea	minspace,a0
	moveq.l	#0,d0			; min verdi
	bsr	40$
	beq.s	9$
	clrz
9$	rts

10$	bsr	60$
	move.b	(a1)+,d0	; sjekker om det er noe i en string, og
	beq.s	50$		; om den inneholder spaces
11$	cmp.b	#' ',d0
	beq.s	50$
	move.b	(a1)+,d0
	bne.s	11$
	clrz
	rts

20$	bsr	60$
	tst.b	(a1)
	beq.s	40$
	rts

30$	bsr	60$
	move.b	(a1)+,d0	; sjekker at stringen er av formen :
	beq.s	50$		; "<tekst> <tekst>"
	cmp.b	#' ',d0
	beq.s	50$
31$	move.b	(a1)+,d0
	beq.s	50$
	cmp.b	#' ',d0
	bne.s	31$
	move.b	(a1)+,d0
	beq.s	50$
32$	cmp.b	#' ',d0
	beq.s	50$
	move.b	(a1)+,d0
	bne.s	32$
	clrz
	rts

40$	push	a0/d0
	bsr	60$
	move.l	a1,a0
	bsr	atoi
	bmi.s	49$
	pop	a0/d1
	cmp.l	d0,d1			; sjekker mot min verdi
	bhi.s	50$			; for liten verdi
41$	clrzn
	rts
49$	pop	a0/d0
;	bra.s	50$

50$	move.l	a0,a1
	lea	wrongdatatext,a0
	bra	blinkandactivate

60$	move.l	gg_SpecialInfo(a0),a1	; henter ut si bufferen til gadgeten
	move.l	si_Buffer(a1),a1
	rts

saveconfig
	push	a2/a3
	bsr	getabbsconfig
	move.l	a0,a3
	bmi	9$			; finner ikke abbs
	bne.s	1$			; ikke fullt oppsett
	bsr	10$			; Fyller i vår configmem
	bmi	8$			; error
	move.l	a3,a1
	move.l	MainBase,a0
	move.l	#ConfigRecord_SIZEOF,d0	; Kopierer over hele config'en
	bsr	memcopylen
	clrzn
	bra	9$

1$	bsr	10$			; tolker gadget'er
	bmi	8$

	lea	SYSOPname(a3),a0
	lea	SysopnameSIBuff,a1
	bsr	namechange
	lea	cantrenysoptext,a0
	beq	7$
	move.l	SYSOPUsernr(MainBase),d0
	lea	userrec,a0		; henter inn sysop'en igjen
	bsr	loadusernr
	lea	nosysoptext,a0
	beq	7$

; vanskelig ..
;	STRUCT		ConfNames,MaxConferences*Sizeof_NameT
;	STRUCT		DirNames,MaxFileDirs*Sizeof_NameT

	lea	userrec,a2			; lagrer sysop med ny adresse osv.
	lea	SysopAddressSIBuff,a0
	lea	Address(a2),a1
	bsr	strcopy
	lea	postalSIBuff,a0
	lea	CityState(a2),a1
	bsr	strcopy
	lea	HometlfSIBuff,a0
	lea	HomeTelno(a2),a1
	bsr	strcopy
	lea	WorktlfSIBuff,a0
	lea	WorkTelno(a2),a1
	bsr	strcopy
	move.l	a2,a0
	move.l	Usernr(a2),d0
	bsr	saveusernr
	lea	cantsasysoptext,a0
	beq	7$
	lea	BaseName(MainBase),a0		; kopierer over til abbs's config
	lea	BaseName(a3),a1			; struktur.
	bsr	strcopy
	lea	SYSOPpassword(MainBase),a0
	lea	SYSOPpassword(a3),a1
	moveq.l	#Sizeof_PassT,d0
	bsr	strcopymaxlen
	move.w	MaxLinesMessage(MainBase),MaxLinesMessage(a3)
	move.w	NewUserTimeLimit(MainBase),NewUserTimeLimit(a3)
	move.w	SleepTime(MainBase),SleepTime(a3)
	move.b	DefaultCharSet(MainBase),DefaultCharSet(a3)
	move.b	Cflags(MainBase),Cflags(a3)
	move.w	NewUserFileLimit(MainBase),NewUserFileLimit(a3)
	move.w	ByteRatiov(MainBase),ByteRatiov(a3)
	move.w	FileRatiov(MainBase),FileRatiov(a3)
	move.w	MinULSpace(MainBase),MinULSpace(a3)
	lea	4+ConfSW(MainBase),a0
	lea	4+ConfSW(a3),a1
	moveq.l	#MaxConferences*1-4,d0
	bsr	memcopylen
	lea	ConfOrder(MainBase),a0
	lea	ConfOrder(a3),a1
	moveq.l	#MaxConferences*1,d0
	bsr	memcopylen
	lea	FileOrder(MainBase),a0
	lea	FileOrder(a3),a1
	moveq.l	#MaxConferences*1,d0
	bsr	memcopylen
	lea	DirPaths(MainBase),a0
	lea	DirPaths(a3),a1
	move.l	#MaxConferences*Sizeof_NameT,d0
	bsr	memcopylen
	lea	ConfMaxScan(MainBase),a0
	lea	ConfMaxScan(a3),a1
	move.l	#MaxConferences*2,d0
	bsr	memcopylen
	bsr	savemainconfig			; lagrer config
	lea	cantsavcnfitext,a0
	beq.s	7$				; error
	setn
	bra.s	9$
7$	moveq.l	#1,d0
	bsr	title
	move.w	#1,titlech

8$	clrn					; ikke ferdig
	setz					; ikke ut
9$	pop	a2/a3
	rts

10$	push	a2/d2
	move.l	MainBase,a2

	lea	BoardnameSIBuff,a0
	lea	BaseName(a2),a1
	moveq.l	#Sizeof_NameT,d0
	bsr	strcopymaxlen

	lea	SysopnameSIBuff,a0
	lea	SYSOPname(a2),a1
	moveq.l	#Sizeof_NameT,d0
	bsr	strcopymaxlen

	lea	SysopPasswordSIBuff,a0
	lea	SYSOPpassword(a2),a1
	moveq.l	#Sizeof_PassT,d0
	bsr	strcopymaxlen

;	moveq.l	#0,SYSOPUsernr(a2)

	lea	maxmsglinesSIBuff,a0
	bsr	atoi
	bmi	20$				; egentlig umulig, men ...
	move.w	d0,MaxLinesMessage(a2)

	lea	newtimeSIBuff,a0
	bsr	atoi
	bmi	20$				; egentlig umulig, men ...
	move.w	d0,NewUserTimeLimit(a2)

	lea	sleeptimeSIBuff,a0
	bsr	atoi
	bmi	20$				; egentlig umulig, men ...
	move.w	d0,SleepTime(a2)

	move.b	charset,DefaultCharSet(a2)

	move.b	#0,d0
	lea	byteratiobit,a0
	move.b	#CflagsB_Byteratio,d1
	bsr	40$
	lea	fileratiobit,a0
	move.b	#CflagsB_Fileratio,d1
	bsr	40$
	lea	MenuItem4,a0
	move.b	#CflagsB_Lace,d1
	bsr	30$
	lea	MenuItem5,a0
	move.b	#CflagsB_8Col,d1
	bsr	30$
	lea	MenuItem7,a0
	move.b	#CflagsB_Upload,d1
	bsr	30$
	lea	MenuItem8,a0
	move.b	#CflagsB_Download,d1
	bsr	30$
	lea	NewMenuItem1,a0
	move.b	#CflagsB_AllowTmpSysop,d1
	bsr	30$
	lea	NewMenuItem2,a0
	move.b	#CflagsB_UseASL,d1
	bsr	30$
	move.b	d0,Cflags(a2)

	lea	newfiletimeSIBuff,a0
	bsr	atoi
	bmi.s	20$				; egentlig umulig, men ...
	move.w	d0,NewUserFileLimit(a2)

	lea	byteratioSIBuff,a0
	bsr	atoi
	bmi.s	20$				; egentlig umulig, men ...
	move.w	d0,ByteRatiov(a2)

	lea	fileratioSIBuff,a0
	bsr	atoi
	bmi.s	19$				; egentlig umulig, men ...
	move.w	d0,FileRatiov(a2)

	lea	minspaceSIBuff,a0
	bsr	atoi
	bmi.s	20$				; egentlig umulig, men ...
	move.w	d0,MinULSpace(a2)
	clrn
19$	pop	a2/d2
	rts

20$	lea	intererror1text,a0		; egentlig umulig, men amiga .. :-)
	moveq.l	#1,d0
	bsr	title
	move.w	#1,titlech
	setn
	bra.s	19$

30$	move.w	mi_Flags(a0),d2			; setter flagg i d0 avhengig
	and.w	#CHECKED,d2			; av om menyitemet er valgt
	beq.s	39$				; eller ikke
	bset	d1,d0
39$	rts

40$	move.w	gg_Flags(a0),d2			; setter flagg i d0 avhengig
	and.w	#GFLG_SELECTED,d2		; av om gadgeten er valgt
	beq.s	49$				; eller ikke			
	bset	d1,d0
49$	rts

createconfs
	lea	NewsSIBuff,a0
	moveq.l	#CONFSWF_ImmRead,d0
	bsr	10$
	bmi.s	9$
	beq.s	9$
	lea	PostSIBuff,a0
	move.l	#CONFSWF_ImmRead+CONFSWF_ImmWrite+CONFSWF_PostBox,d0
	bsr	10$
	bmi.s	9$
	beq.s	9$
	lea	UserinfoSIBuff,a0
	moveq.l	#CONFSWF_ImmRead+CONFSWF_Resign,d0
	bsr	10$
	bmi.s	9$
	beq.s	9$
	lea	FileinfoSIBuff,a0
	moveq.l	#CONFSWF_ImmRead+CONFSWF_Resign,d0
	bsr	10$
;	bmi.s	9$
;	beq.s	9$
9$	rts

10$	lea	msg,a1			; lager conf
	move.w	#Main_createconference,m_Command(a1)
	move.l	d0,m_Data(a1)
	bsr	upstring
	lea	msg,a1
	move.l	a0,m_Name(a1)
	bsr	handlemsg
	bne.s	11$
	setn
	bra.s	19$
11$	move.l	d0,a0
	cmp.w	#Error_OK,m_Error(a0)	; Alt ok ?
	notz
	bne.s	19$
	lea	cantcrconftext,a0
	bsr	title
	move.w	#1,titlech
	setz
19$	rts

createdirs
	lea	privatename,a0
	bsr	10$
	bmi.s	9$
	beq.s	9$
	lea	uploadname,a0
	bsr	10$
;	bmi.s	9$
;	beq.s	9$
9$	rts

10$	lea	msg,a1			; lager dir
	move.w	#Main_createfiledir,m_Command(a1)
	bsr	upstring
	lea	msg,a1
	move.l	a0,m_Name(a1)
	lea	fildedirpath,a0
	move.l	a0,m_Data(a1)
	bsr	handlemsg
	bne.s	11$
	setn
	bra.s	19$
11$	move.l	d0,a0
	cmp.w	#Error_OK,m_Error(a0)	; Alt ok ?
	notz
	bne.s	19$
	lea	cantcrfdirtext,a0
	bsr	title
	move.w	#1,titlech
	setz
19$	rts

createsysop
	move.l	a2,-(a7)
	lea	userrec,a2
	move.l	a2,a0			; tømmer bufferen først.
	lea	UserRecord_SIZEOF(a2),a1
	moveq.l	#0,d0
1$	move.w	d0,(a0)+
	cmp.l	a0,a1
	bhi.s	1$
	lea	SysopnameSIBuff,a0	; begynner å fylle inn data
	lea	Name(a2),a1
	bsr	strcopy
	IFND	V1.0
	lea	SysopPasswordSIBuff,a0
	move.l	a2,a1
	bsr	insertpasswd
	ELSE
	lea	Password(a2),a1
	bsr	strcopy
	ENDC
	lea	SysopAddressSIBuff,a0
	lea	Address(a2),a1
	bsr	strcopy
	lea	postalSIBuff,a0
	lea	CityState(a2),a1
	bsr	strcopy
	lea	HometlfSIBuff,a0
	lea	HomeTelno(a2),a1
	bsr	strcopy
	lea	WorktlfSIBuff,a0
	lea	WorkTelno(a2),a1
	bsr	strcopy
	lea	ConfAccess(a2),a0
	move.b	#ACCF_Write+ACCF_Read+ACCF_Download+ACCF_Upload+ACCF_FileVIP+ACCF_Sysop,d0
	move.b	d0,(a0)		; Full access i news
	move.b	d0,1(a0)	; i post
	move.b	d0,2(a0)	; i userinfo
	move.b	d0,3(a0)	; .. og i fileinfo
;	move.w	#0,d0			( allerede null)
;	move.w	d0,TimeLimit(a2)	; Sysop har
;	move.w	d0,FileLimit(a2)	; ingen limit
	move.b	DefaultCharSet(MainBase),Charset(a2)
	move.w	#28,PageLength(a2)
	move.w	#SAVEBITSF_ReadRef,Savebits(a2)
	move.b	#1,ScratchFormat(a2)			; setter ARC som default pakker
	lea	msg,a1				; foretar createuser
	move.w	#Main_createuser,m_Command(a1)
	move.l	a2,m_Data(a1)
	lea	Name(a2),a0
	move.l	a0,m_Name(a1)
	bsr	handlemsg
	bne.s	2$
	setn
	bra.s	9$
2$	move.l	d0,a0
	cmp.w	#Error_OK,m_Error(a0)	; Alt ok ?
	notz
	bne.s	9$
	lea	cantcrsysoptext,a0
	bsr	title
	move.w	#1,titlech
	setz
9$	move.l	(a7)+,a2
	rts

;a0 = passord
;a1 = userrecord
insertpasswd
	push	a2
	link.w	a3,#-20
	move.l	a1,a2
	move.l	sp,a1
	pea	(Name,a2)	; navn
	move.l	a0,-(a7)	; passord
	move.l	a1,-(a7)	; buffer
	IFND	_ACrypt
	XREF	_ACrypt
	ENDC
	jsr	_ACrypt
	lea	(12,sp),sp	; fjerner parametrene igjen
	lea	(Password,a2),a1
	move.l	sp,a0
	moveq.l	#Sizeof_PassT+1-1,d0
1$	move.b	(a0)+,(a1)+
	dbf	d0,1$
	move.b	(a0)+,(pass_10,a2)
	move.b	(a0)+,(pass_11,a2)
	unlk	a3
	pop	a2
	rts

filedirbitcode
	lea	filedirbit,a0
	move.w	gg_Flags(a0),d0
	and.w	#GFLG_SELECTED,d0		; prøver de å deselecte oss ?
	beq.s	8$				; ja.. FY.
	lea	confbit,a0			; slår av confbit'et hvis det er på
	move.w	gg_Flags(a0),d0
	and.w	#GFLG_SELECTED,d0
	beq.s	1$
	bsr	toggleselected
1$	moveq.l	#1,d6				; File er aktiv
	bsr	refreshfilreqspes
	bsr	updatesubfil
	bra.s	9$
8$	bsr	toggleselected
9$	rts

confbitcode
	lea	confbit,a0
	move.w	gg_Flags(a0),d0
	and.w	#GFLG_SELECTED,d0		; prøver de å deselecte oss ?
	beq.s	8$				; ja.. FY.
	lea	filedirbit,a0
	move.w	gg_Flags(a0),d0
	and.w	#GFLG_SELECTED,d0
	beq.s	1$
	bsr	toggleselected
1$	moveq.l	#0,d6				; conf er aktiv
	bsr	refreshfilreqspes
	bsr	updatesubfil
	bra.s	9$
8$	bsr	toggleselected
9$	rts

updatesubfil
	move.l	intbase,a6
	lea	CFName,a1
	moveq.l	#5,d0
	move.l	winadr,a0
	jsrlib	RemoveGList
	lea	bigup,a1
	moveq.l	#2,d0
	move.l	winadr,a0
	jsrlib	RemoveGList

	move.b	#0,CFNameSIBuff			; clearer CFName
	move.b	#0,pathSIBuff			; clearer 
	move.b	#0,scanSIBuff			; clearer 
	move.b	#0,BitsSIBuff			; clearer 
	move.b	#0,orderSIBuff			; clearer 

	lea	bigup,a0
	or.w	#GFLG_DISABLED,gg_Flags(a0)	; av med bigup
	lea	bigdown,a0
	or.w	#GFLG_DISABLED,gg_Flags(a0)	; av med bigdown

	lea	path,a0
	or.w	#GFLG_DISABLED,gg_Flags(a0)	; av med path
	lea	scan,a0
	or.w	#GFLG_DISABLED,gg_Flags(a0)	; slår av scan og bits
	lea	Bits,a0
	or.w	#GFLG_DISABLED,gg_Flags(a0)
	lea	order,a0
	or.w	#GFLG_DISABLED,gg_Flags(a0)
	lea	CFName,a0
;	or.w	#GFLG_DISABLED,gg_Flags(a0)

	lea	CFName,a1
	moveq.l	#-1,d0
	moveq.l	#5,d1
	move.l	winadr,a0
	jsrlib	AddGList
	lea	bigup,a1
	moveq.l	#-1,d0
	moveq.l	#2,d1
	move.l	winadr,a0
	jsrlib	AddGList
	move.l	winadr,a1
	lea	CFName,a0
	moveq.l	#5,d0
	jsrlib	RefreshGList
	lea	bigup,a0
	move.l	winadr,a1
	moveq.l	#5,d0
	jsrlib	RefreshGList
	move.l	_SysBase,a6
	rts

; a0 - gadget
toggleselected
	push	a2	
	move.l	intbase,a6
	move.l	a0,a2
	move.l	winadr,a0
	move.l	a2,a1
	moveq.l	#1,d0
	jsrlib	RemoveGList
	move.l	a2,a1
	eor.w	#GFLG_SELECTED,gg_Flags(a1)
	moveq.l	#-1,d0
	moveq.l	#1,d1
	move.l	winadr,a0
	jsrlib	AddGList
	move.l	winadr,a1
	move.l	a2,a0
	moveq.l	#1,d0
	jsrlib	RefreshGList
	move.l	_SysBase,a6
	pop	a2
	rts

bigdowncode
	move.w	#1,d0
	bsr	movedown
	beq.s	9$			; ingen forandring
	bsr	refreshfilreqspes
9$	rts

bigupcode
	move.w	#1,d0
	bsr	moveup
	beq.s	9$			; ingen forandring
	bsr	refreshfilreqspes
9$	rts

downcode
	tst.l	d6				; conf aktiv ?
	bne.s	1$				; nei
	move.w	conftop,d0
	add.w	#1,d0
	move.w	ActiveConf(MainBase),d1
	sub.w	#4,d1
	bcs.s	9$				; for få
	beq.s	9$				; for få
	cmp.w	d1,d0
	bhi.s	9$
	move.w	d0,conftop
	bra.s	8$
1$	move.w	dirtop,d0
	add.w	#1,d0
	move.w	ActiveDirs(MainBase),d1
	sub.w	#4,d1
	bcs.s	9$				; for få
	beq.s	9$				; for få
	cmp.w	d1,d0
	bhi.s	9$
	move.w	d0,dirtop
8$	bsr	refreshfilreqspes
	bsr	recalcpropgadget
9$	rts

upcode	tst.l	d6				; conf aktiv ?
	bne.s	1$				; nei
	move.w	conftop,d0
	beq.s	9$
	sub.w	#1,conftop
	bra.s	8$
1$	move.w	dirtop,d0
	beq.s	9$
	sub.w	#1,dirtop
8$	bsr	refreshfilreqspes
	bsr	recalcpropgadget
9$	rts

recalcpropgadget
	push	a2/a6/d2/d3/d4
	bsr	calcpotbody
	move.l	d0,d2
	move.l	d1,d4
	moveq.l	#-1,d1
	moveq.l	#-1,d3
	move.w	#AUTOKNOB+FREEVERT+PROPNEWLOOK,d0
	lea	slidebar,a0
	move.l	winadr,a1
	sub.l	a2,a2
	move.l	intbase,a6
	jsrlib	ModifyProp
	pop	a2/a6/d2/d3/d4
	rts

slidebarcode
	push	d2
	lea	slidebarSInfo,a0

	move.w	conftop,d2
	move.w	ActiveConf(MainBase),d0
	tst.l	d6				; conf aktiv ?
	beq.s	1$				; ja
	move.w	dirtop,d2
	move.w	ActiveDirs(MainBase),d0
1$	sub.w	#4,d0
	bcc.s	2$
	moveq.l	#0,d0				; hidden klar
2$	mulu	pi_VertPot(a0),d0
	add.l	#MAXPOT/2,d0
	divu	#MAXPOT,d0
	cmp.w	d2,d0				; samme topline ?
	beq.s	9$				; jepp.
	tst.l	d6				; conf aktiv ?
	bne.s	3$				; nei
	move.w	ActiveConf(MainBase),d1
	sub.w	#4,d1
	bcs.s	9$				; for få
	beq.s	9$				; for få
	cmp.w	d1,d0
	bhi.s	9$
	move.w	d0,conftop
	bra.s	8$
3$	move.w	ActiveDirs(MainBase),d1
	sub.w	#4,d1
	bcs.s	9$				; for få
	beq.s	9$				; for få
	cmp.w	d1,d0
	bhi.s	9$
	move.w	d0,dirtop
8$	bsr	refreshfilreqspes
9$	pop	d2
	rts

name1code
	moveq.l	#0,d0
	bra.s	namexcode
name2code
	moveq.l	#1,d0
	bra.s	namexcode
name3code
	moveq.l	#2,d0
	bra.s	namexcode
name4code
	moveq.l	#3,d0
;	bra.s	namexcode
namexcode
	move.l	intbase,a6
	push	d2/a2/d3
	lea	nameptrs,a0
	move.l	d0,d3
	beq.s	4$
7$	addq.l	#4,a0
	subq.l	#1,d0
	bne.s	7$
4$	move.l	(a0),a0			; ptr til teksten
	tst.b	(a0)			; er det noe her ?
	beq	99$			: nei, ut
	cmp.b	#' ',(a0)
	beq	99$			: nei, ut
	tst.w	d6			; conferences ?
	bne	1$			; nei

	move.l	winadr,a0
	lea	CFName,a1
	moveq.l	#5,d0
	jsrlib	RemoveGList
	add.w	conftop,d3
	move.l	d3,d0
	lea	ConfNames(MainBase),a0
	lea	ConfOrder(MainBase),a1
	bsr	10$
	move.w	d2,topnr
	lea	ConfSW(MainBase),a0
	move.b	0(a0,d2.w),d0
	lea	BitsSIBuff,a0
	lea	confacsbitstext,a1
	moveq	#0,d1
6$	btst	d1,d0
	beq.s	5$
	move.b	0(a1,d1.w),(a0)+
5$	addq.w	#1,d1
	cmp.w	#6,d1
	bls.s	6$
	move.b	#0,(a0)

	lsl.l	#1,d2
	lea	ConfMaxScan(MainBase),a0
	move.w	0(a0,d2.w),d0
	lea	scanSIBuff,a0
	bsr	konverterw
	lea	orderSIBuff,a0

	bsr	20$

	lea	CFName,a0			; slår på alle gadget'ene under
;	and.w	#~GFLG_DISABLED,gg_Flags(a0)
	lea	order,a0
	and.w	#~GFLG_DISABLED,gg_Flags(a0)
	lea	scan,a0
	and.w	#~GFLG_DISABLED,gg_Flags(a0)
	lea	Bits,a0			; disabler bit'ene hvis det er faste
	and.w	#~GFLG_DISABLED,gg_Flags(a0)
	move.w	topnr,d0		; conf'er det er snakk om.
	cmp.w	#4,d0
	bcc.s	2$
	or.w	#GFLG_DISABLED,gg_Flags(a0)

2$	move.l	winadr,a0
	lea	CFName,a1		; opp med gadgetene
	moveq.l	#-1,d0
	moveq.l	#5,d1
	jsrlib	AddGList
	move.l	winadr,a1
	lea	CFName,a0		; refresh'er dem
	moveq.l	#5,d0
	jsrlib	RefreshGList
	bra	9$

1$	move.l	winadr,a0		; fjerner navn
	lea	CFName,a1
	moveq.l	#5,d0
	jsrlib	RemoveGList
	add.w	dirtop,d3
	move.l	d3,d0
	lea	DirNames(MainBase),a0
	lea	FileOrder(MainBase),a1
	bsr	10$
	move.w	d2,topnr
	lea	orderSIBuff,a0

	bsr	20$

	lea	DirPaths(MainBase),a0
	move.w	d2,d0
	mulu	#Sizeof_NameT,d0
	lea	(0,a0,d0.l),a0
	lea	pathSIBuff,a1
	bsr	strcopy

	lea	CFName,a0			; slår på alle gadget'ene under
;	and.w	#~GFLG_DISABLED,gg_Flags(a0)
	lea	path,a0
	and.w	#~GFLG_DISABLED,gg_Flags(a0)
	lea	order,a0
	and.w	#~GFLG_DISABLED,gg_Flags(a0)

	move.l	winadr,a0
	lea	CFName,a1
	moveq.l	#-1,d0
	moveq.l	#5,d1
	jsrlib	AddGList
	move.l	winadr,a1
	lea	CFName,a0		; refresh'er dem
	moveq.l	#5,d0
	jsrlib	RefreshGList

9$	lea	CFName,a0
	bsr	activate
99$	pop	d2/a2/d3
	move.l	_SysBase,a6
	rts

10$	moveq.l	#0,d2
	move.b	0(a1,d0.w),d2			; henter nummeret
	sub.b	#1,d2
	move.l	d2,d0
	mulu	#Sizeof_NameT,d0
	lea	(0,a0,d0.l),a0
	lea	CFNameSIBuff,a1
	bsr	strcopy
	rts

20$	move.w	d3,oldordr
	move.w	d3,d0
	addq.l	#1,d0
	bsr	konverterw
	lea	bigup,a0		; er bigup og bigdown slått på ?
	move.w	gg_Flags(a0),d0
	and.w	#GFLG_DISABLED,d0
	beq.s	29$			; ja
	move.l	winadr,a1		; nei, slår de på
	jsrlib	OnGadget
	lea	bigdown,a0
	move.l	winadr,a1
	jsrlib	OnGadget
29$	rts

cfnamecode
	lea	CFNameSIBuff,a0
	tst.b	(a0)
	bne.s	1$
	lea	CFName,a1
	lea	wrongdatatext,a0
	bsr	blinkandactivate
	bra.s	9$
1$	bsr	upstring
	lea	ConfNames(MainBase),a1
	tst.w	d6
	beq.s	2$
	lea	DirNames(MainBase),a1
2$	move.w	topnr,d1
	moveq.l	#Sizeof_NameT,d0
	mulu	d0,d1
	lea	0(a1,d1.l),a1
	bsr	strcopymaxlen
	move.l	intbase,a6
	move.l	winadr,a1
	lea	CFName,a0
	moveq.l	#1,d0
	jsrlib	RefreshGList
	move.l	_SysBase,a6
	bsr	refreshfilreqspes
	lea	order,a0		; akriverer neste gadget
	tst.w	d6
	beq.s	3$
	lea	path,a0
3$	bsr	activate
9$	rts

pathcode
	lea	pathSIBuff,a0
	tst.b	(a0)
	bne.s	1$
	lea	path,a1
	lea	wrongdatatext,a0
	bsr	blinkandactivate
	bra.s	9$
1$	lea	DirPaths(MainBase),a1
	move.w	topnr,d1
	moveq.l	#Sizeof_NameT,d0
	mulu	d0,d1
	lea	0(a1,d1.l),a1
	subq.l	#1,d0
	bsr	strcopymaxlen
	lea	order,a0		; akriverer neste gadget
	bsr	activate
9$	rts

ordercode
	lea	orderSIBuff,a0
	bsr	atoi
	bmi.s	2$
	bne.s	1$
2$	lea	order,a1
	lea	wrongdatatext,a0
	bsr	blinkandactivate
	bra.s	9$
1$	move.w	oldordr,d1
	sub.w	d1,d0
	sub.w	#1,d0
	beq.s	8$			; samme order ? jepp,nop
	bpl.s	3$
	neg.w	d0
	bsr	moveup
	bra.s	4$
3$	bsr	movedown
4$	beq.s	8$			; ingen forandring
	bsr	refreshfilreqspes
8$	lea	scan,a0
	tst.w	d6
	beq.s	5$
	lea	CFName,a0
5$	bsr	activate
9$	rts

scancode
	lea	scanSIBuff,a0
	bsr	atoi
	bmi.s	2$
	bne.s	1$
2$	lea	scan,a1
	lea	wrongdatatext,a0
	bsr	blinkandactivate
	bra.s	9$
1$	cmp.w	#700,d0
	bhi.s	2$
	move.w	topnr,d1
	lsl.w	#1,d1
	lea	ConfMaxScan(MainBase),a0
	move.w	d0,0(a0,d1.w)
	lea	Bits,a0			; er neste disablet ?
	move.w	gg_Flags(a0),d0
	and.w	#GFLG_DISABLED,d0
	beq.s	3$			; nei
	lea	CFName,a0		; ja, tar neste etter der isteden
3$	bsr	activate
9$	rts

bitscode
	lea	BitsSIBuff,a0
	tst.b	(a0)
	beq.s	2$
	bsr	parseconfaccsesbits
	bne.s	1$
2$	lea	Bits,a0
	lea	wrongdatatext,a0
	bsr	blinkandactivate
	bra.s	9$
1$	move.w	topnr,d1
	lea	ConfSW(MainBase),a0
	move.b	d0,0(a0,d1.w)
	lea	CFName,a0
	bsr	activate
9$	rts

parseconfaccsesbits
	bsr	upstring
	moveq.l	#0,d0
4$	move.b	(a0)+,d1
	beq.s	9$
	cmp.b	#'R',d1
	bne.s	42$
	ori.b	#CONFSWF_ImmRead,d0
	bra.s	4$
42$	cmp.b	#'W',d1
	bne.s	43$
	ori.b	#CONFSWF_ImmWrite,d0
	bra.s	4$
43$	cmp.b	#'P',d1
	bne.s	44$
	ori.b	#CONFSWF_PostBox,d0
	bra.s	4$
44$	cmp.b	#'A',d1
	bne.s	45$
	ori.b	#CONFSWF_Private,d0
	bra.s	4$
45$	cmp.b	#'V',d1
	bne.s	46$
	ori.b	#CONFSWF_VIP,d0
	bra.s	4$
46$	cmp.b	#'E',d1
	bne.s	47$
	ori.b	#CONFSWF_Resign,d0
	bra.s	4$
47$
9$	notz
	rts

; d0 = antall plasser
moveup
	lea	ConfOrder(MainBase),a0
	tst.l	d6				; conf aktiv ?
	beq.s	1$				; ja
	lea	FileOrder(MainBase),a0
1$	move.w	oldordr,d1
	cmp.w	d0,d1
	bcc.s	2$
	move.l	d1,d0
	beq.s	9$
2$	sub.w	d0,oldordr			; opdaterer oldorder
	lea	(0,a0,d1.w),a0
	move.b	(a0),d1
3$	move.b	-1(a0),(a0)
	subq.l	#1,a0
	sub.w	#1,d0
	bne.s	3$
	move.b	d1,(a0)
	bsr	moveupdate
	clrz
9$	rts

; d0 = antall plasser
movedown
	lea	ConfOrder(MainBase),a0
	move.w	ActiveConf(MainBase),d1
	tst.l	d6				; conf aktiv ?
	beq.s	1$				; ja
	lea	FileOrder(MainBase),a0
	move.w	ActiveDirs(MainBase),d1
1$	sub.w	oldordr,d1
	beq.s	9$
	sub.w	#1,d1
	beq.s	9$
	cmp.w	d0,d1
	bcc.s	2$
	move.w	d1,d0
	beq.s	9$
2$	move.w	oldordr,d1
	add.w	d0,oldordr			; opdaterer oldorder
	lea	(0,a0,d1.w),a0
	move.b	(a0),d1				; husker denne
3$	move.b	1(a0),(a0)+
	sub.w	#1,d0
	bne.s	3$
8$	move.b	d1,(a0)
	bsr	moveupdate
	clrz
9$	rts

moveupdate
	move.l	intbase,a6
	move.w	oldordr,d0
	add.w	#1,d0
	lea	orderSIBuff,a0
	bsr	konverterw
	move.l	winadr,a1
	lea	order,a0
	moveq.l	#1,d0
	jsrlib	RefreshGList
	move.l	_SysBase,a6
	rts

activate
	move.w	gg_Flags(a0),d0
	and.w	#GFLG_DISABLED,d0	; bare hvis den ikke er disabl'a
	bne.s	9$
	move.l	intbase,a6
	move.l	winadr,a1		; aktiviserer gadget med feil i
	sub.l	a2,a2
	jsrlib	ActivateGadget
	move.l	_SysBase,a6
9$	rts

; a0 = title
; a1 = gadget
blinkandactivate
	move.l	a1,-(a7)
	moveq.l	#1,d0
	bsr	title
	move.w	#1,titlech
	move.l	(a7)+,a0
	bsr	activate		; aktiviserer gadget med feil i
	setz
	rts

; a0 = tittel
; d0 = beep (= true) ?
title	push	a6/a2
	move.l	intbase,a6
	move.l	a0,a1
	tst.l	d0
	beq.s	1$
	move.l	a1,-(a7)
	sub.l	a0,a0
	jsrlib	DisplayBeep
	move.l	(a7)+,a1
1$	move.l	winadr,a0
	suba.l	a2,a2
	jsrlib	SetWindowTitles
	pop	a6/a2
	rts

cleanup	move.l	intbase,a6
	tst.b	menusta
	bne.s	1$
	move.l	winadr,d0
	jsrlib	ClearMenuStrip
	move.b	#0,menusta
1$	move.l	winadr,d0
	beq.s	2$
	move.l	d0,a0
	jsrlib	CloseWindow
	moveq.l	#0,d0
	move.l	d0,winadr
2$	move.l	_SysBase,a6
	move.l	mem,d0
	beq.s	3$
	move.l	d0,a1
	move.l	#ConfigRecord_SIZEOF,d0
	jsrlib	FreeMem
	moveq.l	#0,d0
	move.l	d0,mem
3$	move.l	port,d0
	beq.s	4$
	move.l	d0,a0
	bsr	DeletePort
	moveq.l	#0,d0
	move.l	d0,port
4$	rts

writedostext
	push	d2-d3/a6
	move.l	dosbase,a6
	move.l	a0,d2
	bsr	strlen
	move.l	d0,d3
	jsrlib	Output
	move.l	d0,d1
	jsrlib	Write
	pop	d2-d3/a6
	rts

; a0 = data område
; d0 = brukernr
loadusernr
	lea	msg,a1
	move.w	#Main_loadusernr,m_Command(a1)
	move.l	d0,m_UserNr(a1)
	move.l	a0,m_Data(a1)
	bsr	handlemsg
	lea	msg,a1
	move.w	m_Error(a1),d0
	cmp.w	#Error_OK,d0
	notz
	rts

; a0 = data område
; d0 = brukernr
saveusernr
	lea	msg,a1
	move.w	#Main_saveusernr,m_Command(a1)
	move.l	d0,m_UserNr(a1)
	move.l	a0,m_Data(a1)
	bsr	handlemsg
	lea	msg,a1
	move.w	m_Error(a1),d0
	cmp.w	#Error_OK,d0
	notz
	rts

savemainconfig
	lea	msg,a1
	move.w	#Main_saveconfig,m_Command(a1)
	moveq.l	#0,d0
	move.l	d0,m_Data(a1)
	bsr	handlemsg
	lea	msg,a1
	move.w	m_Error(a1),d0
	cmp.w	#Error_OK,d0
	notz
	rts

; a0 = gammelt navn
; a1 = nytt navn
namechange
	move.l	a2,-(a7)
	move.l	a1,a2
	moveq.l	#Sizeof_NameT,d0		; Har vi byttet navn på sysop ?
	bsr	comparestringsfull
	notz
	bne.s	9$				; nei, ferdig
	lea	msg,a1				; byttter navn
	move.w	#Main_ChangeName,m_Command(a1)
	move.l	a2,m_Name(a1)
	move.l	SYSOPUsernr(MainBase),m_UserNr(a1)
	moveq.l	#0,d0				; ifra node 0
	move.l	d0,m_arg(a1)
	move.l	#userrec,m_Data(a1)		; tom plass som changename trenger
	bsr	handlemsg
	lea	msg,a1
	move.w	m_Error(a1),d1
	cmp.w	#Error_OK,d1
	notz
9$	move.l	(a7)+,a2
	rts

getabbsconfig
	lea	msg,a1
	move.w	#Main_testconfig,m_Command(a1)
	bsr	handlemsg
	bne.s	1$
	setn
	bra.s	9$			; abbs porten var ikke der
1$	lea	msg,a1
	move.l	m_Data(a1),a0		; Configspace
	move.w	m_UserNr(a1),d0		; configstatus
	clrn
9$	rts

getconfig
	bsr	getabbsconfig
	bmi.s	9$
	beq.s	9$
	move.l	MainBase,a1
	move.l	#ConfigRecord_SIZEOF,d0 ; Kopierer hele config'em til buffer
	bsr	memcopylen
	clrzn
9$	rts

setupgadgetsspes
	move.l	intbase,a6
	move.l	winadr,a0		; fjerner meny
	jsrlib	ClearMenuStrip
	move.b	#0,menusta
	move.l	winadr,a0
	lea	GadgetList1,a1		; fjerner gadgeter
	moveq.l	#-1,d0
	jsrlib	RemoveGList
	bsr	setupgadgets		; oppdaterer alt
	move.l	winadr,a0
	lea	GadgetList1,a1		; opp med gadgetene
	moveq.l	#-1,d0
	moveq.l	#-1,d1
	jsrlib	AddGList
	move.l	winadr,a1		; refresh'er dem
	lea	GadgetList1,a0
	moveq.l	#-1,d0
	jsrlib	RefreshGList
	move.l	winadr,a0		; Opp med meny
	lea	MenuList1,a1
	jsrlib	SetMenuStrip
	tst.l	d0
	beq.s	1$
	move.b	#1,menusta
1$	move.l	_SysBase,a6
	rts

setupgadgets
	push	a2/d2
	lea	BaseName(MainBase),a0		; base navnet
	lea	BoardnameSIBuff,a1
	bsr	strcopy
	lea	SYSOPname(MainBase),a0		; Sysop navn
	lea	SysopnameSIBuff,a1
	bsr	strcopy
	lea	SYSOPpassword(MainBase),a0	; sysop passord
	lea	SysopPasswordSIBuff,a1
	bsr	strcopy
	lea	userrec,a2
	lea	Address(a2),a0
	lea	SysopAddressSIBuff,a1
	bsr	strcopy
	lea	CityState(a2),a0
	lea	postalSIBuff,a1
	bsr	strcopy
	lea	HomeTelno(a2),a0
	lea	HometlfSIBuff,a1
	bsr	strcopy
	lea	WorkTelno(a2),a0
	lea	WorktlfSIBuff,a1
	bsr	strcopy
	move.w	MaxLinesMessage(MainBase),d0
	lea	maxmsglinesSIBuff,a0
	bsr	konverterw
	move.w	NewUserTimeLimit(MainBase),d0
	lea	newtimeSIBuff,a0
	bsr	konverterw
	move.w	SleepTime(MainBase),d0
	lea	sleeptimeSIBuff,a0
	bsr	konverterw
;	lea	ClosedPassword(MainBase),a0
	moveq.l	#0,d0
	move.b	DefaultCharSet(MainBase),d0
	move.b	d0,charset
	lea	charsettext,a0
	lsl.l	#2,d0			; beregner fremm plassen til
	add.l	d0,a0			; tegnsett plassen
	lea	ITextText6+8,a1
	moveq.l	#3,d0
	bsr	strcopymaxlen
	move.b	Cflags(MainBase),d2
	lea	MenuItem4,a0
	move.b	#CflagsB_Lace,d0
	bsr	10$
	lea	MenuItem5,a0
	move.b	#CflagsB_8Col,d0
	bsr	10$
	lea	MenuItem8,a0
	move.b	#CflagsB_Download,d0
	bsr	10$
	lea	MenuItem7,a0
	move.b	#CflagsB_Upload,d0
	bsr	10$
	lea	fileratiobit,a0
	move.b	#CflagsB_Fileratio,d0
	bsr	20$
	lea	byteratiobit,a0
	move.b	#CflagsB_Byteratio,d0
	bsr	20$
	lea	NewMenuItem1,a0
	move.b	#CflagsB_AllowTmpSysop,d0
	bsr	10$
	lea	NewMenuItem2,a0
	move.b	#CflagsB_UseASL,d0
	bsr	10$

	move.w	NewUserFileLimit(MainBase),d0
	lea	newfiletimeSIBuff,a0
	bsr	konverterw
	lea	ConfNames(MainBase),a2
	move.l	a2,a0
	lea	NewsSIBuff,a1
	bsr	strcopy
	lea	PostSIBuff,a1
	lea	Sizeof_NameT(a2),a2
	move.l	a2,a0
	bsr	strcopy
	lea	UserinfoSIBuff,a1
	lea	Sizeof_NameT(a2),a2
	move.l	a2,a0
	bsr	strcopy
	lea	FileinfoSIBuff,a1
	lea	Sizeof_NameT(a2),a2
	move.l	a2,a0
	bsr	strcopy
	move.w	ByteRatiov(MainBase),d0
	lea	byteratioSIBuff,a0
	bsr	konverter
	move.w	FileRatiov(MainBase),d0
	lea	fileratioSIBuff,a0
	bsr	konverterw
	move.w	MinULSpace(MainBase),d0
	lea	minspaceSIBuff,a0
	bsr	konverterw
	bsr	updateslidebar
	bsr	refreshfilreq
	pop	a2/d2
	rts

10$	and.w	#~CHECKED,mi_Flags(a0)		; slaar av flagget
	btst	d0,d2				; skal det vaere paa ?
	beq.s	19$				; nei.
	or.w	#CHECKED,mi_Flags(a0)		; slaar det paa
19$	rts

20$	and.w	#~GFLG_SELECTED,gg_Flags(a0)	; slaar av flagget
	btst	d0,d2				; skal det vaere paa ?
	beq.s	29$				; nei.
	or.w	#GFLG_SELECTED,gg_Flags(a0)	; slaar det paa
29$	rts

updateslidebar
	bsr	calcpotbody
	lea	slidebarSInfo,a0
	move.w	d0,pi_VertPot(a0)
	move.w	d1,pi_VertBody(a0)
	rts

calcpotbody
	push	d2/d3/d4
; totallines = d3
; visiblelines = 4
; topline = d2
; overlap = 1
; hidden = d1

	move.w	conftop,d2
	move.w	ActiveConf(MainBase),d3
	tst.l	d6				; conf aktiv ?
	beq.s	1$				; ja
	move.w	dirtop,d2
	move.w	ActiveDirs(MainBase),d3
1$	move.w	d3,d1
	sub.w	#4,d1
	bcc.s	2$
	moveq.l	#0,d1				; hidden klar
2$	cmp.w	d2,d1				; topline,hidden
	bcc.s	3$
	move.w	d1,d2				; reduce topline
3$	move.w	#MAXBODY,d0
	tst.w	d1				; hidden == 0 ?
	beq.s	4$				; jepp
	move.l	#(4-1)*MAXBODY,d0
	move.w	d3,d4
	sub.w	#1,d4
	divu	d4,d0
4$	move.w	d0,d4
	moveq.l	#0,d0
	tst.w	d1				; hidden == 0 ?
	beq.s	5$				; jepp
	move.w	d2,d0
	mulu	#MAXPOT,d0
	divu	d1,d0
5$	move.w	d4,d1
	pop	d2/d3/d4
	rts

refreshfilreqspes
	tst.l	d7				; er det full setup ?
	bne.s	9$				; ja. dette er en nop
	move.l	intbase,a6
	move.l	winadr,a0
	lea	name1,a1			; fjerner Name gadgetene
	moveq.l	#4,d0
	jsrlib	RemoveGList
	bsr	refreshfilreq	
	move.l	winadr,a0
	lea	name1,a1		; opp med gadgetene
	moveq.l	#-1,d0
	moveq.l	#4,d1
	jsrlib	AddGList
	move.l	winadr,a1		; refresh'er dem
	lea	name1,a0
	moveq.l	#4,d0
	jsrlib	RefreshGList
	move.l	_SysBase,a6
9$	rts

refreshfilreq
	push	a2/a3/d2/d3/d4
	tst.l	d7				; er det full setup ?
	bne.s	9$				; ja. dette er en nop
	moveq.l	#0,d3
	moveq.l	#0,d4				; 4 gadget'er aa update
	lea	nameptrs,a4
	lea	ConfOrder(MainBase),a2
	lea	ConfNames(MainBase),a3
	move.w	conftop,d2
	tst.l	d6				; conf aktiv ?
	beq.s	1$				; ja
	lea	FileOrder(MainBase),a2
	lea	DirNames(MainBase),a3
	move.w	dirtop,d2
1$	move.b	0(a2,d2.w),d3			; henter nummeret
	sub.b	#1,d3
	move.l	d3,d0
	mulu	#Sizeof_NameT,d0
	lea	(0,a3,d0.l),a0
 	move.l	(a4)+,a1
	moveq.l	#Sizeof_NameT,d0
	bsr	strcopypace
	add.w	#1,d2
	addq.l	#1,d4
	cmp.w	#4,d4
	bcs.s	1$
9$	pop	a2/a3/d2/d3/d4
	rts

nameptrs	dc.l	ITextText51,ITextText52,ITextText53,ITextText54

setupnewconfig
	move.l	d2,-(a7)
	move.w	#MaxConferences,d2		; oppdaterer MaxScan og order
	move.w	#50,d0
	moveq.l	#1,d1
	lea	ConfOrder(MainBase),a1
	lea	ConfMaxScan(MainBase),a0
1$	move.w	d0,(a0)+
	move.b	d1,(a1)+
	addq.l	#1,d1
	sub.w	#1,d2
	bne.s	1$

	move.w	#MaxFileDirs,d2			; oppdaterer Filedir order
	moveq.l	#1,d1
	lea	FileOrder(MainBase),a1
2$	move.b	d1,(a1)+
	addq.l	#1,d1
	sub.w	#1,d2
	bne.s	2$
	move.l	(a7)+,d2
	rts

handlemsg
	move.l	a1,-(a7)
	XREF	Forbid
0$	jsrlib	Forbid
	lea	mainmsgportname,a1
	jsrlib	FindPort
	move.l	(a7)+,a1
	tst.l	d0
	beq.s	9$
	move.l	d0,a0
	jsrlib	PutMsg
	jsrlib	Permit
1$	move.l	port,a0
	jsrlib	WaitPort
	tst.l	d0
	beq.s	1$
	move.l	port,a0
	jsrlib	GetMsg
	tst.l	d0
	beq.s	1$
	rts
9$	move.l	a1,-(a7)
	jsrlib	Permit
	lea	IText70,a1		; BodyText
	bsr	req			; Trenger abbs !!
	bne.s	0$			; Prøv igjen
	addq.l	#4,a7
	setz				; gir opp
	rts

req	movem.l	a2/a3/a6,-(a7)
	move.l	intbase,a6
	move.l	winadr,a0
	lea	IText90,a2	; PositiveText
	lea	IText80,a3	; NegativeText
	moveq.l	#0,d0		; PositiveFlags
	moveq.l	#0,d1		; NegativeFlags
	move.l	#300,d2		; with
	moveq.l	#60,d3		; height
	jsrlib	AutoRequest
	movem.l	(a7)+,a2/a3/a6
	tst.l	d0
	rts

******************************
;CreatePort
;inputs : name,priority (a0,d0) (hvis name er null, så blir det en privat port)
;outputs: msgport (d0)
******************************
CreatePort
	movem.l	d2/d3/a2/a3,-(sp)
	move.l	a0,a2
	move.l	d0,d3
	move.l	#MP_SIZE,d0
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	jsrlib	AllocMem
	tst.l	d0
	beq.s	1$
	move.l	d0,a3
	moveq.l	#-1,d0
	move.l	d0,d2
	jsrlib	AllocSignal
	cmp.l	d2,d0
	beq.s	2$
	move.b	d0,MP_SIGBIT(a3)
	sub.l	a1,a1
	jsrlib	FindTask
	move.l	d0,MP_SIGTASK(a3)
	move.l	a2,LN_NAME(a3)
	move.b	d3,LN_PRI(a3)
	move.b	#NT_MSGPORT,LN_TYPE(a3)
	move.b	#PA_SIGNAL,MP_FLAGS(a3)
	move.l	a3,a1
	tst.l	LN_NAME(a1)
	bne.s	3$
	lea	MP_MSGLIST(A1),A0	; Address of port's message list.
	NEWLIST	a0			; initer msg listen
	bra.s	4$
3$	jsrlib	AddPort
4$	move.l	a3,d0
	movem.l	(sp)+,a2/a3/d2/d3
	rts

2$	move.l	a3,a1
	move.l	#MP_SIZE,d0
	jsrlib	FreeMem
1$	movem.l	(sp)+,a2/a3/d2/d3
	setz
	rts


; d0 = tall
; a0 = inn streng.
konverterw
	and.l	#$ffff,d0
konverter
	link	a5,#-12
	move.l	sp,a1
1$	moveq.l	#10,d1
	bsr	divspes
	add.w	#'0',d1
	move.b	d1,(a1)+
	tst.l	d0
	bne.s	1$
	move.l	a1,d1
	moveq.l	#0,d0
2$	move.b	-(a1),(a0)+
	add.l	#1,d0
	cmpa.l	a1,sp
	bne.s	2$
	clr.b	(a0)
	sub.l	sp,d1
	unlk	a5
	rts

divspes	move.l	d2,-(sp)
	swap	d1
	move.w	d1,d2
	bne.s	9$
	swap	d0
	swap	d1
	swap	d2
	move.w	d0,d2
	beq.s	1$
	divu	d1,d2
	move.w	d2,d0
1$	swap	d0
	move.w	d0,d2
	divu	d1,d2
	move.w	d2,d0
	swap	d2
	move.w	d2,d1
9$	move.l	(sp)+,d2
	rts

******************************
;DeletePort
;inputs : msgport (a0)
;outputs: none
******************************
DeletePort
	move.l	a2,-(sp)
	move.l	a0,a2
	move.l	a0,a1
	tst.l	LN_NAME(a1)		; Er den add'a ?
	beq.s	1$			; nei.
	jsrlib	RemPort
1$	move.b	MP_SIGBIT(a2),d0
	jsrlib	FreeSignal
	move.l	a2,a1
	move.l	#MP_SIZE,d0
	jsrlib	FreeMem
	move.l	(sp)+,a2
	rts

atoi	moveq.l	#-1,d0
	moveq.l	#0,d1
1$	move.b	(a0)+,d1
	beq.s	9$
	cmp.b	#' ',d1
	beq.s	9$
	cmp.b	#10,d1
	beq.s	9$
	cmp.b	#13,d1
	beq.s	9$
	sub.b	#'0',d1
	bcs.s	8$
	cmp.b	#9,d1
	bhi.s	8$
	cmp.l	#-1,d0
	bne.s	2$
	move.l	d1,d0
	bra.s	1$
2$	mulu	#10,d0
	add.l	d1,d0
	bra.s	1$
8$	setn
	rts
9$	tst.w	d0
	rts

******************************
;strcopy (fromstreng,tostreng1)
;	 a0.l	     a1.l
;copys until end of fromstring
******************************
strcopy
1$	move.b	(a0)+,(a1)+
	bne.s	1$
	rts

******************************
;strcopylen (fromstreng,tostreng1,length)
;memcopylen (fromstreng,tostreng1,length)
;	     a0.l	a1.l	  d0.w
******************************
strcopylen
memcopylen
	subq.l	#1,d0
	bcs.s	9$
1$	move.b	(a0)+,(a1)+
	dbf	d0,1$
9$	rts

******************************
;strcopymaxlen (fromstreng,tostreng1,length)
;		a0.l	   a1.l	     d0.w
;Fyller ut med 0'er på slutten.
******************************
strcopymaxlen
	sub.w	#1,d0
2$	move.b	(a0)+,(a1)+
	beq.s	3$
	dbf	d0,2$
	bra.s	9$
1$	move.b	#0,(a1)+
3$	dbf	d0,1$
9$	rts

******************************
;strcopymaxlenspace (fromstreng,tostreng1,length)
;			a0.l	   a1.l	     d0.w
;Fyller ut med spac'er på slutten.
******************************
strcopypace
	sub.w	#1,d0
2$	move.b	(a0)+,(a1)+
	beq.s	1$
	dbf	d0,2$
	bra.s	9$
1$	move.b	#' ',-1(a1)
3$	move.b	#' ',(a1)+
	dbf	d0,3$
9$	move.b	#0,-1(a1)
	rts

******************************
;len = strlen (string)
;d0		a0
******************************
strlen	moveq.l	#-1,d0
1$	tst.b	(a0)+
	dbeq	d0,1$
	not.w	d0
	ext.l	d0
	rts

******************************
;char = upchar (char)
;d0.b		d0.b
******************************

upchar	cmp.b	#'a',d0
	bcs.s	1$
	cmp.b	#'z',d0
	bhi.s	2$
	sub.b	#'a'-'A',d0
1$	rts
2$	cmp.b	#224,d0		; Starten på utenlandske tegn (små)
	bcs.s	3$
	sub.b	#32,d0		; Forskjellen på Store og små ISO tegn.
3$	rts

******************************
;string = upstring (string)
;a0		    a0
;does a upchar on every char in string
******************************

upstring
	movem.l	a0/d0,-(sp)
	move.l	a0,a1
3$	move.b	(a0)+,d0
	beq.s	1$
	bsr	upchar
	move.b	d0,(a1)+
	bra.s	3$
1$	movem.l	(sp)+,a0/d0
	rts

******************************
;result = comparestringsfull (streng,streng1,length)
;Zero bit		      a0.l   a1.l    d0.w
******************************
comparestringsfull
	subq.w	#1,d0
1$	move.b	(a0)+,d1
	cmp.b	(a1)+,d1
	dbne	d0,1$
	rts

	section bdata,BSS

_SysBase	ds.l	1
charset	ds.b	1
pad_1	ds.b	1

oldordr	ds.w	1
newordr	ds.w	1
topnr	ds.w	1
conftop	ds.w	1
dirtop	ds.w	1
menusta ds.w	1
titlech	ds.w	1
msgport	ds.l	1
winadr	ds.l	1
dosbase	ds.l	1
intbase	ds.l	1
port	ds.l	1
mem	ds.l	1
msg	ds.b	ABBSmsg_SIZE
userrec	ds.b	UserRecord_SIZEOF

	section data,data

charsettext
	dc.b	'ISO',0
	dc.b	'IBM',0
	dc.b	'IBN',0,0,0

confacsbitstext	dc.b	'RWPAVEN',0,0

intererror1text	dc.b	'Internal error 1',0
sorrynocodetext	dc.b	'Sorry. Edit save is not functional yet.',0
wrongdatatext	dc.b	'Error in data or data missing !',0
cantcrsysoptext	dc.b	'Can''t create sysop !',0
cantsasysoptext	dc.b	'Can''t save sysop !',0
cantrenysoptext	dc.b	'Can''t rename sysop !',0
cantcrconftext	dc.b	'Can''t create conference !',0
cantcrfdirtext	dc.b	'Can''t create filedir !',0
nomenutext	dc.b	'Error setting up menu',10,0
nowindowtext	dc.b	'Can''t open window',10,0
nosysoptext	dc.b	'Error loading sysop',10,0
noporttext	dc.b	'Can''t create msg port',10,0
nomemtext	dc.b	'Can''t allocate memory',10,0
cantsavcnfitext	dc.b	'Can''t save config !',0

dosname		dc.b	'dos.library',0
intname		dc.b	'intuition.library',0
noabbstext	dc.b	'Can''t find abbs !',10,0
tmpportname	dc.b	'ConfigBBS port',0
mainmsgportname
	dc.b	'ABBS mainport',0
fildedirpath	dc.b	'abbs:files/',0
uploadname	dc.b	'UPLOAD',0
privatename	dc.b	'PRIVATE',0

	CNOP	0,2

activetabell
	dc.l	SysopPassword,SysopAddress,postal,Hometlf,Worktlf,Boardname
	dc.l	News,Post,Userinfo,Fileinfo,newtime,newfiletime,maxmsglines
	dc.l	sleeptime,byteratio,fileratio,minspace,Sysopname

specialjumptable
	dc.l	filedirbitcode,confbitcode,bigupcode,bigdowncode,slidebarcode
	dc.l	upcode,downcode,name1code,name2code,name3code,name4code,cfnamecode
	dc.l	pathcode,ordercode,scancode,bitscode


NewWindowStructure1:
	dc.w	0,0
	dc.w	640,200
	dc.b	0,1
	dc.l	GADGETUP+MENUPICK
	dc.l	WINDOWDRAG+WINDOWDEPTH+ACTIVATE+NOCAREREFRESH
	dc.l	GadgetList1
	dc.l	NULL
	dc.l	NewWindowName1
	dc.l	NULL
	dc.l	NULL
	dc.w	5,5
	dc.w	-1,-1
	dc.w	WBENCHSCREEN
NewWindowName1:
	dc.b	'ConfigBBS',0
	cnop 0,2
UNDOBUFFER:
	dcb.b 31,0
	cnop 0,2
GadgetList1:
Sysopname:
	dc.l	SysopPassword
	dc.w	16,34
	dc.w	244,8
	dc.w	NULL
	dc.w	RELVERIFY+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border1
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	SysopnameSInfo
	dc.w	1
	dc.l	NULL
SysopnameSInfo:
	dc.l	SysopnameSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	31
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
SysopnameSIBuff:
	dcb.b 31,0
	cnop 0,2
Border1:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors1
	dc.l	NULL
BorderVectors1:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,10
	dc.w	0,10
	dc.w	0,1
SysopPassword:
	dc.l	SysopAddress
	dc.w	268,34
	dc.w	73,8
	dc.w	NULL
	dc.w	RELVERIFY+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border2
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	SysopPasswordSInfo
	dc.w	2
	dc.l	NULL
SysopPasswordSInfo:
	dc.l	SysopPasswordSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	9
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
SysopPasswordSIBuff:
	dcb.b 9,0
	cnop 0,2
Border2:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors2
	dc.l	NULL
BorderVectors2:
	dc.w	0,0
	dc.w	76,0
	dc.w	76,10
	dc.w	0,10
	dc.w	0,1
SysopAddress:
	dc.l	postal
	dc.w	16,55
	dc.w	244,8
	dc.w	NULL
	dc.w	RELVERIFY+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border3
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	SysopAddressSInfo
	dc.w	3
	dc.l	NULL
SysopAddressSInfo:
	dc.l	SysopAddressSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	31
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
SysopAddressSIBuff:
	dcb.b 31,0
	cnop 0,2
Border3:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors3
	dc.l	NULL
BorderVectors3:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,10
	dc.w	0,10
	dc.w	0,1
postal:
	dc.l	News
	dc.w	16,76
	dc.w	244,8
	dc.w	NULL
	dc.w	RELVERIFY+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border4
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	postalSInfo
	dc.w	4
	dc.l	NULL
postalSInfo:
	dc.l	postalSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	31
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
postalSIBuff:
	dcb.b 31,0
	cnop 0,2
Border4:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors4
	dc.l	NULL
BorderVectors4:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,10
	dc.w	0,10
	dc.w	0,1
News:
	dc.l	Post
	dc.w	369,23
	dc.w	244,8
	dc.w	GFLG_DISABLED
	dc.w	RELVERIFY+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border5
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	NewsSInfo
	dc.w	8
	dc.l	NULL
NewsSInfo:
	dc.l	NewsSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	31
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
NewsSIBuff:
	dc.b	'News',0,0
PWstringlen	set	*-NewsSIBuff
	dcb.b 31-PWstringlen,0
	cnop 0,2
Border5:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors5
	dc.l	NULL
BorderVectors5:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,10
	dc.w	0,10
	dc.w	0,1
Post:
	dc.l	Userinfo
	dc.w	370,45
	dc.w	244,8
	dc.w	GFLG_DISABLED
	dc.w	RELVERIFY+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border6
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	PostSInfo
	dc.w	9
	dc.l	NULL
PostSInfo:
	dc.l	PostSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	31
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
PostSIBuff:
	dc.b	'Post',0
PWstringlen	set	*-PostSIBuff
	dcb.b 31-PWstringlen,0
	cnop 0,2
Border6:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors6
	dc.l	NULL
BorderVectors6:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,10
	dc.w	0,10
	dc.w	0,1
Userinfo:
	dc.l	Fileinfo
	dc.w	370,67
	dc.w	244,8
	dc.w	GFLG_DISABLED
	dc.w	RELVERIFY+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border7
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	UserinfoSInfo
	dc.w	10
	dc.l	NULL
UserinfoSInfo:
	dc.l	UserinfoSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	31
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
UserinfoSIBuff:
	dc.b	'UserInfo',0
PWstringlen	set	*-UserinfoSIBuff
	dcb.b 31-PWstringlen,0
	cnop 0,2
Border7:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors7
	dc.l	NULL
BorderVectors7:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,10
	dc.w	0,10
	dc.w	0,1
Fileinfo:
	dc.l	newtime
	dc.w	370,89
	dc.w	244,8
	dc.w	GFLG_DISABLED
	dc.w	RELVERIFY+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border8
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	FileinfoSInfo
	dc.w	11
	dc.l	NULL
FileinfoSInfo:
	dc.l	FileinfoSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	31
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
FileinfoSIBuff:
	dc.b	'Fileinfo',0
PWstringlen	set	*-FileinfoSIBuff
	dcb.b 31-PWstringlen,0
	cnop 0,2
Border8:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors8
	dc.l	NULL
BorderVectors8:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,10
	dc.w	0,10
	dc.w	0,1
newtime:
	dc.l	newfiletime
	dc.w	16,125
	dc.w	34,8
	dc.w	NULL
	dc.w	RELVERIFY+LONGINT+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border9
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	newtimeSInfo
	dc.w	12
	dc.l	NULL
newtimeSInfo:
	dc.l	newtimeSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	4
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
newtimeSIBuff:
	dc.b	'30',0
PWstringlen	set	*-newtimeSIBuff
	dcb.b 4-PWstringlen,0
	cnop 0,2
Border9:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors9
	dc.l	NULL
BorderVectors9:
	dc.w	0,0
	dc.w	37,0
	dc.w	37,10
	dc.w	0,10
	dc.w	0,1
newfiletime:
	dc.l	Boardname
	dc.w	16,137
	dc.w	34,8
	dc.w	NULL
	dc.w	RELVERIFY+LONGINT+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border10
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	newfiletimeSInfo
	dc.w	13
	dc.l	NULL
newfiletimeSInfo:
	dc.l	newfiletimeSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	4
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
newfiletimeSIBuff:
	dc.b	'15',0
PWstringlen	set	*-newfiletimeSIBuff
	dcb.b 4-PWstringlen,0
	cnop 0,2
Border10:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors10
	dc.l	NULL
BorderVectors10:
	dc.w	0,0
	dc.w	37,0
	dc.w	37,10
	dc.w	0,10
	dc.w	0,1
Boardname:
	dc.l	fileratio
	dc.w	241,97
	dc.w	110,8
	dc.w	NULL
	dc.w	RELVERIFY+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border11
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	BoardnameSInfo
	dc.w	7
	dc.l	NULL
BoardnameSInfo:
	dc.l	BoardnameSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	31
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
BoardnameSIBuff:
	dcb.b 31,0
	cnop 0,2
Border11:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors11
	dc.l	NULL
BorderVectors11:
	dc.w	0,0
	dc.w	109,0
	dc.w	109,10
	dc.w	0,10
	dc.w	0,1
fileratio:
	dc.l	byteratio
	dc.w	16,185
	dc.w	34,8
	dc.w	NULL
	dc.w	RELVERIFY+LONGINT+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border12
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	fileratioSInfo
	dc.w	17
	dc.l	NULL
fileratioSInfo:
	dc.l	fileratioSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	4
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
fileratioSIBuff:
	dc.b	'5',0
PWstringlen	set	*-fileratioSIBuff
	dcb.b 4-PWstringlen,0
	cnop 0,2
Border12:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors12
	dc.l	NULL
BorderVectors12:
	dc.w	0,0
	dc.w	37,0
	dc.w	37,10
	dc.w	0,10
	dc.w	0,1
byteratio:
	dc.l	fileratiobit
	dc.w	16,173
	dc.w	34,8
	dc.w	NULL
	dc.w	RELVERIFY+LONGINT+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border13
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	byteratioSInfo
	dc.w	16
	dc.l	NULL
byteratioSInfo:
	dc.l	byteratioSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	5
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
byteratioSIBuff:
	dc.b	'1000',0
	cnop 0,2
Border13:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors13
	dc.l	NULL
BorderVectors13:
	dc.w	0,0
	dc.w	37,0
	dc.w	37,10
	dc.w	0,10
	dc.w	0,1
fileratiobit:
	dc.l	minspace
	dc.w	156,183
	dc.w	29,9
	dc.w	GADGHIMAGE+GADGIMAGE
	dc.w	RELVERIFY+TOGGLESELECT
	dc.w	BOOLGADGET
	dc.l	Image1
	dc.l	Image2
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.w	NULL
	dc.l	NULL
Image1:
	dc.w	0,0
	dc.w	27,11
	dc.w	2
	dc.l	ImageData1
	dc.b	$0003,$0000
	dc.l	NULL
Image2:
	dc.w	0,0
	dc.w	27,11
	dc.w	2
	dc.l	ImageData2
	dc.b	$0003,$0000
	dc.l	NULL
minspace:
	dc.l	maxmsglines
	dc.w	207,185
	dc.w	34,8
	dc.w	NULL
	dc.w	RELVERIFY+LONGINT+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border14
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	minspaceSInfo
	dc.w	18
	dc.l	NULL
minspaceSInfo:
	dc.l	minspaceSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	4
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
minspaceSIBuff:
	dc.b	'100',0
	cnop 0,2
Border14:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors14
	dc.l	NULL
BorderVectors14:
	dc.w	0,0
	dc.w	37,0
	dc.w	37,10
	dc.w	0,10
	dc.w	0,1
maxmsglines:
	dc.l	sleeptime
	dc.w	16,149
	dc.w	34,8
	dc.w	NULL
	dc.w	RELVERIFY+LONGINT+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border15
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	maxmsglinesSInfo
	dc.w	14
	dc.l	NULL
maxmsglinesSInfo:
	dc.l	maxmsglinesSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	5
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
maxmsglinesSIBuff:
	dc.b	'300',0
	cnop 0,2
Border15:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors15
	dc.l	NULL
BorderVectors15:
	dc.w	0,0
	dc.w	37,0
	dc.w	37,10
	dc.w	0,10
	dc.w	0,1
sleeptime:
	dc.l	byteratiobit
	dc.w	16,161
	dc.w	34,8
	dc.w	NULL
	dc.w	RELVERIFY+LONGINT+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border16
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	sleeptimeSInfo
	dc.w	15
	dc.l	NULL
sleeptimeSInfo:
	dc.l	sleeptimeSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	3
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
sleeptimeSIBuff:
	dc.b	'3',0
PWstringlen	set	*-sleeptimeSIBuff
	dcb.b 3-PWstringlen,0
	cnop 0,2
Border16:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors16
	dc.l	NULL
BorderVectors16:
	dc.w	0,0
	dc.w	37,0
	dc.w	37,10
	dc.w	0,10
	dc.w	0,1
byteratiobit:
	dc.l	Hometlf
	dc.w	156,171
	dc.w	29,9
	dc.w	GADGHIMAGE+GADGIMAGE
	dc.w	RELVERIFY+TOGGLESELECT
	dc.w	BOOLGADGET
	dc.l	Image3
	dc.l	Image4
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.w	NULL
	dc.l	NULL
Image3:
	dc.w	0,0
	dc.w	27,11
	dc.w	2
	dc.l	ImageData3
	dc.b	$0003,$0000
	dc.l	NULL
Image4:
	dc.w	0,0
	dc.w	27,11
	dc.w	2
	dc.l	ImageData4
	dc.b	$0003,$0000
	dc.l	NULL
Hometlf:
	dc.l	Worktlf
	dc.w	16,97
	dc.w	99,8
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	STRGADGET
	dc.l	Border17
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	HometlfSInfo
	dc.w	5
	dc.l	NULL
HometlfSInfo:
	dc.l	HometlfSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	18
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
HometlfSIBuff:
	dcb.b 18,0
	cnop 0,2
Border17:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors17
	dc.l	NULL
BorderVectors17:
	dc.w	0,0
	dc.w	100,0
	dc.w	100,10
	dc.w	0,10
	dc.w	0,1
Worktlf:
	dc.l	filedirbit
	dc.w	122,97
	dc.w	99,8
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	STRGADGET
	dc.l	Border18
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	WorktlfSInfo
	dc.w	6
	dc.l	NULL
WorktlfSInfo:
	dc.l	WorktlfSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	18
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
WorktlfSIBuff:
	dcb.b 18,0
	cnop 0,2
Border18:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors18
	dc.l	NULL
BorderVectors18:
	dc.w	0,0
	dc.w	100,0
	dc.w	100,10
	dc.w	0,10
	dc.w	0,1
filedirbit:
	dc.l	confbit
	dc.w	368,101
	dc.w	75,9
	dc.w	GADGHIMAGE+GADGIMAGE
	dc.w	RELVERIFY+TOGGLESELECT
	dc.w	BOOLGADGET
	dc.l	Image5
	dc.l	Image6
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.w	-1
	dc.l	NULL
Image5:
	dc.w	-1,-1
	dc.w	76,11
	dc.w	2
	dc.l	ImageData5
	dc.b	$0003,$0000
	dc.l	NULL
Image6:
	dc.w	-1,-1
	dc.w	76,11
	dc.w	2
	dc.l	ImageData6
	dc.b	$0003,$0000
	dc.l	NULL
confbit:
	dc.l	bigup
	dc.w	445,101
	dc.w	91,9
	dc.w	GADGHIMAGE+GADGIMAGE+GFLG_SELECTED
	dc.w	RELVERIFY+TOGGLESELECT
	dc.w	BOOLGADGET
	dc.l	Image7
	dc.l	Image8
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.w	-2
	dc.l	NULL
Image7:
	dc.w	-1,-1
	dc.w	92,11
	dc.w	2
	dc.l	ImageData7
	dc.b	$0003,$0000
	dc.l	NULL
Image8:
	dc.w	-1,-1
	dc.w	92,11
	dc.w	2
	dc.l	ImageData8
	dc.b	$0003,$0000
	dc.l	NULL
bigup:
	dc.l	bigdown
	dc.w	542,101
	dc.w	32,9
	dc.w	GADGHIMAGE+GADGIMAGE+GFLG_DISABLED
	dc.w	RELVERIFY
	dc.w	BOOLGADGET
	dc.l	Image9
	dc.l	Image10
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.w	-3
	dc.l	NULL
Image9:
	dc.w	-3,-1
	dc.w	38,11
	dc.w	2
	dc.l	ImageData9
	dc.b	$0003,$0000
	dc.l	NULL
Image10:
	dc.w	-3,-1
	dc.w	38,11
	dc.w	2
	dc.l	ImageData10
	dc.b	$0003,$0000
	dc.l	NULL
bigdown:
	dc.l	slidebar
	dc.w	580,101
	dc.w	34,9
	dc.w	GADGHIMAGE+GADGIMAGE+GFLG_DISABLED
	dc.w	RELVERIFY
	dc.w	BOOLGADGET
	dc.l	Image11
	dc.l	Image12
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.w	-4
	dc.l	NULL
Image11:
	dc.w	-2,-1
	dc.w	38,11
	dc.w	2
	dc.l	ImageData11
	dc.b	$0003,$0000
	dc.l	NULL
Image12:
	dc.w	-2,-1
	dc.w	38,11
	dc.w	2
	dc.l	ImageData12
	dc.b	$0003,$0000
	dc.l	NULL
slidebar:
	dc.l	up
	dc.w	617,100
	dc.w	17,44
	dc.w	NULL	;GADGIMAGE
	dc.w	RELVERIFY
	dc.w	PROPGADGET
	dc.l	Image13
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	slidebarSInfo
	dc.w	-5
	dc.l	NULL
slidebarSInfo:
	dc.w	AUTOKNOB+FREEVERT+PROPNEWLOOK
	dc.w	MAXPOT,MAXPOT
	dc.w	MAXBODY,MAXBODY
	dc.w	0,0,0,0,0,0
Image13:
	dc.w	0,0
	dc.w	10,40
	dc.w	0
	dc.l	NULL
	dc.b	$0000,$0000
	dc.l	NULL
up:
	dc.l	down
	dc.w	619,146
	dc.w	15,7
	dc.w	GADGHIMAGE+GADGIMAGE
	dc.w	RELVERIFY
	dc.w	BOOLGADGET
	dc.l	Image14
	dc.l	Image15
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.w	-6
	dc.l	NULL
Image14:
	dc.w	0,0
	dc.w	13,8
	dc.w	2
	dc.l	ImageData14
	dc.b	$0003,$0000
	dc.l	NULL
Image15:
	dc.w	0,0
	dc.w	13,8
	dc.w	2
	dc.l	ImageData15
	dc.b	$0003,$0000
	dc.l	NULL
down:
	dc.l	name1
	dc.w	619,155
	dc.w	14,7
	dc.w	GADGHIMAGE+GADGIMAGE
	dc.w	RELVERIFY
	dc.w	BOOLGADGET
	dc.l	Image16
	dc.l	Image17
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.w	-7
	dc.l	NULL
Image16:
	dc.w	0,0
	dc.w	13,8
	dc.w	2
	dc.l	ImageData16
	dc.b	$0003,$0000
	dc.l	NULL
Image17:
	dc.w	0,0
	dc.w	13,8
	dc.w	2
	dc.l	ImageData17
	dc.b	$0003,$0000
	dc.l	NULL
name1:
	dc.l	name2
	dc.w	368,113
	dc.w	246,9
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	BOOLGADGET
	dc.l	Border19
	dc.l	NULL
	dc.l	IText51
	dc.l	NULL
	dc.l	NULL
	dc.w	-8
	dc.l	NULL
Border19:
	dc.w	-1,-1
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors19
	dc.l	NULL
BorderVectors19:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,40
	dc.w	0,40
	dc.w	0,1
IText51:
	dc.b	3,0,RP_JAM2,0
	dc.w	1,1
	dc.l	NULL
	dc.l	ITextText51
	dc.l	NULL
ITextText51:
	ds.b	Sizeof_NameT+2
	cnop 0,2
name2:
	dc.l	name3
	dc.w	368,123
	dc.w	246,9
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	BOOLGADGET
	dc.l	Border20
	dc.l	NULL
	dc.l	IText52
	dc.l	NULL
	dc.l	NULL
	dc.w	-9
	dc.l	NULL
Border20:
	dc.w	-1,-1
	dc.b	0,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors20
	dc.l	NULL
BorderVectors20:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,10
	dc.w	0,10
	dc.w	0,0
IText52:
	dc.b	3,0,RP_JAM2,0
	dc.w	1,1
	dc.l	NULL
	dc.l	ITextText52
	dc.l	NULL
ITextText52:
	ds.b	Sizeof_NameT+2
	cnop 0,2
name3:
	dc.l	name4
	dc.w	368,133
	dc.w	246,9
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	BOOLGADGET
	dc.l	Border21
	dc.l	NULL
	dc.l	IText53
	dc.l	NULL
	dc.l	NULL
	dc.w	-10
	dc.l	NULL
Border21:
	dc.w	-1,-1
	dc.b	0,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors21
	dc.l	NULL
BorderVectors21:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,10
	dc.w	0,10
	dc.w	0,0
IText53:
	dc.b	3,0,RP_JAM2,0
	dc.w	1,1
	dc.l	NULL
	dc.l	ITextText53
	dc.l	NULL
ITextText53:
	ds.b	Sizeof_NameT+2
	cnop 0,2
name4:
	dc.l	CFName
	dc.w	368,143
	dc.w	246,9
	dc.w	NULL
	dc.w	RELVERIFY
	dc.w	BOOLGADGET
	dc.l	Border22
	dc.l	NULL
	dc.l	IText54
	dc.l	NULL
	dc.l	NULL
	dc.w	-11
	dc.l	NULL
Border22:
	dc.w	-1,-1
	dc.b	0,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors22
	dc.l	NULL
BorderVectors22:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,10
	dc.w	0,10
	dc.w	0,0
IText54:
	dc.b	3,0,RP_JAM2,0
	dc.w	1,1
	dc.l	NULL
	dc.l	ITextText54
	dc.l	NULL
ITextText54:
	ds.b	Sizeof_NameT+2
	cnop 0,2
CFName:
	dc.l	scan
	dc.w	370,156
	dc.w	244,8
	dc.w	GFLG_DISABLED
	dc.w	RELVERIFY+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border23
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	CFNameSInfo
	dc.w	-12
	dc.l	NULL
CFNameSInfo:
	dc.l	CFNameSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	31
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
CFNameSIBuff:
	dcb.b 31,0
	cnop 0,2
Border23:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors23
	dc.l	NULL
BorderVectors23:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,10
	dc.w	0,10
	dc.w	0,1
scan:
	dc.l	Bits
	dc.w	488,180
	dc.w	33,8
	dc.w	GFLG_DISABLED
	dc.w	RELVERIFY+LONGINT+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border26
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	scanSInfo
	dc.w	-15
	dc.l	NULL
scanSInfo:
	dc.l	scanSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	4
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
scanSIBuff:
	dcb.b 4,0
	cnop 0,2
Border26:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors26
	dc.l	NULL
BorderVectors26:
	dc.w	0,0
	dc.w	37,0
	dc.w	37,10
	dc.w	0,10
	dc.w	0,1
Bits:
	dc.l	order
	dc.w	541,180
	dc.w	72,8
	dc.w	GFLG_DISABLED
	dc.w	RELVERIFY+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border27
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	BitsSInfo
	dc.w	-16
	dc.l	NULL
BitsSInfo:
	dc.l	BitsSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	9
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
BitsSIBuff:
	dcb.b 9,0
	cnop 0,2
Border27:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors27
	dc.l	NULL
BorderVectors27:
	dc.w	0,0
	dc.w	76,0
	dc.w	76,10
	dc.w	0,10
	dc.w	0,1
order:
	dc.l	path
	dc.w	435,180
	dc.w	32,8
	dc.w	GFLG_DISABLED
	dc.w	RELVERIFY+LONGINT+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border25
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	orderSInfo
	dc.w	-14
	dc.l	NULL
orderSInfo:
	dc.l	orderSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	4
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
orderSIBuff:
	dcb.b 4,0
	cnop 0,2
Border25:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors25
	dc.l	NULL
BorderVectors25:
	dc.w	0,0
	dc.w	37,0
	dc.w	37,10
	dc.w	0,10
	dc.w	0,1

path:	dc.l	NULL
	dc.w	370,168
	dc.w	244,8
	dc.w	GFLG_DISABLED
	dc.w	RELVERIFY+ALTKEYMAP
	dc.w	STRGADGET
	dc.l	Border24
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	pathSInfo
	dc.w	-13
	dc.l	NULL
pathSInfo:
	dc.l	pathSIBuff
	dc.l	UNDOBUFFER
	dc.w	0
	dc.w	31
	dc.w	0
	dc.w	0,0,0,0,0
	dc.l	0
	dc.l	0
	dc.l	NULL
pathSIBuff:
	dcb.b 31,0
	cnop 0,2
Border24:
	dc.w	-3,-2
	dc.b	3,0,RP_JAM1
	dc.b	5
	dc.l	BorderVectors24
	dc.l	NULL
BorderVectors24:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,10
	dc.w	0,10
	dc.w	0,1

MenuList1:
Menu1:
	dc.l	Menu2
	dc.w	0,0
	dc.w	63,0
	dc.w	MENUENABLED
	dc.l	Menu1Name
	dc.l	MenuItem1
	dc.w	0,0,0,0
Menu1Name:
	dc.b	'Project',0
	cnop 0,2
MenuItem1:
	dc.l	MenuItem2
	dc.w	0,0
	dc.w	128,8
	dc.w	ITEMTEXT+COMMSEQ+ITEMENABLED+HIGHCOMP
	dc.l	0
	dc.l	IText1
	dc.l	NULL
	dc.b	'L'
	dc.b	NULL
	dc.l	NULL
	dc.w	MENUNULL
IText1:
	dc.b	3,1,RP_COMPLEMENT,0
	dc.w	0,0
	dc.l	NULL
	dc.l	ITextText1
	dc.l	NULL
ITextText1:
	dc.b	'Load Config',0
	cnop 0,2
MenuItem2:
	dc.l	MenuItem3
	dc.w	0,8
	dc.w	128,8
	dc.w	ITEMTEXT+COMMSEQ+ITEMENABLED+HIGHCOMP
	dc.l	0
	dc.l	IText2
	dc.l	NULL
	dc.b	'S'
	dc.b	NULL
	dc.l	NULL
	dc.w	MENUNULL
IText2:
	dc.b	3,1,RP_COMPLEMENT,0
	dc.w	0,0
	dc.l	NULL
	dc.l	ITextText2
	dc.l	NULL
ITextText2:
	dc.b	'Save Config',0
	cnop 0,2
MenuItem3:
	dc.l	NULL
	dc.w	0,16
	dc.w	128,8
	dc.w	ITEMTEXT+COMMSEQ+ITEMENABLED+HIGHCOMP
	dc.l	0
	dc.l	IText3
	dc.l	NULL
	dc.b	'Q'
	dc.b	NULL
	dc.l	NULL
	dc.w	MENUNULL
IText3:
	dc.b	3,1,RP_COMPLEMENT,0
	dc.w	0,0
	dc.l	NULL
	dc.l	ITextText3
	dc.l	NULL
ITextText3:
	dc.b	'Quit',0
	cnop 0,2
Menu2:
	dc.l	Menu3
	dc.w	70,0
	dc.w	71,0
	dc.w	MENUENABLED
	dc.l	Menu2Name
	dc.l	MenuItem4
	dc.w	0,0,0,0
Menu2Name:
	dc.b	'Features',0
	cnop 0,2
MenuItem4:
	dc.l	MenuItem5
	dc.w	0,0
	dc.w	131,8
	dc.w	CHECKIT+ITEMTEXT+MENUTOGGLE+ITEMENABLED+HIGHCOMP
	dc.l	0
	dc.l	IText4
	dc.l	NULL
	dc.b	NULL
	dc.b	NULL
	dc.l	NULL
	dc.w	MENUNULL
IText4:
	dc.b	3,1,RP_COMPLEMENT,0
	dc.w	19,0
	dc.l	NULL
	dc.l	ITextText4
	dc.l	NULL
ITextText4:
	dc.b	'Interlaced',0
	cnop 0,2
MenuItem5:
	dc.l	MenuItem6
	dc.w	0,8
	dc.w	131,8
	dc.w	CHECKIT+ITEMTEXT+MENUTOGGLE+ITEMENABLED+HIGHCOMP
	dc.l	0
	dc.l	IText5
	dc.l	NULL
	dc.b	NULL
	dc.b	NULL
	dc.l	NULL
	dc.w	MENUNULL
IText5:
	dc.b	3,1,RP_COMPLEMENT,0
	dc.w	19,0
	dc.l	NULL
	dc.l	ITextText5
	dc.l	NULL
ITextText5:
	dc.b	'8 Colors',0
	cnop 0,2
MenuItem6:
	dc.l	NewMenuItem1
	dc.w	0,16
	dc.w	131,8
	dc.w	ITEMTEXT+ITEMENABLED+HIGHCOMP
	dc.l	0
	dc.l	IText6
	dc.l	NULL
	dc.b	NULL
	dc.b	NULL
	dc.l	SubItem1
	dc.w	MENUNULL
IText6:
	dc.b	3,1,RP_COMPLEMENT,0
	dc.w	19,0
	dc.l	NULL
	dc.l	ITextText6
	dc.l	NULL
ITextText6:
	dc.b	'Charset ISO',0
	cnop 0,2
SubItem1:
	dc.l	SubItem2
	dc.w	92,-8
	dc.w	24,8
	dc.w	ITEMTEXT+ITEMENABLED+HIGHCOMP
	dc.l	0
	dc.l	IText7
	dc.l	NULL
	dc.b	NULL
	dc.b	NULL
	dc.l	NULL
	dc.w	MENUNULL
IText7:
	dc.b	3,1,RP_COMPLEMENT,0
	dc.w	0,0
	dc.l	NULL
	dc.l	ITextText7
	dc.l	NULL
ITextText7:
	dc.b	'ISO',0
	cnop 0,2
SubItem2:
	dc.l	SubItem3
	dc.w	92,0
	dc.w	24,8
	dc.w	ITEMTEXT+ITEMENABLED+HIGHCOMP
	dc.l	0
	dc.l	IText8
	dc.l	NULL
	dc.b	NULL
	dc.b	NULL
	dc.l	NULL
	dc.w	MENUNULL
IText8:
	dc.b	3,1,RP_COMPLEMENT,0
	dc.w	0,0
	dc.l	NULL
	dc.l	ITextText8
	dc.l	NULL
ITextText8:
	dc.b	'IBM',0
	cnop 0,2
SubItem3:
	dc.l	NULL
	dc.w	92,8
	dc.w	24,8
	dc.w	ITEMTEXT+ITEMENABLED+HIGHCOMP
	dc.l	0
	dc.l	IText9
	dc.l	NULL
	dc.b	NULL
	dc.b	NULL
	dc.l	NULL
	dc.w	MENUNULL
IText9:
	dc.b	3,1,RP_COMPLEMENT,0
	dc.w	0,0
	dc.l	NULL
	dc.l	ITextText9
	dc.l	NULL
ITextText9:
	dc.b	'IBN',0
	cnop 0,2


NewMenuItem1
	dc.l	NewMenuItem2
	dc.w	0,24
	dc.w	131,8
	dc.w	CHECKIT+ITEMTEXT+MENUTOGGLE+ITEMENABLED+HIGHCOMP
	dc.l	0
	dc.l	NewIText1
	dc.l	NULL
	dc.b	NULL
	dc.b	NULL
	dc.l	NULL
	dc.w	MENUNULL
NewIText1:
	dc.b	3,1,RP_COMPLEMENT,0
	dc.w	19,0
	dc.l	NULL
	dc.l	NewITextText1
	dc.l	NULL
NewITextText1:
	dc.b	'Allow TmpSysop',0
	cnop 0,2

NewMenuItem2
	dc.l	NULL
	dc.w	0,32
	dc.w	131,8
	dc.w	CHECKIT+ITEMTEXT+MENUTOGGLE+ITEMENABLED+HIGHCOMP
	dc.l	0
	dc.l	NewIText2
	dc.l	NULL
	dc.b	NULL
	dc.b	NULL
	dc.l	NULL
	dc.w	MENUNULL
NewIText2:
	dc.b	3,1,RP_COMPLEMENT,0
	dc.w	19,0
	dc.l	NULL
	dc.l	NewITextText2
	dc.l	NULL
NewITextText2:
	dc.b	'Use ASL',0
	cnop 0,2


Menu3:
	dc.l	NULL
	dc.w	148,0
	dc.w	111,0
	dc.w	MENUENABLED
	dc.l	Menu3Name
	dc.l	MenuItem7
	dc.w	0,0,0,0
Menu3Name:
	dc.b	'New Users May',0
	cnop 0,2
MenuItem7:
	dc.l	MenuItem8
	dc.w	0,0
	dc.w	83,8
	dc.w	CHECKIT+ITEMTEXT+MENUTOGGLE+ITEMENABLED+HIGHCOMP
	dc.l	0
	dc.l	IText10
	dc.l	NULL
	dc.b	NULL
	dc.b	NULL
	dc.l	NULL
	dc.w	MENUNULL
IText10:
	dc.b	3,1,RP_COMPLEMENT,0
	dc.w	19,0
	dc.l	NULL
	dc.l	ITextText10
	dc.l	NULL
ITextText10:
	dc.b	'Upload',0
	cnop 0,2
MenuItem8:
	dc.l	NULL
	dc.w	0,8
	dc.w	83,8
	dc.w	CHECKIT+ITEMTEXT+MENUTOGGLE+ITEMENABLED+HIGHCOMP
	dc.l	0
	dc.l	IText11
	dc.l	NULL
	dc.b	NULL
	dc.b	NULL
	dc.l	NULL
	dc.w	MENUNULL
IText11:
	dc.b	3,1,RP_COMPLEMENT,0
	dc.w	19,0
	dc.l	NULL
	dc.l	ITextText11
	dc.l	NULL
ITextText11:
	dc.b	'Download',0
	cnop 0,2
IntuiTextList1:
IText12:
	dc.b	3,0,RP_JAM2,0
	dc.w	54,125
	dc.l	NULL
	dc.l	ITextText12
	dc.l	IText13
ITextText12:
	dc.b	'Time limit',0
	cnop 0,2
IText13:
	dc.b	3,0,RP_JAM2,0
	dc.w	55,137
	dc.l	NULL
	dc.l	ITextText13
	dc.l	IText14
ITextText13:
	dc.b	'File Time Limit',0
	cnop 0,2
IText14:
	dc.b	3,0,RP_JAM2,0
	dc.w	54,185
	dc.l	NULL
	dc.l	ITextText14
	dc.l	IText15
ITextText14:
	dc.b	'File Ratio',0
	cnop 0,2
IText15:
	dc.b	3,0,RP_JAM2,0
	dc.w	55,173
	dc.l	NULL
	dc.l	ITextText15
	dc.l	IText16
ITextText15:
	dc.b	'KByte Ratio',0
	cnop 0,2
IText16:
	dc.b	3,0,RP_JAM2,0
	dc.w	246,185
	dc.l	NULL
	dc.l	ITextText16
	dc.l	IText17
ITextText16:
	dc.b	'Min UL Space',0
	cnop 0,2
IText17:
	dc.b	3,0,RP_JAM2,0
	dc.w	55,149
	dc.l	NULL
	dc.l	ITextText17
	dc.l	IText18
ITextText17:
	dc.b	'Max Lines In Msgs',0
	cnop 0,2
IText18:
	dc.b	3,0,RP_JAM2,0
	dc.w	54,161
	dc.l	NULL
	dc.l	ITextText18
	dc.l	IText19
ITextText18:
	dc.b	'Sleep Time',0
	cnop 0,2
IText19:
	dc.b	3,0,RP_JAM2,0
	dc.w	432,190
	dc.l	NULL
	dc.l	ITextText19
	dc.l	IText20
ITextText19:
	dc.b	'Order  Scan  Bits',0
	cnop 0,2
IText20:
	dc.b	2,0,RP_JAM2,0
	dc.w	14,13
	dc.l	NULL
	dc.l	ITextText20
	dc.l	IText21
ITextText20:
	dc.b	'SYSOP INFO',0
	cnop 0,2
IText21:
	dc.b	3,0,RP_JAM2,0
	dc.w	237,87
	dc.l	NULL
	dc.l	ITextText21
	dc.l	IText22
ITextText21:
	dc.b	'Board Name',0
	cnop 0,2
IText22:
	dc.b	3,0,RP_JAM2,0
	dc.w	367,13
	dc.l	NULL
	dc.l	ITextText22
	dc.l	IText23
ITextText22:
	dc.b	'News Conference Name',0
	cnop 0,2
IText23:
	dc.b	3,0,RP_JAM2,0
	dc.w	367,35
	dc.l	NULL
	dc.l	ITextText23
	dc.l	IText24
ITextText23:
	dc.b	'Post Conference Name',0
	cnop 0,2
IText24:
	dc.b	3,0,RP_JAM2,0
	dc.w	367,57
	dc.l	NULL
	dc.l	ITextText24
	dc.l	IText25
ITextText24:
	dc.b	'UserInfo Conference Name',0
	cnop 0,2
IText25:
	dc.b	3,0,RP_JAM2,0
	dc.w	367,79
	dc.l	NULL
	dc.l	ITextText25
	dc.l	IText26
ITextText25:
	dc.b	'FileInfo Conference Name',0
	cnop 0,2
IText26:
	dc.b	3,0,RP_JAM2,0
	dc.w	14,24
	dc.l	NULL
	dc.l	ITextText26
	dc.l	IText27
ITextText26:
	dc.b	'Name',0
	cnop 0,2
IText27:
	dc.b	3,0,RP_JAM2,0
	dc.w	13,45
	dc.l	NULL
	dc.l	ITextText27
	dc.l	IText28
ITextText27:
	dc.b	'Address',0
	cnop 0,2
IText28:
	dc.b	3,0,RP_JAM2,0
	dc.w	13,66
	dc.l	NULL
	dc.l	ITextText28
	dc.l	IText29
ITextText28:
	dc.b	'Postal Code',0
	cnop 0,2
IText29:
	dc.b	3,0,RP_JAM2,0
	dc.w	13,87
	dc.l	NULL
	dc.l	ITextText29
	dc.l	IText30
ITextText29:
	dc.b	'Home Phone',0
	cnop 0,2
IText30:
	dc.b	3,0,RP_JAM2,0
	dc.w	120,87
	dc.l	NULL
	dc.l	ITextText30
	dc.l	IText31
ITextText30:
	dc.b	'Work Phone',0
	cnop 0,2
IText31:
	dc.b	3,0,RP_JAM2,0
	dc.w	265,24
	dc.l	NULL
	dc.l	ITextText31
	dc.l	NULL
ITextText31:
	dc.b	'Password',0
	cnop 0,2

;**************** requester tekst *****************
IText70:
	dc.b	1,0,RP_JAM2,0
	dc.w	6,3	;x,y
	dc.l	NULL
	dc.l	ITextText70
	dc.l	IText720

ITextText70:
	dc.b	'Can''t find ABBS''s msgport.',0
	cnop 0,2

IText720:
	dc.b	1,0,RP_JAM2,0
	dc.w	6,3+10	;x,y
	dc.l	NULL
	dc.l	ITextText720
	dc.l	NULL

ITextText720:
	dc.b	'You must run ABBS first !.',0
	cnop 0,2

IText80:
	dc.b	1,0,RP_JAM2,0
	dc.w	6,3	;x,y
	dc.l	NULL
	dc.l	ITextText80
	dc.l	NULL
ITextText80:
	dc.b	'Cancel',0
	cnop 0,2

IText90:
	dc.b	1,0,RP_JAM2,0
	dc.w	6,3	;x,y
	dc.l	NULL
	dc.l	ITextText90
	dc.l	NULL
ITextText90:
	dc.b	' Retry ',0
	cnop 0,2

	section	imagedata,data_c

ImageData1:
	dc.w	$0000,$0000,$0000,$0020,$0F07,$0720,$198C,$0C20
	dc.w	$199F,$1F20,$198C,$0C20,$198C,$0C20,$198C,$0C20
	dc.w	$0F0C,$0C20,$0000,$0020,$FFFF,$FFE0,$FFFF,$FFE0
	dc.w	$8000,$0000,$8F07,$0700,$998C,$0C00,$999F,$1F00
	dc.w	$998C,$0C00,$998C,$0C00,$998C,$0C00,$8F0C,$0C00
	dc.w	$8000,$0000,$0000,$0000

ImageData2:
	dc.w	$FFFF,$FFE0,$8000,$0000,$81E0,$0000,$8330,$0000
	dc.w	$8333,$E000,$8333,$3000,$8333,$3000,$8333,$3000
	dc.w	$81E3,$3000,$8000,$0000,$8000,$0000,$0000,$0000
	dc.w	$0000,$0020,$0000,$0020,$0000,$0020,$0000,$0020
	dc.w	$0000,$0020,$0000,$0020,$0000,$0020,$0000,$0020
	dc.w	$0000,$0020,$7FFF,$FFE0

ImageData3:
	dc.w	$0000,$0000,$0000,$0020,$0F07,$0720,$198C,$0C20
	dc.w	$199F,$1F20,$198C,$0C20,$198C,$0C20,$198C,$0C20
	dc.w	$0F0C,$0C20,$0000,$0020,$FFFF,$FFE0,$FFFF,$FFE0
	dc.w	$8000,$0000,$8F07,$0700,$998C,$0C00,$999F,$1F00
	dc.w	$998C,$0C00,$998C,$0C00,$998C,$0C00,$8F0C,$0C00
	dc.w	$8000,$0000,$0000,$0000
ImageData4:
	dc.w	$FFFF,$FFE0,$8000,$0000,$81E0,$0000,$8330,$0000
	dc.w	$8333,$E000,$8333,$3000,$8333,$3000,$8333,$3000
	dc.w	$81E3,$3000,$8000,$0000,$8000,$0000,$0000,$0000
	dc.w	$0000,$0020,$0000,$0020,$0000,$0020,$0000,$0020
	dc.w	$0000,$0020,$0000,$0020,$0000,$0020,$0000,$0020
	dc.w	$0000,$0020,$7FFF,$FFE0

ImageData5:
	dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w	$0000,$0010,$1F86,$0600,$001E,$0600,$0010,$1800
	dc.w	$0600,$001B,$0000,$0010,$1806,$060F,$0019,$861F
	dc.w	$0F10,$1E06,$0619,$8019,$8619,$9810,$1806,$061F
	dc.w	$8019,$8618,$0F10,$1806,$0618,$001B,$0618,$0190
	dc.w	$1803,$030F,$001E,$0318,$1F10,$0000,$0000,$0000
	dc.w	$0000,$0010,$FFFF,$FFFF,$FFFF,$FFFF,$FFF0,$FFFF
	dc.w	$FFFF,$FFFF,$FFFF,$FFF0,$8000,$0000,$0000,$0000
	dc.w	$0000,$9F86,$0600,$001E,$0600,$0000,$9800,$0600
	dc.w	$001B,$0000,$0000,$9806,$060F,$0019,$861F,$0F00
	dc.w	$9E06,$0619,$8019,$8619,$9800,$9806,$061F,$8019
	dc.w	$8618,$0F00,$9806,$0618,$001B,$0618,$0180,$9803
	dc.w	$030F,$001E,$0318,$1F00,$8000,$0000,$0000,$0000
	dc.w	$0000,$0000,$0000,$0000,$0000,$0000

ImageData6:
	dc.w	$FFFF,$FFFF,$FFFF,$FFFF,$FFF0,$8000,$0000,$0000
	dc.w	$0000,$0000,$9F86,$0600,$001E,$0600,$0000,$9800
	dc.w	$0600,$001B,$0000,$0000,$9806,$060F,$0019,$861F
	dc.w	$0F00,$9E06,$0619,$8019,$8619,$9800,$9806,$061F
	dc.w	$8019,$8618,$0F00,$9806,$0618,$001B,$0618,$0180
	dc.w	$9803,$030F,$001E,$0318,$1F00,$8000,$0000,$0000
	dc.w	$0000,$0000,$8000,$0000,$0000,$0000,$0000,$0000
	dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w	$0010,$0000,$0000,$0000,$0000,$0010,$0000,$0000
	dc.w	$0000,$0000,$0010,$0000,$0000,$0000,$0000,$0010
	dc.w	$0000,$0000,$0000,$0000,$0010,$0000,$0000,$0000
	dc.w	$0000,$0010,$0000,$0000,$0000,$0000,$0010,$0000
	dc.w	$0000,$0000,$0000,$0010,$0000,$0000,$0000,$0000
	dc.w	$0010,$7FFF,$FFFF,$FFFF,$FFFF,$FFF0

ImageData7:
	dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w	$0000,$0000,$0000,$0010,$0780,$0007,$0000,$0000
	dc.w	$0000,$0010,$0C00,$000C,$0000,$0000,$0000,$0010
	dc.w	$180F,$1F1F,$0F1F,$0F1F,$0F0F,$0F10,$1819,$998C
	dc.w	$1999,$9999,$9819,$9810,$1819,$998C,$1F98,$1F99
	dc.w	$981F,$8F10,$0C19,$998C,$1818,$1819,$9818,$0190
	dc.w	$078F,$198C,$0F18,$0F19,$8F0F,$1F10,$0000,$0000
	dc.w	$0000,$0000,$0000,$0010,$FFFF,$FFFF,$FFFF,$FFFF
	dc.w	$FFFF,$FFF0,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFF0
	dc.w	$8000,$0000,$0000,$0000,$0000,$0000,$8780,$0007
	dc.w	$0000,$0000,$0000,$0000,$8C00,$000C,$0000,$0000
	dc.w	$0000,$0000,$980F,$1F1F,$0F1F,$0F1F,$0F0F,$0F00
	dc.w	$9819,$998C,$1999,$9999,$9819,$9800,$9819,$998C
	dc.w	$1F98,$1F99,$981F,$8F00,$8C19,$998C,$1818,$1819
	dc.w	$9818,$0180,$878F,$198C,$0F18,$0F19,$8F0F,$1F00
	dc.w	$8000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w	$0000,$0000,$0000,$0000

ImageData8:
	dc.w	$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFF0,$8000,$0000
	dc.w	$0000,$0000,$0000,$0000,$8780,$0007,$0000,$0000
	dc.w	$0000,$0000,$8C00,$000C,$0000,$0000,$0000,$0000
	dc.w	$980F,$1F1F,$0F1F,$0F1F,$0F0F,$0F00,$9819,$998C
	dc.w	$1999,$9999,$9819,$9800,$9819,$998C,$1F98,$1F99
	dc.w	$981F,$8F00,$8C19,$998C,$1818,$1819,$9818,$0180
	dc.w	$878F,$198C,$0F18,$0F19,$8F0F,$1F00,$8000,$0000
	dc.w	$0000,$0000,$0000,$0000,$8000,$0000,$0000,$0000
	dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w	$0000,$0000,$0000,$0000,$0000,$0010,$0000,$0000
	dc.w	$0000,$0000,$0000,$0010,$0000,$0000,$0000,$0000
	dc.w	$0000,$0010,$0000,$0000,$0000,$0000,$0000,$0010
	dc.w	$0000,$0000,$0000,$0000,$0000,$0010,$0000,$0000
	dc.w	$0000,$0000,$0000,$0010,$0000,$0000,$0000,$0000
	dc.w	$0000,$0010,$0000,$0000,$0000,$0000,$0000,$0010
	dc.w	$0000,$0000,$0000,$0000,$0000,$0010,$7FFF,$FFFF
	dc.w	$FFFF,$FFFF,$FFFF,$FFF0

ImageData9:
	dc.w	$0000,$0000,$0000,$0000,$0000,$0400,$000C,$C000
	dc.w	$0400,$000C,$C000,$0400,$000C,$CF80,$0400,$000C
	dc.w	$CCC0,$0400,$000C,$CCC0,$0400,$000C,$CF80,$0400
	dc.w	$0007,$8C00,$0400,$0000,$0C00,$0400,$FFFF,$FFFF
	dc.w	$FC00,$FFFF,$FFFF,$FC00,$8000,$0000,$0000,$800C
	dc.w	$C000,$0000,$800C,$C000,$0000,$800C,$CF80,$0000
	dc.w	$800C,$CCC0,$0000,$800C,$CCC0,$0000,$800C,$CF80
	dc.w	$0000,$8007,$8C00,$0000,$8000,$0C00,$0000,$0000
	dc.w	$0000,$0000

ImageData10:
	dc.w	$FFFF,$FFFF,$FC00,$8000,$0000,$0000,$800C,$C000
	dc.w	$0000,$800C,$C000,$0000,$800C,$CF80,$0000,$800C
	dc.w	$CCC0,$0000,$800C,$CCC0,$0000,$800C,$CF80,$0000
	dc.w	$8007,$8C00,$0000,$8000,$0C00,$0000,$8000,$0000
	dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$0400,$0000
	dc.w	$0000,$0400,$0000,$0000,$0400,$0000,$0000,$0400
	dc.w	$0000,$0000,$0400,$0000,$0000,$0400,$0000,$0000
	dc.w	$0400,$0000,$0000,$0400,$0000,$0000,$0400,$7FFF
	dc.w	$FFFF,$FC00

ImageData11:
	dc.w	$0000,$0000,$0000,$0000,$0000,$0400,$0F00,$0000
	dc.w	$0400,$0D80,$0000,$0400,$0CC7,$98CF,$8400,$0CCC
	dc.w	$D8CC,$C400,$0CCC,$DACC,$C400,$0D8C,$DFCC,$C400
	dc.w	$0F07,$8D8C,$C400,$0000,$0000,$0400,$FFFF,$FFFF
	dc.w	$FC00,$FFFF,$FFFF,$FC00,$8000,$0000,$0000,$8F00
	dc.w	$0000,$0000,$8D80,$0000,$0000,$8CC7,$98CF,$8000
	dc.w	$8CCC,$D8CC,$C000,$8CCC,$DACC,$C000,$8D8C,$DFCC
	dc.w	$C000,$8F07,$8D8C,$C000,$8000,$0000,$0000,$0000
	dc.w	$0000,$0000

ImageData12:
	dc.w	$FFFF,$FFFF,$FC00,$8000,$0000,$0000,$8F00,$0000
	dc.w	$0000,$8D80,$0000,$0000,$8CC7,$98CF,$8000,$8CCC
	dc.w	$D8CC,$C000,$8CCC,$DACC,$C000,$8D8C,$DFCC,$C000
	dc.w	$8F07,$8D8C,$C000,$8000,$0000,$0000,$8000,$0000
	dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$0400,$0000
	dc.w	$0000,$0400,$0000,$0000,$0400,$0000,$0000,$0400
	dc.w	$0000,$0000,$0400,$0000,$0000,$0400,$0000,$0000
	dc.w	$0400,$0000,$0000,$0400,$0000,$0000,$0400,$7FFF
	dc.w	$FFFF,$FC00

ImageData13:
	dc.w	$0000,$2AC0,$5540,$2AC0,$5540,$2AC0,$FFC0,$FFC0
	dc.w	$D500,$AA80,$D500,$AA80,$D500,$0000

ImageData14:
	dc.w	$0000,$0008,$0208,$0508,$0888,$1048,$0008,$FFF8
	dc.w	$FFF8,$8000,$8000,$8000,$8000,$8000,$8000,$0000

ImageData15:
	dc.w	$FFF8,$8000,$8200,$8500,$8880,$9040,$8000,$8000
	dc.w	$0000,$0008,$0008,$0008,$0008,$0008,$0008,$7FF8

ImageData16:
	dc.w	$0000,$0008,$1048,$0888,$0508,$0208,$0008,$FFF8
	dc.w	$FFF8,$8000,$8000,$8000,$8000,$8000,$8000,$0000

ImageData17:
	dc.w	$FFF8,$8000,$9040,$8880,$8500,$8200,$8000,$8000
	dc.w	$0000,$0008,$0008,$0008,$0008,$0008,$0008,$7FF8
	END
