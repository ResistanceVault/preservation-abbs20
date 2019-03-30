	include	'abbs:first.i'

	include	'exec/types.i'
	include	'exec/memory.i'
	include	'libraries/dos.i'
	include	'intuition/intuition.i'

;debug = 1

	include	'asm.i'

	include	'bbs.i'

	CODE

MainBase	equr	a5

start	move.l	4,a6
	moveq.l	#0,d7			; full setup eller foradre
	openlib	dos
	openlib	int

;	moveq.l	#0,d0
;	move.l	d0,a0
;	bsr	CreatePort		; setter opp vår reply port
;	beq	no_port
;	move.l	d0,iport
;	lea	msg,a0			; Fyller i msg
;	move.l	d0,MN_REPLYPORT(a0)

;2$	move.l	#ConfigRecord_SIZEOF,d0 ; allokerer config minne
;	move.l	#MEMF_CLEAR,d1
;	jsrlib	AllocMem
;	move.l	d0,mem
;	beq	no_mem
;	move.l	d0,MainBase

3$
;	lea	Worktlf,a0
;	moveq.l	#0,d0
;	move.l	d0,(a0)			; slår av "fil requestor'en"
;	lea	IText18,a0
;	lea	IText20,a1
;	move.l	a1,it_NextText(a0)

	move.l	intbase,a6		; Opp med vindu !
	lea	NewWindowStructure1,a0
	jsrlib	OpenWindow
	move.l	d0,winadr
	beq	no_win
	move.l	d0,a0
	move.l	wd_RPort(a0),a0		; ut med tekst !
	lea	IntuiTextList1,a1
	moveq.l	#0,d0
	moveq.l	#0,d1
	jsrlib	PrintIText
	move.l	winadr,a0
	lea	MenuList1,a1
	jsrlib	SetMenuStrip
	tst.l	d0
	beq	no_menu

	move.l	winadr,a0
	move.l	wd_UserPort(a0),msgport
	lea	GadgetList1,a0		; aktiviserer første gadgeten.
	move.l	winadr,a1
	sub.l	a2,a2
	move.l	intbase,a6
	jsrlib	ActivateGadget
	move.l	4,a6

vent	move.l	msgport,a0
	jsrlib	WaitPort
	tst.l	d0
	beq.s	vent
	move.l	msgport,a0
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
	bmi.s	vent			; dropper negative for øyeblikket
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

6$	move.l	winadr,a1
	sub.l	a2,a2
	move.l	intbase,a6
	jsrlib	ActivateGadget
	move.l	4,a6
	bra	vent

2$	move.w	im_Code(a1),-(a7)
	jsrlib	ReplyMsg
	move.w	(a7)+,d0
3$	cmp.w	#MENUNULL,d0
	beq	vent
;	bra.s	ut



ut	move.l	intbase,a6
	move.l	winadr,d0
	jsrlib	ClearMenuStrip
no_menu	move.l	winadr,d0
	beq.s	no_win
	move.l	d0,a0
	jsrlib	CloseWindow
no_win	move.l	4,a6
;	move.l	mem,d0
;	beq.s	no_mem
;	move.l	d0,a1
;	move.l	#ConfigRecord_SIZEOF,d0
;	jsrlib	FreeMem
no_mem
no_abbs
;	move.l	iport,a0
;	bsr	DeletePort
no_port	closlib	int
no_int	closlib	dos
no_dos	rts


	BSS

msgport	ds.l	1
winadr	ds.l	1
dosbase	ds.l	1
intbase	ds.l	1

	DATA

dosname	dc.b	'dos.library',0
intname	dc.b	'intuition.library',0

	CNOP	0,2

activetabell
	dc.l	SysopPassword,SysopAddress,postal,Hometlf,Worktlf,Boardname
	dc.l	News,Post,Userinfo,Fileinfo,newtime,newfiletime,maxmsglines
	dc.l	sleeptime,byteratio,fileratio,minspace,Sysopname

;filedirbit
;confbit
;bigup
;bigdown
;slidebar
;up
;down
;name1
;name2
;name3
;name4
;CFName
;path
;order
;scan
;Bits



NewWindowStructure1:
	dc.w	0,0
	dc.w	640,200
	dc.b	0,1
	dc.l	IDCMP_GADGETUP+IDCMP_MENUPICK
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.w	NULL
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
	dc.b	'News',0
PWstringlen	set	*-NewsSIBuff
	dcb.b 31-PWstringlen,0
	cnop 0,2
Border5:
	dc.w	-3,-2
	dc.b	3,0,RP_COMPLEMENT
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
	dc.w	NULL
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.w	NULL
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.w	NULL
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.w	4
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.w	-1,-2
	dc.b	3,0,RP_COMPLEMENT
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
	dc.w	121,97
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
	dc.w	-1,-2
	dc.b	3,0,RP_COMPLEMENT
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
	dc.w	GADGHIMAGE+GADGIMAGE
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
	dc.w	29,9
	dc.w	GADGHIMAGE+GADGIMAGE
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
	dc.w	29,9
	dc.w	GADGHIMAGE+GADGIMAGE
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
	dc.w	GADGIMAGE
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
	dc.w	FREEVERT
	dc.w	0,7281
	dc.w	-1,6553
	dc.w	0,0,0,0,0,0
Image13:
	dc.w	0,3
	dc.w	10,7
	dc.w	2
	dc.l	ImageData13
	dc.b	$0003,$0000
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
	dc.w	RELVERIFY+TOGGLESELECT
	dc.w	BOOLGADGET
	dc.l	Border19
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.l	NULL
	dc.w	-8
	dc.l	NULL
Border19:
	dc.w	-1,-1
	dc.b	3,0,RP_COMPLEMENT
	dc.b	5
	dc.l	BorderVectors19
	dc.l	NULL
BorderVectors19:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,40
	dc.w	0,40
	dc.w	0,1
name2:
	dc.l	name3
	dc.w	368,123
	dc.w	246,9
	dc.w	NULL
	dc.w	RELVERIFY+TOGGLESELECT
	dc.w	BOOLGADGET
	dc.l	Border20
	dc.l	NULL
	dc.l	NULL
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
name3:
	dc.l	name4
	dc.w	368,133
	dc.w	246,9
	dc.w	NULL
	dc.w	RELVERIFY+TOGGLESELECT
	dc.w	BOOLGADGET
	dc.l	Border21
	dc.l	NULL
	dc.l	NULL
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
name4:
	dc.l	CFName
	dc.w	368,143
	dc.w	246,9
	dc.w	NULL
	dc.w	RELVERIFY+TOGGLESELECT
	dc.w	BOOLGADGET
	dc.l	Border22
	dc.l	NULL
	dc.l	NULL
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
CFName:
	dc.l	path
	dc.w	370,156
	dc.w	244,8
	dc.w	NULL
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
	dc.b	3,0,RP_COMPLEMENT
	dc.b	5
	dc.l	BorderVectors23
	dc.l	NULL
BorderVectors23:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,10
	dc.w	0,10
	dc.w	0,1
path:
	dc.l	order
	dc.w	370,168
	dc.w	244,8
	dc.w	NULL
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
	dc.b	3,0,RP_COMPLEMENT
	dc.b	5
	dc.l	BorderVectors24
	dc.l	NULL
BorderVectors24:
	dc.w	0,0
	dc.w	247,0
	dc.w	247,10
	dc.w	0,10
	dc.w	0,1
order:
	dc.l	scan
	dc.w	435,180
	dc.w	34,8
	dc.w	NULL
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
	dc.b	3,0,RP_COMPLEMENT
	dc.b	5
	dc.l	BorderVectors25
	dc.l	NULL
BorderVectors25:
	dc.w	0,0
	dc.w	37,0
	dc.w	37,10
	dc.w	0,10
	dc.w	0,1
scan:
	dc.l	Bits
	dc.w	488,180
	dc.w	34,8
	dc.w	NULL
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
	dc.b	3,0,RP_COMPLEMENT
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
	dc.l	NULL
	dc.w	541,180
	dc.w	73,8
	dc.w	NULL
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
	dc.b	3,0,RP_COMPLEMENT
	dc.b	5
	dc.l	BorderVectors27
	dc.l	NULL
BorderVectors27:
	dc.w	0,0
	dc.w	76,0
	dc.w	76,10
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
	dc.w	0,8
	dc.w	128,8
	dc.w	ITEMTEXT+COMMSEQ+ITEMENABLED+HIGHCOMP
	dc.l	0
	dc.l	IText1
	dc.l	NULL
	dc.b	'S'
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
	dc.b	'Save Config',0
	cnop 0,2
MenuItem2:
	dc.l	NULL
	dc.w	0,16
	dc.w	128,8
	dc.w	ITEMTEXT+COMMSEQ+ITEMENABLED+HIGHCOMP
	dc.l	0
	dc.l	IText2
	dc.l	NULL
	dc.b	'Q'
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
	dc.w	107,8
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
	dc.w	107,8
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
	dc.l	NULL
	dc.w	0,16
	dc.w	107,8
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
	dc.w	55,125
	dc.l	NULL
	dc.l	ITextText12
	dc.l	IText13
ITextText12:
	dc.b	'New User Time limit',0
	cnop 0,2
IText13:
	dc.b	3,0,RP_JAM2,0
	dc.w	55,137
	dc.l	NULL
	dc.l	ITextText13
	dc.l	IText14
ITextText13:
	dc.b	'New User File Time Limit',0
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
