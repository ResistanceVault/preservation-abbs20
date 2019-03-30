******************************************************************************
******									******
******		      ABBS - Amiga Bulletin Board System		******
******			 Written By Geir Inge Høsteng			******
******									******
******************************************************************************

*******************************************************************************
*									      *
* * * * * * * * * * * * *  Kode for Master task * * * * * * * * * * * * * * * *
*									      *
*******************************************************************************

 *****************************************************************
 *
 * NAME
 *	Main.asm
 *
 * DESCRIPTION
 *	Source for the ABBS main task
 *
 * AUTHOR
 *	Geir Inge Høsteng
 *
 * $Id: main.asm 1.2 1995/07/08 12:01:33 geirhos Exp geirhos $
 *
 * MODIFICATION HISTORY
 * $Log: main.asm $
;; Revision 1.2  1995/07/08  12:01:33  geirhos
;; removed unused code. small cleanup
;;
;; Revision 1.1  1995/06/24  10:32:07  geirhos
;; Initial revision
;;
 *
 *****************************************************************

	NOLIST
	include	'first.i'

	include	'exec/types.i'
	include	'exec/lists.i'
	include	'exec/ports.i'
	include	'exec/lists.i'
	include	'exec/io.i'
	include	'exec/memory.i'
	include	'exec/tasks.i'
	include	'exec/libraries.i'
	include	'exec/execbase.i'
	include	'dos/dos.i'
	include	'dos/dostags.i'
	include	'dos/dosextens.i'
	include	'utility/tagitem.i'
	include	'rexx/storage.i'
	include	'intuition/intuition.i'
	include	'intuition/screens.i'
	include	'graphics/gfxbase.i'
	include	'workbench/workbench.i'
	include	'libraries/commodities.i'
	include	'libraries/gadtools.i'
	include	'fifo.i'
	include	'ABBSmy.i'

	include	'asm.i'
	include	'bbs.i'

;	LIST

CreateMissingFiles EQU 1

	section kode,code

	XREF	comparestringsfull
	XREF	comparestringsifull
	XREF	comparestringsicase
	XREF	CreatePort
	XREF	DeletePort
	XREF	Exception
	XREF	fillinnodenr
	XREF	getkonfbulletname
	XREF	memcopylen
	XREF	memcopyrlen
	XREF	NewScreenStructure
	XREF	NewWindowStructure1
	XREF	publicportname
	XREF	nodestart
	XREF	nstart
	XREF	parserexxcmd
	XREF	strcopy
	XREF	atoi
	XREF	strcopymaxlen
	XREF	Environment
	XREF	upchar
	XREF	createmenutags
	XREF	MenuTags
	XREF	versionstr
	XREF	strlen
	XREF	memclr
	XREF	_AsmDeletePool
	XREF	_AsmCreatePool
	XREF	_AsmAllocPooled
	XREF	_AsmFreePooled

	XDEF	exebase
	XDEF	intbase
	XDEF	gfxbase
	XDEF	gadbase
	XDEF	aslbase
	XDEF	rexbase
	XDEF	dosbase
	XDEF	utibase
	XDEF	fifobase
	XDEF	dfobase
	XDEF	iffbase
	XDEF	utiname
	XDEF	mainstack
	XDEF	copyrighttext
	XDEF	protokollbaser
	XDEF	nodelist
	XDEF	mainscreenadr
	XDEF	abbsrootname
	XDEF	mainmemoryblock
	XDEF	main
	XDEF	mainmsgport
	XDEF	pubscreenname
	XDEF	MainTask

;exceptionhandler = 1

main	move.l	4.w,a6
	move.l	a7,mainstack
	moveq.l	#0,d0
	move.l	d0,wbmessage		; nullstiller, just in case
	move.l	ThisTask(a6),a0
	move.l	pr_CLI(a0),d0
	bne.b	1$			; startet fra cli
	push	a2			; henter wb startupmessage
	move.l	a0,a2
2$	lea	pr_MsgPort(a2),a0
	jsrlib	WaitPort
	lea	pr_MsgPort(a2),a0
	jsrlib	GetMsg
	move.l	d0,wbmessage
	beq.b	2$
	pop	a2
	bra	4$

1$
	IFD	sdfsdfsdf
	moveq.l	#0,d0
	move.l	#dosname,a1
	IFND	_LVOOpenLibrary
	XREF	_LVOOpenLibrary
	ENDIF
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,dosbase
	beq	mainsetuperror
	cmp.w	#36,LIB_VERSION(a6)	; Kjører vi på noe bedre enn 1.3 ?
	bcc.b	5$			; Jepp. Kjører.
	lea	need2.0text,a0
	bsr	writemainerror
	bra	mainsetuperror

5$	push	d2/d3/a6
	move.l	#readargsstring,d1
	lea	mainscreenadr,a0	; bruker som tmp buffer
	move.l	a0,d2
	moveq.l	#0,d3
	move.l	d3,(a0)+		; clearer
	move.l	d3,(a0)+
	move.l	dosbase,a6
	jsrlib	ReadArgs
	move.l	d0,d1
	bne.b	6$
	jsrlib	IoErr
	move.l	d0,d1
	move.l	#abbstext,d2
	jsrlib	PrintFault
	bra.b	7$
6$	jsrlib	FreeArgs

	push	a2
	lea	mainscreenadr,a2
; bruk argumentene..
	move.l	(a2)+,d0
	beq.b	8$
	move.l	d0,a0
	jsr	writemainerror
8$	move.l	(a2)+,d0
	beq.b	9$
	move.l	d0,a0
	jsr	writemainerror
9$	pop	a2
	move.l	dosbase,a6

7$	lea	mainscreenadr,a0	; tmp buffer
	moveq.l	#0,d0
	move.l	d0,(a0)+		; clearer igjen
	move.l	d0,(a0)+
	jsrlib	GetArgStr
	move.l	d0,a0
11$	move.b	(a0),d0			; ødelegger startup parametrene
	beq.b	10$
	move.b	#0,(a0)+
	bra.b	11$
10$	pop	d2/d3/a6
	ENDC

4$	bsr	mainsetup
	beq	mainsetuperror	; Branch if error
	bsr	loadconfigs	; load userdata ++ (needs work)
	bpl.b	3$		; normal sak. 
	bsr	openstatuswindow; ingen config, åpner vinduet så installasjon skal være lettere
	bra.b	main1		; Ingen config file, dummy mode
3$	beq	loadconfigserror	; ... error

	bsr	openfiles	; Åpner filer
	beq	openfileserror

	bsr	gettooltypes
	bsr	setupappicon
	bsr	setupcommodity
	beq	no_appicon
	bsr	startnodes	; Kick off each node.
	beq	startnodeserror	; No startup file.
	btst	#0,configbyte
	bne.b	main1		; skal ikke pop'e opp
	bsr	openstatuswindow

main1
1$	tst.w	mainshutdown
	bne	mainexit
	move.l	mainwait,d0	; Service requests
	jsrlib	Wait
	move.l	d0,-(sp)
	and.l	mainportsigbit,d0
	beq.b	2$
	bsr	mainportinput	; Some node wants a job done.
2$	move.l	(sp),d0
	move.l	mainscreenadr,d1
	beq.b	3$		; ingen skjerm oppe, så vi sjekker ikke
	and.l	mainintsigbit,d0
	beq.b	3$
	bsr	intuitioninput	; Intuition message.
3$	move.l	(sp),d0
	move.b	statusopen,d1
	beq.b	4$		; ikke noe status vindu oppe, gi f..
	and.l	maingadtosigbit,d0
	beq.b	4$
	bsr	gadtoolsinput	; Gadtools message.
	tst.b	closestatuswind
	beq.b	4$
	move.b	#0,closestatuswind
	move.b	statusopen,d0
	beq.b	4$
	bsr	closestatuswindow
4$	move.l	(sp),d0
	and.l	#SIGBREAKF_CTRL_C,d0
	beq.b	6$
	move.b	statusopen,d0
	bne.b	41$
	bsr	openstatuswindow
	bra.b	6$
41$	bsr	closestatuswindow
6$	move.l	(sp),d0
	and.l	#SIGBREAKF_CTRL_E,d0
	beq.b	5$
	bsr	updatenodelist
5$	move.l	(sp),d0
	and.l	maincommisigbit,d0
	beq.b	7$
	bsr	handlecommodity
7$	move.l	(sp)+,d0
	and.l	wbportsigbit,d0
	beq	1$
	bsr	wbinput		; WorkBench message.
	bra	1$

mainexit
	bsr	shutdownnodes	; free resources used for nodes.
	tst.w	lesconfigstatus
	beq.b	1$
	bsr	main_saveconfig	; Saves config (needs work)
1$
startnodeserror
	bsr	clearcommodity
	bsr	clearappicon
no_appicon
	bsr	closefiles
openfileserror
loadconfigserror
	bsr	mainclosedown	; close screen,window  ++
mainsetuperror
	move.l	wbmessage,d0
	beq.b	1$
	jsrlib	Forbid		; reply the wb message
	move.l	wbmessage,a1
	jsrlib	ReplyMsg
1$	moveq	#0,d0		; We don't need a return code, do we ?
	rts

; reads startupfile, and kick's off all nodes in there.
; returns z=1 for error, or Z=0 for no error
startnodes
	push	d2-d5/a2/a6
	link.w	a3,#-128
	move.w	#0,Nodes(MainBase)	; Zero nodes active
	move.l	dosbase,a6		; open startup file for read.
	move.l	#startupfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq	8$			; error : No startup file

3$	move.l	d4,d1			; leser et tegn
	move.l	sp,d2
	moveq.l	#127,d3
	jsrlib	FGets
	tst.l	d0			; null ?
	beq.b	2$			; Ja <=> EOF,error
	moveq.l	#0,d5			; ingen tegn

	move.l	sp,a0
1$	move.b	(a0)+,d0
	cmp.b	#10,d0			; NewLine ?
	beq.b	4$			; Jepp.
	cmp.b	#' ',d0			; Space ?
	beq.b	4$			; Jepp.
	cmp.b	#9,d0			; TAB ?
	beq.b	4$			; Jepp.
	cmp.b	#';',d0			; Semi kolon ?
	beq.b	4$			; Jepp
	addq.l	#1,d5			; tegnpos ++
	bra.b	1$

4$	tst.l	d5			; Tegnet var NL, eller komentar ferdig
	beq.b	3$			; strlen = 0 -> no name.
	move.b	#0,(-1,a0)		; markerer str slutt
	move.l	sp,a0			; navn i a0
	bsr	kickoffnode		; starter node
;	beq.b	3$			; error, prøver neste
	bra.b	3$

2$	move.l	d4,d1
	jsrlib	Close
	jsrlib	IoErr
	tst.l	d0
	notz
	bne.b	9$
	lea	(errstartfiltext),a0
	bra.b	81$
8$	lea	nostartfiletext,a0
81$	bsr	writemainerror
	setz
9$	unlk	a3
	pop	d2-d5/a2/a6
	rts

; d0 = nodenr
; a0 = string å legge navnet i (160 lang)
getnodeconfigfile
	push	d2-d6/a6/a2
	move.l	a0,a2
	move.l	d0,d6
	move.l	dosbase,a6		; open startup file for read.
	move.l	#startupfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq	9$			; error : No startup file

3$	move.l	d4,d1			; leser en string
	move.l	a2,d2
	moveq.l	#127,d3
	jsrlib	FGets
	tst.l	d0			; null ?
	beq.b	2$			; Ja <=> EOF,error
	moveq.l	#0,d5			; ingen tegn

	move.l	a2,a0
1$	move.b	(a0)+,d0
	cmp.b	#10,d0			; NewLine ?
	beq.b	4$			; Jepp.
	cmp.b	#' ',d0			; Space ?
	beq.b	4$			; Jepp.
	cmp.b	#9,d0			; TAB ?
	beq.b	4$			; Jepp.
	cmp.b	#';',d0			; Semi kolon ?
	beq.b	4$			; Jepp
	addq.l	#1,d5			; tegnpos ++
	bra.b	1$

4$	tst.l	d5			; Tegnet var NL, eller komentar ferdig
	beq.b	3$			; strlen = 0 -> no name.
	move.b	#0,(-1,a0)		; markerer str slutt
	sub.w	#1,d6			; teller ned
	bne.b	3$			; Vi er ikke ferdig enda, tar neste
	move.l	d4,d1
	jsrlib	Close
	clrz
	bra.b	9$

2$	move.l	d4,d1
	jsrlib	Close
	setz
9$	pop	d2-d6/a6/a2
	rts

; navn på config fila til noden
kickoffnode
	push	d2-d5/a2/a6
	move.l	exebase,a6
	move.l	a0,a2
	move.w	(MaxLinesMessage+CStr,MainBase),d0
	mulu	#LinesSize,d0
	add.l	#Nodenode_SIZEOF,d0
	move.l	d0,d2					; husker size'n
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	jsrlib	AllocMem
	move.l	d0,d5
	beq	1$
	addq.w	#1,Nodes(MainBase)
	move.l	d0,a0
	move.l	d2,Nodenode_alloc(a0)			; husker size'n
	move.l	a2,Nodeusernr(a0)			; Midlertidig lagersted
	move.w	Nodes(MainBase),Nodenr(a0)

	jsrlib	Forbid					; legger inn noden i lista
	move.l	a0,a1
	lea	nodelist,a0
	ADDTAIL
	jsrlib	Permit

	lea	CreateNewProcTags,a0
	move.l	#nstart,4(a0)				; slenger inn startkode
	move.l	a2,12(a0)				; slenger inn navnet
	move.l	a0,d1
	move.l	dosbase,a6
	jsrlib	CreateNewProc
;	bra.b	5$

;6$	sub.l	a1,a1					; arver prioritet
;	jsrlib	FindTask
;	move.l	d0,a0
;	moveq.l	#0,d2
;	move.b	(pr_Task+TC_Struct+LN_PRI,a0),d2
;	move.l	a2,d1					; name
;	move.l	#nodestart,d3
;	lsr.l	#2,d3
;	move.l	#4*4096,d4				; stack størrelse
;	move.l	dosbase,a6
;	jsrlib	CreateProc

5$	tst.l	d0					; gikk det bra ?
	bne.b	1$					; ja
	move.l	d5,a1					; fjerner fra lista
	lea	nodelist,a0
	REMOVE
	move.l	d5,a1					; frigir minne
	move.l	Nodenode_alloc(a1),d0
	move.l	exebase,a6
	jsrlib	FreeMem
	subq.w	#1,Nodes(MainBase)
	moveq.l	#0,d5
1$	move.l	d5,d0
	pop	d2-d5/a2/a6
	rts
; fjern currentdir saken (default med createnewproc)

shutdownnodes
	push	a2/d2
	move.l	nodelist+LH_HEAD,a2
1$	move.l	(LN_SUCC,a2),d2				; henter neste
	beq.b	9$
	move.l	a2,a1					; fjerner fra lista
	REMOVE
	move.l	a2,a1
	move.l	(Nodenode_alloc,a1),d0
	beq.b	2$
	jsrlib	FreeMem
2$	move.l	d2,a2
	bra.b	1$
9$	pop	a2/d2
	rts

intuitioninput
	push	d2/d3
intuitioninput1
	move.l	mainintuiport,a0
	jsrlib	GetMsg
	tst.l	d0
	beq	9$
	move.l	d0,a1
	move.l	im_Class(a1),d0
	cmp.l	#MENUPICK,d0
	bne	8$
	move.w	im_Code(a1),d2		; husker item
	move.w	d2,d0
	cmp.w	#MENUNULL,d0
	beq	8$
	move.w	d0,d1
	and.w	#$1f,d0			;menunum
	asr.w	#5,d1
;	move.w	d1,d2
	and.w	#$3f,d1			;itemnum
;	asr.w	#6,d2
;	and.w	#$1f,d2			;subnum

	push	d0/d1
	jsrlib	ReplyMsg
	pop	d0/d1

	tst.w	d0
	bne.b	2$
	tst.w	d1
	bne.b	9$

	move.w	MainBits(MainBase),d0		; er vi locked ?
	and.w	#MainBitsF_ABBSLocked,d0
	bne.b	3$				; ja, nekte
	tst.w	Nodes(MainBase)
	beq.b	1$
3$	move.l	intbase,a6
	move.l	mainscreenadr,a0
	jsrlib	DisplayBeep
	move.l	exebase,a6
	bra.b	9$
1$	move.w	#1,mainshutdown
	bra.b	9$

2$	cmp.w	#1,d0			; sysop available ?
	bne.b	9$
	tst.w	d1
	bne.b	9$
	move.l	intbase,a6
	move.l	(mainmenustruct),a0
	move.w	d2,d0
	jsrlib	ItemAddress
	move.l	(exebase),a6
	move.l	d0,a0
	move.w	MainBits(MainBase),d0
	and.w	#~MainBitsF_SysopNotAvail,d0
	move.w	mi_Flags(a0),d1
	and.w	#CHECKED,d1
	beq.b	21$
	or.w	#MainBitsF_SysopNotAvail,d0
21$	move.w	d0,MainBits(MainBase)
	bra.b	9$

8$	jsrlib	ReplyMsg
	bra	intuitioninput1
9$	pop	d2/d3
	rts

mainportinput
	push	a2
0$	move.l	mainmsgport,a0
	jsrlib	GetMsg
	tst.l	d0
	beq	9$
	move.l	d0,a2
	move.l	d0,a0
	XREF	CheckRexxMsg
	jsr	CheckRexxMsg			; arexx melding ??
	tst.l	d0
	beq.b	1$				; nope, vanelig
	move.l	ARG0(a2),a0			; kommandoen
	bsr	domainarexxcmd
	moveq.l	#0,d1
	move.l	d1,rm_Result2(a2)
	move.l	d0,rm_Result1(a2)	; setter RC
	bne.b	8$			; error
	move.l	a0,d0			; har vi en streng ?
	beq.b	8$			; nope
	move.l	ACTION(a2),d0		; vil han ha en string ?
	btst	#RXFB_RESULT,d0
	beq.b	8$			; nope
	move.l	rm_LibBase(a2),d0	; henter libbase
	beq.b	8$			; har ingen!
	move.l	d0,a6

	move.l	a0,a1			; strlen
	move.l	a0,d0
3$	tst.b	(a1)+
	bne.b	3$
	subq.l	#1,a1
	sub.l	d0,a1
	move.l	a1,d0
	jsrlib	CreateArgstring
	move.l	a2,a1
	move.l	d0,rm_Result2(a1)
	move.l	exebase,a6
	bra.b	8$

1$	move.l	a2,a0
	lea	msgportjumps,a1
	move.w	m_Command(a0),d0
	cmp.w	#Main_LASTCOMM,d0		; lovlig kommando ?
	bcc.b	2$				; nei
	asl.w	#2,d0
	move.l	0(a1,d0.w),a1
	jsr	(a1)
	bra.b	8$
2$	move.w	#Error_IllegalCMD,m_Error(a2)
8$	move.l	a2,a1
	tst.l	MN_REPLYPORT(a1)
	beq	0$
	jsrlib	ReplyMsg
	bra	0$				; Ta alle meldinger.
9$	pop	a2
	rts

wbinput	push	a2
0$	move.l	wbmsgport,a0
	jsrlib	GetMsg
	tst.l	d0
	beq	9$
	move.l	d0,a2
	move.l	d0,a0
	move.w	(am_Type,a0),d0
	cmp.w	#MTYPE_APPICON,d0
	bne.b	8$				; ukjennt sak
	move.b	statusopen,d0
	bne.b	1$
	bsr	openstatuswindow
	bra.b	8$
1$	bsr	closestatuswindow

8$	move.l	a2,a1
	tst.l	MN_REPLYPORT(a1)
	beq	0$
	jsrlib	ReplyMsg
	bra	0$				; Ta alle meldinger.
9$	pop	a2
	rts

gadtoolsinput
	push	a2/a6
	move.l	gadbase,a6
0$	move.l	maingadtoolport,a0
	jsrlib	GT_GetIMsg
	tst.l	d0
	beq	9$
	move.l	d0,a2
	move.l	im_Class(a2),d0
	cmp.l	#IDCMP_CLOSEWINDOW,d0
	bne.b	1$
	move.l	a2,a1
	jsrlib	GT_ReplyIMsg
	bsr	closestatuswindow
	bra.b	9$
1$	cmp.l	#IDCMP_NEWSIZE,d0
	beq.b	5$
	cmp.l	#IDCMP_SIZEVERIFY,d0
	bne.b	2$
5$	jsr	ABBSAppWindowRender
	bra.b	8$

2$	cmp.l	#IDCMP_GADGETUP,d0
	bne.b	3$
	move.l	(im_IAddress,a2),a0
	move.w	(gg_GadgetID,a0),d0
	move.w	(im_Code,a2),d1
	move.l	a2,a0
	bsr	handlestatusgadget
	bra.b	8$
3$	cmp.l	#IDCMP_MENUPICK,d0
	bne.b	4$
	move.w	(im_Code,a2),d0
	cmpi.w	#MENUNULL,d0
	beq.b	8$
	bsr	handlegadmenu
	bra.b	8$
4$	cmp.l	#IDCMP_VANILLAKEY,d0
	bne.b	8$
;	move.w	(ie_Qualifier,a2),d0	Tar alle qualifiere
	move.w	(im_Code,a2),d0
	bsr	handlevanillakey
8$	move.l	a2,a1
	jsrlib	GT_ReplyIMsg
	bra	0$
9$	pop	a2/a6
	rts

updatenodelist
	push	a2/a3/a6
	move.b	statusopen,d0
	beq.b	9$
	move.l	gadbase,a6
	move.l	ABBSAppWindowGadgets,a0
	move.l	ABBSAppWindowWnd,a1
	suba.l	a2,a2
	lea	(updatenodelisttags),a3
	jsrlib	GT_SetGadgetAttrsA
9$	pop	a2/a3/a6
	rts

handlevanillakey
	push	d2
	bsr	upchar
	lea	chartogadget,a0
	moveq.l	#0,d2
1$	move.b	(a0)+,d1
	beq.b	9$				; ferdig, ukjennt tegn
	addq.l	#1,d2
	cmp.b	d0,d1
	bne.b	1$
	move.l	d2,d0
	bsr	handlestatusgadget
9$	pop	d2
	rts

; d0 = menucode
handlegadmenu
	push	d2
0$	move.l	d0,d2				; husker menukode
	move.l	d0,d1
	lsr.l	#5,d1
	andi.w	#$3f,d1				; finner item nummeret
	andi.w	#$1f,d0				; finner menu nummeret
	bne.b	2$				; ikke menu 0
	move.w	d1,d0
	bne.b	11$				; ikke item 0
; Item  (0,0) - about
	bra.b	8$

11$	cmp.w	#2,d0
	bne.b	12$
	move.b	#1,closestatuswind		; Item  (0,2) - Iconify
	bra.b	8$

12$	cmp.w	#4,d0
	bne.b	8$
	move.l	(exebase),a6
	bsr	shutdownall
	move.w	MainBits(MainBase),d0		; er vi locked ?
	and.w	#MainBitsF_ABBSLocked,d0
	bne.b	7$				; ja, nekte
	move.w	Nodes(MainBase),d1		; Item  (0,4) - Quit
	bne.b	7$				; kan ikke
	move.w	#1,mainshutdown
	bra.b	8$

2$

7$	move.l	(intbase),a6
	suba.l	a0,a0				; nei, blinker vinduet.
	jsrlib	DisplayBeep
8$	movea.l	(intbase),a6			; Finner neste, hvis det er noen
	move.w	d2,d0
	movea.l	(ABBSAppWindowMenus),a0
	jsrlib	ItemAddress
	tst.l	d0
	beq.b	9$
	movea.l	d0,a0
	move.w	(mi_NextSelect,a0),d0
	cmp.w	#MENUNULL,d0
	bne.b	0$

9$	pop	d2
	move.l	gadbase,a6
	rts

; d0 = gadgetid
; d1 = Code (bare for listgadget, og cycle gadgeter)
; a0 = intuimessage  (bare for listgadget, og cycle gadgeter)
handlestatusgadget
	push	d2/d3/d4/a6
	move.l	intbase,a6
	move.w	d1,d4				; husker code
	cmp.w	#GD_ListViewGadget,d0
	bne.b	1$
	move.w	d1,activenode			; lagrer hvilken node det var
	move.l	oldclicksecs,d0			; sjekker om det var double click
	move.l	oldclickmicros,d1
	move.l	(im_Seconds,a0),d2
	move.l	(im_Micros,a0),d3
	move.l	d2,oldclicksecs
	move.l	d3,oldclickmicros
	jsrlib	DoubleClick
	tst.l	d0
	beq	9$				; ikke double, ikke vis noden
	moveq.l	#0,d0
	move.l	d0,oldclicksecs			; sletter gamle tider, for å hindre tripple click
	move.l	d0,oldclickmicros
	move.w	activenode,d0
	move.w	#Node_Show,d2
	bra.b	2$

1$	cmp.w	#GD_Win_size,d0
	bhi.b	9$				; for høy
	sub.w	#1,d0				; trekker ifra for listview'n
	ext.l	d0

	add.l	d0,d0
	lea	(gadgetcmdtable),a0
	moveq.l	#0,d2
	move.w	(a0,d0.w),d2			; husker i d2
	bmi.b	3$				; negative skal sendes som meldinger
	subq.l	#1,d2
	lsl.l	#2,d2
	lea	(gadgetjmptable),a0
	add.l	d2,a0
	move.l	(a0),a0
	move.l	d4,d0				; gir code videre
	move.l	(exebase),a6
	jsr	(a0)
	beq.b	8$
	bra.b	9$
3$	move.w	activenode,d0			; har vi en valgt ?
	cmp.w	#-1,d0
	bne.b	2$				; jepp
	suba.l	a0,a0				; nei, blinker vinduet.
	jsrlib	DisplayBeep
	bra.b	9$

2$	add.w	#1,d0				; har nodenummer i d0 nå
	move.l	exebase,a6
	move.w	d2,d1
	bsr	sendmsgtonodeasync
	bne.b	9$				; alt ok
	cmp.w	#Node_Show,d2			; Fant ikke noden (trolig nede)
	bne.b	8$				; blink hvis det ikke var show
	bsr	main_opennode			; da prøver vi å åpne noden
	bne.b	9$				; blinker ikke hvis det gikk bra.
8$	move.l	intbase,a6
	suba.l	a0,a0				; nei, blinker vinduet.
	jsrlib	DisplayBeep
9$	pop	d2/d3/d4/a6
	rts

; d0: code
; returner z = 1 for displaybeep
main_winsize
	move.l	ABBSAppWindowWnd,a0
	move.w	(wd_Height,a0),d1
	neg.w	d1
	tst.w	d0
	bne.b	1$				; 1 = Show
	add.w	statuswinheight,d1
	sub.w	#28,d1
	bra.b	2$
1$	add.w	statuswinheight,d1
2$	move.l	(intbase),a6
	moveq.l	#0,d0
	jsrlib	SizeWindow
9$	move.l	(exebase),a6
	clrz
	rts

main_closeabbs
	move.w	MainBits(MainBase),d1		; er vi locked ?
	and.w	#MainBitsF_ABBSLocked,d1
	bne.b	9$				; ja, nekte
	move.w	Nodes(MainBase),d1
	notz
	beq.b	9$				; kan ikke
	move.w	#1,mainshutdown			; husker at vi skal ned
9$	rts

main_opennode
	push	d2
	link.w	a3,#-128
	move.w	activenode,d2			; har vi en valgt ?
	cmp.w	#-1,d2
	beq.b	9$				; Nei, beep
	add.w	#1,d2
	move.w	d2,d0
	move.l	sp,a1
	lea	publicportname,a0
	bsr	fillinnodenr			; bygger opp navnet til porten
	move.l	sp,a1				; Ser om vi finner porten
	jsrlib	FindPort
	tst.l	d0
	notz
	beq.b	9$				; vi fant, da er den allerede oppe
	move.w	d2,d0
	move.l	sp,a0
	bsr	getnodeconfigfile
	beq.b	9$
	move.l	sp,a0
	move.w	activenode,d0
	add.w	#1,d0
	bsr	restartnode
9$	unlk	a3
	pop	d2
	rts

main_ejectall
	move.w	#Node_Eject,d0
	bsr	loopallopennodes
	rts

shutdownall
	move.w	#Node_Shutdown,d0
;	bra	loopallopennodes

; d0.w = command to send to all open nodes
loopallopennodes
	push	a2/d2/d3
	move.w	d0,d3
	move.l	nodelist+LH_HEAD,a2
1$	move.l	(LN_SUCC,a2),d2
	beq.b	9$
	move.w	(Nodenr,a2),d0
	beq.b	2$
	move.w	d3,d1
	bsr	sendmsgtonodeasync
	beq.b	99$
2$	move.l	d2,a2
	bra.b	1$
9$	clrz
99$	pop	a2/d2/d3
	rts

openstatuswindow
	push	a6/a2/a3
	move.b	#1,statusopen
	jsr	SetupScreen
	bne.b	closestatuswindow1
	jsr	OpenABBSAppWindowWindow
	bne.b	closestatuswindow1
	move.l	ABBSAppWindowWnd,a0
	move.w	(wd_Height,a0),statuswinheight
	move.l	wd_UserPort(a0),a0
	moveq	#0,d1
	move.b	MP_SIGBIT(a0),d1
	moveq.l	#0,d0
	bset	d1,d0
	move.l	d0,maingadtosigbit
	or.l	#SIGBREAKF_CTRL_E,d0
	or.l	d0,mainwait
	move.l	a0,maingadtoolport
	move.w	#-1,activenode			; sletter hvilken node som er valgt

;	move.l	(gadbase),a6
;	move.l	ABBSAppWindowWnd,a1
;	move.l	ABBSAppWindowGadgets,a0
;	moveq.l	#GDX_Win_size*4,d0
;	add.l	d0,a0
;	move.l	(a0),a0
;	suba.l	a2,a2
;	lea	(winsizetags),a3
;	jsrlib	GT_SetGadgetAttrsA
	pop	a6/a2/a3
	clrz
	rts

closestatuswindow
	push	a6
closestatuswindow1
	move.b	#0,statusopen
	move.l	maingadtosigbit,d0
	or.l	#SIGBREAKF_CTRL_E,d0
	not.l	d0
	and.l	d0,mainwait
	jsr	CloseABBSAppWindowWindow
	jsr	CloseDownScreen
	move.l	maingadtosigbit,d0		; fjerner gadtools sigbit'et
	or.l	#SIGBREAKF_CTRL_E,d0
	not.l	d0
	and.l	d0,mainwait
	pop	a6
	setz
	rts

; a0 = cmdline
domainarexxcmd
	lea	mainarexxcmdtxt,a1
	moveq.l	#1,d0			; vi kaller parserexxcmd ifra main
	bsr	parserexxcmd
	beq.b	9$			; ikke kjennt
	lea	mainarexxjmp,a0		; utfører kommandoen
	add.l	d0,a0
	move.l	(a0),a0
	jsr	(a0)			; utfører
9$	rts

; Arexx kommandoene
; de skal returnere:
; a0 - retur string til arexx programmet, 0 for ingen
; d0 - retur verdi til arexx programmet (RC)

rexx_shutdown
	moveq.l	#5,d0				; RC = 5, kan ikke lukke
	move.w	MainBits(MainBase),d1		; er vi locked ?
	and.w	#MainBitsF_ABBSLocked,d1
	bne.b	9$				; ja, nekte
	move.w	Nodes(MainBase),d1
	bne.b	9$
	move.w	#1,mainshutdown
	moveq.l	#0,d0				; RC = 0, alt ok
9$	sub.l	a0,a0				; ingen return string
	rts

rexx_startnode
	moveq.l	#10,d0				; error
	lea	txtbuffer(MainBase),a1
	move.l	rx_NumParam(a1),d1		; har vi 1 parameter ?
	beq.b	9$				; nope.
	move.l	rx_ptr1(a1),a0			; har configfilename
	moveq.l	#0,d0				; node nummeret
	bsr	restartnode
	beq.b	8$
	moveq.l	#0,d0
	bra.b	9$
8$	moveq.l	#5,d0				; RC = klarte ikke
9$	sub.l	a0,a0				; ingen return string
	rts

rexx_showgui
	lea	(txtbuffer,MainBase),a1
	move.l	(rx_NumParam,a1),d1		; har vi 1 parameter ?
	bne.b	1$				; Jepp, da skal vi lukke
	move.b	statusopen,d0
	bne.b	9$				; allerede åpent
	bsr	openstatuswindow
	bra.b	9$
1$	move.b	statusopen,d0
	beq.b	9$				; allerede lukket
	bsr	closestatuswindow
;	bra.b	9$
9$	moveq.l	#0,d0
	sub.l	a0,a0				; ingen return string
	rts

; a0 = nodeconfig fil
; d0.w = bruk node nr # (0 = ta første og beste)
restartnode
	push	d2
	move.w	d0,d2				; husker node nummeret
	move.l	nodelist+LH_HEAD,a1
	moveq.l	#1,d1				; nodenr
1$	move.l	(LN_SUCC,a1),d0
	beq.b	2$
	tst.w	Nodenr(a1)
	beq.b	3$				; fant en vi kan bruke
5$	move.l	d0,a1
	addq.l	#1,d1				; teller nodenr'et
	bra.b	1$

2$	bsr	kickoffnode			; starter ny node
	bra.b	9$

3$	tst.w	d2				; skal vi ha en spesiell ?
	beq.b	4$				; nei, tar hva som helst
	cmp.w	d1,d2				; riktig node ?
	bne.b	5$				; fortsetter hvis ikke
4$	moveq.l	#0,d0
	move.l	d0,(NodeTask,a1)		; sletter task feltet
	move.w	d1,(Nodenr,a1)			; lagrer nodenr'et
	move.l	a0,(Nodeusernr,a1)		; Midlertidig lagersted
	move.l	(dosbase),a6
	move.l	a0,d1				; navn på config fila
	moveq.l	#0,d2
	move.l	#nodestart,d3
	lsr.l	#2,d3
	move.l	#4*4096,d4			; stack størrelse
	jsrlib	CreateProc
	move.l	exebase,a6
	tst.l	d0				; gikk det bra ?
	beq.b	9$				; nei
	addq.w	#1,Nodes(MainBase)
	clrz
9$	pop	d2
	rts

; d0 = usernr
; d1 = node vi skal ignorere
Reloaduser
	push	a2/a3/d2/d3/a6
	move.l	exebase,a6
	move.l	d0,d2
	move.l	d1,d3

	move.l	nodelist+LH_HEAD,a2
1$	move.l	(LN_SUCC,a2),d0
	beq.b	9$
	cmp.l	Nodeusernr(a2),d2	; riktig bruker ?
	bne.b	2$			; nope.
	move.w	Nodestatus(a2),d0	; inne ?
	beq.b	2$			; nope
	move.w	Nodenr(a2),d0
	beq.b	2$			; noden er nede
	cmp.w	d0,d3			; skal vi droppe denne ?
	beq.b	2$			; jepp

; d2 = usernr
	move.w	#Node_Reloaduser,d1
	bsr	sendmsgtonodeasync

2$	move.l	(LN_SUCC,a2),a2		; Henter ptr til nestenode
	bra	1$			; flere noder. Same prosedure as last year
9$	pop	a2/a3/d2/d3/a6
	rts


; d0.w = nodenummer
; d1.w = command
; d2.l = usernr (optional for commands that need it)
sendmsgtonodeasync
	push	a2/d3
	move.l	d1,d3
	lea	txtbuffer(MainBase),a1
	lea	publicportname,a0
	bsr	fillinnodenr		; bygger opp navnet til porten

	moveq.l	#ABBSmsg_SIZE,d0	; allokerer minne til melding
	move.l	#MEMF_CLEAR,d1
	jsrlib	AllocMem
	tst.l	d0
	beq.b	9$
	move.l	d0,a2

	jsrlib	Forbid
	lea	txtbuffer(MainBase),a1	; Ser om vi finner porten
	jsrlib	FindPort
	tst.l	d0
	beq.b	3$			; ingen port
	move.l	d0,a0
	move.l	a2,a1
	move.w	d3,m_Command(a1)
	move.l	d2,m_UserNr(a1)
	jsrlib	PutMsg
	jsrlib	Permit
	clrz
	bra.b	9$

3$	jsrlib	Permit
	move.l	a2,a1
	moveq.l	#ABBSmsg_SIZE,d0
	jsrlib	FreeMem
	setz
9$	pop	d3/a2
	rts

openscreen
	move.l	mainscreenadr,d0
	bne	9$				; already open
	move.l	intbase,a6
	move.b	(Cflags+CStr,MainBase),d0
	btst	#CflagsB_Lace,d0
	beq.b	1$
	or.l	#LORESLACE_KEY,ScreenModes+4
1$	btst	#CflagsB_8Col,d0
	beq.b	2$
	move.l	#3,ScreenDepth+4
	bra.b	4$
2$	lea	(penlist2color),a0
	move.l	a0,ScreenPens+4
4$	sub.l	a0,a0
	lea	NewScreenTags,a1
	jsrlib	OpenScreenTagList
	move.l	d0,mainscreenadr
	bne.b	5$
	lea	nomainscrentext,a0
	bsr	writemainerror
	bra	no_scr
5$	bsr	readcolors
	move.l	mainscreenadr,a0
	lea	sc_ViewPort(a0),a0
	lea	screencolors,a1			; Velger mellom 2 farver
	moveq.l	#2,d0				; og 8 farver paletten
	move.b	(Cflags+CStr,MainBase),d1
	btst	#CflagsB_8Col,d1
	beq.b	3$
	lea	screencolors+4,a1
	moveq.l	#8,d0
3$	move.l	gfxbase,a6
	jsrlib	LoadRGB4
	move.l	intbase,a6
	lea	NewWindowStructure1,a0
	move.l	mainscreenadr,a1
	move.l	a1,nw_Screen(a0)
	move.w	sc_Width(a1),nw_Width(a0)	; Samme bredde som skjermen
	moveq.l	#0,d0
	move.b	sc_BarHeight(a1),d0		; Justerer starten etter
	addq.w	#1,d0
	move.w	d0,nw_TopEdge(a0)		; Høyden på skjermens titlebar
	move.w	sc_Height(a1),d1
	sub.w	d0,d1
	move.w	d1,nw_Height(a0)		; Og justerer høyden på vinduet
	move.w	#0,nw_LeftEdge(a0)		; For sikkerhetsskyld
	jsrlib	OpenWindow
	move.l	d0,mainwindowadr
	bne.b	6$
	lea	nomainwintext,a0
	bsr	writemainerror
	bra	no_mwin
6$	move.l	d0,a0
	move.l	wd_UserPort(a0),a0
	moveq	#0,d1
	move.b	MP_SIGBIT(a0),d1
	moveq.l	#0,d0
	bset	d1,d0
	move.l	d0,mainintsigbit
	or.l	d0,mainwait
	move.l	a0,mainintuiport
	bsr	setupmenu
	bne.b	7$
	lea	(nosetupmenutext),a0
	bsr	writemainerror
	bra	no_msup
7$	move.l	mainwindowadr,a0
	move.l	mainmenustruct,a1
	jsrlib	SetMenuStrip
	tst.l	d0
	bne.b	8$
	lea	nomainmenutext,a0
	bsr	writemainerror
	bra.b	no_mmen
8$	move.w	MainBits(MainBase),d0
	and.w	#MainBitsF_SysopNotAvail,d0
	bne.b	81$
	move.l	mainwindowadr,a0
	jsrlib	ClearMenuStrip
	move.l	mainmenustruct,a0
	move.l	(mu_NextMenu,a0),a0
	move.l	(mu_FirstItem,a0),a0
	andi.w	#~CHECKED,(mi_Flags,a0)
	move.l	mainwindowadr,a0
	move.l	mainmenustruct,a1
	jsrlib	ResetMenuStrip
81$	movea.l	mainscreenadr,a0
	moveq.l	#0,d0
	jsrlib	PubScreenStatus				; gjør skjermen public
	move.l	exebase,a6
9$	add.w	#1,screenopencount
	rts

closescreen
	sub.w	#1,screenopencount
	bne.b	noclose					; flere er oppe
	move.l	mainscreenadr,d0
	beq.b	noclose					; no screen to close
	move.l	intbase,a6
	move.l	mainwindowadr,d0
	beq.b	noclose
	move.l	d0,a0
	jsrlib	ClearMenuStrip
no_mmen	bsr	freemenu
no_msup	move.l	mainintsigbit,d0
	not.l	d0
	and.l	d0,mainwait
	move.l	mainwindowadr,a0
	jsrlib	CloseWindow
no_mwin	moveq.l	#0,d0
	move.l	d0,mainwindowadr
	move.l	mainscreenadr,a0
	jsrlib	CloseScreen
	moveq.l	#0,d0
	move.l	d0,mainscreenadr
no_scr	move.l	exebase,a6
noclose	rts

*******************************************************************************
*			kode for node kommandoer
*******************************************************************************


*****************************************************************************
;Error = GetMaxConfDirs ()
;m_Error (altid ok)
;m_Data = MaxConferences, m_UserNr = MaxFileDirs
*****************************************************************************
GetMaxConfDirs
	moveq.l	#0,d0
	move.w	(Maxconferences+CStr,MainBase),d0
	move.l	d0,m_Data(a0)
	move.w	(MaxfileDirs+CStr,MainBase),d0
	move.l	d0,m_UserNr(a0)
	move.w	#Error_OK,m_Error(a0)
	rts

*****************************************************************************
;Error = BroadcastMsg (intermsg, receivenode)
;m_Error		m_Data	 m_UserNr
*****************************************************************************

BroadcastMsg
	push	a3/a2
	move.l	a0,a3
	move.w	#Error_OK,m_Error(a3)	; Alt ok.
	jsrlib	Forbid
	move.l	m_UserNr(a3),d1
	beq	1$			; 0 = alle noder.

	move.l	nodelist+LH_HEAD,a2	; finner noden
	move.l	(LN_SUCC,a2),d0
	beq.b	22$			; ingen node
	bra.b	21$
2$	move.l	(LN_SUCC,a2),d0
	beq.b	22$			; fant den ikke
21$	cmp.w	Nodenr(a2),d1
	beq.b	3$			; funnet
	move.l	d0,a2
	bra.b	2$
22$	move.w	#Error_Not_Found,m_Error(a3)
	bra	9$
8$	move.w	#Error_No_Active_User,m_Error(a3)
	bra	9$

3$	move.w	Nodestatus(a2),d0	; fant noden
	beq.b	8$			; 0 = Logged off, vil ikke ha meldingen
	move.w	InterMsgwrite(a2),d1
	lea	InterNodeMsg(a2),a1
	moveq.l	#InterNodeMsgsiz,d0
	mulu	d0,d1
	lea	0(a1,d1.w),a1
	move.l	m_Data(a3),a0
	moveq.l	#InterNodeMsgsiz,d0
	jsr	memcopylen
	move.w	InterMsgwrite(a2),d1
	addq.w	#1,d1
	cmp.w	#MaxInterNodeMsg,d1
	bcs.b	4$
	moveq.l	#0,d1
4$	move.w	d1,InterMsgwrite(a2)
	cmp.w	InterMsgread(a2),d1	; Er buffer full ?
	bne.b	40$			; Nei.
	move.w	InterMsgread(a2),d0
	addq.w	#1,d0
	cmpi.w	#MaxInterNodeMsg,d0
	bcs.b	41$
	moveq.l	#0,d0			; wrap'er rundt
41$	move.w	d0,InterMsgread(a2)	; Sletter eldste melding.
40$	move.l	NodeTask(a2),a1
	move.l	InterMsgSig(a2),d0
	jsrlib	Signal
	bra.b	9$

1$	move.l	nodelist+LH_HEAD,a2
	move.l	(LN_SUCC,a2),d0
	beq.b	9$
5$	move.w	Nodestatus(a2),d0
	beq.b	6$			; 0 = Logged off
	move.w	i_franode(a2),a0
	cmp.w	Nodenr(a2),d1		; Er dette senderen ??
	beq.b	6$			; Ja, sa skip'er vi

;	move.b	(Nodedivstatus,a2),d0	; not availible ?	(sjekkes før dette)
;	andi.b	#NDSF_Notavail,d0
;	bne.b	6$			; jepp, da skip'er vi.
	move.w	InterMsgwrite(a2),d1
	lea	InterNodeMsg(a2),a1
	moveq.l	#InterNodeMsgsiz,d0
	mulu	d0,d1
	lea	0(a1,d1.w),a1
	move.l	m_Data(a3),a0
	moveq.l	#InterNodeMsgsiz,d0
	jsr	memcopylen
	move.w	InterMsgwrite(a2),d1
	addq.w	#1,d1
	cmp.w	#MaxInterNodeMsg,d1
	bcs.b	7$
	moveq.l	#0,d1
7$	move.w	d1,InterMsgwrite(a2)
	cmp.w	InterMsgread(a2),d1	; Er buffer full ?
	bne.b	61$			; Nei.
	move.w	InterMsgread(a2),d0
	addq.w	#1,d0
	cmpi.w	#MaxInterNodeMsg,d0
	bcs.b	62$
	moveq.l	#0,d0			; wrap'er rundt
62$	move.w	d0,InterMsgread(a2)	; Sletter eldste melding.
61$	move.l	NodeTask(a2),a1
	move.l	InterMsgSig(a2),d0
	jsrlib	Signal
6$	move.l	(LN_SUCC,a2),a2
	move.l	(LN_SUCC,a2),d0
	bne.b	5$

9$	jsrlib	Permit
	pop	a3/a2
	rts

LockABBS
	move.w	(MainBits,MainBase),d0
	or.w	#MainBitsF_ABBSLocked,d0
	move.w	d0,(MainBits,MainBase)
	rts

UnLockABBS
	move.w	(MainBits,MainBase),d0
	and.w	#~MainBitsF_ABBSLocked,d0
	move.w	d0,(MainBits,MainBase)
	rts

; for bruk av configbbs. Returnerer config strukturen og config init status.
Getconfig
	lea	(CStr,MainBase),a1
	move.l	a1,m_Data(a0)
	move.w	lesconfigstatus,m_UserNr(a0)
	move.w	#Error_OK,m_Error(a0)	; Alt ok.
	rts

Testconfig
	move.w	#Error_IllegalCMD,m_Error(a0)	; nekter
	rts

Startnode
;	add.w	#1,Nodes(MainBase)
	rts

Nodeshutdown
	subq.w	#1,Nodes(MainBase)
	rts

Loadfileentry
	movem.l	a2/a3/d2-d5,-(sp)
	move.l	a0,a2
	moveq.l	#Fileentry_SIZEOF,d5
	move.l	m_Data(a2),a3			; filestruct
	move.l	m_UserNr(a2),d0			; dir
	lsl.l	#2,d0
	move.l	d0,d4
	move.w	#Error_File,m_Error(a2)
	move.l	m_arg(a2),d1			; filnr + 1
	subq.l	#1,d1
	btst	#CflagsB_CacheFL,(Cflags2+CStr,MainBase)	; cache ?
	beq.b	2$				; nei.
	move.l	(n_Filedirfiles,MainBase),a0
	add.l	d4,a0
	move.l	(a0),d0
	beq.b	9$				; ingen fil..
	move.l	d0,a0
	move.l	d1,d0
	move.w	#Error_EOF,(m_Error,a2)
	bsr	findflentrynr
	bmi.b	9$				; EOF
	beq.b	9$				; not found

;	push	a0	; remove ME!!!
	move.l	a3,a1
	move.l	d5,d0
	jsr	memcopylen
;	pop	a0	; remove ME!!!
;	move.l	(mem_filefilenr,a0),(Uploader,a3)	; remove ME!!!
;	move.l	(mem_filenr,a0),(AntallDLs,a3)	; remove ME!!!
	bra.b	1$				; ok

2$	move.l	dosbase,a6
	mulu	d5,d1
	move.l	(n_Filedirfiles,MainBase),a0
	bsr	seekfile
	beq.b	9$
	move.l	d4,d0
	move.l	a3,d2
	move.l	d5,d3
	move.w	#Error_EOF,m_Error(a2)
	move.l	(n_Filedirfiles,MainBase),a0
	bsr	readfile
	beq.b	9$
	bpl.b	1$
	move.w	#Error_Read,m_Error(a2)
	bra.b	9$
1$	move.w	#Error_OK,m_Error(a2)
	move.l	m_arg(a2),m_UserNr(a2)
9$	move.l	exebase,a6
	movem.l	(sp)+,a2/a3/d2-d5
	rts

RenameFileEntry
	moveq.l	#2,d0
	bra.b	Addfiledl1
Savefileentry
	moveq.l	#1,d0
	bra.b	Addfiledl1
Addfiledl
	moveq.l	#0,d0
Addfiledl1
	movem.l	a2/a3/d2-d7,-(sp)
	move.l	d0,d6				; husker om det var add dl save eller rename
	move.l	a0,a2				; husker meldingen
	moveq.l	#Fileentry_SIZEOF,d5		; legger size hendig i et register
	move.l	(m_Data,a2),a3			; fileentry strukturen
	move.l	(m_UserNr,a2),d0		; file dir nr (* 1)
	lsl.l	#2,d0
	move.l	d0,d7				; = file dir nr (* 4)
	move.w	#Error_File,(m_Error,a2)
	move.l	(m_arg,a2),d1			; filnr + 1
	subq.l	#1,d1				; = filenr
	move.l	(n_Filedirfiles,MainBase),a0
	btst	#CflagsB_CacheFL,(Cflags2+CStr,MainBase)	; cache ?
	beq.b	2$				; nei.
	move.l	d1,d4				; = filenr (mem)
	add.l	d7,a0				; finner denne dir'ens mem structure
	move.l	(a0),d0
	beq	9$				; Error, ingen mem strukt (egentlig umulig)
	move.l	d0,a0				; = mem struct
	move.l	d4,d0				; filenr [0 - n>
	move.l	a0,d4				; husker mem struct...
	move.w	#Error_EOF,(m_Error,a2)
	bsr	findflentrynr
	bmi	9$				; EOF
	cmp.w	#2,d6				; rename ?
	bne.b	5$				; nope
	move.l	a0,d3				; husker..
	lea	(mem_fentry+Filename,a0),a0
	bsr	calchash
	move.l	d0,d2				; husker hash verdien
	move.l	d3,a0
	lea	(mem_fentry+Filename,a0),a1
	lea	(Filename,a3),a0
	moveq.l	#Sizeof_FileName,d0
	jsr	memcopylen
	move.l	d4,a1				; henter memstruct
	move.l	d3,a0				; henter mem entry
	move.l	d2,d0				; henter tilbake hash'en
	bsr	rehashentry
	move.l	d3,a0
5$	move.l	(mem_filefilenr,a0),d4		; Henter filposnr (fil)
	tst.l	d6				; Skal vi bare save ?
	bne.b	3$				; ja.
	addq.l	#1,(AntallDLs,a0)		; Vi skal øke antall dl's
;	moveq.l	#1,d6				; nå skal vi bare save
	move.l	a0,a3				; ny vi skal save
	bra.b	4$
3$	exg	a0,a3				; a3 = ny save buffer
	move.l	a3,a1
	move.l	d5,d0
	jsr	memcopylen			; sletter ved å flytte den andre
4$	move.l	d7,d0				; file dir nr (* 4)
	move.l	a3,a0
	move.l	d4,d1
	mulu	d5,d1
	move.w	#Error_Write,(m_Error,a2)
	bsr	savefileentrycachemode
	beq.b	9$
	bra.b	8$

2$	move.l	dosbase,a6			; ikke cach'a
	mulu	d5,d1
	move.l	d1,d4				; husker pos
	bsr	seekfile
	beq.b	9$
	tst.l	d6				; Skal vi bare save ?
	bne.b	1$				; ja.
	move.w	#Error_Read,m_Error(a2)
	move.l	d7,d0
	move.l	a3,d2
	move.l	d5,d3
	move.l	(n_Filedirfiles,MainBase),a0
	bsr	readfile
	beq.b	9$
	bmi.b	9$				; EOF
	move.l	d7,d0				; Seek'er tilbake
	move.l	d4,d1
	move.l	(n_Filedirfiles,MainBase),a0
	bsr	seekfile
	beq.b	9$
	addq.l	#1,AntallDLs(a3)
1$	move.w	#Error_Write,m_Error(a2)
	move.l	d7,d0
	move.l	a3,d2
	move.l	d5,d3
	move.l	(n_Filedirfiles,MainBase),a0
	bsr	writefile
	beq.b	9$
	move.l	d7,d0
	move.l	(n_Filedirfiles,MainBase),a0
	bsr	closefile
	move.l	d7,d0
	bsr	openfilefile
	bne.b	8$
	move.w	#Error_Open_File,m_Error(a2)
	bra.b	9$
8$	move.w	#Error_OK,m_Error(a2)
9$	move.l	exebase,a6
	movem.l	(sp)+,a2/a3/d2-d7
	rts

Findfile
	movem.l	a2/a3/d2-d5,-(sp)
	moveq.l	#0,d5
	moveq.l	#Fileentry_SIZEOF,d3
	move.l	a0,a2				; msg er i a2
	move.l	m_Data(a2),a3			; fileentry
	move.l	m_UserNr(a2),d0			; dir
	lsl.l	#2,d0
	move.l	d0,d4				; dir * 4
	btst	#CflagsB_CacheFL,(Cflags2+CStr,MainBase)	; cache ?
	beq.b	4$				; nei.
	move.w	#Error_File,(m_Error,a2)
	move.l	(n_Filedirfiles,MainBase),a0
	add.l	d4,a0
	move.l	(a0),d0
	beq	9$				; ingen filedir
	move.w	#Error_Not_Found,(m_Error,a2)
	move.l	d0,a1
	move.l	(m_Name,a2),a0			; filenavnet
	bsr	findflentry
	beq.b	9$				; ikke funnet. Må nå sjekke nesten match...
	move.l	(mem_filenr,a0),d5		; lagrer filnr
	addq.l	#1,d5
	move.l	a3,a1
	move.l	d3,d0
	jsr	memcopylen			; loader...
	bra.b	3$

4$	move.l	dosbase,a6
	moveq.l	#0,d1				; Seek'er til begynnelsen
	move.l	(n_Filedirfiles,MainBase),a0
	bsr	seekfile
	beq.b	9$
	move.w	#Error_Read,m_Error(a2)
1$	move.l	d4,d0
	move.l	a3,d2
	move.l	(n_Filedirfiles,MainBase),a0
	bsr	readfile
	bmi.b	9$
	beq.b	2$
	addq.l	#1,d5
	move.w	Filestatus(a3),d0
	and.w	#FILESTATUSF_Filemoved+FILESTATUSF_Fileremoved,d0
	bne.b	1$				; Dette er en slettet filinfo

	move.l	m_Name(a2),a0			; filenavnet
	lea	Filename(a3),a1
	bsr	comparestringsicasespes
	bne.b	1$
	bpl.b	3$				; ordentelig match

	move.l	m_arg(a2),a1			; sted å lagre nesten match på
	move.l	m_UserNr(a2),(a1)+		; husker fildir
	move.l	d5,(a1)+			; filnr i fildir
	lea	Filename(a3),a0			; tar vare på nesten match'en.
	bsr	strcopy				; og filnavnet
	bra.b	1$

3$	move.w	#Error_OK,m_Error(a2)
	move.l	d5,m_UserNr(a2)
	bra.b	9$
2$	move.w	#Error_Not_Found,m_Error(a2)
9$	move.l	exebase,a6
	movem.l	(sp)+,a2/a3/d2-d5
	rts

; a0 = msg
Addfile	movem.l	a2/a3/d2-d4,-(sp)
	move.l	a0,a2				; husker melding
	move.l	m_Data(a2),a3			; fileentry struct
	move.l	m_UserNr(a2),d0			; fildir
	lsl.l	#2,d0
	move.l	d0,d4				; fildir * 4
	btst	#CflagsB_CacheFL,(Cflags2+CStr,MainBase)	; cache ?
	beq	4$				; nei, vanelig
	move.w	#Error_Write,m_Error(a2)
	moveq.l	#-1,d1
	move.l	a3,a0
	bsr	savefileentrycachemode		; lagrer fileentry
	beq	9$				; error
	move.l	d0,d2				; husker pos
	move.w	#Error_Nomem,m_Error(a2)
	move.l	(flpool,MainBase),a0
	moveq.l	#mem_Fileentry_SIZEOF,d0
	jsr	_AsmAllocPooled
	tst.l	d0
	beq	9$
	move.l	a3,a0				; file entry klar for source
	move.l	d0,a3				; husker mem_entry
	move.l	a3,a1
	moveq.l	#Fileentry_SIZEOF,d0
	jsr	memcopylen

	move.l	d2,d0
	moveq.l	#Fileentry_SIZEOF,d1
	move.l	utibase,a6
	jsrlib	UDivMod32
	move.l	exebase,a6
	move.l	d0,(mem_filefilenr,a3)		; lagrer filnr
	moveq.l	#0,d0
	move.l	d0,(mem_filenr,a3)		; sletter mem filnr (i tilfelle første fil)
	move.l	d0,(mem_fnexthash,a3)		; sletter hash peker (ligger trash der)
	move.l	d0,(mem_fnext,a3)		; sletter neste fil peker (trash..)
	move.l	m_Data(a2),a0			; fileentry struct
	lea	(Filename,a0),a0		; legg inn i hash liste
	bsr	calchash
	move.w	#Error_File,m_Error(a2)
	move.l	a3,a0
	move.l	(n_Filedirfiles,MainBase),a1
	add.l	d4,a1
	move.l	(a1),d2				; henter header
	beq.b	9$				; ikke noen fil... bør frigi
	move.l	d2,a1
	bsr	insertinhashchain
	move.l	d2,a1
	moveq.l	#0,d0				; mem filnr
	move.l	(first_file,a1),d1
	bne.b	1$
	move.l	a0,(first_file,a1)		; lagrer
	bra.b	8$				; ferdig
1$	move.l	d1,a1
	addq.l	#1,d0				; øker mem filnr
	move.l	(mem_fnext,a1),d1
	bne.b	1$
	move.l	a0,(mem_fnext,a1)		; lagrer
	move.l	d0,(mem_filenr,a3)		; lagrer memfilnr
	bra.b	8$				; ferdig

4$	move.l	dosbase,a6
	moveq.l	#-1,d1				; søker til end.
	move.w	#Error_File,m_Error(a2)
	move.l	(n_Filedirfiles,MainBase),a0
	bsr	seekfile
	beq.b	9$
	move.w	#Error_Write,m_Error(a2)
	move.l	d4,d0
	move.l	a3,d2
	moveq.l	#Fileentry_SIZEOF,d3
	move.l	(n_Filedirfiles,MainBase),a0
	bsr	writefile
	beq.b	9$
	move.l	d4,d0
	move.l	(n_Filedirfiles,MainBase),a0
	bsr	closefile
	move.l	d4,d0
	bsr	openfilefile
	bne.b	8$
	move.w	#Error_Open_File,m_Error(a2)
	bra.b	9$
8$	move.w	#Error_OK,m_Error(a2)
9$	move.l	exebase,a6
	movem.l	(sp)+,a2/a3/d2-d4
	rts

Createfiledir
	push	a2/d2/d3/a3
	move.l	a0,a2
	move.w	(MaxfileDirs+CStr,MainBase),d0	; Henter MaxfileDirs til d0
	sub.w	#1,d0				; Legger til en i d0
	cmp.w	(ActiveDirs+CStr,MainBase),d0	; Sjekker med ActiveDirs
	bls	8$
	move.l	m_Name(a2),a0
	bsr	createdirfilepath		; lager i txtbuffer
	move.l	d0,d1
	move.l	dosbase,a6
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	tst.l	d0
	beq	7$
	move.l	d0,d3
	btst	#CflagsB_CacheFL,(Cflags2+CStr,MainBase)	; cache ?
	beq.b	1$				; nei, vanelig
	move.l	d3,d1
	jsrlib	Close				; lukker igjen
	move.l	#fileentryheader_sizeof,d3
	move.l	(flpool,MainBase),a0
	move.l	d3,d0
	move.l	exebase,a6
	jsr	_AsmAllocPooled
	tst.l	d0
	beq	7$			; ikke noe ram til hash.
	move.l	d0,a0			; null stiller
	exg.l	d0,d3			; husker struct
	jsr	memclr
1$	move.l	exebase,a6
	addq.w	#1,(ActiveDirs+CStr,MainBase)
	move.l	(firstFileDirRecord+CStr,MainBase),a3
	lea	(n_DirName,a3),a3
	moveq.l	#0,d2
2$	move.b	(a3),d0			; dir her ?
	beq.b	3$			; nei. da tar vi den plassen
	lea	(FileDirRecord_SIZEOF,a3),a3	; peker til neste navn
	addq.l	#1,d2
	bra.b	2$
3$	move.l	(n_Filedirfiles,MainBase),a0
	move.l	d2,d0
	lsl.l	#2,d0
	move.l	d3,(a0,d0.w)
	move.l	m_Name(a2),a0
	move.l	a3,a1
	bsr	strcopy
	lea	(n_DirPaths,a3),a1
	move.l	m_Data(a2),a0
	bsr	strcopy
	move.w	(ActiveDirs+CStr,MainBase),d0	; setter inn fileorder
	addq.l	#1,d2
	move.w	d2,(n_FileOrder,a3)
	move.w	#0,(n_PrivToConf,a3)
	bsr	main_saveconfig
	beq.b	7$
	move.w	#Error_OK,m_Error(a2)
	bra.b	9$
7$	move.w	#Error_Open_File,m_Error(a2)
	bra.b	9$
8$	move.w	#Error_Conferencelist_full,m_Error(a2)
9$	pop	a2/d2/d3/a3
	move.l	exebase,a6
	rts

Createbulletin
	push	d2-d7/a2/a3
	moveq.l	#0,d7			; Om vi har oppdatert confbullets
	move.l	a0,a2			; Msg.
	move.w	#Error_Open_File,m_Error(a2)	; Setter default feil.
	move.l	dosbase,a6
	move.l	m_UserNr(a2),d0		; bullet nr (hi word) og confnr (lo word)
	move.w	d0,d1
	lsr.w	#1,d1
	swap	d0
	tst.w	d0
	bne.b	1$
	lea	(n_FirstConference+CStr,MainBase),a3
	mulu	#ConferenceRecord_SIZEOF,d1
	add.l	d1,a3
	move.b	(n_ConfBullets,a3),d0		; Oppdaterer antall bulletiner.
	addq.b	#1,d0
	bne.b	3$
	move.w	#Error_Bulletinlist_full,m_Error(a2)
	bra	99$
3$ 	move.b	d0,(n_ConfBullets,a3)
	moveq.l	#1,d7
1$	lea	txtbuffer(MainBase),a0
	bsr	getkonfbulletname

	lea	txtbuffer(MainBase),a0	; kopierer bulletin.
	move.l	a0,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	9$
	move.l	m_Name(a2),d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d5
	beq.b	8$
	move.w	#Error_Write,m_Error(a2)

	move.l	m_Data(a2),d2			; buffer
	move.l	m_arg(a2),d6			; size

2$	move.l	d5,d1
	move.l	d6,d3
	jsrlib	Read
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq.b	7$			; File error
	tst.l	d0
	beq.b	6$			; EOF, ferdig.
	move.l	d4,d1
	move.l	d0,d3
	jsrlib	Write
	cmp.l	d3,d0			; Sjekker mot det vi leste
	beq.b	2$
	bra.b	7$			; file error
6$	bsr	main_saveconfig
	move.l	dosbase,a6
	beq.b	7$
	move.w	#Error_OK,m_Error(a2)
	moveq.l	#0,d7
7$	move.l	d5,d1
	jsrlib	Close
8$	move.l	d4,d1
	jsrlib	Close
9$	tst.l	d7				; har vi økt uten at det gikk bra ?
	beq.b	99$				; nei, ferdig
	subq.b	#1,(n_ConfBullets,a3)		; retter opp igjen.
99$	move.l	exebase,a6
	pop	d2-d7/a2/a3
	rts

Clearbulletins
	move.l	m_UserNr(a0),d0
	lsr.w	#1,d0
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF,d0
	add.l	d0,a0
	clr.b	(n_ConfBullets,a3)		; Clearer antall bulletiner.
	move.w	#Error_OK,m_Error(a0)
	rts

Savemsgheader
	movem.l	a2/a3/d2-d4,-(sp)
	move.l	dosbase,a6
	move.l	a0,a2			; Msg (abbsmsg)
	move.l	m_Data(a2),a3		; Msg header
	move.w	#Error_Not_Found,m_Error(a2)
	move.l	m_UserNr(a2),d0		; conf nr (* 2)
	add.l	d0,d0
	move.l	d0,d4
	move.l	Number(a3),d1
	subq.l	#1,d1
	mulu	#MessageRecord_SIZEOF,d1
	move.l	(n_MsgHeaderfiles,MainBase),a0
	bsr	seekfile
	beq.b	9$
	move.w	#Error_Write,m_Error(a2)
	move.l	d4,d0
	move.l	a3,d2		; Msg header buffer
	moveq.l	#MessageRecord_SIZEOF,d3
	move.l	(n_MsgHeaderfiles,MainBase),a0
	bsr	writefile
	beq.b	9$
	move.l	d4,d0
	move.l	(n_MsgHeaderfiles,MainBase),a0
	bsr	closefile
	move.l	d4,d0
	bsr	openheaderfile
	bne.b	8$
	move.w	#Error_Open_File,m_Error(a2)
	bra.b	9$
8$	move.w	#Error_OK,m_Error(a2)
9$	move.l	exebase,a6
	movem.l	(sp)+,a2/a3/d2-d4
	rts

Loadmsgheader
	movem.l	a2/a3/d2-d4,-(sp)
	move.l	dosbase,a6
	move.l	a0,a2			; Msg (abbsmsg)
	move.l	m_Data(a2),a3		; Msg header
	moveq.l	#0,d0
	move.w	m_Error(a2),d0		; conf nr
	add.l	d0,d0
	move.l	d0,d4
	move.w	#Error_Not_Found,m_Error(a2)
	move.l	m_UserNr(a2),d1		; msg nr
	mulu	#MessageRecord_SIZEOF,d1
	move.l	(n_MsgHeaderfiles,MainBase),a0
	bsr	seekfile
	beq.b	9$
	move.w	#Error_Read,m_Error(a2)
	move.l	d4,d0
	move.l	a3,d2		; Msg header buffer
	moveq.l	#MessageRecord_SIZEOF,d3
	move.l	(n_MsgHeaderfiles,MainBase),a0
	bsr	readfile
	bmi.b	9$
	beq.b	9$
	move.w	#Error_OK,m_Error(a2)
9$	move.l	exebase,a6
	movem.l	(sp)+,a2/a3/d2-d4
	rts

Loadmsgtext
	movem.l	a2/a3/d2-d4,-(sp)
	move.l	dosbase,a6
	move.l	a0,a2			; Msg (abbsmsg)
	move.l	m_Name(a2),a3		; Msg header
	move.w	#Error_File,m_Error(a2)
	move.l	m_UserNr(a2),d0		; conf nr
	add.l	d0,d0
	move.l	d0,d4
	move.l	TextOffs(a3),d1
	move.l	(n_MsgTextfiles,MainBase),a0
	bsr	seekfile
	beq.b	9$
	move.w	#Error_Read,m_Error(a2)
	move.l	d4,d0
	move.l	m_Data(a2),a0			; Msg text buf
	move.l	a0,d2
	moveq.l	#0,d3
	move.w	NrBytes(a3),d3
	cmp.l	(a0),d3				; sjekker mot lovelig størrlese
	bls.b	4$
	move.l	(a0),d3				; Kan bare loade så mye som dette
4$	tst.l	d3				; 0 bytes ?
	bne.b	1$				; nei, leser som før.
	move.b	#0,(a0)				; terminerer
	bra.b	2$				; og ok.
1$	move.l	(n_MsgTextfiles,MainBase),a0
	bsr	readfile
	bmi.b	9$
	beq.b	9$
2$	move.w	#Error_OK,m_Error(a2)
9$	move.l	exebase,a6
	movem.l	(sp)+,a2/a3/d2-d4
	rts

*****************************************************************************
;Error = CreateConference (name, new status bits)
;m_Error		   m_Name,	m_Data
*****************************************************************************
CreateConference	; CI
	push	a2/d2/d3
	moveq.l	#0,d3
	move.l	a0,a2			; husker melding
	move.w	#Error_Conferencelist_full,m_Error(a2)
	move.w	(Maxconferences+CStr,MainBase),d0
	cmp.w	(ActiveConf+CStr,MainBase),d0
	bcs	9$			; ikke plass
	move.l	m_Name(a2),a0		; navnet
	lea	dotmessagestext,a1	; lager .m fil
	bsr	createconffilepath
	move.l	d0,d1
	move.l	dosbase,a6
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d3
	beq	7$

	move.l	m_Name(a2),a0
	lea	dotmsgheadertxt,a1	; lager .h fil
	bsr	createconffilepath
	move.l	d0,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d2
	beq	7$

	move.l	exebase,a6
	addq.w	#1,(ActiveConf+CStr,MainBase)	; øker (OK)
	lea	(n_ConfName+n_FirstConference+CStr,MainBase),a1
	moveq	#0,d1				; confnr.
2$	move.b	(a1),d0				; noe her ? (Leter etter ledig navn)
	beq.b	3$				; nope, ferdig
	lea	(ConferenceRecord_SIZEOF,a1),a1
	addq	#1,d1
	bra.b	2$
3$	move.l	m_Data(a2),d0		; Flags
	move.w	d0,(n_ConfSW,a1)
	moveq.l	#0,d0			; clearer conference bulletins.
	move.b	d0,(n_ConfBullets,a1)	; skulle ikke være nødvendig, men.
	move.l	d0,(n_ConfDefaultMsg,a1)	; Høyeste melding i konfen
	addq.l	#1,d0
	move.l	d0,(n_ConfFirstMsg,a1)
	moveq.l	#50,d0
	move.w	d0,(n_ConfMaxScan,a1)	; Satt til 50 automatisk ser det ut til...

; Finner konferanse rekkefølgen
	lea	(n_FirstConference+CStr,MainBase),a0
	move.w	(ActiveConf+CStr,MainBase),d0
	subq.w	#1,d0
	mulu	#ConferenceRecord_SIZEOF,d0
	add.w	#1,d1
;	move.w	d1,(n_ConfOrder,a0,d0.l)
	sub.w	#1,d1

	lsl.l	#2,d1
	move.l	(n_MsgHeaderfiles,MainBase),a0
	move.l	d2,0(a0,d1.l)
	move.l	(n_MsgTextfiles,MainBase),a0
	move.l	d3,0(a0,d1.l)

	move.l	m_Name(a2),a0			; stapper inn navnet
	bsr	strcopy

	move.w	#Error_Open_File,m_Error(a2)
	bsr	main_saveconfig
	beq.b	9$
	move.w	#Error_OK,m_Error(a2)
	bra.b	9$
7$	move.w	#Error_Open_File,m_Error(a2)
	move.l	d3,d1
	beq.b	9$
	jsrlib	Close
9$	pop	a2/d2/d3
	move.l	exebase,a6
	rts

Savemsg	push	a2/a3/d2-d5
	move.l	dosbase,a6
	move.l	a0,a2			; Msg (abbsmsg)
	move.l	m_Name(a2),a3		; Msg header
	move.l	m_UserNr(a2),d0		; conf nr * 2
	move.w	#Error_File,m_Error(a2)
	add.l	d0,d0
	move.l	d0,d4			; conf nr * 4
	moveq.l	#-1,d1			; Til slutten.
	move.l	(n_MsgTextfiles,MainBase),a0
	bsr	seekfile
	beq	9$
	move.l	d4,d0
	moveq.l	#-1,d1			; Til slutten.
	move.l	(n_MsgTextfiles,MainBase),a0
	bsr	seekfile
	beq	9$
	move.l	d0,TextOffs(a3)
	move.w	#Error_Write,m_Error(a2)
	move.l	d4,d0
	move.l	m_Data(a2),d2		; Msg text
	moveq.l	#0,d3
	move.w	NrBytes(a3),d3
	move.l	(n_MsgTextfiles,MainBase),a0
	bsr	writefile
	beq	9$
	move.l	d4,d0
	move.l	(n_MsgTextfiles,MainBase),a0
	bsr	closefile
	move.l	d4,d0
	bsr	openmsgtextfile
	bne.b	1$
	move.w	#Error_Open_File,m_Error(a2)
	bra	9$

1$	move.w	#Error_File,m_Error(a2)
	move.l	d4,d0
	moveq.l	#-1,d1			; Til slutten.
	move.l	(n_MsgHeaderfiles,MainBase),a0
	bsr	seekfile
	beq	9$
	move.l	d4,d0
	moveq.l	#-1,d1			; Til slutten.
	move.l	(n_MsgHeaderfiles,MainBase),a0
	bsr	seekfile
	beq	9$
	moveq.l	#MessageRecord_SIZEOF,d1
	move.l	utibase,a6
	jsrlib	UDivMod32
	move.l	dosbase,a6
	tst.l	d1			; sjekker resten
	beq.b	2$			; ikke null. problemer
	move.l	d0,d5			; husker nr.
	mulu	#MessageRecord_SIZEOF,d0
	move.l	d0,d1			; posisjon
	move.l	d4,d0			; søler til en jevn start pos
	move.l	(n_MsgHeaderfiles,MainBase),a0
	bsr	seekfile
	beq.b	9$			; feil..
	move.l	d5,d0
2$	addq.l	#1,d0
	move.l	d0,Number(a3)
	move.w	#Error_Write,m_Error(a2)
	move.l	d4,d0
	move.l	a3,d2			; Msg header
	moveq.l	#MessageRecord_SIZEOF,d3
	move.l	(n_MsgHeaderfiles,MainBase),a0
	bsr	writefile
	beq.b	9$
	move.l	d4,d0
	move.l	(n_MsgHeaderfiles,MainBase),a0
	bsr	closefile
	move.l	d4,d0
	bsr	openheaderfile
	bne.b	8$
	move.w	#Error_Open_File,m_Error(a2)
	bra.b	9$
8$	move.w	#Error_Open_File,m_Error(a3)	; oppdaterer configfila.
	lea	(n_FirstConference+CStr,MainBase),a0
	move.l	(m_UserNr,a2),d0		; conf nr * 2
	mulu	#ConferenceRecord_SIZEOF/2,d0
	move.l	(Number,a3),(n_ConfDefaultMsg,a0,d0.l)
	bsr	main_saveconfig
	beq.b	9$
	move.w	#Error_OK,m_Error(a2)
9$	move.l	exebase,a6
	pop	a2/a3/d2-d5
	rts

Loadmsg	push	a2/a3/d2-d4
	move.l	dosbase,a6
	move.l	a0,a2			; Msg (abbsmsg)
	move.l	m_Name(a2),a3		; Msg header
	moveq.l	#0,d0
	move.w	m_Error(a2),d0		; conf nr
	add.l	d0,d0
	move.l	d0,d4
	move.w	#Error_File,m_Error(a2)
	move.l	m_UserNr(a2),d1		; msg nr
	mulu	#MessageRecord_SIZEOF,d1
	move.l	(n_MsgHeaderfiles,MainBase),a0
	bsr	seekfile
	beq.b	9$
	move.w	#Error_Read,m_Error(a2)
	move.l	d4,d0
	move.l	a3,d2		; Msg header buffer
	moveq.l	#MessageRecord_SIZEOF,d3
	move.l	(n_MsgHeaderfiles,MainBase),a0
	bsr	readfile
	beq.b	9$

	move.w	#Error_File,m_Error(a2)
	move.l	d4,d0
	move.l	TextOffs(a3),d1
	move.l	(n_MsgTextfiles,MainBase),a0
	bsr	seekfile
	beq.b	9$
	move.w	#Error_Read,m_Error(a2)
	move.l	d4,d0
	move.l	m_Data(a2),a0			; Msg text buf
	move.l	a0,d2
	moveq.l	#0,d3
	move.w	NrBytes(a3),d3
	cmp.l	(a0),d3				; sjekker mot lovelig størrlese
	bls.b	4$
	move.l	(a0),d3				; Kan bare loade så mye som dette
4$	tst.l	d3				; 0 bytes ?
	bne.b	1$				; nei, leser som før.
	move.b	#0,(a0)				; terminerer
	bra.b	2$				; og ok.
1$	move.l	(n_MsgTextfiles,MainBase),a0
	bsr	readfile
	beq.b	9$
2$	move.w	#Error_OK,m_Error(a2)
9$	move.l	exebase,a6
	pop	a2/a3/d2-d4
	rts

*****************************************************************************
;Error = Loadsaveuser (navnstreng,data area,load/save)
;m_Error(a0)	       m_Name(a0) m_Data(a0) m_Command(a0)
*****************************************************************************
Loadsaveuser
	movem.l	d2-d4/a2/a3,-(sp)
	move.l	a0,a3
	move.w	#Error_Not_Found,m_Error(a3)
	move.l	m_Name(a3),a0
	bsr	finnlogentrynavn
	beq	9$
	move.l	a0,a2

	move.l	dosbase,a6		; Les inn recorden
	move.w	#Error_Open_File,m_Error(a3)
	move.l	userfile(MainBase),d4
	beq	9$
	move.w	#Error_File,m_Error(a3)
	move.l	d4,d1
	moveq.l	#OFFSET_BEGINNING,d3
	move.l	l_RecordNr(a2),d2
	move.l	(UserrecordSize+CStr,MainBase),d0
	mulu	d0,d2
	jsrlib	Seek
	bsr	testseekerror
	bne	8$				; error
	move.l	d4,d1
	move.l	m_Data(a3),d2
	move.l	(UserrecordSize+CStr,MainBase),d3
	cmp.w	#Main_saveuser,m_Command(a3)	; Skal vi lagre ??
	beq.b	4$			; Ja
	jsrlib	Read			; Nei, da leser vi
	bra.b	5$
4$	jsrlib	Write
5$	moveq.l	#-1,d1			; read/write error ??
	cmp.l	d0,d1
	beq.b	8$
	move.w	#Error_OK,m_Error(a3)
8$	cmp.w	#Main_saveuser,m_Command(a3)	; har vi lagret ??
	bne.b	9$				; nei, da er vi ferdig
	cmp.w	#Error_OK,m_Error(a3)		; Gikk alt ok ?
	bne.b	9$				; nei
	move.l	d4,d1
	jsrlib	Close
	moveq.l	#0,d0
	move.l	d0,userfile(MainBase)
	move.w	#Error_Open_File,m_Error(a3)
	move.l	#userfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,userfile(MainBase)
	beq	9$
	move.w	#Error_OK,m_Error(a3)
	move.l	m_arg(a3),d1			; nodenr to skip
	move.l	l_UserNr(a2),d0
	bsr	Reloaduser
	move.l	m_Data(a3),a0
	move.w	Userbits(a0),d0
	cmp.w	l_UserBits(a2),d0		; har userbit'ene forandret seg ?
	beq.b	9$				; nope.
	move.w	d0,l_UserBits(a2)		; Oppdaterer log'ens userbits
	bsr	savelog
	bne.b	9$				; alt ok
	move.w	#Error_SavingIndex,m_Error(a3)
9$	move.l	exebase,a6
	movem.l	(sp)+,a2/a3/d2-d4
	rts

*****************************************************************************
;Error = Loadsaveusernr (bruker nr,data area,load/save)
;m_Error(a0)		 m_UserNr(a0) m_Data(a0) m_Command(a0)
*****************************************************************************
Loadsaveusernr
	push	d2-d4/a3/a2
	move.l	a0,a3
	move.w	#Error_EOF,m_Error(a3)
	move.l	m_UserNr(a3),d0
	cmp.l	(MaxUsers+CStr,MainBase),d0	; Sjekk om brukernr < maks brukernr.
	bcc	9$			; For høy. Error.
	move.w	#Error_Open_File,m_Error(a3)
	move.l	userfile(MainBase),d4
	beq	9$
	move.l	dosbase,a6
	move.w	#Error_File,m_Error(a3)
	moveq.l	#OFFSET_BEGINNING,d3
	move.l	m_UserNr(a3),d0		; Har allerede sjekket range
	lsl.l	#2,d0
	move.l	NrTabelladr(MainBase),a0
	move.l	0(a0,d0.l),d0		; Henter Lognr
	move.w	#Error_Not_Found,m_Error(a3)
	cmp.l	#-1,d0
	beq	9$
	move.l	LogTabelladr(MainBase),a2
	mulu	#Log_entry_SIZEOF,d0
	add.l	d0,a2			; Henter Logentry
	move.l	l_RecordNr(a2),d2
	move.l	(UserrecordSize+CStr,MainBase),d0
	mulu	d0,d2
	move.l	d4,d1
	jsrlib	Seek
	bsr	testseekerror
	bne	8$				; error
	move.l	d4,d1
	move.l	m_Data(a3),d2
	move.l	(UserrecordSize+CStr,MainBase),d3
	cmp.w	#Main_saveusernr,m_Command(a3)	; Skal vi lagre ??
	beq.b	4$			; Ja
	jsrlib	Read			; Nei, da leser vi
	bra.b	5$
4$	jsrlib	Write
5$	moveq.l	#-1,d1			; read/write error ??
	cmp.l	d0,d1
	beq.b	8$
	move.w	#Error_OK,m_Error(a3)
8$	cmp.w	#Main_saveusernr,m_Command(a3)	; har vi lagret ??
	bne.b	9$				; nei
	cmp.w	#Error_OK,m_Error(a3)		; Gikk alt ok ?
	bne.b	9$				; nei
	move.l	d4,d1
	jsrlib	Close
	moveq.l	#0,d0
	move.l	d0,userfile(MainBase)
	move.w	#Error_Open_File,m_Error(a3)
	move.l	#userfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,userfile(MainBase)
	beq.b	9$
	move.l	m_arg(a3),d1			; nodenr to skip
	move.l	m_UserNr(a3),d0
	bsr	Reloaduser
	move.w	#Error_OK,m_Error(a3)
	move.l	m_Data(a3),a0
	move.w	Userbits(a0),d0
	cmp.w	l_UserBits(a2),d0		; har userbit'ene forandret seg ?
	beq.b	9$				; nope.
	move.w	d0,l_UserBits(a2)		; Oppdaterer log'ens userbits
	bsr	savelog
	bne.b	9$				; alt ok
	move.w	#Error_SavingIndex,m_Error(a3)
9$	move.l	exebase,a6
	pop	a3/d2-d4/a2
	rts

*****************************************************************************
;Error = Loadsaveusernrnr (nr i fil,data area,load/save)
;m_Error(a0)		   m_UserNr(a0) m_Data(a0) m_Command(a0)
*****************************************************************************
Loadsaveusernrnr
	push	d2-d4/a3/a2
	move.l	a0,a3
	move.w	#Error_Open_File,m_Error(a3)
	move.l	dosbase,a6		; Les inn recorden
	move.l	userfile(MainBase),d4
	beq	9$
	move.l	d4,d1
	move.w	#Error_File,m_Error(a3)
	moveq.l	#OFFSET_BEGINNING,d3
	move.l	m_UserNr(a3),d2
	move.l	(UserrecordSize+CStr,MainBase),d0
	mulu	d0,d2
	jsrlib	Seek
	bsr	testseekerror
	bne.b	8$				; error
	move.l	d2,-(a7)
	move.w	#Error_EOF,m_Error(a3)
	move.l	d4,d1
	moveq.l	#OFFSET_CURRENT,d3
	moveq.l	#0,d2
	jsrlib	Seek
	move.l	(a7)+,d1
	cmp.l	d0,d1
	bne.b	8$
	move.l	d4,d1
	move.l	m_Data(a3),d2
	move.l	(UserrecordSize+CStr,MainBase),d3
	cmp.w	#Main_saveusernrnr,m_Command(a3)	; Skal vi lagre ??
	beq.b	4$					; Ja
	jsrlib	Read					; Nei, da leser vi
	bra.b	5$
4$	move.w	#Error_File,m_Error(a3)
	jsrlib	Write
5$	cmp.l	d0,d3					; read/write error ??
	bne.b	8$
	move.w	#Error_OK,m_Error(a3)
8$	cmp.w	#Main_saveusernrnr,m_Command(a3)	; har vi lagret ??
	bne.b	9$				; nei
	cmp.w	#Error_OK,m_Error(a3)		; Gikk alt ok ?
	bne.b	9$				; nei
	move.l	d4,d1
	jsrlib	Close
	moveq.l	#0,d0
	move.l	d0,userfile(MainBase)
	move.w	#Error_Open_File,m_Error(a3)
	move.l	#userfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,userfile(MainBase)
	beq.b	9$
	move.w	#Error_Not_Found,m_Error(a3)
	move.l	m_Data(a3),a0
	lea	Name(a0),a0
	bsr	finnlogentrynavn
	beq.b	9$
	move.l	a0,a2
	move.l	m_arg(a3),d1			; nodenr to skip
	move.l	l_UserNr(a2),d0
	bsr	Reloaduser
	move.w	#Error_OK,m_Error(a3)
	move.l	m_Data(a3),a0
	move.w	Userbits(a0),d0
	cmp.w	l_UserBits(a2),d0		; har userbit'ene forandret seg ?
	beq.b	9$				; nope.
	move.w	d0,l_UserBits(a2)		; Oppdaterer log'ens userbits
	bsr	savelog
	bne.b	9$				; alt ok
	move.w	#Error_SavingIndex,m_Error(a3)
9$	move.l	exebase,a6
	pop	a3/d2-d4/a2
	rts

*****************************************************************************
;Error = Createuser(navnstreng,data area)
;m_Error(a0)	    m_Name(a0)	m_Data(a0)
*****************************************************************************
Createuser
	push	d2-d5/a2/a3
	move.l	a0,a3				; husker meldingen
	moveq.l	#0,d5				; maxuser skal ikke økes
	lea	txtbuffer(MainBase),a2		; bruker denne som en tmpLogEntry
	move.l	(m_Name,a3),a0
	lea	(l_Name,a2),a1
	moveq.l	#Sizeof_NameT,d0
	bsr	strcopymaxlen			; Fyller i name

	move.l	(NrTabelladr,MainBase),a0
	moveq.l	#-1,d1
	moveq.l	#0,d3				; bruker nummeret
	move.l	(Users+CStr,MainBase),d2
	beq.b	10$				; Ingen brukere, ikke scan
5$	move.l	(a0)+,d0
	cmp.l	d0,d1
	beq.b	6$
	addq.l	#1,d3
	subq.l	#1,d2
	bne.b	5$
10$	moveq.l	#1,d5				; maxuser skal økes alikevel
6$	move.l	d3,(l_UserNr,a2)
	move.l	(m_Data,a3),a0
	move.l	d3,(Usernr,a0)
	move.w	#0,(l_UserBits,a2)		; Han er ikke død...

	move.l	a2,a0
	move.w	#Error_Found,(m_Error,a3)
	bsr	insertlogentry			; returnerer plassen i d0.
	beq	9$				; klarte ikke. Må finnes.

	move.l	(NrTabelladr,MainBase),a0
	lsl.l	#2,d3
	move.l	d0,0(a0,d3.l)
	mulu	#Log_entry_SIZEOF,d0		; opdaterer a2 til å peke på
	move.l	(LogTabelladr,MainBase),a0	; plassen hvor entry'et havna.
	lea	0(a0,d0.l),a2

	move.w	#Error_Open_File,m_Error(a3)
	move.l	dosbase,a6
	move.l	userfile(MainBase),d4
	bne.b	3$
	tst.w	lesconfigstatus			; skal den finnes ?
	bne	99$				; ja
	move.l	#userfilename,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,userfile(MainBase)
	beq	99$
	move.l	d0,d4
3$	move.w	#Error_File,m_Error(a3)
	move.l	d4,d1
	moveq.l	#OFFSET_END,d3
	moveq.l	#0,d2
	jsrlib	Seek
	bsr	testseekerror
	bne	8$				; error
	move.l	d4,d1
	moveq.l	#OFFSET_END,d3
	moveq.l	#0,d2
	jsrlib	Seek
	bsr	testseekerror
	bne.b	8$				; error
	move.l	(UserrecordSize+CStr,MainBase),d1
	move.l	utibase,a6
	jsrlib	UDivMod32
	move.l	dosbase,a6
	move.l	d1,d2			; Sjekker om vi er på en ujevn userrecord_size.
	beq.b	1$			; Det er vi ikke
	move.l	d0,l_RecordNr(a2)	; runder nedover, og lager over den 'halve' userrecord'en
	move.l	d4,d1
	moveq.l	#OFFSET_END,d3
	neg.l	d2
	jsrlib	Seek
	bsr	testseekerror
	bne.b	8$				; error
	bra.b	2$
1$	move.l	d0,l_RecordNr(a2)
2$	move.l	d4,d1
	move.l	m_Data(a3),d2
	move.l	(UserrecordSize+CStr,MainBase),d3
	jsrlib	Write
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq.b	8$
	move.w	#Error_OK,m_Error(a3)
8$	move.l	d4,d1
	jsrlib	Close
	moveq.l	#0,d0
	move.l	d0,userfile(MainBase)
	move.l	#userfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,userfile(MainBase)
	bne.b	4$
	move.w	#Error_Open_File,m_Error(a3)
	bra.b	99$
4$	cmp.w	#Error_OK,m_Error(a3)	; Gikk alt bra ?
	bne.b	99$			; Nei. Ut.
	move.l	exebase,a6
	move.w	#Error_Open_File,m_Error(a3)
	addq.l	#1,(Users+CStr,MainBase)
	tst.l	d5			; skulle max også økes ?
	beq.b	7$			; nei
	addq.l	#1,(MaxUsers+CStr,MainBase)
7$	bsr	main_saveconfig
	beq.b	9$
	bsr	savehash		; og lagrer log tabellen
	beq.b	9$
	move.w	#Error_OK,m_Error(a3)
	bra.b	9$
99$	move.l	(l_UserNr,a2),d0
	move.l	(NrTabelladr,MainBase),a0
	lsl.l	#2,d0
	moveq.l	#-1,d1
	move.l	d1,0(a0,d0.l)		; sletter bruker nummeret
	move.l	(m_Name,a3),a0		; sletter igjen
	bsr	deletelogentry
	bsr	main_saveconfig
9$	move.l	exebase,a6
	pop	d2-d5/a2/a3
	rts

*****************************************************************************
;Error = Getusername(usernumber)
;m_Error(a0)	     m_UserNr(a0)
;username -> m_Name(a0)
*****************************************************************************

Getusername
	move.w	#Error_Not_Found,m_Error(a0)
	move.l	m_UserNr(a0),d0
	moveq.l	#0,d1
	move.l	d1,(m_arg,a0)		; ingen base (lokal)
	cmp.l	(MaxUsers+CStr,MainBase),d0	; Sjekk om brukernr < maks brukernr.
	bhi.b	9$			; For høy. Error.
	move.l	NrTabelladr(MainBase),a1
	lsl.l	#2,d0
	move.l	0(a1,d0.l),d0		; Henter Lognr
	cmp.l	#-1,d0			; er det en slettet bruker ?
	beq.b	9$			; Jepp, gir error
	move.l	LogTabelladr(MainBase),a1
	mulu	#Log_entry_SIZEOF,d0
	lea	0(a1,d0.l),a1		; Henter Logentry
	move.w	l_UserBits(a1),m_Data(a0)
	addq.l	#l_Name,a1
	move.l	a1,m_Name(a0)
8$	move.w	#Error_OK,m_Error(a0)	; Alt ok.
9$	rts

*****************************************************************************
;Error = Getusernumber (navnstreng)
;m_Error(a0)		m_Name(a0)
;usernumber -> m_UserNr(a0)
*****************************************************************************
Getusernumber
	push	d2/a2
	move.w	#Error_Not_Found,m_Error(a0)	; sier vi ikke fant den.
	move.l	a0,d2
	move.l	m_Name(a0),a0
	bsr	finnlogentrynavn
	beq.b	9$
	move.l	d2,a1
	move.l	l_UserNr(a0),m_UserNr(a1)
	move.w	#Error_OK,m_Error(a1)		; Alt ok.
9$	pop	d2/a2
	rts

*****************************************************************************
;Error = Saveconfig(m_data)
;m_Error(a0)        config
*****************************************************************************
Saveconfig
	push	d2-d5/a3
	move.l	(Configsize+CStr,MainBase),d5
	move.l	a0,a3
	move.l	m_Data(a3),d0		; Er Data satt ? da ligger ny config der
	beq.b	3$
	move.l	d0,a0			; kopierer inn i minne buffer
	lea	(CStr,MainBase),a1
	move.l	d5,d0
	jsr	memcopylen
3$	move.l	dosbase,a6
	move.l	#configfilename,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	1$
	move.l	d4,d1
	lea	(CStr,MainBase),a0
	move.l	a0,d2
	move.l	d5,d3
	jsrlib	Write
	cmp.l	d5,d0
	bne.b	2$
	move.l	d4,d1
	jsrlib	Close
	move.w	#Error_OK,m_Error(a3)	; Alt ok.
9$	move.l	exebase,a6
	pop	d2-d5/a3
	rts
1$	move.w	#Error_Open_File,m_Error(a3)
	bra.b	9$
2$	move.l	d4,d1
	jsrlib	Close
	move.w	#Error_Write,m_Error(a3)
	bra.b	9$

QuitBBS	move.w	#Error_Cant_shut_down,m_Error(a0)
	move.w	MainBits(MainBase),d0		; er vi locked ?
	and.w	#MainBitsF_ABBSLocked,d0
	bne.b	9$				; ja, nekte
	tst.w	Nodes(MainBase)
	bne.b	9$
	move.w	#1,mainshutdown
	move.w	#Error_OK,m_Error(a0)
9$	rts

****************************************************************************************
;Error = PackuserFile (tmpuser data area,Table of usernrs to delete, terminated by a -1)
;m_Error(a0)	       m_Data(a0)	 m_arg
****************************************************************************************
PackuserFile
	push	a3/a2/d2-d7
	move.l	a0,a3					; husker meldingen
	move.w	#Error_Open_File,(m_Error,a3)
	move.l	dosbase,a6
	move.l	(userfile,MainBase),d5
	beq	9$
	move.l	#newuserfilename,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d6
	beq	9$					; error opening new userfile

	move.l	d5,d1
	move.w	#Error_File,m_Error(a3)
	moveq.l	#OFFSET_BEGINNING,d3
	moveq.l	#0,d2
	jsrlib	Seek					; går til starten
	bsr	testseekerror
	bne	8$					; error
	moveq.l	#0,d7					; record nr

1$	moveq.l	#0,d1
	jsrlib	SetIoErr				; clear'er error. Fread gjør det ikke..
	move.l	d5,d1					; leser inn neste bruker
	move.l	(m_Data,a3),d2
	move.l	(UserrecordSize+CStr,MainBase),d3
	moveq.l	#1,d4
	jsrlib	FRead
	tst.l	d0
	bne.b	4$					; ok, gå videre
	jsrlib	IoErr
	tst.l	d0
	bne	8$					; error, ut, rydd opp					; error
	bra.b	7$					; EOF
4$	move.l	d2,a0
	move.l	(Usernr,a0),d0				; henter usernummeret
	cmp.l	(SYSOPUsernr+CStr,MainBase),d0
	beq.b	2$					; ja, aldri fjerne han
	move.l	(m_arg,a3),a0
	bsr	10$
	bne.b	2$					; han skal ikke slettes
	move.l	d2,a0
	move.l	(Usernr,a0),d0				; henter usernummeret
	move.l	NrTabelladr(MainBase),a1		; setter -1 som record nummer
	lsl.l	#2,d0
	move.l	#-1,(a1,d0.l)
	lea	(Name,a0),a0
	bsr	deletelogentry				; slett han fra index tabellen
	beq.b	3$					; gikk ikke (fant'n ikke)
	subq.l	#1,(Users+CStr,MainBase)
	bra.b	3$
2$	move.l	d6,d1					; skriver til ny userfil
; d2,d3 og d4 er riktig
	jsrlib	FWrite
	moveq.l	#1,d1
	cmp.l	d0,d1
	bne	8$
	move.l	d2,a0
	lea	(Name,a0),a0
	bsr	finnlogentrynavn
	beq.b	81$					; fant ikke. Egentlig umulig
	move.l	d7,(l_RecordNr,a0)
	addq.l	#1,d7
3$	bra.b	1$

7$	moveq.l	#0,d7					; record nr
	move.l	(Users+CStr,MainBase),d0			; Henter antall brukere
	move.l	LogTabelladr(MainBase),a0
	move.l	NrTabelladr(MainBase),a1
71$	move.l	(l_UserNr,a0),d1			; oppdaterer nr tabellen
	lsl.l	#2,d1
	move.l	d7,(a1,d1.l)
	addq.l	#1,d7
	lea	(Log_entry_SIZEOF,a0),a0
	subq.l	#1,d0
	bne.b	71$
	bsr	savehash
	beq.b	8$
	move.l	d5,d1				; lukker userfile
	jsrlib	Close
	move.l	d6,d1
	jsrlib	Close				; lukker newfile
	moveq.l	#0,d0
	move.l	d0,(userfile,MainBase)
	move.l	#userfilename,d1
	jsrlib	DeleteFile			; sletter gammel brukerfil
	move.l	#newuserfilename,d1
	move.l	#userfilename,d2
	jsrlib	Rename
	tst.l	d0
	beq.b	9$
	move.l	#userfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,(userfile,MainBase)
	beq	9$
	move.w	#Error_OK,m_Error(a3)		; Ingen feil
	bra.b	9$

81$	move.w	#Error_Not_Found,m_Error(a3)
8$	move.l	d6,d1				; lukker, og sletter newuserfile
	jsrlib	Close
82$	move.l	#newuserfilename,d1
	jsrlib	DeleteFile
9$	move.l	exebase,a6
	pop	a3/a2/d2-d7
	rts

; d0 = brukernr
; a0 = table
; ret: z = 1, bruker er i array'en
10$	move.l	(a0)+,d1
	cmp.l	d0,d1
	beq.b	19$
	cmp.l	#-1,d1
	bne.b	10$
	clrz
19$	rts

*****************************************************************************
;Error = MatchName(navnstreng,data area)
;m_Error(a0)	   m_Name(a0) m_Data(a0)
*****************************************************************************

MatchName
	push	a2/a3/d2-d7
	move.l	a0,a3
	move.l	m_Name(a3),d2			; søke navn
	move.l	m_Data(a3),a2			; data område
	move.w	#Error_OK,m_Error(a3)		; ingen feil kilder ...
	moveq.l	#match_sizeof,d3

	move.w	#maksisøkebuffer,d0		; nullstiller bufferet
	moveq.l	#0,d1
	move.l	a2,a0
1$	move.b	d1,m_poeng(a0)
	add.l	d3,a0
	subq.w	#1,d0
	bne.b	1$

	moveq.l	#Log_entry_SIZEOF,d5
	move.l	(Users+CStr,MainBase),d4		; Henter maks antall brukere
	subq.l	#1,d4
	move.l	LogTabelladr(MainBase),a3
	move.l	d4,d0
	mulu	d5,d0
	add.l	d0,a3				; peker på det siste logentry'et
2$	move.w	l_UserBits(a3),d0		; drept.. Ikke med
	and.w	#USERF_Killed,d0
	bne.b	3$
	lea	l_Name(a3),a1
	move.l	d2,a0
	bsr	give_points
	move.w	d0,d6				; fikk vi noe ?
	bmi.b	3$				; nei.
	beq.b	3$				; nei.
; sett inn på riktig sted
	move.l	a2,a0
	moveq.l	#0,d0				; d0 = pos å sette inn på
5$	cmp.b	m_poeng(a0),d6
	bhi.b	4$
	add.l	d3,a0
	addq.l	#1,d0
	cmp.w	#maksisøkebuffer,d0
	bcs.b	5$
	bra.b	3$
4$	move.l	a0,d7				; husker plassen
	move.l	a2,a1
	move.w	#maksisøkebuffer,d1
	mulu	d3,d1
	add.l	d1,a1
	move.l	a1,a0
	sub.l	d3,a0
	neg.w	d0
	addq.w	#maksisøkebuffer-1,d0
	bmi.b	6$
	beq.b	6$
	mulu	d3,d0
	bsr	memcopyrlen
6$	move.l	d7,a0
	move.b	d6,m_poeng(a0)
	lea	m_navn(a0),a1
	lea	l_Name(a3),a0
	bsr	strcopy
3$	sub.l	d5,a3
	subq.l	#1,d4
	bcc.b	2$
	pop	a2/a3/d2-d7
	rts

*****************************************************************************
;SetAvailSysop(boolean)
;		m_Data
*****************************************************************************
SetAvailSysop
	push	d2
	move.w	#Error_OK,m_Error(a0)
	move.l	m_Data(a0),d0
	bne.b	2$
	or.w	#MainBitsF_SysopNotAvail,MainBits(MainBase)	; setter sysop not avail
	bra.b	1$
2$	and.w	#~MainBitsF_SysopNotAvail,MainBits(MainBase)	; setter sysop avail
1$	move.l	d0,d2						; husker status

	move.l	mainwindowadr,d0			; har vi vindu ?
	beq.b	9$					; nope. Gjør ikke noe.
	move.l	intbase,a6				; vekk med meny
	move.l	d0,a0
	jsrlib	ClearMenuStrip
	move.l	(mainmenustruct),a0
	move.w	#1+(0<<5),d0
	jsrlib	ItemAddress
	move.l	d0,a0
	move.l	d2,d0
	beq.b	3$
	and.w	#~CHECKED,(mi_Flags,a0)			; Oppdaterer menu item'et
	bra.b	4$
3$	or.w	#CHECKED,(mi_Flags,a0)			; Oppdaterer menu item'et
4$	move.l	mainwindowadr,a0			; og opp med menyen igjen
	move.l	(mainmenustruct),a1
	jsrlib	ResetMenuStrip
9$	move.l	exebase,a6
	pop	d2
	rts

*****************************************************************************
;Error = DeleteDir (dir nr)
;m_Error	    m_UserNr
*****************************************************************************
DeleteDir
	push	a2/d2/d3/a3
	move.l	a0,a2
	move.l	m_UserNr(a2),d2			; Dir nr * 1
	move.w	#Error_Not_Found,m_Error(a2)
	move.l	(firstFileDirRecord+CStr,MainBase),a3
	lea	(n_DirName,a3),a3
	move.l	d2,d0
	mulu	#FileDirRecord_SIZEOF,d0
	add.l	d0,a3
	tst.b	(a3)
	beq	9$				; Allerede slettet.
	move.l	a3,a0
	bsr	createdirfilepath		; lager i txtbuffer
	move.w	#Error_File,m_Error(a2)
	move.l	d2,d0
	lsl.l	#2,d0
	move.l	(n_Filedirfiles,MainBase),a0
	btst	#CflagsB_CacheFL,(Cflags2+CStr,MainBase)	; cache ?
	beq.b	2$				; nei.
	move.l	(a0,d0.l),d1
	beq.b	3$				; ingen fil. Rart..
	moveq.l	#0,d3
	move.l	d3,(a0,d0.l)			; sletter ptr.
	move.l	d1,a1
	move.l	(first_file,a1),d3		; husker første fil (hvis noen)
	move.l	(flpool,MainBase),a0
	move.l	#fileentryheader_sizeof,d0
	jsr	_AsmFreePooled
4$	tst.l	d3				; har vi fil ?
	beq.b	3$				; nope, ferdig
	move.l	d3,a1				; frigir alle mem copy'ene
	move.l	(mem_fnext,a1),d3
	move.l	(flpool,MainBase),a0
	moveq.l	#mem_Fileentry_SIZEOF,d0
	jsr	_AsmAllocPooled
	bra.b	4$

2$	move.l	dosbase,a6
	bsr	closefile
	tst.l	d0
	beq.b	9$
3$	move.l	dosbase,a6
	lea	txtbuffer(MainBase),a0		; Filnavn (path/fildir.fl)
	move.l	a0,d1
	jsrlib	DeleteFile
	tst.l	d0
	beq.b	9$
	move.w	#Error_Open_File,m_Error(a2)
	move.b	#0,(a3)				; sletter i config
	move.w	d2,d0
	add.w	#1,d0

	move.l	(firstFileDirRecord+CStr,MainBase),a0	; rydder opp i fileorder
	moveq.l	#0,d1
	move.w	(MaxfileDirs+CStr,MainBase),d1
	subq.l	#1,d1
6$	cmp.w	(n_FileOrder,a0),d0
	lea	(FileDirRecord_SIZEOF,a0),a0
	dbeq	d1,6$
	cmp.w	#-1,d1
	beq.b	7$				; fant ikke.. Error. ferdig.
	sub.l	#FileDirRecord_SIZEOF,a0
5$	move.b	(n_FileOrder+FileDirRecord_SIZEOF,a0),(n_FileOrder,a0)	; sletter denne
	lea	(FileDirRecord_SIZEOF,a0),a0
	dbeq	d1,5$
	move.b	#0,(-FileDirRecord_SIZEOF+n_FileOrder,a0) ; og sletter siste
7$	subq.w	#1,(ActiveDirs+CStr,MainBase)
	bcc.b	1$
	move.w	#0,(ActiveDirs+CStr,MainBase)
1$	bsr	main_saveconfig			; lagrer config
	beq.b	9$
	move.w	#Error_OK,m_Error(a2)
9$	move.l	exebase,a6
	pop	a2/d2/d3/a3
	rts

*****************************************************************************
;Error = RenameDir (dir nr, new name)
;m_Error	   m_UserNr,m_Name
*****************************************************************************
RenameDir
	push	a2/d2/a3
	move.l	a0,a2
	move.l	m_UserNr(a2),d2			; Dir nr * 1
	move.w	#Error_Not_Found,m_Error(a2)
	move.l	m_Name(a2),a0			; bygger opp new name
	bsr	createdirfilepath		; lager i txtbuffer
	lea	txt2buffer(MainBase),a1
	move.l	d0,a0
	bsr	strcopy
	move.l	(firstFileDirRecord+CStr,MainBase),a3	; bygger opp old name
	lea	(n_DirName,a3),a3
	move.l	d2,d0
	mulu	#FileDirRecord_SIZEOF,d0
	add.l	d0,a3
	move.l	a3,a0
	tst.b	(a0)
	beq.b	9$				; Finnes ingen dir her
	bsr	createdirfilepath		; lager i txtbuffer
	move.l	dosbase,a6
	move.w	#Error_File,m_Error(a2)
	lea	txtbuffer(MainBase),a0		; Filnavn (path/fildir.fl)
	move.l	a0,d1				; oldname
	lea	txt2buffer(MainBase),a0		; Filnavn (path/fildir.fl)
	move.l	a0,d2				; new name
	jsrlib	Rename
	tst.l	d0
	beq.b	9$
	move.w	#Error_Open_File,m_Error(a2)

	move.l	m_Name(a2),a0
	move.l	a3,a1
	bsr	strcopy
	bsr	main_saveconfig			; lagrer config
	beq.b	9$
	move.w	#Error_OK,m_Error(a2)
9$	move.l	exebase,a6
	pop	a2/d2/a3
	rts

*****************************************************************************
;Error = DeleteConference (conf nr, data area)  DELCONF
;m_Error		   m_UserNr m_Data
*****************************************************************************
DeleteConference
	push	d2-d7/a2/a3
	move.l	a0,a3				; husker meldingen
	move.l	m_Data(a3),a2			; data område
	move.l	a2,d7
	move.l	m_UserNr(a3),d5			; conferanse nr * 1
	move.w	#Error_Not_Found,m_Error(a3)
	cmp.w	(Maxconferences+CStr,MainBase),d5
	bcc	9$
	move.w	#Error_Not_allowed,m_Error(a3)
	cmp.w	#4,d5				; ikke lov å slette de 4 første
	bcs	9$

	lea	(u_almostendsave,a2),a2
	move.w	d5,d0
	mulu	#Userconf_seizeof,d0
	add.l	d0,a2			; Har nå adressen til access word'et
	move.l	dosbase,a6
	move.w	#Error_Open_File,m_Error(a3)
	move.l	userfile(MainBase),d4		; tar først og sletter accessen
	beq	9$				; ingen userfil. Ut..
	move.w	#Error_File,m_Error(a3)		; til denne conferansen for alle
	move.l	d4,d1				; søker tilbake
	moveq.l	#0,d2
	moveq.l	#OFFSET_BEGINNING,d3
	jsrlib	Seek
	bsr	testseekerror
	bne	8$				; error
	move.l	(UserrecordSize+CStr,MainBase),d6 ; brukere
1$	move.l	d4,d1				; leser inn bruker
	move.l	d7,d2
	move.l	d6,d3
	jsrlib	Read
	tst.l	d0
	beq.b	2$
	cmp.l	d3,d0
	bne	8$
	moveq.l	#0,d0
	move.w	d0,(uc_Access,a2)		; sletter conf access
	move.l	d0,(uc_LastRead,a2)		; sletter last read
	move.l	d4,d1				; søker tilbake
	move.l	d6,d2
	neg.l	d2
	moveq.l	#OFFSET_CURRENT,d3
	jsrlib	Seek
	bsr	testseekerror
	bne	8$				; error
	move.l	d4,d1				; og lagrer brukeren
	move.l	d6,d3
	move.l	d7,d2
	jsrlib	Write
	cmp.l	d0,d3
	bne	8$
	bra.b	1$				; fortsetter
2$	move.l	d4,d1
	jsrlib	Close
	move.w	#Error_Open_File,m_Error(a3)
	move.l	#userfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,userfile(MainBase)
	beq	9$
	move.l	d5,d2
	lsl.l	#2,d2
	move.l	d2,d0
	move.l	(n_MsgTextfiles,MainBase),a0	; lukker filene
	bsr	closefile
	move.l	d2,d0
	move.l	(n_MsgHeaderfiles,MainBase),a0
	bsr	closefile

	lea	(n_ConfName+n_FirstConference+CStr,MainBase),a0
	move.l	d5,d0
	mulu	#ConferenceRecord_SIZEOF,d0
	lea	(n_ConfName,a0,d0.l),a0		; Har konferanse navnet.
	tst.b	(a0)				; er den en conferanse her ?
	beq.b	3$				; nei, hopper over del
	move.l	a0,a2				; husker
	lea	dotmsgheadertxt,a1
	bsr	createconffilepath
	move.l	d0,d1
	jsrlib	DeleteFile
	move.l	a2,a0
	lea	dotmessagestext,a1
	bsr	createconffilepath
	move.l	d0,d1
	jsrlib	DeleteFile
3$	move.l	exebase,a6
	move.w	#Error_Open_File,m_Error(a3)
	moveq.l	#0,d0
	move.b	d0,(n_ConfName,a2)		; sletter alt
	move.b	d0,(n_ConfBullets,a2)
	move.l	d0,(n_ConfDefaultMsg,a2)
	move.l	d0,(n_ConfFirstMsg,a2)
	move.w	d0,(n_ConfSW,a2)
	move.w	d0,(n_ConfMaxScan,a2)

; JEO Sletter ikke n_ConfOrder

	move.w	d5,d0					; max konfer i bruk d5
	add.w	#1,d0					; pluss 1
	lea	(n_FirstConference+CStr,MainBase),a0	; Peker til første i a0
;	moveq.l	#0,d1
;	move.w	(Maxconferences+CStr,MainBase),d1	; Max_confer i d1
;	subq.l	#1,d1					; minus 1
;6$	cmp.w	(n_ConfOrder,a0),d0
;	lea	(ConferenceRecord_SIZEOF,a0),a0
;	dbeq	d1,6$
;	cmp.w	#-1,d1
;	beq.b	7$				; fant ikke.. Error. ferdig.
;	lea	(-ConferenceRecord_SIZEOF,a0),a0
;5$	move.w	(n_ConfOrder+ConferenceRecord_SIZEOF,a0),(n_ConfOrder+a0) ; sletter denne
;	lea	(ConferenceRecord_SIZEOF,a0),a0
;	dbeq	d1,5$
;	move.w	#0,(n_ConfOrder-ConferenceRecord_SIZEOF,a0)	; og sletter siste

7$	subq.w	#1,(ActiveConf+CStr,MainBase)	; tar bort 1 i teller
	bcc.b	4$				; sikkerhet
	move.w	#0,(ActiveConf+CStr,MainBase)
4$	bsr	main_saveconfig			; lagrer config
	beq.b	9$
	move.w	#Error_OK,m_Error(a3)
;	bra.b	9$
8$;	move.l	d4,d1				; hvorfor lukke ??
;	jsrlib	Close
9$	move.l	exebase,a6
	pop	a2/a3/d2-d7
	rts

*****************************************************************************
;Error = CleanConference (conf nr, data area)
;m_Error		   m_UserNr m_Data
*****************************************************************************
CleanConference
	push	d2-d7/a2/a3
	move.l	a0,a3
	move.l	m_Data(a3),a2			; data område
	move.l	a2,d7
	move.l	m_UserNr(a3),d5			; conferanse nr
	move.w	#Error_Not_Found,m_Error(a3)
	cmp.w	(Maxconferences+CStr,MainBase),d5
	bcc	9$
	lea	(u_almostendsave,a2),a2
	move.w	d5,d0
	mulu	#Userconf_seizeof,d0
	lea	(uc_LastRead,a2,d0.l),a2	; Har nå adressen til last read

	move.l	dosbase,a6
	move.w	#Error_Open_File,m_Error(a3)
	move.l	userfile(MainBase),d4		; tar først og sletter last read
	beq	9$
	move.w	#Error_File,m_Error(a3)		; til denne conferansen for alle
	move.l	d4,d1				; søker tilbake
	moveq.l	#0,d2
	moveq.l	#OFFSET_BEGINNING,d3
	jsrlib	Seek
	bsr	testseekerror
	bne	8$				; error
	move.l	(UserrecordSize+CStr,MainBase),d6 ; brukere
1$	move.l	d4,d1				; leser inn bruker
	move.l	d7,d2
	move.l	d6,d3
	jsrlib	Read
	tst.l	d0
	beq.b	2$
	cmp.l	d3,d0
	bne	8$				; read error
	moveq.l	#0,d0
	move.l	d0,(a2)				; sletter last read
	move.l	d4,d1				; søker tilbake
	move.l	d6,d2
	neg.l	d2
	moveq.l	#OFFSET_CURRENT,d3
	jsrlib	Seek
	bsr	testseekerror
	bne	8$				; error
	move.l	d4,d1				; og lagrer brukeren
	move.l	d6,d3
	move.l	d7,d2
	jsrlib	Write
	cmp.l	d0,d3
	bne	8$				; write error
	bra.b	1$				; fortsetter
2$	move.l	d4,d1
	jsrlib	Close
	move.w	#Error_Open_File,m_Error(a3)
	move.l	#userfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,userfile(MainBase)
	beq	9$
	move.l	d5,d2
	lsl.l	#2,d2
	move.l	d2,d0
	move.l	(n_MsgTextfiles,MainBase),a0	; lukker filene
	bsr	closefile
	move.l	d2,d0
	move.l	(n_MsgHeaderfiles,MainBase),a0
	bsr	closefile

	move.l	d5,d0
	lea	(n_FirstConference+CStr,MainBase),a0
	mulu	#ConferenceRecord_SIZEOF,d0
	add.l	d0,a0
	moveq.l	#0,d1
	move.l	d1,(n_ConfDefaultMsg,a0)
						; sletter filene
	lea	(n_ConfName,a0),a0		; Har konferanse navnet.
	tst.b	(a0)				; er det en conferanse her ?
	beq	9$				; nei, hopper over del
	move.l	a0,a2
	lea	dotmsgheadertxt,a1
	bsr	createconffilepath
	move.l	d0,d1

	move.w	#Error_Open_File,m_Error(a3)
	move.l	dosbase,a6
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d3
	beq	9$
	move.l	a2,a0
	lea	dotmessagestext,a1
	bsr	createconffilepath
	move.l	d0,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open

	move.l	d5,d1
	lsl.l	#2,d1
	move.l	(n_MsgTextfiles,MainBase),a0
	move.l	d0,0(a0,d1.w)
	bne.b	5$
	move.l	d3,d1
	jsrlib	Close
	bra.b	9$
5$	move.l	(n_MsgHeaderfiles,MainBase),a0
	move.l	d3,0(a0,d1.w)

	bsr	main_saveconfig			; lagrer config
	beq.b	9$
	move.w	#Error_OK,m_Error(a3)
	bra.b	9$
8$	move.l	d4,d1
	jsrlib	Close
9$	move.l	exebase,a6
	pop	a2/a3/d2-d7
	rts

*****************************************************************************
;Error = RenameConference (conf nr, new name, new status bits)
;m_Error		   m_UserNr,m_Name,	m_Data
*****************************************************************************
RenameConference
	push	a2/d2/d3/a3
	move.l	a0,a2
	move.l	m_UserNr(a2),d2			; confnr * 1
	lea	(n_FirstConference+CStr,MainBase),a3
	move.l	d2,d0
	mulu	#ConferenceRecord_SIZEOF,d0
	add.l	d0,a3				; har conference strukturen
	move.l	m_Name(a2),d0			; skal vi bytte navn ?
	beq	1$				; nei
	move.w	#Error_Not_Found,m_Error(a2)

	move.l	m_Name(a2),a0			; bygger opp new name
	lea	dotmessagestext,a1
	bsr	createconffilepath
	move.l	d0,a0
	lea	txt2buffer(MainBase),a1
	bsr	strcopy

	lea	(n_ConfName,a3),a0		; bygger opp old name
	tst.b	(a0)
	beq	9$				; Finnes ingen conf her
	move.l	a0,d3				; husker navnet ..
	lea	dotmessagestext,a1
	bsr	createconffilepath

	move.l	dosbase,a6
	move.w	#Error_File,m_Error(a2)
	move.l	d0,d1				; oldname
	lea	txt2buffer(MainBase),a0		; Filnavn (path/confnavn.h)
	move.l	a0,d2				; new name
	jsrlib	Rename
	tst.l	d0
	beq.b	9$

	move.l	m_Name(a2),a0			; bygger opp new name
	lea	dotmsgheadertxt,a1
	bsr	createconffilepath
	move.l	d0,a0
	lea	txt2buffer(MainBase),a1
	bsr	strcopy

	move.l	d3,a0				; så tar vi .h filen
	lea	dotmsgheadertxt,a1
	bsr	createconffilepath
	move.l	d0,d1				; oldname
	lea	txt2buffer(MainBase),a0		; Filnavn (path/confnavn.h)
	move.l	a0,d2				; new name
	jsrlib	Rename
	tst.l	d0
	beq.b	9$
1$	move.l	m_Data(a2),d0			; skal vi forandre bits ?
	beq.b	2$				; nei
	move.w	d0,(n_ConfSW,a3)		; oppdaterer conf bit'ene
2$	move.w	#Error_Open_File,m_Error(a2)

	lea	(n_ConfName,a3),a1
	move.l	m_Name(a2),a0
	bsr	strcopy
	move.l	exebase,a6
	bsr	main_saveconfig			; lagrer config
	beq.b	9$
	move.w	#Error_OK,m_Error(a2)
9$	move.l	exebase,a6
	pop	a2/d2/d3/a3
	rts

*****************************************************************************
;Error = ChangeName (New name,  data area, usernr,  franode)
;m_Error	     m_Name	m_Data	   m_UserNr m_arg
*****************************************************************************
ChangeName
	push	a2/a3/d2/d3/d4/d5
	move.l	a0,a3			; tar vare på meldingen
	move.w	#Error_Not_Found,m_Error(a3)
	move.l	m_arg(a3),d3		; fra node nr
	move.l	m_UserNr(a3),d5
	cmp.l	(MaxUsers+CStr,MainBase),d5	; Sjekk om brukernr < maks brukernr.
	bhi	9$			; For høy. Error.
	move.w	#Error_Found,m_Error(a3)
	move.l	m_Name(a3),a0		; sjekker om det er noen med det
	bsr	finnlogentrynavn	; navnet vi vil bytte til
	beq.b	5$			; fant ikke. Ok.
	lea	(l_Name,a0),a1
	move.l	m_Name(a3),a0		; sjekker om det er samme navnet
	bsr	comparestringsicase
	bne	9$			; nei, ikke samme, ut ..
5$	move.w	#Error_User_Active,m_Error(a3)

	move.l	nodelist+LH_HEAD,a0	; går igjennom alle nodene
1$	move.l	(LN_SUCC,a0),d0
	beq.b	2$			; ferdig
	cmp.w	Nodenr(a0),d3		; er dette nodenr'et vi kommer fra ?
	beq.b	3$			; ja, da hoppe vi over testen
	cmp.l	Nodeusernr(a0),d5	; samme usernr ?
	beq	9$			; da er brukeren aktiv et annet sted
3$	move.l	d0,a0
	bra.b	1$			; looper til slutten

2$	move.l	NrTabelladr(MainBase),a0	; Henter logentry'et
	lsl.l	#2,d5
	move.l	0(a0,d5.l),d5		; Henter Lognr
	move.l	d5,d0
	mulu	#Log_entry_SIZEOF,d0
	move.l	LogTabelladr(MainBase),a0
	lea	0(a0,d0.l),a2		; Henter Logentry
	move.l	dosbase,a6		; henter inn bruker i m_data
	move.w	#Error_Open_File,m_Error(a3)
	move.l	userfile(MainBase),d4
	beq	9$
	move.l	d4,d1
	move.w	#Error_File,m_Error(a3)	; søker til riktig post
	moveq.l	#OFFSET_BEGINNING,d3
	move.l	l_RecordNr(a2),d2
	move.l	(UserrecordSize+CStr,MainBase),d0
	mulu	d0,d2
	jsrlib	Seek
	bsr	testseekerror
	bne	8$				; error
	move.l	d4,d1
	move.l	m_Data(a3),d2
	move.l	(UserrecordSize+CStr,MainBase),d3
	jsrlib	Read			; Les inn recorden
	moveq.l	#-1,d1			; read/write error ??
	cmp.l	d0,d1
	beq	8$
	move.l	m_Data(a3),a0		; fornadrer navnet i m_data
	lea	Name(a0),a1
	move.l	m_Name(a3),a0
	moveq.l	#Sizeof_NameT,d0
	bsr	strcopymaxlen
	move.l	d4,d1			; søker tilbake
	move.l	(UserrecordSize+CStr,MainBase),d2
	neg.l	d2
	moveq.l	#OFFSET_CURRENT,d3
	jsrlib	Seek
	bsr	testseekerror
	bne	8$				; error
	move.l	d4,d1			; saver bruker.
	move.l	m_Data(a3),d2
	move.l	(UserrecordSize+CStr,MainBase),d3
	jsrlib	Write
	moveq.l	#-1,d1			; read/write error ??
	cmp.l	d0,d1
	beq.b	8$
	move.l	d4,d1
	jsrlib	Close
	moveq.l	#0,d0
	move.l	d0,userfile(MainBase)
	move.w	#Error_Open_File,m_Error(a3)
	move.l	#userfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,userfile(MainBase)
	beq	9$
	move.l	exebase,a6		; userfile er oppdatert
	lea	l_Name(a2),a1		; Oppdaterer navnet i logentry'et
	move.l	m_Name(a3),a0
	moveq.l	#Sizeof_NameT,d0
	bsr	strcopymaxlen
	move.l	m_Data(a3),a0		; henter copy space
	move.l	d5,d0
	move.l	a2,a1
	bsr	movelogentry		; flytter logentry'et til riktig plass
	move.w	#Error_Open_File,m_Error(a3)
	bsr	savehash		; og lagrer log tabellen
	beq.b	9$
	move.l	(SYSOPUsernr+CStr,MainBase),d0
	cmp.l	m_UserNr(a3),d0		; er dette sysop ?
	bne.b	4$			; nei ...
	move.l	m_Name(a3),a0
	lea	(SYSOPname+CStr,MainBase),a1
	moveq.l	#Sizeof_NameT,d0
	bsr	strcopymaxlen
	bsr	main_saveconfig		; lagrer config
	beq.b	9$
4$	move.w	#Error_OK,m_Error(a3)
	bra.b	9$
8$	move.l	d4,d1
	jsrlib	Close
9$	move.l	exebase,a6
	pop	a2/a3/d2/d3/d4/d5
	rts

*******************************************************************************
*			support kode for node kommandoer
*******************************************************************************

******************************
;result = comparestringsicasespes (streng,streng1)
;Zero bit/minus bit		   a0.l   a1.l
******************************
comparestringsicasespes
1$	move.b	(a0)+,d0
	beq.b	2$
	bsr	upchar
	move.b	d0,d1
	move.b	(a1)+,d0
	beq.b	3$
	bsr	upchar
	cmp.b	d0,d1
	bne.b	9$
	bra.b	1$
2$	tst.b	(a1)
	beq.b	9$
	cmp.b	#'.',(a1)
	bne.b	9$
	setn
	rts
3$	clrz
9$	clrn
	rts

; d0 = logentrynr
; a0 = copy space
; a1 = entryet
movelogentry
	push	a2/a3/d2-d6
	move.l	a0,a2		; entry'et
	lea	l_Name(a1),a3	; det nye navnet
	moveq.l	#0,d3		; ny plass (0 foreløpig)
; finn hvilken plass entry'et skal ha
	move.l	(Users+CStr,MainBase),d4		; Henter maks antall brukere
	beq.b	9$				; ingen brukere (umulig, men ..)
	subq.l	#1,d4				; hi
	beq.b	9$				; bare en bruker, ferdig ..
	moveq.l	#Log_entry_SIZEOF,d5
	move.l	d0,d6				; nåværende plass
	bne.b	1$				; ikke først
	move.l	d5,d0
	bsr.b	11$				; sjekker den ovenfor
	blo.b	9$				; søke navn mindre, dvs ferdig
	bra.b	4$				; skal søke oppover
1$	cmp.l	d6,d4
	bhi.b	2$				; ligger ikke i noen ende
	move.l	d4,d0
	subq.l	#1,d0
	mulu	d5,d0
	bsr.b	11$				; sjekker den nedenfor
	bhi.b	9$				; søke navn større, dvs ferdig
	bra.b	3$				; skal søke nedover
2$	move.l	d6,d0
	addq.l	#1,d0
	bsr.b	10$				; sjekker den nedenfor
	bhi.b	4$				; søke navn større, søk oppover
	move.l	d6,d0
	subq.l	#1,d0
	bsr.b	10$				; sjekker den nedenfor
	bcc.b	9$				; ikke mindre, dvs står riktig
3$	move.l	d6,d3				; søker nedover
	subq.l	#1,d3
	move.l	d3,d2
	mulu	d5,d2
31$	move.l	d2,d0
	bsr.b	11$
	bhi.b	39$				; søke navn større, dvs ferdig
	subq.l	#1,d3
	bcs.b	39$				; nederst. ferdig
	sub.l	d5,d2
	bra.b	31$
39$	addq.l	#1,d3
	bra.b	5$
4$	move.l	d6,d3				; søker oppover
	addq.l	#1,d3
	move.l	d3,d2
	mulu	d5,d2
41$	move.l	d2,d0
	bsr.b	11$
	blo.b	49$				; søke navn mindre, dvs ferdig
	addq.l	#1,d3
	cmp.l	d3,d4
	bcs.b	49$				; nederst. ferdig
	add.l	d5,d2
	bra.b	41$
49$	subq.l	#1,d3
5$	move.l	d6,d0				; nåværende plass
	move.l	d3,d1				; ny plass
	move.l	a2,a0				; copy space
	bsr.b	20$				; foretar selve flyttingen
9$	pop	a2/a3/d2-d6
	rts

10$	mulu	d5,d0
11$	move.l	LogTabelladr(MainBase),a0	; sjekker mot plass i d0
	add.l	d0,a0
	lea	l_Name(a0),a1
	move.l	a3,a0
	moveq.l	#Sizeof_NameT,d0
	bra	comparestringsifull

; d0 = nåværende plass
; d1 = ny plass
; a0 = copy space
20$	push	a2/a3/d2/d3/d4
	cmp.l	d0,d1				; samme ?
	beq.b	29$				; ferdig
	move.l	d0,d2				; fra
	move.l	d1,d3				; til
	move.l	a0,a2
	move.l	a0,a1				; kopierer entryet til copyspace
	move.l	LogTabelladr(MainBase),a0
	mulu	#Log_entry_SIZEOF,d0
	add.l	d0,a0
	moveq.l	#Log_entry_SIZEOF,d0
	move.l	a0,a3				; husker starten på fra entry'et
	bsr	memcopylen
	move.l	a3,a0				; henter fram fra entry adressen
	moveq.l	#Log_entry_SIZEOF,d1
	move.l	d2,d0
	sub.l	d3,d0				; hvilken retning ?
	bcs.b	21$				; vi skal flytte oppover
	move.l	d0,d4				; d4 = antall plasser å flytte
	move.l	a0,a1				; flytter nedover
	add.l	d1,a1
	move.l	d1,d0
	mulu	d4,d0
	move.l	LogTabelladr(MainBase),a3	; beregner laveste adresse
	mulu	d3,d1
	add.l	d1,a3				; og husker den.
	move.l	d3,d2				; husker nr'et også
	bsr	memcopyrlen			; flytter ....
	bra.b	22$
21$	neg.l	d0				; flytter oppover
	move.l	d0,d4				; d4 = antall plasser å flytte
	move.l	a0,a1
	add.l	d1,a0
	move.l	d1,d0
	mulu	d4,d0
	move.l	a1,a3				; husker laveste adresse
;	move.l	d2,d2				; husker nr'et også
	bsr	memcopylen			; flytter ...
22$	move.l	d3,d1				; beregner adressen til til
	move.l	LogTabelladr(MainBase),a1
	moveq.l	#Log_entry_SIZEOF,d0
	mulu	d0,d1
	add.l	d1,a1
	move.l	a2,a0				; kopierer det entryet vi har
	bsr	memcopylen			; flyttet til ny plass
; oppdater Nrtabellen.
	move.l	NrTabelladr(MainBase),a0
	moveq.l	#Log_entry_SIZEOF,d1
; d2 = nr til laveste entry
; d4 = antall vi har flyttet
; a3 = adr til laveste entry
23$	move.l	l_UserNr(a3),d0
	lsl.l	#2,d0
	move.l	d2,0(a0,d0.l)
	add.l	d1,a3
	addq.l	#1,d2
	subq.l	#1,d4
	bcc.b	23$
29$	pop	a2/a3/d2/d3/d4
	rts

give_points
	push	d2
	moveq.l	#0,d2			; antall poeng
	move.b	(a1)+,d0		; sjekker fornavnet
	bsr	upchar			; rører ikke annet en d0
	move.b	d0,d1
	move.b	(a0)+,d0
	bsr	upchar			; rører ikke annet en d0
	cmp.b	d0,d1			; er første bokstav lik ?
	bne.b	8$			; nei, null poeng
	addq.l	#1,d2			; gir poeng for match
1$	move.b	(a0)+,d0
	beq.b	8$			; error, EOString
	cmp.b	#' ',d0			; mellomrom ?
	beq.b	2$			; ja, går over til etternavn
	bsr	upchar
	move.b	d0,d1
	move.b	(a1)+,d0
	beq.b	8$			; feil..
	bsr	upchar
	addq.l	#1,d2			; gir poeng
	cmp.b	d0,d1			; tester tegn
	beq.b	1$			; de er like.. fortsetter
	subq.l	#2,d2			; feil, tar tilbake poeng + 1 for feil
	bra.b	1$
2$	move.b	(a1)+,d1		; søker etter mellomrom i navnet
	beq.b	8$			; feil..
	cmp.b	#' ',d1
	bne.b	2$
3$	move.b	(a1)+,d0		; sjekker etternavnet
	bsr	upchar
	move.b	d0,d1
	move.b	(a0)+,d0
	bsr	upchar
	cmp.b	d0,d1			; er første bokstav lik ?
	bne.b	8$			; nei, null poeng
	addq.l	#2,d2			; gir poeng for match
4$	move.b	(a0)+,d0
	beq.b	9$			; ferdig
	bsr	upchar
	move.b	d0,d1
	move.b	(a1)+,d0
	beq.b	6$			; feil..
	bsr	upchar
	addq.l	#2,d2			; gir poeng
	cmp.b	d0,d1			; tester tegn
	beq.b	4$			; de er like.. fortsetter
5$	subq.l	#4,d2			; feil, tar tilbake poeng + 1 for feil (*2)
	bra.b	4$
6$	subq.l	#1,a1			; korigerer a1
	bra.b	5$			; og prøver videre
8$	moveq.l	#0,d2			; returnerer null poeng
9$	move.l	d2,d0
	pop	d2
	rts

; a0 = peker til navn vi skal finne.
; returnerer: a0, logentry til dette navnet
; 		Z = 0, Fant logentry'et
finnlogentrynavn
	push	a2/a3/d2-d5
	move.l	a0,a3				; lager peker til navnet
	move.l	(Users+CStr,MainBase),d4		; Henter antall brukere
	beq.b	9$				; ingen brukere (usansynelig)
	subq.l	#1,d4				; hi
	moveq.l	#0,d2				; lo
	moveq.l	#Log_entry_SIZEOF,d5
1$	cmp.l	d2,d4
	bcs.b	4$
	move.l	d2,d3
	add.l	d4,d3
	lsr.l	#1,d3				; mid = (lo + hi) / 2
	move.l	d3,d0
	mulu	d5,d0
	move.l	LogTabelladr(MainBase),a2
	lea	0(a2,d0.l),a2
	lea	l_Name(a2),a1
	move.l	a3,a0
	moveq.l	#Sizeof_NameT,d0
	bsr	comparestringsifull
	blo.b	2$				; søke navn mindre
	bhi.b	3$				; søke navn større
	bra.b	8$				; egentlig beq, men det er kun beq som kommer hit.
2$	move.l	d3,d4
	subq.l	#1,d4
	bcc.b	1$
	bra.b	4$				; Vi fant ikke noe.
3$	move.l	d3,d2
	addq.l	#1,d2
	bra.b	1$
4$	setz
	bra.b	9$
8$	move.l	a2,a0				; vi fant den
	clrz
9$	pop	a2/a3/d2-d5
	rts

; a0 = navnet vi skal slette ifra log tabellen
deletelogentry
	bsr	finnlogentrynavn		; finner log entry'en, gir peker til starten i a0
	beq.b	9$				; finnes ikke.. (sletta :-)
	move.l	(Users+CStr,MainBase),d0		; Henter maks antall brukere
	subq.l	#1,d0				; hi
	moveq.l	#Log_entry_SIZEOF,d1
	mulu	d1,d0
	add.l	LogTabelladr(MainBase),d0	; har nå starten på siste logentry
	sub.l	a0,d0				; trekker fra starten på dette, har da
	beq.b	8$				; antall bytes som skal kopieres
	bcs.b	8$				; sjekker for underflow
	move.l	a0,a1
	add.l	d1,a0
	jsr	memcopylen			; sletter ved å flytte de andre
8$	clrz
9$	rts

; a0 = peker til log entry som skal settes inn.
; returnerer plassen i d0.
insertlogentry
	movem.l	a2/a3/d2-d7,-(sp)
	move.l	a0,a3
	moveq.l	#0,d3				; setter d3 til 0, i tilfelle vi hopper til 7$
	move.l	(Users+CStr,MainBase),d4
	subq.l	#1,d4
	bcs.b	7$
	moveq.l	#0,d2
	moveq.l	#Log_entry_SIZEOF,d6

1$	cmp.l	d2,d4
	bcs.b	4$
	move.l	d2,d3
	add.l	d4,d3
	lsr.l	#1,d3				; mid = (lo + hi) / 2
	move.l	d3,d0
	mulu	d6,d0
	move.l	LogTabelladr(MainBase),a2
	lea	0(a2,d0.l),a2
	lea	l_Name(a2),a1
	lea	l_Name(a3),a0
	moveq.l	#Sizeof_NameT,d0
	bsr	comparestringsifull
	blo.b	2$				; søke navn mindre
	bhi.b	3$				; søke navn større
	setz
	bra	9$				; Den finnes fra før !!
2$	move.l	d3,d4
	beq.b	4$				; sikkerhet
	subq.l	#1,d4
	bra.b	1$
3$	move.l	d3,d2
	addq.l	#1,d2
	bra.b	1$
4$	move.l	(Users+CStr,MainBase),d0		; Passer på at vi ikke kommer
	subq.l	#1,d0				; utenfor (på overkant)
	cmp.l	d0,d4
	bls.b	5$
	move.l	d0,d4
5$	move.l	d4,d3
	move.l	d4,d0
	mulu	d6,d0
	move.l	LogTabelladr(MainBase),a2
	lea	0(a2,d0.l),a2
	lea	l_Name(a2),a1
	lea	l_Name(a3),a0
	moveq.l	#Sizeof_NameT,d0
	bsr	comparestringsifull
	blo.b	7$				; søke navn mindre
	addq.l	#1,d3				; søke navn større, dvs etter denne.

; nå er plassen den skal inn på i d3.
7$	move.l	(Users+CStr,MainBase),d2
	move.l	MaxNumLogEntries(MainBase),d1
	cmp.l	d2,d1
	bhi	11$				; vi har plass
	moveq.l	#50,d0
	add.l	d0,d1				; øker med 50 plasser
	move.l	d1,d0
	move.l	d1,-(a7)
	mulu	d6,d0
	lsl.l	#2,d1
	add.l	d1,d0
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	jsrlib	AllocMem
	move.l	d0,d7
	bne.b	12$
	addq.l	#4,sp				; pop'er d1
	setz
	bra	9$				; Vi fikk ikke allokert noe
12$	move.l	d7,a1
	move.l	(a7),d0				; henter ny maxnumlogentrys
	lsl.l	#2,d0
	add.l	d0,a1				; beregner ny start av logtabellen
	move.l	LogTabelladr(MainBase),a0
	move.l	MaxNumLogEntries(MainBase),d0
	mulu	d6,d0
	jsr	memcopylen			; kopierer tabellen over i større minne
	move.l	d7,a1				; starten for ny nrtabell
	move.l	NrTabelladr(MainBase),a0
	move.l	MaxNumLogEntries(MainBase),d0
	lsl.l	#2,d0
	jsr	memcopylen			; kopierer nr tabellen

	move.l	NrTabelladr(MainBase),a1	; frigir gammelt minne
	move.l	MaxNumLogEntries(MainBase),d0
	moveq.l	#Log_entry_SIZEOF+4,d1
	mulu	d1,d0				; har nå minne i bytes
	jsrlib	FreeMem

	move.l	(a7)+,d1
	move.l	d1,MaxNumLogEntries(MainBase)	; oppdaterer
	move.l	d7,NrTabelladr(MainBase)
	lsl.l	#2,d1
	add.l	d1,d7
	move.l	d7,LogTabelladr(MainBase)
	move.l	(Users+CStr,MainBase),d2

11$	subq.l	#1,d2
	move.l	d2,d5
	mulu	d6,d2
	move.l	LogTabelladr(MainBase),a2
; d2 = maks * size
; d3 = plassen
; d5 = maks
10$	cmp.l	d3,d5				; Har vi flyttet alle vi må flytte ?
	blt.b	8$				; Jepp.
	subq.l	#1,d5				; Logentry'ene starter på 0..

	lea	0(a2,d2.l),a0			; Finner starten på denne
	lea	Log_entry_SIZEOF(a2,d2.l),a1	; Finner ny start
	move.l	l_UserNr(a0),-(a7)		; Husker bruker nummeret
	moveq.l	#Log_entry_SIZEOF,d0
	jsr	memcopylen			; kopierer til ny plass
	move.l	NrTabelladr(MainBase),a0	; Oppdaterer Nrtabellen
	move.l	(a7)+,d0			; henter ut usernr'et igjen
	lsl.l	#2,d0				; * 4
	addq.l	#1,0(a0,d0.l)			; og oppdaterer (vi har flyttet
	sub.l	d6,d2
	bra.b	10$				; og her starter vi ...

;Nå er det bare å sette inn. (d3 er plass nr'et)
8$	move.l	d3,d4
	mulu	d6,d3
	lea	0(a2,d3.l),a1			; Finner starten på denne
	move.l	a3,a0
	move.l	l_UserNr(a0),-(a7)		; Husker bruker nummeret
	moveq.l	#Log_entry_SIZEOF,d0
	jsr	memcopylen			; kopierer inn på plassen
	move.l	NrTabelladr(MainBase),a0	; Oppdaterer Nrtabellen
	move.l	(a7)+,d0			; henter ut usernr'et igjen
	lsl.l	#2,d0				; * 4
	move.l	d4,0(a0,d0.l)			; setter inn i NrTabell.
	move.l	d4,d0
	clrz					; Alt gikk ok.
9$	movem.l	(sp)+,a2/a3/d2-d7
	rts

main_saveconfig
	push	d2-d4
	move.l	dosbase,a6
	move.l	#configfilename,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	1$
	move.l	d4,d1
	lea	(CStr,MainBase),a0
	move.l	a0,d2
	move.l	(Configsize,a0),d3
	jsrlib	Write
	move.l	d4,d1
	move.l	d0,d2				; husker bytes skrevet
	jsrlib	Close
	cmp.l	d3,d2				; skrev vi allt ?
	notz
1$	pop	d2-d4
	move.l	exebase,a6
	rts

savelog	push	d2-d4/a6
	move.l	dosbase,a6
	move.l	#indexfilename,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	9$
	move.l	d4,d1
	move.l	LogTabelladr(MainBase),d2
	move.l	(Users+CStr,MainBase),d3			; det finnes Users mange logendtrys
	mulu	#Log_entry_SIZEOF,d3
	jsrlib	Write
	move.l	d0,d2
	move.l	d4,d1
	jsrlib	Close
	cmp.l	d2,d3				; Skrev vi alt ?
	notz
9$	pop	d2-d4/a6
	rts

******************************
;savehash - saves hash tables
******************************

savehash
	bsr	savelog
	push	d2-d4/a6
	move.l	dosbase,a6

	move.l	#nrindexfilename,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	9$
	move.l	d4,d1
	move.l	NrTabelladr(MainBase),a0
	move.l	a0,d2
	move.l	(MaxUsers+CStr,MainBase),d3
	lsl.l	#2,d3			; antall brukere * 4
	jsrlib	Write
	move.l	d0,d2
	move.l	d4,d1
	jsrlib	Close
	cmp.l	d2,d3				; Skrev vi alt ?
	notz
9$	pop	d2-d4/a6
	rts

; a0 = filptr base
; d0 = filnr*4
; d1 = pos i fila
seekfile
	movem.l	a2/d2/d3,-(sp)
	move.l	a0,a2
	add.l	d0,a2
	moveq.l	#-1,d0
	cmp.l	d0,d1
	bne.b	1$
	moveq.l	#OFFSET_END,d3
	moveq.l	#0,d2
	bra.b	2$
1$	move.l	d1,d2
	moveq.l	#OFFSET_BEGINNING,d3
2$	move.l	(a2),d1
	beq.b	9$			; Filen er ikke åpen.
	jsrlib	Seek
	push	d0
	jsrlib	IoErr
	tst.l	d0
	notz
	pop	d0
9$	movem.l	(sp)+,d2/d3/a2
	rts

; a0 = filptr base
; d0 = filnr*4
; d2 = buffer
; d3 = len
readfile
	move.l	0(a0,d0.l),d1
	beq.b	7$
	jsrlib	Read
	tst.l	d0
	clrn
	beq.b	9$
	cmp.l	d0,d3
	clrn
	beq.b	8$
7$	setn
8$	clrz
9$	rts

; a0 = filptr base
; d0 = filnr*4
; d2 = buffer
; d3 = len
writefile
	move.l	0(a0,d0.l),d1
	beq.b	9$
	jsrlib	Write
	cmp.l	d0,d3
	beq.b	8$
	clrz
8$	notz
9$	rts

; d0 = dir * 4
; d1 = offset, if d1 == -1L place at end
; a0 = entry
; ret: z = 1, error
; d0 pos (if ok)
savefileentrycachemode
	push	d2-d5/a2/a6
	move.l	dosbase,a6
	move.l	d0,d3				; dir nr
	move.l	a0,a2				; struct
	move.l	d1,d5				; offset
	move.l	(firstFileDirRecord+CStr,MainBase),a0
	lsr.l	#2,d0
	mulu	#FileDirRecord_SIZEOF,d0
	add.l	d0,a0
	lea	(n_DirName,a0),a0
	tst.b	(a0)
	beq.b	9$				; error: No directory
	bsr	createdirfilepath		; stores in txtbuffer
	move.l	d0,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	9$				; error open
	move.l	d4,d1
	moveq.l	#-1,d0
	cmp.l	d5,d0				; to end?
	bne.b	1$				; nope
	moveq.l	#0,d2
	moveq.l	#OFFSET_END,d3
	bra.b	2$
1$	move.l	d5,d2
	moveq.l	#OFFSET_BEGINNING,d3
2$	jsrlib	Seek
	bsr	testseekerror
	bne.b	8$				; error
	move.l	d4,d1				; finner pos
	moveq.l	#0,d2
	moveq.l	#OFFSET_CURRENT,d3
	jsrlib	Seek
	bsr	testseekerror
	bne.b	8$				; error
	move.l	d0,d5				; husker pos
	move.l	d4,d1
	move.l	a2,d2
	moveq.l	#Fileentry_SIZEOF,d3
	jsrlib	Write
	cmp.l	d0,d3
	bne.b	8$				; error write
	move.l	d4,d1
	jsrlib	Close
	move.l	d5,d0				; returnerer pos
	clrz
	bra.b	9$
8$	move.l	d4,d1
	jsrlib	Close
	setz
9$	pop	d2-d5/a2/a6
	rts

closefile
	move.l	0(a0,d0.l),d1
	beq.b	9$
	clr.l	0(a0,d0.l)		; sletter
	jsrlib	Close
9$	moveq.l	#1,d0			; sukse'
	rts

; d0 = dirnum * 4
openfilefile
	movem.l	d2/d3,-(a7)
	move.l	d0,d3
	move.l	(firstFileDirRecord+CStr,MainBase),a0
	lsr.l	#2,d0
	mulu	#FileDirRecord_SIZEOF,d0
	add.l	d0,a0
	lea	(n_DirName,a0),a0
	tst.b	(a0)
	beq.b	9$
	bsr	createdirfilepath		; lager i txtbuffer
	move.l	d0,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	(n_Filedirfiles,MainBase),a0
	move.l	d0,0(a0,d3.w)
9$	movem.l	(a7)+,d3/d2
	rts

; d0 = confnum * 4
openheaderfile
	push	d2/d3
	move.l	d0,d3
	lea	(n_ConfName+n_FirstConference+CStr,MainBase),a0
	lsr.l	#1,d0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	add.l	d0,a0			; Har konferanse navnet.
	tst.b	(a0)			; har vi konf der ?
	beq.b	9$			; nope, ut
	lea	dotmsgheadertxt,a1
	bsr	createconffilepath
	move.l	d0,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	(n_MsgHeaderfiles,MainBase),a0
	move.l	d0,(0,a0,d3.w)
9$	pop	d3/d2
	rts

; a0 = fildirname
; a1 = extension
createdirfilepath
	lea	(dotfilelisttext),a1
	push	a2/a3
	move.l	a0,a2
	move.l	a1,a3
	lea	fileheaderpath,a0
	lea	txtbuffer(MainBase),a1	; må bruke denne bufferen.. (renconf bruker dette)
	jsr	strcopy
	subq.l	#1,a1
	move.l	a2,a0
1$	move.b	(a0)+,d0		; bytter ut '/' tegn med space
	beq.b	2$
	move.b	d0,(a1)+
	cmp.b	#'/',d0
	bne.b	1$
	move.b	#' ',-1(a1)
	bra.b	1$
2$	move.l	a3,a0
	jsr	strcopy
	lea	txtbuffer(MainBase),a0	; Filnavn
	move.l	a0,d0
	pop	a2/a3
	rts

; a0 = conf/fil name
; a1 = extension
createconffilepath
	push	a2/a3
	move.l	a0,a2
	move.l	a1,a3
	lea	conferencepath,a0
	lea	txtbuffer(MainBase),a1	; må bruke denne bufferen.. (renconf bruker dette)
	jsr	strcopy
	subq.l	#1,a1
	move.l	a2,a0
1$	move.b	(a0)+,d0		; bytter ut '/' tegn med space
	beq.b	2$
	move.b	d0,(a1)+
	cmp.b	#'/',d0
	bne.b	1$
	move.b	#' ',-1(a1)
	bra.b	1$
2$	move.l	a3,a0
	jsr	strcopy
	lea	txtbuffer(MainBase),a0	; Filnavn
	move.l	a0,d0
	pop	a2/a3
	rts

; d0 = confnum * 4
openmsgtextfile
	push	d2/d3
	move.l	d0,d3
	lea	(n_ConfName+n_FirstConference+CStr,MainBase),a0
	lsr.l	#1,d0
	mulu	#ConferenceRecord_SIZEOF/2,d0
	add.l	d0,a0			; Har konferanse navnet.
	tst.b	(a0)			; har vi konf der ?
	beq.b	9$			; nope, ut
	lea	dotmessagestext,a1
	bsr	createconffilepath
	move.l	d0,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	(n_MsgTextfiles,MainBase),a0
	move.l	d0,(0,a0,d3.w)
9$	pop	d3/d2
	rts

;a0 = filename
;a1 = adr
;d0 = size
readinfile
	push	d2-d5/a6
	move.l	dosbase,a6
	move.l	d0,d3
	move.l	a1,d5
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	9$
	move.l	d4,d1
	move.l	d5,d2
	jsrlib	Read
	cmp.l	d3,d0
	beq.b	1$
	move.l	d4,d1
	jsrlib	Close
	setz
	bra.b	9$
1$	move.l	d4,d1
	jsrlib	Close
	clrz
9$	pop	d2-d5/a6
	rts

openfiles
	push	d2/d3/d4/d5/a3/a2
	move.l	dosbase,a6
	move.l	#userfilename,d1
	move.l	d1,d5				; husker filnavn for error
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,(userfile,MainBase)
	beq	2$
	move.b	(Cflags2+CStr,MainBase),d0
	btst	#CflagsB_CacheFL,d0
	beq.b	11$
	bsr	readflfiles
	beq	99$
	bra.b	3$				; gikk bra, gå videre

11$	move.l	(n_Filedirfiles,MainBase),a2
	moveq.l	#0,d3
	move.l	(firstFileDirRecord+CStr,MainBase),a3
	lea	(n_DirName,a3),a3
1$	cmp.w	(ActiveDirs+CStr,MainBase),d3
	bcc.b	3$
	tst.b	(a3)			; er det en file dir her ?
	bne.b	7$			; ja..
	lea	(FileDirRecord_SIZEOF,a3),a3	; peker til neste navn
	moveq.l	#0,d0
	move.l	d0,(a2)+		; Sier at denne fila er tom..
	bra.b	1$
7$
	move.l	a3,a0
	bsr	createdirfilepath		; lager i txtbuffer
	move.l	d0,d1
	move.l	d1,d5
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	addq.l	#1,d3
	lea	(FileDirRecord_SIZEOF,a3),a3	; peker til neste navn
	move.l	d0,(a2)+
	bne.b	1$
	IFD	CreateMissingFiles
	move.l	d5,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,(-4,a2)
	bne.b	1$
	ENDC
	bra	2$

3$	move.l	(n_MsgHeaderfiles,MainBase),a2
	lea	(n_FirstConference+n_ConfName+CStr,MainBase),a3
	moveq.l	#0,d3
4$	cmp.w	(ActiveConf+CStr,MainBase),d3
	bcc.b	5$
	tst.b	(a3)			; er det en konf her ?
	bne.b	8$			; ja..
	lea	(ConferenceRecord_SIZEOF,a3),a3	; peker til neste navn
	moveq.l	#0,d0
	move.l	d0,(a2)+		; Sier at denne fila er tom..
	bra.b	4$
8$	move.l	a3,a0
	lea	dotmsgheadertxt,a1
	bsr	createconffilepath
	move.l	d0,d1
	move.l	d1,d5
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	addq.l	#1,d3
	lea	(ConferenceRecord_SIZEOF,a3),a3	; peker til neste navn
	move.l	d0,(a2)+
	bne.b	4$
	IFD	CreateMissingFiles
	move.l	d5,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,(-4,a2)
	bne.b	4$
	ENDC
	bra.b	2$

5$	move.l	(n_MsgTextfiles,MainBase),a2
	lea	(n_FirstConference+n_ConfName+CStr,MainBase),a3
	moveq.l	#0,d3
6$	cmp.w	(ActiveConf+CStr,MainBase),d3
	bcc.b	9$
	tst.b	(a3)			; er det en konf her ?
	bne.b	10$			; ja..
	lea	(ConferenceRecord_SIZEOF,a3),a3	; peker til neste navn
	moveq.l	#0,d0
	move.l	d0,(a2)+		; Sier at denne fila er tom..
	bra.b	6$
10$	move.l	a3,a0
	lea	dotmessagestext,a1
	bsr	createconffilepath
	move.l	d0,d1
	move.l	d1,d5
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	addq.l	#1,d3
	lea	(ConferenceRecord_SIZEOF,a3),a3	; peker til neste navn
	move.l	d0,(a2)+
	bne.b	6$
	IFD	CreateMissingFiles
	move.l	d5,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	move.l	d0,(-4,a2)
	bne.b	6$
	ENDC
2$
	lea	(erroropentext),a0
	bsr	writemainerror
	move.l	d5,a0
	bsr	writemainerror
	lea	(nltext),a0
	bsr	writemainerror
	setz
99$	move.l	exebase,a6
	pop	d2/d3/d4/d5/a3/a2
	beq	closefiles
	rts
9$	clrz
	bra.b	99$

closefiles
	push	d2/a2
	move.l	dosbase,a6
	move.l	userfile(MainBase),d1
	beq.b	10$
	jsrlib	Close
	moveq.l	#0,d0
	move.l	d0,userfile(MainBase)
10$	move.b	(Cflags2+CStr,MainBase),d0
	btst	#CflagsB_CacheFL,d0
	beq.b	2$
	bsr	closeflfiles
	bra.b	4$

2$	move.l	(n_Filedirfiles,MainBase),a2
	moveq.l	#0,d2
1$	move.l	(a2)+,d1
	beq.b	6$
	jsrlib	Close
6$	addq.l	#1,d2
	cmp.w	(MaxfileDirs+CStr,MainBase),d2
	bcs.b	1$
4$	move.l	(n_MsgHeaderfiles,MainBase),a2
	moveq.l	#0,d2
3$	move.l	(a2)+,d1
	beq.b	7$
	jsrlib	Close
7$	addq.l	#1,d2
	cmp.w	(Maxconferences+CStr,MainBase),d2
	bcs.b	3$

	move.l	(n_MsgTextfiles,MainBase),a2
	moveq.l	#0,d2
5$	move.l	(a2)+,d1
	beq.b	8$
	jsrlib	Close
8$	addq.l	#1,d2
	cmp.w	(Maxconferences+CStr,MainBase),d2
	bcs.b	5$
9$	move.l	exebase,a6
	pop	d2/a2
	setz
	rts

readflfiles
	push	a2/d3/a3/d2/d4
	moveq.l	#0,d0
	move.l	#mem_Fileentry_SIZEOF*100,d1
	move.l	d1,d2
	move.l	exebase,a6
	jsr	_AsmCreatePool
	move.l	dosbase,a6
	lea	noflpoolmemtext,a1
	move.l	a0,(flpool,MainBase)
	beq.b	4$			; error, no pool

	move.l	(n_Filedirfiles,MainBase),a2
	moveq.l	#0,d3			; dir nr
	move.l	(firstFileDirRecord+CStr,MainBase),a3
	lea	(n_DirName,a3),a3
1$	cmp.w	(ActiveDirs+CStr,MainBase),d3
	bcc.b	3$			; ferdig
	tst.b	(a3)			; er det en file dir her ?
	bne.b	2$			; ja..
	moveq.l	#0,d0
	move.l	d0,(a2)+		; Sier at denne fila er tom..
	lea	(FileDirRecord_SIZEOF,a3),a3	; peker til neste navn
	bra.b	1$

2$	move.l	a3,a0
	bsr	createdirfilepath	; lager i txtbuffer
	move.l	d0,d1
	move.l	d1,d4
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	IFD	CreateMissingFiles
	tst.l	d0
	bne.b	1234$			; not error
	move.l	d4,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
1234$
	ENDC
	lea	(erroropentext),a0
	tst.l	d0
	beq.b	5$			; error
	bsr	readflfile		; fila lukkes her inne..
	lea	(errorreadfitext),a0
	beq.b	5$			; error
	addq.l	#1,d3
	lea	(FileDirRecord_SIZEOF,a3),a3	; peker til neste navn
	move.l	d0,(a2)+		; lagrer pekeren til første fileentry
	bne.b	1$

5$	bsr	writemainerror
	move.l	d4,a1
4$	move.l	a1,a0			; error
	bsr	writemainerror
	setz
	bra.b	9$

3$	clrz
9$	pop	a2/d3/a3/d2/d4
	rts

; d0 = filehandle
readflfile
	push	d2-d7/a2/a3/a4
	move.l	d0,d5
	move.l	#fileentryheader_sizeof,d6
	moveq.l	#-1,d7			; fil filnr
	suba.l	a3,a3			; vi har ikke noen forige enda..

	move.l	(flpool,MainBase),a0
	move.l	d6,d0
	move.l	exebase,a6
	jsr	_AsmAllocPooled
	tst.l	d0
	beq	7$			; ikke noe ram til hash.
	move.l	d0,a4			; dir start
	move.l	d0,a0			; null stiller
	move.l	d6,d0
	jsr	memclr

	move.l	(flpool,MainBase),a0
	moveq.l	#mem_Fileentry_SIZEOF,d0
	jsr	_AsmAllocPooled
	move.l	dosbase,a6
	tst.l	d0
	beq	7$
	move.l	d0,a2			; og som forrige
	moveq.l	#-1,d6			; filnr (i mem)

1$	moveq.l	#0,d1
	jsrlib	SetIoErr
	move.l	d5,d1
	move.l	a2,d2			; buffer
	move.l	#Fileentry_SIZEOF,d3
	moveq.l	#1,d4
	jsrlib	FRead
	tst.l	d0
	beq.b	8$
	addq.l	#1,d7			; øker fil filnr

	move.w	(Filestatus,a2),d0
	and.w	#FILESTATUSF_Filemoved|FILESTATUSF_Fileremoved,d0
	bne.b	1$			; denne var slettet... Hopper over

	addq.l	#1,d6			; øker mem filnr
	move.l	d6,(mem_filenr,a2)	; lagrer mem filnr
	move.l	d7,(mem_filefilenr,a2)	; lagrer file filnr
	moveq.l	#0,d0
	move.l	d0,(mem_fnexthash,a2)	; sletter hash peker (ligger trash der)
	move.l	d0,(mem_fnext,a2)	; sletter neste fil peker (trash..)

	lea	(Filename,a2),a0	; legg inn i hash liste
	bsr	calchash
	move.l	a2,a0
	move.l	a4,a1
	bsr	insertinhashchain

	move.l	a3,d0
	bne.b	2$
	move.l	a0,(first_file,a4)	; lagrer første fileentry
	bra.b	3$
2$	move.l	a2,(mem_fnext,a3)	; linker den forrige inn i den før der igjen
3$	move.l	(flpool,MainBase),a0	; allokerer neste entry
	moveq.l	#mem_Fileentry_SIZEOF,d0
	move.l	exebase,a6
	jsr	_AsmAllocPooled
	move.l	dosbase,a6
	tst.l	d0
	beq.b	7$			; error..
	move.l	a2,a3			; husker siste
	move.l	d0,a2
	bra.b	1$

8$	move.l	(flpool,MainBase),a0	; frigir siste allokerte
	moveq.l	#mem_Fileentry_SIZEOF,d0
	move.l	a2,a1
	move.l	exebase,a6
	jsr	_AsmFreePooled
	move.l	dosbase,a6
	jsrlib	IoErr			; var det fil error ?
	tst.l	d0
	beq.b	9$			; Nei, videre

7$	suba.l	a4,a4			; returnerer null
9$	move.l	dosbase,a6
	move.l	d5,d1
	jsrlib	Close
	move.l	a4,d0			; peker til hash + returnerer Z bit'et
	pop	d2-d7/a2/a3/a4
	rts

closeflfiles
	push	a2/a3/d2-d7/a6
	move.l	(n_Filedirfiles,MainBase),a2
	move.l	(firstFileDirRecord+CStr,MainBase),a3
	lea	(n_DirName,a3),a3
	move.l	#Fileentry_SIZEOF,d3
	moveq.l	#0,d5
1$	move.l	(a2)+,d0		; har vi hash struct ?
	beq	2$			; nei, videre
	move.l	d0,a0			; henter hash
	move.l	(first_file,a0),d7	; har vi filer ?
	beq.b	2$			; nei, gå videre

	move.l	d7,d1			; søker for å se om vi må lagre
8$	move.l	d1,a0
	move.w	(mem_fentry+Filestatus,a0),d0
	and.w	#FILESTATUSF_Filemoved+FILESTATUSF_Fileremoved,d0
	bne.b	10$			; denne er slettet, vi må lagre
	move.l	(mem_fnext,a0),d1	; mere ?
	bne.b	8$			; ja
	bra.b	2$			; vi trenger ikke lagre denne

10$	move.l	a3,a0			; lagrer ny .fl fil
	bsr	createdirfilepath	; lager i txtbuffer
	move.l	d0,d1
	move.l	#MODE_NEWFILE,d2
	jsrlib	Open
	lea	(erroropentext),a0
	move.l	d0,d6
	beq.b	5$			; error
	moveq.l	#1,d4

3$	move.l	d7,a0
	move.w	(mem_fentry+Filestatus,a0),d0
	and.w	#FILESTATUSF_Filemoved+FILESTATUSF_Fileremoved,d0
	bne.b	7$			; denne er slettet, ikke save denne
	move.l	d6,d1
	move.l	d7,d2			; buf
	jsrlib	FWrite
	cmp.l	d4,d0
	bne.b	4$
	move.l	d7,a0
7$	move.l	(mem_fnext,a0),d7	; mere ?
	bne.b	3$			; ja
6$	move.l	d6,d1
	jsrlib	Close
	bra.b	2$
4$	lea	(errorwritfitext),a0
5$	bsr	writemainerror
	lea	(txtbuffer,MainBase),a0	; Filnavn
	bsr	writemainerror
	lea	(nltext),a0
	bsr	writemainerror
	bra.b	6$

2$	lea	(FileDirRecord_SIZEOF,a3),a3	; peker til neste navn
	addq.l	#1,d5
	cmp.w	(MaxfileDirs+CStr,MainBase),d5
	bcs	1$
	move.l	(flpool,MainBase),d0
	beq.b	9$
	move.l	d0,a0
	move.l	exebase,a6
	jsr	_AsmDeletePool
9$	pop	a2/a3/d2-d7/a6
	rts

; a0 = navn
; a1 = hashstruct
; ret : z = 1 => not found
findflentry
	push	a2/a3
	move.l	a0,a2
	move.l	a1,a3
	bsr	calchash
	lsl.l	#2,d0
	move.l	(0,a3,d0.l),d0
	beq.b	9$			; ikke funnet
2$	move.l	d0,a3
	move.w	(mem_fentry+Filestatus,a3),d0
	and.w	#FILESTATUSF_Filemoved+FILESTATUSF_Fileremoved,d0
	bne.b	3$			; denne er slettet, ikke sjekk denne
	lea	(Filename,a3),a1
	move.l	a2,a0
	bsr	comparestringsicase
	beq.b	1$
3$	move.l	(mem_fnexthash,a3),d0
	bne.b	2$
	bra.b	9$			; ikke funnet
1$	move.l	a3,a0
	clrz
9$	pop	a2/a3
	rts


; d0 = nr
; a0 = hashstruct
; ret : n = 1 > EOF, z = 1 > not found
findflentrynr
	move.l	(first_file,a0),d1
	beq.b	3$			; EOF
1$	move.l	d1,a0
	subq.l	#1,d0
	bcs.b	2$
	move.l	(mem_fnext,a0),d1
	bne.b	1$			; still more files
3$	setn				; EOF
	bra.b	9$
2$	clrzn				; funnet
9$	rts

; d0 = hashval
; a0 = entry
; a1 = table
insertinhashchain
	lsl.l	#2,d0			; * 4
	move.l	(0,a1,d0.l),d1
	bne.b	1$			; plassen opptatt
	move.l	a0,(0,a1,d0.l)
	bra.b	9$
1$	move.l	d1,a1			; finner slutten
	move.l	(mem_fnexthash,a1),d1
	bne.b	1$
	move.l	a0,(mem_fnexthash,a1)	; legger inn
9$	rts

;a0 = entry
;a1 = hashstruct
;d0 = hash for old name
rehashentry
	push	a2/a3
	move.l	a0,a2
	move.l	a1,a3
; fjern gammel...

	lsl.l	#2,d0			; * 4
	move.l	(0,a1,d0.l),d1		; adressen til første i hash kjeden
	beq.b	3$			; finnes ikke. Egentlig umulig, men ...
	cmp.l	d1,a2			; riktig ?
	bne.b	1$
	moveq.l	#0,d1			; sletter i selve tabellen
	move.l	d1,(0,a1,d0.l)
	bra.b	3$			; ferdig

1$	move.l	d1,a1
	move.l	(mem_fnexthash,a1),d1
	beq.b	3$			; egentlig umulig, men ..
	cmp.l	d1,a2			; riktig ?
	bne.b	1$			; nei, fortsetter
	move.l	(mem_fnexthash,a2),(mem_fnexthash,a1)	; unlink'er
	moveq.l	#0,d0
	move.l	d0,(mem_fnexthash,a2)	; unlinker helt..

3$	lea	mem_fentry+Filename(a2),a0
	bsr	calchash
	move.l	a2,a0
	move.l	a3,a1
	bsr	insertinhashchain
9$	pop	a2/a3
	rts

; a0 = string
; ret : d0 = hash, modulo 72
calchash
	push	a2/d2/d3/d4
	move.l	a0,a2				; husker stringen
	jsr	(strlen)
	move.l	d0,d2				; val
	move.l	d0,d3				; len
	moveq.l	#0,d4				; i
	bra.b	1$
2$	moveq.l	#0,d0
	move.b	(a2)+,d0
	jsr	upchar
	move.l	d2,d1				; val = (val*13 + upchar (*string++)) & $7ff
	asl.l	#3,d1
	sub.l	d2,d1
	add.l	d1,d1
	sub.l	d2,d1
	add.l	d0,d1
	move.l	d1,d2
	andi.l	#$7ff,d2
	addq.l	#1,d4
1$	cmp.l	d3,d4				; len > i
	blt.b	2$				; nope
	divu	#72,d2
	clr.w	d2
	swap	d2
	move.l	d2,d0
	pop	a2/d2/d3/d4
	rts

loadconfigs
	movem.l	d2-d4,-(a7)
	move.l	dosbase,a6
	move.l	#configfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq	2$
	move.l	d4,d1
	lea	(CStr,MainBase),a0
	move.l	a0,d2
	move.l	(Configsize,a0),d3	; Configsize må altså være riktig før lesing ..
	jsrlib	Read
	move.l	d4,d1
	move.l	d0,d4
	jsrlib	Close
	cmp.l	d3,d4
	bne	2$			; read error
	addq.w	#1,lesconfigstatus

	lea	(staticConfigRecord_SIZEOF+CStr,MainBase),a0 ; slutten av static config
	move.w	(Maxconferences+CStr,MainBase),d0
	mulu	#ConferenceRecord_SIZEOF,d0
	add.l	d0,a0
	move.l	a0,(firstFileDirRecord+CStr,MainBase)

	move.w	(MaxfileDirs+CStr,MainBase),d0
	mulu	#FileDirRecord_SIZEOF,d0
	add.l	d0,a0
	move.l	a0,(n_Filedirfiles,MainBase)

	moveq.l	#0,d0
	move.w	(MaxfileDirs+CStr,MainBase),d0
	lsl.l	#2,d0
	add.l	d0,a0
	move.l	a0,(n_MsgHeaderfiles,MainBase)
	moveq.l	#0,d0
	move.w	(Maxconferences+CStr,MainBase),d0
	lsl.l	#2,d0
	add.l	d0,a0
	move.l	a0,(n_MsgTextfiles,MainBase)

	move.l	#nrindexfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	1$
	move.l	d4,d1
	move.l	NrTabelladr(MainBase),a0
	move.l	a0,d2
	move.l	LogTabelladr(MainBase),d3
	sub.l	a0,d3			; Beregner plassen vi har til rådighet
	jsrlib	Read
	move.l	d4,d1
	move.l	d0,d4
	jsrlib	Close
	moveq.l	#-1,d0
	cmp.l	d0,d4
	beq.b	1$			; read error
	addq.w	#1,lesconfigstatus

	move.l	#indexfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	1$
	move.l	d4,d1
	move.l	LogTabelladr(MainBase),a0
	move.l	a0,d2
	lsr.l	#2,d3
;	move.l	(MaxUsers+CStr,MainBase),d3
	mulu	#Log_entry_SIZEOF,d3
	jsrlib	Read
	move.l	d4,d1
	move.l	d0,d4
	jsrlib	Close
	moveq.l	#-1,d0
	cmp.l	d0,d4
	beq.b	1$			; read error
	addq.w	#1,lesconfigstatus
	move.l	exebase,a6
	clrz
	bra.b	9$
1$	move.l	exebase,a6
	setz
	bra.b	9$
2$	move.l	exebase,a6
	setn
9$	movem.l	(a7)+,d2-d4
	rts

gettooltypes
	push	a2/a6
	move.l	icobase,a6
	lea	abbsinfoname,a0		; name
	jsrlib	GetDiskObject
	move.l	d0,maindiskobj
	beq	8$			; ikke noe icon
	move.l	d0,a0
	move.l	(do_ToolTypes,a0),a2	; har tooltypes array'en

	move.l	icobase,a6
	move.l	a2,a0
	lea	(pritooltype),a1
	jsrlib	FindToolType
	tst.l	d0			; fant vi noe ?
	beq.b	1$			; nei
	move.l	d0,a0
	bsr	10$
	bmi.b	1$			; ikke noe tall
	move.b	d0,brokerpri

1$	move.l	a2,a0
	lea	(popuptooltype),a1
	jsrlib	FindToolType
	tst.l	d0			; fant vi noe ?
	beq.b	2$			; nei
	move.l	d0,a0
	lea	(notext),a1
	jsrlib	MatchToolValue
	tst.l	d0
	beq.b	2$			; Vi fant ikke no i popup
	bset	#0,configbyte		; ikke pop up

2$	lea	(appicontooltype),a1
	move.l	a2,a0
	jsrlib	FindToolType
	tst.l	d0			; fant vi noe ?
	beq.b	3$			; nei
	move.l	d0,a0
	lea	(falsetext),a1
	jsrlib	MatchToolValue
	tst.l	d0
	beq.b	3$			; Vi fant ikke false
	bset	#1,configbyte		; ikke appicon

3$	lea	(winlefttooltype),a1
	move.l	a2,a0
	jsrlib	FindToolType
	tst.l	d0			; fant vi noe ?
	beq.b	4$			; nei
	move.l	d0,a0
	bsr.b	10$
	bmi.b	4$			; ikke noe tall
	move.w	d0,ABBSAppWindowLeft

4$	lea	(wintoptooltype),a1
	move.l	a2,a0
	jsrlib	FindToolType
	tst.l	d0			; fant vi noe ?
	beq.b	5$			; nei
	move.l	d0,a0
	bsr.b	10$
	bmi.b	5$			; ikke noe tall
	move.w	d0,ABBSAppWindowTop

5$	lea	(popkeytooltype),a1
	move.l	a2,a0
	jsrlib	FindToolType
	tst.l	d0			; fant vi noe ?
	beq.b	9$			; nei
	move.l	d0,brokerhotkey
	bra.b	9$
8$	lea	(nodiskicontext),a0
	bsr	writemainerror
	setz
9$	pop	a2/a6
	rts

10$	cmp.b	#'-',(a0)
	bne.b	11$
	addq.l	#1,a0
	jsr	(atoi)
	bmi	19$			; ikke noe tall
	neg.l	d0
	clrn
	bra.b	19$
11$	jsr	(atoi)
19$	rts

setupappicon
	push	a2-a4/a6
	btst	#1,configbyte
	bne.b	9$			; skal ikke ha appicon
	move.l	maindiskobj,d0
	beq.b	9$			; no object
	move.l	d0,a3			; diskobj
	move.l	wbbase,a6
	moveq.l	#0,d0			; ID
	moveq.l	#0,d1			; Userdata
	lea	abbsappicontext,a0
	move.l	wbmsgport,a1
	suba.l	a2,a2			; lock
	suba.l	a4,a4			; Tags
	jsrlib	AddAppIconA
	move.l	d0,mainappicon
	bne.b	9$
	bsr	clearappicon
8$	lea	(noicontext),a0
	bsr	writemainerror
	setz
9$	pop	a2-a4/a6
	rts

clearappicon
	move.l	mainappicon,d0
	beq.b	1$
	move.l	wbbase,a6
	move.l	d0,a0
	jsrlib	RemoveAppIcon
1$	move.l	maindiskobj,d0
	beq.b	9$
	move.l	icobase,a6
	move.l	d0,a0
	jsrlib	FreeDiskObject
	moveq.l	#0,d0
	move.l	d0,maindiskobj
9$	move.l	exebase,a6
	bsr	closestatuswindow
	rts

EVT_HOTKEY EQU	1

handlecommodity
	push	a2/d2/d3
0$	move.l	brokermsgport,a0
	jsrlib	GetMsg
	tst.l	d0
	beq	9$
	move.l	d0,a2
	move.l	a2,a0
	move.l	combase,a6
	jsrlib	CxMsgType
	move.l	d0,d2				; husker typen
	move.l	a2,a0
	jsrlib	CxMsgID
	move.l	d0,d3				; husker id
	move.l	exebase,a6
	move.l	a2,a1
	tst.l	(MN_REPLYPORT,a1)
	beq	1$
	jsrlib	ReplyMsg
1$	cmp.w	#CXM_COMMAND,d2
	bne.b	4$				; ikke command
	cmp.w	#CXCMD_APPEAR,d3
	bne.b	2$
5$	move.b	statusopen,d0
	bne.b	0$				; allerede åpent
	bsr	openstatuswindow
	bra.b	0$
2$	cmp.w	#CXCMD_DISAPPEAR,d3
	bne.b	3$
	move.b	statusopen,d0
	beq.b	0$				; allerede lukket
	bsr	closestatuswindow
	bra.b	0$

3$	cmp.w	#CXCMD_KILL,d3
	bne.b	0$
	move.w	MainBits(MainBase),d0		; er vi locked ?
	and.w	#MainBitsF_ABBSLocked,d0
	bne.b	8$				; ja, nekte
	move.w	Nodes(MainBase),d0
	bne.b	8$				; kan ikke
	move.w	#1,mainshutdown
	bra	0$

4$	cmp.w	#CXM_IEVENT,d2
	bne	0$				; ikke event
	cmp.w	#EVT_HOTKEY,d3
	bne	0$				; ikke hotkey
	bra.b	5$				; det var hotkey. Opp med vinduet.

8$	move.l	intbase,a6
	suba.l	a0,a0				; nei, blinker vinduet.
	jsrlib	DisplayBeep
	move.l	exebase,a6
	bra	0$
9$	pop	a2/d2/d3
	rts

setupcommodity
	moveq.l	#0,d0
	move.l	d0,a0
	bsr	CreatePort
	move.l	d0,brokermsgport
	beq	9$
	lea	(brokerstruct),a0
	moveq.l	#0,d0
	move.l	combase,a6
	jsrlib	CxBroker
	move.l	d0,broker
	bne.b	1$
2$	move.l	exebase,a6
	bsr	clearcommodity
	setz
	bra	9$
1$	move.l	#CX_FILTER,d0
	move.l	brokerhotkey,a0
	suba.l	a1,a1
	jsrlib	CreateCxObj
	move.l	d0,brokerfilter
	beq.b	2$
	move.l	broker,a0
	move.l	d0,a1
	jsrlib	AttachCxObj
	move.l	#CX_SEND,d0
	move.l	brokermsgport,a0
	move.l	#EVT_HOTKEY,a1
	jsrlib	CreateCxObj
	tst.l	d0
	beq.b	2$
	move.l	brokerfilter,a0
	move.l	d0,a1
	jsrlib	AttachCxObj

	move.l	#CX_TRANSLATE,d0
	suba.l	a1,a1
	suba.l	a0,a0
	jsrlib	CreateCxObj
	tst.l	d0
	beq.b	2$
	move.l	brokerfilter,a0
	move.l	d0,a1
	jsrlib	AttachCxObj

	move.l	brokerfilter,a0
	jsrlib	CxObjError
	tst.l	d0
	bne	2$

	move.l	broker,a0
	moveq.l	#1,d0
	jsrlib	ActivateCxObj
	move.l	exebase,a6
	move.l	brokermsgport,a0
	moveq.l	#0,d0
	move.b	(MP_SIGBIT,A0),d1
	bset	d1,d0
	or.l	d0,mainwait
	move.l	d0,maincommisigbit
;	clrz
9$	rts

clearcommodity
	move.l	broker,d0
	beq.b	1$
	move.l	combase,a6
	move.l	d0,a0
	jsrlib	DeleteCxObjAll
	move.l	exebase,a6
	moveq.l	#0,d0
	move.l	d0,broker
1$	move.l	brokermsgport,d0
	beq.b	2$
	move.l	d0,a0
	bsr	DeletePort
	moveq.l	#0,d0
	move.l	d0,brokermsgport
2$
	rts

******************************
;Mainsetup
; open libs,screen,mainwindow.
; open mainport,set mainmenu
; returns Z bit. Z = 0 : Success
******************************

mainsetup
	move.w	AttnFlags(a6),Environment+2	; save copy for dump
	move.l	a6,exebase
	openlib	dos
	cmp.w	#36,LIB_VERSION(a6)	; Kjører vi på noe bedre enn 1.3 ?
	bcc.b	5$			; Jepp. Kjører.
	lea	need2.0text,a0
	bsr	writemainerror
	bra	no_dos
5$	lea	mainmsgportname,a1	; sjekker om abbs er kjørt før
	jsrlib	FindPort
	tst.l	d0
	bne	is_runi			; ja .. Da avslutter vi
	openlib	int
	openlib	gfx
	openlib	wb
	openlib	ico
	openlib	gad
	openlib	com
	openlib	dfo
	IFND DEMO
	openlib	zxp			; xprZmodem
	openlib	yxp			; xprYmodem
	move.l	yxpbase,d0
	move.l	d0,yxpbase1		; xprYmodem batch
	move.l	d0,yxpbase2		; xprYmodem-G
	move.l	d0,xxpbase		; xprXmodem
	move.l	d0,xxpbase1		; xprXmodemCRC
	ENDC
	openlib	rex
	openlib	uti

	moveq.l	#0,d0
	lea	aslname,a1
	jsrlib	OpenLibrary
	move.l	d0,aslbase

	moveq.l	#0,d0
	lea	fifoname,a1
	jsrlib	OpenLibrary
	move.l	d0,fifobase

	moveq.l	#0,d0
	lea	iffname,a1
	jsrlib	OpenLibrary
	move.l	d0,iffbase

	move.l	dosbase,a6
	move.l	#abbsrootname,d1
	push	d2
	moveq.l	#ACCESS_READ,d2
	jsrlib	Lock
	pop	d2
	move.l	d0,d1
	beq	no_root
	jsrlib	CurrentDir
	move.l	d0,MainOldDir
	move.l	exebase,a6

	bsr	getconfigfilesize
	lea	(noconfigfiltext),a0
	beq	3$
	add.l	#StaticMainmemory_SIZEOF,d0		; allokerer minne
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	push	d0
	jsrlib	AllocMem
	pop	d1
	move.l	d0,mainmemoryblock
	beq	0$
	move.l	d0,MainBase
	move.l	d1,(MainmemoryAlloc,MainBase)
	lea	configfilename,a0		; leser inn config
	lea	(CStr,MainBase),a1
	move.l	#staticConfigRecord_SIZEOF,d0
	bsr	readinfile
; vi er ikke så interesert i error her..

	move.l	(MaxUsers+CStr,MainBase),d0
	moveq.l	#100,d1				; sørger for at min er 100
	cmp.l	d1,d0
	bcc.b	61$
	move.l	d1,d0
61$	moveq.l	#30,d1				; og setter av plass til 30 flere
	add.l	d1,d0				; d0 er nå antall indexer vi skal ha
	move.l	d0,(MaxNumLogEntries,MainBase)
	moveq.l	#Log_entry_SIZEOF+4,d1
	mulu	d1,d0				; har nå minne i bytes
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	jsrlib	AllocMem
	move.l	d0,(NrTabelladr,MainBase)
	beq	7$
	move.l	(MaxNumLogEntries,MainBase),d1
	lsl.l	#2,d1
	add.l	d1,d0
	move.l	d0,(LogTabelladr,MainBase)

	sub.l	a1,a1
	jsrlib	FindTask
	move.l	d0,MainTask
	move.l	d0,a1
	moveq.l	#-1,d0
	move.l	d0,pr_WindowPtr(a1)		; Fjerner alle requestere
	move.l	TC_TRAPCODE(a1),d0		; check current exception
	move.l	a1,-(a7)
	move.l	d0,a1
	jsrlib	TypeOfMem
	move.l	(a7)+,a1
	IFD	exceptionhandler
	tst.l	d0				; Er det null ? dvs ROM eller ingenting
	bne.b	6$				; somebody else (debugger?) has vector
	move.l	#Exception,TC_TRAPCODE(a1)	; install pointers to code
	move.l	MainBase,TC_TRAPDATA(a1)	; ...and data
	ENDC

6$	or.w	#MainBitsF_SysopNotAvail,MainBits(MainBase)	; setter sysop not avail
	move.l	exebase,a6
	jsrlib	CreateMsgPort
	move.l	d0,wbmsgport
	beq	41$
	move.l	d0,a0
	moveq.l	#0,d0
	move.b	MP_SIGBIT(A0),d1
	bset	d1,d0
	bset	#SIGBREAKB_CTRL_C,d0
	or.l	d0,mainwait
	move.l	d0,wbportsigbit
	lea	mainmsgportname,a0
	moveq.l	#0,d0
	bsr	CreatePort
	move.l	d0,mainmsgport
	beq	4$
	move.l	d0,a0
	moveq.l	#0,d0
	move.b	MP_SIGBIT(A0),d1
	bset	d1,d0
	or.l	d0,mainwait
	move.l	d0,mainportsigbit
	bsr	readkeys
	clrz
	rts

7$	lea	noindexmemtext,a0
	bsr	writemainerror
	bra	no_indx
0$	lea	nomainmemtext,a0
3$	bsr	writemainerror
	bra	no_main
4$	lea	nomainporttext,a0
	bsr	writemainerror
	bra	no_mpor
41$	lea	nowbporttext,a0
	bsr	writemainerror
	bra	no_wpor

******************************
;mainclosedown
;close libs,screen, mainwindow.
;close mainport, clear menu
******************************

mainclosedown
	move.l	keyfile(MainBase),d0	; har vi keyfile ?
	beq.b	1$
	move.l	d0,a1
	move.l	(a1),d0
	jsrlib	FreeMem
1$	move.l	wbmsgport,a0
	bsr	DeletePort
no_wpor	move.l	mainmsgport,a0
	bsr	DeletePort
no_mpor	move.l	(MaxNumLogEntries,MainBase),d0
	moveq.l	#Log_entry_SIZEOF+4,d1
	mulu	d1,d0				; har nå minne i bytes
	move.l	(NrTabelladr,MainBase),a1
	jsrlib	FreeMem
no_indx	move.l	mainmemoryblock,a1
	move.l	(MainmemoryAlloc,MainBase),d0
	jsrlib	FreeMem
no_main	move.l	dosbase,a6
	move.l	MainOldDir,d1
	jsrlib	CurrentDir
	move.l	d0,d1
	jsrlib	UnLock
no_root	move.l	exebase,a6
	move.l	iffbase,d0
	beq.b	4$
	move.l	d0,a1
	jsrlib	CloseLibrary
4$	move.l	fifobase,d0
	beq.b	3$
	move.l	d0,a1
	jsrlib	CloseLibrary
3$	move.l	aslbase,d0
	beq.b	2$
	move.l	d0,a1
	jsrlib	CloseLibrary
2$	closlib	uti
no_uti1	closlib	rex
no_rex1
	IFND DEMO
	closlib	yxp
no_yxp1	closlib	zxp
no_zxp1
	ENDC
	closlib	dfo
no_dfo1	closlib	com
no_com1	closlib	gad
no_gad1	closlib	ico
no_ico1	closlib	wb
no_wb1	closlib	gfx
no_gfx1	closlib	int
no_int1	closlib	dos
no_dos	setz		; Can't write anything without dos.library
	rts

no_rex	lea	norexlibtext,a0
	bsr	writemainerror
	bra	no_uti1
no_uti	lea	noutilibtext,a0
	bsr	writemainerror
	bra	no_uti1
	IFND DEMO
no_yxp	lea	noyxplibtext,a0
	bsr	writemainerror
	bra	no_yxp1
no_zxp	lea	nozxplibtext,a0
	bsr	writemainerror
	bra	no_zxp1
	ENDC
no_com	lea	nocomlibtext,a0
	bsr	writemainerror
	bra	no_com1
no_gad	lea	nogadlibtext,a0
	bsr	writemainerror
	bra	no_gad1
no_ico	lea	noicolibtext,a0
	bsr	writemainerror
	bra	no_ico1
no_wb	lea	nowblibtext,a0
	bsr	writemainerror
	bra	no_wb1
no_dfo	lea	nodfolibtext,a0
	bsr	writemainerror
	bra	no_dfo1
no_gfx	lea	nogfxlibtext,a0
	bsr	writemainerror
	bra	no_gfx1
no_int	lea	nointlibtext,a0
	bsr	writemainerror
	bra	no_int1
is_runi	lea	alreadyrunitext,a0
	bsr	writemainerror
	bra	no_int1

getconfigfilesize
	link.w	a3,#-20
	lea	configfilename,a0		; leser inn config
	move.l	sp,a1
	moveq.l	#Users,d0			; vi skal lese size + max#?
	bsr	readinfile
	beq.b	9$				; en eller annen feil
	move.w	(Revision,sp),d0
	cmp.w	#ConfigRev,d0
	notz
	beq.b	9$				; feil revision
	move.l	(Configsize,sp),d0
	moveq.l	#0,d1
	move.w	(MaxfileDirs,sp),d1		; for n_Filedirfiles
	lsl.l	#2,d1				; * 4
	add.l	d1,d0
	moveq.l	#0,d1
	move.w	(Maxconferences,sp),d1
	lsl.l	#3,d1				; * 4 * 2
	add.l	d1,d0
9$	unlk	a3
	rts

setupmenu
	push	a6
	move.l	(gadbase),a6
	movea.l	(mainscreenadr),a0
	suba.l	a1,a1
	jsrlib	GetVisualInfoA
	move.l	d0,mainvisualinfo
	beq.b	9$
	lea.l	(Project0NewMenu0),a0
	lea	(createmenutags),a1
	move.b	(Cflags+CStr,MainBase),d1
	btst	#CflagsB_8Col,d1
	bne.b	1$
	move.l	#1,(4,a1)
1$	jsrlib	CreateMenusA
	move.l	d0,mainmenustruct
	beq.b	freemenu2
	move.l	d0,a0
	push	a2
	lea	(MenuTags),a2
	movea.l	mainvisualinfo,a1
	jsrlib	LayoutMenusA
	pop	a2
	tst.l	d0
	beq.b	freemenu1
9$	pop	a6
	rts

freemenu
	push	a6
	move.l	(gadbase),a6
freemenu1
	movea.l	mainmenustruct,a0
	jsrlib	FreeMenus
freemenu2
	movea.l	mainvisualinfo,a0
	jsrlib	FreeVisualInfo
	pop	a6
	setz
	rts

testseekerror
	push	d0
	jsrlib	IoErr
	tst.l	d0
	pop	d0
	rts

readkeys
	push	d2-d4/a6/a2
	move.l	dosbase,a6
	move.l	#keyfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	9$
	move.l	d4,d1			; finds size of file
	moveq.l	#0,d2
	moveq.l	#OFFSET_END,d3
	jsrlib	Seek
	bsr	testseekerror
	bne.b	8$				; error
	move.l	d4,d1
	moveq.l	#0,d2
	moveq.l	#OFFSET_BEGINNING,d3
	jsrlib	Seek
	bsr	testseekerror
	bne.b	8$				; error
	addq.l	#5,d0			; plass til size, og en 0 byte på slutten
	move.l	d0,d3
	move.l	exebase,a6
	move.l	#MEMF_CLEAR,d1
	jsrlib	AllocMem
	move.l	dosbase,a6
	tst.l	d0
	beq.b	8$
	move.l	d0,a2
	move.l	d3,(a2)			; lagrer size
	move.l	a2,keyfile(MainBase)	; lagrer bufferen
	lea	4(a2),a2
	move.l	d4,d1
	move.l	a2,d2
	jsrlib	Read
	moveq.l	#-1,d1
	cmp.l	d0,d1
	beq.b	8$
	bsr	10$
8$	move.l	d4,d1
	jsrlib	Close
9$	pop	d2-d4/a6/a2
	rts

10$	lea	keys(MainBase),a1
	moveq.l	#10,d1			; maks antall key's
12$	move.l	a2,(a1)+
11$	move.b	(a2)+,d0
	beq.b	19$
	cmp.b	#10,d0
	bne.b	11$
	move.b	#0,-1(a2)
	subq.l	#1,d1
	bne.b	12$			; det er flere igjen
19$	rts

******************************
;writemainerror
;inputs : text (a0)
******************************
writemainerror
	move.l	dosbase,d0
	beq.b	9$		; dos.library hasn't been opened yet.No can do
	move.l	a0,-(sp)	; save pointer to Text
	move.l	d0,a6
	jsrlib	Output
	move.l	d0,d1		; Output file.
	move.l	(sp)+,d2	; Get text
	move.l	d2,a0		; Get Strlen.
	moveq.l	#-1,d3
1$	tst.b	(a0)+
	dbeq	d3,1$
	not.w	d3
	ext.l	d3		; D3 = Strlen.
	jsrlib	Write		; .. and write the text.
	move.l	exebase,a6		; Get Execbase (back)
9$	rts

readcolors
	push	d2-d4
	move.l	dosbase,a6
	move.l	#colorfilename,d1
	move.l	#MODE_OLDFILE,d2
	jsrlib	Open
	move.l	d0,d4
	beq.b	9$
	move.l	d0,d1
	move.l	#screencolors,d2
	moveq.l	#2*2+2*8,d3
	jsrlib	Read
	move.l	d4,d1
	jsrlib	Close
9$	move.l	exebase,a6
	pop	d2-d4
	rts

***************************************************************************
***				DATA					***
***************************************************************************

	section bdata,BSS

dosbase		ds.l	1
intbase		ds.l	1
wbbase		ds.l	1
icobase		ds.l	1
exebase		ds.l	1
gfxbase		ds.l	1
dfobase		ds.l	1
aslbase		ds.l	1
gadbase		ds.l	1
combase		ds.l	1
rexbase		ds.l	1
utibase		ds.l	1
fifobase	ds.l	1

protokollbaser
zxpbase		ds.l	1
xxpbase		ds.l	1
xxpbase1	ds.l	1
yxpbase		ds.l	1
yxpbase1	ds.l	1
yxpbase2	ds.l	1
iffbase		ds.l	1

_SysBase = exebase
	XDEF	_SysBase

mainscreenadr	ds.l	1
mainwindowadr	ds.l	1
mainmsgport	ds.l	1
wbmsgport	ds.l	1
mainintuiport	ds.l	1
maingadtoolport	ds.l	1
mainwait	ds.l	1
mainintsigbit	ds.l	1
mainportsigbit	ds.l	1
maingadtosigbit	ds.l	1
maincommisigbit	ds.l	1
wbportsigbit	ds.l	1
mainstack	ds.l	1
MainOldDir	ds.l	1
mainmenustruct	ds.l	1
mainvisualinfo	ds.l	1
mainappicon	ds.l	1
maindiskobj	ds.l	1
wbmessage	ds.l	1
broker		ds.l	1
brokerfilter	ds.l	1
oldclicksecs	ds.l	1
oldclickmicros	ds.l	1

useonlyearly	equ	mainscreenadr


mainmemoryblock	ds.l	1

mainlesbuffer	ds.l	1
lesconfigstatus	ds.w	1
mainshutdown	ds.w	1
screenopencount	ds.w	1
statuswinheight	ds.w	1
statusopen	ds.b	1
configbyte	ds.b	1
closestatuswind	ds.b	1

		section data,data

msgportjumps
	dc.l	Loadsaveuser,Loadsaveuser,Createuser,Getusername,Getusernumber
	dc.l	Saveconfig,Startnode,Nodeshutdown,Savemsg,Loadmsg
	dc.l	CreateConference,Loadmsgheader,Loadmsgtext,Savemsgheader
	dc.l	Testconfig,Createbulletin,Clearbulletins,Createfiledir
	dc.l	Addfile,Findfile,Addfiledl,Loadfileentry,Savefileentry
	dc.l	BroadcastMsg,GetMaxConfDirs,Loadsaveusernr
	dc.l	Loadsaveusernr,ChangeName,DeleteDir,RenameDir
	dc.l	DeleteConference,RenameConference,SetAvailSysop
	dc.l	Loadsaveusernrnr,Loadsaveusernrnr,MatchName,CleanConference
	dc.l	QuitBBS,QuitBBS,QuitBBS,PackuserFile,openscreen,closescreen
	dc.l	RenameFileEntry,LockABBS,UnLockABBS,Getconfig

gadgetcmdtable
	dc.w	Node_Show,Node_Hide,Node_chat,Node_OffHook
	dc.w	Node_Eject,Node_Killuser,Node_TmpSysop
	dc.w	Node_ShowUser,Node_Shutdown,Node_chat		; really foo2 gadget
	dc.w	1,2,3,Node_InitModem,Node_ReleasePort,4		; Quitabbs,ReopenABBS,EjectAll


gadgetjmptable
	dc.l	main_closeabbs,main_opennode,main_ejectall,main_winsize

chartogadget	dc.b	'S','H',-1,'O','E',-1,-1,'O','U',-1,'Q','R','A','I','L',0

copyrighttext	dc.b	'ABBS II © 1997-2000 Jan Erik Olausen.',0

defhotkey	dc.b	'lalt lshift A',0
dosname		dc.b	'dos.library',0
intname		dc.b	'intuition.library',0
wbname		dc.b	'workbench.library',0
iconame		dc.b	'icon.library',0
gfxname		dc.b	'graphics.library',0
dfoname		dc.b	'diskfont.library',0
aslname		dc.b	'asl.library',0
gadname		dc.b	'gadtools.library',0
comname		dc.b	'commodities.library',0
rexname		dc.b	'rexxsyslib.library',0
zxpname		dc.b	'xprzmodem.library',0
yxpname		dc.b	'xprymodem.library',0
utiname		dc.b	'utility.library',0
iffname		dc.b	'iffparse.library',0
fifoname	FIFOLIBNAME

		even

activenode	dc.w	-1

Project0NewMenu0:
    DC.B    NM_TITLE,0
    DC.L    Project0MName0
    DC.L    0
    DC.W    0
    DC.L    0,0

Project0NewMenu1:
    DC.B    NM_ITEM,0
    DC.L    Project0MName1
    DC.L    Project0MComm1
    DC.W    0
    DC.L    0,0

Project0NewMenu2:
    DC.B    NM_TITLE,0
    DC.L    Project0MName2
    DC.L    0
    DC.W    0
    DC.L    0,0

Project0NewMenu3:
    DC.B    NM_ITEM,0
    DC.L    Project0MName3
    DC.L    Project0MComm3
    DC.W    CHECKIT!CHECKED!MENUTOGGLE
    DC.L    0,0

    DC.B    NM_END,0
    DC.L    0,0
    DC.W    0
    DC.L    0,0

Project0MName0:
    DC.B    'Project',0

Project0MName1:
    DC.B    'Quit',0

Project0MComm1:
    DC.B    'Q',0

Project0MName2:
    DC.B    'Sysop',0

Project0MName3:
    DC.B    'Not Availble',0

Project0MComm3:
    DC.B    'A',0

	even

nodelist
nhead	dc.l	ntail
ntail	dc.l	0		; tail
	dc.l	nhead
	dc.b	0,0

	CNOP	0,4
updatenodelisttags
	dc.l	GTLV_Labels,nodelist
	dc.l	TAG_DONE,0

;winsizetags
;	dc.l	GTCY_Active,1
;	dc.l	TAG_DONE,0

CreateNewProcTags
		dc.l	NP_Entry,0
		dc.l	NP_Name,0
		dc.l	NP_StackSize,4*4096
		dc.l	NP_Cli,1		; TRUE
		dc.l	TAG_DONE,0

NewScreenTags
ScreenDepth	dc.l	SA_Depth,1
		dc.l	SA_Width,STDSCREENWIDTH
		dc.l	SA_Height,STDSCREENHEIGHT


ScreenModes	dc.l	SA_DisplayID,HIRES_KEY
		dc.l	SA_Title,copyrighttext
;		dc.l	SA_Colors,colorspec
		dc.l	SA_SysFont,1
		dc.l	SA_PubName,pubscreenname
MainTask	EQU	*+4
		dc.l	SA_PubTask,0
		dc.l	SA_PubSig,SIGBREAKB_CTRL_F

	IFND	SA_Interleaved
SA_Interleaved	equ	$80000042
	ENDC
		dc.l	SA_Interleaved,1
ScreenPens	dc.l	SA_Pens,penlist
		dc.l	TAG_DONE

		IFND	SUPER72_MONITOR_ID
SUPER72_MONITOR_ID		EQU	$00081000
		ENDC

brokerstruct	dc.b	5,0		; NB_VERSION,0
		dc.l	abbstext,versionstr,copyrighttext
		dc.w	NBU_UNIQUE,COF_SHOW_HIDE
brokerpri	dc.b	0,0
brokermsgport	dc.l	0
brokerhotkey	dc.l	defhotkey
		dc.w	0

screencolors	dc.w	$aaa,$000
		dc.w	$000,$f00,$0c0,$ff0
		dc.w	$00d,$d0d,$0ff,$fff
;sort,rød,grøn, gul,blå,lilla,lblå,hvit

penlist2color	dc.w    1,0,1,1,1,0,1
		dc.w	0,1,1,0,0,-1
;DETAILPEN,BLOCKPEN,TEXTPEN,SHINEPEN,SHADOWPEN,FILLPEN,FILLTEXTPEN,
;BACKGROUNDPEN,HIGHLIGHTTEXTPEN,BARDETAILPEN,BARBLOCKPEN,BARTRIMPEN

penlist		dc.w    1,7,7,6,2,4,7
		dc.w	0,1,7,1,0,-1

;DETAILPEN,BLOCKPEN,TEXTPEN,SHINEPEN,SHADOWPEN,FILLPEN,FILLTEXTPEN,
;BACKGROUNDPEN,HIGHLIGHTTEXTPEN,BARDETAILPEN,BARBLOCKPEN,BARTRIMPEN

abbstext	dc.b	'ABBS',0
pubscreenname	dc.b	'ABBS Screen',0
mainmsgportname	dc.b	'ABBS mainport',0

abbsrootname	dc.b	'ABBS:',0
abbsinfoname	dc.b	'progdir:abbs',0
conferencepath	dc.b	'ABBS:Conferences/',0
fileheaderpath	dc.b	'ABBS:Fileheaders/',0
abbsappicontext	dc.b	'ABBS Appicon',0

configfilename	dc.b	'config/configfile',0
colorfilename	dc.b	'config/colorfile',0
userfilename	dc.b	'config/userfile',0
newuserfilename	dc.b	'config/userfile.new',0
indexfilename	dc.b	'config/userfile.index',0
nrindexfilename	dc.b	'config/userfile.nrindex',0
startupfilename	dc.b	'config/startup.config',0
keyfilename	dc.b	'config/abbs.keys',0
dotnewtext	dc.b	'.new',0
dotmessagestext	dc.b	'.m',0
dotmsgheadertxt	dc.b	'.h',0
dotfilelisttext	dc.b	'.fl',0

; hovedtask setup error meldinger
alreadyrunitext	dc.b	10,'ABBS is already running!',10,0
need2.0text	dc.b	'Need Kickstart 2.0 or better. UPGRADE *NOW*!',10,0
nostartfiletext	dc.b	10,'Can''t open startup file!',10,0
errstartfiltext	dc.b	10,'Error reading startup file!',10,0
nosetupmenutext	dc.b	10,'Can''t create main menu!',10,0
nomainmenutext	dc.b	10,'Can''t attach main menu!',10,0
nowbporttext	dc.b	10,'Can''t open wb message port!',10,0
nomainporttext	dc.b	10,'Can''t open main message port!',10,0
norexlibtext	dc.b	10,'Can''t open rexxsyslib.library!',10,0
noutilibtext	dc.b	10,'Can''t open utility.library!',10,0
nozxplibtext	dc.b	10,'Can''t open xprzmodem.library!',10,0
noyxplibtext	dc.b	10,'Can''t open xprymodem.library!',10,0
nogadlibtext	dc.b	10,'Can''t open gadtools.library!',10,0
nocomlibtext	dc.b	10,'Can''t open commodities.library!',10,0
nogfxlibtext	dc.b	10,'Can''t open graphics.library!',10,0
nodfolibtext	dc.b	10,'Can''t open diskfont.library!',10,0
nowblibtext	dc.b	10,'Can''t open workbench.library!',10,0
noicolibtext	dc.b	10,'Can''t open icon.library!',10,0
nointlibtext	dc.b	10,'Can''t open intuition.library!',10,0
nomainmemtext	dc.b	10,'Can''t allocate main memory!',10,0
noflpoolmemtext	dc.b	10,'Can''t allocate fl pool memory!',10,0
noindexmemtext	dc.b	10,'Can''t allocate index memory!',10,0
nomainscrentext	dc.b	10,'Can''t open main screen!',10,0
nomainwintext	dc.b	10,'Can''t open main window!',10,0
noconfigfiltext	dc.b	10,'Can''t read the config file!',10,0
nltext		dc.b	10,0
erroropentext	dc.b	10,'Error opening file: ',0
errorreadfitext	dc.b	10,'Error reading file: ',0
errorwritfitext	dc.b	10,'Error writeing file: ',0
noicontext	dc.b	10,'Warning: Error setting up the Appicon',10,0
nodiskicontext	dc.b	10,'Warning: no ABBS icon found',10,0

;argstring
readargsstring	dc.b	'Configfile,userfile',0

;Tooltypes
pritooltype	dc.b	'CX_PRIORITY',0
popuptooltype	dc.b	'CX_POPUP',0
popkeytooltype	dc.b	'CX_POPKEY',0
appicontooltype	dc.b	'APPICON',0
winlefttooltype	dc.b	'WINDOWLEFT',0
wintoptooltype	dc.b	'WINDOWTOP',0

notext		dc.b	'NO',0
falsetext	dc.b	'FALSE',0

mainarexxcmdtxt	dc.b	'SHOWGUI,SHUTDOWN,STARTNODE',0
		even
mainarexxjmp	dc.l	rexx_showgui,rexx_shutdown,rexx_startnode

		END		; That's all Folks !!!

